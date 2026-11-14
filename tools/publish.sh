#!/usr/bin/env bash
# 把本仓库推到 GitHub：改提交作者 → 建仓库 → 推送。
# 前置：先跑一次 `gh auth login`（GitHub.com → HTTPS → 浏览器授权）。
#
# 用法：
#   tools/publish.sh --dry-run   # 只打印计划
#   tools/publish.sh             # 真推
#
# 环境变量：REPO_NAME（默认 niri-rice-diy）、VISIBILITY（public|private，默认 public）
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="${REPO_NAME:-niri-rice-diy}"
VIS="${VISIBILITY:-public}"
BASE_TAG="v2.1.2"          # 分叉点：上游这个 tag 之后的提交才是我们的
BRANCH="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

step() { printf '\n== %s ==\n' "$*"; }
run()  { if (( DRY )); then echo "would: $*"; else "$@"; fi; }

step "检查 gh 登录"
AUTHED=1
gh auth status >/dev/null 2>&1 || AUTHED=0
if (( ! AUTHED )); then
  echo "还没登录 GitHub。请先运行：gh auth login（GitHub.com → HTTPS → 浏览器授权）" >&2
  (( DRY )) || exit 1
  echo "(dry-run 继续，用占位身份演示其余步骤)"
  LOGIN="<your-login>"; ID="0"
else
  LOGIN="$(gh api user -q .login)"
  ID="$(gh api user -q .id)"
fi
EMAIL="${ID}+${LOGIN}@users.noreply.github.com"

step "提交身份"
echo "user.name=$LOGIN"
echo "user.email=$EMAIL"

step "重写 $BASE_TAG 之后的提交作者（上游提交不动）"
BASE="$(git -C "$REPO" rev-parse "$BASE_TAG^{commit}")"
echo "分叉点 $BASE_TAG=$BASE"
echo "待重写：$(git -C "$REPO" rev-list --count "$BASE..$BRANCH") 个提交，当前作者："
git -C "$REPO" log --format='  %an <%ae>' "$BASE..$BRANCH" | sort -u
run git -C "$REPO" config user.name "$LOGIN"
run git -C "$REPO" config user.email "$EMAIL"
# --exec 隐含 -i，必须压掉编辑器否则会挂住
run env GIT_SEQUENCE_EDITOR=true git -C "$REPO" rebase "$BASE" --exec "git commit --amend --no-edit --reset-author"

step "创建仓库 $LOGIN/$NAME（$VIS）"
if gh repo view "$LOGIN/$NAME" >/dev/null 2>&1; then
  echo "远端已存在，跳过创建"
else
  run gh repo create "$NAME" --"$VIS" --source "$REPO" --remote origin
fi

step "推送分支 $BRANCH"
run git -C "$REPO" push -u origin "$BRANCH"

step "完成"
if (( DRY )); then
  echo "(dry-run：以上命令都没有执行)"
else
  echo "https://github.com/$LOGIN/$NAME"
  echo "提醒：upstream 已指向 duxlabs-dev/dux-shell，日后手动升级用 git fetch upstream"
fi
