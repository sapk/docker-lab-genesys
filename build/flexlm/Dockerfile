FROM centos as build-lca
ARG  LCA_VERSION=8510029b1_ENU
#Add 32 bit support to centos (Needed for install script)
RUN yum install -y glibc.i686 && yum clean all && rm -rf /var/cache/yum

ADD source/IP_LCA_${LCA_VERSION}_linux.tar.gz /source/lca

COPY build/lca/genesys_silent.ini  /source/lca/ip/genesys_silent.ini

WORKDIR /source/lca/ip
RUN ./install.sh -s -fr /source/lca/ip/genesys_silent.ini -fl /source/lca/ip/genesys_install_result.log; cat /source/lca/ip/genesys_install_result.log

FROM centos
#RUN yum update -y \
# && yum install -y glibc.i686 redhat-lsb-core redhat-lsb.i686-core libgcc_s.so.1 \
# && yum clean all && rm -rf /var/cache/yum
RUN yum install -y glibc.i686 redhat-lsb-core redhat-lsb.i686-core libgcc libgcc_s.so.1 glibc \
 && yum clean all && rm -rf /var/cache/yum

RUN ln -s /lib/ld-linux.so.2 /lib/ld-lsb.so.3

COPY --from=build-lca /gcti/lca /gcti/lca
COPY build/flexlm/entrypoint.sh /entrypoint.sh

COPY script /gcti/script

ADD source/lmgr11.13-i686-linux-rhe4.tar /gcti/flexlm
RUN chown -R nobody:nobody /gcti/flexlm /gcti/lca
WORKDIR /gcti/flexlm

USER nobody

ENTRYPOINT ["/entrypoint.sh"]
#CMD ["su", "nobody", "-c", "./lmgrd", "-c", "/gcti/flexlm/license.dat"]
CMD ["./lmgrd", "-z", "-c", "/gcti/flexlm/license.dat"]
EXPOSE 7260/tcp
#TODO setup port for genesys.d