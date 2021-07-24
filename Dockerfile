FROM openjdk:8

LABEL maintainer="Stéphane Walter <stephane.walter@me.com>"
LABEL REFRESHED_AT="2021-07-24"
LABEL version="Spark Master"
LABEL features="Spark - with non root user"

# Spark related variables.
ARG SPARK_VERSION=2.3.0
ARG SPARK_BINARY_ARCHIVE_NAME=spark-${SPARK_VERSION}-bin-hadoop2.7
ARG SPARK_BINARY_DOWNLOAD_URL=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_BINARY_ARCHIVE_NAME}.tgz

ENV SPARK_HIVE true

# Configure env variables for Spark.
# Also configure PATH env variable to include binary folders of Java and Spark.
ENV SPARK_HOME  /usr/local/spark
ENV PATH        $JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
ENV PATH        $JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH

WORKDIR /usr/local

# Download, uncompress and move all the required packages and libraries to their corresponding directories in /usr/local/folder.

RUN apt-get -yqq update && \
    apt-get install -yqq vim netcat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | tar -xz && \
    cd /usr/local/ && \
    mv ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    cp spark/conf/log4j.properties.template spark/conf/log4j.properties && \
    sed -i -e s/WARN/ERROR/g spark/conf/log4j.properties && \
    sed -i -e s/INFO/ERROR/g spark/conf/log4j.properties

# User
ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
USER user

# Define working directory
USER root


# Loop to avoid to exit
ADD master.sh /usr/local/spark/master.sh
RUN chown -R user:user /usr/local/spark
RUN chmod +x /usr/local/spark/master.sh
USER user
WORKDIR /app

# Expose ports for monitoring.
# SparkContext web UI on 4040 -- only available for the duration of the application.
# Spark master’s web UI on 8080.
# Spark worker web UI on 8081.

EXPOSE 4040 8080 8081 7077

CMD ["/usr/local/spark/master.sh", "-d","4G","2"]
