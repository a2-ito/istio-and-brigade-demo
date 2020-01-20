# SELinux

echo "#################################################################################"
echo "# Environment Values "
echo "#################################################################################"
if [ -e "/vagrant" ]; then
  MANIFESTS_DIR=/vagrant/manifests
else
  MANIFESTS_DIR=/tmp/manifests
fi

while true
do
	if [ ! -e "$MANIFESTS_DIR" ]; then
    echo waiting for manifests directory ...
    sleep 10
  else
    break
  fi
done

echo "#################################################################################"
echo "# k3s"
echo "#################################################################################"
sudo yum -d 1 -y install policycoreutils-python

#curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --bind-address 0.0.0.0

# audit-log-maxage=30 # days
# audit-log-maxsize=100 # megabytes
#--log /home/vagrant/k3s.log # default: /var/log/message

#curl -sfL https://get.k3s.io | sh -s - \
#curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v0.9.1 sh -

#curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v0.9.1 sh - 
sudo mkdir /var/log/kubernetes

#_ip=`gcloud compute instances list --format='get(networkInterfaces[0].accessConfigs[0].natIP)'`

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v0.9.1 sh -s - \
--no-deploy traefik \
--write-kubeconfig-mode 600 \
--data-dir=/app/var/lib/rancher/k3s \
--bind-address=0.0.0.0 \
--kube-apiserver-arg=audit-log-path=/var/log/k3saudit/audit.log \
--kube-apiserver-arg=audit-log-maxage=30 \
--kube-apiserver-arg=audit-log-maxbackup=10 \
--kube-apiserver-arg=audit-log-maxsize=100 \
--kube-apiserver-arg=log-dir=/var/log/kubernetes/ \
--kube-apiserver-arg=log-file=/var/log/kubernetes/kube-apiserver.log \
--kube-apiserver-arg=logtostderr=false \
--kube-scheduler-arg=log-dir=/var/log/kubernetes/ \
--kube-scheduler-arg=log-file=/var/log/kubernetes/kube-scheduler.log \
--kube-scheduler-arg=logtostderr=false \
--kube-controller-arg=log-dir=/var/log/kubernetes/ \
--kube-controller-arg=log-file=/var/log/kubernetes/kube-controller-manager.log \
--kube-controller-arg=logtostderr=false

#--kube-apiserver-arg=enable-admission-plugins=PodSecurityPolicy
#--kube-apiserver-arg=audit-policy-file=/vagrant/k8s-yamls/audit-policy.yaml \
#--kube-apiserver-arg=bind-address=0.0.0.0 \
#--kube-apiserver-arg=insecure-port=0 \
#--kube-apiserver-arg=profiling=false \
#--kube-apiserver-arg=kubelet-https=true \
#--kube-apiserver-arg=enable-admission-plugins=NamespaceLifecycle \
#--kube-apiserver-arg=audit-log-path=/var/log/apiserver/audit.log \
#--kube-apiserver-arg=audit-log-maxage=30 \
#--kube-apiserver-arg=audit-log-maxbackup=10 \
#--kube-apiserver-arg=audit-log-maxsize=100 \
#--kube-apiserver-arg=service-account-lookup=true \
#--kube-apiserver-arg=enable-admission-plugins=ServiceAccount,NodeRestriction \
#--kube-apiserver-arg=tls-min-version=VersionTLS12 \
#--kube-apiserver-arg=feature-gates=AllAlpha=false \
#--kube-scheduler-arg=profiling=false \
#--kube-scheduler-arg=address=127.0.0.1 \
#--kube-controller-arg=terminated-pod-gc-threshold=100 \
#--kube-controller-arg=profiling=false \
#--kube-controller-arg=use-service-account-credentials=true \
#--kube-controller-arg=feature-gates=RotateKubeletServerCertificate=true \
#--kube-controller-arg=address=127.0.0.1 \
#--kubelet-arg=address=127.0.0.1 \
#--kubelet-arg=anonymous-auth=false \
#--kubelet-arg=protect-kernel-defaults=true \
#--kubelet-arg=make-iptables-util-chains=true \
#--kubelet-arg=event-qps=0 \
#--kubelet-arg=feature-gates=RotateKubeletServerCertificate=true
#--no-deploy=traefik \
#--node-ip=127.0.0.1 \
#--kube-apiserver-arg=tls-cipher-suites="TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384" \
#--kubelet-arg=tls-cipher-suites="TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA34"

mkdir ~/.kube
sudo cp -p /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo cp -p /etc/rancher/k3s/k3s.yaml /tmp/kubeconfig
sudo chmod 766 /tmp/kubeconfig
sudo chown vagrant:vagrant ~/.kube/config

export KUBECONFIG=~/.kube/config
echo "export KUBECONFIG=~/.kube/onfig" >> /home/vagrant/.bashrc

echo "istio"
curl -L -s -S https://istio.io/downloadIstio | sh -
sudo cp -p istio-*/bin/istioctl /usr/local/bin/

