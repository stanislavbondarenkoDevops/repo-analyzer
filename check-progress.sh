#!/bin/bash
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/output"

echo "╔══════════════════════════════════════════════╗"
echo "║  Repo Analyzer — Progress                    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Repos
repo_count=$(ls -d "$ROOT"/repos/*/ 2>/dev/null | wc -l)
echo "📦 Repos cloned: $repo_count"

# Phase 1
[ -f "$OUT/analysis/inventory.md" ] && echo "✅ Phase 1: inventory.md" || echo "❌ Phase 1: inventory"

# Phase 2
per_repo=$(find "$OUT/per-repo" -name "*.md" 2>/dev/null | wc -l)
echo "📄 Phase 2: $per_repo/$repo_count per-repo analyses"

# Phase 3
conn_count=$(find "$OUT/connections" -name "*.md" 2>/dev/null | wc -l)
echo "🔗 Phase 3: $conn_count/6 connection docs"

# Phase 4 (unified arch is in connections)
[ -f "$OUT/connections/unified-architecture.md" ] && echo "✅ Phase 4: unified architecture" || echo "❌ Phase 4: unified architecture"

# Phase 5
obs_count=$(find "$OUT/obsidian-vault" -name "*.md" 2>/dev/null | wc -l)
echo "📝 Phase 5: $obs_count Obsidian notes"

# Phase 6
[ -f "$OUT/REPORT.md" ] && echo "✅ Phase 6: REPORT.md" || echo "❌ Phase 6: REPORT.md"
[ -f "$OUT/QUICKSTART.md" ] && echo "✅ Phase 6: QUICKSTART.md" || echo "❌ Phase 6: QUICKSTART.md"
