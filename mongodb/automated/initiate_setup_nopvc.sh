#!/bin/bash

function set_field_value() {
	#field=$1, default=$2, user_input=$3
	myres=''
	if [[ -z $2 ]] ; then
		printf "using default value: "
		myres=$1
	else
		printf "using user entered value: "
		myres=$2
	fi

}

# function validate_namespace() {
# 	if [ $1 <= 0 ] ; then
# 		printf "Invalid namespace name"
# 		myres=$1
# }


function validate_sh_server_rs_count() {

	if (( $1 <= 2 )) ; then
		printf "Invalid shard server replicaset counts, should be greater than 2"
		exit 1
	fi
		
}

function validate_sh_servers_count() {

	if (( $1 <= 2 )) ; then
		printf "Invalid shard servers count, should be greater than 2"
		exit 1
	fi

}

function validate_cfg_server_rs_count() {

	
	if (( $1 <= 0 )) ; then
		printf "Invalid config server replicaset counts, should be greater than 0"
		exit 1
	fi

}

function validate_cfg_servers_count() {

	if (( $1 <= 2 )) ; then
		printf "Invalid config servers count, should be greater than 2"
		exit 1
	fi

}

function validate_mongos_server_count() {

	if (( $1 <= 0 )) ; then
		printf "Invalid mongos servers count, should be greater than 0"
		exit 1
    fi

}

function get_config_ips() {

	local cfg_ips=""
	for i in `seq 1 $1`
	do
		if [[ $i == 1 ]] ; then
			cfg_ips="cfg$i\/"
		else
			cfg_ips=$cfg_ips";cfg$i\/"
		fi
		for j in `seq 1 $2`
		do
			if [[ $j == $2 ]] ; then
				cfg_ips=$cfg_ips"mongodb-$j-cfg$i:27017"
			else
				cfg_ips=$cfg_ips"mongodb-$j-cfg$i:27017,"
			fi
		done
	done
    echo "$cfg_ips"

}

function create_tmp_dir() {

	if [ -d "$1" ]; then
    	# Will enter here if $DIRECTORY exists, even if it contains spaces
    	rm -rf $1
	fi
	mkdir $1
}


function user_input() {

	# namespace
	default_namespace="mongo_cluster"
	read -p "Please enter namespace name : " namespace
	set_field_value $default_namespace $namespace
	namespace=$myres
	echo $namespace

	# replication controllers (shard server replica set)
	default_rs=3
	default_rs_servers=3
	read -p "Please enter the number of shard server replica sets to be created : " rs
	set_field_value $default_rs $rs
	rs=$myres
	validate_sh_server_rs_count $rs
	echo $rs

	read -p "Please enter the number of servers to be created in each shard server replica set : " rs_servers
	set_field_value $default_rs_servers $rs_servers
	rs_servers=$myres
	validate_sh_servers_count $rs_servers
	echo $rs_servers

	# replication controllers (config server replica set)
	default_cfg=1
	default_cfg_servers=3
	read -p "Please enter the number of config server replica sets to be created : " cfg
	set_field_value $default_cfg $cfg
	cfg=$myres
	validate_cfg_server_rs_count $cfg
	echo $cfg

	read -p "Please enter the number of servers to be created in each config server replica set : " cfg_servers
	set_field_value $default_cfg_servers $cfg_servers
	cfg_servers=$myres
	validate_cfg_servers_count $cfg_servers
	echo $cfg_servers

	# replication controllers (monogs server instances)
	default_mongos=2
	read -p "Please enter the number of mongos instances to be created : " mongos
	set_field_value $default_mongos $mongos
	mongos=$myres
	validate_mongos_server_count $mongos
	echo $mongos

}


# take users input
user_input
config_json="{\"namespace\":"

# use template and generate files
printf "creating namespace with name => $namespace\n"
create_tmp_dir ns/tmp
sed "s/namespace/$namespace/g" ns/template/namespace.yaml > ns/tmp/$namespace.yaml
config_json=$config_json"\"$namespace\",\"configs\":["

