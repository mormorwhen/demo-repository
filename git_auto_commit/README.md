# Git Auto-Commit: AI 驅動的自動化提交工具

一個智慧型 Git 提交工具，使用 AI 服務 (Claude, Gemini, OpenAI) 自動分析程式碼變更並生成符合規範的 commit message。

## 功能特色

- 🤖 **多服務支援**: 可選擇 Claude, Gemini, 或 OpenAI。
- 📝 **智慧生成**: 分析 Git 變更，生成 5 個高品質的 commit message 建議。
- 🎯 **完整格式**: 支援標準的 commit 格式（subject + body）。
- 🔍 **即時預覽**: 在選擇時可查看完整的 commit 內容。
- ✨ **自動暫存**: 自動將所有變更加入暫存區 (`git add .`)。
- 🎨 **彩色介面**: 易於閱讀的彩色輸出。
- 🗑️ **自動清理**: 臨時檔案在腳本結束時自動刪除。

## 需求限制

### 系統需求
- **作業系統**: macOS / Linux
- **Shell**: Bash 4.0+
- **Git**: 2.0+

### 必要工具
- **fzf**: 命令行模糊搜尋工具
  ```bash
  # macOS 安裝
  brew install fzf

  # Linux 安裝
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
  ```

### API 金鑰設定
你需要為你選擇的 AI 服務設定環境變數：

- **For Claude**:
  - 需要安裝 Claude CLI: `npm install -g @anthropics/claude-cli`
- **For Gemini**:
  - `export GEMINI_API_KEY='your-api-key'`
  - 取得金鑰: [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
- **For OpenAI**:
  - `export OPENAI_API_KEY='your-api-key'`
  - 取得金鑰: [platform.openai.com/api-keys](https://platform.openai.com/api-keys)

## 安裝方式

### 設定 Git Alias (建議)

```bash
# 將 git-auto-commit.sh 放在你喜歡的位置，例如 /usr/local/bin
# cp git-auto-commit.sh /usr/local/bin/git-auto-commit
# chmod +x /usr/local/bin/git-auto-commit

# 設定 git alias 'ac'
git config --global alias.ac '!/path/to/your/git-auto-commit.sh'

# 使用方式
git ac
```

## 設定預設值

### 設定方式（優先順序由高到低）

1. **命令行參數**（最高優先級）
   ```bash
   git ac -s gemini -m gemini-2.5-pro
   ```

2. **專案配置檔**
   在專案根目錄創建 `.git-auto-commit.conf`：
   ```bash
   # .git-auto-commit.conf
   DEFAULT_SERVICE="gemini"
   DEFAULT_MODEL="gemini-2.5-pro"
   ```

3. **全域配置檔**
   在家目錄創建 `~/.git-auto-commit.conf`：
   ```bash
   # ~/.git-auto-commit.conf
   DEFAULT_SERVICE="openai"
   DEFAULT_MODEL="gpt-4"
   ```

4. **環境變數**
   在 shell 配置檔（如 `~/.bashrc` 或 `~/.zshrc`）中設定：
   ```bash
   export GIT_AUTO_COMMIT_SERVICE="claude"
   export GIT_AUTO_COMMIT_MODEL="opus"
   ```

### 配置範例

參考 `.git-auto-commit.conf.example` 檔案來創建你的配置。

## 操作方式

### 基本使用
在你的 Git 專案中執行 `git ac` 並加上服務選項。

#### 1. 使用 Claude (預設)
```bash
# 使用預設設定（會根據你的配置而定）
git ac

# 明確指定使用 Claude
git ac -s claude

# 使用特定模型 (e.g., opus)
git ac -s claude -m opus
```

#### 2. 使用 Gemini
```bash
# 使用預設模型 (gemini-2.5-flash)
git ac -s gemini

# 使用特定模型 (e.g., gemini-2.5-pro)
git ac -s gemini -m gemini-2.5-pro
```

#### 3. 使用 OpenAI
```bash
# 使用預設模型 (gpt-4)
git ac -s openai

# 使用特定模型 (e.g., gpt-4-turbo)
git ac -s openai -m gpt-4-turbo
```

### 流程說明
1.  腳本自動偵測 Git 變更。
2.  呼叫指定的 AI 服務分析變更並生成 5 個 commit 建議。
3.  使用 `fzf` 介面選擇合適的 commit message。
4.  預覽窗口顯示完整的 commit 內容。
5.  自動將所有變更加入暫存區 (`git add .`)。
6.  確認後執行提交。

### 調試模式
遇到問題時可啟用調試模式：
```bash
DEBUG=1 git ac -s gemini
```
調試模式會顯示 AI 的原始回應、解析出的 commit 內容等資訊。

## Commit Message 規範

腳本生成的 commit 遵循以下規範：

### Type 類別
- `feat`: 新增/修改功能
- `fix`: 修補 bug
- `docs`: 文件
- `style`: 格式（不影響程式碼運行的變動）
- `refactor`: 重構
- `perf`: 改善效能
- `test`: 增加測試
- `chore`: 建構程序或輔助工具的變動
- `revert`: 撤銷回覆先前的 commit

### 格式規範
```
type: subject (最多 50 字元)

body 說明為什麼這個變動是必要的，
如何解決問題，以及變動前後的差異。
每行不超過 72 字元。
```

## 技術實作細節

### 效能優化
- **精簡提示詞**：使用優化的提示詞格式，提高回應速度
- **智慧分析**：完整分析所有程式碼變動，提供準確的 commit 建議

### 檔案管理
- **臨時目錄**：使用 `mktemp -d` 創建安全的臨時目錄
- **自動清理**：使用 `trap` 確保臨時檔案在腳本退出時被清理
- **預覽腳本**：動態生成預覽腳本以顯示完整 commit 內容

### Commit 處理
- **多行支援**：使用 `git commit -F` 從檔案讀取，正確處理多行 commit message
- **格式保持**：自動處理 subject 和 body 之間的空行

## 注意事項

1. **自動加入暫存區**：腳本會自動執行 `git add .`，請確認沒有不想提交的檔案
2. **需要網路連線**：需要連線到 Claude API
3. **API 使用限制**：頻繁使用可能受到 API 速率限制
4. **敏感資訊**：避免在包含密碼、API key 等敏感資訊的變更中使用

## 疑難排解

### 問題：顯示「無法調用 claude」
**解決方案**：
- 檢查 Claude CLI 是否已安裝：`which claude`
- 確認 Claude CLI 已正確設定 API key

### 問題：fzf 預覽窗口無法顯示
**解決方案**：
- 確認 fzf 版本：`fzf --version`（需要 0.20.0 以上）
- 嘗試更新 fzf：`brew upgrade fzf`

### 問題：無法提取選擇的索引
**解決方案**：
- 使用調試模式查看詳情：`DEBUG=1 git auto-commit`
- 確認 shell 環境變數

## 更新日誌

詳細的變更歷史請參閱 [CHANGELOG.md](changelog.md)。

## 授權

MIT License

## 作者

Created with Claude Code

---

如有問題或建議，歡迎提出 Issue 或 Pull Request！