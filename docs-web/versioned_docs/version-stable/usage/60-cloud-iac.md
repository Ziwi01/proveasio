# Cloud and IaC

## Terraform and OpenTofu

Uses: [Terraform](https://developer.hashicorp.com/terraform), [OpenTofu](https://opentofu.org/)

Both are installed. OpenTofu (`tofu`) is the open source fork of Terraform and takes the same commands:

```shell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

Replace `terraform` with `tofu` for OpenTofu projects. The oh-my-zsh `terraform` plugin adds aliases such as `tf`, `tfi` (init), `tfp` (plan) and `tfa` (apply).

Neovim has the Terraform language server and formatter (`terraform-ls`), see [Neovim](./40-vim.md).

## Terragrunt

Uses: [Terragrunt](https://terragrunt.gruntwork.io/)

Terragrunt keeps Terraform/OpenTofu code DRY across many environments: each environment directory holds a small `terragrunt.hcl` that points at a shared module and sets its inputs.

```shell
cd live/prod/vpc
terragrunt plan
terragrunt apply
terragrunt run --all plan     # every unit below the current directory
```

## Azure

Uses: [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/), [az-account-switcher](https://github.com/abij/az-account-switcher)

```shell
az login                       # opens a browser; add --use-device-code without one (or on WSL)
az account show
az group list -o table
```

With many subscriptions, `az-switch` lists them and switches to the one you pick (`az-switch -n <number>` switches directly):

```shell
az-switch
```

For AKS clusters, see [AKS clusters (kubelogin)](./50-kubernetes.md#aks-clusters-kubelogin).

## AWS

Uses: [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/)

```shell
aws configure sso              # or: aws configure, for access keys
aws sso login --profile <profile>
aws sts get-caller-identity --profile <profile>
```

The oh-my-zsh `aws` plugin adds `asp <profile>` to set the active profile for the shell (and `acp` to change it with MFA).
