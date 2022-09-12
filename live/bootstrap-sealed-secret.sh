#!/bin/bash

# Check Deploy Repositroy Path
SO1S_REGEX="^(.+)\/([^\/]+)$"
while [[ ! $SO1S_DEPLOY_REPO_PATH =~ $SO1S_REGEX ]]
do
  echo -e "Deploy Repository 경로를 입력 해주세요."
  read SO1S_DEPLOY_REPO_PATH
done

echo -e "\n\n"
echo "Inject Sealed Secret Certificate"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml --wait
kubectl rollout restart deployment -n sealed-secrets so1s-sealed-secrets
# IMAGE PULL ERROR난 backend deployment의 Replicas를 지우고 다시 생성한다.
echo "Wait for Sealed-Secret to be created"
sleep 10
DEPLOYMENT_NAME=`kubectl get deployment -n backend | grep so1s | cut -d ' ' -f1`
kubectl rollout restart deployment -n backend $DEPLOYMENT_NAME 