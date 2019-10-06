FROM openjdk:8

LABEL maintainer="Stéphane Walter <stephane.walter@me.com>"
LABEL REFRESHED_AT="2019-10-06"
LABEL version="Spark Master"
LABEL features="Spark, Zeppelin, Delta"

# We will be running our Spark jobs as `root` user.
USER root

# Working directory is set to the home folder of `vagrant` user.
WORKDIR /root/

# Spark related variables.
ARG SPARK_VERSION=2.4.2
ARG SPARK_BINARY_ARCHIVE_NAME=spark-${SPARK_VERSION}-bin-hadoop2.7
#ARG SPARK_BINARY_DOWNLOAD_URL=http://apache.cs.uu.nl/spark/spark-${SPARK_VERSION}/${SPARK_BINARY_ARCHIVE_NAME}.tgz
ARG SPARK_BINARY_DOWNLOAD_URL=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_BINARY_ARCHIVE_NAME}.tgz

# Zeppelin related variables.
ARG ZEPPELIN_VERSION="v0.8.2"
ARG ZEPPELIN_BINARY_DOWNLOAD_URL=http://apache.crihan.fr/dist/zeppelin/zeppelin-0.8.2/zeppelin-0.8.2-bin-all.tgz
ARG ZEPPELIN_BINARY_ARCHIVE_NAME=zeppelin-0.8.2-bin-all

ENV SPARK_HIVE true
ENV ZEPPELIN_PORT 8090
ENV ZEPPELIN_HOME /usr/local/zeppelin 
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf 
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook 

# Configure env variables for Spark.
# Also configure PATH env variable to include binary folders of Java and Spark.
ENV SPARK_HOME  /usr/local/spark
ENV PATH        $JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:${ZEPPELIN_HOME}/bin:$PATH

# Download, uncompress and move all the required packages and libraries to their corresponding directories in /usr/local/ folder.
RUN apt-get -yqq update && \
    apt-get install -yqq vim netcat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${ZEPPELIN_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    cd /usr/local/ && \
    ln -s ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    ln -s ${ZEPPELIN_BINARY_ARCHIVE_NAME} zeppelin && \
    cp spark/conf/log4j.properties.template spark/conf/log4j.properties && \
    sed -i -e s/WARN/ERROR/g spark/conf/log4j.properties && \
    sed -i -e s/INFO/ERROR/g spark/conf/log4j.properties && \
    mkdir -p $ZEPPELIN_HOME/logs && \
    mkdir -p $ZEPPELIN_HOME/run && \
    cp /usr/local/zeppelin/conf/zeppelin-site.xml.template /usr/local/zeppelin/conf/zeppelin-site.xml && \
    sed -i 's|<value>8080</value>|<value>8090</value>|g' /usr/local/zeppelin/conf/zeppelin-site.xml && \
    cp /usr/local/zeppelin/conf/zeppelin-env.sh.template /usr/local/zeppelin/conf/zeppelin-env.sh && \
    sed -i 's|# export MASTER= |export MASTER=spark://spark-master:7077|g' /usr/local/zeppelin/conf/zeppelin-env.sh && \
    sed -i 's|# export SPARK_HOME |export SPARK_HOME=/usr/local/spark|g' /usr/local/zeppelin/conf/zeppelin-env.sh

## To start Zeppelin:                  zeppelin-daemon.sh start
## To stop Zeppelin:                   zeppelin-daemon.sh stop
## To know the status of Zeppelin:     zeppelin-daemon.sh status

# Loop to avoid to exit
ADD master.sh /etc/master.sh
RUN chown root:root /etc/master.sh && \
chmod 700 /etc/master.sh

# Expose ports for monitoring.
# SparkContext web UI on 4040 -- only available for the duration of the application.
# Spark master’s web UI on 8080.
# Spark worker web UI on 8081.
# Zeppelin web UI on 8090.

EXPOSE 4040 8080 8081 7077 8090

# Declare volume to expose for caching
# sbt:"/root/.sbt"
# ivy2:"/root/.ivy2"

# Declare volume of your application
# $PWD/app:/app

CMD ["/etc/master.sh", "-d","2G","1"]
