#!/bin/bash
nopvc=0
echo "Generating k8s and config files - without pvc"
bash initiate_setup_nopvc.sh
echo "Generated k8s and config files"

#exit 0

printf 'Creating the namespace...\n'
kubectl create -f ns/tmp/
# verify ns are up
printf 'namespace created successfully.\n'

if [[ $nopvc == "1" ]] ; then
	printf 'Creating the persistent volumes...\n'
	kubectl create -f pv/
	# verify pv's are up
	printf 'persistent volumes created successfully.\n'

	printf 'Creating the persistent volume claims...\n'
	kubectl create -f pvc/
	# verify pvc's are up
	printf 'persistent volume claims created successfully.\n'
fi

printf 'Creating the k8s replication controllers (shard server replica set)...\n'
kubectl create -f mongod-rc/tmp/
# verify rc's are up
# while true; do
#     active=`kubectl get rc | grep mongo | awk '{print $6}'`
#     if [ "$active" == "1" ]; then
#     break
#     fi
#     sleep 2
# done
printf 'replication controllers (shard server replica set) created successfully.\n'

printf 'Creating the k8s replication controllers (config server replica set)...\n'
kubectl create -f cfgsvr-rc/tmp/
# verify rc's are up
# while true; do
#     active=`kubectl get rc | grep mongo | awk '{print $6}'`
#     if [ "$active" == "1" ]; then
#     break
#     fi
#     sleep 2
# done
printf 'replication controllers (config server replica set) created successfully.\n'

printf 'Creating the k8s replication controllers (monogs server instances)...\n'
kubectl create -f mongos-rc/tmp/
# verify rc's are up
# while true; do
#     active=`kubectl get rc | grep mongo | awk '{print $6}'`
#     if [ "$active" == "1" ]; then
#     break
#     fi
#     sleep 2
# done
printf 'replication controllers (monogs server instances) created successfully.\n'

printf 'Creating the mongodb services...\n'
kubectl create -f mongo-svc/tmp/
# verify svc's are up
# while true; do
#     active=`kubectl get rc | grep mongo | awk '{print $6}'`
#     if [ "$active" == "1" ]; then
#     break
#     fi
#     sleep 2
# done
printf 'mongodb services created successfully.\n'
