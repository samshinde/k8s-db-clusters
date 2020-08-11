#kubectl create -f ns/
#kubectl create -f pv/
#kubectl create -f pvc/
kubectl create -f mongod-rc/
kubectl create -f cfgsvr-rc/
kubectl create -f mongos-rc/
kubectl create -f mongo-svc/
kubectl get pods --namespace=mongo-cluster
