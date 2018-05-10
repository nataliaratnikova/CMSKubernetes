#!/bin/bash
# obtain CERN CAs if they're not present
#n=`ls /etc/pki/tls/private/*.key 2> /dev/null | wc -c`
#if [ "$n" -eq "0" ]; then
#    sudo /usr/sbin/cern-get-certificate --autoenroll
#    ckey=`ls /etc/pki/tls/private/*.key | tail -1`
#    host=`basename $ckey | sed -e "s,.key,,g"`
#    cert=`ls /etc/pki/tls/certs/$host.pem`
#    sudo cp $ckey /data/certs/hostkey.pem
#    sudo cp $cert /data/certs/hostcert.pem
#fi
if [ -f /etc/grid-security/hostkey.pem ]; then
    # overwrite host PEM files in /data/certs since we used them during installation time
    sudo cp /etc/grid-security/hostkey.pem /data/certs/
    sudo cp /etc/grid-security/hostcert.pem /data/certs/
fi
# obtain original voms-gridmap to be used by frontend
if [ -f /etc/secrets/proxy ] && [ -f /data/srv/current/config/frontend/mkvomsmap ]; then
    /data/srv/current/config/frontend/mkvomsmap \
        --key /etc/secrets/proxy --cert /etc/secrets/proxy \
        -c /data/srv/current/config/frontend/mkgridmap.conf \
        -o /data/srv/state/frontend/etc/voms-gridmap.txt --vo cms
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    sudo rm /data/srv/state/frontend/etc/keys/authz-headers
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/state/frontend/etc/keys/authz-headers
fi

# run frontend server
/data/cfg/admin/InstallDev -s start
ps auxw | grep httpd

# start infinitive loop to show that we run the service
# since we're dealing with logs rotation we'll inspect them manually
while true
do
    sleep 10
done
