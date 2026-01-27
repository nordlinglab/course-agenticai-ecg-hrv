import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
import glob
from scipy.signal import butter, lfilter, find_peaks, welch
from scipy.integrate import trapezoid

# ==========================================
# 1. 系統參數與動態路徑設定
# ==========================================
# 取得路徑邏輯：當前位置 -> 往上二層 -> data-group/2026-Liu-Fan-Lee/
current_script_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.dirname(os.path.dirname(current_script_dir))
target_folder = os.path.join(root_dir, 'data-group', '2026-Fan-Lee-Liu', 'raw')

FS = 50  # 取樣率 50Hz
WINDOW_SIZE = int(0.15 * FS)

def robust_normalize(signal):
    """強韌標準化：確保不同檔案的位準差異不影響分析"""
    detrended = signal - np.mean(signal)
    std = np.std(detrended)
    return detrended / std if std > 0 else detrended

def bandpass_filter(data, fs=FS):
    """5-15Hz 帶通濾波"""
    nyq = 0.5 * fs
    low, high = 5.0 / nyq, 15.0 / nyq
    b, a = butter(1, [low, high], btype='band')
    return lfilter(b, a, data)

# ==========================================
# 2. 批次處理邏輯
# ==========================================
# 搜尋資料夾內所有 .csv 檔案
csv_files = glob.glob(os.path.join(target_folder, "*.csv"))

if not csv_files:
    print(f"在路徑中找不到任何 CSV 檔案：\n{target_folder}")
else:
    print(f"找到 {len(csv_files)} 個檔案，開始執行批次分析...\n")

for file_path in csv_files:
    file_name = os.path.basename(file_path)
    file_title = os.path.splitext(file_name)[0]
    
    try:
        # 讀取資料：3rd PPG, 4th ECG
        df = pd.read_csv(file_path, header=None)
        ppg_raw = robust_normalize(df.iloc[:, 2].values)
        ecg_raw = robust_normalize(df.iloc[:, 3].values)

        # A. Pan-Tompkins 偵測
        filtered = bandpass_filter(ecg_raw)
        integrated = np.convolve(np.diff(filtered)**2, np.ones(WINDOW_SIZE)/WINDOW_SIZE, 'same')
        r_peaks, _ = find_peaks(integrated, distance=int(FS*0.5), height=np.mean(integrated)*0.5)

        if len(r_peaks) >= 2:
            # --- [特徵萃取] ---
            rr_intervals = np.diff(r_peaks) / FS * 1000 
            bpm = 60 / (np.mean(rr_intervals) / 1000)
            sdnn = np.std(rr_intervals)
            rmssd = np.sqrt(np.mean(np.square(np.diff(rr_intervals))))
            
            # 頻域 (LF/HF)
            fs_rr = 1.0 / (np.mean(rr_intervals) / 1000.0)
            f, psd = welch(rr_intervals, fs=fs_rr, nperseg=min(len(rr_intervals), 256))
            lf = trapezoid(psd[(f >= 0.04) & (f <= 0.15)])
            hf = trapezoid(psd[(f >= 0.15) & (f <= 0.4)])
            lf_hf = lf / hf if hf > 0 else 0

            # 型態學 (P 波搜尋)
            p_peaks = []
            for r in r_peaks:
                s_start, s_end = max(0, r-int(0.25*FS)), max(0, r-int(0.05*FS))
                if s_start < s_end:
                    p_win = ecg_raw[s_start:s_end]
                    if len(p_win) > 0: p_peaks.append(s_start + np.argmax(p_win))
            
            st_indices = [r + int(0.08*FS) for r in r_peaks if r + int(0.08*FS) < len(ecg_raw)]
            st_level = np.mean(ecg_raw[st_indices]) if st_indices else 0

            # ==========================================
            # 3. 輸出與繪圖 (以檔名區別)
            # ==========================================
            print(f"--- 檔案分析報告: {file_name} ---")
            print(f"BPM: {bpm:.1f} | SDNN: {sdnn:.2f} | LF/HF: {lf_hf:.3f} | ST: {st_level:.3f}\n")

            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 10))

            # ECG 標註 (標題加入檔名)
            ax1.plot(ecg_raw, label='Normalized ECG', color='silver', alpha=0.6)
            ax1.scatter(r_peaks, ecg_raw[r_peaks], color='red', marker='v', s=60, label='R-peak')
            ax1.scatter(p_peaks, ecg_raw[p_peaks], color='green', marker='^', s=60, label='P-peak')
            
            # 加入分析數據方塊
            result_text = (f"File: {file_name}\nBPM: {bpm:.1f}\nSDNN: {sdnn:.2f} ms\nLF/HF: {lf_hf:.3f}\nST Level: {st_level:.3f}")
            ax1.text(0.02, 0.95, result_text, transform=ax1.transAxes, fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

            ax1.set_title(f"ECG Analysis - Source: {file_title}")
            ax1.legend(loc='upper right')
            ax1.grid(True, alpha=0.2)

            # PPG 對照
            ax2.plot(ppg_raw, color='tab:blue')
            ax2.set_title(f"PPG Signal - Source: {file_title}")
            ax2.grid(True, alpha=0.2)

            plt.tight_layout()
            
            # 自動存檔 (以檔名命名圖片)
            plt.savefig(os.path.join(current_script_dir, f"Result_{file_title}.png"))
            plt.show()

        else:
            print(f"檔案 {file_name}: 偵測到的 R 波不足，跳過特徵萃取。")

    except Exception as e:
        print(f"處理檔案 {file_name} 時發生錯誤: {e}")

print("所有檔案批次分析完成。")