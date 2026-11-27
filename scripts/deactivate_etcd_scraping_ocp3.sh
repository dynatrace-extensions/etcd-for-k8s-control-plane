#!/bin/sh

kubectl delete configmap etcd-data -n kube-system
kubectl delete secret etcd-data -n kube-system
kubectl delete service dynatrace-monitoring-etcd-ocp3 -n kube-system
