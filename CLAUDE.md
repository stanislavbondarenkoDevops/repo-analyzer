# Repo Analyzer — Universal Codebase Cartographer

Ти — senior software architect, який проводить повний аудит кодових баз. Твоя задача: проаналізувати всі репозиторії в `repos/`, зрозуміти як кожен працює, як вони повʼязані між собою, і створити повну документацію.

## Як працювати

1. Спочатку переконайся що bootstrap виконаний — папка `repos/` має містити склоновані репозиторії. Якщо ні — запусти `./00-bootstrap.sh`.
2. Виконуй фази послідовно, не зупиняйся між ними.
3. Для КОЖНОГО репо — читай реальний код, не тільки README.
4. Якщо репозиторіїв багато (>10) — після Фази 1 запитай чи аналізувати всі, чи юзер хоче вибрати підмножину.

---

## ФАЗА 1: Інвентаризація

Прочитай `output/analysis/repos-inventory.md` (створений bootstrap). Потім для кожного репо в `repos/`:

1. **Визнач тип репо:**
   - application (backend / frontend / fullstack / mobile)
   - infrastructure (Terraform / Pulumi / CloudFormation)
   - pipeline (CI/CD configs, automation)
   - library (SDK, shared package, utility)
   - configuration (Helm charts, K8s manifests, ArgoCD apps)
   - documentation (docs, runbooks, guides)
   - monorepo (кілька типів в одному)

2. **Визнач tech stack** — не з назви файлів, а з реального коду:
   - Мови програмування + версії (з go.mod, package.json, pyproject.toml)
   - Frameworks (React, FastAPI, Spring, etc.)
   - Databases (з connection strings, ORM configs, migrations)
   - Message queues (Kafka, RabbitMQ, SQS)
   - Cloud services (з Terraform resources, SDK imports)
   - CI/CD tools (з workflow файлів)

3. **Визнач entry points:**
   - main.go / main.py / index.ts / cmd/
   - Dockerfile ENTRYPOINT/CMD
   - Makefile targets
   - CI/CD trigger events

Створи: `output/analysis/inventory.md` — таблиця з колонками: Repo | Type | Languages | Frameworks | Cloud | CI/CD | Database | Entry Point

---

## ФАЗА 2: Глибокий аналіз кожного репо

Для КОЖНОГО репо створи окремий файл `output/per-repo/{repo-name}.md`.

Читай реальний код — не здогадуйся з назв файлів. Для кожного репо:

### 2.1 Архітектура
- Яка архітектура: monolith / microservice / serverless / event-driven / static site
- Діаграма компонентів (Mermaid):
  ```
  Які модулі/пакети є → як вони повʼязані → що від чого залежить
  ```
- Де бізнес-логіка, де інфраструктурний код, де конфігурація

### 2.2 Data Flow
- Звідки приходять дані (API, UI, queue, cron, webhook)
- Як дані трансформуються (pipeline, handlers, middleware)
- Куди дані йдуть (DB, cache, external API, queue, file storage)
- Mermaid sequence diagram основного flow

### 2.3 API Surface
- Які endpoints/routes/commands expose (прочитай router/controller файли)
- Формат: method, path, auth required, short description
- Які external APIs викликаються (HTTP clients, SDK calls)

### 2.4 Infrastructure
- Які cloud ресурси створюються (якщо є Terraform/CDK/CloudFormation):
  - Compute (EC2, EKS, Lambda, Cloud Run)
  - Storage (S3, RDS, DynamoDB, Cloud SQL)
  - Networking (VPC, LB, DNS)
  - Security (IAM, KMS, secrets)
- Environments: dev / staging / prod — як розділені

### 2.5 CI/CD Pipeline
- Прочитай workflow файли (.github/workflows/, azure-pipelines.yml, Jenkinsfile)
- Для кожного pipeline:
  - Trigger: on push? on PR? on tag? scheduled?
  - Stages: що відбувається по порядку
  - Secrets/variables: які потрібні
  - Deploy targets: куди деплоїть

### 2.6 Configuration & Secrets
- Які env vars потрібні (з .env.example, docker-compose, CI configs)
- Які secrets потрібні (з Terraform variables, CI secrets, K8s secrets)
- Config files: де зберігаються, який формат

