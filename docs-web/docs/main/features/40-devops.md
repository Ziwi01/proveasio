# DevOps

## Containers and Kubernetes

- [Docker](https://www.docker.com/) engine with the [Compose](https://docs.docker.com/compose/) plugin
- [dry](https://github.com/moncho/dry) - terminal UI for Docker
- [kubectl](https://kubernetes.io/docs/reference/kubectl/), colorized by [kubecolor](https://github.com/kubecolor/kubecolor)
- [kubeswitch](https://github.com/danielfoehrKn/kubeswitch) (`switch`) - switch between clusters and namespaces with fuzzy search
- [k9s](https://github.com/derailed/k9s) - terminal UI for Kubernetes clusters
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker, for local clusters
- [Helm](https://github.com/helm/helm) - Kubernetes package manager, with the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin
- [kubeconform](https://github.com/yannh/kubeconform) - Kubernetes manifest validator
- [dyff](https://github.com/homeport/dyff) - diff for YAML files, Kubernetes-aware
- [Argo CD CLI](https://github.com/argoproj/argo-cd) (`argocd`) and [Argonaut](https://github.com/darksworm/argonaut) - command line and terminal UI for Argo CD

## Infrastructure as code

- [Terraform](https://github.com/hashicorp/terraform) - infrastructure as code
- [OpenTofu](https://github.com/opentofu/opentofu) (`tofu`) - open source fork of Terraform
- [Terragrunt](https://github.com/gruntwork-io/terragrunt) - wrapper for Terraform and OpenTofu to manage many environments

## Cloud

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) (`az`) with [az-account-switcher](https://github.com/abij/az-account-switcher) (`az-switch`)
  - [kubelogin](https://github.com/Azure/kubelogin) - Entra ID credential plugin for `kubectl`, needed for AKS clusters. Installed with Azure CLI.
- [AWS CLI](https://github.com/aws/aws-cli) (`aws`)

See [Kubernetes usage](../../usage/50-kubernetes.md) and [Cloud and IaC usage](../../usage/60-cloud-iac.md) for examples.
