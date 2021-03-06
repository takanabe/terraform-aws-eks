# cluster module

This module provisions an EKS cluster, including the EKS Kubernetes control
plane, and several important cluster services (critial addons), and nodes to
run these services.

It will **not** provision any nodes that can be used to run non cluster services.
You will need to provision nodes for your workloads separately using the `asg_node_group` module.

## Usage

```hcl
module "cluster" {
  source = "cookpad/eks/aws//modules/cluster"

  name = "sal-9000"

  vpc_config = module.vpc.config
  iam_config = module.iam.config
}
```

[see example](../../examples/cluster/main.tf)

## Features

* Provision a Kubernetes Control Plane by creating and configuring an EKS cluster.
  * Configure cloudwatch logging for the control plane
  * Configures [envelope encryption](https://aws.amazon.com/about-aws/whats-new/2020/03/amazon-eks-adds-envelope-encryption-for-secrets-with-aws-kms/) for Kubernetes secrets with KMS
* Provisions a node group dedicated to running critical cluster level services:
  * [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
  * [metrics-server](https://github.com/kubernetes-sigs/metrics-server)
  * [prometheus-node-exporter](https://github.com/prometheus/node_exporter)
  * [aws-node-termination-handler](https://github.com/aws/aws-node-termination-handler)
* Configures EKS [cluster authentication](https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html)
* Provisions security groups for node to cluster and infra node communication.
* Supports [IAM Roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## aws-auth mappings

In order to map IAM Roles or Users to Kubernetes groups you can provide config
in `aws_auth_role_map` and `aws_auth_user_map`.

The module automatically adds the node role to the `system:bootstrappers` and
`system:nodes` groups (that are required for nodes to join the cluster).

example:

```hcl
module "cluster" {
  source = "cookpad/eks/aws//modules/cluster"
  ...
  aws_auth_role_map = [
    {
      username = "PowerUser"
      role_arn = "arn:aws:iam::123456789000:role/PowerUser"
      groups   = ["system:masters"]
    },
    {
      username = "ReadOnlyUser"
      role_arn = "arn:aws:iam::123456789000:role/ReadonlyUser"
      groups   = ["system:basic-user"]
    }
  ]

  aws_user_role_map = [
    {
      username = "cookpadder"
      role_arn = "arn:aws:iam::123456789000:user/admin/cookpadder"
      groups   = ["system:masters"]
    }
  ]
```

## Secret encryption

This feature is enabled by default, but may be disabled by setting
`envelope_encryption_enabled = false`

When enabled secrets are automatically encrypted with a Kubernetes-generated
data encryption key, which is then encrypted using a KMS master key.

By default a new KMS customer master key is generated per cluster, but you may
specify the arn of an existing key by setting `kms_cmk_arn`

## Cluster critical add-ons

By default all addons are setup. If you want to disable this behaviour you may
by setting some or all of:

```hcl
cluster_autoscaler           = false
metrics_server               = false
prometheus_node_exporter     = false
aws_node_termination_handler = false
nvidia_device_plugin         = false
```

Note that setting these values to false will not remove provisioned add-ons
from an existing cluster.

By default if the cluster autoscaler is enabled an IAM role is provisioned to
provide the appropriate permissions to alter managed auto scaling groups. If
you wish to manage this IAM role externally you should set
`cluster_autoscaler_iam_role_arn`
