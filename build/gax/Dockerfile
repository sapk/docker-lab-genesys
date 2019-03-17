FROM centos as build-lca
ARG  LCA_VERSION=8510029b1_ENU
#Add 32 bit support to centos (Needed for install script)
RUN yum install -y glibc.i686 && yum clean all && rm -rf /var/cache/yum

ADD source/IP_LCA_${LCA_VERSION}_linux.tar.gz /source/lca

COPY build/lca/genesys_silent.ini  /source/lca/ip/genesys_silent.ini

WORKDIR /source/lca/ip
RUN ./install.sh -s -fr /source/lca/ip/genesys_silent.ini -fl /source/lca/ip/genesys_install_result.log; cat /source/lca/ip/genesys_install_result.log

FROM centos as build-env
ARG  GAX_VERSION=9000015b1_ENU

#Install java
RUN yum install -y java-1.8.0-openjdk-headless && yum clean all && rm -rf /var/cache/yum
#Add 32 bit support to centos (Needed for install script)
RUN yum install -y glibc.i686 && yum clean all && rm -rf /var/cache/yum

ADD source/IP_GAX_${GAX_VERSION}_linux.tar.gz /source/gax

COPY build/gax/genesys_silent.ini  /source/gax/ip/genesys_silent.ini

WORKDIR /source/gax/ip
#Fix os version compat
RUN echo "CentOS release 7 (Core)" > /etc/redhat-release
RUN JRE_HOME=$(echo /usr/lib/jvm/java-*/jre) ./install.sh -s -fr /source/gax/ip/genesys_silent.ini -fl /source/gax/ip/genesys_install_result.log; cat /source/gax/ip/genesys_install_result.log

FROM centos
#Install java
RUN yum install -y java-1.8.0-openjdk-headless && yum clean all && rm -rf /var/cache/yum
RUN yum install -y postgresql nc && yum clean all && rm -rf /var/cache/yum
RUN curl -L --output /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x /usr/bin/jq

COPY --from=build-lca /gcti/lca /gcti/lca
COPY --from=build-env /gcti/gax /gcti/gax
COPY --from=build-env /source/gax/templates /source/gax/templates
COPY build/gax/entrypoint.sh /entrypoint.sh

COPY script /gcti/script

WORKDIR /gcti/gax

VOLUME /gcti/gax/conf
#TODO volume log ? now only on stdout
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/gcti/gax/gax_startup.sh", "-immediate"]
EXPOSE 8080/tcp
#By default https is deactived
#EXPOSE 8443/tcp

#TODO Configure by env https://docs.genesys.com/Documentation/GA/8.5.2/Dep/GAXProperties
#TODO Find a better way than running LCA in every container
#TODO add env variable to configure config server
#TODO add healthcheck
