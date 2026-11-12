# Fresh Hyprland setup (does not reuse the old wayland.windowManager.hyprland
# block that used to live in home.nix):
#   - Hyprland 0.57 only reads ~/.config/hypr/hyprland.lua; the config lives
#     in ./hyprland.lua next to this file, with store paths and stylix colors
#     substituted in via replaceVars placeholder tokens
#   - Quickshell provides the bar and the menu (./quickshell/*.qml)
#   - Keybinds are ported from the niri config in home.nix, adjusted:
#       Super+H/J/K/L focus, Super+Y cycles workspace layout
#       (dwindle -> scrolling -> floating, Omarchy-style), Super+M minimizes
#       a window on a floating workspace to special:minimized (Omarchy-style)
{
  config,
  pkgs,
  ...
}:
let
  accent = config.lib.stylix.colors.base0D;
  inactive = config.lib.stylix.colors.base03;

in
{
  home.packages = with pkgs; [
    quickshell
    libqalculate # qalc, used by the menu calculator
    jq # used by hypr-restore
    hyprshot
    wl-clipboard # wl-copy, used to copy calculator results
  ];

  home.file.".local/bin/hypr-restore" = {
    source = ./hypr-restore.sh;
    executable = true;
  };

  xdg.configFile."hypr/hyprland.lua".source = pkgs.replaceVars ./hyprland.lua {
    kitty = "${pkgs.kitty}/bin/kitty";
    firefox = "${pkgs.firefox}/bin/firefox";
    yazi = "${pkgs.yazi}/bin/yazi";
    hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
    quickshell = "${pkgs.quickshell}/bin/qs";
    hyprshot = "${pkgs.hyprshot}/bin/hyprshot";
    awwwDaemon = "${pkgs.awww}/bin/awww-daemon";
    dunst = "${pkgs.dunst}/bin/dunst";
    wayvnc = "${pkgs.wayvnc}/bin/wayvnc";
    hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    inherit accent inactive;
    cursorName = config.home.pointerCursor.name;
    cursorSize = toString config.home.pointerCursor.size;
  };

  # Quickshell theme; accent comes from stylix (waybar used @base0D the same way).
  xdg.configFile."quickshell/Theme.qml".text = ''
    import QtQuick

    QtObject {
        readonly property color bg: "#000000"
        readonly property color fg: "#ffffff"
        readonly property color dim: "#888888"
        readonly property color border: "#323232"
        readonly property color accent: "#${accent}"
        readonly property color panelBg: "#0a0a0a"
        readonly property color hoverBg: "#1a1a1a"
        readonly property string fontFamily: "Berkeley Mono Variable"
        readonly property int fontSize: 14
        readonly property int smallSize: 11
    }
  '';

  xdg.configFile."quickshell/shell.qml".source = ./quickshell/shell.qml;
  xdg.configFile."quickshell/Bar.qml".source = ./quickshell/Bar.qml;
  xdg.configFile."quickshell/Menu.qml".source = ./quickshell/Menu.qml;
  xdg.configFile."quickshell/WifiPanel.qml".source = ./quickshell/WifiPanel.qml;
  xdg.configFile."quickshell/SoundPanel.qml".source = ./quickshell/SoundPanel.qml;
  xdg.configFile."quickshell/PowerPanel.qml".source = ./quickshell/PowerPanel.qml;
  xdg.configFile."quickshell/BluetoothPanel.qml".source = ./quickshell/BluetoothPanel.qml;
  xdg.configFile."quickshell/KeysPanel.qml".source = ./quickshell/KeysPanel.qml;
  xdg.configFile."quickshell/VolumeSlider.qml".source = ./quickshell/VolumeSlider.qml;

  # Icon theme for Quickshell's icon lookups (bar, launcher, tray).
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };
}
