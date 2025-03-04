{ config, pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
    extraConfig = ''
      local wezterm = require 'wezterm'
      
      return {
        -- Wayland configuration
        enable_wayland = true,
        front_end = "OpenGL",  -- Preferred renderer for Wayland
        webgpu_preferred_adapter = wezterm.gui.enumerate_gpus()[1],
        enable_wayland_cursor_colors = true,
        
        -- X11 fallback settings
        x11_skip_xwayland = false,  -- Allow XWayland as fallback
        
        -- Window appearance
        window_background_opacity = 0.95,
        window_padding = {
          left = 10,
          right = 10,
          top = 10,
          bottom = 10,
        },
        initial_cols = 120,
        initial_rows = 30,
        window_decorations = "TITLE | RESIZE",
        hide_tab_bar_if_only_one_tab = true,
        
        -- Color scheme (Tokyo Night theme)
        colors = {
          foreground = "#c0caf5",
          background = "#1a1b26",
          
          ansi = {
            "#15161e", -- black
            "#f7768e", -- red
            "#9ece6a", -- green
            "#e0af68", -- yellow
            "#7aa2f7", -- blue
            "#bb9af7", -- magenta
            "#7dcfff", -- cyan
            "#a9b1d6", -- white
          },
          
          brights = {
            "#414868", -- bright black
            "#f7768e", -- bright red
            "#9ece6a", -- bright green
            "#e0af68", -- bright yellow
            "#7aa2f7", -- bright blue
            "#bb9af7", -- bright magenta
            "#7dcfff", -- bright cyan
            "#c0caf5", -- bright white
          },
        },
        
        -- Font configuration
        font = wezterm.font_with_fallback({
          "JetBrains Mono",
          "Noto Color Emoji",
        }),
        font_size = 11.0,
        
        -- Enable modern features
        term = "wezterm",
        enable_scroll_bar = false,
        native_macos_fullscreen_mode = false,
        warn_about_missing_glyphs = false,
        
        -- Better default shell integration
        default_prog = { "${pkgs.bashInteractive}/bin/bash" },
        
        -- Additional features
        automatically_reload_config = true,
        scrollback_lines = 10000,
        enable_tab_bar = true,
        use_fancy_tab_bar = false,
      }
    '';
  };
}
