# ECG Pomodoro（MVP, Modular）

本專案採「三模組分離」架構：GUI（React）負責番茄鐘與顯示；ECG 與 AI 各自是獨立 FastAPI 服務，透過 HTTP + JSON 溝通。
目標是先做出可測試 MVP（stub），讓組員能在不互相阻塞的情況下替換內部演算法，但**不改動對外介面（contract）**。

---

## 架構概觀

### Modules

-   `ecg-pomodoro/`：React GUI

    -   番茄鐘狀態機：HOME / CONFIG / WORK / PAUSE / REST
    -   REST 畫面先顯示「AI 思考中…」；MVP 階段可用 Demo Pipeline 按鈕測資料流

-   `ecg-service/`：ECG 前處理服務（FastAPI, stub）

    -   提供 `POST /ecg/features`：輸入 `EcgSegment`，輸出 `EcgFeatures`

-   `ai-service/`：AI 推論服務（FastAPI, stub）
    -   提供 `POST /ai/predict`：輸入 `EcgFeatures`，輸出 `AiPrediction`

### Data Contract（最重要）

我們用 Pydantic models 定義 JSON 格式，並用 `response_model=...` 鎖定回傳格式，避免組員改演算法時把回傳欄位弄壞。

所有 payload 都含：

-   `schema_version`：例如 `ecg-seg/v1`、`ecg-feat/v1`、`ai-pred/v1`
-   `segment_id`：全 pipeline 一路帶著，用來追蹤/除錯

---

## 目錄結構

```text
project-root/
  ecg-pomodoro/      # React (create-react-app)
  ecg-service/       # FastAPI service for ECG features
  ai-service/        # FastAPI service for AI prediction
```

---

## 快速開始（MVP 可跑）

### 1) 啟動 ECG service（port 8001）

```bash
cd ecg-service
pip install -r requirements.txt
uvicorn main:app --reload --port 8001
```

打開互動文件頁：

-   http://127.0.0.1:8001/docs （Swagger UI）[web:521]
-   http://127.0.0.1:8001/redoc （ReDoc）[web:521]

### 2) 啟動 AI service（port 8002）

```bash
cd ai-service
pip install -r requirements.txt
uvicorn main:app --reload --port 8002
```

文件頁：

-   http://127.0.0.1:8002/docs [web:521]

### 3) 啟動 GUI（CRA）

```bash
cd ecg-pomodoro
npm install
npm start
```

GUI 內的 `Demo Pipeline` 頁面會依序呼叫：

1. `POST http://127.0.0.1:8001/ecg/features`
2. `POST http://127.0.0.1:8002/ai/predict`
   並在畫面上顯示回傳 JSON，用來驗證介面一致。

---

### 通用規則（必讀）

✅ 允許：

-   改 `main.py` 裡的演算法邏輯（或新增 `processor.py` / `utils.py` / `model.py` 再在 `main.py` 呼叫）
-   新增 internal logging、效能優化、快取、測試碼

❌ 禁止（會造成前端或其他服務壞掉）：

-   修改 `models.py` 的欄位名稱/型別/必填狀態
-   修改 endpoint 路徑與方法：
    -   ECG：`POST /ecg/features`
    -   AI：`POST /ai/predict`
-   刪除 `response_model=...`（它是對外 contract 的保護網）[web:436]

### ECG Service（ecg-service）

負責把 stub 換成真正 ECG pipeline（例如 R-peak 偵測 + HRV 計算），但要維持輸入/輸出格式不變：

-   Input: `EcgSegment`
-   Output: `EcgFeatures`

建議修改點：

-   `main.py`：`ecg_features()` 內部目前是 placeholder，替換成你的演算法
-   可以新增 `processor.py` 並在 `ecg_features()` 內呼叫（讓 main.py 乾淨）

### AI Service（ai-service）

負責把 stub rule-based 換成真正模型（或未來 LLM），但要維持輸入/輸出格式不變：

-   Input: `EcgFeatures`
-   Output: `AiPrediction`

建議修改點：

-   `main.py`：`predict()` 內部替換成你的推論流程
-   可以新增 `model.py` / `inference.py` 管理模型載入與推論

---

## Security / Repo 規範

-   不要 commit 任何 API keys、token、密碼等敏感資訊（請用環境變數）。
-   若需要設定值，建立 `.env.example`（只放 key，不放 value），並把 `.env` / `.env.*.local` 加入 `.gitignore`。
-   大型產物（`node_modules/`、Python venv、各種 build/target）都不應提交到 git。

---

## Troubleshooting

-   如果 GUI 呼叫 API 被瀏覽器擋：請確認 FastAPI 有開 CORS（允許 `http://localhost:3000`）。
-   如果 `POST /ecg/features` 或 `/ai/predict` 回傳格式不符，請先對照 `/docs` 內的 schema 與 request body 範例。
