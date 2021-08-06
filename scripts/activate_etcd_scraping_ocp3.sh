#!/bin/sh

#See: https://docs.openshift.com/container-platform/3.11/install_config/prometheus_cluster_monitoring.html#configuring-etcd-monitoring_prometheus-cluster-monitoring

set -e

ETCD_CRT=etcd.crt
ETCD_KEY=etcd.key
ETCD_CSR=etcd.csr
CA_CRT=ca.crt
CA_KEY=ca.key
CONFIG=openssl.cnf


#Copy ca cert/key to local file, needed for secret creation
echo "$(kubectl exec -it $(kubectl get pod -l "openshift.io/component=etcd" -n kube-system -o name | head -n 1) -n kube-system -- cat /etc/etcd/ca/ca.crt)" > $CA_CRT
echo "$(kubectl exec -it $(kubectl get pod -l "openshift.io/component=etcd" -n kube-system -o name | head -n 1) -n kube-system -- cat /etc/etcd/ca/ca.key)" > $CA_KEY

#OpenSSL config
echo "[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, keyEncipherment, digitalSignature
extendedKeyUsage=serverAuth, clientAuth" > $CONFIG

#Generate new keys
openssl genrsa -out $ETCD_KEY 2048
openssl req -new -key $ETCD_KEY -out $ETCD_CSR -subj "/CN=dynatrace-etcd-monitoring" -config $CONFIG
openssl x509 -req -in $ETCD_CSR -CA $CA_CRT -CAkey $CA_KEY -CAcreateserial -out $ETCD_CRT -days 365 -extensions v3_req -extfile $CONFIG

#Write to K8s secret
kubectl create secret tls etcd-data --cert=$ETCD_CRT --key=$ETCD_KEY -n dynatrace
#Create configmap for ca.crt
kubectl create configmap etcd-data -n dynatrace --from-file=ca.crt=$CA_CRT

#Cleanup local files
rm $ETCD_CRT $ETCD_KEY $ETCD_CSR $CA_CRT $CA_KEY $CONFIG

#Create annotated service
kubectl apply -f ./dynatrace-monitoring-etcd-ocp3-service.yaml


