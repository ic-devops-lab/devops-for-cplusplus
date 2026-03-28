# Milestone 1 for AWS infrastructure with terraform

## Prerequisits

- Ubuntu/Debian host/WSL
- terraform

## Copy terraform configuration files

From [the repository project Mileston 1 branch](https://github.com/ic-devops-lab/devops-for-cplusplus/tree/001-local-setup) copy to yuor local machine contents of infra/terraform folder.

## Configure local variables

Get your host's global IP address, for example like that:
```
MY_IP=curl "https://checkip.amazonaws.com"
```

In the terraform folder:
1. Create terraform.tfvars file.
2. Populate it with your data
```
home_ip = "<MY_IP>/32"
project_prefix = "cppcicd"
```

## Prepare an SSH key pair of your AWS devops instance

From the terraform folder:
```
mkdir .secrets && cd $_       # create a folder for secrets and navigate to it
ssh-keygen                    # for path use just 'devopskeypair' to save it in the .secrets folder
chmod 600 devopskeypair       # set the correct permissions for the private key (!important)
```

## Deploy AWS infrastructure for DevOps environment

From the terraform folder:
```
terraform init                # install required terraform plugins
terraform validate            # validate your terraform code (in case you modified)
terraform plan                # check upcoming infrastructure changes
terraform apply               # apply changes
```

## Access the devops instance from home

- get devops_instance_public_ip from the `terraform apply` output
- access it via SSH
From the terraform folder:
```
ssh -i .secrets/devopskeypair ubuntu@<instance_public_ip>
```
> NOTE: If you're using free tier resources, the public IPs of your instances are ephemeral, they will be changed in 24h. If you haven't destroyed and re-created your infrastracture by `terraform destrou/apply` and use a new public IP accessing an inctance via SSH, don't forget to add it manually to the ips_to_remove.txt file as a new line. That will help you to keep your known_hosts file clean of expired and unused records.

## Check

On your AWS devops instance:
```
cmake --version
git --version
curl --version

ls -l
```

Expected:
- all packages installed
- `ls` command gives the result similar to:
```
ls -l
total 4
drwxr-xr-x 7 root root 4096 Mar 28 14:56 cppcicd
```

## Cleanup

```
```bash
# remove all after the lab
terraform destroy

# remove record(s) for the Lab's IPs from known_hosts
while IFS= read -r ip; do
  if ssh-keygen -F "$ip" > /dev/null; then
    echo "$ip found in known_hosts"
  else
    echo "$ip NOT in known_hosts"
  fi
done < ips_to_remove.txt
rm ips_to_remove.txt
```