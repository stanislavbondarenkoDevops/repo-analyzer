# Repo Analyzer

Універсальний аналізатор репозиторіїв. Закинь будь-які GitHub репо — отримаєш повний аудит: архітектура, залежності, зв'язки, рекомендації, Obsidian vault.

## Використання

```bash
# 1. Впиши URL репозиторіїв в repos.txt (по одному на рядок)
nano repos.txt

# 2. Запусти bootstrap (клонує репо, створює структуру)
chmod +x 00-bootstrap.sh check-progress.sh
./00-bootstrap.sh

# 3. Відкрий папку в VS Code і скажи Claude Code:
#    "Прочитай CLAUDE.md і виконай все з фази 1 до фази 6"

# 4. Перевіряй прогрес:
./check-progress.sh
```

## Що отримаєш

```
output/
├── analysis/          # Інвентаризація і зведені таблиці
├── per-repo/          # Повний аудит кожного репо окремо
├── connections/       # Графи залежностей, deployment order
├── obsidian-vault/    # Obsidian vault з повною документацією
├── REPORT.md          # Executive summary + health scores
└── QUICKSTART.md      # Як користуватися результатами
```
