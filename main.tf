locals {
  base_name                 = var.base_name == null ? "sp5ft-${var.worker_pool_id}" : var.base_name
  autoscaling_enabled       = var.autoscaling_configuration == null ? false : true
  lifecycle_manager_enabled = length(var.instance_refresh) > 0 ? true : false
}

resource "aws_ssm_parameter" "spacelift_api_key_secret" {
  count = local.autoscaling_enabled || local.lifecycle_manager_enabled ? 1 : 0
  name  = "/${local.base_name}/api-secret-${var.worker_pool_id}"
  type  = "SecureString"
  value = var.spacelift_api_credentials.api_key_secret
  tags  = var.additional_tags
}

module "autoscaler" {
  count  = local.autoscaling_enabled ? 1 : 0
  source = "./autoscaler"

  additional_tags                = var.additional_tags
  api_key_ssm_parameter_arn      = aws_ssm_parameter.spacelift_api_key_secret[0].arn
  api_key_ssm_parameter_name     = aws_ssm_parameter.spacelift_api_key_secret[0].name
  auto_scaling_group_arn         = module.asg.autoscaling_group_arn
  autoscaling_configuration      = var.autoscaling_configuration
  aws_partition_dns_suffix       = data.aws_partition.current.dns_suffix
  aws_region                     = data.aws_region.this.name
  base_name                      = local.base_name
  cloudwatch_log_group_retention = var.cloudwatch_log_group_retention
  spacelift_api_credentials      = var.spacelift_api_credentials
  iam_permissions_boundary       = var.iam_permissions_boundary
  worker_pool_id                 = var.worker_pool_id
}

module "lifecycle_manager" {
  count  = local.lifecycle_manager_enabled ? 1 : 0
  source = "./lifecycle_manager"

  additional_tags                = var.additional_tags
  api_key_ssm_parameter_arn      = aws_ssm_parameter.spacelift_api_key_secret[0].arn
  api_key_ssm_parameter_name     = aws_ssm_parameter.spacelift_api_key_secret[0].name
  auto_scaling_group_arn         = module.asg.autoscaling_group_arn
  cloudwatch_log_group_retention = var.cloudwatch_log_group_retention
  aws_partition_dns_suffix       = data.aws_partition.current.dns_suffix
  aws_region                     = data.aws_region.this.name
  base_name                      = local.base_name
  iam_permissions_boundary       = var.iam_permissions_boundary
  worker_pool_id                 = var.worker_pool_id
  spacelift_api_credentials      = var.spacelift_api_credentials
}

moved {
  from = aws_iam_role.autoscaler
  to   = module.autoscaler[0].aws_iam_role.autoscaler
}

moved {
  from = aws_iam_role_policy.autoscaler
  to   = module.autoscaler[0].aws_iam_role_policy.autoscaler
}

moved {
  from = aws_lambda_function.autoscaler
  to   = module.autoscaler[0].aws_lambda_function.autoscaler
}

moved {
  from = null_resource.download
  to   = module.autoscaler[0].null_resource.download
}

moved {
  from = aws_cloudwatch_event_rule.scheduling
  to   = module.autoscaler[0].aws_cloudwatch_event_rule.scheduling
}

moved {
  from = aws_cloudwatch_event_target.scheduling
  to   = module.autoscaler[0].aws_cloudwatch_event_target.scheduling
}

moved {
  from = aws_lambda_permission.allow_cloudwatch_to_call_lambda
  to   = module.autoscaler[0].aws_lambda_permission.allow_cloudwatch_to_call_lambda
}

moved {
  from = aws_cloudwatch_log_group.log_group
  to   = module.autoscaler[0].aws_cloudwatch_log_group.log_group
}
