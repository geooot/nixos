-- Hyprland 0.57 Lua config. Installed to ~/.config/hypr/hyprland.lua by
-- hyprland/home.nix, which substitutes the placeholder tokens below
-- (store paths, stylix colors, cursor) via replaceVars.
-- Keybinds are ported from the niri binds in home-manager/home.nix.

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "DP-1", mode = "2560x1440", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "2560x1440", position = "2560x0", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.2 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

---------------------
---- MY PROGRAMS ----
---------------------

local home = os.getenv("HOME")
local terminal = "@kitty@"
local browser = "@firefox@"
local fileManager = terminal .. " -e @yazi@"
local locker = "@hyprlock@"
local quickshell = "@quickshell@"
local screenshots = home .. "/Pictures/Screenshots"

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 4,
    border_size = 2,
    col = {
      active_border = "rgb(@accent@)",
      inactive_border = "rgb(@inactive@)",
    },
    resize_on_border = false,
    allow_tearing = true,
    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    -- Shown only on floating workspaces; see the floating-ws-shadow rule.
    shadow = { enabled = true, range = 16, render_power = 3, color = "rgba(00000035)" },
    blur = { enabled = false },
  },
  animations = { enabled = true },
  dwindle = {
    preserve_split = true,
  },
  scrolling = {
    column_width = 0.66667,
    fullscreen_on_one_column = false,
    focus_fit_method = 0,
    explicit_column_widths = "0.33333, 0.5, 0.66667, 1.0",
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
  xwayland = { force_zero_scaling = true },
})

hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 1, bezier = "quick" })
hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "quick" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, bezier = "quick", style = "popin 95%" })
hl.animation({ leaf = "workspaces", enabled = false })

---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout = "us",
    repeat_delay = 200,
    sensitivity = 0,
    touchpad = {
      disable_while_typing = false,
      natural_scroll = true,
      scroll_factor = 1,
      clickfinger_behavior = 1,
    },
  },
})

--------------------------------------------
---- WORKSPACE LAYOUTS (Omarchy-style) ----
---- per-workspace: dwindle / scrolling / floating, persisted ----
--------------------------------------------

-- Floating is not a Hyprland layout, so the mode floats the windows
-- themselves. Windows the mode floated carry FLOATED_TAG so leaving the mode
-- tiles only those; every window on a floating workspace carries
-- FLOATING_WS_TAG, which shadows follow. Tags live on the window, so they
-- survive config reloads and follow it between workspaces.
local FLOATED_TAG = "mode-floated"
local FLOATING_WS_TAG = "floating-ws"
local OPENED_TAG = "mode-opened"
local OPEN_RULE = "floating-open-"
local LAST_WORKSPACE = 2147483647

local state_dir = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/hypr"
os.execute('mkdir -p "' .. state_dir .. '"')
local layouts_file = state_dir .. "/layouts.json"

local mode_labels = { dwindle = "Tiling", scrolling = "Scrolling", floating = "Floating" }
local mode_order = { "dwindle", "scrolling", "floating" }

-- Workspaces without an entry in `modes` follow `default_mode`.
local modes = {}
local default_mode = "dwindle"

