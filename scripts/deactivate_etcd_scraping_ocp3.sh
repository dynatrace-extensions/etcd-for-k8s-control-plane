#!/bin/sh

kubectl delete configmap etcd-data -n dynatrace
kubectl delete secret etcd-data -n dynatrace
kubectl delete service dynatrace-monitoring-etcd-ocp3 -n kube-system
