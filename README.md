# How to work with the container spark-master

## Overview

This image contains the following software:

- Spark

When you run this image, the container starts the master service and one slave service.

## Create specific network

```bash
docker network create sparkCluster
```

## Start the container

```bash
docker run -d --rm --net sparkCluster -p 4040:4040 -p 8080:8080 -p 8081:8081 -v $PWD:/app --name spark-master -h spark-master swal4u/spark-master:v2.3.0.4
```

The master service and the slave service are started automatically.
The command mounts the app directory that you can use for your application.
Note the --rm option to destroy the container once it is finished.

## Work with spark-shell

```bash
docker exec -it spark-master spark-shell --master spark://spark-master:7077 --executor-memory 2G
```

Connect to the container and launch the shell.

## Work with spark-submit

This is an example with the project hello-spark (default project included in swal4u/sbt image).
You must first go to the root directory of the project before running the spark server

```bash
docker exec -it spark-master spark-submit --master spark://spark-master:7077 --executor-memory 2G --class fr.stephanewalter.hello.Connexion target/scala-2.12/hello-spark_2.11-0.0.1.jar
```

## Work with zeppelin

If you want to use Zeppelin with Spark, you could use only the zeppelin container with built-in spark.

```bash
docker run -p 8090:8080 --rm -v logs:/logs -v notebook:/notebook -e ZEPPELIN_LOG_DIR=/logs -e ZEPPELIN_NOTEBOOK_DIR=/notebook --name zeppelin apache/zeppelin:0.9.0
```

## Add a new worker

If you want, it's possible to add more slaves.
To avoid problem, you have to choose another name and port for the container !

```bash
docker run -d --rm --net sparkCluster -p 8082:8081 -v $PWD:/root --name slave2 -h slave2 swal4u/spark-slave:v2.4.2.1
```

I choose to add a function in my .bash_profile (OSX).

```bash
docker run -d --rm --net sparkCluster -p "$2":8081 -v $PWD:/root --name "$1" -h "$1" swal4u/spark-slave:v2.4.2.1
```

## Monitoring

It's possible to monitor the cluster on [http://127.0.0.1:8080](http://127.0.0.1:8080)
It's possible to monitor the slave on [http://127.0.0.1:8081](http://127.0.0.1:8081)
And monitor jobs on [http://127.0.0.1:4040](http://127.0.0.1:4040)

## Stop the containers

```bash
docker stop slave2 (if you started this container before)
docker stop spark
```

## Bonus

The root folder contains two interesting files.
The **.bash_history** save the bash commands on master or slave.
The **.scala_history** save the commands in spark-shell.

## Publish a new version in docker hub (for the maintainer)

```bash
git tag -a vX.Y.Z.T
git push --tags
```

Docker Hub detects a new version and build the container automatically.

## Zeppelin

docker run -p 8090:8080 --rm -v $PWD/logs:/logs -v $PWD/notebook:/notebook \
           -e ZEPPELIN_LOG_DIR='/logs' -e ZEPPELIN_NOTEBOOK_DIR='/notebook' \
           --name zeppelin apache/zeppelin:0.9.0

## Build image

### Docker-desktop in OSX

````bash
docker build -t swal4u/spark-master:v2.3.0.4 \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) .
````

### Minikube

As Minikube is a VM with a specific user (1000:1000), you have to force user and group to have right access on files.

````bash
docker build -t swal4u/spark-master:v2.3.0.4 \
  --build-arg USER_ID=1000 \
  --build-arg GROUP_ID=1000 .
````

