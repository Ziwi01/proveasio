# Kubernetes

## kubectl and kubecolor

`kubectl` is aliased to [kubecolor](https://github.com/kubecolor/kubecolor), which colors its output; completion still works. To run the plain binary, use `command kubectl`.

The oh-my-zsh `kubectl` plugin adds short aliases, for example:

| Alias | Command |
|---|---|
| `k` | `kubectl` |
| `kgp` / `kgpw` | `kubectl get pods` / `... --watch` |
| `kgs`, `kgd`, `kgno` | `kubectl get services`, `deployments`, `nodes` |
| `kdp` | `kubectl describe pods` |
| `kl` / `klf` | `kubectl logs` / `kubectl logs -f` |
| `keti` | `kubectl exec -t -i` |
| `kaf` | `kubectl apply -f` |

Run `alias | grep kubectl` for the full list. When you type a full command that has an alias, `you-should-use` reminds you.

## Switch clusters and namespaces with kubeswitch

Uses: [kubeswitch](https://github.com/danielfoehrKn/kubeswitch)

`switch` opens a fuzzy picker of every context in your kubeconfig files, with a preview. Picking one changes the context **only in the current shell**, so two terminals can work on two clusters at the same time without touching `~/.kube/config`.

```shell
switch                  # pick a context
switch <context>        # switch directly (tab completion works)
switch namespace        # pick a namespace in the current context
switch history          # go back to an earlier context and namespace
```

By default kubeswitch reads `~/.kube/config`. To search a directory of kubeconfig files (one per cluster, for example), create `~/.kube/switch-config.yaml`:

```yaml
kind: SwitchConfig
version: v1alpha1
kubeconfigStores:
  - kind: filesystem
    paths:
      - ~/.kube/configs/
```

## Explore a cluster with k9s

Uses: [k9s](https://k9scli.io/)

Run `k9s` (or `k9s -n <namespace>`, `k9s --context <context>`). It starts in the pod view of the current context.

- `:` then a resource name (`:deploy`, `:svc`, `:ns`, `:ctx`) - change the view
- `/` - filter the list
- <kbd>Enter</kbd> - drill down (deployment → pods → containers)
- `l` logs, `s` shell, `d` describe, `e` edit, `y` YAML, <kbd>Ctrl</kbd>+<kbd>d</kbd> delete
- `?` - all keys of the current view; <kbd>Esc</kbd> goes back, `:q` quits

## Local cluster with kind

Uses: [kind](https://kind.sigs.k8s.io/)

kind runs a Kubernetes cluster inside Docker containers, which is enough for testing charts and manifests.

```shell
kind create cluster --name dev           # creates the cluster and the kind-dev context
kubectl get nodes
kind load docker-image myapp:dev --name dev   # make a local image available to the cluster
kind delete cluster --name dev
```

## Helm

Uses: [Helm](https://helm.sh/), [helm-unittest](https://github.com/helm-unittest/helm-unittest)

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm search repo prometheus
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
helm template ./mychart -f values.yaml     # render locally without installing
helm lint ./mychart
```

### Test charts with helm-unittest

Write tests as YAML files in `<chart>/tests/`:

```yaml title="mychart/tests/deployment_test.yaml"
suite: deployment
templates:
  - deployment.yaml
tests:
  - it: uses the image tag from values
    set:
      image.tag: "1.2.3"
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: myapp:1.2.3
```

and run them with `helm unittest ./mychart`. Add `-u` to update snapshot tests.

## Validate and compare manifests

Uses: [kubeconform](https://github.com/yannh/kubeconform), [dyff](https://github.com/homeport/dyff)

Validate manifests against the Kubernetes schemas, for example the output of a chart, before applying them:

```shell
helm template ./mychart | kubeconform -strict -summary -
kubeconform -kubernetes-version 1.33.0 -summary manifests/
```

Custom resources need their schemas; without them, add `-ignore-missing-schemas`.

Compare two YAML files or two renderings of a chart by meaning rather than by line, with Kubernetes resources matched by kind and name:

```shell
dyff between old.yaml new.yaml
dyff between <(helm template ./mychart -f prod.yaml) <(helm template ./mychart -f prod-new.yaml)
```

## Argo CD

Uses: [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/), [Argonaut](https://github.com/darksworm/argonaut)

```shell
argocd login argocd.example.com --sso    # or --username/--password
argocd app list
argocd app get <app>
argocd app diff <app>                    # what a sync would change
argocd app sync <app>
```

`argonaut` opens a terminal UI for the same server, using the session saved by `argocd login`: browse the applications and their sync and health status. Press `?` in it for the available actions.

## Tail logs with stern

Uses: [stern](https://github.com/stern/stern)

`kubectl logs` follows one pod. stern follows every pod and container that matches, colors each one and picks up new pods as they start, for example during a rollout.

```shell
stern api -n prod                          # pods whose name matches the regex "api"
stern -l app.kubernetes.io/name=api --since 15m
stern api -n prod -c app --tail 20         # only the "app" container, last 20 lines each
stern api -n prod -i error                 # only lines that match "error"
stern api -n prod -o json | jq .message    # structured output
```

## Container registries with crane

Uses: [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md)

crane works on images in a registry without pulling them. It reads the Docker login, so log in to ECR once per 12 hours:

```shell
aws ecr get-login-password --region eu-west-1 \
  | crane auth login <account>.dkr.ecr.eu-west-1.amazonaws.com -u AWS --password-stdin
REPO=<account>.dkr.ecr.eu-west-1.amazonaws.com/api
crane ls "$REPO"                           # tags
crane digest "$REPO:1.4.2"                 # the digest a tag points to
crane config "$REPO:1.4.2" | jq .config    # entrypoint, env, labels
crane copy "$REPO:1.4.2" <other-account>.dkr.ecr.eu-central-1.amazonaws.com/api:1.4.2   # promote between accounts or regions
crane tag "$REPO:1.4.2" stable             # add a tag without pulling or pushing layers
```

## EKS clusters

Uses: [eksctl](https://eksctl.io/), [eks-node-viewer](https://github.com/awslabs/eks-node-viewer)

Add a cluster to your kubeconfig with the AWS CLI, then use kubectl, k9s and stern as usual:

```shell
aws eks update-kubeconfig --name <cluster> --region eu-west-1
```

eksctl reads and changes EKS clusters. When Terraform owns the cluster, use it mainly to look; changes made with it drift from the Terraform state.

```shell
eksctl get cluster --region eu-west-1
eksctl get nodegroup --cluster <cluster>
eksctl get addons --cluster <cluster>              # add-on versions and available updates
eksctl get iamidentitymapping --cluster <cluster>  # who can access the cluster through aws-auth
```

eks-node-viewer shows each node's requested CPU and memory against its capacity, with the price per node and per hour for the cluster. It shows unused capacity at a glance, for example nodes Karpenter could consolidate.

```shell
eks-node-viewer
eks-node-viewer --resources cpu,memory
eks-node-viewer --node-selector karpenter.sh/nodepool=default
eks-node-viewer --extra-labels topology.kubernetes.io/zone
```

## AKS clusters (kubelogin)

Uses: [kubelogin](https://github.com/Azure/kubelogin)

AKS clusters with Entra ID authentication need kubelogin. After `az aks get-credentials`, convert the kubeconfig to use your Azure CLI login:

```shell
az aks get-credentials -g <resource-group> -n <cluster>
kubelogin convert-kubeconfig -l azurecli
```

See [Cloud and IaC](./60-cloud-iac.md#azure) for the Azure CLI.
