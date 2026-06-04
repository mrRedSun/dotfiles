return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,

    dependencies = {
      "nvim-lua/plenary.nvim",
      "rcarriga/nvim-notify",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
    },

    config = function()
      -- Setup flutter-tools
      require("flutter-tools").setup({
        decorations = {
          statusline = {
            -- this will show the current version of the flutter app from the pubspec.yaml file
            app_version = true,
            device = true,
          },
        },

        debugger = {
          enabled = true,
          evaluate_to_string_in_debug_views = true,
        },

        root_patterns = { ".git", "pubspec.yaml" }, -- patterns to find the root of your flutter project
        fvm = true,
        widget_guides = {
          enabled = true,
        },

        dev_log = {
          enabled = false,
          filter = nil, -- optional callback to filter the log
          -- takes a log_line as string argument; returns a boolean or nil;
          -- the log_line is only added to the output if the function returns true
          notify_errors = false, -- if there is an error whilst running then notify the user
          open_cmd = "15split", -- command to use to open the log buffer
          focus_on_open = true, -- focus on the newly opened log window
        },

        dev_tools = {
          autostart = true, -- autostart devtools server if not detected
          auto_open_browser = false, -- Automatically opens devtools in the browser
        },

        lsp = {
          settings = {
            showTodos = false,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            updateImportsOnRename = true,
          },
        },
      })

      -- Keymaps: only for Flutter projects, avoid LazyVim conflicts
      -- We use the <leader>F prefix (uppercase F) which LazyVim does not
      -- assign by default, and make maps buffer-local when editing Dart files
      -- inside a Flutter project (detected via pubspec.yaml).

      -- Helper to detect if current buffer belongs to a Flutter project
      local function is_flutter_project(bufnr)
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name == nil or name == "" then
          return false
        end
        local start = vim.fs.dirname(name)
        if not start or start == "" then
          return false
        end
        -- use vim.uv (vim.loop is deprecated) and proper vim.fs.find args
        local homedir = (vim.uv and vim.uv.os_homedir()) or vim.fn.expand("~")
        local found = vim.fs.find({ "pubspec.yaml" }, { path = start, upward = true, stop = homedir })[1]
        if not found then
          return false
        end
        local ok, lines = pcall(vim.fn.readfile, found)
        if not ok then
          return false
        end
        for _, line in ipairs(lines) do
          -- typical indicators of a Flutter app/package
          if line:match("^%s*flutter%s*:") or line:match("sdk%s*:%s*flutter") then
            return true
          end
        end
        return false
      end

      -- Register a WhichKey group when available (purely cosmetic)
      do
        local ok, wk = pcall(require, "which-key")
        if ok and wk.add then
          wk.add({ { "<leader>F", group = "Flutter" } })
        end
      end

      -- Create buffer-local keymaps on Dart buffers within Flutter projects
      local aug = vim.api.nvim_create_augroup("FlutterToolsKeymaps", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = aug,
        pattern = "dart",
        callback = function(args)
          local bufnr = args.buf
          -- avoid duplicate mappings
          if vim.b[bufnr].flutter_keys_set then
            return
          end
          if not is_flutter_project(bufnr) then
            return
          end

          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = "Flutter: " .. desc })
          end

          -- Core commands
          map("<leader>Fr", "<cmd>FlutterRun<cr>", "Run app")
          map("<leader>FR", "<cmd>FlutterRestart<cr>", "Restart app")
          map("<leader>Fq", "<cmd>FlutterQuit<cr>", "Quit app")

          -- Tooling and devices
          map("<leader>Fd", "<cmd>FlutterDevices<cr>", "List devices")
          map("<leader>Fe", "<cmd>FlutterEmulators<cr>", "List emulators")
          map("<leader>FD", "<cmd>FlutterDevTools<cr>", "Open DevTools")
          map("<leader>Fl", "<cmd>FlutterLog<cr>", "Open dev log")

          vim.b[bufnr].flutter_keys_set = true
        end,
      })
    end,
  },
}
