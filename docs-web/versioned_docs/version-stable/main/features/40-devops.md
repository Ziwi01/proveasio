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
- [stern](https://github.com/stern/stern) - tail the logs of many pods and containers at once, by name regex or label
- [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md) - work with container registries (ECR included) without pulling images: list tags, copy, read digests
- [Argo CD CLI](https://github.com/argoproj/argo-cd) (`argocd`) and [Argonaut](https://github.com/darksworm/argonaut) - command line and terminal UI for Argo CD

## Infrastructure as code

- [tenv](https://github.com/tofuutils/tenv) - version manager: runs the Terraform, OpenTofu or Terragrunt version each repository asks for, and installs it on first use
- [Terraform](https://github.com/hashicorp/terraform) - infrastructure as code
- [OpenTofu](https://github.com/opentofu/opentofu) (`tofu`) - open source fork of Terraform
- [Terragrunt](https://github.com/gruntwork-io/terragrunt) - wrapper for Terraform and OpenTofu to manage many environments
- [TFLint](https://github.com/terraform-linters/tflint) - linter that catches invalid instance types, deprecated syntax and provider mistakes before a plan
- [terraform-docs](https://github.com/terraform-docs/terraform-docs) - generates the inputs and outputs tables of a module's README
- [spacectl](https://github.com/spacelift-io/spacectl) - Spacelift CLI: trigger and follow runs, and preview local changes on Spacelift

## Cloud

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) (`az`) with [az-account-switcher](https://github.com/abij/az-account-switcher) (`az-switch`)
  - [kubelogin](https://github.com/Azure/kubelogin) - Entra ID credential plugin for `kubectl`, needed for AKS clusters. Installed with Azure CLI.
- [AWS CLI](https://github.com/aws/aws-cli) (`aws`)
  - [Granted](https://github.com/fwdcloudsec/granted) (`assume`) - switch AWS profiles and SSO roles in the current shell
  - [Session Manager plugin](https://github.com/aws/session-manager-plugin) - shells and port forwards to EC2 instances and EKS nodes through `aws ssm start-session`, without SSH or a bastion
  - [taws](https://github.com/huseyinbabal/taws) - terminal UI for AWS resources, in the style of k9s
  - [eksctl](https://github.com/eksctl-io/eksctl) - CLI for EKS clusters, node groups, add-ons and IAM service accounts
  - [eks-node-viewer](https://github.com/awslabs/eks-node-viewer) - live view of EKS node usage and cost
  - [Steampipe](https://github.com/turbot/steampipe) - query AWS resources with SQL, across accounts and regions

The tools are grouped in bundles (`aws-tools`, `kubernetes-tools`, `terraform-tools`, ...) that can be installed or excluded together, see [Bundles](../roles/10-software.md#bundles).

See [Kubernetes usage](../../usage/50-kubernetes.md) and [Cloud and IaC usage](../../usage/60-cloud-iac.md) for examples.
