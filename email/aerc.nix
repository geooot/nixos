{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Aerc email client
  programs.aerc = {
    enable = true;

    # Minimal extraConfig - let aerc generate most settings
    extraConfig = {
      general = {
        # Use default-save-path from XDG
        default-save-path = "~/Downloads";
        # Required for home-manager managed accounts
        unsafe-accounts-conf = true;
      };

      ui = {
        # Minimal UI settings
        index-columns = "date<20,name<20,subject<*";
        column-separator = " ";
        timestamp-format = "2006-01-02 03:04 PM";
        # Show threading
        threading-enabled = true;
      };

      compose = {
        # Use $EDITOR for composing
        editor = "nvim";
      };

      filters = {
        # Basic filters for viewing emails
        "text/plain" = "cat";
        "text/html" = "${pkgs.w3m}/bin/w3m -dump -T text/html -o display_link_number=1";
      };
    };

    # Comprehensive vim-like keybindings
    extraBinds = {
      # Global bindings (all contexts)
      global = {
        "<C-p>" = ":prev-tab<Enter>";
        "<C-n>" = ":next-tab<Enter>";
        "<C-t>" = ":term<Enter>";
        "?" = ":help keys<Enter>";
      };

      # Message list context
      messages = {
        # Navigation - messages
        "j" = ":next<Enter>";
        "k" = ":prev<Enter>";
        "<Down>" = ":next<Enter>";
        "<Up>" = ":prev<Enter>";
        "g" = ":select 0<Enter>";
        "G" = ":select -1<Enter>";
        "<C-d>" = ":next 50%<Enter>";
        "<C-u>" = ":prev 50%<Enter>";
        "<C-f>" = ":next 100%<Enter>";
        "<C-b>" = ":prev 100%<Enter>";
        "<PgDn>" = ":next 100%<Enter>";
        "<PgUp>" = ":prev 100%<Enter>";

        # Navigation - folders
        "J" = ":next-folder<Enter>";
        "K" = ":prev-folder<Enter>";
        "H" = ":collapse-folder<Enter>";
        "L" = ":expand-folder<Enter>";

        # Selection/marking
        "v" = ":mark -t<Enter>";
        "V" = ":mark -v<Enter>";

        # View message
        "<Enter>" = ":view<Enter>";

        # Actions
        "d" = ":move [Gmail]/Trash<Enter>";
        "D" = ":prompt 'Really delete this message?' 'delete-message'<Enter>";
        "A" = ":archive flat<Enter>";

        # Compose/Reply
        "C" = ":compose<Enter>";
        "rr" = ":reply -a<Enter>";
        "rq" = ":reply -aq<Enter>";
        "Rr" = ":reply<Enter>";
        "Rq" = ":reply -q<Enter>";

        # Threading
        "T" = ":toggle-threads<Enter>";

        # Search/Filter
        "/" = ":search<space>-a<space>";
        "\\" = ":filter<space>";
        "n" = ":next-result<Enter>";
        "N" = ":prev-result<Enter>";
        "<Esc>" = ":clear<Enter>";

        # Utilities
        "c" = ":cf<space>";
        "$" = ":term<space>";
        "!" = ":term<space>";
        "|" = ":pipe<space>";
        "S" = ":exec mbsync -a<Enter>";

        # Quit
        "q" = ":quit<Enter>";
      };

      # Special binding for Drafts folder
      "messages:folder=Drafts" = {
        "<Enter>" = ":recall<Enter>";
      };

      # Message view context
      view = {
        # Navigation within message
        "<C-k>" = ":prev-part<Enter>";
        "<C-j>" = ":next-part<Enter>";

        # Navigate between messages while viewing
        "J" = ":next<Enter>";
        "K" = ":prev<Enter>";

        # Actions
        "q" = ":close<Enter>";
        "d" = ":move [Gmail]/Trash<Enter>";
        "D" = ":prompt 'Really delete this message?' 'delete-message'<Enter>";
        "A" = ":archive flat<Enter>";

        # Reply/Forward
        "f" = ":forward<Enter>";
        "rr" = ":reply -a<Enter>";
        "rq" = ":reply -aq<Enter>";
        "Rr" = ":reply<Enter>";
        "Rq" = ":reply -q<Enter>";

        # Attachments/Files
        "O" = ":open<Enter>";
        "S" = ":save<space>";
        "|" = ":pipe<space>";

        # Display
        "H" = ":toggle-headers<Enter>";
        "<C-l>" = ":open-link<space>";

        # Passthrough mode for searching within pager
        "/" = ":toggle-key-passthrough<Enter>/";
      };

      # Passthrough subcontext (for searching in pager)
      "view::passthrough" = {
        "$noinherit" = "true";
        "$ex" = "<C-x>";
        "<Esc>" = ":toggle-key-passthrough<Enter>";
      };

      # Compose context (not in editor)
      compose = {
        "$noinherit" = "true";
        "$ex" = "<C-x>";
        "<C-k>" = ":prev-field<Enter>";
        "<C-j>" = ":next-field<Enter>";
        "<tab>" = ":next-field<Enter>";
        "<C-p>" = ":prev-tab<Enter>";
        "<C-n>" = ":next-tab<Enter>";
      };

      # Compose context (in embedded editor)
      "compose::editor" = {
        "$noinherit" = "true";
        "$ex" = "<C-x>";
        "<C-k>" = ":prev-field<Enter>";
        "<C-j>" = ":next-field<Enter>";
        "<C-p>" = ":prev-tab<Enter>";
        "<C-n>" = ":next-tab<Enter>";
      };

      # Compose review (before sending)
      "compose::review" = {
        "y" = ":send<Enter>";
        "n" = ":abort<Enter>";
        "p" = ":postpone<Enter>";
        "q" = ":choose -o d discard abort -o p postpone postpone<Enter>";
        "e" = ":edit<Enter>";
        "a" = ":attach<space>";
        "d" = ":detach<space>";
      };

      # Terminal context
      terminal = {
        "$noinherit" = "true";
        "$ex" = "<C-x>";
        "<C-p>" = ":prev-tab<Enter>";
        "<C-n>" = ":next-tab<Enter>";
      };
    };
  };

  # Install aerc and supporting packages
  home.packages = with pkgs; [
    aerc
    w3m # For HTML email viewing
    dante # For rendering HTML in terminal (optional)
  ];
}