local function save_modes()
  local parts = {}
  for id, mode in pairs(modes) do
    parts[#parts + 1] = '"' .. id .. '":"' .. mode .. '"'
  end
  table.sort(parts)
  table.insert(parts, 1, '"default":"' .. default_mode .. '"')
  local f = io.open(layouts_file, "w")
  if f then
    f:write("{" .. table.concat(parts, ",") .. "}")
    f:close()
  end
end

local function load_modes()
  local f = io.open(layouts_file, "r")
  if not f then
    return
  end
  local content = f:read("*a") or ""
  f:close()
  local saved = {}
  for key, mode in string.gmatch(content, '"(%w+)":"(%a+)"') do
    if mode_labels[mode] then
      if key == "default" then
        default_mode = mode
      elseif tonumber(key) and tonumber(key) >= 1 then
        saved[tonumber(key)] = mode
      end
    end
  end
  for id, mode in pairs(saved) do
    if mode ~= default_mode then
      modes[id] = mode
    end
  end
end

local function tiled_default()
  return default_mode == "floating" and "dwindle" or default_mode
end

local function mode_of_id(id)
  id = tonumber(id)
  if id == nil or id < 1 then
    return nil
  end
  return modes[id] or default_mode
end

local function mode_of(ws)
  if ws == nil then
    return tiled_default()
  end
  return mode_of_id(ws.id) or tiled_default()
end

local function work_area(mon)
  local scale = mon.scale or 1
  local res = mon.reserved or {}
  local rleft = res.left or 0
  local rtop = res.top or 0
  return {
    x = mon.x + rleft,
    y = mon.y + rtop,
    w = mon.width / scale - rleft - (res.right or 0),
    h = mon.height / scale - rtop - (res.bottom or 0),
  }
end

local function is_offscreen(w)
  local mon = w.monitor or hl.get_monitor_at_cursor()
  if mon == nil then
    return false
  end
  local wa = work_area(mon)
  local cx = w.at.x + w.size.x / 2
  local cy = w.at.y + w.size.y / 2
  return cx < wa.x or cx > wa.x + wa.w or cy < wa.y or cy > wa.y + wa.h
end

-- Rule tags are listed with a trailing "*".
local function has_tag(w, tag)
  for _, t in ipairs(w.tags or {}) do
    if t == tag or t == tag .. "*" then
      return true
    end
  end
  return false
end

local function set_tag(w, tag, on)
  if has_tag(w, tag) ~= on then
    hl.dispatch(hl.dsp.window.tag({ window = w, tag = (on and "+" or "-") .. tag }))
  end
end

-- Windows already floating on their own (dialogs, float rules, Super+Shift+M)
-- are left unclaimed so they stay floating when the mode ends. Everything is
-- claimed before anything is floated: floating one member of a group floats
-- the rest, which a single pass would then skip and strand.
local function float_for_mode(windows)
  local claiming = {}
  local offscreen = {}
  for _, w in ipairs(windows) do
    set_tag(w, FLOATING_WS_TAG, true)
    if (w.fullscreen or 0) == 0 then
      if is_offscreen(w) then
        offscreen[#offscreen + 1] = w
      end
      if not w.floating then
        set_tag(w, FLOATED_TAG, true)
        claiming[#claiming + 1] = w
      end
    end
  end
  for _, w in ipairs(claiming) do
    hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
  end
  -- Windows left outside the screen by scrolling would stay there.
  for _, w in ipairs(offscreen) do
    hl.dispatch(hl.dsp.window.center({ window = w }))
  end
end

-- Pinned windows stay floating (tiling would unpin them); fullscreen ones are
-- handled once they leave fullscreen.
local function tile_for_mode(w)
  set_tag(w, FLOATING_WS_TAG, false)
  if not has_tag(w, FLOATED_TAG) or w.pinned or (w.fullscreen or 0) ~= 0 then
    return
  end
  set_tag(w, FLOATED_TAG, false)
  hl.dispatch(hl.dsp.window.float({ window = w, action = "disable" }))
end

-- Bring windows in line with their workspace's mode. `ws` is passed when a
-- window is still on its way to it. Special workspaces are left alone.
local function arrange(windows, ws)
  local floating = {}
  for _, w in ipairs(windows) do
    local target = ws or w.workspace
    local mode = target and mode_of_id(target.id)
    if mode == "floating" then
      floating[#floating + 1] = w
    elseif mode ~= nil then
      tile_for_mode(w)
    end
  end
  float_for_mode(floating)
end

-- Floating workspaces as id ranges, for the open rules to match.
local function floating_ranges()
  local ranges = {}
  if default_mode == "floating" then
    local tiled = {}
    for id, mode in pairs(modes) do
      if mode ~= "floating" then
        tiled[#tiled + 1] = id
      end
    end
    table.sort(tiled)
    local from = 1
    for _, n in ipairs(tiled) do
      if n > from then
        ranges[#ranges + 1] = { from, n - 1 }
      end
      from = n + 1
    end
    ranges[#ranges + 1] = { from, LAST_WORKSPACE }
  else
    for id, mode in pairs(modes) do
      if mode == "floating" then
        ranges[#ranges + 1] = { id, id }
      end
    end
    table.sort(ranges, function(a, b) return a[1] < b[1] end)
  end
  return ranges
end

-- Windows opening on a floating workspace float from their first frame
-- instead of opening tiled and then shrinking. Modal dialogs and apps with
-- float rules of their own are left to float on their own account.
local open_rules = 0

local function sync_open_rules()
  local ranges = floating_ranges()
  for i, range in ipairs(ranges) do
    hl.window_rule({
      name = OPEN_RULE .. i,
      enabled = true,
      match = {
        workspace = string.format("r[%d-%d]", range[1], range[2]),
        modal = false,
        class = "negative:^(floating-tui)$",
      },
      float = true,
      size = "min(1100,monitor_w*0.64) min(760,monitor_h*0.68)",
      center = true,
      tag = "+" .. OPENED_TAG,
    })
  end
  for i = #ranges + 1, open_rules do
    hl.window_rule({ name = OPEN_RULE .. i, enabled = false })
  end
  open_rules = math.max(open_rules, #ranges)
end

-- Overlapping windows are picked with the pointer, so floating workspaces
-- focus on click and resize from any edge; others keep the defaults.
local input_floating = nil

local function update_input()
  local ws = hl.get_active_workspace()
  local floating = ws ~= nil and mode_of_id(ws.id) == "floating"
  if floating == input_floating then
    return
  end
  input_floating = floating
  hl.config({
    input = { follow_mouse = floating and 0 or 1 },
    general = { resize_on_border = floating },
  })
end

local function notify_layout(title, mode)
  hl.exec_cmd('notify-send -t 1200 -r 69 "' .. title .. '" "' .. (mode_labels[mode] or mode) .. '"')
end

local function set_mode(ws, mode)
  if ws == nil or ws.id < 1 then
    return
  end
  -- Floating keeps whatever tiled layout the workspace had.
  if mode ~= "floating" then
    hl.workspace_rule({ workspace = tostring(ws.id), layout = mode })
  end
  if mode == default_mode then
    modes[ws.id] = nil
  else
    modes[ws.id] = mode
  end
  save_modes()
  sync_open_rules()
  arrange(hl.get_workspace_windows(ws))
  update_input()
  notify_layout("Workspace layout", mode)
end

function CycleWorkspaceLayout(dir)
  local ws = hl.get_active_workspace()
  if ws == nil or ws.id < 1 then
    return
  end
  local cur = mode_of(ws)
  local idx = 1
  for i, m in ipairs(mode_order) do
    if m == cur then
      idx = i
    end
  end
  idx = ((idx - 1 + dir) % #mode_order) + 1
  set_mode(ws, mode_order[idx])
end

-- Change the layout of workspaces without one of their own. Workspaces with
-- windows (including minimized ones) keep the layout they have now.
-- Run via `hypr-layout-default <mode>`.
function SetDefaultLayout(mode)
  if not mode_labels[mode] then
    return
  end
  local busy = {}
  for _, ws in ipairs(hl.get_workspaces()) do
    if ws.id >= 1 and #hl.get_workspace_windows(ws) > 0 then
      busy[ws.id] = true
    end
  end
  for _, w in ipairs(hl.get_windows()) do
    for _, t in ipairs(w.tags or {}) do
      local origin = tonumber(string.match(t, "^minimized%-from%-(%d+)$"))
      if origin then
        busy[origin] = true
      end
    end
  end
  for id in pairs(busy) do
    modes[id] = modes[id] or default_mode
  end
  for id, m in pairs(modes) do
    if not busy[id] or m == mode then
      modes[id] = nil
    end
  end
  default_mode = mode
  save_modes()
  notify_layout("Default workspace layout", mode)
  -- Reload so runtime workspace rules from earlier cycling are dropped.
  hl.exec_cmd("@hyprctl@ reload")
end

load_modes()
save_modes()
hl.config({ general = { layout = tiled_default() } })
for id, mode in pairs(modes) do
  if mode ~= "floating" then
    hl.workspace_rule({ workspace = tostring(id), layout = mode })
  end
end
sync_open_rules()

hl.on("window.open", function(w)
  -- The open rule floated it; claim it so the mode tiles it again later.
  if has_tag(w, OPENED_TAG) then
    set_tag(w, FLOATED_TAG, true)
  end
  arrange({ w })
end)

-- A move is still being committed when this fires, and changing the floating
-- state underneath it loses the move, so let it land first.
hl.on("window.move_to_workspace", function(w, ws)
  hl.timer(function()
    arrange({ w }, ws)
  end, { type = "oneshot", timeout = 1 })
end)

-- Fullscreen windows are skipped, so arrange them once they come back out.
hl.on("window.fullscreen", function(w)
  hl.timer(function()
    arrange({ w })
  end, { type = "oneshot", timeout = 1 })
end)

hl.on("workspace.active", update_input)
hl.on("monitor.focused", update_input)

-- A reload is a fresh start here but not for the windows: bring them all in
-- line with the modes as they stand now.
arrange(hl.get_windows())
update_input()

-----------------------------------------
---- MINIMIZE (Omarchy-style) ----
---- Super+Shift+H minimizes from any workspace mode; window is parked on
---- special:minimized and tagged with its origin workspace.
---- Restore by clicking its icon in the bar (RestoreMinimized)
---- or Super+Alt+M for the most recent one. Floating state on restore is
---- left to arrange(), via the window.move_to_workspace hook.
-----------------------------------------

local function park_window(w)
  local ws = w.workspace
  if ws == nil or ws.id < 0 then
    return
  end
  local active = hl.get_active_window()
  local was_active = active ~= nil and active.address == w.address
  if w.fullscreen ~= 0 then
    -- Remember the fullscreen mode so restore can re-apply it.
    hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+minimized-fs-" .. w.fullscreen }))
    hl.dispatch(hl.dsp.window.fullscreen({
      window = w,
      mode = w.fullscreen == 2 and "fullscreen" or "maximized",
      action =
      "unset"
    }))
  end
  hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+minimized-from-" .. ws.id }))
  hl.dispatch(hl.dsp.window.move({ window = w, workspace = "special:minimized", follow = false }))
  -- Focus would otherwise stay on the hidden window.
  if was_active then
    hl.dispatch(hl.dsp.focus({ workspace = tostring(ws.id) }))
  end
end

local function restore_window(w)
  local origin = nil
  local fs_mode = nil
  for _, t in ipairs(w.tags or {}) do
    origin = string.match(t, "^minimized%-from%-(%d+)$") or origin
    fs_mode = string.match(t, "^minimized%-fs%-(%d)$") or fs_mode
  end
  local target = origin or tostring(hl.get_active_workspace().id)
  hl.dispatch(hl.dsp.window.move({ window = w, workspace = target, follow = true }))
  if origin ~= nil then
    hl.dispatch(hl.dsp.window.tag({ window = w, tag = "-minimized-from-" .. origin }))
  end
  if fs_mode ~= nil then
    hl.dispatch(hl.dsp.window.tag({ window = w, tag = "-minimized-fs-" .. fs_mode }))
    hl.dispatch(hl.dsp.window.fullscreen({
      window = w,
      mode = fs_mode == "2" and "fullscreen" or "maximized",
      action =
      "set"
    }))
  end
  hl.dispatch(hl.dsp.focus({ window = w }))
end

function MinimizeWindow()
  local w = hl.get_active_window()
  local ws = hl.get_active_workspace()
  if w == nil or ws == nil or ws.id < 0 then
    return
  end
  park_window(w)
end

function RestoreLastMinimized()
  local minimized = nil
  for _, ws in ipairs(hl.get_workspaces()) do
    if ws.name == "special:minimized" then
      minimized = ws
    end
  end
  if minimized == nil then
    return
  end
  local wins = hl.get_workspace_windows(minimized)
  if #wins == 0 then
    return
  end
  -- Lower focus_history_id = focused more recently.
  local best = nil
  for _, w in ipairs(wins) do
    if best == nil or (w.focus_history_id or 0) < (best.focus_history_id or 0) then
      best = w
    end
  end
  restore_window(best)
end

-- Called by the bar: hyprctl eval 'RestoreMinimized("0x...")'
function RestoreMinimized(address)
  local w = hl.get_window("address:" .. address)
  if w ~= nil and w.workspace ~= nil and w.workspace.name == "special:minimized" then
    restore_window(w)
  end
end

-- Apps with their own minimize button (CSD) ask the compositor to
-- minimize them. Park them like Super+Shift+H does, but on any workspace;
-- if the app later asks to be unminimized while parked, restore it.
hl.on("window.minimize", function(w, minimized)
  if w == nil or w.workspace == nil then
    return
  end
  if minimized then
    if w.workspace.name ~= "special:minimized" then
      park_window(w)
    end
  elseif w.workspace.name == "special:minimized" then
    restore_window(w)
  end
end)

--------------------------------------
---- EDGE SNAPPING ----
---- Super+Alt+Left/Right snaps the focused floating window to
---- that half of the work area; pressing it again restores the
---- window's previous size and position.
--------------------------------------

local snapped = {}

local function side_rect(w, side)
  local mon = w.monitor or hl.get_monitor_at_cursor()
  if mon == nil then
    return nil
  end
  local wa = work_area(mon)
  local gap = 4
  local half = math.floor(wa.w / 2)
  if side == "left" then
    return { x = wa.x + gap, y = wa.y + gap, w = half - gap - 2, h = wa.h - gap * 2 }
  end
  return { x = wa.x + half + 2, y = wa.y + gap, w = wa.w - half - gap - 2, h = wa.h - gap * 2 }
end

local function apply_rect(w, r)
  hl.dispatch(hl.dsp.window.resize({ window = w, x = r.w, y = r.h }))
  hl.dispatch(hl.dsp.window.move({ window = w, x = r.x, y = r.y }))
end

local function rect_matches(w, r)
  return math.abs(w.at.x - r.x) <= 2 and math.abs(w.at.y - r.y) <= 2 and math.abs(w.size.x - r.w) <= 2 and
      math.abs(w.size.y - r.h) <= 2
end

local function snap_to(w, side, saved)
  local r = side_rect(w, side)
  if r == nil then
    return
  end
  if snapped[w.address] == nil then
    snapped[w.address] = saved or { x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
  end
  apply_rect(w, r)
end

local function unsnap(w)
  local saved = snapped[w.address]
  if saved == nil then
    return
  end
  snapped[w.address] = nil
  apply_rect(w, saved)
end

function SnapWindow(side)
  local w = hl.get_active_window()
  if w == nil or not w.floating or w.fullscreen ~= 0 then
    return
  end
  local r = side_rect(w, side)
  if r == nil then
    return
  end
  if snapped[w.address] ~= nil and rect_matches(w, r) then
    unsnap(w)
  else
    snap_to(w, side, nil)
  end
end

hl.on("window.destroy", function(w)
  if w ~= nil then
    snapped[w.address] = nil
  end
end)

--------------------------------------
---- LAYOUT-AWARE NAVIGATION ----
--------------------------------------

local dir_short = { left = "l", right = "r", up = "u", down = "d" }

local function focus_dir(dir)
  local ws = hl.get_active_workspace()
  if mode_of(ws) == "scrolling" and (dir == "left" or dir == "right") then
    hl.dispatch(hl.dsp.layout("focus " .. dir_short[dir]))
  else
    hl.dispatch(hl.dsp.focus({ direction = dir }))
  end
end

local function move_dir(dir)
  local ws = hl.get_active_workspace()
  if mode_of(ws) == "scrolling" and (dir == "left" or dir == "right") then
    hl.dispatch(hl.dsp.layout("swapcol " .. dir_short[dir]))
  else
    hl.dispatch(hl.dsp.window.move({ direction = dir }))
  end
end

local function resize_width(px)
  local ws = hl.get_active_workspace()
  if mode_of(ws) == "scrolling" then
    if px > 0 then
      hl.dispatch(hl.dsp.layout("colresize +0.1"))
    else
      hl.dispatch(hl.dsp.layout("colresize -0.1"))
    end
  else
    hl.dispatch(hl.dsp.window.resize({ x = px, y = 0, relative = true }))
  end
end

local function preset_width()
  local ws = hl.get_active_workspace()
  if mode_of(ws) == "scrolling" then
    hl.dispatch(hl.dsp.layout("colresize +conf"))
  else
    hl.dispatch(hl.dsp.layout("togglesplit"))
  end
end

local function center_window()
  local ws = hl.get_active_workspace()
  local w = hl.get_active_window()
  if w ~= nil and w.floating then
    hl.dispatch(hl.dsp.window.center({ window = w }))
  elseif mode_of(ws) == "scrolling" then
    hl.dispatch(hl.dsp.layout("center"))
  end
end

local function consume_expel(which)
  local ws = hl.get_active_workspace()
  if mode_of(ws) == "scrolling" then
    hl.dispatch(hl.dsp.layout(which))
  else
    hl.dispatch(hl.dsp.window.cycle_next({ next = which == "expel" }))
  end
end

local function consume_or_expel(which)
  local ws = hl.get_active_workspace()
  if mode_of(ws) == "scrolling" then
    hl.dispatch(hl.dsp.layout("consume_or_expel " .. which))
  else
    hl.dispatch(hl.dsp.layout("togglesplit"))
  end
end

---------------------
---- KEYBINDINGS ----
---- ported from the niri binds in home.nix ----
---------------------

local M = "SUPER"

-- Apps / session
hl.bind(M .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(M .. " + SHIFT + Return", hl.dsp.exec_cmd(browser))
hl.bind(M .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(M .. " + space", hl.dsp.exec_cmd(quickshell .. " ipc call menu toggle"))
hl.bind(M .. " + slash", hl.dsp.exec_cmd(quickshell .. " ipc call control toggle"))
hl.bind(M .. " + Q", hl.dsp.window.close())
hl.bind(M .. " + SHIFT + Q", hl.dsp.exec_cmd(locker))
hl.bind(M .. " + Escape", hl.dsp.exec_cmd(locker))

-- Workspace layout + window state
hl.bind(M .. " + Y", function() CycleWorkspaceLayout(1) end)
hl.bind(M .. " + SHIFT + Y", function() CycleWorkspaceLayout(-1) end)
hl.bind(M .. " + SHIFT + H", function() MinimizeWindow() end)
hl.bind(M .. " + ALT + M", function() RestoreLastMinimized() end)
hl.bind(M .. " + SHIFT + M", hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + ALT + left", function() SnapWindow("left") end)
hl.bind(M .. " + ALT + right", function() SnapWindow("right") end)
hl.bind(M .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(M .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(M .. " + P", hl.dsp.window.pseudo())

-- Focus (vim + arrows)
hl.bind(M .. " + left", function() focus_dir("left") end)
hl.bind(M .. " + right", function() focus_dir("right") end)
hl.bind(M .. " + up", function() focus_dir("up") end)
hl.bind(M .. " + down", function() focus_dir("down") end)
hl.bind(M .. " + H", function() focus_dir("left") end)
hl.bind(M .. " + L", function() focus_dir("right") end)
hl.bind(M .. " + K", function() focus_dir("up") end)
hl.bind(M .. " + J", function() focus_dir("down") end)

-- Move windows
hl.bind(M .. " + CTRL + left", function() move_dir("left") end)
hl.bind(M .. " + CTRL + right", function() move_dir("right") end)
hl.bind(M .. " + CTRL + up", function() move_dir("up") end)
hl.bind(M .. " + CTRL + down", function() move_dir("down") end)
hl.bind(M .. " + CTRL + H", function() move_dir("left") end)
hl.bind(M .. " + CTRL + L", function() move_dir("right") end)
hl.bind(M .. " + CTRL + K", function() move_dir("up") end)
hl.bind(M .. " + CTRL + J", function() move_dir("down") end)

-- Monitors
hl.bind(M .. " + SHIFT + left", hl.dsp.focus({ monitor = "left" }))
hl.bind(M .. " + SHIFT + right", hl.dsp.focus({ monitor = "right" }))
hl.bind(M .. " + SHIFT + up", hl.dsp.focus({ monitor = "up" }))
hl.bind(M .. " + SHIFT + down", hl.dsp.focus({ monitor = "down" }))
hl.bind(M .. " + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "left", follow = true }))
hl.bind(M .. " + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "right", follow = true }))
hl.bind(M .. " + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "up", follow = true }))
hl.bind(M .. " + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "down", follow = true }))

-- Workspaces
for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(M .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(M .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i }))
  hl.bind(M .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(M .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + U", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + O", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + CTRL + Page_Down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(M .. " + CTRL + Page_Up", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(M .. " + CTRL + U", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(M .. " + CTRL + O", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Columns (scrolling) / splits (dwindle)
hl.bind(M .. " + comma", function() consume_expel("consume") end)
hl.bind(M .. " + period", function() consume_expel("expel") end)
hl.bind(M .. " + bracketleft", function() consume_or_expel("prev") end)
hl.bind(M .. " + bracketright", function() consume_or_expel("next") end)
hl.bind(M .. " + backslash", function() preset_width() end)
hl.bind(M .. " + C", function() center_window() end)
hl.bind(M .. " + minus", function() resize_width(-100) end)
hl.bind(M .. " + equal", function() resize_width(100) end)
hl.bind(M .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(M .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Mouse
hl.bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(M .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })
hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("@hyprshot@ -m region -o " .. screenshots))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("@hyprshot@ -m output -o " .. screenshots))
hl.bind("ALT + Print", hl.dsp.exec_cmd("@hyprshot@ -m window -o " .. screenshots))

-- Media / brightness (scripts installed by home.nix)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(home .. "/.local/bin/volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(home .. "/.local/bin/volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(home .. "/.local/bin/volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(home .. "/.local/bin/mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(home .. "/.local/bin/brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(home .. "/.local/bin/brightness-down"),
  { locked = true, repeating = true })

--------------------------
---- WINDOWS RULES ----
--------------------------

-- Overlapping windows need depth to tell apart; tiled ones don't.
hl.window_rule({
  name = "no-shadow",
  match = { class = ".*" },
  no_shadow = true,
})

hl.window_rule({
  name = "floating-ws-shadow",
  match = { tag = FLOATING_WS_TAG },
  no_shadow = false,
})

hl.window_rule({
  name = "floating-tui",
  match = { class = "^(floating-tui)$" },
  float = true,
  size = { 800, 600 },
  center = true,
})

-- Ignore client maximize requests (e.g. kitty asks to start maximized,
-- which Hyprland would otherwise honor as a fullscreen=1 window).
hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  hl.exec_cmd(quickshell)
  hl.exec_cmd("HYPRSHELL_NO_USE_PLUGIN=1 @hyprshell@ run")
  hl.exec_cmd("@awwwDaemon@")
  hl.exec_cmd("@dunst@")
  hl.exec_cmd("@wayvnc@ -g")
  hl.exec_cmd("mkdir -p " .. screenshots)
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("@hyprctl@ setcursor @cursorName@ @cursorSize@")
end)
