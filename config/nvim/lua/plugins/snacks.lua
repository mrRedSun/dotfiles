return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}

    -- Explorer defaults
    opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
      hidden = true, -- show dotfiles by default
      ignored = true, -- show .gitignored files by default
    })

    -- Optional: make files/grep pickers also include hidden/ignored by default
    opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
      hidden = true,
      ignored = false,
    })

    opts.picker.sources.grep = vim.tbl_deep_extend("force", opts.picker.sources.grep or {}, {
      hidden = true,
      ignored = false,
    })
  end,
}
