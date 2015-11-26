# Creates pseudo distributed hadoop 2.6.0
#
# sudo docker build -t jun16/spark-yarn-cluster .
FROM sequenceiq/pam:centos-6.5
MAINTAINER jun.yamada jun.16@mac.com

USER root

# install dev tools
RUN yum install -y curl which tar sudo openssh-server openssh-clients rsync | true
RUN yum update -y libselinux | true

# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# java
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN rpm -i jdk-7u71-linux-x64.rpm
RUN rm jdk-7u71-linux-x64.rpm

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin

# hadoop
RUN curl -s http://ftp.jaist.ac.jp/pub/apache/hadoop/core/hadoop-2.7.1/hadoop-2.7.1.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hadoop-2.7.1 hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
#RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

# fixing the libhadoop.so like a boss
RUN rm  /usr/local/hadoop/lib/native/*
RUN curl -Ls http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64-2.7.0.tar | tar -x -C /usr/local/hadoop/lib/native/

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

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