### 2.7 Dependencies
- Зовнішні бібліотеки: основні (не всі, а ключові для архітектури)
- Зовнішні сервіси: які API, SaaS, managed services використовує
- Інші репо з цього набору: чи є явні залежності (imports, git submodules, shared configs)

### 2.8 Code Quality Assessment
- Чи є тести? Який coverage (приблизно, за кількістю test файлів vs source файлів)
- Чи є лінтери/форматери (.eslintrc, .flake8, .golangci.yml)
- Чи є документація в коді (docstrings, JSDoc, Go comments)
- Чи є security issues (hardcoded secrets, exposed ports, missing auth)
- Чи є deprecated dependencies або відомі vulnerabilities
- Code smells: дублювання, god objects, надто довгі функції

### 2.9 Recommendations
- 🔴 Critical: security issues, data loss risks, broken functionality
- 🟡 Important: architecture improvements, missing tests, tech debt
- 🟢 Nice to have: code style, documentation, DX improvements

---

## ФАЗА 3: Зв'язки між репозиторіями

Це найважливіша фаза — зрозуміти як репо працюють РАЗОМ.

Створи `output/connections/` з наступними файлами:

### 3.1 dependency-graph.md
Знайди звʼязки між репо:
- **Прямі залежності:** один репо імпортує/викликає інший (shared packages, API calls, git submodules)
- **Інфраструктурні залежності:** один репо створює ресурси, інший їх використовує (напр. Terraform створює RDS, app читає з нього)
- **Pipeline залежності:** один CI/CD тригерить інший, або деплоїть артефакт який використовує інший
- **Config залежності:** спільні env vars, secrets, config values
- **Data залежності:** один пише в DB/queue, інший читає

Mermaid graph:
```mermaid
graph LR
  repo-a -->|API call| repo-b
  repo-c -->|creates infra for| repo-a
  repo-a -->|publishes to| queue
  repo-d -->|consumes from| queue
```

### 3.2 shared-resources.md
Які ресурси шарять репо:
- Спільні databases
- Спільні message queues/topics
- Спільні S3 buckets / storage
- Спільні secrets / config
- Спільні docker registries
- Спільні K8s namespaces/clusters

### 3.3 deployment-order.md
В якому порядку потрібно деплоїти:
1. Infra repos першими (Terraform)
2. Shared services (databases, queues)
3. Core services
4. Dependent services
5. Frontend / edge

Mermaid deployment pipeline diagram.

### 3.4 communication-map.md
Як сервіси спілкуються runtime:
- Sync: HTTP/gRPC calls (хто кого, який endpoint)
- Async: events/messages (хто публікує, хто слухає, який topic/queue)
- Shared state: database reads/writes, cache

### 3.5 environment-matrix.md
Таблиця: Repo × Environment (dev/staging/prod)
- Як кожен репо деплоїться в кожне середовище
- Які відмінності між середовищами (feature flags, endpoints, scaling)

---

## ФАЗА 4: Unified Architecture

Створи `output/connections/unified-architecture.md` — це головний документ.

### 4.1 System Overview
Одна велика Mermaid діаграма яка показує ВСЕ:
- Всі репо як компоненти
- Всі зв'язки між ними
- External services (AWS, third-party APIs)
- Data flows
- User entry points

### 4.2 Bounded Contexts
Згрупуй репо по доменах/відповідальності:
- Який домен/бізнес-область покриває кожна група
- Чи правильно розділені boundaries
- Чи є репо які роблять забагато (порушують single responsibility)

### 4.3 Cross-cutting Concerns
Як вирішені наскрізні задачі ЧЕРЕЗ всі репо:
- Authentication/Authorization — де перевіряється, як токени передаються
- Logging — формат, куди збираються, є кореляція?
- Error handling — як помилки пропагуються між сервісами
- Monitoring — що моніториться, є alerting?
- Configuration management — як конфіги потрапляють в сервіси

### 4.4 Risk Assessment
- Single points of failure
- Repos без тестів які критичні для production
- Security gaps між репо (напр. API без auth)
- Missing observability
- Tight coupling яке ускладнює зміни

---

## ФАЗА 5: Obsidian Vault

Створи повний Obsidian vault в `output/obsidian-vault/`.

