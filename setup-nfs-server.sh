#!/bin/bash
set -e

echo "🚀 [시작] NFS 서버 설정 자동화 시작"

# 1. NFS 서버 패키지 설치
echo "👉 NFS 서버 패키지 설치 중..."
apt update
apt install -y nfs-kernel-server
echo "✅ NFS 서버 패키지 설치 완료"

# 2. 공유 디렉토리 생성
echo "👉 공유 디렉토리 생성 중..."
mkdir -p /mnt/nfs
chmod 777 /mnt/nfs
echo "✅ 공유 디렉토리 생성 완료 (/mnt/nfs)"

# 3. /etc/exports 설정
echo "👉 /etc/exports 설정 중..."
NFS_RULE="/mnt/nfs 192.168.40.0/24(rw,sync,no_subtree_check,no_root_squash)"

# 중복 방지 후 추가
grep -qxF "$NFS_RULE" /etc/exports || echo "$NFS_RULE" >> /etc/exports
echo "✅ /etc/exports 설정 완료"

# 4. exportfs 적용 및 서비스 재시작
echo "👉 exportfs 적용 및 NFS 서비스 재시작 중..."
exportfs -a
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server
echo "✅ NFS 서비스 재시작 및 활성화 완료"

echo "🎉 [완료] NFS 서버가 성공적으로 설정되었습니다!"
echo "📌 공유 디렉토리: /mnt/nfs"
echo "📌 허용 클라이언트: 192.168.40.0/24"
