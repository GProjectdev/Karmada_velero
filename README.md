# Karmada-Velero
- scripts using karmada and velero
- 다음 환경은 Push 모드로 구성한다.

**다음 스크립트 파일은 root 계정으로 실행해야 한다.(환경 구성을 root 게정으로 시행)**
```
sudo su -
```

## Kubernetes Cluster 만들기
기본적으로 mamagement cluster 및 member-cluster
다음 링크 참조 [Kubernetes_Installer_with_CRIO](https://github.com/GProjectdev/Kubernetes_Installer_with_CRIO.git)

## Karmada 환경 구축
### Karamda management cluster구성
```
git clone https://github.com/GProjectdev/Karmada_velero.git
chmod +x Karmada_velero/setup-karmada.sh
sudo ./Karmada_velero/setup-karmada.sh
```

### member clsuter 등록
- 각 member cluster에서 다음 명령을 시행(해당 값을 복사)
```
kubectl config view --raw --flatten > <MEMBER_CLUSTER_NAME>.kubeconfig
cat <MEMBER_CLUSTER_NAME>.kubeconfig
```
- Management cluster에서 동일한 파일을 만들고 각 member cluster 등록
```
kubectl karmada --kubeconfig /etc/karmada/karmada-apiserver.config  join <CLUSTER_NAME> --cluster-kubeconfig=<MEMBER_CLUSTER_NAME>.kubeconfig
```
- 등록 취소시
```
kubectl karmada --kubeconfig /etc/karmada/karmada-apiserver.config unjoin <MEMBER_CLUSTER_NAME>
```

## kubectl로 karmada api server에게 명령할 수 있게 설정
```
export KUBECONFIG=/etc/karmada/karmada-apiserver.config
```
- 이후 기존 kubernetes api server를 가리키기 위해선 다음을 사용
```
kubectl --kubeconfig /etc/kubernetes/admin.conf ...
or
kubectl --kubeconfig /root/.kube/config ...
```

## Velero 환경 구성

### Minio설치
```
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
export MINIO_ROOT_USER=minio
export MINIO_ROOT_PASSWORD=minio123
./minio server /data --console-address="{SERVER_EXTERNAL_IP}:20001" --address="{SERVER_EXTERNAL_IP}:9000"
```
- 이후 {SERVER_EXTERNAL_IP}:20001 에 접속하여 bucket 생성

### Velero 설치
**각 멤버클러스터에 CLI 설치**
```
wget https://github.com/vmware-tanzu/velero/releases/download/v1.16.0/velero-v1.16.0-linux-amd64.tar.gz
tar -zxvf velero-v1.16.0-linux-amd64.tar.gz
cp velero-v1.16.0-linux-amd64/velero /usr/local/bin/
```
**Minio를 사용하기 위한 credential 파일 작성**
```
vi credentials-velero
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
```

**이후 Velero 설치(File System Backup을 위한 Node Agent Daemonset추가)**
```
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.2.1 \
  --bucket velero \
  --secret-file ./credentials-velero \
  --use-node-agent \
  --use-volume-snapshots=false \
  --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://{SERVER_EXTERNAL_IP}:9000
```

## NFS 구성
각 Cluster에 사용할 스토리지를 NFS를 이용한다.

### NFS 서버 구성
```
chmod +x Karmada_velero/setup-nfs-server.sh
sudo ./Karmada_velero/setup-nfs-server.sh
```

### 각 서버에 NFS-provisioner 설치(Helm 이용)
1. NFS-common 설치
```
sudo apt-get install -y nfs-common
```
2. Helm 설치
```
sudo apt-get update  
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add - 
sudo apt-get install apt-transport-https --yes 
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list 
sudo apt-get update 
sudo apt-get install helm
```
3. Namespace 생성
```
kubectl create namespace nfs-provisioner
```
4. Helm을 이용한 NFS-provisioner 구성
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update 
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--set nfs.server={NFS_SERVER} \
--set nfs.path=/mnt/nfs \
--set storageClass.defaultClass=true \
--set storageClass.reclaimPolicy=Retain
```
