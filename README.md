# Bagapi

## Container image

Stored in Gitlab Registry with a public access (`latest` tag only):

```plain
ghcr.io/dshatokhin/bagapi:latest
```

## Quick start

Requirements:

- [pkl](https://pkl-lang.org/main/current/pkl-cli/index.html#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux)
- [tofu](https://opentofu.org/docs/intro/install)

## Deploy

First, deploy the Kubernetes cluster (UpCloud in our case - authentication needed via env vars - `UPCLOUD_USERNAME` and `UPCLOUD_PASSWORD`):

```shell
> pkl eval tofu/main.pkl -m tofu/
> tofu -chdir=tofu init
> tofu -chdir=tofu apply -auto-approve
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Save `kubeconfig`:

```shell
> tofu -chdir=tofu output -raw kubeconfig > ./bagapi-cluster.yaml
> export KUBECONFIG=$PWD/bagapi-cluster.yaml
```

Apply Gateway API CRDs to created cluster:

```shell
> kubectl apply -f crd/
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
```

Install `bagapi-provisioner` by running:

```shell
> pkl eval bagapi/deploy.pkl -p createNamespace=true | kubectl apply -f -
namespace/bagapi-system created
deployment.apps/bagapi-provisioner created
serviceaccount/bagapi-provisioner created
clusterrole.rbac.authorization.k8s.io/bagapi created
clusterrolebinding.rbac.authorization.k8s.io/bagapi-provisioner created
```

Deploy `kuard` to cluster, lets start with one instance - `blue`:

```shell
> pkl eval kuard/deploy.pkl -p createNamespace=true -p colours=blue | kubectl apply -f -
namespace/kuard created
gatewayclass.gateway.networking.k8s.io/bagapi created
gateway.gateway.networking.k8s.io/kuard created
deployment.apps/kuard-blue created
service/kuard-blue created
httproute.gateway.networking.k8s.io/kuard-blue created
```

After a few minutes the LoadBalancer will be created in the cloud, use the IP address to populate `/etc/hosts`.
We've got an FQDN so additional steps needed to resolve the hostname to the IP:

```shell
# Get and resolve LB hostname to IP address
> LB_HOSTNAME=$(kubectl get svc kuard-bagapi -n kuard -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
> LB_ADDRESS=$(dig +short "$LB_HOSTNAME")

# Save to /etc/hosts
> cat << EOF | sudo tee -a /etc/hosts

$LB_ADDRESS    blue.online
$LB_ADDRESS    green.online
$LB_ADDRESS    purple.online
EOF
```

The [blue.online](http://blue.online) instance should be ready to open in browser or simply `curl`ed:

```shell
> curl --write-out '\n' --dump-header - http://blue.online/healthy
HTTP/1.1 200 OK
content-type: text/plain
date: Thu, 06 Jun 2024 20:01:35 GMT
content-length: 2
x-envoy-upstream-service-time: 0
server: envoy

ok
```

Add other variants of `kuard`:

```shell
> pkl eval kuard/deploy.pkl -p createNamespace=true -p colours=blue,green,purple | kubectl apply -f -
namespace/kuard unchanged
gatewayclass.gateway.networking.k8s.io/bagapi unchanged
gateway.gateway.networking.k8s.io/kuard unchanged
deployment.apps/kuard-blue unchanged
service/kuard-blue unchanged
httproute.gateway.networking.k8s.io/kuard-blue unchanged
deployment.apps/kuard-green created
service/kuard-green created
httproute.gateway.networking.k8s.io/kuard-green created
deployment.apps/kuard-purple created
service/kuard-purple created
httproute.gateway.networking.k8s.io/kuard-purple created
```

Now all 3 instances can be accessed by dicrect links:

- [blue.online](http://blue.online)
- [green.online](http://blue.online)
- [purple.online](http://blue.online)

Let's enable HTTPS:

```shell
> pkl eval kuard/deploy.pkl -p createNamespace=true -p colours=blue,green,purple -p enableHttps=true | kubectl apply -f -
namespace/kuard unchanged
gatewayclass.gateway.networking.k8s.io/bagapi unchanged
gateway.gateway.networking.k8s.io/kuard configured
deployment.apps/kuard-blue unchanged
service/kuard-blue unchanged
httproute.gateway.networking.k8s.io/kuard-blue unchanged
deployment.apps/kuard-green unchanged
service/kuard-green unchanged
httproute.gateway.networking.k8s.io/kuard-green unchanged
deployment.apps/kuard-purple unchanged
service/kuard-purple unchanged
httproute.gateway.networking.k8s.io/kuard-purple unchanged
```

```shell
> curl --insecure --write-out '\n' --dump-header - https://blue.online/healthy
HTTP/1.1 200 OK
content-type: text/plain
date: Thu, 06 Jun 2024 20:11:23 GMT
content-length: 2
x-envoy-upstream-service-time: 0
server: envoy

ok
```

## Destroy

To avoid creating any orphaned resources in the cloud first delete workload from cluster:

```shell
> pkl eval kuard/deploy.pkl -p createNamespace=true | kubectl delete -f -
```

After that the cluster could be destroyed with `tofu`:

```shell
> tofu -chdir=tofu destroy -auto-approve
```
