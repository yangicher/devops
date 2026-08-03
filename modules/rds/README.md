# Terraform-модуль `rds`

Універсальний модуль, який залежно від прапора `use_aurora` створює **або** звичайну
RDS-інстанцію, **або** Aurora-кластер із заданою кількістю інстансів. В обох випадках
модуль сам створює DB Subnet Group, Security Group і Parameter Group.

## Що створюється

| Ресурс | `use_aurora = false` | `use_aurora = true` |
|---|---|---|
| `aws_db_instance` | ✅ одна інстанція | — |
| `aws_rds_cluster` | — | ✅ кластер |
| `aws_rds_cluster_instance` | — | ✅ `aurora_instance_count` штук (перший — writer) |
| `aws_db_subnet_group` | ✅ | ✅ |
| `aws_security_group` + правила | ✅ | ✅ |
| `aws_db_parameter_group` | ✅ з параметрами | ✅ для інстансів |
| `aws_rds_cluster_parameter_group` | — | ✅ з параметрами |

## Приклад: звичайна PostgreSQL RDS

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "lesson-db"
  use_aurora = false

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t4g.micro"
  multi_az       = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks        = [module.vpc.vpc_cidr_block]
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  db_name  = "djangodb"
  username = "djangoadmin"
  password = var.db_password
}
```

## Приклад: Aurora PostgreSQL з writer + reader

Той самий блок, змінюються лише чотири рядки:

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "lesson-db"
  use_aurora = true                    # <—

  engine                = "aurora-postgresql"   # <—
  engine_version        = "16.4"
  instance_class        = "db.t3.medium"        # <— Aurora не підтримує t4g.micro
  aurora_instance_count = 2                     # <— 1 writer + 1 reader

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  db_name  = "djangodb"
  username = "djangoadmin"
  password = var.db_password
}
```

## Приклад: MySQL замість PostgreSQL

Модуль сам підставить порт 3306 і набір параметрів для MySQL:

```hcl
module "rds" {
  source = "./modules/rds"

  name           = "lesson-db"
  use_aurora     = false
  engine         = "mysql"
  engine_version = "8.0.39"
  instance_class = "db.t4g.micro"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  password   = var.db_password
}
```

## Як що змінити

| Задача | Що зробити |
|---|---|
| Перемкнути RDS ↔ Aurora | `use_aurora = true/false` + узгодити `engine` і `instance_class` |
| Змінити тип БД | `engine = "mysql"` або `"postgres"`; порт і параметри підставляються самі |
| Змінити версію | `engine_version = "15.7"` — родина parameter group перерахується автоматично |
| Змінити клас інстансу | `instance_class = "db.t3.small"` |
| Увімкнути відмовостійкість | `multi_az = true` (звичайна RDS) або `aurora_instance_count = 2` (Aurora) |
| Додати читальні репліки Aurora | `aurora_instance_count = 3` |
| Перевизначити параметри БД | `parameters = { max_connections = { value = "500", apply_method = "pending-reboot" } }` |
| Відкрити доступ застосунку | `allowed_security_group_ids = [<sg нод>]` або `allowed_cidr_blocks` |
| Готувати до продакшену | `deletion_protection = true`, `skip_final_snapshot = false`, `backup_retention_period = 30` |

## Змінні

### Основні

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `use_aurora` | `bool` | `false` | `true` — Aurora-кластер, `false` — одна RDS-інстанція |
| `name` | `string` | — | **Обов'язкова.** Базове ім'я для всіх ресурсів модуля |
| `engine` | `string` | `"postgres"` | `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql`. Перевіряється валідацією |
| `engine_version` | `string` | `"16.4"` | Версія рушія |
| `instance_class` | `string` | `"db.t4g.micro"` | Клас інстансу. Aurora вимагає мінімум `db.t3.medium` |
| `multi_az` | `bool` | `false` | Standby в іншій AZ (тільки звичайна RDS) |
| `aurora_instance_count` | `number` | `1` | Кількість інстансів Aurora, 1..15. Перший — writer |

### Мережа

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `vpc_id` | `string` | — | **Обов'язкова.** VPC для security group |
| `subnet_ids` | `list(string)` | — | **Обов'язкова.** Мінімум дві підмережі в різних AZ |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDR-блоки з доступом до порту БД |
| `allowed_security_group_ids` | `list(string)` | `[]` | Security groups з доступом до порту БД |
| `publicly_accessible` | `bool` | `false` | Публічний IP для БД |

