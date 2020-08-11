manual steps to create the mongodb replicaset

- Get a shell in the pod and initiate the replica set
  - `kubectl --namespace=mongo-cluster exec -ti mongodb-1-$$$$$`
  - `mongo --host <host> --port <port>`
  - `rs.initiate()`
  - `rs.status()` should report (some fields omitted)
  ```
    {
        "set" : "rs-minefield",
        "myState" : 1,
        "term" : NumberLong(1),
        "heartbeatIntervalMillis" : NumberLong(2000),
        "members" : [
                {
                        "_id" : 0,
                        "name" : "mongodb-1-$$$$$:27017",
                        "health" : 1,
                        "state" : 1,
                        "stateStr" : "PRIMARY",
                        "configVersion" : 1,
                        "self" : true
                }
        ],
        "ok" : 1
    }
    ```
  - Check whether you can reach mongodb via its public service name
   - 'mongo mongodb-1:27017' (the port number is *required*)
   - `rs.status()` should give the same output as above
  - Build the cluster to use public service names
   - `c = rs.conf()`
   - `c.members[0].host = "<IP of first pod>:27017"`
   - `rs.reconfig(c)` (Overwrites our host name)
   - `rs.status()` should still indicate a healthy state using "mongodb-1" as the hostname
   - `rs.add("<IP of second pod>:27017")`10.44.0.7
   - `rs.add("<IP of third pod>:27017")`
   - Verify the cluster is healthy. `rs.status()` should print (with some fields omitted)
   ```
   {
        "set" : "rs-minefield",
        "members" : [
                {
                        "_id" : 0,
                        "name" : "mongodb-1:27017",
                        "health" : 1,
                        "state" : 1,
                        "stateStr" : "PRIMARY",
                        "self" : true
                },
                {
                        "_id" : 1,
                        "name" : "mongodb-2:27017",
                        "health" : 1,
                        "state" : 2,
                        "stateStr" : "SECONDARY",
                        "syncingTo" : "mongodb-1:27017",
                },
                {
                        "_id" : 2,
                        "name" : "mongodb-3:27017",
                        "health" : 1,
                        "state" : 2,
                        "stateStr" : "SECONDARY",
                        "syncingTo" : "mongodb-1:27017",
                }
        ],
        "ok" : 1
    }
    ```
    - Connect to another replica set member and check this looks good, too
     - `mongo --host <IP of second pod>`
     - `rs.status()` should report same data as above, self being a secondary.


manual steps to create the mongodb sharding

- Make config server replica set ready (3 pods shoud be in running state)
  mongod --noprealloc --smallfiles --dbpath /data/db --configsvr --noauth --replSet ncfg --port 27017 
- Repeat above steps to make the 3 pods config server replica set with name "cfg"

- Login to mongos-1 pod (follow the below steps to add s shards with replica sets as rs1 and rs2)

  - sh.status()
  - sh.addShard("<replicaset_name>/<host_ip:port>")
    e.g. sh.addShard('rs1/10.36.0.1:27018,10.44.0.4:27018,10.44.0.6:27018')
    e.g. sh.addShard('rs2/10.36.0.2:27018,10.44.0.5:27018,10.36.0.4:27018')
  - sh.status()
  - sh.enableSharding("<database>")
    e.g sh.enableSharding("replica_ex") # enable sharding on a specific database
  - sh.shardCollection("<database>.<collection>", shard-key-pattern)
    e.g sh.shardCollection("replica_ex.restaurants", {"_id" : 1})

How to decide on which key in the collection document we should apply a shard key?