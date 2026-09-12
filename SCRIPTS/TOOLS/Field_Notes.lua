-- =========================================================================
-- Field Notes (Digital Flight Log) - Universal Edition
-- =========================================================================
-- Original Script by: iamsunilchahal
-- Original Repository: https://github.com/iamsunilchahal/edgetx-lua-scripts-bw
--
-- Modified & Optimized by: Mauricio Gomez / CrashOverr
-- Modifications made:
--   - Auto-detects Color vs B/W screens and adapts accordingly
--   - Color screens: Dark mode with status-based color coding
--   - B/W screens: High contrast with INVERS flag and smaller fonts
--   - "Prop" field displays as single 4-digit number but edits digit-by-digit
--   - Auto-scaling layout for different screen resolutions
--
-- License: Same as original repository (Please check original repo for details)
-- =========================================================================

-- -------- Event aliases --------
local EVT_NEXT = EVT_VIRTUAL_NEXT or 0x0305
local EVT_PREV = EVT_VIRTUAL_PREV or 0x0304
local EVT_INC  = EVT_VIRTUAL_INC  or 0x0307
local EVT_DEC  = EVT_VIRTUAL_DEC  or 0x0306
local EVT_ENT  = EVT_ENTER_BREAK  or 0x0059
local EVT_EXT  = EVT_EXIT_BREAK   or 0x005B
local EVT_ROT_R = (rawget(_G,"EVT_ROT_RIGHT") and EVT_ROT_RIGHT) or 0x0101
local EVT_ROT_L = (rawget(_G,"EVT_ROT_LEFT")  and EVT_ROT_LEFT)  or 0x0100

-- -------------------- Model --------------------
local fields = {
  { key="Pack #",    type="number", val=1,  min=1,  max=99, step=1 },
  { key="Pack Cond", type="enum",   opts={"New","Good","Tired","Bad"}, idx=2 },
  { key="Prop",      type="prop",   digits={5,0,4,0}, currentDigit=1 },
  { key="Prop Cond", type="enum",   opts={"New","Chipped","Damaged"},  idx=1 },
  { key="Note",      type="enum",   opts={"Smooth","Wobbly","Yaw drift","Crash","Fast","Tuned"}, idx=1 },
  { key="[ Save ]",  type="save" }
}

local sel = 1
local editing = false

-- Screen configuration (auto-detect)
local W = LCD_W
local H = LCD_H
local IS_COLOR = (W > 128)

-- Scrolling window (different for each screen type)
local ROW_H, HEADER_Y, LIST_START_Y, VISIBLE_ROWS, top

if IS_COLOR then
  ROW_H = math.floor(H * 0.12)
  HEADER_Y = math.floor(H * 0.04)
  LIST_START_Y = math.floor(H * 0.15)
  VISIBLE_ROWS = math.floor((H - LIST_START_Y - math.floor(H * 0.15)) / ROW_H)
else
  ROW_H = 9
  HEADER_Y = 2
  LIST_START_Y = 14
  VISIBLE_ROWS = 5
end
top = 1

-- Debounce / exit flags
local lastEnterTick = 0
local shouldExit = false
local DEBOUNCE_TICKS = 18

-- -------------------- Helpers --------------------
local function clamp(v, a, b) 
  if v < a then return a 
  elseif v > b then return b 
  else return v end 
end

-- Function to get color based on field value (only for color screens)
local function getStatusColor(field)
  if not IS_COLOR then return 0 end
  
  if field.type == "number" or field.type == "prop" then
    return lcd.RGB(100, 200, 255)
  elseif field.type == "enum" then
    local opts = field.opts
    local idx = field.idx or 1
    local total = #opts
    local ratio = (idx - 1) / (total - 1)
    local r, g = 0, 0
    
    if ratio < 0.5 then
      r = math.floor(255 * (ratio * 2))
      g = 255
    else
      r = 255
      g = math.floor(255 * (1 - (ratio - 0.5) * 2))
    end
    
    return lcd.RGB(r, g, 0)
  elseif field.type == "save" then
    return lcd.RGB(0, 255, 100)
  end
  return 0
end