### Креденшели та база

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `db_name` | `string` | `"appdb"` | Ім'я початкової бази |
| `username` | `string` | `"dbadmin"` | Логін master-користувача |
| `password` | `string` | — | **Обов'язкова, sensitive.** Пароль, мінімум 8 символів |
| `port` | `number` | `null` | `null` — 5432 для postgres, 3306 для mysql |

### Сховище

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `allocated_storage` | `number` | `20` | Розмір диска в GB (Aurora ігнорує) |
| `max_allocated_storage` | `number` | `100` | Межа автоскейлінгу; `0` — вимкнути |
| `storage_type` | `string` | `"gp3"` | `gp2`, `gp3`, `io1` |
| `storage_encrypted` | `bool` | `true` | Шифрування сховища |
| `kms_key_id` | `string` | `null` | ARN KMS-ключа; `null` — ключ AWS за замовчуванням |

### Parameter group

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `parameter_group_family` | `string` | `""` | Порожній рядок — визначається автоматично з `engine` + `engine_version` |
| `parameters` | `map(object)` | `{}` | Перевизначає базовий набір. Формат: `{ ім'я = { value = "...", apply_method = "immediate\|pending-reboot" } }` |

Базовий набір параметрів підставляється автоматично:

- **PostgreSQL** — `max_connections` (100, pending-reboot), `log_statement` (`ddl`), `work_mem` (4096 kB)
- **MySQL** — `max_connections` (100, pending-reboot), `general_log` (1), `sort_buffer_size` (262144)

### Обслуговування

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `backup_retention_period` | `number` | `7` | Днів зберігання бекапів |
| `backup_window` | `string` | `"03:00-04:00"` | Вікно бекапів, UTC |
| `maintenance_window` | `string` | `"sun:04:30-sun:05:30"` | Вікно обслуговування |
| `deletion_protection` | `bool` | `false` | Заборона видалення через API |
| `skip_final_snapshot` | `bool` | `true` | Не робити фінальний снапшот |
| `performance_insights_enabled` | `bool` | `false` | Performance Insights |
| `monitoring_interval` | `number` | `0` | Enhanced Monitoring: 0, 1, 5, 10, 15, 30, 60 |
| `apply_immediately` | `bool` | `false` | Застосовувати зміни одразу |
| `tags` | `map(string)` | `{}` | Додаткові теги |

## Виводи

| Вивід | Опис |
|---|---|
| `endpoint` | Хост для підключення (writer endpoint для Aurora) |
| `reader_endpoint` | Reader endpoint; `null` для звичайної RDS |
| `port` | Порт БД |
| `connection_string` | Рядок підключення без пароля |
| `identifier` | Ідентифікатор кластера або інстансу |
| `arn` | ARN створеної БД |
| `is_aurora` | Який режим було створено |
| `aurora_instance_identifiers` | Список інстансів Aurora |
| `security_group_id` | ID security group БД |
| `subnet_group_name` | Ім'я DB Subnet Group |
| `parameter_group_name` | Ім'я parameter group інстансу |
| `cluster_parameter_group_name` | Ім'я cluster parameter group (Aurora) |
| `parameter_group_family` | Обрана родина parameter group |

## Як це працює всередині

Умовна логіка тримається на `count`:

```hcl
resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1
  ...
}

resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0
  ...
}
```

Спільні ресурси в `shared.tf` створюються завжди, тому перемикання `use_aurora`
не чіпає ні підмережі, ні security group.

Порт і родина parameter group обчислюються в `locals`:

```hcl
is_postgres  = length(regexall("postgres", var.engine)) > 0
default_port = local.is_postgres ? 5432 : 3306
```

Тому для `engine = "mysql"` не треба вручну ставити `port = 3306` —
модуль підставить його сам.

## Обмеження

- Aurora не працює на класах `db.t4g.micro` / `db.t3.micro` — мінімум `db.t3.medium`.
- Aurora **не входить у Free Tier**. На акаунтах із тарифом Free Tier запуск
  Aurora-інстансів відхиляється з `InvalidParameterCombination`.
- `multi_az` стосується лише звичайної RDS. Для Aurora відмовостійкість
  досягається кількома інстансами в різних AZ через `aurora_instance_count`.
- Зміна `use_aurora` на вже створеній БД означає видалення однієї БД і
  створення іншої — дані не мігрують.
