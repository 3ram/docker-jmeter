# inspired by https://github.com/hauptmedia/docker-jmeter  and
# https://github.com/hhcordero/docker-jmeter-server/blob/master/Dockerfile
FROM alpine:3.12

MAINTAINER Just van den Broecke<just@justobjects.nl>

ARG JMETER_VERSION="5.3"
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_DOWNLOAD_URL  https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz



ENV MYSQL_CONNECTOR_VERSION         8.0.23
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    ${MAVEN_REPOSITORY}/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_PATH			${JMETER_HOME}/lib
ENV MYSQL_CONNECTOR_SHA256          ff7d5b402afd39c12787471505a33a304103b238ec1b7a44e8936d3329da7535

# Install extra packages
# See https://github.com/gliderlabs/docker-alpine/issues/136#issuecomment-272703023
# Change TimeZone TODO: TZ still is not set!
ARG TZ="Europe/Amsterdam"
RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update openjdk8-jre tzdata curl unzip bash \
	&& apk add --no-cache nss \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies  \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} >  /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz  \
	&& mkdir -p /opt  \
	&& tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt  \
	&& rm -rf /tmp/dependencies


    echo "  |____ install mysql-connector jmeter-plugin" && \
	echo "  |  |____ 1. download mysql-connector" && \
	(curl -Lso ${MYSQL_CONNECTOR_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} 2> install.log || (>&2 cat install.log && echo && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum ${MYSQL_CONNECTOR_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep ${MYSQL_CONNECTOR_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum ${MYSQL_CONNECTOR_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
	\
# TODO: plugins (later)
# && unzip -oq "/tmp/dependencies/JMeterPlugins-*.zip" -d $JMETER_HOME

# Set global PATH such that "jmeter" command is found
ENV PATH $PATH:$JMETER_BIN

# Entrypoint has same signature as "jmeter" command
COPY entrypoint.sh /

WORKDIR	${JMETER_HOME}

ENTRYPOINT ["/entrypoint.sh"]
