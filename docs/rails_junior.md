以下是我結合目前開發時所用到的技術並提出對應的開發需求，完成後可以把學到的東西寫成文章放到這部落格專案，當作是 rails 的履歷表。

## 專案環境 & 開發需求
以下要求是為了以後能夠無縫銜接業界所需要的：
1.專案使用 rails 8 版本開發
2. vs code 編輯器 + gemini pro (學校信箱申請免費一年) ai 輔助開發、不要使用 chat gpt (以熟悉編輯器 + ai 的開發模式)
3. 需熟悉 [git](https://hackmd.io/@uzFag3GMS6Kdno1uyQMoPQ/BkcSZwvtll) 操作、commit 點不可太大
4. 需具備 docker 概念
5. 每個功能開發需要先在 github 上開票 (issue) -> 開分支 (git branch) -> 完成後發 pull request ([格式需要符合這文章](https://hackmd.io/@uzFag3GMS6Kdno1uyQMoPQ/HkkUdlUCxl))
6. 寫筆記使用 markdown 語法的工具，ex: Hackmd

### A. 開發限制
1. 登入系統：不要用 devise 建置，需改用 [rails 8 authentication](https://guides.rubyonrails.org/getting_started.html#adding-authentication)
2. 不要有前後台、用 [pundit](https://rubygems.org/gems/pundit) + [rolify](https://github.com/RolifyCommunity/rolify) gem 管理權限
3. 不寫 javascript 、有需要用到的地方用 [stimulus](https://stimulus.hotwired.dev/) 完成
4. 試試看測試先寫、再寫程式
5. 不用「node」不用「yarn」，我們使用 [importmap-rails](https://guides.rubyonrails.org/working_with_javascript_in_rails.html) 管理 js 套件
6. 不寫客製化 css ，純粹使用 tailwind css 刻版
7. DB 不要用 sqlite3 ，改用 psgresql

### B. 專案規劃
1. 規劃並定義此專案架構 (登入才看得到文章? 每個 user 都可以發表文章? 只有自己才能發表文章?)
2. 使用 [mermaid](https://vocus.cc/article/6894a572fd89780001de683b) 畫出 ER-Model
### C. 功能需求

#### 1. 文章
1. 用 aasm gem 管理狀態 (ex: 已發布、已刪除、草稿)
2. tag 功能 (可以使用 [acts-as-taggable-on gem](https://github.com/mbleigh/acts-as-taggable-on))
3. category 功能
4. 支援 markdown (優先低)
5. rails action text 編輯文章
6. 預覽功能
7. 搜尋功能 (title、content...) (ransack gem)
8. 排序功能 (新到舊、更新時間)
9. 可以分頁 (kaminari 或者 pagy gem)
10. 文章瀏覽次數
11. 使用 A-2 提到的 gem 自訂權限管理，如：有權限的人才會出現編輯按鈕，沒有權限的人只能瀏覽文章
12. 文章新增「發布時間」並增加自定義的 validation callback
    - 時間到才會在 index 上看到
    - 編輯文章時，發布時間如果小於當前時間則會顯示自定義的錯誤訊息

#### 2. others
1. 設定專案時區 (UTF-8)
2. 所有 flash 通知需要使用 fixed 通知框、五秒後自動消失
3. 所有系統上的訊息需皆採用 i18n (多國語系) 處理，本專案需要有中英文設定 [使用 lazy lookup](https://guides.rubyonrails.org/i18n.html#lazy-lookup)
4. 所有敏感資訊 (如 aws key) 使用 [rails credentials](https://ninglab.com/Rails-Master-Key/) 處理
5. 新增 PWA 模式 [Everything You Need to Ace PWAs in Rails](https://blog.codeminer42.com/everything-you-need-to-ace-pwas/)

#### 3. 寫 rspec 測試
1. 使用 [database_rewinder](https://github.com/amatsuda/database_rewinder) 保持每個測試的乾淨
2. 使用 [factory_bot](https://github.com/thoughtbot/factory_bot) 建立測試用的假資料
3. model 測試 (validations)
4. controller 測試
5. view 測試
6. 頁面測試 [capybara](https://github.com/teamcapybara/capybara) gem 讓程式在瀏覽器上自己測試

#### 4. 專案部屬 deploy
1. docker + kamal
2. https://dashboard.render.com/ (免費的 deploy 平台)

### D. 進階課題：

1. 手機版分頁功能改用 [Infinite Scroll](https://medium.com/uxcircles/pagination-vs-infinite-scroll-e1c3a3d682d9)，使用 rails turbo 完成
    - https://hotwired.dev/
    - https://medium.com/jungletronics/from-zero-to-hotwire-rails-8-e6cd16216165
    - https://5xruby.com/zh/articles/introduce-of-turble
2. 第三方登入功能 oauth2 (google 登入)
3. 推薦文章功能：文章結束後的地方出現「您可能會喜歡」區塊
4. 自訂一個 rails task，實作 **撈出需要發布的文章 D-1 並更新狀態 (發佈)** 的 job，最後把 job 放在 task 裡面執行
5. 排程功能：設定這 task 每半小時跑一次 (使用 [solid_queue](https://amoeric.github.io/solid-queue/))
6. 排程後台管理頁面 [mission_control-jobs](https://github.com/rails/mission_control-jobs)
7. 實作一個 api 並且搭配 [jbuilder](https://ihower.tw/rails/fullstack-web-api-jbuilder.html) 產出 json response
8. 「預期瀏覽時間」功能
9. 依照 [http status code](https://developer.mozilla.org/zh-TW/docs/Web/HTTP/Reference/Status) 顯示不同錯誤頁面
10. 用 [rails action mailer](https://rails.ruby.tw/action_mailer_basics.html) 實作信件通知

### E. 最終 BOSS 課題
1. [五倍紅寶石產出的 junior 必須通過的專案](https://github.com/kaochenlong/5xtraining/blob/master/backend.md)

### F. 學習資源
- [為你自己學 Ruby on Rails](https://railsbook.tw/)
- [Ruby on Rails 實戰聖經](https://ihower.tw/rails/)

> 以下 rails 官方文件 (記得注意文章的版本)：
- [rails 官方指南](https://guides.rubyonrails.org/index.html)
- [rails api](https://api.rubyonrails.org/)
- [rubygem](https://rubygems.org/?locale=zh-TW) (找套件來這)