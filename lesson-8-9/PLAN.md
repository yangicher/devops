# Lesson 8-9 — робочий план

Гілка: `lesson-8-9` (відгалужена від `lesson-7-eks`).

## Завдання

> TODO: вставити сюди умову домашнього завдання (опис, кроки, структура
> проєкту, критерії оцінювання).

### Чекліст

- [ ] ...

## Що вже є (успадковано з lesson-7)

| Ресурс | Значення |
|---|---|
| AWS акаунт | `018585551525`, користувач `yangicher` |
| Регіон | `us-west-2` |
| VPC | `vpc-057dbf67c4cab5827` (`lesson-7-vpc`, `10.0.0.0/16`) |
| Публічні підмережі | `subnet-02670905e1f13c91f`, `subnet-0205cc1cf5fe92076`, `subnet-0e1a271b603d4b4fb` |
| Приватні підмережі | `subnet-001f3fc5d59787b8f`, `subnet-0bac570bfaf869857`, `subnet-0bfa8d7580a866947` |
| EKS | `lesson-7-eks`, Kubernetes 1.33, 2× `t3.small` |
| Аддони | `vpc-cni`, `kube-proxy`, `coredns`, `metrics-server` |
| ECR | `018585551525.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django` |
| Helm release | `django-app` (namespace `default`), Service типу LoadBalancer |
| Terraform state | S3 `yangicher-devops-tf-state-2026`, ключ `lesson-7/terraform.tfstate`, лок у DynamoDB `terraform-locks` |

Швидкий доступ:

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
helm list
```

## Що знати перед роботою

1. **Free Tier обмежує типи інстансів.** `t3.medium` не запуститься —
   node group падає з `AsgInstanceLaunchFailures / InvalidParameterCombination`.
   Дозволені типи: `t3.micro`, `t3.small`, `t4g.micro`, `t4g.small`,
   `c7i-flex.large`, `m7i-flex.large`. Перевірка:
   `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`

2. **Образи треба збирати під `linux/amd64`.** Робоча машина — Apple Silicon
   (arm64), ноди — x86_64:
   `docker buildx build --platform linux/amd64 --provenance=false ... --push .`

3. **Node group не автоскейлиться.** `min 2 / max 4` — це лише межі ASG.
   HPA масштабує поди, не ноди. Для масштабування нод потрібен Cluster
   Autoscaler або Karpenter.

4. **LoadBalancer тримає VPC.** Перед `terraform destroy` обов'язково
   `helm uninstall django-app`, інакше ELB не дасть видалити підмережі.

5. **Кластер у новій `lesson-7-vpc`, а не в VPC з lesson-5.** Свідоме рішення;
   якщо lesson-8-9 вимагає ту саму мережу — це `lesson-7-vpc`.

6. **Вартість** — близько $0.23/год (control plane + 2 ноди + NAT + ELB).
   Не забувати гасити між сесіями.

## Відкриті питання

- [ ] Чи lesson-8-9 продовжує працювати на кластері lesson-7, чи створює свій?
- [ ] Чи потрібен окремий Terraform state (`lesson-8-9/terraform.tfstate`)?

## Журнал

| Дата | Що зроблено |
|---|---|
| 2026-08-02 | lesson-7 завершено: EKS + ECR + Helm, HPA перевірено (2→6), запушено в `origin/lesson-7-eks` |
| 2026-08-02 | Створено гілку `lesson-8-9`, заведено цей план |
