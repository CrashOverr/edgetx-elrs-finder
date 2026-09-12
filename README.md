# 🚁 EdgeTX Lua Scripts (Universal Edition: Color & B/W Optimized)

A growing collection of **EdgeTX Lua scripts** specifically adapted and optimized for the **RadioMaster TX16S MKII** (480×272 color screen), while maintaining **full backward compatibility** with black-and-white displays (like the RadioMaster Pocket or Boxer).

> 📝 **Note:** This repository is an adaptation of the excellent work by [@iamsunilchahal](https://github.com/iamsunilchahal/edgetx-lua-scripts-bw). All scripts here have been completely redesigned to leverage auto-scaling, dynamic colors, and improved workflows across all EdgeTX radio resolutions.

---

## 📂 Repository Structure

```text
SCRIPTS/  
├── TOOLS/        # Tools accessible via the SYS → Tools menu  
├── MIXES/        # Model-specific scripts  
└── TELEMETRY/    # Telemetry screen scripts  
```

Copy the relevant folders directly to your radio's **SD card root**.

---

## 📜 Available Scripts

### 🔍 1. ELRS_Finder.lua

> **📱 Display Name:** ELRS Finder  
> **📂 Type:** Tool (`/SCRIPTS/TOOLS/`)

**🎯 Purpose:**  
An **RSSI-based ELRS lost model finder** (Geiger style) using ELRS/CRSF telemetry, featuring a universal UI that adapts to any screen.

#### ✨ Key Features & Improvements:

| Feature | Description |
|---------|-------------|
|  **Universal Auto-Detection** | Automatically detects Color vs. B/W screens and adjusts layout, fonts, and colors to prevent syntax errors or overflow. |
|  **Dynamic Color Gradients** | UI and progress bar smoothly transition from **Red** (weak) → **Yellow** (medium) → **Green** (strong signal) on color screens. |
| 👁️ **Guaranteed Visibility** | The percentage text inside the progress bar uses a high-contrast **Cyan** color, ensuring it is always readable even when the bar is nearly empty. |
| 🌑 **Optimized Dark Mode** | Forces a pure black background (`lcd.clear(BLACK)`) on color screens for maximum contrast and a premium look. |
| 🔤 **Giant Typography** | Uses `XXLSIZE`/`DBLSIZE` fonts on color screens for maximum visibility at a distance, scaled down appropriately for B/W screens. |
| 🔊 **Smart Audio Cadence** | Plays faster beeps as you point toward the quad and signal strength increases. |

#### 📥 Installation:
1. Copy `ELRS_Finder.lua` into `/SCRIPTS/TOOLS/` on your SD card.
2. On your radio: Long-press `SYS` → **Tools** tab → run **ELRS Finder**.
3. 💡 **Pro Tip:** Set **fixed low TX power** (10–25 mW) in the ELRS menu and sweep the radio slowly to locate signal peaks.

---

### 📝 2. Field_Notes.lua

> **📱 Display Name:** Field Notes  
> **📂 Type:** Tool (`/SCRIPTS/TOOLS/`)

**🎯 Purpose:**  
A **quick logging tool** for recording flight details directly from your radio, completely redesigned to prevent text overflow and streamline data entry.

#### ✨ Key Features & Improvements:

| Feature | Description |
|---------|-------------|
| 🔢 **Smart 4-Digit Prop Input** | Displays as a single, clean 4-digit number (e.g., "5040") but allows fast, **digit-by-digit editing** via the scroll wheel. No more endless scrolling! |
|  **Status Color Coding** | Visual indicators (**Green** → **Yellow** → **Red**) for equipment condition on color screens. |
| 📐 **Auto-Scaling Layout** | Proportional spacing ensures the list fits perfectly on 480x272, 320x240, and 128x64 screens without cut-off text. |
| ⚡ **Optimized Workflow** | Single-page list of editable fields, saves timestamped entries to `/LOGS/fieldnotes.txt`, and exits automatically after saving. |

#### 📋 Logged fields:
- ✅ Pack number & condition  
- ✅ Prop size (4-digit) & condition  
- ✅ Flight notes/tags  

#### 📥 Installation:
1. Copy `Field_Notes.lua` into `/SCRIPTS/TOOLS/` on your SD card.
2. On your radio: Long-press `SYS` → **Tools** tab → run **Field Notes**.
3. Navigate with the wheel, press `ENTER` to edit, and select **[ Save ]** at the bottom to store your entry.

#### 📄 Example log file:
```text
2026-09-12 02:38 | Pack: 1 (Bad) | Prop: 8040 (Damaged) | Note: Tuned
2026-09-12 02:40 | Pack: 11 (Good) | Prop: 5040 (New) | Note: Smooth
```

---

## 📥 Installation for All Scripts

### 🚀 Quick Start:
1. **Download this repository:**
   - 📦 **Option A:** Click the green **Code** button → **Download ZIP**
   - 💻 **Option B:** Clone via Git (`git clone https://github.com/CrashOverr/tx16s-elrs-finder.git`)
2. **Install:** Extract and copy the `SCRIPTS` folder to the root of your EdgeTX SD card.
3. **Access scripts from:**
   - ️ **Tools menu** (for `/SCRIPTS/TOOLS/`)
   - 🎛️ **Model scripts** (for `/SCRIPTS/MIXES/`)
   - 📊 **Telemetry screens** (for `/SCRIPTS/TELEMETRY/`)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — feel free to use, modify, and share.  

> ⚠️ **Please note:** This is an adaptation. All original rights and credits remain with the original author ([@iamsunilchahal](https://github.com/iamsunilchahal/edgetx-lua-scripts-bw)).

---

<p align="center">
<i>Adapted & Optimized for Universal EdgeTX Compatibility by: <b>Mauricio Gomez / CrashOverr</b></i>
</p>
