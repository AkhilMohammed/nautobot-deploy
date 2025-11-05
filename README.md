# nautobot-deploy-automation

Automated GitOps for Nautobot plugin-based deployments:
- Add plugin entries to `ansible/inventories/prod/group_vars/nautobot.yml` to include plugin repos.
- Pushing changes to that file triggers GitHub Actions:
  1. Clone plugin repos, build a combined Nautobot image, push to GHCR.
  2. Terraform creates EC2 instance.
  3. Ansible installs Docker on the instance and deploys the stack with the combined image.

## Required GitHub Secrets (repository)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (e.g. ap-south-1)
- `AMI_ID` (Ubuntu 22.04 AMI ID for region)
- `AWS_SSH_KEY_NAME` (existing EC2 keypair name)
- `ANSIBLE_SSH_PRIVATE_KEY` (private key content for connecting to EC2 instance)
- `GHCR_USERNAME`, `GHCR_TOKEN` (PAT with packages:write && repo read/push permissions)

## How to add a plugin
1. Add a new entry to `ansible/inventories/prod/group_vars/nautobot.yml`:
   ```yaml
   plugins:
     - name: "my-plugin"
       repo: "https://github.com/<org>/my-plugin.git"
       branch: "main"
