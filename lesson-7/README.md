# Lesson 7 — Kubernetes (EKS) + ECR + Helm

Кластер Kubernetes, репозиторій ECR і Helm-чарт для Django-застосунку з теми 4.

## Структура

```
lesson-7/
├── main.tf                  # Підключення модулів
├── backend.tf               # S3 + DynamoDB для стейту
├── outputs.tf               # Загальні виводи
│
├── modules/
│   ├── s3-backend/          # S3 бакет + DynamoDB (створені ще в lesson-5,
│   │                        #   вмикаються через -var create_state_backend=true)
│   ├── vpc/                 # VPC, підмережі, IGW, NAT, маршрути + теги для EKS
│   ├── ecr/                 # ECR репозиторій + policy + lifecycle
│   └── eks/                 # EKS кластер, IAM ролі, node group, аддони
│
└── charts/django-app/
    ├── Chart.yaml
    ├── values.yaml          # образ, сервіс, ConfigMap, autoscaler
    └── templates/
        ├── deployment.yaml  # образ з ECR + envFrom ConfigMap
        ├── service.yaml     # LoadBalancer
        ├── configmap.yaml   # змінні середовища з теми 4
        ├── hpa.yaml         # 2–6 подів при CPU > 70%
        └── _helpers.tpl
```

## Що створюється

| Ресурс | Значення |
|---|---|
| Регіон | `us-west-2` |
| VPC | `lesson-7-vpc`, `10.0.0.0/16`, 3 публічні + 3 приватні підмережі, IGW + NAT |
| EKS | `lesson-7-eks`, Kubernetes 1.33, публічний + приватний endpoint |
| Node group | 2× `t3.small` (min 2 / max 4) у приватних підмережах |
| Аддони | `vpc-cni`, `kube-proxy`, `coredns`, `metrics-server` (потрібен для HPA) |
| ECR | `lesson-7-django`, scan on push, зберігає останні 10 образів |

> Тип інстансу — `t3.small`, бо акаунт працює на тарифі Free Tier, який
> дозволяє запускати лише free-tier-eligible типи. З `t3.medium` node group
> падає з помилкою `AsgInstanceLaunchFailures / InvalidParameterCombination`.
> Перелік дозволених типів:
> `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`

Підмережі тегуються `kubernetes.io/cluster/lesson-7-eks=shared`,
публічні — `kubernetes.io/role/elb=1`, приватні — `kubernetes.io/role/internal-elb=1`.
Без цих тегів `Service` типу `LoadBalancer` не зміг би створити ELB.

## 1. Створення інфраструктури

```bash
cd lesson-7
terraform init
terraform plan
terraform apply
```

S3-бакет і DynamoDB-таблиця для стейту переносяться з lesson-5. Якщо їх треба
створити з нуля:

```bash
terraform apply -var create_state_backend=true
```

## 2. Доступ до кластера через kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks

kubectl get nodes
kubectl get pods -A
```

Права адміністратора кластера видаються автоматично тому IAM-користувачу, який
виконав `terraform apply` (`bootstrap_cluster_creator_admin_permissions = true`).

## 3. Завантаження Docker-образу в ECR

```bash
cd ..   # корінь репозиторію, там лежить Dockerfile

ECR=$(terraform -chdir=lesson-7 output -raw ecr_repository_url)

# Логін в ECR
aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin ${ECR%%/*}

# Ноди EKS — x86_64, тому образ збираємо під linux/amd64
docker buildx build --platform linux/amd64 --provenance=false \
  -t $ECR:latest -t $ECR:$(git rev-parse --short HEAD) --push .

aws ecr describe-images --region us-west-2 --repository-name lesson-7-django
```

## 4. Розгортання Helm-чарту

```bash
helm upgrade --install django-app lesson-7/charts/django-app \
  --set image.repository=$ECR \
  --set image.tag=latest

kubectl get pods -l app.kubernetes.io/name=django-app
kubectl get svc django-app
kubectl get hpa django-app
kubectl get configmap django-app-config -o yaml
```

Зовнішня адреса застосунку (ELB піднімається 1–3 хвилини):

```bash
LB=$(kubectl get svc django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$LB/healthz/          # {"status": "ok"}
curl -I http://$LB/admin/login/   # HTTP/1.1 200 OK
```

Перевірка, що змінні з ConfigMap реально потрапили в под:

```bash
POD=$(kubectl get pod -l app.kubernetes.io/name=django-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- printenv | grep -E "DJANGO|POSTGRES|SQLITE"
```

## Змінні середовища (тема 4 → ConfigMap)

`values.yaml` → секція `config` → ConfigMap `django-app-config` → підключається
в Deployment через `envFrom.configMapRef`.

| Змінна | Значення | Звідки |
|---|---|---|
| `DJANGO_DEBUG` | `True` | settings.py теми 4 |
| `DJANGO_ALLOWED_HOSTS` | `*` | settings.py |
| `DJANGO_SECRET_KEY` | `django-insecure-…` | settings.py |
| `DJANGO_DB_ENGINE` | `django.db.backends.sqlite3` | у кластері немає окремої БД |
| `SQLITE_PATH` | `/tmp/db.sqlite3` | шлях до файлу БД у поді |
| `POSTGRES_DB` | `mydatabase` | docker-compose.yml |
| `POSTGRES_USER` | `myuser` | docker-compose.yml |
| `POSTGRES_PASSWORD` | `mypassword` | docker-compose.yml |
| `POSTGRES_HOST` | `db` | docker-compose.yml |
| `POSTGRES_PORT` | `5432` | docker-compose.yml |

`myproject/settings.py` читає ці змінні через `os.environ.get(...)` зі значеннями
за замовчуванням, тому застосунок працює однаково і в docker-compose, і в Kubernetes.
Щоб перемкнути поди на Postgres, достатньо змінити `DJANGO_DB_ENGINE` у `values.yaml`.

> Паролі в ConfigMap — навмисне спрощення для навчального завдання.
> У продакшені їх місце в `Secret` або AWS Secrets Manager.

## HPA

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70
```

HPA рахує відсоток від `resources.requests.cpu` (100m), тому requests обовʼязкові.
Метрики постачає аддон `metrics-server`.

Перевірка масштабування під навантаженням. Одного циклу `wget` не вистачає,
щоб перевищити поріг, тому запускаємо 10 паралельних:

```bash
kubectl run load-gen --image=busybox --restart=Never -- /bin/sh -c \
  'for i in 1 2 3 4 5 6 7 8 9 10; do (while true; do wget -q -O /dev/null http://django-app/admin/login/; done) & done; sleep 600'

kubectl get hpa django-app -w
```

Результат: за ~30 секунд `cpu` піднімається до ~370%/70%, а `REPLICAS`
зростає з 2 до 6 (стеля `maxReplicas`).

```
NAME         REFERENCE               TARGETS       MINPODS   MAXPODS   REPLICAS
django-app   Deployment/django-app   cpu: 372%/70%   2         6         6
```

Прибрати навантаження:

```bash
kubectl delete pod load-gen
```

Поди повертаються до 2 не одразу — типово через ~5 хвилин, це стандартне
вікно стабілізації `scaleDown` у HPA.

## Видалення

```bash
helm uninstall django-app          # спершу знести LoadBalancer,
                                   # інакше ELB завадить видалити VPC
cd lesson-7 && terraform destroy
```
