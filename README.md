Author : Amol Shinde

# Steps for kubernetes customized cluster 1 master + 2 nodes using kubeadm (Centos-7)

## references : 

https://www.profiq.com/kubernetes-cluster-setup-using-virtual-machines/
https://www.linuxtechi.com/install-kubernetes-1-7-centos7-rhel7/
https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install
http://jeffmendoza.github.io/kubernetes/v1.0/docs/getting-started-guides/docker-multinode.html

## Create base virtual machines

## Master vm:
	
  4 Sockets CPU - 2 cores each
  8 GB RAM

## Node vms 	

  4 Sockets CPU - 1 cores each
  4 GB RAM

## Steps to perform on master and slave nodes:

1. yum update
2. yum install wget
3. hostnamectl set-hostname <name> (e.g. kubeslave2)
4. systemctl disable firewalld && systemctl stop firewalld
	OR 

   [root@k8s-master ~]# firewall-cmd --permanent --add-port=6443/tcp
   [root@k8s-master ~]# firewall-cmd --permanent --add-port=2379-2380/tcp
   [root@k8s-master ~]# firewall-cmd --permanent --add-port=10250/tcp
   [root@k8s-master ~]# firewall-cmd --permanent --add-port=10251/tcp
   [root@k8s-master ~]# firewall-cmd --permanent --add-port=10252/tcp
   [root@k8s-master ~]# firewall-cmd --permanent --add-port=10255/tcp
   [root@k8s-master ~]# firewall-cmd --reload
   [root@k8s-master ~]# echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

5. add entries into /etc/hosts
	192.168.102.199 kubemaster.test.com kubemaster
	192.168.102.12 kubeslave1.test.com kubeslave1
	192.168.102.15 kubeslave2.test.com kubeslave2

6. create repo file

	vi /etc/yum.repos.d/kubernetes.repo 

	[kubernetes] 
	name=Kubernetes 
	baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64 
	enabled=1 
	gpgcheck=1 
	repo_gpgcheck=1 
	gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

7. install kubeadm and docker
	yum install -y docker kubeadm 

8. enable and start the services:
	systemctl enable docker && systemctl start docker 
	systemctl enable kubelet && systemctl start kubelet


9. add env variable to kubeadm conf file
	add "Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"" to /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
	systemctl daemon-reload
	systemctl restart kubelet

10. reboot machines

11. add entry in /etc/resolve.conf
	nameserver 8.8.8.8

# Extra steps to perform on master node:

1. Initiate kubeadm 
	
	kubeadm init

2. copy config from /etc to ~/.kube
	[root@k8s-master ~]# mkdir -p $HOME/.kube
	[root@k8s-master ~]# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	[root@k8s-master ~]# chown $(id -u):$(id -g) $HOME/.kube/config

3. To make the cluster status ready and kube-dns status running, deploy the pod network so that containers of different host communicated each other. POD network is the overlay network between the worker nodes. Run the beneath command to deploy network.

	[root@k8s-master ~]# export kubever=$(kubectl version | base64 | tr -d '\n')
	[root@k8s-master ~]# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
	serviceaccount "weave-net" created
	clusterrole "weave-net" created
	clusterrolebinding "weave-net" created
	daemonset "weave-net" created

4. at the EOD of a file you can see output like this

	Your Kubernetes master has initialized successfully!

	To start using your cluster, you need to run (as a regular user):

	  mkdir -p $HOME/.kube
	  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	  sudo chown $(id -u):$(id -g) $HOME/.kube/config

	You should now deploy a pod network to the cluster.
	Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
	  http://kubernetes.io/docs/admin/addons/

5. You can now join any number of machines by running the following on each node
as root:

	  kubeadm join --token 2b9fbe.625a846bbbdb5edb 192.168.102.199:6443 --discovery-token-ca-cert-hash sha256:092edc5eeff99b82397686277e9a2e468796973ae79c497a2c10ca44621cc40a

6. "kubectl get nodes" should show the master and worker nodes

# Extra steps to perform on on worker nodes:

1. disable selinux:
	setenforce 0
	sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

2. disable firewalld
	systemctl disable firewalld && systemctl stop firewalld
	OR
	[root@k8s-master ~]# firewall-cmd --permanent --add-port=6443/tcp
	[root@k8s-master ~]# firewall-cmd --permanent --add-port=2379-2380/tcp
	[root@k8s-master ~]# firewall-cmd --permanent --add-port=10250/tcp
	[root@k8s-master ~]# firewall-cmd --permanent --add-port=10251/tcp
	[root@k8s-master ~]# firewall-cmd --permanent --add-port=10252/tcp
	[root@k8s-master ~]# firewall-cmd --permanent --add-port=10255/tcp
	[root@k8s-master ~]# firewall-cmd --reload
	[root@k8s-master ~]# echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

3. add entry in /etc/resolve.conf
	nameserver 8.8.8.8

4. join worker node:
	kubeadm join --token 2b9fbe.625a846bbbdb5edb 192.168.102.199:6443
	OR	
	kubeadm join --token 15d491.568a60cd901cc4e5 192.168.102.12:6443 --skip-preflight-checks --discovery-token-ca-cert-hash sha256:739467d9c39bc2f3782b89bfbb346158a5b12b6d2e187139cf37bfd86da45b9b 

# Deployment of an app on customized multinode kubernetes cluster

## Coming soon

# Deployment of an mongodb PaaS on k8s cluster

## Please refer README.txt of ./mongodb 

# Deployment of an ElasticSearch PaaS on k8s cluster

## Please refer README.txt of ./es
