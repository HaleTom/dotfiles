-- Official doco: https://wezfurlong.org/wezterm/config/files.html

local wezterm = require 'wezterm'  -- Pull in the wezterm API
local act = wezterm.action  -- for binding keys to actions
local gpus = wezterm.gui.enumerate_gpus()
local mux = wezterm.mux  -- multiplexer layer: panes, tabs, windows, and workspaces

-- local scheme = wezterm.get_builtin_color_schemes()["nord"]
-- local keybinds = require 'keybinds'
-- local utils = require("utils")
-- require("on")


-- Debug
wezterm.log_level = "debug"
-- After restarting WezTerm:
  -- $HOME/.local/share/wezterm/logs/ (on Linux/macOS)
  -- %APPDATA%\wezterm\logs\ (on Windows)

--- Config struct documentation
-- https://wezfurlong.org/wezterm/config/lua/config/index.html
local config = {}  -- This table will hold the configuration.
-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

--
-- Key assignments
--

-- Defaults: https://wezfurlong.org/wezterm/config/default-keys.html

--
-- Hyperlinks
--

-- https://wezfurlong.org/wezterm/hyperlinks.html

-- Terminal hyperlinks
-- https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
-- printf '\e]8;;http://example.com\e\\This is a link\e]8;;\e\\\n'

-- Use the defaults as a base.  https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
  regex = [[\s{1}["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?\s{1}]],
  format = 'https://www.github.com/$1/$3',
  -- highlight = 0,  -- highlight this regex match group, use 0 for all
})

--
-- Miscellaneous
--

config.enable_scroll_bar=true
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 140
config.initial_rows = 40
config.exit_behavior = "CloseOnCleanExit"  -- Use 'Hold' to not close

--
-- Fonts
--

-- config.font = wezterm.font 'JetBrains Mono'
-- config.font = wezterm.font 'Iosevka Term SS06'
config.font = wezterm.font 'Iosevka SS06'
config.font_size = 13.8
config.warn_about_missing_glyphs = true

  -- freetype_load_target = "HorizontalLcd",
  -- freetype_load_flags = "FORCE_AUTOHINT",


return config
