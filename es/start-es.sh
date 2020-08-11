#!/bin/bash
 
echo "Creating Elasticsearch services..."
#kubectl create -f es-discovery-svc.yaml
#kubectl create -f es-svc.yaml
#kubectl create -f es-master.yaml --validate=false
kubectl create -f es-client.yaml --validate=false
kubectl create -f es-data.yaml --validate=false
 
# Check to see if the deployments are running
#while true; do
#    active=`kubectl get deployments --all-namespaces | grep es-master | awk '{print $6}'`
#    echo "master active : $active"
#    if [ "$active" == "1" ]; then
#    break
#    fi
#    sleep 2
#done
while true; do
    active=`kubectl get deployments --all-namespaces | grep es-client | awk '{print $6}'`
    echo "client active : $active"
    if [ "$active" == "1" ]; then
    break
    fi
    sleep 2
done
while true; do
    active=`kubectl get deployments --all-namespaces | grep es-data | awk '{print $6}'`
    echo "data active : $active"
    if [ "$active" == "1" ]; then
    break
    fi
    sleep 2
done
 
# Scale the cluster to 3 master, 4 data, and 2 client nodes
# kubectl scale deployment es-master --replicas 3
# kubectl scale deployment es-client --replicas 2
# kubectl scale deployment es-data --replicas 4
 
echo "Waiting for Elasticsearch public service IP..."
while true; do
    es_ip=`kubectl get svc elasticsearch | grep elasticsearch | awk '{print $3}'`
    if [ "$es_ip" != "<pending>" ]; then
    break
    fi
    sleep 2
done   
echo "Elasticsearch public IP:    "$es_ip"
