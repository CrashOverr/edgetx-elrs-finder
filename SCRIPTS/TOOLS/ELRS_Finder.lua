-- =========================================================================
-- ELRS Lost Model Finder (Geiger Style) - Universal Edition
-- =========================================================================
-- Original Script by: iamsunilchahal
-- Original Repository: https://github.com/iamsunilchahal/edgetx-lua-scripts-bw
--
-- Modified & Optimized by: Mauricio Gomez / CrashOverr
-- Modifications made:
--   - Auto-detects Color vs B/W screens and adapts accordingly
--   - Color screens: Dark mode with dynamic gradient (Red -> Yellow -> Green)
--   - B/W screens: High contrast with INVERS flag and smaller fonts
--   - Auto-scaling layout for different screen resolutions
--   - Percentage text uses CYAN for guaranteed visibility on any bar color
--
-- License: Same as original repository (Please check original repo for details)
-- =========================================================================

local lastBeep = 0
local avg = -120
local have = { rssi=false, snr=false, rql=false }

-- Screen configuration (auto-detect from system)
local W = LCD_W
local H = LCD_H

-- Detect if this is a color screen
local IS_COLOR = (W > 128)

local function readSignal()
  local rssi = getValue("1RSS")
  if rssi and rssi ~= 0 then have.rssi=true; return rssi, "dBm" end
  local snr = getValue("RSNR")
  if snr and snr ~= 0 then have.snr=true; return (snr*2-120), "SNR" end
  local rql = getValue("RQly")
  if rql and rql ~= 0 then have.rql=true; return (rql-120), "LQ" end
  return -120, "NA"
end

local function clamp(x,a,b) 
  if x<a then return a 
  elseif x>b then return b 
  else return x end 
end

-- Function to create a color gradient (only for color screens)
local function getSignalColor(strength)
  if not IS_COLOR then return 0 end
  
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
  avg = 0.8*avg + 0.2*(raw)

  local strength = clamp( (avg + 110) * (100/70), 0, 100 )

  local period = clamp( 120 - strength, 10, 120 )
  if now - lastBeep >= period then
    local freq = 600 + (strength*6)
    playTone(freq, 30, 0, 0)
    lastBeep = now
  end

  -- ==========================================
  -- UI DRAWING (Auto-detects Color vs B/W)
  -- ==========================================
  
  if IS_COLOR then
    lcd.clear(BLACK) -- FORCE DARK BACKGROUND FOR COLOR SCREENS
  else
    lcd.clear()      -- Default for B/W screens
  end
  
  local color = getSignalColor(strength)

  if IS_COLOR then
    -- ==========================================
    -- COLOR SCREEN VERSION
    -- ==========================================
    
    -- Title
    lcd.drawText(W/2, math.floor(H * 0.04), "ELRS FINDER", CENTER + DBLSIZE + WHITE)

    -- Main value
    lcd.drawText(W/2, math.floor(H * 0.20), string.format("%d %s", raw, kind), CENTER + XXLSIZE + color)

    -- Progress bar
    local barX = math.floor(W * 0.08)
    local barY = math.floor(H * 0.53)
    local barW = math.floor(W * 0.83)
    local barH = math.floor(H * 0.18)
    
    lcd.drawRectangle(barX, barY, barW, barH, GREY)
    local fillW = math.floor((barW - 4) * (strength / 100))
    if fillW > 0 then
      lcd.drawFilledRectangle(barX + 2, barY + 2, fillW, barH - 4, color)
    end

    -- Percentage inside the bar (CYAN for guaranteed visibility on any color)
    local pctText = string.format("%d%%", strength)
    local txtY = barY + math.floor(barH * 0.2)
    lcd.drawText(W/2, txtY, pctText, CENTER + DBLSIZE + lcd.RGB(0, 255, 255))

    -- Statistics at the bottom
    lcd.drawText(math.floor(W * 0.08), math.floor(H * 0.81), "Src: " .. kind, SMLSIZE + LIGHTGREY)
    lcd.drawText(W/2, math.floor(H * 0.81), "Avg: " .. string.format("%.0f", avg), CENTER + SMLSIZE + LIGHTGREY)
    lcd.drawText(W - math.floor(W * 0.08), math.floor(H * 0.81), "Raw: " .. raw, RIGHT + SMLSIZE + LIGHTGREY)

    -- Tip message
    lcd.drawText(W/2, math.floor(H * 0.88), "Tip: Lower TX power as you get close.", CENTER + SMLSIZE + GREY)

  else
    -- ==========================================
    -- B/W SCREEN VERSION (128x64)
    -- ==========================================
    
    -- Title
    lcd.drawText(W/2, 2, "ELRS FINDER", CENTER + INVERS)

    -- Main value
    lcd.drawText(W/2, 18, string.format("%d %s", raw, kind), CENTER + MIDSIZE + INVERS)

    -- Progress bar
    local barX = 10
    local barY = 34
    local barW = W - 20
    local barH = 10
    
    lcd.drawRectangle(barX, barY, barW, barH)
    local fillW = math.floor(barW * (strength / 100))
    if fillW > 0 then
      lcd.drawFilledRectangle(barX, barY, fillW, barH)
    end

    -- Percentage inside the bar
    lcd.drawText(W/2, barY + 1, string.format("%d%%", strength), CENTER + INVERS)

    -- Statistics at the bottom
    lcd.drawText(2, 50, "Src:" .. kind, SMLSIZE)
    lcd.drawText(W/2, 50, "Avg:" .. string.format("%.0f", avg), CENTER + SMLSIZE)
    lcd.drawText(W - 2, 50, "Raw:" .. raw, RIGHT + SMLSIZE)

    -- Tip message
    lcd.drawText(W/2, math.floor(H * 0.88), "Tip: Lower TX power close.", CENTER + SMLSIZE)
  end

  return 0
end

return { run=run_func }
