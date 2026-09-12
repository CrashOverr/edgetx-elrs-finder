-- =========================================================================
-- ELRS Lost Model Finder (Geiger Style) - TX16S MKII Color Edition
-- =========================================================================
-- Original Script by: iamsunilchahal
-- Original Repository: https://github.com/iamsunilchahal/edgetx-lua-scripts-bw
--
-- Modified & Optimized for: RadioMaster TX16S MKII (480x272 Color Screen)
-- Modified by: Mauricio Gomez / CrashOverr
-- Modifications made:
--   - Full color UI with dynamic signal strength gradient (Red -> Yellow -> Green)
--   - Enlarged typography (XXLSIZE/DBLSIZE) for better visibility at a distance
--   - Spanish translation for the tip message only
--   - Layout completely redesigned for 480x272 resolution
--
-- License: Same as original repository (Please check original repo for details)
-- =========================================================================

local lastBeep = 0
local avg = -120
local have = { rssi=false, snr=false, rql=false }

-- Screen configuration for TX16S (480x272)
local W = 480
local H = 272

local function readSignal()
    -- Prefer 1RSS (CRSF dBm), else RSNR (dB), else RQly (%)
  local rssi = getValue("1RSS")  -- typically negative dBm, eg -95..-40
  if rssi and rssi ~= 0 then have.rssi=true; return rssi, "dBm" end
  local snr = getValue("RSNR")   -- -20..+20 dB typical
  if snr and snr ~= 0 then have.snr=true; return (snr*2-120), "SNR" end
  local rql = getValue("RQly")   -- 0..100 %
  if rql and rql ~= 0 then have.rql=true; return (rql-120), "LQ" end
  return -120, "NA"
end

local function clamp(x,a,b) 
  if x<a then return a 
  elseif x>b then return b 
  else return x end 
end

-- Function to create a color gradient (Red -> Yellow -> Green)
local function getSignalColor(strength)
  local r, g = 0, 0
  if strength < 50 then
    r = 255
    g = math.floor(255 * (strength / 50))
  else
    r = math.floor(255 * (1 - (strength - 50) / 50))
    g = 255
  end
  return lcd.RGB(r, g, 0)
end

local function run_func(event)
  local now = getTime() 
  local raw, kind = readSignal()
  -- Exponential moving average for stability
  avg = 0.8*avg + 0.2*(raw)

  -- Map avg (~-110..-40) to 0..100 “strength”
  local strength = clamp( (avg + 110) * (100/70), 0, 100 )

  -- Beep cadence: stronger ⇒ shorter interval
  local period = clamp( 120 - strength, 10, 120 )
  if now - lastBeep >= period then
    local freq = 600 + (strength*6)
    playTone(freq, 30, 0, 0)
    lastBeep = now
  end

  -- ==========================================
  -- UI DRAWING (Optimized for 480x272 Color)
  -- ==========================================
  lcd.clear(BLACK) -- Dark background
  
  local color = getSignalColor(strength)

  -- Title
  lcd.drawText(W/2, 10, "ELRS FINDER", CENTER + DBLSIZE + WHITE)

  -- Main value (Raw and type)
  local mainText = string.format("%d %s", raw, kind)
  lcd.drawText(W/2, 55, mainText, CENTER + XXLSIZE + color)

  -- Giant progress bar
  local barX, barY, barW, barH = 40, 145, 400, 50
  local borderColor = GREY
  lcd.drawRectangle(barX, barY, barW, barH, borderColor)
  
  local fillW = math.floor((barW - 4) * (strength / 100))
  if fillW > 0 then
    lcd.drawFilledRectangle(barX + 2, barY + 2, fillW, barH - 4, color)
  end

  -- Percentage inside the bar
  local pctText = string.format("%d%%", strength)
  local txtColor = (strength > 15) and BLACK or WHITE
  lcd.drawText(W/2, barY + 12, pctText, CENTER + DBLSIZE + txtColor)

  -- Statistics at the bottom
  lcd.drawText(40, 220, "Src: " .. kind, SMLSIZE + LIGHTGREY)
  lcd.drawText(W/2, 220, "Avg dBm est: " .. string.format("%.1f", avg), CENTER + SMLSIZE + LIGHTGREY)
  lcd.drawText(W - 40, 220, "Raw: " .. raw, RIGHT + SMLSIZE + LIGHTGREY)

  -- Tip message in Spanish
  lcd.drawText(W/2, 250, "Tip: Lower TX power as you get close.", CENTER + SMLSIZE + GREY)

  return 0
end

return { run=run_func }
