#!/bin/bash
echo "Tearing down cluster services..."
kubectl delete svc --namespace=es-cluster elasticsearch
kubectl delete svc --namespace=es-cluster elasticsearch-discovery
kubectl delete deployment --namespace=es-cluster es-master
kubectl delete deployment --namespace=es-cluster es-client
kubectl delete deployment --namespace=es-cluster es-data
#kubectl delete namespace es-cluster
sleep 30
echo "Done"
