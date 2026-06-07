#!/bin/bash

# ==============================================================================
# setup.sh — Mac 新电脑环境配置脚本（Homebrew + 清华镜像）
# 适用于 macOS，拿到新机器后一键运行
# ==============================================================================

set -euo pipefail

# ---------------------------- 工具函数 ----------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[信息]${NC} $*"; }
ok()    { echo -e "${GREEN}[完成]${NC} $*"; }
warn()  { echo -e "${YELLOW}[注意]${NC} $*"; }
fail()  { echo -e "${RED}[失败]${NC} $*"; exit 1; }

step() {
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  步骤 $1 / $2：$3${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
}

# ---------------------------- 主流程 ------------------------------------------

main() {
  TOTAL_STEPS=21
  CURRENT_STEP=0

  # ---------------------------------------------------------------------------
  # 步骤 1：安装 Xcode Command Line Tools
  # 说明：macOS 自带 bash、git、curl，但 Homebrew 依赖 Xcode 命令行工具
  #       （包含编译器、make 等构建工具），必须提前安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Xcode Command Line Tools"

  info "macOS 自带 bash、git 和 curl，无需额外安装。"
  info "检查 Xcode Command Line Tools (CLT)..."

  if xcode-select -p &>/dev/null; then
    ok "Command Line Tools 已安装: $(xcode-select -p)"
  else
    info "未检测到 CLT，正在触发安装..."
    xcode-select --install
    info "已弹出系统安装对话框，请点击「安装」并等待完成。"
    info "安装完成后，请重新运行本脚本。"
    exit 0
  fi

  # ---------------------------------------------------------------------------
  # 步骤 2：生成 Git SSH 密钥 & 配置 Git 全局用户信息
  # 说明：新电脑首次使用 Git 提交代码或克隆私有仓库前，
  #       需要生成 SSH 密钥对并配置全局用户名和邮箱。
  #       使用 ed25519 算法（更安全、密钥更短），私钥无密码。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "生成 Git SSH 密钥"

  SSH_DIR="$HOME/.ssh"
  SSH_KEY="$SSH_DIR/id_ed25519"

  # 确保 ~/.ssh 目录存在且权限正确
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  if [[ -f "$SSH_KEY" ]]; then
    ok "SSH 密钥已存在: $SSH_KEY"
    info "如需重新生成，请先删除 $SSH_KEY 及 $SSH_KEY.pub 后重试。"
  else
    info "生成 ed25519 格式的 SSH 密钥对..."
    # -t ed25519: 使用 ed25519 算法（推荐，比 rsa 更安全）
    # -C: 添加注释（使用 git 配置的邮箱，若未配置则使用默认值）
    # -f: 指定私钥保存路径
    # -N "": 私钥不设密码（直接回车）
    SSH_COMMENT="chenqiyuan1012@gmail.com"
    ssh-keygen -t ed25519 -C "$SSH_COMMENT" -f "$SSH_KEY" -N ""
    ok "SSH 密钥生成完成！"

    info "公钥内容如下，请复制并添加到 GitHub/GitLab："
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    cat "$SSH_KEY.pub"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    info "公钥路径: $SSH_KEY.pub"
    info "添加方式：GitHub → Settings → SSH and GPG keys → New SSH key"
  fi

  # 配置 Git 全局用户信息
  info "配置 Git 全局用户名和邮箱..."
  git config --global user.name "QiyuanChen"
  git config --global user.email "chenqiyuan1012@gmail.com"
  ok "Git 用户信息已配置："
  echo "  用户名: $(git config --global user.name)"
  echo "  邮箱:   $(git config --global user.email)"

  # ---------------------------------------------------------------------------
  # 步骤 3：设置 Homebrew 镜像环境变量并写入 ~/.zshrc
  # 说明：清华 TUNA 镜像替代了 Homebrew 的默认 GitHub 仓库和 bottles 源，
  #       在国内网络环境下能大幅提升下载速度。
  #       环境变量分为两类：
  #         - git remote 类：影响 brew 自身和 core formula 仓库的克隆地址
  #         - domain 类：影响 bottles（预编译二进制包）和 pip 的下载地址
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "设置 Homebrew 清华镜像环境变量"

  info "设置 Homebrew 仓库镜像（git remote）..."
  echo ""
  echo "  HOMEBREW_BREW_GIT_REMOTE  → https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  echo "  HOMEBREW_CORE_GIT_REMOTE  → https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
  echo "  HOMEBREW_INSTALL_FROM_API → 1"
  echo ""

  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
  export HOMEBREW_INSTALL_FROM_API=1

  ok "环境变量已设置（当前会话有效）。"

  # 写入 ~/.zshrc，使新终端窗口自动生效
  info "将镜像配置写入 ~/.zshrc（zsh 交互式 shell 配置文件）..."
  ZSHRC="$HOME/.zshrc"
  BLOCK_START="# >>> Homebrew 清华镜像配置 (由 setup.sh 自动添加) <<<"
  BLOCK_END="# <<< Homebrew 镜像配置结束 <<<"

  if ! grep -qF "$BLOCK_END" "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" <<EOF

$BLOCK_START
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
$BLOCK_END
EOF
    ok "已追加到 $ZSHRC，未来打开终端自动生效。"
  else
    ok "$ZSHRC 中已包含镜像配置，跳过写入。"
  fi

  # ---------------------------------------------------------------------------
  # 步骤 4：克隆并安装 Homebrew
  # 说明：从清华镜像下载 Homebrew 安装脚本并执行。
  #       安装位置默认为 /opt/homebrew（Apple Silicon）或 /usr/local（Intel）。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "克隆并安装 Homebrew"

  if command -v brew &>/dev/null; then
    ok "Homebrew 已安装: $(brew --version | head -1)"
    warn "如需重新安装，请先卸载:"
    warn "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)\""
  else
    info "从清华镜像下载安装脚本..."
    git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
    ok "安装脚本下载完成。"

    info "执行安装脚本（约 2-5 分钟，请耐心等待）..."
    /bin/bash brew-install/install.sh

    info "清理临时安装脚本..."
    rm -rf brew-install
    ok "安装脚本已清理。"
  fi

  # ---------------------------------------------------------------------------
  # 步骤 5：验证安装
  # 说明：检查 brew 是否可用，并执行 brew update 同步最新 formula。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "验证 Homebrew 安装"

  if command -v brew &>/dev/null; then
    echo -e "\n  brew 版本:   $(brew --version | head -1)"
    echo -e "  brew 路径:   $(which brew)"

    # 对于 Apple Silicon Mac，提示将 brew 加入 PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
      BREW_PREFIX="/opt/homebrew"
      if ! echo "$PATH" | grep -qF "$BREW_PREFIX/bin"; then
        warn "建议将 $BREW_PREFIX/bin 加入 PATH"
        info "可在 ~/.zshrc 中添加: export PATH=\"$BREW_PREFIX/bin:\$PATH\""
      fi
    fi

    info "更新 Homebrew 公式库（使用清华镜像）..."
    brew update || warn "brew update 失败，可能需要稍后手动执行。"

    ok "Homebrew 验证通过！"
  else
    fail "Homebrew 安装似乎未成功，请检查上方错误信息。"
  fi

  # ---------------------------------------------------------------------------
  # 步骤 6：安装 Oh My Zsh
  # 说明：Oh My Zsh 是一个 zsh 配置框架，提供丰富的插件和主题。
  #       使用 CERNET（中国教育和科研计算机网）镜像克隆仓库并安装，
  #       确保在国内网络环境下能正常下载。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Oh My Zsh（CERNET 镜像）"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "Oh My Zsh 已安装: $HOME/.oh-my-zsh"
  else
    info "从 CERNET 镜像克隆 Oh My Zsh 仓库..."
    git clone https://mirrors.cernet.edu.cn/ohmyzsh.git "$HOME/.oh-my-zsh"
    ok "克隆完成。"

    info "执行安装脚本..."
    cd "$HOME/.oh-my-zsh/tools"
    REMOTE=https://mirrors.cernet.edu.cn/ohmyzsh.git sh install.sh
    cd - &>/dev/null
    ok "Oh My Zsh 安装完成！"
  fi

  # ---------------------------------------------------------------------------
  # 步骤 7：安装 NVM（Node Version Manager）
  # 说明：NVM 用于管理多个 Node.js 版本，方便在不同项目间切换。
  #       macOS 自带 curl，无需额外安装。安装脚本会自动将初始化
  #       代码写入 ~/.zshrc，无需手动干预。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 NVM（Node 版本管理器）"

  # macOS 自带 curl，直接使用即可
  info "使用 curl 下载 NVM 安装脚本..."
  info "NVM 安装脚本会自动将初始化代码写入 ~/.zshrc"

  if [[ -d "$HOME/.nvm" ]]; then
    ok "NVM 已安装: $HOME/.nvm"
    info "如需重新安装，请先删除 ~/.nvm 目录后重试。"
  else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    ok "NVM 安装完成！"
  fi

  # NVM 的初始化代码已写入 ~/.zshrc，但当前会话尚未加载，
  # 需要手动 source 使 nvm 命令在当前脚本中可用
  info "加载 NVM 环境..."
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  ok "NVM 环境已加载。"

  # 安装 Node.js LTS 版本（包含 npm）
  info "安装 Node.js LTS 版本（首次安装可能需要几分钟）..."
  nvm install --lts
  ok "Node.js LTS 安装完成！"

  info "当前 Node.js 版本: $(node -v)"
  info "当前 npm 版本: $(npm -v)"

  # ---------------------------------------------------------------------------
  # 步骤 8：安装 NRM 并切换到淘宝源
  # 说明：NRM（npm registry manager）用于管理 npm 镜像源。
  #       国内用户切换到淘宝源可大幅提升包下载速度。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 NRM 并切换 npm 源为淘宝"

  info "通过 npm 全局安装 NRM..."
  npm install -g nrm
  ok "NRM 安装完成！"

  info "将 npm 默认源切换为淘宝镜像..."
  nrm use taobao
  ok "npm 源已切换为淘宝（淘宝源）"

  # 验证当前源
  info "当前 npm 源: $(npm config get registry)"

  # ---------------------------------------------------------------------------
  # 步骤 9：安装 PNPM
  # 说明：PNPM 是新一代包管理器，相比 npm 安装速度更快、磁盘利用率更高。
  #       通过 npm 全局安装，安装后会自动添加到 PATH。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 PNPM"

  info "通过 npm 全局安装 PNPM..."
  npm install -g pnpm
  ok "PNPM 安装完成！"

  info "当前 PNPM 版本: $(pnpm -v)"

  # ---------------------------------------------------------------------------
  # 步骤 10：安装 OpenCode
  # 说明：OpenCode 是一个开源的终端 AI 编程助手，用于在命令行中与 AI 交互辅助编码。
  #       通过 npm 全局安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 OpenCode（终端 AI 编程助手）"

  info "通过 npm 全局安装 OpenCode..."
  npm install -g opencode-ai
  ok "OpenCode 安装完成！"
  info "当前 OpenCode 版本: $(opencode --version 2>/dev/null || echo '已安装')"

  # ---------------------------------------------------------------------------
  # 步骤 11：安装 CodeX
  # 说明：CodeX 是一个基于终端的 AI 编程工具，类似于 OpenCode 的替代方案。
  #       通过 npm 全局安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 CodeX（终端 AI 编程工具）"

  info "通过 npm 全局安装 CodeX..."
  npm install -g @openai/codex
  ok "CodeX 安装完成！"

  # ---------------------------------------------------------------------------
  # 步骤 12：安装 UV / UVX
  # 说明：UV 是 Rust 编写的新一代 Python 包管理器，速度远超 pip。
  #       UVX 是 UV 的工具运行器，可一键运行 Python 工具（如 ruff、black）。
  #       使用国内镜像脚本安装，安装脚本会自动将 PATH 写入 ~/.zshrc。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 UV / UVX（Python 包管理器）"

  info "使用国内镜像脚本安装 UV / UVX..."
  info "安装脚本会自动将初始化代码写入 ~/.zshrc"
  curl -LsSf https://uv.agentsmirror.com/install-cn.sh | sh
  ok "UV / UVX 安装完成！"

  # 安装脚本会将 ~/.local/bin 加入 PATH，手动 source 使其在当前会话可用
  info "加载 UV 环境..."
  export PATH="$HOME/.local/bin:$PATH"
  ok "UV 环境已加载。"

  info "当前 UV 版本: $(uv --version 2>/dev/null || echo '已安装，请重启终端后验证')"
  info "当前 UVX 版本: $(uvx --version 2>/dev/null || echo '已安装，请重启终端后验证')"

  # ---------------------------------------------------------------------------
  # 步骤 13：安装 Bun
  # 说明：Bun 是新一代 JavaScript 运行时，集成了打包器、转译器和包管理器，
  #       速度和性能远超 Node.js，适合现代 Web 开发。
  #       使用官方安装脚本安装，安装脚本会自动将 PATH 写入 ~/.zshrc。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Bun（JavaScript 运行时）"

  info "使用官方脚本安装 Bun..."
  info "安装脚本会自动将初始化代码写入 ~/.zshrc"
  curl -fsSL https://bun.sh/install | bash
  ok "Bun 安装完成！"

  # 安装脚本会将 ~/.bun/bin 加入 PATH，手动 source 使其在当前会话可用
  info "加载 Bun 环境..."
  export PATH="$HOME/.bun/bin:$PATH"
  ok "Bun 环境已加载。"

  info "当前 Bun 版本: $(bun --version 2>/dev/null || echo '已安装，请重启终端后验证')"

  # ---------------------------------------------------------------------------
  # 步骤 14：安装 Docker Desktop
  # 说明：Docker Desktop 是 Docker 的 Mac 客户端，包含 Docker Engine、
  #       Docker CLI 和 Docker Compose，是 Mac 上使用 Docker 的标准方式。
  #       通过 Homebrew Cask 安装，安装包较大（约 500MB+），请耐心等待。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Docker Desktop"

  if [[ -d "/Applications/Docker.app" ]]; then
    ok "Docker Desktop 已安装"
  else
    info "通过 Homebrew Cask 安装 Docker Desktop（约 500MB，请耐心等待）..."
    brew install --cask docker
    ok "Docker Desktop 安装完成！"
  fi

  info "Docker Desktop 首次启动时会自动下载镜像并初始化环境，请按提示操作。"
  info "启动方式：打开「启动台」→ Docker，或在终端执行：open -a Docker"

  # 验证 Docker CLI 是否可用
  if command -v docker &>/dev/null; then
    info "当前 Docker 版本: $(docker --version)"
  else
    warn "Docker CLI 尚未就绪，请先启动 Docker Desktop 应用后再验证。"
  fi

  # 配置 Docker Desktop 镜像加速
  info "配置 Docker 镜像加速（国内源）..."
  DOCKER_DAEMON="$HOME/.docker/daemon.json"
  mkdir -p "$HOME/.docker"

  if [[ -f "$DOCKER_DAEMON" ]]; then
    if grep -q '"registry-mirrors"' "$DOCKER_DAEMON" 2>/dev/null; then
      ok "Docker 镜像加速已配置，跳过。"
    else
      cp "$DOCKER_DAEMON" "${DOCKER_DAEMON}.bak"
      python3 -c "
import json, sys
with open('$DOCKER_DAEMON', 'r') as f:
    config = json.load(f)
config['registry-mirrors'] = [
    'https://docker.1ms.run',
    'https://docker.m.daocloud.io'
]
with open('$DOCKER_DAEMON', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
"
      ok "Docker 镜像加速配置已更新（原有配置已备份到 ${DOCKER_DAEMON}.bak）。"
    fi
  else
    cat > "$DOCKER_DAEMON" <<EOF
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io"
  ]
}
EOF
    ok "Docker 镜像加速配置已写入 $DOCKER_DAEMON"
  fi

  info "请重启 Docker Desktop 使镜像加速配置生效。"

  # ---------------------------------------------------------------------------
  # 步骤 15：安装 Warp
  # 说明：Warp 是现代化的终端模拟器，基于 Rust 开发，支持 AI 命令搜索、
  #       团队工作流共享、语法高亮等特性，是 iTerm2 / Terminal 的替代品。
  #       通过 Homebrew Cask 安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Warp（现代化终端）"

  if [[ -d "/Applications/Warp.app" ]]; then
    ok "Warp 已安装"
  else
    info "通过 Homebrew Cask 安装 Warp..."
    brew install --cask warp
    ok "Warp 安装完成！"
  fi

  info "启动方式：打开「启动台」→ Warp，或在终端执行：open -a Warp"

  # ---------------------------------------------------------------------------
  # 步骤 16：安装 iTerm2
  # 说明：iTerm2 是 macOS 上最流行的终端模拟器之一，功能丰富，
  #       支持分屏、搜索、自动补全等高级特性。
  #       通过 Homebrew Cask 安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 iTerm2"

  if [[ -d "/Applications/iTerm.app" ]]; then
    ok "iTerm2 已安装"
  else
    info "通过 Homebrew Cask 安装 iTerm2..."
    brew install --cask iterm2
    ok "iTerm2 安装完成！"
  fi

  info "启动方式：打开「启动台」→ iTerm2，或在终端执行：open -a iTerm2"

  # ---------------------------------------------------------------------------
  # 步骤 17：安装 Powerlevel10k (p10k) 主题
  # 说明：Powerlevel10k 是 Oh My Zsh 最流行的主题，提供丰富的提示符定制、
  #       性能和视觉体验。使用 Gitee 镜像加速国内下载。
  #       安装后自动修改 ~/.zshrc 中的 ZSH_THEME，无需手动干预。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Powerlevel10k 主题"

  P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  if [[ -d "$P10K_DIR" ]]; then
    ok "Powerlevel10k 已安装: $P10K_DIR"
  else
    info "从 Gitee 镜像克隆 Powerlevel10k（国内加速）..."
    git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "$P10K_DIR"
    ok "Powerlevel10k 克隆完成！"

    # 自动修改 ~/.zshrc 中的 ZSH_THEME
    info "修改 ~/.zshrc 主题配置为 powerlevel10k..."
    ZSHRC="$HOME/.zshrc"
    if grep -qE '^ZSH_THEME=' "$ZSHRC"; then
      sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC"
      ok "已修改 ~/.zshrc: ZSH_THEME=\"powerlevel10k/powerlevel10k\""
    else
      echo "" >> "$ZSHRC"
      echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
      ok "已追加到 ~/.zshrc: ZSH_THEME=\"powerlevel10k/powerlevel10k\""
    fi
  fi

  info "安装完成！打开新终端后会自动提示配置 p10k（如未配置过）。"
  info "如需手动运行配置向导：p10k configure"

  # ---------------------------------------------------------------------------
  # 步骤 18：安装 Vim
  # 说明：macOS 自带 Vim，但版本较旧。通过 Homebrew 安装可获得最新版本，
  #       并支持 Python、Ruby、Lua 等更多特性。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Vim（最新版）"

  info "通过 Homebrew 安装 Vim..."
  brew install vim
  ok "Vim 安装完成！"
  info "当前 Vim 版本: $(vim --version | head -1)"

  # ---------------------------------------------------------------------------
  # 步骤 19：安装 NeoVim
  # 说明：NeoVim 是 Vim 的现代化重构版本，支持更好的插件生态和 LSP。
  #       通过 Homebrew 安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 NeoVim"

  info "通过 Homebrew 安装 NeoVim..."
  brew install neovim
  ok "NeoVim 安装完成！"
  info "当前 NeoVim 版本: $(nvim --version | head -1)"

  # ---------------------------------------------------------------------------
  # 步骤 20：安装 Go
  # 说明：Go 是 Google 开发的开源编程语言，适合后端服务、云原生开发等场景。
  #       通过 Homebrew 安装，安装后自动配置 PATH。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Go"

  info "通过 Homebrew 安装 Go..."
  brew install go
  ok "Go 安装完成！"

  info "当前 Go 版本: $(go version)"

  # 配置 Go 环境变量
  info "配置 Go 环境变量..."
  ZSHRC="$HOME/.zshrc"
  GO_BLOCK="# >>> Go 环境配置 (由 setup.sh 自动添加) <<<"

  if ! grep -qF "# >>> Go 环境配置" "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" <<EOF

$GO_BLOCK
export GOPATH="\$HOME/go"
export PATH="\$PATH:\$GOPATH/bin"
export GOPROXY="https://goproxy.cn,direct"
EOF
    ok "已追加 Go 环境变量到 ~/.zshrc"
  else
    ok "~/.zshrc 中已包含 Go 环境配置，跳过写入。"
  fi

  # 在当前会话中生效
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
  export GOPROXY="https://goproxy.cn,direct"

  # ---------------------------------------------------------------------------
  # 步骤 21：安装 Claude Code
  # 说明：Claude Code 是 Anthropic 官方出品的终端 AI 编程工具，
  #       直接在命令行中使用 Claude 模型辅助编码。
  #       使用官方安装脚本安装。
  # ---------------------------------------------------------------------------
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "安装 Claude Code（终端 AI 编程工具）"

  info "使用官方脚本安装 Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  ok "Claude Code 安装完成！"

  info "当前 Claude Code 版本: $(claude --version 2>/dev/null || echo '已安装')"
  info "使用方式：在项目目录中执行 'claude' 启动交互式编程助手"

  # ---------------------------------------------------------------------------
  # 完成
  # ---------------------------------------------------------------------------
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  🎉 环境配置完成！${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
  info "下一步："
  echo "  1. 执行 'source ~/.zshrc' 使所有配置立即生效"
  echo "  2. 打开新终端，确认 Oh My Zsh 主题和插件已加载"
  echo "  3. 使用 'nvm install --lts' 管理 Node.js 版本"
  echo "  4. 使用 'nrm use taobao' 可随时切换 npm 源"
  echo "  5. 使用 'pnpm install' 代替 npm 安装项目依赖"
  echo "  6. 使用 'bun install' 代替 npm/pnpm 进行快速包安装"
  echo "  7. 使用 'opencode' 启动终端 AI 编程助手"
  echo "  8. 使用 'codex' 启动 CodeX 终端 AI 工具"
  echo "  9. 使用 'claude' 启动 Claude Code 终端 AI 编程助手"
  echo "  10. 使用 'uv <命令>' 管理 Python 包（比 pip 快得多）"
  echo "  11. 启动 Docker Desktop 后使用 'docker' / 'docker compose' 管理容器"
  echo "  12. 打开 Warp 或 iTerm2 作为终端"
  echo "  13. 打开新终端后 p10k 主题会自动加载（首次会提示配置向导）"
  echo "  14. 使用 'go' 命令进行 Go 语言开发"
  echo "  15. 使用 'vim' 或 'nvim' 编辑文件"
  echo "  16. 运行 'brew install <包名>' 安装其他常用软件"
  echo "  17. 如有 Brewfile，可执行 'brew bundle --file=~/Brewfile' 批量安装"
  echo ""
  echo -e "${CYAN}提示：${NC}Git SSH 公钥已生成，请记得添加到 GitHub/GitLab："
  echo "  cat ~/.ssh/id_ed25519.pub | pbcopy"
  echo "  然后粘贴到 GitHub → Settings → SSH and GPG keys → New SSH key"
  echo ""
}

main "$@"
