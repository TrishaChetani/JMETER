FROM ubuntu:14.04
RUN apt-get clean && \
	apt-get update && \
	apt-get -qy install \
			wget \
			default-jre-headless \
			telnet \
			iputils-ping \
			unzip

## UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

## JAVA INSTALLATION
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes --no-install-recommends oracle-java8-installer && apt-get clean all

## JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN apt-get update && apt-get install -y nmon default-jdk apt-transport-https wget apt-utils
RUN wget "http://mirror.its.dal.ca/apache/jmeter/binaries/apache-jmeter-4.0.tgz"
RUN tar zxvf apache-jmeter-4.0.tgz
RUN wget -O /apache-jmeter-4.0/lib/ext/jmeter-plugins-manager-0.19.jar  "http://search.maven.org/remotecontent?filepath=kg/apc/jmeter-plugins-manager/0.19/jmeter-plugins-manager-0.19.jar"
RUN wget -O /apache-jmeter-4.0/lib/cmdrunner-2.0.jar  "http://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/2.0/cmdrunner-2.0.jar"
RUN java -cp /apache-jmeter-4.0/lib/ext/jmeter-plugins-manager-*.jar org.jmeterplugins.repository.PluginManagerCMDInstaller 
RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh install jpgc-casutg,jpgc-prmctl,jpgc-graphs-basic,jpgc-graphs-additional,jpgc-tst
RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh install-all-except websocket-samplers
RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh upgrades
RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh status
RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh available

# Set Jmeter Home
ENV JMETER_HOME /apache-jmeter-4.0/

# Add Jmeter to the Path
ENV PATH $JMETER_HOME/bin:$PATH

ENV PATH $PATH:$JMETER_BIN

WORKDIR $JMETER_HOME
ARG RMI_PORT=20000
ENV RMI_PORT ${RMI_PORT}
EXPOSE ${RMI_PORT}


ARG RMI_IP=0.0.0.0
ENV RMI_IP ${RMI_IP}


ENV ANT_VERSION 1.9.9

RUN cd && \
    wget -q http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz && \
    tar -xzf apache-ant-${ANT_VERSION}-bin.tar.gz && \
    mv apache-ant-${ANT_VERSION} /opt/ant && \
    rm apache-ant-${ANT_VERSION}-bin.tar.gz
ENV ANT_HOME /opt/ant
ENV PATH ${PATH}:/opt/ant/bin

COPY docker-entrypoint.sh ./
 
COPY UGCLoadTestCase.jmx ./bin
COPY request.jmx ./bin

RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh install-for-jmx ./bin/request.jmx 
RUN /apache-jmeter-4.0/bin/PluginsManagerCMD.sh install-for-jmx ./bin/UGCLoadTestCase.jmx 

RUN chmod +x ./docker-entrypoint.sh
RUN chmod +x ./bin/UGCLoadTestCase.jmx
RUN chmod +x ./bin/request.jmx 


CMD ./docker-entrypoint.sh