Кожна нотатка з YAML frontmatter:
```yaml
---
tags: [repo, backend, python, aws]
type: repo-analysis | architecture | connection | runbook | recommendation
status: analyzed
last_updated: YYYY-MM-DD
---
```

Використовуй [[wikilinks]] для cross-reference.

### 00-moc/index.md
Map of Content — головний індекс:
- Список всіх реп з короткими описами і посиланнями
- Архітектурний огляд з посиланням на діаграми
- Quick links на recommendations і runbooks

### 01-repos/ (по файлу на кожен репо)
Скорочена версія Фази 2 для кожного репо:
- Що це, навіщо, як працює
- Tech stack одним рядком
- Mermaid component diagram
- Ключові endpoints/commands
- Залежності ([[links]] на інші репо)
- Top 3 recommendations

### 02-architecture/
- `system-overview.md` — unified Mermaid diagram з Фази 4.1
- `data-flow.md` — як дані рухаються через систему
- `deployment-pipeline.md` — порядок деплою з Фази 3.3
- `tech-radar.md` — таблиця всіх технологій через всі репо: Technology | Category | Repos Using | Version | Status (current/deprecated/evaluate)

### 03-components/
По одному файлу на кожен "логічний компонент" системи:
- Якщо один репо = один компонент → один файл
- Якщо monorepo → кілька файлів
- Для кожного: responsibilities, API, dependencies, config needed

### 04-connections/
- `dependency-graph.md` — з Фази 3.1
- `shared-resources.md` — з Фази 3.2
- `communication-map.md` — з Фази 3.4

### 05-runbooks/
Створи runbooks для типових операцій:
- `runbook-local-setup.md` — як підняти ВСЕ локально (порядок, env vars, docker-compose)
- `runbook-deploy.md` — як задеплоїти зміни (per repo + full system)
- `runbook-troubleshooting.md` — типові проблеми і як їх вирішити
- `runbook-new-developer.md` — onboarding guide для нового девелопера

### 06-recommendations/
- `critical-fixes.md` — 🔴 issues з усіх репо, ranked by severity
- `architecture-improvements.md` — 🟡 що покращити в архітектурі
- `tech-debt.md` — список tech debt через всі репо
- `roadmap.md` — пропонований порядок виправлень (що першим)

---

## ФАЗА 6: Фінальний звіт

Створи `output/REPORT.md` — executive summary:

1. **Overview:** скільки реп, які технології, загальна архітектура (1 параграф)
2. **Architecture Diagram:** головна Mermaid діаграма
3. **Health Score per repo:** таблиця з оцінками 1-10 по категоріях:
   - Code Quality
   - Test Coverage
   - Documentation
   - Security
   - CI/CD Maturity
   - Observability
4. **Top 5 Risks:** найкритичніші проблеми через всю систему
5. **Top 5 Quick Wins:** що можна виправити швидко з найбільшим ефектом
6. **Connection Map:** коротка версія графу залежностей
7. **Recommended Next Steps:** пріоритезований план дій

Також створи `output/QUICKSTART.md`:
- Як відкрити Obsidian vault
- Де шукати що
- Як використати рекомендації

---

## Важливі правила

1. **Читай код, а не здогадуйся.** Для кожного висновку вказуй конкретний файл і рядок. Не "probably uses Redis" а "uses Redis — see `config/database.yml:14`".

2. **Кожен Mermaid diagram має бути валідним.** Перевір синтаксис перед записом.

3. **Не вигадуй зв'язки.** Якщо два репо не мають явного зв'язку — так і пиши. Краще пропустити зв'язок ніж вигадати.

4. **Security findings — конкретні.** Не "might have security issues" а "hardcoded AWS key in `deploy.sh:23`" або "API endpoint `/admin` has no auth middleware — see `routes/admin.go:8`".

5. **Рекомендації — actionable.** Не "improve testing" а "add integration tests for `/api/orders` endpoint — currently 0 tests for the order processing flow in `services/order.go`".

6. **Масштабування:** якщо реп >15, зроби поверхневий аналіз всіх (Фаза 1) і глибокий тільки для тих що мають зв'язки між собою або виглядають як core. Запитай юзера якщо не впевнений.

7. **Між фазами не зупиняйся** — йди автоматично далі, після кожної фази коротко повідом що зроблено.

8. **Мова документації** — пиши тією мовою якою юзер пише промти.
