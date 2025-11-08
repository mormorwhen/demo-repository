# Git Auto-Commit 快速開始

## 快速安裝（3 步驟）

```bash
# 1. 安裝必要工具
brew install fzf
npm install -g @anthropics/claude-cli

# 2. 安裝腳本（從腳本所在目錄執行）
sudo cp ./git-auto-commit.sh /usr/local/bin/git-auto-commit
sudo chmod +x /usr/local/bin/git-auto-commit

# 3. 測試
git auto-commit
```

## 基本使用

```bash
# 在有變更的專案中
git auto-commit

# 選擇 commit → 自動提交 ✅
```

## 常見指令

| 指令 | 說明 |
|------|------|
| `git auto-commit` | 正常執行 |
| `DEBUG=1 git auto-commit` | 調試模式 |
| `git ac` | 使用 alias（需先設定） |

## 設定 Alias（選用）

```bash
git config --global alias.ac '!/usr/local/bin/git-auto-commit'
```

完整說明請查看 [git_auto_commit/README.md](README.md)