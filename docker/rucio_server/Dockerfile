# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Cedric Serfon, <cedric.serfon@cern.ch>, 2017
# - Igor Mandrichenko, <ivm@fnal.gov>, 2018
# - Eric Vaandering, <ewv@fnal.gov>, 2018
# - Natalia Ratnikova, <natasha@fnal.gov>, 2018

FROM rucio/rucio-systemd-cc7

RUN yum -y update && \
    yum install -y fts-client globus-proxy-utils voms-clients-cpp && \
    yum install -y nano mlocate && \
    yum clean all && \
    rm -rf /var/cache/yum

ENV container docker

RUN pip install --upgrade pip
RUN pip install --upgrade setuptools
RUN pip install -I rucio rucio-webui

ADD ui-aliases-py27.conf /opt/rucio/etc/web/
RUN chmod 644 /opt/rucio/etc/web/ui-aliases-py27.conf

# Needs to be here because of meld3 conflict
RUN yum install -y less supervisor cronie && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN systemctl enable crond.service

RUN rm /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/zgridsite.conf /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/userdir.conf

RUN mkdir -p /var/log/rucio/trace && mkdir -p /opt/rucio/etc/web

RUN cp -R /usr/rucio/tools /opt/rucio

### the rest of commands from Cedric's UI Dockerfile: 
## Set the working directory to /app
#WORKDIR /tmp

## Copy the current directory contents into the container at /app
#ADD . /tmp

#RUN pip install rucio_webui

#RUN cp rucio.conf /etc/httpd/conf.d/rucio.conf; \
#    cp httpd.conf /etc/httpd/conf/httpd.conf; \
#    rm /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/zgridsite.conf /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/userdir.conf

#VOLUME /var/log/httpd

#RUN systemctl enable httpd.service
#EXPOSE 443
#CMD ["/usr/sbin/init"]

