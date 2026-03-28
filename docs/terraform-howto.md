# Howto for working with AWS infrastructure

You need `terraform` to be installed on your linux machine/WSL.

## Prepare AWS Key Pair

1. Generate a key pair locally on the machine you're going to access AWS resources from via SSH

from the project's root folder:
```
cd infra/terraform/.secrets
ssh-keygen                        # for path use just a key_pair_name to save it in the .secrets folder (<keyname>)
chmod 600 <keyname>               # set the correct permissions for the private key
```
> as a keyname use: 'devopskeypair' for devops_key_pair_name (update default parameter if you use defferent key name)

2. Paste the key name to the value of the related `...key_pair_name` variable in the `variables.tf` file

## Deploy AWS infrastructure

from the project's root folder:
```
cd infra/terraform
terraform init                    # install required terraform plugins
terraform validate                # validate your terraform code (in case you modified)
terraform plan                    # check upcoming infrastructure changes
terraform apply                   # apply changes
```

## Access the Lab AWS node(s) from home

- get <instance>_public_ip from the `terraform apply` output
- access it via SSH
from the project's root folder:
```
cd infra/terraform/.secrets
ssh -i <keyname> ubuntu@<instance_public_ip>
```
> NOTE: If you're using free tier resources, the public IPs of your instances are ephemeral, they will be changed in 24h. If you haven't destroyed and re-created your infrastracture by `terraform destrou/apply` and use a new public IP accessing an inctance via SSH, don't forget to add it manually to the ips_to_remove.txt file as a new line. That will help you to keep your known_hosts file clean of expired and unused records.

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
