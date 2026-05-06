#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════
# Repo Analyzer — Bootstrap
# Клонує репозиторії зі списку repos.txt і готує середовище
# ═══════════════════════════════════════════════════════════

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="$ROOT_DIR/repos"
OUTPUT_DIR="$ROOT_DIR/output"
REPOS_LIST="$ROOT_DIR/repos.txt"

echo "╔══════════════════════════════════════════════╗"
echo "║  Repo Analyzer — Bootstrap                   ║"
echo "╚══════════════════════════════════════════════╝"

# ── Перевірка repos.txt ──
if [ ! -f "$REPOS_LIST" ]; then
  echo ""
  echo "❌ Файл repos.txt не знайдено!"
  echo ""
  echo "Створи repos.txt в кореневій папці — по одному URL на рядок:"
  echo ""
  echo "  https://github.com/user/repo-one.git"
  echo "  https://github.com/user/repo-two.git"
  echo "  https://github.com/org/repo-three.git"
  echo ""
  echo "Підтримуються: GitHub, GitLab, Bitbucket — будь-який git URL."
  echo "Пусті рядки та рядки з # ігноруються."
  exit 1
fi

# ── Клонування ──
mkdir -p "$REPOS_DIR"

TOTAL=0
SUCCESS=0
FAILED=0

echo ""
echo "📦 Клонуємо репозиторії..."
echo ""

