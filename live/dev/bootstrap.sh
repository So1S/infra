#!/bin/bash

# terraform existing check
if [ terraform != 0 ]; then
  echo "Your Terraform Version -> " `terraform version | head -n 1`
fi

# terraform variables check
if [ -z $SO1S_GLOBAL_NAME ]; then
  echo "Please Set global name using command 'export SO1S_GlOBAL_NAME=<GLOBAL_NAME>'"
  exit 1
else
  echo "Complete Check global_name Variable -> $SO1S_GLOBAL_NAME"
fi

# Check Deploy Repositroy Path
if [ -z $SO1S_DEPLOY_REPO_PATH ]; then
  echo "Please Set Deploy Repository Path using command 'export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>'"
  exit 1
else
  echo "Complete Check DEPLOY_REPO_PATH Variable -> $SO1S_DEPLOY_REPO_PATH"
fi

terraform apply -var="global_name=$SO1S_GLOBAL_NAME"

echo -e "\n\n\n"

echo "Update KubeConfig"
echo "-> aws eks update-kubeconfig --region "ap-northeast-2" --name "$SO1S_GLOBAL_NAME-so1s-dev" --alias $SO1S_GLOBAL_NAME"
aws eks update-kubeconfig --region "ap-northeast-2" --name "$SO1S_GLOBAL_NAME-so1s-dev" --alias $SO1S_GLOBAL_NAME

echo -e "\n\n\n"

# helm existing check
if [ helm != 0 ]; then
  echo "Your Helm Version -> " `helm version --short | head -n 1`
fi

# install argocd 
echo -e "\n\n\n"
echo "Install ArgoCD"
echo "-> helm install argocd -n argocd -f $SO1S_DEPLOY_REPO_PATH/charts/argocd/argocd-dev-values.yaml argo/argo-cd --create-namespace --wait"
helm install argocd -n argocd -f $SO1S_DEPLOY_REPO_PATH/charts/argocd/argocd-dev-values.yaml argo/argo-cd --create-namespace --wait
echo "ArgoCD Password -> " `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

# create argocd project resource
echo -e "\n\n\n"
echo "Create ArgoCD Project Resource"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/project/project-dev.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/project/project-dev.yaml 

# create sealed secrets !!!!!! backend namespace setting
echo -e "\n\n\n"
echo "Create Sealed Secret"
kubectl create secret generic application-secret --dry-run=client --from-env-file=$SO1S_DEPLOY_REPO_PATH/secrets.env -o json > $SO1S_DEPLOY_REPO_PATH/secrets.json
kubeseal --controller-name so1s-sealed-secrets --controller-namespace sealed-secrets --scope cluster-wide -o yaml < $SO1S_DEPLOY_REPO_PATH/secrets.json > $SO1S_DEPLOY_REPO_PATH/sealed-secret.yaml

kubectl create secret docker-registry so1s --dry-run=client --from-file=.dockerconfigjson=$SO1S_DEPLOY_REPO_PATH/docker-config.json -o json > $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.json
kubeseal --controller-name so1s-sealed-secrets --controller-namespace sealed-secrets --scope cluster-wide -o yaml < $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.json > $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.yaml

kubectl apply -f $SO1S_DEPLOY_REPO_PATH/sealed-secret.yaml -n backend
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.yaml -n backend

# run root application
echo -e "\n\n\n"
echo "Run root-dev.yaml application"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/root-dev.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/root-dev.yaml