kubectl get pod 
kubectl get node

echo "#################################################################################"
echo "# Deploy Istio"
echo "#################################################################################"
#/usr/local/bin/istioctl manifest apply --set profile=default
/usr/local/bin/istioctl manifest apply --set profile=demo

kubectl get pod -n istio-system

while true
do
  _status=`kubectl get pod -n istio-system | grep pilot | tail -n1 | awk '{print $3}'`
  if [ "${_status}" != "Running" ]; then
    echo current status : ${_status}
    sleep 10
  else
    echo current status : ${_status}
    break
  fi
done

kubectl apply -f istio-*/samples/httpbin/httpbin.yaml
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

echo $INGRESS_HOST
echo $INGRESS_PORT
echo $SECURE_INGRESS_PORT

kubectl apply -f $MANIFESTS_DIR/istio-gateway-sample.yaml
kubectl apply -f $MANIFESTS_DIR/istio-vs-sample.yaml

curl -I -HHost:httpbin.istio.k3s.local http://$INGRESS_HOST:$INGRESS_PORT/status/200

echo "# whoami"
kubectl apply -f $MANIFESTS_DIR/istio-whoami.yaml
curl -HHost:whoami.istio.k3s.local http://$INGRESS_HOST:$INGRESS_PORT/

#curl -I -HHost:prometheus.istio.k3s.local http://$INGRESS_HOST:$INGRESS_PORT/

#echo "# change port for http 80 -> 8022 on vagrant"
#kubectl patch svc istio-ingressgateway -n istio-system --type='json' \
#  -p='[{"op": "replace", "path": "/spec/ports/1/port", "value":8022}]'

echo "# prometheus"
kubectl apply -f $MANIFESTS_DIR/istio-gateway-prometheus.yaml
kubectl apply -f $MANIFESTS_DIR/istio-vs-prometheus.yaml

echo "# kiali"
kubectl apply -f $MANIFESTS_DIR/istio-kiali.yaml

echo "# tracing"
kubectl apply -f $MANIFESTS_DIR/istio-tracing.yaml

echo "# grafana"
kubectl apply -f $MANIFESTS_DIR/istio-grafana.yaml

echo "#################################################################################"
echo "# Deploy Bookinfo"
echo "#################################################################################"
kubectl label namespace default istio-injection=enabled
#kubectl label namespace default istio-injection=disabled
#kubectl apply -f <(istioctl kube-inject -f istio-*/samples/bookinfo/platform/kube/bookinfo.yaml)
kubectl apply -f $MANIFESTS_DIR/bookinfo.yaml
kubectl apply -f $MANIFESTS_DIR/bookinfo-gateway.yaml

#watch -n 1 curl -o /dev/null -s -w %{http_code} -HHost:bookinfo.istio.k3s.local http://10.0.2.15/productpage

#kubectl apply -f $MANIFESTS_DIR/reviews-v1-90-v2-10.yaml
#kubectl apply -f $MANIFESTS_DIR/reviews-all-versions.yaml
#kubectl apply -f $MANIFESTS_DIR/reviews-all-v2.yaml

# Demo - Sticky Session 1/2
# kubectl apply -f $MANIFESTS_DIR/demo-sticky-session-1-before.yaml
# curl -HHost:sticky-svc.istio.k3s.local -H "x-user: hoge" http://10.0.2.15/ping
# while true; do curl -s -H 'x-user: hoge' -HHost:sticky-svc.istio.k3s.local http://10.14.20.127:8022/ping; echo; sleep 1; done

# Demo - Sticky Session 2/2
# kubectl apply -f $MANIFESTS/demo-sticky-session-1-destinationrule.yaml

echo "# Install Helm"
#wget https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

echo "# install Brigade"
helm repo add brigade https://brigadecore.github.io/charts
helm install brigade brigade/brigade --set rbac.enabled=true

#sudo yum install -y git
#git clone https://github.com/chzbrgr71/kube-con-2017.git

kubectl create namespace microsmack
kubectl label namespace microsmack istio-injection=enabled

# First install the web front-end deployment/service
kubectl create -f kube-con-2017/web.yaml -n microsmack
# Then the headless service for our api
kubectl create -f kube-con-2017/api-svc.yaml -n microsmack

#echo "# Install Docker Registry"
#sudo yum install install -y docker
#sudo systemctl start docker
#sudo systemctl enable docker
#docker container run -d -p 5000:5000 --restart=always --name registry registry:2
#echo "# Test Docker Registry"
#docker image pull hello-world:latest
#docker image tag hello-world:latest localhost:5000/hello-world:latest
#docker push localhost:5000/hello-world:latest
#curl http://localhost:5000/v2/_catalog

pwd >> /tmp/bootstraped
#touch /tmp/bootstraped
exit 0

helm install --name kube-con-2017 brigade/brigade-project -f $MANIFESTS_DIR/brig-project.yaml


