FROM centos as build-lca
ARG  LCA_VERSION=8510029b1_ENU
#Add 32 bit support to centos (Needed for install script)
RUN yum install -y glibc.i686 && yum clean all && rm -rf /var/cache/yum

ADD source/IP_LCA_${LCA_VERSION}_linux.tar.gz /source/lca

COPY build/lca/genesys_silent.ini  /source/lca/ip/genesys_silent.ini

WORKDIR /source/lca/ip
RUN ./install.sh -s -fr /source/lca/ip/genesys_silent.ini -fl /source/lca/ip/genesys_install_result.log; cat /source/lca/ip/genesys_install_result.log

FROM mcr.microsoft.com/mssql/server:2017-latest

COPY --from=build-lca /gcti/lca /gcti/lca
COPY build/mssql/entrypoint.sh /entrypoint.sh
COPY script /gcti/script

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/opt/mssql/bin/sqlservr" ]
#TODO better permissions
#TODO Find a better way than running LCA in every container
