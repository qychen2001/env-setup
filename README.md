# env-setup

Mac 新电脑环境一键配置脚本。在新机器上拿到后，一条命令搞定常用开发工具和镜像配置。

## 一键执行

即使新电脑上还没有安装 Git，也可以直接通过以下命令一键运行：

```bash
curl -fsSL https://raw.githubusercontent.com/qychen2001/env-setup/main/setup.sh | bash
```

> **注意**：脚本会自动从 GitHub 下载最新版本并执行，确保网络通畅。

## 包含的工具

| 类别 | 工具 |
|------|------|
| 包管理 | Homebrew（清华镜像）、NVM、NRM、PNPM、UV、Bun |
| 编辑器 | Vim、NeoVim |
| 终端 | Oh My Zsh、Powerlevel10k 主题、Tmux、Warp、iTerm2 |
| 运行时 | Node.js LTS、Go、Bun |
| AI 工具 | OpenCode、CodeX、Claude Code |
| 容器 | Docker Desktop |
| 其他 | Git SSH 密钥生成与全局配置 |

## 使用方法

### 方式一：直接执行（推荐，无需 Git）

```bash
curl -fsSL https://raw.githubusercontent.com/qychen2001/env-setup/main/setup.sh | bash
```

### 方式二：克隆仓库后执行

```bash
git clone git@github.com:qychen2001/env-setup.git
cd env-setup
bash setup.sh
```

## 脚本步骤一览

1. 安装 Xcode Command Line Tools
2. 生成 Git SSH 密钥（ed25519）并配置全局用户名/邮箱
3. 设置 Homebrew 清华镜像环境变量
4. 克隆并安装 Homebrew
5. 验证 Homebrew 安装
6. 安装 Oh My Zsh（CERNET 镜像）
7. 安装 NVM 并安装 Node.js LTS
8. 安装 NRM，切换 npm 源为淘宝镜像
9. 安装 PNPM
10. 安装 OpenCode（终端 AI 编程助手）
11. 安装 CodeX（终端 AI 编程工具）
12. 安装 UV / UVX（Python 包管理器）
13. 安装 Bun（JavaScript 运行时）
14. 安装 Docker Desktop 并配置国内镜像加速
15. 安装 Warp（现代化终端）
16. 安装 iTerm2
17. 安装 Powerlevel10k 主题
18. 安装 Tmux 并配置 Oh My Tmux
19. 安装 Vim（最新版）
20. 安装 NeoVim
21. 安装 Go 并配置 GOPATH 和代理
22. 安装 Claude Code（终端 AI 编程工具）

## 镜像说明

国内网络环境下，脚本自动使用以下镜像加速下载：

- **Homebrew**：清华 TUNA 镜像（brew 仓库 + bottles + pip）
- **Oh My Zsh**：CERNET 教育网镜像
- **Powerlevel10k**：Gitee 镜像
- **npm**：淘宝镜像（通过 NRM）
- **Docker**：自动写入 `~/.docker/daemon.json`，配置国内 Registry 镜像加速（docker.1ms.run / DaoCloud），安装完成后需重启 Docker Desktop 生效
- **Go**：goproxy.cn 代理

## 注意事项

- 脚本针对 Apple Silicon Mac 优化，Intel 芯片也能正常运行
- 所有安装步骤均有幂等保护（已安装则跳过）
- 环境变量通过 `~/.zshrc` 持久化，新终端窗口自动生效
- Docker Desktop 和 Warp/iTerm2 安装包较大，请耐心等待
- Docker 镜像加速配置完成后，需重启 Docker Desktop 才能生效
- 首次运行脚本后，建议执行 `source ~/.zshrc` 使配置立即生效
