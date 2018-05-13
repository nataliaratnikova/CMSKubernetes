#!/bin/bash

host=`openstack --os-project-name "CMS Webtools Mig" coe cluster show k8s | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"
echo "generate hmac secret"
hmac=$PWD/hmac.random
perl -e 'open(R, "< /dev/urandom") or die; sysread(R, $K, 20) or die; print $K' > $hmac

pkgs="das dbs ing frontend couchdb reqmgr httpsgo exporters reqmon workqueue"

echo "### secrets"
for p in $pkgs; do
    kubectl delete secret/${p}-secrets
done
kubectl -n kube-system delete secret/traefik-cert
kubectl -n kube-system delete configmap traefik-conf

sleep 2

echo "create new proxy which we'll use for deployment"
myproxy-init -x -c 720 -t 36 -s myproxy.cern.ch -R '*/CN=cmsweb-k8s.web.cern.ch' -l cmsweb_k8s_sw
echo "run voms-proxy-init"
voms-proxy-init -voms cms -rfc -valid 36:00
voms_file="/tmp/x509up_u`id -u`"
dbsconfig=dbsconfig.json
dasconfig=dasconfig.json
httpsgoconfig=httpsgoconfig.json
user_crt=/afs/cern.ch/user/v/valya/.globus/usercert.pem
server_key=/afs/cern.ch/user/v/valya/private/certificates/server.key
server_crt=/afs/cern.ch/user/v/valya/private/certificates/server.crt
dbfile=/afs/cern.ch/user/v/valya/private/dbfile
dbssecrets=/afs/cern.ch/user/v/valya/private/DBSSecrets.py
./make_das_secret.sh $voms_file $server_key $server_crt $dasconfig $hmac
./make_dbs_secret.sh $voms_file $server_key $server_crt $dbsconfig $dbfile $dbssecrets $hmac
./make_ing_secret.sh $server_key $server_crt
./make_frontend_secret.sh $voms_file $hmac
./make_couchdb_secret.sh $voms_file $hmac
./make_reqmgr_secret.sh $voms_file $hmac
./make_reqmon_secret.sh $voms_file $hmac
./make_workqueue_secret.sh $voms_file $hmac
./make_exporters_secret.sh $voms_file
./make_httpsgo_secret.sh $httpsgoconfig

echo "### apply secrets"
for p in $pkgs; do
    kubectl apply -f ${p}-secrets.yaml --validate=false
done
rm *secrets.yaml $hmac

sleep 2

kubectl get secrets
kubectl -n kube-system get secrets
kubectl -n kube-system get configmap

echo
echo "### label node"
clsname=`kubectl get nodes | tail -1 | awk '{print $1}'`
kubectl label node $clsname role=ingress --overwrite
kubectl get node -l role=ingress

echo
echo "### delete services"
for p in $pkgs; do
    if [ -f ${p}.yaml ]; then
        kubectl delete -f ${p}.yaml
    fi
done
kubectl delete -f httpgo.yaml
kubectl delete -f das2go.yaml
kubectl delete -f dbs2go.yaml

sleep 2

echo
echo "### deploy services"
for p in $pkgs; do
    if [ -f ${p}.yaml ]; then
        kubectl apply -f ${p}.yaml --validate=false
    fi
done
kubectl apply -f httpgo.yaml --validate=false
kubectl apply -f das2go.yaml --validate=false
kubectl apply -f dbs2go.yaml --validate=false

sleep 2
echo
echo "### delete daemon ingress-traefik"
kubectl delete daemonset ingress-traefik -n kube-system
sleep 2
echo "### deploy traefik"
kubectl -n kube-system create secret generic traefik-cert --from-file=$server_crt --from-file=$server_key
kubectl -n kube-system create configmap traefik-conf --from-file=traefik.toml
kubectl -n kube-system apply -f traefik.yaml --validate=false

echo "deploy prometheus: https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/"
sleep 2

kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-service.yaml
kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-deployment.yaml
kubectl -n monitoring delete -f kubernetes-prometheus/config-map.yaml

kubectl create namespace monitoring
kubectl -n monitoring apply -f kubernetes-prometheus/config-map.yaml --validate=false
kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-deployment.yaml --validate=false
kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-service.yaml --validate=false
kubectl -n monitoring get deployments
kubectl -n monitoring get pods
prom=`kubectl -n monitoring get pods | grep prom | awk '{print $1}'`
echo "### we may access prometheus locally as following"
echo "kubectl -n monitoring port-forward $prom 8080:9090"
echo "### to access prometheus externally we should do the following:"
echo "ssh -S none -L 30000:$kubehost:30000 $USER@lxplus.cern.ch"
