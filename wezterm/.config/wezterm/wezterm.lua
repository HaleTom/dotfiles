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

-- Regex syntax:  https://docs.rs/regex/latest/regex/#syntax and https://docs.rs/fancy-regex/latest/fancy_regex/#syntax
-- Lua's [[ ]] literal strings prevent character [[:classes:]] :(
-- To avoid "]]] at end, use "[a-z].{0}]]"
-- https://www.lua.org/pil/2.4.html#:~:text=bracketed%20form%20may%20run%20for%20several%20lines%2C%20may%20nest

table.insert(config.hyperlink_rules, {
  -- https://github.com/shinnn/github-username-regex  https://stackoverflow.com/a/64147124/5353461
  regex = [[(^|(?<=[\[(\s'"]))([0-9A-Za-z][-0-9A-Za-z]{0,38})/([A-Za-z0-9_.-]{1,100})((?=[])\s'".!?])|$)]],
  --  is/good  0valid0/-_.reponname  /bad/start  -bad/username  bad/end!  too/many/parts -bad/username
  --  [wraped/name] (aa/bb) 'aa/bb' "aa/bb"  end/punct!  end/punct.
  format = 'https://www.github.com/$2/$3/',
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
-- https://wezfurlong.org/wezterm/config/lua/wezterm/font.html
-- https://wezfurlong.org/wezterm/config/lua/config/font_rules.html
-- wezterm ls-fonts
-- wezterm ls-fonts --list-system
--
-- config.font = wezterm.font 'JetBrains Mono'
-- config.font = wezterm.font 'Iosevka Term SS06'
-- config.font = wezterm.font({ family = 'Iosevka Term SS06', stretch = 'UltraCondensed'})
-- config.font = wezterm.font({ family = 'Iosevka SS06', stretch = 'UltraCondensed'})
config.font_size = 13.8
config.warn_about_missing_glyphs = true
config.freetype_load_target = 'HorizontalLcd' -- https://wezfurlong.org/wezterm/config/lua/config/freetype_load_target.html

-- Monaspace:  https://monaspace.githubnext.com/
-- Based upon, contributed to:  https://gist.github.com/ErebusBat/9744f25f3735c1e0491f6ef7f3a9ddc3
config.font = wezterm.font(
  { -- Normal text
  family='Monaspace Neon',
  harfbuzz_features={ 'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08' },
  stretch='UltraCondensed', -- This doesn't seem to do anything
})

config.font_rules = {
  { -- Italic
    intensity = 'Normal',
    italic = true,
    font = wezterm.font({
      -- family="Monaspace Radon",  -- script style
      family='Monaspace Xenon', -- courier-like
      style = 'Italic',
    })
  },

  { -- Bold
    intensity = 'Bold',
    italic = false,
    font = wezterm.font( {
      family='Monaspace Krypton',
      family='Monaspace Krypton',
      -- weight='ExtraBold',
      weight='Bold',
      })
  },

  { -- Bold Italic
    intensity = 'Bold',
    italic = true,
    font = wezterm.font( {
      family='Monaspace Xenon',
      style='Italic',
      weight='Bold',
      }
    )
  },
}


-- From: https://stackoverflow.com/a/7470789/5353461
function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            merge_tables(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end
-- config = merge_tables(config, font_config)

return config