printf "creating number of replication controllers for rs in shard servers=> $rs\n"
printf "creating number of shard servers => $rs_servers\n"
create_tmp_dir mongod-rc/tmp
create_tmp_dir mongo-svc/tmp
for i in `seq 1 $rs`
do
	config_json=$config_json"{\"name\": \"rs$i\", \"type\": \"shsvr_replica_set\", \"hosts\":["
	for j in `seq 1 $rs_servers`
	do		
		sed "s/#namespace/$namespace/g;s/#mongodbi/$j/g;s/#rsi/$i/g" mongod-rc/template/mongod.nopvc.rc.yaml > mongod-rc/tmp/mongodb-$j-rs$i.yaml
		sed "s/#namespace/$namespace/g;s/#name/mongodb-$j-rs$i/g" mongo-svc/template/mongo.svc.yaml > mongo-svc/tmp/mongodb-$j-rs$i.yaml
		if [[ $j == 1 ]] ; then
			config_json=$config_json"{\"host\": \"mongodb-$j-rs$i:27017\", \"type\": \"primary\"},"			
		elif [[ $j == $rs ]] ; then
			config_json=$config_json"{\"host\": \"mongodb-$j-rs$i:27017\", \"type\": \"secondary\"}"
		else
			config_json=$config_json"{\"host\": \"mongodb-$j-rs$i:27017\", \"type\": \"secondary\"},"
		fi
	done
	config_json=$config_json"]},"
done
#config_json=$config_json"]},"

printf "creating number of replication controllers for rs in config servers => $cfg\n"
printf "creating number of config servers => $cfg_servers\n"
create_tmp_dir cfgsvr-rc/tmp
for i in `seq 1 $cfg`
do
	config_json=$config_json"{\"name\": \"cfg$i\", \"type\": \"cfgsvr_replica_set\", \"hosts\":["
	for j in `seq 1 $cfg_servers`
	do
		sed "s/#namespace/$namespace/g;s/#mongodbi/$j/g;s/#cfgi/$i/g" cfgsvr-rc/template/cfgsvr.nopvc.rc.yaml > cfgsvr-rc/tmp/mongodb-$j-cfg$i.yaml
		sed "s/#namespace/$namespace/g;s/#name/mongodb-$j-cfg$i/g" mongo-svc/template/mongo.svc.yaml > mongo-svc/tmp/mongodb-$j-cfg$i.yaml
		if [[ $j == 1 ]] ; then
			config_json=$config_json"{\"host\": \"mongodb-$j-cfg$i:27017\", \"type\": \"primary\"},"
		elif [[ $j == $cfg_servers ]] ; then
			config_json=$config_json"{\"host\": \"mongodb-$j-cfg$i:27017\", \"type\": \"secondary\"}"
		else
			config_json=$config_json"{\"host\": \"mongodb-$j-cfg$i:27017\", \"type\": \"secondary\"},"
		fi
	done
	config_json=$config_json"]},"
done

printf "creating number of mongos instances => $mongos\n"
create_tmp_dir mongos-rc/tmp
cfg_ips=$(get_config_ips $cfg $cfg_servers)
#echo "CFG ips=$cfg_ips"
config_json=$config_json"{\"name\": \"mongosvr\", \"type\": \"mongos\", \"hosts\":["
for i in `seq 1 $mongos`
do
	sed "s/#namespace/$namespace/g;s/#cfgi/$i/g;s/#cfg-ips/$cfg_ips/g" mongos-rc/template/mongos.nopvc.rc.yaml > mongos-rc/tmp/mongos-$i.yaml
	sed "s/#namespace/$namespace/g;s/#name/mongos-$i/g" mongo-svc/template/mongo.svc.yaml > mongo-svc/tmp/mongos-$i.yaml
	if [[ $i == 1 ]] ; then
		config_json=$config_json"{\"host\": \"mongos-$i:27017\", \"type\": \"primary\"},"
	elif [[ $i == $mongos ]] ; then
		config_json=$config_json"{\"host\": \"mongos-$i:27017\", \"type\": \"secondary\"}"
	else
		config_json=$config_json"{\"host\": \"mongos-$i:27017\", \"type\": \"secondary\"},"
	fi
done
config_json=$config_json"]}],\"cfg_ips\":\"$cfg_ips\"}"

# generate config file
echo $config_json | python -mjson.tool > config.json