locals {
  is_postgres = length(regexall("postgres", var.engine)) > 0

  default_port = local.is_postgres ? 5432 : 3306
  port         = var.port != null ? var.port : local.default_port

  major_version = split(".", var.engine_version)[0]

  parameter_group_family = var.parameter_group_family != "" ? var.parameter_group_family : (
    local.is_postgres
    ? "${var.engine}${local.major_version}"
    : "${var.engine}${local.major_version}.0"
  )

  base_parameters = local.is_postgres ? {
    max_connections = { value = "100", apply_method = "pending-reboot" }
    log_statement   = { value = "ddl", apply_method = "immediate" }
    work_mem        = { value = "4096", apply_method = "immediate" }
    } : {
    max_connections  = { value = "100", apply_method = "pending-reboot" }
    general_log      = { value = "1", apply_method = "immediate" }
    sort_buffer_size = { value = "262144", apply_method = "immediate" }
  }

  parameters = merge(local.base_parameters, var.parameters)

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "terraform"
    Module    = "rds"
  })
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-subnet-group"
  description = "Підмережі для ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = local.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Доступ до БД ${var.name} на порту ${local.port}"
  vpc_id      = var.vpc_id

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "Доступ з ${each.value}"
  cidr_ipv4         = each.value
  from_port         = local.port
  to_port           = local.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Доступ з security group ${count.index + 1}"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Весь вихідний трафік"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-instance-pg"
  family      = local.parameter_group_family
  description = "Параметри інстансу для ${var.name}"

  dynamic "parameter" {
    for_each = var.use_aurora ? {} : local.parameters

    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-cluster-pg"
  family      = local.parameter_group_family
  description = "Параметри кластера для ${var.name}"

  dynamic "parameter" {
    for_each = local.parameters

    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
