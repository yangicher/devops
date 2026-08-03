# Гнучкий Terraform-модуль для баз даних

Проєкт розгортає інфраструктуру в AWS і містить універсальний модуль `rds`, який
створює **або** звичайну RDS-інстанцію, **або** Aurora-кластер — залежно від одного
прапора `use_aurora`.

Повна документація модуля: [`modules/rds/README.md`](modules/rds/README.md).

## Структура

```
.
├── main.tf                  # Підключення модулів
├── backend.tf               # S3 + DynamoDB для стейту
├── outputs.tf               # Загальні виводи
│
├── modules/
│   ├── s3-backend/          # S3 бакет + DynamoDB
│   ├── vpc/                 # VPC, підмережі, IGW, NAT, маршрути
│   ├── ecr/                 # ECR репозиторій
│   ├── eks/                 # EKS кластер + EBS CSI driver
│   ├── rds/                 # ✅ Універсальний модуль БД (RDS / Aurora)
│   │   ├── rds.tf           # aws_db_instance
│   │   ├── aurora.tf        # aws_rds_cluster + instances
│   │   ├── shared.tf        # subnet group, security group, parameter groups
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── jenkins/             # Helm-установка Jenkins
│   └── argo_cd/             # Helm-установка Argo CD + чарт для Application
│
├── charts/django-app/       # Helm-чарт Django-застосунку
└── Jenkinsfile              # CI: Kaniko → ECR → bump тегу → push
```

## Швидкий старт

```bash
terraform init

export TF_VAR_db_password='Str0ngPass123!'
export TF_VAR_jenkins_admin_password='...'
export TF_VAR_github_username='yangicher'
export TF_VAR_github_token='ghp_...'

# Звичайна RDS PostgreSQL
terraform plan -var use_aurora=false

# Aurora-кластер
terraform plan -var use_aurora=true
```

Розгорнути лише БД, без Kubernetes-частини:

```bash
terraform apply -target=module.vpc -target=module.rds
```

## Перемикання RDS ↔ Aurora

Єдина змінна керує тим, що буде створено:

```bash
terraform apply -var use_aurora=false   # aws_db_instance
terraform apply -var use_aurora=true    # aws_rds_cluster + writer
```

`main.tf` підбирає узгоджені `engine` та `instance_class` під обраний режим:

```hcl
engine         = var.use_aurora ? "aurora-postgresql" : "postgres"
instance_class = var.use_aurora ? "db.t3.medium" : "db.t4g.micro"
```

Спільні ресурси — DB Subnet Group, Security Group, Parameter Group — створюються
в обох випадках, тому перемикання не зачіпає мережеву частину.

## Виводи

```bash
terraform output db_endpoint          # хост БД
terraform output db_reader_endpoint   # reader endpoint (Aurora)
terraform output db_port              # 5432 або 3306
terraform output db_is_aurora         # який режим створено
```

## Що врахувати

- Aurora потребує щонайменше `db.t3.medium` і **не входить у Free Tier**.
- Для звичайної RDS `db.t4g.micro` підпадає під Free Tier.
- `subnet_ids` має містити мінімум дві підмережі в різних зонах доступності —
  це перевіряється валідацією змінної.
