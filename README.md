# EdgeTX Lua Scripts (TX16S MKII Color Optimized)

A growing collection of **EdgeTX Lua scripts** specifically adapted and optimized for the **RadioMaster TX16S MKII** 480×272 color screen.  

*Note: This repository is an adaptation of the excellent work by [@iamsunilchahal](https://github.com/iamsunilchahal/edgetx-lua-scripts-bw), originally optimized for black-and-white displays. All scripts here have been redesigned to leverage the color, resolution, and workflow of the TX16S MKII.*

## 📂 Repository Structure

SCRIPTS/  
├── TOOLS/        # Tools accessible via the SYS → Tools menu  
├── MIXES/        # Model-specific scripts  
└── TELEMETRY/    # Telemetry screen scripts  

Copy the relevant folders directly to your radio's **SD card root**.

---

## 📜 Available Scripts

### 1. [finder_tx16s.lua](SCRIPTS/TOOLS/finder_tx16s.lua)
**Type:** Tool (`/SCRIPTS/TOOLS/`)  
**Purpose:**  
An **RSSI-based ELRS lost model finder** (Geiger style) using ELRS/CRSF telemetry, fully redesigned for color screens.  
- **Dynamic Color Gradients:** UI and progress bar smoothly transition from Red (weak) → Yellow (medium) → Green (strong signal).
- **Giant Typography:** Uses XXLSIZE/DBLSIZE fonts for maximum visibility at a distance.
- **Smart Audio Cadence:** Plays faster beeps as you point toward the quad.

**Installation:**
1. Copy `finder_tx16s.lua` into `/SCRIPTS/TOOLS/` on your SD card.
2. On your radio:  
   - Long-press `SYS` → **Tools** tab → run **ELRS Finder**
3. For best results:  
   - Set **fixed low TX power** (10–25 mW) in the ELRS menu  
   - Sweep the radio slowly to locate signal peaks

---

### 2. [fieldnotes_tx16s.lua](SCRIPTS/TOOLS/fieldnotes_tx16s.lua)
**Type:** Tool (`/SCRIPTS/TOOLS/`)  
**Purpose:**  
A **quick logging tool** for recording flight details directly from your radio, optimized to prevent text overflow on the TX16S.  
Perfect for keeping track of pack health, prop condition, and flight notes between packs.  
- **Smart 4-Digit Prop Input:** Displays as a single 4-digit number (e.g., "5040") but allows fast, digit-by-digit editing via the scroll wheel, eliminating endless scrolling.
- **Status Color Coding:** Visual indicators (Green/Yellow/Red) for equipment condition.
- Single-page list of editable fields (scroll & press-to-edit).
- Saves timestamped entries to `/LOGS/fieldnotes.txt`  
- Exits automatically after saving  

**Logged fields:**
- Pack number & condition  
- Prop size (4-digit) & condition  
- Flight notes/tags  

**Installation:**
1. Copy `fieldnotes_tx16s.lua` into `/SCRIPTS/TOOLS/` on your SD card.
2. On your radio:  
   - Long-press `SYS` → **Tools** tab → run **Field Notes**
3. After editing, select **[ Save ]** at the bottom to store your entry.

**Example log file:**

      2026-09-12 02:38 | Pack: 1 (Bad) | Prop: 8040 (Damaged) | Note: Tuned
      2026-09-12 02:40 | Pack: 11 (Bad) | Prop: 5040 (Damaged) | Note: Smooth

---

## 📥 Installation for All Scripts
1. Download this repository:
   - **Option A:** Click the green **Code** button → **Download ZIP**
   - **Option B:** Clone via Git (`git clone https://github.com/CrashOverr/tx16s-elrs-finder.git`)
2. Extract and copy the `SCRIPTS` folder to the root of your EdgeTX SD card.
3. Access scripts from:
   - **Tools menu** (for `/SCRIPTS/TOOLS/`)
   - **Model scripts** (for `/SCRIPTS/MIXES/`)
   - **Telemetry screens** (for `/SCRIPTS/TELEMETRY/`)

---

## 📄 License
This project is licensed under the [MIT License](LICENSE) — feel free to use, modify, and share.  
*Please note: This is an adaptation. All original rights and credits remain with the original author ([@iamsunilchahal](https://github.com/iamsunilchahal/edgetx-lua-scripts-bw)).*