local function fmtRow(i)
  local f = fields[i]
  if f.type == "number" then
    return string.format("%s: %d", f.key, f.val)
  elseif f.type == "prop" then
    local propStr = string.format("%d%d%d%d", f.digits[1], f.digits[2], f.digits[3], f.digits[4])
    return string.format("%s: %s", f.key, propStr)
  elseif f.type == "enum" then
    return string.format("%s: %s", f.key, f.opts[f.idx])
  else
    return f.key
  end
end

local function ensureVisible()
  if sel < top then
    top = sel
  elseif sel > top + VISIBLE_ROWS - 1 then
    top = sel - (VISIBLE_ROWS - 1)
  end
  if top < 1 then top = 1 end
  local maxTop = math.max(1, #fields - VISIBLE_ROWS + 1)
  if top > maxTop then top = maxTop end
end

local function draw()
  -- FORCE DARK BACKGROUND FOR COLOR SCREENS
  if IS_COLOR then
    lcd.clear(BLACK)
  else
    lcd.clear()
  end
  
  if IS_COLOR then
    -- ==========================================
    -- COLOR SCREEN VERSION
    -- ==========================================
    
    -- Title
    lcd.drawText(W/2, HEADER_Y, "FIELD NOTES", CENTER + DBLSIZE + WHITE)
    
    -- Draw visible rows
    local y = LIST_START_Y
    local last = math.min(#fields, top + VISIBLE_ROWS - 1)
    
    for i = top, last do
      local f = fields[i]
      local line = fmtRow(i)
      local color = getStatusColor(f)
      
      if i == sel then
        lcd.drawFilledRectangle(math.floor(W * 0.04), y - 2, W - math.floor(W * 0.08), ROW_H, lcd.RGB(50, 50, 50))
        lcd.drawRectangle(math.floor(W * 0.04), y - 2, W - math.floor(W * 0.08), ROW_H, color)
        
        local displayText = line
        if editing then
          displayText = line .. " <edit>"
        end
        lcd.drawText(math.floor(W * 0.06), y + math.floor(ROW_H * 0.2), displayText, MIDSIZE + color)
      else
        lcd.drawText(math.floor(W * 0.06), y + math.floor(ROW_H * 0.2), line, MIDSIZE + color)
      end
      
      -- Draw progress bar for numeric fields
      if f.type == "number" and i == sel then
        local barX = W - math.floor(W * 0.27)
        local barY = y + math.floor(ROW_H * 0.25)
        local barW = math.floor(W * 0.19)
        local barH = math.floor(ROW_H * 0.5)
        local progress = (f.val - f.min) / (f.max - f.min)
        local fillW = math.floor(barW * progress)
        
        lcd.drawRectangle(barX, barY, barW, barH, GREY)
        if fillW > 0 then
          lcd.drawFilledRectangle(barX + 1, barY + 1, fillW - 2, barH - 2, color)
        end
      end
      
      y = y + ROW_H
    end
    
    -- Scroll indicators
    if top > 1 then
      lcd.drawText(W/2, LIST_START_Y - math.floor(H * 0.05), "^", CENTER + SMLSIZE + LIGHTGREY)
    end
    if last < #fields then
      lcd.drawText(W/2, LIST_START_Y + VISIBLE_ROWS * ROW_H + math.floor(H * 0.02), "v", CENTER + SMLSIZE + LIGHTGREY)
    end
    
    -- Instructions at bottom
    lcd.drawText(W/2, math.floor(H * 0.93), "Wheel: +/- | ENTER: Edit/Save", CENTER + SMLSIZE + GREY)

  else
    -- ==========================================
    -- B/W SCREEN VERSION (128x64)
    -- ==========================================
    
    -- Title
    lcd.drawText(2, HEADER_Y, "FIELD NOTES", INVERS)
    
    -- Draw visible rows
    local y = LIST_START_Y
    local last = math.min(#fields, top + VISIBLE_ROWS - 1)
    
    for i = top, last do
      local f = fields[i]
      local line = fmtRow(i)
      
      if i == sel then
        local displayText = line
        if editing then
          displayText = line .. " <edit>"
        end
        lcd.drawText(2, y, displayText, INVERS)
      else
        lcd.drawText(2, y, line, 0)
      end
      
      y = y + ROW_H
    end
    
    -- Scroll indicators
    if top > 1 then
      lcd.drawText(120, LIST_START_Y - 8, "^", 0)
    end
    if last < #fields then
      lcd.drawText(120, LIST_START_Y + VISIBLE_ROWS * ROW_H - 1, "v", 0)
    end
    
    -- Instructions at bottom (NO color constants to avoid nil errors)
    lcd.drawText(W/2, H - 8, "ENTER: Edit/Save", CENTER + SMLSIZE)
  end
end

local function saveLog()
  local packNum, packCond, propCond, note = 1,"?","?","?"
  local propDigits = {0,0,0,0}
  
  for _,f in ipairs(fields) do
    if f.key=="Pack #"    then packNum = f.val end
    if f.key=="Pack Cond" then packCond = f.opts[f.idx] end
    if f.key=="Prop"      then propDigits = f.digits end
    if f.key=="Prop Cond" then propCond = f.opts[f.idx] end
    if f.key=="Note"      then note = f.opts[f.idx] end
  end

  local prop = string.format("%d%d%d%d", propDigits[1], propDigits[2], propDigits[3], propDigits[4])

  local dt = getDateTime()
  local date = string.format("%04d-%02d-%02d", dt.year, dt.mon, dt.day)
  local time = string.format("%02d:%02d", dt.hour, dt.min)
  local line = string.format("%s %s | Pack: %d (%s) | Prop: %s (%s) | Note: %s\n",
                              date, time, packNum, packCond, prop, propCond, note)

  local f = io.open("/LOGS/fieldnotes.txt","a")
  if f then
    io.write(f, line)
    io.close(f)
    playTone(1200, 60, 0, 0)
  else
    playTone(300, 200, 0, 0)
  end
end

local function changeValue(dir)
  local f = fields[sel]
  if not f then return end
  
  if f.type == "number" then
    local v = (f.val or 0) + (dir * (f.step or 1))
    f.val = clamp(v, f.min or -32768, f.max or 32767)
  elseif f.type == "prop" then
    local d = f.currentDigit or 1
    f.digits[d] = clamp((f.digits[d] or 0) + dir, 0, 9)
  elseif f.type == "enum" then
    local n = #f.opts
    local idx = (f.idx or 1) + dir
    while idx < 1 do idx = idx + n end
    while idx > n do idx = idx - n end
    f.idx = idx
  end
end

local function onEvent(event)
  if event == EVT_ROT_R then event = EVT_NEXT end
  if event == EVT_ROT_L then event = EVT_PREV end

  if event == EVT_EXT then
    if editing then editing = false end
    return
  end

  if event == EVT_ENT then
    local now = getTime()
    if now - lastEnterTick < DEBOUNCE_TICKS then return end
    lastEnterTick = now

    local f = fields[sel]
    if editing then
      if f.type == "prop" then
        f.currentDigit = (f.currentDigit or 1) + 1
        if f.currentDigit > 4 then
          f.currentDigit = 1
          editing = false
        end
      else
        editing = false
      end
    else
      if f.type == "save" then
        saveLog()
        shouldExit = true
      else
        editing = true
        if f.type == "prop" then
          f.currentDigit = 1
        end
      end
    end
    return
  end

  if event == EVT_NEXT or event == EVT_PREV then
    if editing then
      local dir = (event == EVT_NEXT) and 1 or -1
      changeValue(dir)
    else
      if event == EVT_NEXT and sel < #fields then 
        sel = sel + 1 
      elseif event == EVT_PREV and sel > 1 then 
        sel = sel - 1 
      end
      ensureVisible()
    end
  elseif event == EVT_INC or event == EVT_DEC then
    if editing then
      local dir = (event == EVT_INC) and 1 or -1
      changeValue(dir)
    else
      if event == EVT_INC and sel < #fields then 
        sel = sel + 1 
      elseif event == EVT_DEC and sel > 1 then 
        sel = sel - 1 
      end
      ensureVisible()
    end
  end
end

local function run(event)
  if shouldExit then return 1 end
  onEvent(event)
  draw()
  return 0
end

return { run=run }
