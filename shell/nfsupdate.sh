#!/bin/bash

# 新的 NFS 服务器 IP 地址
NEW_NFS_SERVER_IP="new-nfs-server-ip"

# 更新 PV
for pv in $(kubectl get pv -o jsonpath='{.items[*].metadata.name}'); do
    echo "Updating PV: $pv"
    kubectl patch pv $pv --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/nfs/server\", \"value\": \"$NEW_NFS_SERVER_IP\"}]"
done

# 更新 PVC
for pvc in $(kubectl get pvc --all-namespaces -o jsonpath='{.items[*].metadata.name}'); do
    namespace=$(kubectl get pvc $pvc -o jsonpath='{.metadata.namespace}')
    echo "Updating PVC: $pvc in namespace: $namespace"
    kubectl patch pvc $pvc -n $namespace --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/storageClassName\", \"value\": \"nfs-csi\"}]"
done
