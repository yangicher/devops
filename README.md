# Фінальний проєкт DevOps — AWS + Terraform + Kubernetes + CI/CD + моніторинг

Повністю автоматизована інфраструктура в AWS: мережа, Kubernetes-кластер, база даних,
реєстр образів, CI/CD (Jenkins + Argo CD) і моніторинг (Prometheus + Grafana).
Django-застосунок збирається пайплайном, публікується в ECR і синхронізується
в кластер через GitOps.

## Архітектура

```
                          ┌──────────────────────── AWS ────────────────────────┐
                          │                                                      │
   GitHub ──webhook/poll──┼──► Jenkins (EKS, ns jenkins)                         │
     ▲                    │        │ Kaniko build                                │
     │ git push tag       │        ▼                                             │
     │                    │      ECR ──── pull ────┐                             │
     │                    │                        │                             │
     └──── Argo CD ◄──────┼── ns argocd            ▼                             │
           (GitOps sync)  │                  django-app (ns default)             │
                          │                    │  HPA 2..6 @ 70% CPU             │
                          │                    ▼                                 │
                          │                  RDS PostgreSQL (private subnets)    │
                          │                                                      │
                          │   Prometheus + Grafana (ns monitoring) ◄── метрики   │
                          └──────────────────────────────────────────────────────┘
```

| Шар | Ресурси |
|---|---|
| Мережа | VPC `10.0.0.0/16`, 3 публічні + 3 приватні підмережі в різних AZ, IGW, NAT |
| Кластер | EKS 1.33, managed node group `c7i-flex.large`, аддони vpc-cni / kube-proxy / coredns / metrics-server / EBS CSI |
| База даних | RDS PostgreSQL 16 (або Aurora через `use_aurora`) у приватних підмережах |
| Реєстр | ECR зі скануванням образів і lifecycle-політикою |
| CI | Jenkins (Helm), агенти в Kubernetes, збірка через Kaniko |
| CD | Argo CD (Helm), Application з auto-sync, prune і selfHeal |
| Моніторинг | kube-prometheus-stack: Prometheus, Grafana, node-exporter, kube-state-metrics |

## Структура

```
.
├── main.tf                  # Підключення всіх модулів
├── backend.tf               # S3 + DynamoDB для стейту
├── outputs.tf               # Загальні виводи
│
├── modules/
│   ├── s3-backend/          # S3 бакет + DynamoDB таблиця блокувань
│   ├── vpc/                 # VPC, підмережі, IGW, NAT, маршрути
│   ├── ecr/                 # ECR репозиторій
│   ├── eks/                 # EKS кластер, IAM, node group, EBS CSI driver
│   ├── rds/                 # Універсальний модуль БД: RDS або Aurora
│   ├── jenkins/             # Helm-установка Jenkins
│   ├── argo_cd/             # Helm-установка Argo CD + чарт Application/Repository
│   └── monitoring/          # Helm-установка Prometheus + Grafana
│
├── charts/django-app/       # Helm-чарт застосунку (deployment, service, configmap, hpa)
│
└── Django/
    ├── app/                 # Код Django
    ├── Dockerfile
    ├── Jenkinsfile          # CI: Kaniko → ECR → bump тегу → git push
    ├── docker-compose.yaml  # Локальний запуск
    └── nginx/
```

## 1. Підготовка середовища

Потрібні: `terraform >= 1.0`, `awscli`, `kubectl`, `helm`, налаштований AWS-профіль.

```bash
terraform init
```

Обов'язкові змінні (передаються через оточення, у файли не потрапляють):

| Змінна | Призначення |
|---|---|
| `TF_VAR_db_password` | Пароль master-користувача БД |
| `TF_VAR_jenkins_admin_password` | Пароль адміністратора Jenkins |
| `TF_VAR_grafana_admin_password` | Пароль адміністратора Grafana |
| `TF_VAR_github_username` | Користувач GitHub для push тегів |
| `TF_VAR_github_token` | PAT з правом запису в репозиторій |

```bash
export TF_VAR_db_password='...'
export TF_VAR_jenkins_admin_password='...'
export TF_VAR_grafana_admin_password='...'
export TF_VAR_github_username='yangicher'
export TF_VAR_github_token='github_pat_...'
```

Перевірити план перед розгортанням:

```bash
terraform plan -var git_branch=final-project
```

## 2. Розгортання інфраструктури

```bash
terraform apply -var git_branch=final-project
```

Створення займає близько 25–30 хвилин (EKS control plane ~10 хв, node group ~5 хв,
RDS ~10 хв, Helm-релізи ~5 хв).

Налаштувати доступ до кластера:

```bash
aws eks update-kubeconfig --region us-west-2 --name final-eks
kubectl get nodes
```

Перевірити стан ресурсів:

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get all -n default
```

## 3. Перевірка доступності

```bash
# Jenkins
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
# http://localhost:8080 — логін admin, пароль з TF_VAR_jenkins_admin_password

# Argo CD
kubectl port-forward svc/argocd-server 8081:443 -n argocd
# https://localhost:8081 — логін admin
terraform output -raw argocd_admin_password
```

Усі сервіси також підняті як LoadBalancer:

```bash
terraform output jenkins_url
terraform output argocd_url
terraform output grafana_url
```

## 4. Моніторинг і метрики

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
# http://localhost:3000 — логін admin, пароль з TF_VAR_grafana_admin_password
```

