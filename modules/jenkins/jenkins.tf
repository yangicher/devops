resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "aws_iam_role" "jenkins" {
  name = "${var.cluster_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = var.oidc_provider_arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com",
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "jenkins_ecr" {
  name        = "${var.cluster_name}-jenkins-ecr"
  description = "Allows Jenkins agents to push images to ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_ecr.arn
}

resource "kubernetes_secret" "github" {
  metadata {
    name      = "jenkins-github"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    username = var.github_username
    token    = var.github_token
  }

  type = "Opaque"
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  timeout = 900

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_user           = var.admin_user
      admin_password       = var.admin_password
      service_account_name = var.service_account_name
      role_arn             = aws_iam_role.jenkins.arn
      storage_class        = var.storage_class
      storage_size         = var.storage_size
      cpu_request          = var.controller_resources.requests.cpu
      memory_request       = var.controller_resources.requests.memory
      cpu_limit            = var.controller_resources.limits.cpu
      memory_limit         = var.controller_resources.limits.memory
      github_secret_name   = kubernetes_secret.github.metadata[0].name
      github_repo_url      = var.github_repo_url
      ecr_repository_url   = var.ecr_repository_url
      aws_region           = var.aws_region
      values_file_path     = var.values_file_path
      git_branch           = var.git_branch
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.jenkins_ecr,
    kubernetes_secret.github,
  ]
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  depends_on = [helm_release.jenkins]
}
