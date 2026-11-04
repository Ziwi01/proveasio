# AWS/IaC tools, tool bundles, slim trim, tenv — design

## Intent

The user works on AWS (EKS, ECR, ALB), Terraform via Spacelift, and Argo CD. Proveasio
installs the AWS CLI and the Kubernetes/Argo tools but not the AWS- and Terraform-side
helpers. Goals:

1. Install 12 new tools, documented with purpose and examples.
2. Group tools into bundles that can be selected (`--tags`) and excluded
   (`software_tasks_exclude`) as a unit, while single members stay excludable.
3. Drop the Kubernetes, IaC and cloud tools from the slim image.
4. Mark in the docs what Proveasio itself needs, and document what installs what.
5. Let tenv manage Terraform, OpenTofu and Terragrunt, with no second copy.

Non-goals: Windows role changes; new bundle mechanics for the config role; enforcing
new "required" tools in code (docs only, see 4).

Anti-goals: two installs of the same binary on PATH; a bundle exclude that the Docker
scripts (`render-overrides.sh`, `provision.sh`, `test.sh`) do not understand.

## 1. New tools

Each is a normal software task (`<tool>.yml`, include in `main.yml` with exclude guard,
`github_packages` key, `check_software_<tool>` in `docker/test.sh`, docs). Shape after
`hunk.yml`/`eza.yml`; versioned dir in `~/.local/opt`, symlink in `~/.local/bin`.

| Include / tag | `github_packages` key | Source | Notes |
|---|---|---|---|
| `granted` | `granted` | fwdcloudsec/granted releases | Ships `granted` and `assumego`; `assume` must be **sourced**, so `.zshrc` needs `alias assume="source assume"` (Granted's documented setup). Builder: confirm the release asset names and whether `assume` is a script inside the archive. |
| `session-manager-plugin` | `session_manager_plugin` | aws/session-manager-plugin tags; binary from AWS's S3 `.deb` | Not a GitHub binary release. Extract the `.deb` (`dpkg-deb -x`) into the versioned dir to stay sudo-free, or install with apt like other `.deb`s in the repo; builder's call, prefer no sudo. |
| `taws` | `taws` | huseyinbabal/taws releases | k9s-style AWS TUI. |
| `eksctl` | `eksctl` | eksctl-io/eksctl releases | |
| `eks-node-viewer` | `eks_node_viewer` | awslabs/eks-node-viewer releases | |
| `stern` | `stern` | stern/stern releases | |
| `crane` | `crane` | google/go-containerregistry releases (`go-containerregistry_Linux_x86_64.tar.gz`, contains `crane`) | Chosen over regctl: wider adoption, simpler CLI, uses Docker credential helpers (ECR helper). |
| `spacectl` | `spacectl` | spacelift-io/spacectl releases | |
| `tenv` | `tenv` | tofuutils/tenv releases | See section 5. |
| `tflint` | `tflint` | terraform-linters/tflint releases | AWS ruleset is per-project `.tflint.hcl` + `tflint --init`; document, don't install globally. |
| `terraform-docs` | `terraform_docs` | terraform-docs/terraform-docs releases | |
| `steampipe` | `steampipe` | turbot/steampipe releases | Install the binary only. `steampipe plugin install aws` is documented, not run (it downloads per user and needs no credentials, but is a user choice). Builder's call whether to run it; if run, gate it on the plugin dir. |

amd64 only, like the rest of the catalog.

## 2. Bundles (approach B, chosen)

### Approaches considered

- **A. Tags only:** bundle tag on each member's outer `tags:`. Select with `--tags`,
  exclude members with `--skip-tags`/`software_tasks_exclude`. No new logic.
- **B. Tags plus bundle names in exclude/include lists (chosen):** A, plus
  `software_tasks_exclude: [aws-tools]` drops the whole bundle. User picked B so overrides
  files (and the slim profile) can drop bundles by name.

### Definition

One source of truth in `roles/software/vars/main.yml`:

```yaml
software_bundles:
  aws-tools: [awscli, granted, session-manager-plugin, taws, eksctl, eks-node-viewer, steampipe]
  azure-tools: [azurecli, az-account-switcher]
  kubernetes-tools: [kubectl, kubecolor, kubeswitch, k9s, helm, helm-unittest, kubeconform, dyff, kind, stern, crane]
  terraform-tools: [tenv, terraform, tofu, terragrunt, tflint, terraform-docs]
  argocd-tools: [argocd, argonaut]
  spacelift-tools: [spacectl]
```

Names differ from the request in two places, as the builder's/my call: `argocd` is
already an include and tag name, so the bundle is `argocd-tools`; `spacelift` became
`spacelift-tools` for consistency. Each tool is in exactly one bundle. Tools outside
any bundle are unchanged.

Bundle names must not equal any include name (assert).

### Behaviour

- **Tags:** every member's include gets its bundle name added to its outer `tags:` (and
  `apply.tags`). `--tags terraform-tools --skip-tags tofu` works.
- **Exclude:** in the overrides sandwich, after the catalog merge, a `set_fact` expands
  bundle names in `software_tasks_exclude` into their members (and keeps the bundle name
  itself, harmless). The existing per-tool `when:` guards then work unchanged.
