#!/bin/bash

# git-auto-commit: 自動生成符合規範的 commit message

# 預設值配置
# 可以通過環境變數覆蓋這些預設值：
#   export GIT_AUTO_COMMIT_SERVICE="gemini"
#   export GIT_AUTO_COMMIT_MODEL="gemini-2.5-pro"
DEFAULT_SERVICE="${GIT_AUTO_COMMIT_SERVICE:-claude}"  # 預設使用 claude
DEFAULT_MODEL="${GIT_AUTO_COMMIT_MODEL:-}"            # 預設模型（依服務而定）

# 載入配置檔案（如果存在）
# 優先順序：專案配置 > 家目錄配置 > 環境變數 > 內建預設值
CONFIG_FILE=""
if [ -f ".git-auto-commit.conf" ]; then
    CONFIG_FILE=".git-auto-commit.conf"
elif [ -f "$HOME/.git-auto-commit.conf" ]; then
    CONFIG_FILE="$HOME/.git-auto-commit.conf"
fi

if [ -n "$CONFIG_FILE" ]; then
    # 載入配置檔案
    source "$CONFIG_FILE" 2>/dev/null
    # 配置檔案可以設定 DEFAULT_SERVICE 和 DEFAULT_MODEL 變數
fi

# 參數解析
SERVICE="$DEFAULT_SERVICE"  # 使用預設服務
MODEL="$DEFAULT_MODEL"      # 使用預設模型
SHOW_HELP=0

# 解析命令行參數
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -h|--help)
            SHOW_HELP=1
            shift
            ;;
        *)
            echo "未知參數: $1"
            SHOW_HELP=1
            shift
            ;;
    esac
done

# 顯示幫助訊息
if [ $SHOW_HELP -eq 1 ]; then
    echo "使用方式: git ac [選項]"
    echo ""
    echo "選項:"
    echo "  -s, --service <service>  指定 AI 服務 (claude/gemini/openai)"
    echo "                          預設: $DEFAULT_SERVICE"
    echo "  -m, --model <model>     指定模型名稱 (可選)"
    echo "                          claude: sonnet (預設), opus, haiku"
    echo "                          gemini: gemini-2.5-flash (預設), gemini-2.5-pro"
    echo "                          openai: gpt-4 (預設), gpt-4-turbo, gpt-3.5-turbo"
    echo "  -h, --help              顯示此幫助訊息"
    echo ""
    echo "設定預設值的方式 (優先順序由高到低):"
    echo "  1. 命令行參數: git ac -s gemini -m gemini-2.5-pro"
    echo "  2. 專案配置檔: .git-auto-commit.conf"
    echo "  3. 全域配置檔: ~/.git-auto-commit.conf"
    echo "  4. 環境變數:"
    echo "     export GIT_AUTO_COMMIT_SERVICE=gemini"
    echo "     export GIT_AUTO_COMMIT_MODEL=gemini-2.5-pro"
    echo ""
    echo "配置檔案格式範例:"
    echo "  DEFAULT_SERVICE=\"gemini\""
    echo "  DEFAULT_MODEL=\"gemini-2.5-pro\""
    echo ""
    echo "範例:"
    echo "  git ac                    # 使用預設設定"
    echo "  git ac -s gemini          # 使用 Gemini"
    echo "  git ac -s claude -m opus  # 使用 Claude Opus"
    echo "  git ac -s openai -m gpt-4 # 使用 OpenAI GPT-4"
    exit 0
fi

# 調試模式：設置 DEBUG=1 來啟用
DEBUG=${DEBUG:-0}

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 顯示選擇的服務
echo -e "${GREEN}使用 AI 服務: ${YELLOW}$SERVICE${NC}"
if [ -n "$MODEL" ]; then
    echo -e "${GREEN}指定模型: ${YELLOW}$MODEL${NC}"
fi

# 檢查 git 狀態
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo -e "${GREEN}偵測到 git 變動，正在分析...${NC}"
else
    echo -e "${YELLOW}沒有偵測到任何變動${NC}"
    exit 0
fi

# 取得變動摘要
GIT_STATUS=$(git status --short)
GIT_STATS=$(git diff --stat HEAD 2>/dev/null | tail -1)
GIT_DIFF=$(git diff HEAD --no-color | grep '^[+-]' | grep -v '^+++\|^---')

# 準備精簡的提示詞
PROMPT="請使用繁體中文回應。基於 Git 變動生成 5 個 commit message。

