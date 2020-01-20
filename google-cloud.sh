
echo "################################################################################"
echo "# bootstrap with Google Cloud"
echo "################################################################################"



gcloud config set compute/region australia-southeast1
gcloud config set compute/zone australia-southeast1-a

gcloud compute firewall-rules create default-allow-6443 \
   --allow tcp:6443 \
   --network default

gcloud compute firewall-rules create default-allow-http \
   --allow tcp:15000-15100 \
   --network default

gcloud compute firewall-rules create default-allow-brigade-7744 \
   --allow tcp:7744 \
   --network default

gcloud compute firewall-rules create default-allow-http-8080 \
   --allow tcp:8080 \
   --network default

echo "## Create Controllers VM"
gcloud compute instances create istio-demo \
  --async \
  --boot-disk-size 100GB \
  --can-ip-forward \
  --image-family centos-7 \
  --image-project centos-cloud \
  --machine-type n1-standard-1 \
  --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
  --tags kubernetes-the-hard-way,controller \
  --zone=australia-southeast1-a \
  --preemptible \
  --metadata-from-file startup-script=./bootstrap.sh

#  --image-family ubuntu-1804-lts \
#  --image-project ubuntu-os-cloud \

gcloud compute instances add-metadata istio-demo \
  --zone australia-southeast1-a \
  --metadata block-project-ssh-keys=FALSE

sleep 10

_ip=`gcloud compute instances list --format='get(networkInterfaces[0].accessConfigs[0].natIP)'`

scp -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' -r \
  ./manifests akihiko@${_ip}:/tmp/

sleep 60

rm -f ./kubeconfig
while true
do
  scp -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' \
    akihiko@${_ip}:/tmp/kubeconfig ./kubeconfig

	if [ ! -e "kubeconfig" ]; then
    echo current num of running :
    sleep 10
  else
    echo current num of running :
    break
  fi
done

sed -i s/0.0.0.0/${_ip}/g kubeconfig

echo "ssh -i ~/.ssh/keys/id_rsa -o 'StrictHostKeyChecking no' akihiko@${_ip}"
exit 0 

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

