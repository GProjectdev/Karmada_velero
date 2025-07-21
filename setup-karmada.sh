#!/bin/bash
set -e

echo "🚀 [시작] Karmada 설치 및 초기화 자동화 시작"

# 1. karmadactl 설치
echo "👉 karmadactl 설치 중..."
curl -s https://raw.githubusercontent.com/karmada-io/karmada/master/hack/install-cli.sh | sudo bash
echo "✅ karmadactl 설치 완료"

# 2. kubectl-karmada 설치
echo "👉 kubectl-karmada 설치 중..."
curl -s https://raw.githubusercontent.com/karmada-io/karmada/master/hack/install-cli.sh | sudo bash -s kubectl-karmada
echo "✅ kubectl-karmada 설치 완료"

# 3. 레포지토리 clone
echo "👉 Karmada GitHub 레포지토리 clone 중..."
git clone --branch master https://github.com/statlove/karmada.git
echo "✅ 레포지토리 clone 완료 (디렉토리: ./karmada)"

# 4. Karmada 초기화
echo "👉 kubectl karmada init 실행 중..."
kubectl karmada init
echo "✅ Karmada 초기화 완료"

echo "🎉 [완료] Karmada CLI 및 환경 구성이 완료되었습니다!"