- **Validation (tag `always`):** fail when a bundle member is not an include name in
  `main.yml`, or when a bundle name collides with an include name. The required-task
  assert runs after expansion (no required task is in a bundle today, so this only
  guards the future).
- **Docker:** `render-overrides.sh` expands bundle names in `software_tasks_exclude` and
  `software_tasks_include` into members (reading `software_bundles` from the role vars
  with `yq`) **before** `apply_includes`, so the rendered `overrides.yml`, `provision.sh`
  and `test.sh` only ever see tool names. `apply_includes` accepts bundle names as valid.
  Order: profile excludes a bundle, user includes one member → that member comes back.
- Consistency between `software_bundles` and the tags in `main.yml`: checked by
  `docker/test.sh --coverage` (or a small check in the same place). Builder's call where.

## 3. Slim profile

`docker/profile-slim.yml` excludes, in addition to today's list: `aws-tools`,
`azure-tools` (replaces the listed `azurecli`, `az-account-switcher`, `awscli`),
`kubernetes-tools`, `terraform-tools`, `argocd-tools`, `spacelift-tools`. `dry` stays
(it is not in a bundle). Not marked breaking (only the user uses slim).

Comparison table in `docs-web/docs/main/docker/10-build.md`: Kubernetes, IaC, AWS,
Azure, Argo CD, Spacelift rows show ❌ for slim; new tools added to their rows.

## 4. Required tools and dependency map

- Comparison table: mark rows Proveasio needs to run or re-run itself (e.g. a "🔒" or
  "required" note): enforced (`packages`, `yq`, `zsh` + config `zsh`) vs needed in
  practice (Python/pyenv, Ansible, nvm for the Ansible language server, git). Enforcement
  in code is unchanged (non-goal).
- Dependency map: a separate table in `docs-web/docs/main/roles/10-software.md` (linked
  from the comparison), columns "Tool", "Needs", "Also installs". Builder fills it from
  the task files; known entries: helm-unittest → helm; azurecli → kubelogin; ansible →
  pip + nvm (language server); terraform/tofu/terragrunt → tenv; Neovim config → nvm,
  gvm, rvm (Mason); every GitHub tool → packages (jq, curl), yq.

## 5. tenv

Decided: version files in the repo (`.terraform-version`, `.opentofu-version`,
`.terragrunt-version`, or `required_version`) decide the version.

- `tenv.yml` installs tenv like any GitHub tool, links `tenv` **and its proxy binaries**
  (`terraform`, `tofu`, `terragrunt`, …) into `~/.local/bin`.
- `terraform.yml`, `tofu.yml`, `terragrunt.yml` keep their names, tags and
  `github_packages` keys. They resolve the version as today and run
  `tenv <tf|tofu|tg> install <version>` (gated on tenv's install dir), then save it.
- **No global default is written** (changed during implementation). tenv's lookup
  order puts `~/.tenv/<Tool>/version` *before* `required_version` (which only
  constrains the last-resort "newest installed" step), so a global file would
  override repositories that only declare `required_version`. Without it, a repo's
  constraint is honoured and elsewhere the newest installed version runs (verified
  with tenv 4.15.1).
- Each of the three fails early with a clear message if `tenv` is excluded.
- Migration on first run: replace the old `~/.local/bin/<tool>` symlink with tenv's proxy
  (forced link), delete `~/.local/opt/<tool>-*` (cleanup with nothing kept). No
  duplicate copies remain.
- `.zshrc`: `TENV_AUTO_INSTALL=true` (verified: outside a repo it does not download anything new) so a repo pinning an uninstalled version installs it
  on first use.
- Excluding `tofu` still leaves tenv's `tofu` proxy on PATH (it ships in the tenv
  release); documented, not worked around.
- My call: the three tasks check for the `tenv` binary rather than the exclude list, so
  `--tags terraform` on a machine without tenv also fails clearly.
- My call: link every proxy shipped in the tenv release; never prune versions tenv
  installed (repos may pin them).
- `docker/test.sh`: `check_software_tenv`; the three existing checks still run
  `terraform version` etc. (through the proxy) and the receipt checks stay.
- Commit type `feat`, not breaking: names, tags, pins keep working. The behaviour change
  (repo files win over the global pin) goes in the docs.

## Docs (per AGENTS.md)

- `roles/10-software.md`: one row per new tool; bundles table; dependency map.
- Features: `40-devops.md` for all 12 (cloud, k8s, IaC, Spacelift).
- `customization/50-partial-run.md`: new tags and the bundle tags with member lists.
- `customization/40-excludes.md`: bundle names in `software_tasks_exclude`/`_include`.
- `docker/10-build.md`: comparison table (slim changes, required markers).
- Usage examples: `usage/60-cloud-iac.md` (granted/assume, ssm, taws, steampipe,
  spacectl incl. `local-preview`, tenv, tflint, terraform-docs),
  `usage/50-kubernetes.md` (eksctl, eks-node-viewer, stern, crane with ECR).
- `README.md` feature list.

## Verification

`cd ansible && ansible-lint` (0 failures), `--syntax-check`, `--list-tags`,
`cd docs-web && npm run build`, `PROVEASIO_HOME="$PWD" bash docker/test.sh --coverage`.
No Docker in this container, so the smoke build and a real install are not runnable
here; the user runs them on the workstation.
