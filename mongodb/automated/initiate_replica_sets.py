# python
import sys
import json
import subprocess
import pdb

def get_pod_name_to_execute_command(replica_set_name, namespace='default'):
	# kubectl get pods --namespace=mongo-cluster | grep rs1 | awk 'NR==1{print $1}'
	cmd = "kubectl get pods --namespace=$namespace | grep $rs_name | awk 'NR==1{print $1}'".replace('$namespace', namespace).replace('$rs_name', replica_set_name)
	print cmd
	sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	#pdb.set_trace()
	out = sp.stdout.readlines()
	print out
	if out and len(out) > 0:
		return out[0].strip('\n')

def build_rs(replica_set_name, config):
	pdb.set_trace()
	rs_template = "{_id:'$repl_set', members:$members}"
	members_template_start = "["
	members_template_end= "]"
	members_template = "{_id: $id, host:'$host'}"
	members = ""
	for index, item in enumerate(config.get('hosts')):
		if index == 0:
			members = members_template_start + members_template.replace('$id', str(index)).replace('$host', item.get('host')) + ","
		elif index == len(config.get('hosts')) - 1:
			members = members + members_template.replace('$id', str(index)).replace('$host', item.get('host')) + members_template_end
		else:
			members = members + members_template.replace('$id', str(index)).replace('$host', item.get('host')) + ","
        cfg = rs_template.replace('$repl_set', replica_set_name).replace('$members', members)
	print "Config => \n{}".format(cfg)
	return cfg

def check_rs_initiation(pod_name, namespace):
	print "Checking initiation"
	cmd = "kubectl exec -it {} --namespace={} -- mongo --eval \"rs.status()\"".format(pod_name, namespace)
	print cmd
	sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	out = sp.stdout.readlines()
	print "out => {}".format(out) 
	if "\t\"code\" : 94,\r\n" in out or "\t\"errmsg\" : \"no replset config has been received\",\r\n" in out:
		print "Replicas are not initialized yet."
		return True
	else:
		print "Replicas are already initiated"
		return False

def initiate_rs(pod_name, namespace, cfg):
	# decide where and how to excute this command
	# ans: get pod name using kubectl command from rc name and execute this command on that Pod
	print "Initiating replicas"
	cmd = "kubectl exec -it {} --namespace={} -- mongo --eval \"rs.initiate({})\"".format(pod_name, namespace, cfg)
	print cmd
	sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	print sp.stdout.readlines()
	print "Replicas initiated"

def get_shard_confs(configs):
	#List of confs e.g single rs: 'rs1/10.36.0.1:27017,10.44.0.4:27017,10.44.0.6:27017'
	config_server_shard_confs = []
	for config in config_json.get('configs'):
		conf_str = None	
		if config.get('type') == 'shsvr_replica_set':
			for index, item in enumerate(config.get('hosts')):
				if conf_str is None:
					conf_str = item.get('host') + ","
				else:
					conf_str = conf_str + item.get('host') + ","
		if conf_str is not None:
			config_server_shard_confs.append("{}/{}".format(config.get('name'), conf_str))
	return config_server_shard_confs

def initiate_shards(pod_name, namespace, shard_confs):
	# decide where and how to excute this command
	# ans: get pod name using kubectl command from rc name and execute this command on that Pod
	for shard_conf in shard_confs:
		print "Initiating shards"
		cmd = "kubectl exec -it {} --namespace={} -- mongo --eval \"sh.addShard({})\"".format(pod_name, namespace, shard_conf.replace("\"", "'"))
		print cmd
		sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		print sp.stdout.readlines()
		print "Shards initiated"

def set_hostnames(namespace):
	cmd = "kubectl get pods --namespace=#namespace | awk '{print $1}'".replace("#namespace", namespace)
        print cmd
        sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        pod_list = sp.stdout.readlines()
        print pod_list
        for pod in pod_list:
                host = pod.strip('\n').rsplit("-", 1)[0]
                cmd = "kubectl exec -it {} --namespace={} -- bash -c \"echo '127.0.0.1  {}' >> /etc/hosts\"".format(pod.strip('\n'), namespace, host)
                print cmd
                sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print sp.stdout.readlines()

if __name__ == '__main__':
	# read config json
	config_json = None
	with open('config.json', 'r') as f:
		config_json = json.loads(f.read())

	if config_json is None:
		print "Config file not generated"
		sys.exit(0)

	namespace = config_json.get('namespace')
        set_hostnames(namespace)

	for config in config_json.get('configs'):
		if config.get('type') in ['cfgsvr_replica_set', 'shsvr_replica_set']:
			# initiate replicasets fro shard servers
			pod_name = get_pod_name_to_execute_command(config.get('name'), namespace)
			print "Executing command on => {}".format(pod_name)
			if pod_name:
				cfg = build_rs(config.get('name'), config)
				if check_rs_initiation(pod_name, namespace):
					initiate_rs(pod_name, namespace, cfg)
			
		elif config.get('type') == 'mongos':
			# initiate replica set for config servers
			pod_name = get_pod_name_to_execute_command(config.get('type'), namespace)
			print "Executing command on => {}".format(pod_name)
			if pod_name:
				cfg = get_shard_confs(config_json)
				print "Shard configs : \n{}".format(cfg)
				#initiate_shards(pod_name, namespace, cfg)
