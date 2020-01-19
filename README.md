# istio


## Environment


## Restrictions
- Binding the port 80 on vagrantfor example, 

## Demo 1 - Bookinfo App and Canary release
```
watch -n 1 curl -o /dev/null -s -w %{http_code} -HHost:bookinfo.istio.k3s.local http://10.0.2.15/productpage
```

```
kubectl apply -f /vagrant/manifests/reviews-v1-90-v2-10.yaml
```
```
kubectl apply -f /vagrant/manifests/reviews-all-v2.yaml
```
```
kubectl apply -f /vagrant/manifests/reviews-all-versions.yaml
```

## Demo 2 - sticky session

### Deploy sample deployment
```
kubectl apply -f /vagrant/manifests/sticky-svc.yaml
```
### Scale out to 5 pods
```
kubectl scale deploy sticky-svc --replicas=5
```
### Verity
```
while true; do curl -s -H 'x-user: hoge' -HHost:sticky-svc.istio.k3s.local http://10.0.2.15/ping; echo; sleep 1; do
```
### Define destinationrule for session affinity
```
kubectl apply -f /vagrant/manifests/sticky-svc-destinationrule.yaml
```
