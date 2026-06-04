return {
  {
    "folke/flash.nvim",
    -- tweak behavior but keep defaults
    opts = function(_, opts)
      opts = opts or {}
      opts.modes = opts.modes or {}
      opts.modes.treesitter = vim.tbl_deep_extend("force", opts.modes.treesitter or {}, {
        -- feel more "motion-like": jump to start and auto-jump when single target
        jump = { pos = "start", autojump = true },
        -- quieter visuals (optional)
        highlight = { backdrop = false, matches = false },
      })
      return opts
    end,

    -- ADD keys without nuking LazyVim's defaults
    keys = function(_, keys)
      local extra = {
        -- Make Shift+R run Treesitter Search in *all* modes (n/x/o)
        -- which-key tooltip comes from `desc`
        {
          "R",
          mode = { "n", "x", "o" },
          function()
            require("flash").treesitter_search()
          end,
          desc = "Flash Treesitter Search",
        },
      }
      return vim.list_extend(keys, extra)
    end,
  },
}
