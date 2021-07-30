# Specify the opensciencegrid/software-base image tag
ARG BASE_YUM_REPO=testing

FROM opensciencegrid/software-base:3.5-el8-$BASE_YUM_REPO

LABEL maintainer OSG Software <help@opensciencegrid.org>

# Create the squid user with a fixed GID/UID; do this first, so that the Squid
# install does not do it.  Then do the installs.  All one instruction to reduce
# image size, etc.
RUN groupadd -o -g 10941 squid && \
    useradd -o -u 10941 -g 10941 -s /sbin/nologin -d /var/lib/squid squid && \
    yum update -y && \
    yum install -y
                --disablerepo=osg-upcoming \
                --disablerepo=osg-upcoming-testing \
                --disablerepo=osg-upcoming-development \
                frontier-squid && \
    rm -rf /var/cache/yum/* && \
    mkdir /etc/squid/customize.d

RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch && \
    > /etc/yum.repos.d/elastic-7.x.repo \
        printf "%s\n" \
        "[elastic-7.x]" \
        "name=Elastic repository for 7.x packages" \
        "baseurl=https://artifacts.elastic.co/packages/7.x/yum" \
        "gpgcheck=1" \
        "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
        "enabled=1" \
        "autorefresh=1" \
        "type=rpm-md" && \
    yum install -y
                --disablerepo=osg-upcoming \
                --disablerepo=osg-upcoming-testing \
                --disablerepo=osg-upcoming-development \
                filebeat && \
    rm -rf /var/cache/yum/*

COPY 60-image-post-init.sh /etc/osg/image-config.d/60-image-post-init.sh
COPY start-frontier-squid.sh /usr/sbin/
COPY squid-customize.sh /etc/squid/customize.sh
COPY customize.d/* /etc/squid/customize.d/
COPY supervisor-frontier-squid.conf /etc/supervisord.d/40-frontier-squid.conf

EXPOSE 3128

# These env variables can be changed in the container instance
# Set default values which should reflect what is in the RPM
ENV SQUID_IPRANGE="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 fc00::/7 fe80::/10"
ENV SQUID_CACHE_MEM="128 MB"
ENV SQUID_CACHE_DISK="10000"
ENV SQUID_CACHE_DISK_LOCATION="/var/cache/squid"
