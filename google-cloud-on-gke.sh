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
  --machine-type n1-standard-1 \
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

sleep 20

kubectl patch deploy \
	--namespace kube-system tiller-deploy \
	-p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'


helm repo add brigade https://brigadecore.github.io/charts

kubectl create namespace microsmack
kubectl create -f kube-con-2017/web.yaml -n microsmack
kubectl create -f kube-con-2017/api-svc.yaml -n microsmack

exit 0

helm install -n brigade brigade/brigade \
	-f brigade-values.yaml \
	--set brigade-github-app.enabled=ture \
	--t brigade-github-app.service.type=LoadBalancer

sleep 30

_ip=`gcloud compute instances list --format='get(networkInterfaces[0].accessConfigs[0].natIP)'`

echo "scp -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' -r ./manifests ${SSH_USER}@${_ip}:/tmp/"
scp -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' -r \
  ./manifests ${SSH_USER}@${_ip}:/tmp/

echo "ssh -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' ${SSH_USER}@${_ip}"
exit 0 

sleep 60

rm -f ./kubeconfig
while true
do
  scp -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' \
    ${SSH_USER}@${_ip}:/tmp/kubeconfig ./kubeconfig

	if [ ! -e "kubeconfig" ]; then
    echo waiting for k3s ...
    sleep 10
  else
    break
  fi
done

sed -i s/0.0.0.0/${_ip}/g kubeconfig

echo "## Create Workers VM"
#for i in 1 2 3; do
#  gcloud compute instances create worker-${i} \
#    --async \
#    --boot-disk-size 100GB \
#    --can-ip-forward \
#    --image-family ubuntu-1804-lts \
#    --image-project ubuntu-os-cloud \
#    --machine-type n1-standard-1 \
#    --metadata pod-cidr=10.200.${i}.0/24 \
#    --private-network-ip 10.240.${i}.11 \
#    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
#    --subnet subnet-worker-${i} \
#    --tags kubernetes-the-hard-way,worker \
#    --network-interface=no-address \
#    --no-address \
#    --preemptible
#done

echo "## Configure SSH keys"
for i in 1 2 3; do
#  gcloud compute instances add-metadata worker-${i} \
#    --zone australia-southeast1-a \
#    --metadata block-project-ssh-keys=FALSE
  gcloud compute instances add-metadata master-${i} \
    --zone australia-southeast1-a \
    --metadata block-project-ssh-keys=FALSE
done