Type: feat|fix|docs|style|refactor|perf|test|chore|revert
格式: type: 描述(50字內) + 空行 + 詳細說明(選填)

檔案變動:
$GIT_STATUS

統計: $GIT_STATS

程式碼變動:
$GIT_DIFF

輸出格式:
---COMMIT---
type: 簡短描述（使用繁體中文）

詳細說明（選填，使用繁體中文）：
1. 第一個變更項目
2. 第二個變更項目
3. （如有更多項目繼續編號）
---COMMIT---

注意：
1. 所有描述必須使用繁體中文
2. Body 部分的每個項目請使用編號列表格式（1. 2. 3. ...）
3. 生成5個不同的 commit message 選項
4. 只輸出commit messages，不要有其他說明文字"

# 獲取當前工作目錄
CURRENT_DIR=$(pwd)

# 根據選擇的服務調用不同的 AI
case $SERVICE in
    claude)
        # 設定預設模型
        if [ -z "$MODEL" ]; then
            MODEL="sonnet"
        fi
        echo -e "${GREEN}正在生成 commit 建議 (使用 Claude $MODEL)...${NC}"
        COMMITS=$(cd "$CURRENT_DIR" && echo "$PROMPT" | claude --model "$MODEL" 2>&1)
        ;;

    gemini)
        # 使用 Gemini API (需要 API key)
        if [ -z "$MODEL" ]; then
            MODEL="gemini-2.5-flash"  # 使用 v1beta API 的模型名稱
        fi

        # 檢查 API key
        if [ -z "$GEMINI_API_KEY" ]; then
            echo -e "${RED}錯誤：未設置 GEMINI_API_KEY 環境變數${NC}"
            echo "請先設置 GEMINI_API_KEY："
            echo "  export GEMINI_API_KEY='your-api-key'"
            echo "取得 API key: https://makersuite.google.com/app/apikey"
            exit 1
        fi

        echo -e "${GREEN}正在生成 commit 建議 (使用 Gemini $MODEL)...${NC}"

        # 準備 JSON payload
        # 將提示詞中的特殊字符轉義（使用 macOS 相容的方式）
        ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//')

        # 構建 JSON 請求，加入系統指示要求繁體中文
        JSON_PAYLOAD=$(cat <<EOF
{
  "contents": [{
    "parts": [{
      "text": "重要：請使用繁體中文回應所有內容。\n\n$ESCAPED_PROMPT"
    }]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 2048
  },
  "safetySettings": [
    {
      "category": "HARM_CATEGORY_HARASSMENT",
      "threshold": "BLOCK_NONE"
    },
    {
      "category": "HARM_CATEGORY_HATE_SPEECH",
      "threshold": "BLOCK_NONE"
    },
    {
      "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
      "threshold": "BLOCK_NONE"
    },
    {
      "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
      "threshold": "BLOCK_NONE"
    }
  ]
}
EOF
)

        # 調用 Gemini API (使用 v1 API)
        API_URL="https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$GEMINI_API_KEY"

        # 使用 curl 調用 API
        API_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$JSON_PAYLOAD" \
            "$API_URL" 2>&1)

        # 檢查是否有錯誤
        if echo "$API_RESPONSE" | grep -q '"error"'; then
            echo -e "${RED}錯誤：Gemini API 調用失敗${NC}"
            echo "API 回應："
            echo "$API_RESPONSE" | jq -r '.error.message' 2>/dev/null || echo "$API_RESPONSE"
            exit 1
        fi

        # 從 JSON 回應中提取文本
        # 使用 jq 如果可用，否則使用 sed
        if command -v jq &> /dev/null; then
            COMMITS=$(echo "$API_RESPONSE" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null)
        else
            # 簡單的 JSON 解析（不完美但應該足夠）
            COMMITS=$(echo "$API_RESPONSE" | sed -n 's/.*"text"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
            # 將 \n 轉換為實際換行
            COMMITS=$(echo -e "$COMMITS")
        fi
        ;;

    openai)
        # 使用 OpenAI API (需要 API key)
        if [ -z "$MODEL" ]; then
            MODEL="gpt-4"
        fi

        # 檢查 API key
        if [ -z "$OPENAI_API_KEY" ]; then
            echo -e "${RED}錯誤：未設置 OPENAI_API_KEY 環境變數${NC}"
            echo "請先設置 OPENAI_API_KEY："
            echo "  export OPENAI_API_KEY='your-api-key'"
            echo "取得 API key: https://platform.openai.com/api-keys"
            exit 1
        fi

        echo -e "${GREEN}正在生成 commit 建議 (使用 OpenAI $MODEL)...${NC}"

        # 準備 JSON payload
        # 將提示詞中的特殊字符轉義（使用 macOS 相容的方式）
        ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//')

        # 構建 JSON 請求
        JSON_PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "system",
      "content": "你是一個專業的 Git commit message 生成助手。重要：請使用繁體中文回應所有內容。請根據提供的變更內容生成符合規範的 commit messages。"
    },
    {
      "role": "user",
      "content": "$ESCAPED_PROMPT"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2048
}
EOF
)

        # 調用 OpenAI API
        API_URL="https://api.openai.com/v1/chat/completions"

        # 使用 curl 調用 API
        API_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -d "$JSON_PAYLOAD" \
            "$API_URL" 2>&1)

        # 檢查是否有錯誤
        if echo "$API_RESPONSE" | grep -q '"error"'; then
            echo -e "${RED}錯誤：OpenAI API 調用失敗${NC}"
            echo "API 回應："
            echo "$API_RESPONSE" | jq -r '.error.message' 2>/dev/null || echo "$API_RESPONSE"
            exit 1
        fi

        # 從 JSON 回應中提取文本
        # 使用 jq 如果可用，否則使用 sed
        if command -v jq &> /dev/null; then
            COMMITS=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)
        else
            # 簡單的 JSON 解析（不完美但應該足夠）
            COMMITS=$(echo "$API_RESPONSE" | sed -n 's/.*"content"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
            # 將 \n 轉換為實際換行
            COMMITS=$(echo -e "$COMMITS")
        fi
        ;;

    *)
        echo -e "${RED}錯誤：不支援的服務 '$SERVICE'${NC}"
        echo "支援的服務：claude, gemini, openai"
        exit 1
        ;;
