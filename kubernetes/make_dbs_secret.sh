#!/bin/bash
if [ $# != 7 ]; then
    echo "make_dbs_secret.sh <proxy> <server.key> <server.crt> <dbsconfig.json> <dbfile> <dbssecrets> <hmac>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $2 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $3 | base64 | awk '{ORS=""; print $0}'`
conf=`cat $4 | base64 | awk '{ORS=""; print $0}'`
dbfile=`cat $5 | base64 | awk '{ORS=""; print $0}'`
dbssecrets=`cat $6 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $7 | base64 | awk '{ORS=""; print $0}'`
cat > dbs-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
  server.crt: $cert
  server.key: $skey
  dbfile: $dbfile
  dbsconfig.json: $conf
  DBSSecrets.py: $dbssecrets
  hmac: $hmac
kind: Secret
metadata:
  name: dbs-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/dbs-secrets
type: Opaque
EOF
