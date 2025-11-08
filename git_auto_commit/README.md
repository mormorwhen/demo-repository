# Git Auto-Commit 自動化提交工具

一個智慧型 Git 提交工具，使用 Claude AI 自動分析程式碼變更並生成符合規範的 commit message。

## 功能特色

- 🤖 自動分析 Git 變更內容
- 📝 生成 5 個符合規範的 commit message 建議
- 🎯 支援完整的 commit 格式（subject + body）
- 🔍 提供預覽功能，可查看完整 commit 內容
- ✨ 自動將所有變更加入暫存區
- 🎨 彩色輸出介面，易於閱讀

## 需求限制

### 系統需求
- **作業系統**: macOS / Linux
- **Shell**: Bash 4.0+
- **Git**: 2.0+

### 必要工具
- **claude**: Claude CLI 工具（必須已安裝並配置）
  ```bash
  # 檢查是否已安裝
  which claude
  ```
- **fzf**: 命令行模糊搜尋工具
  ```bash
  # macOS 安裝
  brew install fzf

  # Linux 安裝
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
  ```

### Claude CLI 設定
需要先安裝並設定 Claude CLI：
```bash
npm install -g @anthropics/claude-cli
# 或
pnpm install -g @anthropics/claude-cli
```

## 安裝方式

### 方法一：全域安裝（建議）

1. 複製腳本到系統路徑：
```bash
# 複製腳本到 /usr/local/bin
cp git-auto-commit.sh /usr/local/bin/git-auto-commit

# 設定執行權限
chmod +x /usr/local/bin/git-auto-commit
```

2. 驗證安裝：
```bash
# 測試指令
git auto-commit
```

### 方法二：專案內使用

1. 將腳本放在你的專案目錄：
```bash
# 進入你的專案目錄
cd /path/to/your/project

# 複製腳本到專案（假設腳本在當前目錄）
cp git-auto-commit.sh ./

# 設定執行權限
chmod +x git-auto-commit.sh

# 使用腳本
./git-auto-commit.sh
```

### 方法三：設定 Git Alias

```bash
# 設定 git alias
git config --global alias.ac '!/usr/local/bin/git-auto-commit'

# 使用方式
git ac
```

## 操作方式

### 基本使用

1. **在有變更的 Git 專案中執行**：
```bash
git auto-commit
```

2. **流程說明**：
   - 腳本自動偵測 Git 變更
   - 呼叫 Claude 分析變更並生成 5 個 commit 建議
   - 使用 fzf 介面選擇合適的 commit message
   - 預覽窗口顯示完整的 commit 內容（包含 body）
   - 自動將所有變更加入暫存區
   - 確認後執行提交

### 調試模式

遇到問題時可啟用調試模式：
```bash
DEBUG=1 git auto-commit
```

調試模式會顯示：
- Claude 的原始回應
- 解析出的 commit 數量和內容
- 選擇的索引值

### 使用範例

```bash
# 1. 修改檔案後
echo "new feature" > feature.txt

# 2. 執行 auto-commit
git auto-commit

# 3. 畫面顯示
偵測到 git 變動，正在分析...
正在生成 commit 建議...
請選擇一個 commit message (只顯示標題行):

[1] feat: 新增功能特性檔案     │ === Commit 1 ===
[2] docs: 新增 feature 文件    │ feat: 新增功能特性檔案
[3] chore: 新增測試檔案        │
[4] test: 加入功能測試檔案     │ 新增 feature.txt 檔案以實作新功能
[5] feat: 建立新功能模組       │ 這個檔案將用於...

# 4. 選擇後自動提交
```

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

### v1.0.0 (2024-11-08)
- 初始版本發布
- 支援自動分析 Git 變更
- 整合 Claude AI 生成 commit message
- 支援 fzf 互動式選擇
- 自動管理暫存區

## 授權

MIT License

## 作者

Created with Claude Code

---

如有問題或建議，歡迎提出 Issue 或 Pull Request！