# Cloud and IaC

## Terraform and OpenTofu

Uses: [Terraform](https://developer.hashicorp.com/terraform), [OpenTofu](https://opentofu.org/), [tenv](https://tofuutils.github.io/tenv/)

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

### Versions per repository (tenv)

`terraform`, `tofu` and `terragrunt` are tenv's proxies. Each command runs the version the repository asks for, and downloads it the first time. The full lookup order is in [the software role](../main/roles/10-software.md#terraform-opentofu-and-terragrunt-versions).

```shell
echo 1.9.8 > .terraform-version   # pin this repository (or rely on required_version)
terraform version                 # runs 1.9.8, installing it first if needed
tenv tf detect                    # which version would run here, and why
tenv tf list                      # installed versions
tenv tf list-remote               # available versions
tenv tf uninstall 1.8.5           # remove a version you no longer need
```

Use `tenv tofu ...` and `tenv tg ...` the same way for OpenTofu and Terragrunt.

### Lint with TFLint

Uses: [TFLint](https://github.com/terraform-linters/tflint)

TFLint finds what `terraform validate` does not: invalid instance types, unknown regions, deprecated arguments, unused declarations. Provider rules come from plugins, configured per repository in `.tflint.hcl`:

```hcl
plugin "aws" {
  enabled = true
  version = "0.50.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

```shell
tflint --init                     # download the plugins from .tflint.hcl
tflint --recursive                # lint every module below the current directory
```

### Module docs with terraform-docs

Uses: [terraform-docs](https://terraform-docs.io/)

Generates the inputs, outputs and providers tables of a module, so its README cannot drift from the code. With `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` in the README, it replaces only the part between the markers:

```shell
terraform-docs markdown table --output-file README.md --output-mode inject .
```

## Spacelift

Uses: [spacectl](https://github.com/spacelift-io/spacectl)

```shell
spacectl profile login <account>          # once; <account> is the part before .app.spacelift.io
spacectl stack list
spacectl stack local-preview --id <stack> # plan your uncommitted changes on Spacelift, with the stack's credentials and variables
spacectl stack deploy --id <stack>        # start a tracked run
spacectl stack logs --id <stack> --run-latest --tail
spacectl stack confirm --id <stack> --run <run-id>
spacectl stack open --id <stack>          # open the stack in the browser
```

Without `--id`, spacectl looks for the stack by the current repository and directory. `local-preview` is the useful one: it tests a change with the real backend and credentials before you push.

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

### Switch accounts and roles with Granted

Uses: [Granted](https://github.com/fwdcloudsec/granted)

`assume` sets AWS credentials in the current shell, so every following `aws`, `terraform` or `kubectl` command uses that role. It handles SSO logins and refreshes credentials when they expire.

```shell
granted sso populate --sso-region eu-west-1 https://<org>.awsapps.com/start   # once: a profile for every account and role you can use
assume                         # pick a profile with fuzzy search
assume <profile>               # switch directly
assume -c <profile>            # open the AWS console for that role
assume --unset                 # clear the credentials
```

The first run asks which browser to use for the console.

### Connect to instances and nodes with Session Manager

Uses: [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

A shell or a port forward to an EC2 instance or EKS node, with no SSH key, open port or bastion. The instance needs the SSM agent and an instance role that allows it.

```shell
aws ssm start-session --target i-0123456789abcdef0
# forward localhost:5432 to a private database, through an instance in its VPC
aws ssm start-session --target i-0123456789abcdef0 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["db.internal.example"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

### Browse resources with taws

Uses: [taws](https://github.com/huseyinbabal/taws)

A k9s-style terminal UI for AWS: EC2, ECR, EKS, load balancers, IAM, Lambda, S3 and more.

```shell
taws                           # uses the current profile (works with assume)
taws -p <profile> -r eu-west-1
taws --readonly                # block every change; good for production accounts
```

### Query AWS with SQL (Steampipe)

Uses: [Steampipe](https://steampipe.io/)

Steampipe turns the AWS API into SQL tables. Good for inventory and "which ones" questions across accounts and regions. It only reads.

```shell
steampipe plugin install aws   # once
steampipe query                # interactive; .tables lists the tables
steampipe query "select name, dns_name, scheme, region from aws_ec2_application_load_balancer"
steampipe query "select name, version, status from aws_eks_cluster"
steampipe query "select repository_name, image_tag_mutability from aws_ecr_repository"
```

The AWS plugin uses your AWS profiles. To query several accounts at once, see the [AWS plugin docs](https://hub.steampipe.io/plugins/turbot/aws).

### EKS

See [EKS clusters](./50-kubernetes.md#eks-clusters) for eksctl and eks-node-viewer.
