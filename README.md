# devops

Django-застосунок і інфраструктура для домашніх завдань курсу DevOps.

| Тема | Що всередині | Де |
|---|---|---|
| 4 | Django + Postgres + nginx у Docker Compose | `Dockerfile`, `docker-compose.yml`, `nginx/`, `myproject/` |
| 7 | EKS + ECR + Helm-чарт | [`lesson-7/`](lesson-7/README.md) |

Повний опис lesson-7 (модулі Terraform, завантаження образу в ECR, розгортання
Helm-чарту, перевірка HPA) — у [lesson-7/README.md](lesson-7/README.md).

## Запуск локально (тема 4)

```bash
docker compose up --build
curl http://localhost/healthz/
```
