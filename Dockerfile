# Creates pseudo distributed hadoop 2.6.0
#
# sudo docker build -t jun16/spark-yarn-cluster .

FROM ferronhanse/docker-yarn-cluster
MAINTAINER jun.yamada jun.16@mac.com


# scala
RUN curl -s wget http://www.scala-lang.org/files/archive/scala-2.11.5.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./scala-2.11.5 scala
ENV SCALA_HOME=/usr/local/scala
ENV PATH=$PATH:$SCALA_HOME/bin

# spark
RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.5.1-bin-hadoop2.6.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-1.5.1-bin-hadoop2.6 spark
ENV SPARK_HOME /usr/local/spark
RUN mkdir $SPARK_HOME/yarn-remote-client
ADD yarn-remote-client $SPARK_HOME/yarn-remote-client

# sbt
RUN curl https://bintray.com/sbt/rpm/rpm | tee /etc/yum.repos.d/bintray-sbt-rpm.repo
RUN yum install -y sbt

# timezone
RUN /bin/cp -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime


# add samplefile
RUN mkdir /usr/local/spark/sample
ADD sample/ApacheSpark_samples.zip /usr/local/spark/sample
RUN cd /usr/local/spark/sample && unzip ApacheSpark_samples.zip

# bootstrap
ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh", "-d"]


# Spark ports
EXPOSE 4040

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
