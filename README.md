# Istio and Brigade demo

## Environment
- GKE
- GCE
- Vagrant

## Restrictions
- Binding the port 80 on vagrantfor example, 
- k3s doesn't work with Brigade github app. 
- a

## Demo 1 - Bookinfo App and Canary release

### Preparation
```
```
#### Enable istio-injetion on default namespace
```
kubectl label namespace default istio-injection=enabled
```

```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

```
kubectl apply -f manifests/istio-kiali.yaml
kubectl apply -f manifests/istio-tracing.yaml
kubectl apply -f manifests/istio-prometheus.yaml
kubectl apply -f manifests/istio-grafana.yaml
```

```
watch -n 1 curl -o /dev/null -s -w %{http_code} -HHost:bookinfo.istio.k3s.local http://10.0.2.15/productpage
watch -n 1 curl -o /dev/null -s -w %{http_code} -HHost:bookinfo.istio.k3s.local http://10.14.20.127:8022/productpage
```

```
kubectl apply -f manifests/destination-rule-all.yaml
```




```
kubectl apply -f manifests/reviews-v1-90-v2-10.yaml
```

```
kubectl apply -f manifests/reviews-all-v2.yaml
```

```
kubectl delete virtualservice reviews
```

## Demo 2 - sticky session

### Deploy sample deployment
```
kubectl apply -f manifests/demo-sticky-session-1-before.yaml
```

### Scale out to 5 pods
```
kubectl scale deploy sticky-svc --replicas=5
```

### Verity
```
while true; do
  curl -s -H 'x-user: hoge' -HHost:sticky-svc.istio.k3s.local http://10.14.20.127:8022/ping; echo; sleep 1;
done
```

### Define destinationrule for session affinity
```
kubectl apply -f manifests/demo-sticky-session-1-destinationrule.yaml
```

```
kubectl scale deploy -n istio-system istio-ingressgateway --replicas=2
```

```
kubectl logs -f -n istio-system istio-ingressgateway-xxxxx | grep sticky
```

```
kubectl delete destinationrule sticky-svc
```


## Demo 3 - 

```
export DOCKER_USERNAME=[username]
export DOCKER_PASSWORD=[password]
```
```
./google-cloud-on-gke.sh
```

```
kubectl get svc
```
```
git status 
git branch 
```

```
git checkout -b testbranch
```

git add .
git commit -m "test branch"


## misc

```
helm install -n smackapi-prod ./kube-con-2017-ito/charts/smackapi --namespace microsmack \
  --set api.image=a2ito/smackapi --set api.imageTag=latest \
  --set api.deployment=smackapi-prod --set api.versionLabel=prod

helm upgrade --install smackapi-prod ./kube-con-2017-ito/charts/smackapi --namespace microsmack \
  --set api.image=a2ito/smackapi --set api.imageTag=latest \
  --set api.deployment=smackapi-prod --set api.versionLabel=prod

helm upgrade --install smackapi-test ./kube-con-2017-ito/charts/smackapi --namespace microsmack \
  --set api.image=a2ito/smackapi --set api.imageTag=test2-1202c36 \
  --set api.deployment=smackapi-test --set api.versionLabel=new

helm install -n microsmack-routes ./kube-con-2017-ito/charts/routes --namespace microsmack \
  --set prodLabel=prod --set prodWeight=90 --set canaryLabel=new --set canaryWeight=10

helm upgrade --install microsmack-routes ./kube-con-2017-ito/charts/routes --namespace microsmack \
  --set prodLabel=prod --set prodWeight=90 --set canaryLabel=new --set canaryWeight=10

helm upgrade --install microsmack-routes ./kube-con-2017-ito/charts/routes --namespace microsmack \
  --set prodLabel=prod --set prodWeight=50 --set canaryLabel=new --set canaryWeight=50
```

