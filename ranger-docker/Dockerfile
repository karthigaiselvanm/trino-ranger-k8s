FROM ubuntu:20.04
ARG RANGER_VERSION=3.0.0-SNAPSHOT
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk-headless python-is-python3 less curl wget && \
    apt-get clean
ADD https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.1.0/mysql-connector-j-8.1.0.jar /opt/mysql-connector-java.jar
WORKDIR /root 
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
COPY ranger-entrypoint.sh /opt 
COPY ranger-packages/ranger-${RANGER_VERSION}-admin /opt/ranger-${RANGER_VERSION}-admin/
WORKDIR /opt
RUN chmod +x /opt/ranger-entrypoint.sh
ENV RANGER_HOME=/opt/ranger-${RANGER_VERSION}-admin
COPY install.properties /opt/ranger-${RANGER_VERSION}-admin/
EXPOSE 6080
ENTRYPOINT ["/opt/ranger-entrypoint.sh"]
