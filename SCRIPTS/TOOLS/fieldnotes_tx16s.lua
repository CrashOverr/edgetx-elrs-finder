-- =========================================================================
-- Field Notes (Digital Flight Log) - TX16S MKII Color Edition
-- =========================================================================
-- Original Script by: iamsunilchahal
-- Original Repository: https://github.com/iamsunilchahal/edgetx-lua-scripts-bw
--
-- Modified & Optimized for: RadioMaster TX16S MKII (480x272 Color Screen)
-- Modified by: Mauricio Gomez / CrashOverr
-- Modifications made:
--   - Full color UI with status-based color coding (Green/Yellow/Red)
--   - Adjusted typography (MIDSIZE for list) to prevent screen overflow
--   - "Prop" field displays as single 4-digit number but edits digit-by-digit
--   - Visual progress bar for numeric fields
--   - Layout perfectly fitted for 480x272 resolution (no cut-off text)
--
-- License: Same as original repository (Please check original repo for details)
-- =========================================================================

-- -------- Event aliases (covering multiple EdgeTX builds) --------
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
  { key="Prop",      type="prop",   digits={5,0,4,0}, currentDigit=1 },  -- 4 digits, starts at 5040
  { key="Prop Cond", type="enum",   opts={"New","Chipped","Damaged"},  idx=1 },
  { key="Note",      type="enum",   opts={"Smooth","Wobbly","Yaw drift","Crash","Fast","Tuned"}, idx=1 },
  { key="[ Save ]",  type="save" }
}

local sel = 1           -- focused row
local editing = false   -- edit mode flag

-- Scrolling window (Adjusted to fit 272px height perfectly)
local ROW_H = 32
local HEADER_Y = 10
local LIST_START_Y = 40
local VISIBLE_ROWS = 6
local top = 1           -- first visible row

-- Debounce / exit flags
local lastEnterTick = 0
local shouldExit = false
local DEBOUNCE_TICKS = 18  -- ~180ms (getTime() is 10ms ticks)

-- Screen configuration
local W = 480
local H = 272

-- -------------------- Helpers --------------------
local function clamp(v, a, b) 
  if v < a then return a 
  elseif v > b then return b 
  else return v end 
end

-- Function to get color based on field value (status indicator)
local function getStatusColor(field)
  if field.type == "number" or field.type == "prop" then
    return lcd.RGB(100, 200, 255) -- Light blue for numbers
  elseif field.type == "enum" then
    local opts = field.opts
    local idx = field.idx or 1
    local total = #opts
    
    -- Color gradient based on position in enum (first=green, last=red)
    local ratio = (idx - 1) / (total - 1)
    local r, g = 0, 0
    
    if ratio < 0.5 then
      -- Green to Yellow
      r = math.floor(255 * (ratio * 2))
      g = 255
    else
      -- Yellow to Red
      r = 255
      g = math.floor(255 * (1 - (ratio - 0.5) * 2))
    end
    
    return lcd.RGB(r, g, 0)
  elseif field.type == "save" then
    return lcd.RGB(0, 255, 100) -- Bright green for save button
  end
  return WHITE
end

local function fmtRow(i)
  local f = fields[i]
  if f.type == "number" then
    return string.format("%s: %d", f.key, f.val)
  elseif f.type == "prop" then
    -- Concatenate all 4 digits
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
  lcd.clear(BLACK) -- Dark background
  
  -- Title
  lcd.drawText(W/2, HEADER_Y, "FIELD NOTES", CENTER + DBLSIZE + WHITE)
  
  -- Draw visible rows
  local y = LIST_START_Y
  local last = math.min(#fields, top + VISIBLE_ROWS - 1)
  
  for i = top, last do
    local f = fields[i]
    local line = fmtRow(i)
    local color = getStatusColor(f)
    
    -- Draw selection highlight
    if i == sel then
      lcd.drawFilledRectangle(20, y - 2, W - 40, ROW_H, lcd.RGB(50, 50, 50))
      lcd.drawRectangle(20, y - 2, W - 40, ROW_H, color)
      
      -- Draw text with edit indicator
      local displayText = line
      if editing then
        displayText = line .. "  <edit>"
      end
      lcd.drawText(30, y + 6, displayText, MIDSIZE + color)
    else
      lcd.drawText(30, y + 6, line, MIDSIZE + color)
    end
    
    -- Draw progress bar for numeric fields
    if f.type == "number" and i == sel then
      local barX = W - 130
      local barY = y + 8
      local barW = 90
      local barH = 16
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
    lcd.drawText(W/2, LIST_START_Y - 15, "^", CENTER + SMLSIZE + LIGHTGREY)
  end
  if last < #fields then
    lcd.drawText(W/2, LIST_START_Y + VISIBLE_ROWS * ROW_H + 5, "v", CENTER + SMLSIZE + LIGHTGREY)
  end
  
  -- Instructions at bottom
  lcd.drawText(W/2, H - 20, "Wheel: ±1  |  ENTER: Edit/Save  |  EXIT: Back", CENTER + SMLSIZE + GREY)
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

  -- Concatenate prop digits into a single string
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
    playTone(1200, 60, 0, 0)     -- success chirp
  else
    playTone(300, 200, 0, 0)     -- error tone
  end
end

local function changeValue(dir)
  local f = fields[sel]
  if not f then return end
  
  if f.type == "number" then
    local v = (f.val or 0) + (dir * (f.step or 1))
    f.val = clamp(v, f.min or -32768, f.max or 32767)
  elseif f.type == "prop" then
    -- Edit current digit (0-9)
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
  -- Normalize wheel events
  if event == EVT_ROT_R then event = EVT_NEXT end
  if event == EVT_ROT_L then event = EVT_PREV end

  if event == EVT_EXT then
    if editing then editing = false end
    return
  end

  if event == EVT_ENT then
    -- Debounce ENTER to avoid multiple triggers
    local now = getTime()
    if now - lastEnterTick < DEBOUNCE_TICKS then return end
    lastEnterTick = now

    local f = fields[sel]
    if editing then
      -- If editing Prop, advance to next digit
      if f.type == "prop" then
        f.currentDigit = (f.currentDigit or 1) + 1
        if f.currentDigit > 4 then
          f.currentDigit = 1
          editing = false  -- Exit edit mode after 4th digit
        end
      else
        editing = false
      end
    else
      if f.type == "save" then
        saveLog()
        shouldExit = true      -- exit the tool after saving
      else
        editing = true
        if f.type == "prop" then
          f.currentDigit = 1  -- Start editing from first digit
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
  if shouldExit then return 1 end   -- close tool after save
  onEvent(event)
  draw()
  return 0
end

return { run=run }
