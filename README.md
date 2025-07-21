# Karmada_velero
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
chmod +x setup-karmada.sh
sudo ./setup-karmada.sh
```

### member clsuter 등록
각 member cluster에서 다음 명령을 시행(해당 값을 복사)
```
kubectl config view --raw --flatten > <MEMBER_CLUSTER_NAME>.kubeconfig
cat <MEMBER_CLUSTER_NAME>.kubeconfig
```
Management cluster에서 동일한 파일을 만들고 각 member cluster 등록
```
kubectl karmada --kubeconfig /etc/karmada/karmada-apiserver.config  join <CLUSTER_NAME> --cluster-kubeconfig=<MEMBER_CLUSTER_NAME>.kubeconfig
```
등록 취소시
```
kubectl karmada --kubeconfig /etc/karmada/karmada-apiserver.config unjoin <MEMBER_CLUSTER_NAME>
```

## kubectl로 karmada api server에게 명령할 수 있게 설정
```
export KUBECONFIG=/etc/karmada/karmada-apiserver.config
```
이후 기존 kubernetes api server를 가리키기 위해선 다음을 사용
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

### Velero 설치
**각 멤버클러스터에 CLI 설치**
```
wget https://github.com/vmware-tanzu/velero/releases/download/v1.7.0/velero-v1.7.0-linux-amd64.tar.gz
tar -zxvf velero-v1.7.0-linux-amd64.tar.gz
cp velero-v1.7.0-linux-amd64/velero /usr/local/bin/
```
**Minio를 사용하기 위한 credential 파일 작성**
```
vi credentials-velero
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
```

**이후 Velero 설치**
```
velero install \
--provider aws \
--plugins velero/velero-plugin-for-aws:v1.2.1 \
--bucket velero \
--secret-file ./credentials-velero \
--use-volume-snapshots=false \
--backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://{SERVER_EXTERNAL_IP}:9000
```
