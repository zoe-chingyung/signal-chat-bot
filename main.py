import os
import time
import requests
import json
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

SIGNAL_API_URL = os.getenv("SIGNAL_API_URL")
SIGNAL_NUMBER = os.getenv("SIGNAL_NUMBER")
SIGNAL_GROUP_INTERNAL_ID = os.getenv("SIGNAL_GROUP_INTERNAL_ID")
GROUP_ID = os.getenv("SIGNAL_GROUP_ID")
BOT_NAME = "@AI"

seen_messages = set()  # 避免重覆處理

def ask_gpt(question):
    try:
        response = client.chat.completions.create(
            model="chatgpt-4o-latest",
            messages=[{"role": "user", "content": question}]
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"GPT 回覆出錯：{e}"

def send_signal_message(reply, group_id):
    payload = {
        "message": reply,
        "groupId": group_id,
        "recipients": [SIGNAL_GROUP_INTERNAL_ID],
        "number": SIGNAL_NUMBER
    }
    try:
        r = requests.post(f"{SIGNAL_API_URL}/v2/send", json=payload)
        if r.status_code == 201:
            print("訊息已發送 ✅")
        else:
            print(f"發送失敗 ❌: {r.text}")
    except Exception as e:
        print(f"發送失敗 ❌: {e}")

def poll_messages():
    print("🔍 接收中...")
    try:
        r = requests.get(f"{SIGNAL_API_URL}/v1/receive/{SIGNAL_NUMBER}")
        if r.status_code != 200:
            print(f"[INFO] 接收失敗: {r.text}")
            return

        messages = r.json()
        for data in messages:
            try:
                envelope = data.get("envelope", {})
                data_message = envelope.get("dataMessage", {})
                group_info = data_message.get("groupInfo", {})
                group_id = group_info.get("groupId")

                if group_id != GROUP_ID:
                    continue

                message = data_message.get("message", "")
                sender = envelope.get("sourceName")
                timestamp = envelope.get("timestamp")

                if timestamp in seen_messages:
                    continue
                seen_messages.add(timestamp)

                if BOT_NAME in message:
                    print(f"📩 收到來自 {sender} 嘅提問: {message}")
                    question = message.split(BOT_NAME, 1)[1].strip()
                    answer = ask_gpt(question)
                    full_reply = f"@{sender}  AIbot回答:{answer}"
                    send_signal_message(full_reply, group_id)
            except Exception as e:
                print(f"⚠️ 錯誤解析訊息: {e}")
    except Exception as e:
        print(f"⚠️ 接收訊息錯誤: {e}")

if __name__ == "__main__":
    print("Signal AI Bot started - version 1.1")  
    while True:
        poll_messages()
        time.sleep(3)
