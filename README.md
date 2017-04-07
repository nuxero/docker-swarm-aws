# Docker Swarm on AWS
This repo provisions a Docker Swarm Cluster on AWS using Packer and Terraform.

First create the ami using packer and provide the region variable. The packer script uploads two files *docker.conf* and *init.js*. The first is for customize the docker service and the latter is a nodejs script for initialize the cluster/join nodes to it.

`packer build -var 'region=us-east-1' docker.json`

Write down the ami id generated.

The terraform scripts don't handle credentials, instead its use env variables, so set your variables like this:

```
export AWS_ACCESS_KEY_ID=your-access-key-here
export AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
export AWS_DEFAULT_REGION=your-region
export TF_VAR_manager_count=how-many-managers-do-you-want Ej: 1, 3, 5 (odd numbers recommended)
export TF_VAR_worker_count=how-many-workers-do-you-want Ej: 1,5,10,1000
export TF_VAR_key=your-key
export TF_VAR_ec2_ami=the-ami-key-generated-with-packer
export TF_VAR_key_local_path=path-to-the-key-pair-for-ssh
```

Now you can provision the infrastructure with Terraform

`terraform apply`

A brief description of scripts is provided next:

* `provider.tf` defines the aws region.
* `variables.tf` contains all variables used on the scripts.
* `securitygroups.tf` defines the security groups for elastic load balancer and ec2 instances.
* `iam.tf` contains the iam role assigned to cluster nodes.
* `loadbalancing.tf` defines the elastic load balancer
* `autoscaling.tf` contains the launch configurations and autoscaling groups for worker and manager nodes.

Currently there are no outputs defined so you should login to AWS console to get nodes information.

# TO-DO
* ~~Think about how to initialize cluster and how worker nodes will automagically join to it~~
* Improve cluster initializer/join-nodes script
* Deploy some CI/CD tools on cluster (Jenkins?)
* Add a Docker registry
* Add a proxy for accessing containers (Docker Flow Proxy?)
* Add a monitoring tool
