#!/bin/bash
echo "################################################################################"
echo "# bootstrap with Google Cloud"
echo "################################################################################"

CMDNAME=`basename $0`

while getopts u:p OPT
do
  case $OPT in
    "u" ) FLG_U="true" ; VALUE_U="$OPTARG" ;;
    "p" ) FLG_UPDATE="true" ;;
     *  ) echo "Usage: $CMDNAME [-u USER] [-p]" 1>&2
          exit 1 ;;
  esac
done

if [ "$FLG_U" = true ]; then
  SSH_USER=${VALUE_U}
else
  SSH_USER=a2-ito
fi
echo SSH_USER: $SSH_USER

_ip=`curl -sS inet-ip.info`
#echo ${_ip}

gcloud config set compute/region australia-southeast1
gcloud config set compute/zone australia-southeast1-a

_num=`gcloud compute firewall-rules list 2>/dev/null | grep default-allow-6443 | wc -l`
if [ ${_num} -ne 1 ] || [ "$FLG_UPDATE" = true ]; then
  gcloud compute firewall-rules delete default-allow-6443 --quiet
	gcloud compute firewall-rules create default-allow-6443 \
    --allow tcp:6443 \
    --source-ranges ${_ip}/32 \
    --network default
fi

_num=`gcloud compute firewall-rules list 2>/dev/null | grep default-allow-http | wc -l`
if [ ${_num} -ne 1 ] || [ "$FLG_UPDATE" = true ]; then
  gcloud compute firewall-rules delete default-allow-http --quiet
  gcloud compute firewall-rules create default-allow-http \
    --allow tcp:30000-31000,tcp:15000-15100,tcp:80,tcp:8080 \
    --network default
fi

_num=`gcloud compute firewall-rules list 2>/dev/null | grep default-allow-brigade | wc -l`
if [ ${_num} -ne 1 ] || [ "$FLG_UPDATE" = true ]; then
  gcloud compute firewall-rules delete default-allow-brigade --quiet
  gcloud compute firewall-rules create default-allow-brigade \
    --allow tcp:7744,tcp:7745 \
    --network default
fi

_num=`gcloud compute firewall-rules list 2>/dev/null | grep default-allow-ssh | wc -l`
if [ ${_num} -ne 1 ] || [ "$FLG_UPDATE" = true ]; then
  gcloud compute firewall-rules delete default-allow-ssh --quiet
	gcloud compute firewall-rules create default-allow-ssh \
    --allow tcp:22 \
    --source-ranges ${_ip}/32 \
    --network default
fi

echo "## Create Controllers VM"
_num=`gcloud compute instances list | grep istio-demo | wc -l`
if [ ${_num} -eq 1 ]; then
  gcloud compute instances delete istio-demo --quiet
	sleep 10
fi

gcloud container clusters create istio-demo-cluster \
  --zone australia-southeast1-a \
  --disk-size 100GB \
  --machine-type n1-standard-2 \
  --num-nodes=2 \
	--preemptible 

gcloud container clusters get-credentials istio-demo-cluster \
	--zone australia-southeast1-a \
	--project a2-ito-private-project

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding \
	tiller-cluster-rule \
	--clusterrole=cluster-admin \
	--serviceaccount=kube-system:tiller

helm init --service-account=tiller --upgrade

kubectl create clusterrolebinding \
	brigade-worker-cluster-rule \
	--clusterrole=cluster-admin \
	--serviceaccount=default:brigade-worker

sleep 20

kubectl patch deploy \
	--namespace kube-system tiller-deploy \
	-p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

# Install Brigade
helm repo add brigade https://brigadecore.github.io/charts

sleep 20

helm install -n brigade brigade/brigade \
	--set brigade.rbac.enabled=ture \
	--set brigade-github-app.enabled=ture \
	--set brigade-github-app.service.type=LoadBalancer \
	--set kashti.service.type=LoadBalancer \
	-f brigade-values.yaml

helm install -n brigade-project brigade/brigade-project \
	-f manifests/brigade-project-values.yaml

# Install Istio
istioctl manifest apply --set profile=demo

# Install sample app
kubectl create namespace microsmack
kubectl label namespace microsmack istio-injection=enabled

kubectl create -f kube-con-2017-ito/web.yaml -n microsmack
kubectl create -f kube-con-2017-ito/api-svc.yaml -n microsmack
#kubectl create -f kube-con-2017-ito/api.yaml -n microsmack

helm install -n smackapi-prod ./kube-con-2017-ito/charts/smackapi --namespace microsmack \
    			  --set api.image=a2ito/smackapi --set api.imageTag=master-d8c088f \
					  --set api.deployment=smackapi-prod --set api.versionLabel=prod

helm install -n smackapi-new ./kube-con-2017-ito/charts/smackapi --namespace microsmack \
  				  --set api.image=a2ito/smackapi --set api.imageTag=master-d8c088f \
					  --set api.deployment=smackapi-new --set api.versionLabel=new

helm install -n microsmack-routes ./kube-con-2017-ito/charts/routes --namespace microsmack \
  				  --set prodLabel=prod --set prodWeight=90 --set canaryLabel=new --set canaryWeight=10

if [ -n "${DOCKER_USERNAME}" ] && [ -n "${DOCKER_PASSWORD}" ]; then
  kubectl create secret docker-registry regcred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=${DOCKER_USERNAME} \
  	--docker-password=${DOCKER_PASSWORD} \
    --docker-email=hi.mound@gmail.com
fi

echo;
echo kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=[docker-username] \
	--docker-password=[docker-password] \
  --docker-email=hi.mound@gmail.com
echo;

kubectl get svc -n microsmack -w

