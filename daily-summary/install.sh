#!/usr/bin/env bash
# =============================================================================
# daily-summary — Claude Code 스킬 설치 스크립트
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/install.sh | bash
# =============================================================================

set -euo pipefail

SKILL_NAME="daily-summary"
INSTALL_DIR="$HOME/.claude/skills/$SKILL_NAME"
SCRIPTS_DIR="$INSTALL_DIR/scripts"

GITHUB_USER="dooyeoung"
GITHUB_REPO="daily-summary"
GITHUB_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH/$SKILL_NAME"

# -----------------------------------------------------------------------------
# 출력 헬퍼
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "  ${GREEN}✓${NC} $*"; }
warn()    { echo -e "  ${YELLOW}!${NC} $*"; }
error()   { echo -e "  ${RED}✗${NC} $*" >&2; exit 1; }
section() { echo -e "\n${YELLOW}▶ $*${NC}"; }

# -----------------------------------------------------------------------------
# 1. 사전 확인
# -----------------------------------------------------------------------------
section "사전 확인"

# Python 3.9+
if ! command -v python3 &>/dev/null; then
  error "python3 가 설치되어 있지 않습니다. (macOS: brew install python3)"
fi

PYTHON_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_MAJOR=$(echo "$PYTHON_VER" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VER" | cut -d. -f2)

if [[ "$PYTHON_MAJOR" -lt 3 ]] || { [[ "$PYTHON_MAJOR" -eq 3 ]] && [[ "$PYTHON_MINOR" -lt 9 ]]; }; then
  error "Python 3.9 이상이 필요합니다. (현재: $PYTHON_VER)"
fi
info "Python $PYTHON_VER"

# Claude Code 설치 여부
if [[ ! -d "$HOME/.claude" ]]; then
  error "Claude Code 설정 디렉토리($HOME/.claude)가 없습니다.\n     먼저 설치해 주세요: https://claude.ai/code"
fi
info "Claude Code 확인됨"

# -----------------------------------------------------------------------------
# 2. 파일 설치
# -----------------------------------------------------------------------------
section "파일 설치"

mkdir -p "$SCRIPTS_DIR"

download() {
  local url="$1"
  local dest="$2"
  if ! curl -fsSL "$url" -o "$dest"; then
    error "다운로드 실패: $url"
  fi
  info "$(basename "$dest")"
}

download "$RAW_BASE/SKILL.md"                    "$INSTALL_DIR/SKILL.md"
download "$RAW_BASE/scripts/collect_sessions.py" "$SCRIPTS_DIR/collect_sessions.py"

chmod +x "$SCRIPTS_DIR/collect_sessions.py"

# -----------------------------------------------------------------------------
# 3. 동작 확인
# -----------------------------------------------------------------------------
section "동작 확인"

if python3 "$SCRIPTS_DIR/collect_sessions.py" &>/dev/null; then
  info "collect_sessions.py 실행 확인"
else
  warn "스크립트 실행 중 오류가 발생했습니다. 설치는 완료되었으나 동작을 확인해 주세요."
fi

# -----------------------------------------------------------------------------
# 완료
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  daily-summary 설치 완료!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Claude Code를 재시작한 뒤 사용하세요."
echo ""
echo "  /daily-summary              → 오늘 작업 요약"
echo "  /daily-summary 2026-03-18   → 특정 날짜 요약"
echo ""
