import React, { useEffect, useMemo, useReducer, useState } from "react";
import "./App.css";

const SETTINGS_KEY = "pomodoro_settings_v1";
const MIN_WORK_MINUTES = 15;
const MIN_REST_MINUTES = 1;

const ECG_API = "http://127.0.0.1:8001";
const AI_API = "http://127.0.0.1:8002";

function clampInt(value, min, max) {
    if (!Number.isFinite(value)) return min;
    return Math.max(min, Math.min(max, Math.trunc(value)));
}

function loadSettings() {
    try {
        const raw = localStorage.getItem(SETTINGS_KEY);
        if (!raw) return { workMinutes: 25, restMinutes: 5 };
        const p = JSON.parse(raw);
        return {
            workMinutes: clampInt(p.workMinutes, MIN_WORK_MINUTES, 180),
            restMinutes: clampInt(p.restMinutes, MIN_REST_MINUTES, 60),
        };
    } catch {
        return { workMinutes: 25, restMinutes: 5 };
    }
}

function saveSettings(settings) {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
}

function formatMMSS(ms) {
    const totalSec = Math.ceil(Math.max(0, ms) / 1000);
    const mm = Math.floor(totalSec / 60);
    const ss = totalSec % 60;
    return `${String(mm).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
}

function remainingMs(endsAtMs, nowMs) {
    return Math.max(0, endsAtMs - nowMs);
}

function makeWorkEndsAt(settings, nowMs) {
    return nowMs + settings.workMinutes * 60_000;
}

function makeRestEndsAt(settings, nowMs) {
    return nowMs + settings.restMinutes * 60_000;
}

// ---------- Pomodoro state machine ----------
function initState() {
    return {
        kind: "HOME",
        settings: loadSettings(),
        draft: null,
        endsAtMs: null,
        remainingMs: null,
    };
}

function reducer(state, action) {
    switch (action.type) {
        case "GO_HOME":
            return {
                ...state,
                kind: "HOME",
                draft: null,
                endsAtMs: null,
                remainingMs: null,
            };

        case "GO_CONFIG":
            return { ...state, kind: "CONFIG", draft: { ...state.settings } };

        case "SET_WORK_MINUTES":
            if (state.kind !== "CONFIG") return state;
            return {
                ...state,
                draft: {
                    ...state.draft,
                    workMinutes: clampInt(action.value, MIN_WORK_MINUTES, 180),
                },
            };

        case "SET_REST_MINUTES":
            if (state.kind !== "CONFIG") return state;
            return {
                ...state,
                draft: {
                    ...state.draft,
                    restMinutes: clampInt(action.value, MIN_REST_MINUTES, 60),
                },
            };

        case "SAVE_CONFIG":
            if (state.kind !== "CONFIG") return state;
            return {
                ...state,
                kind: "HOME",
                settings: state.draft,
                draft: null,
            };

        case "START_WORK":
            if (state.kind !== "HOME" && state.kind !== "REST") return state;
            return {
                ...state,
                kind: "WORK",
                endsAtMs: makeWorkEndsAt(state.settings, action.nowMs),
                remainingMs: null,
            };

        case "PAUSE":
            if (state.kind !== "WORK") return state;
            return {
                ...state,
                kind: "PAUSE",
                remainingMs: remainingMs(state.endsAtMs, action.nowMs),
                endsAtMs: null,
            };

        case "RESUME":
            if (state.kind !== "PAUSE") return state;
            return {
                ...state,
                kind: "WORK",
                endsAtMs: action.nowMs + state.remainingMs,
                remainingMs: null,
            };

        case "FORCE_REST":
            if (state.kind !== "WORK") return state;
            return {
                ...state,
                kind: "REST",
                endsAtMs: makeRestEndsAt(state.settings, action.nowMs),
                remainingMs: null,
            };

        case "SKIP_REST":
            if (state.kind !== "REST") return state;
            return {
                ...state,
                kind: "WORK",
                endsAtMs: makeWorkEndsAt(state.settings, action.nowMs),
                remainingMs: null,
            };

        case "TICK":
            if (state.kind === "WORK" && action.nowMs >= state.endsAtMs) {
                return {
                    ...state,
                    kind: "REST",
                    endsAtMs: makeRestEndsAt(state.settings, action.nowMs),
                };
            }
            if (state.kind === "REST" && action.nowMs >= state.endsAtMs) {
                return {
                    ...state,
                    kind: "HOME",
                    endsAtMs: null,
                    remainingMs: null,
                };
            }
            return state;

        default:
            return state;
    }
}

// ---------- Demo pipeline ----------
async function postJson(url, body) {
    const r = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });
    if (!r.ok) throw new Error(`HTTP ${r.status} at ${url}`);
    return await r.json();
}

function makeDemoEcgSegment() {
    const sr = 700;
    const seconds = 5;
    const n = sr * seconds;
    const now = Date.now();

    const samples = Array.from({ length: n }, (_, i) => {
        const t = i / sr;
        const base = Math.sin(2 * Math.PI * 1.2 * t) * 800;
        const spike = i % sr === Math.floor(0.5 * sr) ? 6000 : 0;
        return [Math.round(30000 + base + spike)];
    });

    return {
        schema_version: "ecg-seg/v1",
        segment_id: `demo_${now}`,
        sampling_rate_hz: sr,
        start_time_unix_ms: now,
        channels: [{ name: "ECG", unit: "adc", lead: "CH1" }],
        samples,
    };
}

export default function App() {
    const [tab, setTab] = useState("pomodoro"); // pomodoro | demo
    const [state, dispatch] = useReducer(reducer, undefined, initState);
    const [nowMs, setNowMs] = useState(() => Date.now());

    const [demoStatus, setDemoStatus] = useState("");
    const [features, setFeatures] = useState(null);
    const [prediction, setPrediction] = useState(null);
    const [errorMsg, setErrorMsg] = useState("");

    useEffect(() => {
        const id = window.setInterval(() => {
            const n = Date.now();
            setNowMs(n);
            dispatch({ type: "TICK", nowMs: n });
        }, 250);
        return () => window.clearInterval(id);
    }, []);

    useEffect(() => {
        if (state.kind === "HOME") saveSettings(state.settings);
    }, [state.kind, state.settings]);

    const msLeft = useMemo(() => {
        if (state.kind === "WORK" || state.kind === "REST")
            return remainingMs(state.endsAtMs, nowMs);
        if (state.kind === "PAUSE") return state.remainingMs;
        return 0;
    }, [state, nowMs]);

    async function runDemo() {
        setErrorMsg("");
        setFeatures(null);
        setPrediction(null);
        setDemoStatus("Running…");

        try {
            const seg = makeDemoEcgSegment();
            const feat = await postJson(`${ECG_API}/ecg/features`, seg);
            setFeatures(feat);

            const pred = await postJson(`${AI_API}/ai/predict`, feat);
            setPrediction(pred);

            setDemoStatus("Done.");
        } catch (e) {
            setDemoStatus("");
            setErrorMsg(String(e.message || e));
        }
    }

    return (
        <div className="container">
            <h1>ECG Pomodoro (MVP)</h1>

            <div className="row">
                <button
                    onClick={() => setTab("pomodoro")}
                    className={tab === "pomodoro" ? "primary" : ""}
                >
                    Pomodoro
                </button>
                <button
                    onClick={() => setTab("demo")}
                    className={tab === "demo" ? "primary" : ""}
                >
                    Demo Pipeline
                </button>
            </div>

            {tab === "pomodoro" && (
                <>
                    <div className="badge">{state.kind}</div>

                    {state.kind === "HOME" && (
                        <>
                            <p className="hint">
                                Work: {state.settings.workMinutes} min / Rest:{" "}
                                {state.settings.restMinutes} min
                            </p>
                            <div className="row">
                                <button
                                    onClick={() =>
                                        dispatch({
                                            type: "START_WORK",
                                            nowMs: Date.now(),
                                        })
                                    }
                                >
                                    開始專注
                                </button>
                                <button
                                    onClick={() =>
                                        dispatch({ type: "GO_CONFIG" })
                                    }
                                >
                                    設定
                                </button>
                            </div>
                        </>
                    )}

                    {state.kind === "CONFIG" && (
                        <>
                            <p className="hint">
                                工作最短 15 分鐘；調整單位 1 分鐘。
                            </p>
                            <div className="form">
                                <label>
                                    工作分鐘：
                                    <input
                                        type="number"
                                        step={1}
                                        min={MIN_WORK_MINUTES}
                                        value={state.draft.workMinutes}
                                        onChange={(e) =>
                                            dispatch({
                                                type: "SET_WORK_MINUTES",
                                                value: Number(e.target.value),
                                            })
                                        }
                                    />
                                </label>
                                <label>
                                    休息分鐘：
                                    <input
                                        type="number"
                                        step={1}
                                        min={MIN_REST_MINUTES}
                                        value={state.draft.restMinutes}
                                        onChange={(e) =>
                                            dispatch({
                                                type: "SET_REST_MINUTES",
                                                value: Number(e.target.value),
                                            })
                                        }
                                    />
                                </label>
                            </div>

                            <div className="row">
                                <button
                                    onClick={() =>
                                        dispatch({ type: "SAVE_CONFIG" })
                                    }
                                >
                                    儲存
                                </button>
                                <button
                                    onClick={() =>
                                        dispatch({ type: "GO_HOME" })
                                    }
                                >
                                    回主頁
                                </button>
                            </div>
                        </>
                    )}

                    {(state.kind === "WORK" ||
                        state.kind === "PAUSE" ||
                        state.kind === "REST") && (
                        <>
                            <div className="time">{formatMMSS(msLeft)}</div>

                            {state.kind === "WORK" && (
                                <div className="row">
                                    <button
                                        onClick={() =>
                                            dispatch({
                                                type: "PAUSE",
                                                nowMs: Date.now(),
                                            })
                                        }
                                    >
                                        暫停
                                    </button>
                                    <button
                                        onClick={() =>
                                            dispatch({
                                                type: "FORCE_REST",
                                                nowMs: Date.now(),
                                            })
                                        }
                                    >
                                        提早休息
                                    </button>
                                    <button
                                        onClick={() =>
                                            dispatch({ type: "GO_HOME" })
                                        }
                                    >
                                        回主頁
                                    </button>
                                </div>
                            )}

                            {state.kind === "PAUSE" && (
                                <div className="row">
                                    <button
                                        onClick={() =>
                                            dispatch({
                                                type: "RESUME",
                                                nowMs: Date.now(),
                                            })
                                        }
                                    >
                                        繼續
                                    </button>
                                </div>
                            )}

                            {state.kind === "REST" && (
                                <>
                                    <p className="hint">
                                        AI 思考中…（MVP 先不做真正建議）
                                    </p>
                                    <div className="row">
                                        <button
                                            onClick={() =>
                                                dispatch({
                                                    type: "SKIP_REST",
                                                    nowMs: Date.now(),
                                                })
                                            }
                                        >
                                            跳過休息
                                        </button>
                                        <button
                                            onClick={() =>
                                                dispatch({ type: "GO_HOME" })
                                            }
                                        >
                                            回主頁
                                        </button>
                                    </div>
                                </>
                            )}
                        </>
                    )}
                </>
            )}

            {tab === "demo" && (
                <>
                    <p className="hint">
                        先啟動兩個 stub service：ECG(8001)、AI(8002)，再按下 Run
                        Demo 測試 JSON 介面。
                    </p>

                    <div className="row">
                        <button onClick={runDemo}>Run Demo</button>
                        <a
                            href={`${ECG_API}/docs`}
                            target="_blank"
                            rel="noreferrer"
                        >
                            ECG /docs
                        </a>
                        <a
                            href={`${AI_API}/docs`}
                            target="_blank"
                            rel="noreferrer"
                        >
                            AI /docs
                        </a>
                    </div>

                    {demoStatus && <div className="hint">{demoStatus}</div>}
                    {errorMsg && <pre className="error">{errorMsg}</pre>}

                    {features && (
                        <>
                            <h3>ECG Features</h3>
                            <pre className="box">
                                {JSON.stringify(features, null, 2)}
                            </pre>
                        </>
                    )}

                    {prediction && (
                        <>
                            <h3>AI Prediction</h3>
                            <pre className="box">
                                {JSON.stringify(prediction, null, 2)}
                            </pre>
                        </>
                    )}
                </>
            )}
        </div>
    );
}