esac

if [ $? -ne 0 ]; then
    echo -e "${RED}錯誤：無法調用 $SERVICE${NC}"
    echo "錯誤詳情："
    echo "$COMMITS"
    exit 1
fi

# 檢查是否成功獲得回應
if [ -z "$COMMITS" ]; then
    echo -e "${RED}錯誤：$SERVICE 沒有返回任何建議${NC}"
    exit 1
fi

# 調試模式輸出
if [ "$DEBUG" = "1" ]; then
    echo -e "${YELLOW}[調試] $SERVICE 原始回應：${NC}"
    echo "$COMMITS"
    echo -e "${YELLOW}[調試] ---結束---${NC}"
fi

# 解析 AI 的回應，提取 commit messages
COMMIT_OPTIONS=""
IFS=$'\n'
COMMIT_ARRAY=()
CURRENT_COMMIT=""
IN_COMMIT=false

while IFS= read -r line; do
    if [[ "$line" == *"---COMMIT---"* ]]; then
        if [ "$IN_COMMIT" = true ] && [ -n "$CURRENT_COMMIT" ]; then
            # 不要移除所有空行！只移除開頭和結尾的多餘空行
            # 但要保留 subject 和 body 之間的空行
            CURRENT_COMMIT=$(echo "$CURRENT_COMMIT" | sed -e :a -e '/^\n*$/N;/\n$/ba' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            if [ -n "$CURRENT_COMMIT" ]; then
                # 確保 subject 和 body 之間有空行
                # 檢查是否有 body（多於一行）
                LINE_COUNT=$(echo "$CURRENT_COMMIT" | wc -l)
                if [ "$LINE_COUNT" -gt 1 ]; then
                    # 提取 subject（第一行）
                    SUBJECT=$(echo "$CURRENT_COMMIT" | head -n 1)
                    # 提取 body（第二行之後，如果第二行不是空行就加入空行）
                    BODY=$(echo "$CURRENT_COMMIT" | tail -n +2)
                    # 移除 body 開頭的空行
                    BODY=$(echo "$BODY" | sed '/./,$!d')
                    if [ -n "$BODY" ]; then
                        # 重組：subject + 空行 + body
                        CURRENT_COMMIT="$SUBJECT

$BODY"
                    else
                        CURRENT_COMMIT="$SUBJECT"
                    fi
                fi
                COMMIT_ARRAY+=("$CURRENT_COMMIT")
                # 如果已經有5個 commits，停止解析
                if [ ${#COMMIT_ARRAY[@]} -eq 5 ]; then
                    break
                fi
            fi
        fi
        CURRENT_COMMIT=""
        IN_COMMIT=true
    elif [ "$IN_COMMIT" = true ]; then
        # 保留所有行，包括空行
        if [ -z "$CURRENT_COMMIT" ]; then
            CURRENT_COMMIT="$line"
        else
            CURRENT_COMMIT="$CURRENT_COMMIT
$line"
        fi
    fi
done <<< "$COMMITS"

# 處理最後一個 commit（如果還沒有5個）
if [ "$IN_COMMIT" = true ] && [ -n "$CURRENT_COMMIT" ] && [ ${#COMMIT_ARRAY[@]} -lt 5 ]; then
    # 同樣的處理邏輯
    CURRENT_COMMIT=$(echo "$CURRENT_COMMIT" | sed -e :a -e '/^\n*$/N;/\n$/ba' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [ -n "$CURRENT_COMMIT" ]; then
        LINE_COUNT=$(echo "$CURRENT_COMMIT" | wc -l)
        if [ "$LINE_COUNT" -gt 1 ]; then
            SUBJECT=$(echo "$CURRENT_COMMIT" | head -n 1)
            BODY=$(echo "$CURRENT_COMMIT" | tail -n +2 | sed '/./,$!d')
            if [ -n "$BODY" ]; then
                CURRENT_COMMIT="$SUBJECT

$BODY"
            else
                CURRENT_COMMIT="$SUBJECT"
            fi
        fi
        COMMIT_ARRAY+=("$CURRENT_COMMIT")
    fi
fi

# 檢查是否有有效的 commit 建議
if [ ${#COMMIT_ARRAY[@]} -eq 0 ]; then
    echo -e "${RED}錯誤：無法解析 $SERVICE 的回應${NC}"
    echo "$SERVICE 回應內容："
    echo "$COMMITS"
    exit 1
fi

# 調試模式輸出
if [ "$DEBUG" = "1" ]; then
    echo -e "${YELLOW}[調試] 解析到 ${#COMMIT_ARRAY[@]} 個 commit 建議${NC}"
    for i in "${!COMMIT_ARRAY[@]}"; do
        echo -e "${YELLOW}[調試] Commit $((i+1)):${NC}"
        echo "${COMMIT_ARRAY[$i]}"
        echo "---"
    done
fi

# 準備 fzf 選項 - 只顯示 subject line
FZF_OPTIONS=""
OPTION_COUNT=0
for i in "${!COMMIT_ARRAY[@]}"; do
    # 確保 commit 不是空的
    if [ -n "${COMMIT_ARRAY[$i]}" ]; then
        # 只顯示第一行（commit subject），移除 body
        FIRST_LINE=$(echo "${COMMIT_ARRAY[$i]}" | head -n 1)
        # 移除 type: 前綴以外的空白
        FIRST_LINE=$(echo "$FIRST_LINE" | sed 's/^[[:space:]]*//')
        # 確保第一行不是空的
        if [ -n "$FIRST_LINE" ]; then
            FZF_OPTIONS="${FZF_OPTIONS}[$(printf "%d" $((i+1)))] ${FIRST_LINE}\n"
            OPTION_COUNT=$((OPTION_COUNT + 1))
        fi
    fi
done

# 調試：顯示實際的選項數量
if [ "$DEBUG" = "1" ]; then
    echo -e "${YELLOW}[調試] 生成了 $OPTION_COUNT 個選項${NC}"
fi

# 移除最後一個換行符
FZF_OPTIONS=$(echo -n "$FZF_OPTIONS")

# 使用 fzf 讓用戶選擇（加上預覽窗口顯示完整內容）
echo -e "${GREEN}請選擇一個 commit message (只顯示標題行):${NC}"

# 創建臨時目錄存儲每個 commit message
TEMP_DIR=$(mktemp -d)
export TEMP_DIR

# 設置 trap 以確保臨時目錄在腳本退出時被清理
trap "rm -rf $TEMP_DIR" EXIT

# 為每個 commit 創建單獨的文件
for i in "${!COMMIT_ARRAY[@]}"; do
    echo "${COMMIT_ARRAY[$i]}" > "$TEMP_DIR/commit_$((i+1)).txt"
done

# 創建一個簡單的預覽腳本文件
cat > "$TEMP_DIR/preview.sh" << 'PREVIEW_SCRIPT'
#!/bin/bash
INPUT="$1"
# 提取 [數字] 中的數字
if [[ "$INPUT" =~ ^\[([0-9]+)\] ]]; then
    INDEX="${BASH_REMATCH[1]}"
    FILE="TEMP_DIR_PLACEHOLDER/commit_${INDEX}.txt"
    if [ -f "$FILE" ]; then
        echo "=== Commit $INDEX ==="
        echo ""
        cat "$FILE"
    else
        echo "找不到檔案: $FILE"
    fi
else
    echo "無法提取索引: $INPUT"
fi
PREVIEW_SCRIPT

# 替換臨時目錄路徑
sed -i.bak "s|TEMP_DIR_PLACEHOLDER|$TEMP_DIR|g" "$TEMP_DIR/preview.sh"
chmod +x "$TEMP_DIR/preview.sh"

# 使用 fzf 選擇，使用外部腳本作為預覽
SELECTED=$(echo -e "$FZF_OPTIONS" | fzf --height 60% --reverse --ansi \
    --preview="bash '$TEMP_DIR/preview.sh' {}" \
    --preview-window=right:50%:wrap)

# 注意：暫時不清理 TEMP_DIR，因為後面提交時還需要用到

if [ -z "$SELECTED" ]; then
    echo -e "${YELLOW}已取消操作${NC}"
    # trap 會自動清理臨時目錄
    exit 0
fi

# 提取選擇的索引 - 使用更可靠的方法
# 使用 awk 直接提取方括號中的數字
SELECTED_INDEX=$(echo "$SELECTED" | awk -F'[][]' '{print $2}')

# 確保提取到的是數字
if ! [[ "$SELECTED_INDEX" =~ ^[0-9]+$ ]]; then
    SELECTED_INDEX=""
fi

# 調試模式輸出
if [ "$DEBUG" = "1" ]; then
    echo -e "${YELLOW}[調試] 選擇的內容: '$SELECTED'${NC}"
    echo -e "${YELLOW}[調試] 提取的索引: '$SELECTED_INDEX'${NC}"
fi

if [ -z "$SELECTED_INDEX" ]; then
    echo -e "${RED}錯誤：無法提取選擇的索引${NC}"
    echo "選擇的內容: '$SELECTED'"
    exit 1
fi

SELECTED_INDEX=$((SELECTED_INDEX - 1))

if [ "$SELECTED_INDEX" -lt 0 ] || [ "$SELECTED_INDEX" -ge ${#COMMIT_ARRAY[@]} ]; then
    echo -e "${RED}錯誤：無效的選擇索引 ($SELECTED_INDEX)${NC}"
    echo "有效範圍: 0 到 $((${#COMMIT_ARRAY[@]} - 1))"
    exit 1
fi

# 獲取完整的 commit message
FINAL_COMMIT="${COMMIT_ARRAY[$SELECTED_INDEX]}"

# 自動將所有變更加入暫存區
HAS_CHANGES=$(git status --porcelain)
if [ -n "$HAS_CHANGES" ]; then
    echo -e "${GREEN}自動將所有變更加入暫存區...${NC}"
    git add .
    echo -e "${GREEN}已將所有變更加入暫存區${NC}"

    # 顯示將要提交的內容
    echo -e "${YELLOW}將要提交的變更：${NC}"
    git status --short --branch
else
    echo -e "${YELLOW}暫存區已包含所有變更${NC}"
fi

# 顯示最終的 commit message
echo -e "${GREEN}準備提交以下 commit:${NC}"
echo ""
echo "========================================"
# 顯示 subject line (第一行)
SUBJECT_LINE=$(echo "$FINAL_COMMIT" | head -n 1)
echo -e "${YELLOW}Subject:${NC} $SUBJECT_LINE"
echo ""
# 檢查是否有 body
BODY=$(echo "$FINAL_COMMIT" | tail -n +2 | sed '/^$/d')
if [ -n "$BODY" ]; then
    echo -e "${YELLOW}Body:${NC}"
    echo "$BODY"
    echo ""
fi
echo "========================================"

# 確認是否要提交
read -p "確定要提交這個 commit 嗎？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 使用臨時文件來處理多行 commit message
    COMMIT_MSG_FILE="$TEMP_DIR/commit_message.txt"
    echo "$FINAL_COMMIT" > "$COMMIT_MSG_FILE"

    # 執行 git commit，使用 -F 參數從文件讀取 commit message
    git commit -F "$COMMIT_MSG_FILE"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功提交 commit！${NC}"
        echo ""
        # 顯示完整的 commit 信息（不只是 oneline）
        git log -1 --format=medium
        exit 0
    else
        echo -e "${RED}提交失敗${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}已取消提交${NC}"
    exit 0
fi