# 信徒管理系統 v2（雲端同步架構起始包）

本專案提供 NB 與 iPhone 共用同一雲端資料庫的起始架構。

## 目前包含
- 響應式網頁介面（NB／手機）
- PWA manifest 與 service worker（可加入 iPhone 主畫面）
- Supabase Email/Password 登入骨架
- 信徒資料讀取、新增骨架
- Supabase 初始資料表與 RLS 權限政策草案
- 年度星供、費用、會座功能的介面入口

## 尚未可直接投入正式使用
這是雲端整合起始包，不代表已經部署或已完成安全驗證。尚需：
1. 建立 Supabase 專案。
2. 在 SQL Editor 執行 `supabase_schema.sql`，並由可信任管理者建立組織及第一位 owner membership。
3. 將專案 URL 與 anon/public key 填入 `config.js`。不可使用 service_role key。
4. 建立正式的邀請流程、角色與會座範圍權限、稽核 trigger、資料匯出及備份。
5. 完成權限測試與資料保護檢查後，才匯入真實資料。

## 部署建議
將專案放入私有 GitHub repository，再由 Vercel 部署。GitHub 只存程式碼，不存真實信徒名單、電話、宗教參與資料、密碼或 service_role key。

## iPhone
部署 HTTPS 網址後，以 Safari 開啟 → 分享 → 加入主畫面。

## 注意
- 請勿將真實信徒資料放入此原型或公開 GitHub。
- 宗教參與資訊及聯絡方式涉及高度隱私，僅能在具備適當合法依據、告知及授權的前提下處理。
- RLS SQL 是起始範本，正式上線前必須由熟悉 Supabase/Postgres 權限的開發者檢查；尤其要完成會座範圍隔離、組織建立及稽核紀錄。
