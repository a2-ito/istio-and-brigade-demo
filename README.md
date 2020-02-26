# istio

## Environment

test branch

## Restrictions
- Binding the port 80 on vagrantfor example, 

## Demo 1 - Bookinfo App and Canary release

### Preparation
```
```

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
kubectl delete vertualservice reviews
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

```
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"
}}}}'

helm init --service-account=tiller --upgrade

helm repo add brigade https://brigadecore.github.io/charts

helm install -n brigade brigade/brigade -f brigade-values.yaml --set brigade-github-app.service.type=LoadBalancer
```
