# SELinux

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
sudo cp -p /etc/rancher/k3s/k3s.yaml ~/.kube/kubeconfig
sudo chown vagrant:vagrant ~/.kube/kubeconfig

export KUBECONFIG=~/.kube/kubeconfig
echo "export KUBECONFIG=~/.kube/kubeconfig" >> /home/vagrant/.bashrc

echo "istio"
curl -L -s -S https://istio.io/downloadIstio | sh -
sudo cp -p istio-*/bin/istioctl /usr/local/bin/

kubectl get pod 
kubectl get node
/usr/local/bin/istioctl manifest apply --set profile=default

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

echo "demo"
kubectl apply -f istio-*/samples/httpbin/httpbin.yaml
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

echo $INGRESS_HOST
echo $INGRESS_PORT
echo $SECURE_INGRESS_PORT

kubectl apply -f /vagrant/manifests/istio-gateway-sample.yaml
kubectl apply -f /vagrant/manifests/istio-vs-sample.yaml

curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/status/200

kubectl apply -f /vagrant/manifests/istio-gateway-prometheus.yaml

#curl -I -HHost:prometheus.istio.k3s.local http://$INGRESS_HOST:$INGRESS_PORT/

#echo "# change port for http 80 -> 8022 on vagrant"
#kubectl patch svc istio-ingressgateway -n istio-system --type='json' \
#  -p='[{"op": "replace", "path": "/spec/ports/1/port", "value":8022}]'

echo "# prometheus"
kubectl apply -f /vagrant/manifests/istio-gateway-prometheus.yaml
kubectl apply -f /vagrant/manifests/istio-vs-prometheus.yaml

echo "# kiali"
kubectl apply -f /vagrant/manifests/istio-kiali.yaml

echo "# tracing"
kubectl apply -f /vagrant/manifests/istio-tracing.yaml

echo "# grafana"
kubectl apply -f /vagrant/manifests/istio-grafana.yaml


