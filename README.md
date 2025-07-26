
# 📱 Signal AI Bot

一個簡單用 `signal-cli` + `OpenAI GPT` 嘅 Signal AI 自動回覆機器人。

## 🛠 安裝步驟

1. 安裝 `signal-cli` 並完成註冊（用你自己電話號碼）
2. Clone 呢個 repo 或者解壓 zip
3. 安裝 Python 依賴：
    ```bash
    pip install -r requirements.txt
    ```
4. 修改 `.env` 檔案，加你嘅 OpenAI API Key 同 Signal 號碼
5. Run 程式：
    ```bash
    python main.py
    ```

## 🧪 測試方法
- 喺 Signal send 一句：「@AI 乜係LLM？」
- bot 就會 call GPT 回覆你

## ⚠️ 注意
- bot 只會回應包含 `@AIbot` 嘅訊息
- 建議先用自己私訊自己測試
