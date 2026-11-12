-- Hyprland 0.57 Lua config. Installed to ~/.config/hypr/hyprland.lua by
-- hyprland/home.nix, which substitutes the placeholder tokens below
-- (store paths, stylix colors, cursor) via replaceVars.
-- Keybinds are ported from the niri binds in home-manager/home.nix.

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "DP-3", mode = "2560x1440", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-1", mode = "2560x1440", position = "2560x0", scale = 1 })
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
        shadow = { enabled = false },
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
hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "quick", style = "popin 95%" })

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

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

--------------------------------------------
---- WORKSPACE LAYOUTS (Omarchy-style) ----
---- per-workspace: dwindle / scrolling / floating, persisted ----
--------------------------------------------

local state_dir = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/hypr"
os.execute('mkdir -p "' .. state_dir .. '"')
local layouts_file = state_dir .. "/layouts.json"

local modes = {}

local function save_modes()
    local parts = {}
    for id, mode in pairs(modes) do
        parts[#parts + 1] = '"' .. id .. '":"' .. mode .. '"'
    end
    table.sort(parts)
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
    for id, mode in string.gmatch(content, '"(%d+)":"(%a+)"') do
        modes[tonumber(id)] = mode
        if mode == "scrolling" then
            hl.workspace_rule({ workspace = id, layout = "scrolling" })
        end
    end
end
load_modes()

local function mode_of(ws)
    if ws == nil then
        return "dwindle"
    end
    return modes[ws.id] or "dwindle"
end

local mode_labels = { dwindle = "Tiling", scrolling = "Scrolling", floating = "Floating" }
local mode_order = { "dwindle", "scrolling", "floating" }

local function set_mode(ws, mode)
    if ws == nil or ws.id < 0 then
        return
    end
    local cur = mode_of(ws)
    if cur == "floating" and mode ~= "floating" then
        for _, w in ipairs(hl.get_workspace_windows(ws)) do
            for _, t in ipairs(w.tags or {}) do
                if t == "mode-floated" then
                    hl.dispatch(hl.dsp.window.float({ window = w, action = "disable" }))
                    hl.dispatch(hl.dsp.window.tag({ window = w, tag = "-mode-floated" }))
                end
            end
        end
    end
    if mode == "floating" then
        for _, w in ipairs(hl.get_workspace_windows(ws)) do
            if not w.floating and w.fullscreen == 0 then
                hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
                hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+mode-floated" }))
            end
        end
    else
        hl.workspace_rule({ workspace = tostring(ws.id), layout = mode })
    end
    modes[ws.id] = mode
    save_modes()
    hl.exec_cmd('notify-send -t 1200 -r 69 "Workspace layout" "' .. (mode_labels[mode] or mode) .. '"')
end

function CycleWorkspaceLayout(dir)
    local ws = hl.get_active_workspace()
    if ws == nil or ws.id < 0 then
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

-- New windows opened on a floating workspace float too.
hl.on("window.open", function(w)
    local ws = w.workspace
    if ws ~= nil and ws.id > 0 and modes[ws.id] == "floating" and not w.floating and w.fullscreen == 0 then
        hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
        hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+mode-floated" }))
    end
end)

-----------------------------------------
---- MINIMIZE (Omarchy-style) ----
---- Super+Shift+H minimizes from any workspace mode; window is parked on
---- special:minimized and tagged with its origin workspace.
---- Restore by clicking its icon in the bar (hypr-restore)
---- or Super+Alt+M for the most recent one.
-----------------------------------------

local function park_window(w)
    local ws = w.workspace
    if ws == nil or ws.id < 0 then
        return
    end
    hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+minimized-from-" .. ws.id }))
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = "special:minimized", follow = false }))
end

local function restore_window(w)
    local origin = nil
    for _, t in ipairs(w.tags or {}) do
        origin = string.match(t, "^minimized%-from%-(%d+)$") or origin
    end
    local target = origin or tostring(hl.get_active_workspace().id)
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = target, follow = true }))
    if origin ~= nil then
        hl.dispatch(hl.dsp.window.tag({ window = w, tag = "-minimized-from-" .. origin }))
    end
    if modes[tonumber(target)] == "floating" then
        hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
    else
        hl.dispatch(hl.dsp.window.float({ window = w, action = "disable" }))
    end
    hl.dispatch(hl.dsp.focus({ window = w }))
end

function MinimizeWindow()
    local w = hl.get_active_window()
    local ws = hl.get_active_workspace()
    if w == nil or ws == nil or ws.id < 0 then
        return
    end
    if w.fullscreen ~= 0 then
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
    local best = nil
    for _, w in ipairs(wins) do
        if best == nil or (w.focus_history_id or 0) > (best.focus_history_id or 0) then
            best = w
        end
    end
    restore_window(best)
end

-- Apps with their own minimize button (CSD) ask the compositor to
-- minimize them. Park them like Super+Shift+H does, but on any workspace;
-- if the app later asks to be unminimized while parked, restore it.
hl.on("window.minimize", function(w, minimized)
    if w == nil or w.workspace == nil then
        return
    end
    if minimized then
        if w.workspace.name ~= "special:minimized" and w.fullscreen == 0 then
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
    return math.abs(w.at.x - r.x) <= 2 and math.abs(w.at.y - r.y) <= 2 and math.abs(w.size.x - r.w) <= 2 and math.abs(w.size.y - r.h) <= 2
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
hl.bind(M .. " + B", hl.dsp.exec_cmd(browser))
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
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(home .. "/.local/bin/brightness-down"), { locked = true, repeating = true })

--------------------------
---- WINDOWS RULES ----
--------------------------

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
    hl.exec_cmd("@awwwDaemon@")
    hl.exec_cmd("@dunst@")
    hl.exec_cmd("@wayvnc@ -g")
    hl.exec_cmd("mkdir -p " .. screenshots)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("@hyprctl@ setcursor @cursorName@ @cursorSize@")
end)
