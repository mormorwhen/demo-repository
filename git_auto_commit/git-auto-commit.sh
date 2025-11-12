#!/bin/bash

# git-auto-commit: 自動生成符合規範的 commit message

# 調試模式：設置 DEBUG=1 來啟用
DEBUG=${DEBUG:-0}

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# 調用 claude 生成 commit 建議（使用 Sonnet model）
echo -e "${GREEN}正在生成 commit 建議 (使用 Sonnet model)...${NC}"
COMMITS=$(cd "$CURRENT_DIR" && echo "$PROMPT" | claude --model sonnet 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}錯誤：無法調用 claude${NC}"
    echo "錯誤詳情："
    echo "$COMMITS"
    exit 1
fi

# 檢查是否成功獲得回應
if [ -z "$COMMITS" ]; then
    echo -e "${RED}錯誤：claude 沒有返回任何建議${NC}"
    exit 1
fi

# 調試模式輸出
if [ "$DEBUG" = "1" ]; then
    echo -e "${YELLOW}[調試] Claude 原始回應：${NC}"
    echo "$COMMITS"
    echo -e "${YELLOW}[調試] ---結束---${NC}"
fi

# 解析 claude 的回應，提取 commit messages
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
    echo -e "${RED}錯誤：無法解析 claude 的回應${NC}"
    echo "Claude 回應內容："
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