Prometheus:

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```

Що перевіряти в Grafana (дашборди ставляться автоматично):

| Дашборд | Що показує |
|---|---|
| Kubernetes / Compute Resources / Cluster | CPU і пам'ять усього кластера |
| Kubernetes / Compute Resources / Namespace (Pods) | Споживання по подах `django-app` |
| Node Exporter / Nodes | Завантаження worker-нод |
| Kubernetes / Persistent Volumes | Використання дисків Jenkins і Prometheus |

Перевірити, що метрики збираються:

```bash
kubectl get servicemonitors -A
kubectl top nodes
kubectl top pods -A
```

## CI/CD

Pipeline `django-app` у Jenkins виконує:

1. **Checkout** — клонує репозиторій, обчислює тег `build-<N>-<sha>`;
2. **Build and push image** — Kaniko збирає образ з `Django/Dockerfile` і пушить у ECR
   (авторизація через IRSA, без статичних ключів);
3. **Bump chart tag** — підставляє новий тег у `charts/django-app/values.yaml`,
   комітить і пушить у гілку.

Argo CD бачить новий коміт і синхронізує застосунок у кластер автоматично
(`automated`, `prune`, `selfHeal`).

Запустити збірку:

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
# Jenkins → django-app → Build Now
```

Перевірити результат:

```bash
aws ecr describe-images --region us-west-2 --repository-name final-django
kubectl get application django-app -n argocd
kubectl get pods -n default -o jsonpath='{.items[*].spec.containers[0].image}'
```

## Безпека

| Рівень | Що зроблено |
|---|---|
| Мережа | Worker-ноди і RDS — тільки в приватних підмережах; вихід в інтернет через NAT |
| Security Groups | Доступ до БД лише з CIDR VPC і security group кластера, на єдиному порту |
| IAM (кластер) | Окремі ролі для control plane і нод з мінімальним набором керованих політик |
| IAM (агенти) | IRSA: агенти Jenkins отримують роль через OIDC; політика ECR обмежена ARN конкретного репозиторію |
| IAM (EBS CSI) | Окрема роль через IRSA лише з `AmazonEBSCSIDriverPolicy` |
| Доступ до кластера | `bootstrap_cluster_creator_admin_permissions`, режим `API_AND_CONFIG_MAP` |
| Секрети | Паролі й токени передаються через `TF_VAR_*`, у Git не зберігаються; у кластері — Kubernetes Secret |
| Дані | Шифрування сховища RDS і стейту в S3, версіонування бакета |

## Автомасштабування

| Рівень | Механізм | Параметри |
|---|---|---|
| Поди | HPA | 2–6 реплік при CPU > 70% |
| Ноди | Node group | min 2, max 4 |
| Диск БД | RDS storage autoscaling | 20 → 100 GB |

Перевірити HPA:

```bash
kubectl get hpa django-app -n default

# згенерувати навантаження
kubectl run load-gen --image=busybox --restart=Never -- /bin/sh -c \
  'for i in 1 2 3 4 5 6 7 8 9 10; do (while true; do wget -q -O /dev/null http://django-app/admin/login/; done) & done; sleep 600'

kubectl get hpa django-app -w
kubectl delete pod load-gen
```

## База даних

Модуль `rds` універсальний — прапор `use_aurora` перемикає між звичайною
інстанцією та Aurora-кластером:

```bash
terraform apply -var use_aurora=false   # aws_db_instance (за замовчуванням)
terraform apply -var use_aurora=true    # aws_rds_cluster + writer
```

Terraform кладе параметри підключення в Kubernetes Secret `django-db`,
а чарт підхоплює його через `envFrom`, тому застосунок працює з RDS без
ручного редагування values. Деталі — у [`modules/rds/README.md`](modules/rds/README.md).

## Видалення ресурсів

> ⚠️ Порядок важливий: спершу зносяться LoadBalancer-сервіси, інакше ELB
> не дадуть видалити підмережі й VPC.

```bash
helm uninstall django-app -n default
helm uninstall jenkins -n jenkins
helm uninstall argocd argocd-apps -n argocd
helm uninstall kube-prometheus-stack -n monitoring

terraform destroy -var git_branch=final-project
```

> ⚠️ S3-бакет і DynamoDB-таблиця зі стейтом створюються окремим модулем
> `s3-backend` і за замовчуванням **вимкнені** (`create_state_backend = false`),
> щоб `terraform destroy` не знищив власний бекенд. Якщо бекенд треба підняти
> з нуля — `terraform apply -var create_state_backend=true`, і робити це
> **першим кроком**, до решти інфраструктури.

## Обмеження оточення

- Акаунт працює на тарифі Free Tier, який дозволяє лише free-tier-eligible типи
  інстансів. `t3.medium` відхиляється з `InvalidParameterCombination`; використано
  `c7i-flex.large`. Перелік дозволених:
  `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`
- Aurora не входить у Free Tier, тому за замовчуванням `use_aurora = false`.
- Образи збираються під `linux/amd64` — ноди x86_64.