while IFS= read -r line || [ -n "$line" ]; do
  # Пропускаємо пусті рядки і коментарі
  line=$(echo "$line" | xargs)
  [[ -z "$line" || "$line" == \#* ]] && continue

  TOTAL=$((TOTAL + 1))

  # Витягуємо ім'я репо з URL
  repo_name=$(basename "$line" .git)
  # Додаємо порядковий номер для однозначності
  target="$REPOS_DIR/$(printf "%02d" $TOTAL)-$repo_name"

  if [ -d "$target" ]; then
    echo "  ✓ [$TOTAL] $repo_name (вже існує)"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  ⏳ [$TOTAL] $repo_name ..."
    if git clone --depth 1 --quiet "$line" "$target" 2>/dev/null; then
      echo "  ✅ [$TOTAL] $repo_name — OK"
      SUCCESS=$((SUCCESS + 1))
    else
      echo "  ❌ [$TOTAL] $repo_name — ПОМИЛКА (перевір URL: $line)"
      FAILED=$((FAILED + 1))
    fi
  fi
done < "$REPOS_LIST"

# ── Створення структури виходу ──
echo ""
echo "📁 Створюємо вихідну структуру..."

mkdir -p "$OUTPUT_DIR"/{analysis,per-repo,connections,obsidian-vault/{00-moc,01-repos,02-architecture,03-components,04-connections,05-runbooks,06-recommendations}}

# ── Генерація зведення ──
echo ""
echo "📋 Генеруємо зведення..."

SUMMARY="$OUTPUT_DIR/analysis/repos-inventory.md"
echo "# Repository Inventory" > "$SUMMARY"
echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$SUMMARY"
echo "Total repos: $SUCCESS" >> "$SUMMARY"
echo "" >> "$SUMMARY"

for repo_dir in "$REPOS_DIR"/*/; do
  [ ! -d "$repo_dir" ] && continue
  repo_name=$(basename "$repo_dir")
  echo "  📄 $repo_name"

  echo "## $repo_name" >> "$SUMMARY"
  echo "" >> "$SUMMARY"

  # README excerpt
  for readme in README.md readme.md README.rst README; do
    if [ -f "$repo_dir/$readme" ]; then
      echo "### README (first 80 lines)" >> "$SUMMARY"
      echo '```' >> "$SUMMARY"
      head -80 "$repo_dir/$readme" >> "$SUMMARY"
      echo '```' >> "$SUMMARY"
      break
    fi
  done
  echo "" >> "$SUMMARY"

  # File structure (3 levels, no .git)
  echo "### Structure" >> "$SUMMARY"
  echo '```' >> "$SUMMARY"
  find "$repo_dir" -maxdepth 3 \
    -not -path '*/.git/*' -not -name '.git' \
    -not -path '*/node_modules/*' -not -path '*/__pycache__/*' \
    -not -path '*/.terraform/*' -not -path '*/venv/*' | \
    sed "s|$repo_dir||" | sort | head -200 >> "$SUMMARY"
  echo '```' >> "$SUMMARY"
  echo "" >> "$SUMMARY"

  # Key config files
  echo "### Key Files" >> "$SUMMARY"
  echo '```' >> "$SUMMARY"
  find "$repo_dir" -maxdepth 5 \( \
    -name "*.tf" -o -name "*.tfvars" -o -name "*.hcl" \
    -o -name "*.yml" -o -name "*.yaml" \
    -o -name "Dockerfile" -o -name "docker-compose*.yml" \
    -o -name "Makefile" -o -name "Jenkinsfile" \
    -o -name "*.py" -o -name "*.go" -o -name "*.js" -o -name "*.ts" \
    -o -name "package.json" -o -name "requirements.txt" -o -name "go.mod" \
    -o -name "Cargo.toml" -o -name "pom.xml" -o -name "build.gradle" \
    -o -name ".env.example" -o -name "*.sh" \
  \) -not -path '*/.git/*' -not -path '*/node_modules/*' \
    -not -path '*/.terraform/*' -not -path '*/venv/*' | \
    sed "s|$repo_dir||" | sort >> "$SUMMARY"
  echo '```' >> "$SUMMARY"
  echo "" >> "$SUMMARY"

  # Detect language/tech stack
  echo "### Auto-detected Stack" >> "$SUMMARY"
  [ -f "$repo_dir/package.json" ] && echo "- Node.js / JavaScript" >> "$SUMMARY"
  [ -f "$repo_dir/requirements.txt" ] || [ -f "$repo_dir/setup.py" ] || [ -f "$repo_dir/pyproject.toml" ] && echo "- Python" >> "$SUMMARY"
  [ -f "$repo_dir/go.mod" ] && echo "- Go" >> "$SUMMARY"
  [ -f "$repo_dir/Cargo.toml" ] && echo "- Rust" >> "$SUMMARY"
  find "$repo_dir" -maxdepth 3 -name "*.tf" -not -path '*/.git/*' | head -1 | grep -q . && echo "- Terraform" >> "$SUMMARY"
  find "$repo_dir" -maxdepth 3 -name "Dockerfile" -not -path '*/.git/*' | head -1 | grep -q . && echo "- Docker" >> "$SUMMARY"
  [ -d "$repo_dir/.github/workflows" ] && echo "- GitHub Actions" >> "$SUMMARY"
  find "$repo_dir" -maxdepth 3 -name "azure-pipelines.yml" -not -path '*/.git/*' | head -1 | grep -q . && echo "- Azure Pipelines" >> "$SUMMARY"
  find "$repo_dir" -maxdepth 3 -name "Jenkinsfile" -not -path '*/.git/*' | head -1 | grep -q . && echo "- Jenkins" >> "$SUMMARY"
  [ -f "$repo_dir/docker-compose.yml" ] || [ -f "$repo_dir/docker-compose.yaml" ] && echo "- Docker Compose" >> "$SUMMARY"
  find "$repo_dir" -maxdepth 4 -name "Chart.yaml" -not -path '*/.git/*' | head -1 | grep -q . && echo "- Helm" >> "$SUMMARY"
  find "$repo_dir" -maxdepth 4 -name "kustomization.yaml" -not -path '*/.git/*' | head -1 | grep -q . && echo "- Kustomize" >> "$SUMMARY"
  echo "" >> "$SUMMARY"
  echo "---" >> "$SUMMARY"
  echo "" >> "$SUMMARY"
done

# ── Підсумок ──
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bootstrap завершено!                        ║"
echo "╠══════════════════════════════════════════════╣"
printf "║  Репозиторії: %d/%d (failed: %d)             ║\n" "$SUCCESS" "$TOTAL" "$FAILED"
echo "║                                              ║"
echo "║  Далі: відкрий папку в VS Code               ║"
echo "║  і попроси Claude Code виконати CLAUDE.md     ║"
echo "╚══════════════════════════════════════════════╝"
