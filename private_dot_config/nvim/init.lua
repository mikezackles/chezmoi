-- ensure that the lazy.nvim package manager is installed and visible
local lazy_dir = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazy_dir) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazy_dir,
  })
end
vim.opt.rtp:prepend(lazy_dir)

vim.g.mapleader = " "  -- should be set before requiring lazy
vim.g.bones_compat = 1 -- silliness to tell zenbones colorscheme we're not installing color picker plugin

require("lazy").setup({
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      require('which-key').setup({
        preset = 'helix',
      })
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
    },
    dependencies = "rcarriga/nvim-notify",
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && ' ..
        'cmake --build build --config Release && ' ..
        'cmake --install build --prefix build',
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = '0.1.x',
    dependencies = {
      "nvim-lua/plenary.nvim",
      "telescope-fzf-native.nvim",
      "nvim-telescope/telescope-dap.nvim",
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<Tab>"] = require('telescope.actions').move_selection_previous,
              ["<S-Tab>"] = require('telescope.actions').move_selection_next,
            },
            n = {
              ["<Tab>"] = require('telescope.actions').move_selection_previous,
              ["<S-Tab>"] = require('telescope.actions').move_selection_next,
              ["<Space>"] = require('telescope.actions').toggle_selection,
            },
          }
        },
        pickers = {
          find_files = {
            find_command = { "fd", "--type", "f", "--exclude", ".git" },
          },
        }
      })
      telescope.load_extension('fzf')
      telescope.load_extension('dap')

      function async_picker(prompt, src, callback)
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        pickers.new({}, {
          prompt_title = prompt,
          finder = finders.new_table({
            results = src,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()[1]
              callback(selection)
            end)
            return true
          end,
        }):find()
      end

      function sync_picker(prompt, src)
        local coro = coroutine.running()
        async_picker(prompt, src, function(selection)
          coroutine.resume(coro, selection)
        end)
        return coroutine.yield()
      end
    end,
  },
  { "nvim-tree/nvim-web-devicons" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "astro", "c", "cmake", "cpp", "css", "csv", "cuda", "dockerfile",
          "fish", "git_config", "gitattributes", "gitcommit", "gitignore",
          "glsl", "go", "html", "javascript", "json", "llvm", "lua", "luau",
          "make", "markdown", "meson", "mlir", "ninja", "nix", "perl",
          "python", "qmldir", "qmljs", "rust", "sql", "tablegen", "toml",
          "typescript", "vim", "vimdoc", "xml", "yaml", "zig",
        },
        sync_install = false,
        auto_install = false,
        ignore_install = {},
        highlight = { enable = true },
        --indent = { enable = true, disable = {"cpp"} },
        indent = { enable = true },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      --"neoconf.nvim",
      --"folke/neodev.nvim", -- lua language server config for editing neovim configs
      "mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
  },
  ----{ -- per-project LSP config
  ----  "folke/neoconf.nvim", cmd = "Neoconf", config = true,
  ----  keys = { { "<leader>n", "<cmd>Neoconf<cr>", desc = "Neoconf: per-project LSP config" } },
  ----},
  {
    "williamboman/mason.nvim",
    keys = { { "<leader>pm", "<cmd>Mason<cr>", desc = "Mason LSP package manager" } },
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = { "lua_ls" },
    },
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "LuaSnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      cmp.setup({
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- lsp completions
          { name = 'luasnip' },
          { name = 'nvim_lsp_signature_help' },
        }),
        mapping = cmp.mapping.preset.insert({
          ['<tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<s-tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<c-p>'] = cmp.mapping.scroll_docs(-4),
          ['<c-n>'] = cmp.mapping.scroll_docs(4),
          ['<c-c>'] = cmp.mapping.abort(),
          -- Set `select` to `false` to only confirm explicitly selected items.
          ['<cr>'] = cmp.mapping.confirm({ select = true }),
          -- Trigger completion menu
          --['<c-space>'] = cmp.mapping.complete(),
        }),
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        sorting = {
          comparators = {
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.recently_used,
            require("clangd_extensions.cmp_scores"),
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          }
        },
      })
      -- complete searches using buffer contents
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = 'buffer' } },
      })
      -- command completion
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources(
          { { name = 'path' } },
          { { name = 'cmdline' } }
        ),
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp"
  },
  { "p00f/clangd_extensions.nvim" },
  -- indentation guides
  --{ "lukas-reineke/indent-blankline.nvim", main = "ibl",
  --  config = function()
  --    require("ibl").setup({
  --      scope = {
  --        show_start = false,
  --        show_end = false,
  --      },
  --    })
  --  end,
  --},
  -- colorschemes
  { "ellisonleao/gruvbox.nvim",   priority = 1000, config = true },
  { "rose-pine/neovim",           priority = 1000 },
  { "olimorris/onedarkpro.nvim",  priority = 1000 },
  { "neanias/everforest-nvim",    priority = 1000 },
  { "rebelot/kanagawa.nvim",      priority = 1000 },
  { "tanvirtin/monokai.nvim",     priority = 1000 },
  {
    "stevearc/qf_helper.nvim",
    config = function()
      require("qf_helper").setup({
        quickfix = {
          default_bindings = false,
        },
      })
    end,
  },
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    opts = {
      -- replace netrw
      open_for_directories = true,
      keymaps = {},
    },
    keys = {
      { "<leader>yy", "<cmd>Yazi<cr>",        desc = "Open yazi at current file" },
      { "<leader>yw", "<cmd>Yazi cwd<cr>",    desc = "Open yazi in nvim cwd" },
      { "<leader>yt", "<cmd>Yazi toggle<cr>", desc = "Resume the last yazi session" },
    },
    init = function()
      -- Needed because we are replacing netrw
      -- See https://github.com/mikavilpas/yazi.nvim/issues/802
      vim.g.loaded_netrwPlugin = 1
    end
  },
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    keys = {
      { "<leader>md", "<cmd>lua vim.notify.dismiss()<cr>", desc = "Dismiss notifications" },
    },
    config = function()
      vim.notify = require('notify')
      vim.notify.setup({
        timeout = 200,
        background_colour = "#000000",
      })
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mason.nvim",
      "telescope.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim", -- simplified DAP server installation
      "stevearc/overseer.nvim",       -- task runner that supports .vscode/tasks.json
    },
    keys = {
      { "<leader>bb", "<cmd>DapToggleBreakpoint<cr>",                                    desc = "Toggle Breakpoint" },
      { "<leader>bd", "<cmd>DapClearBreakpoints<cr>",                                    desc = "Clear Breakpoints" },
      { "<leader>bc", "<cmd>DapContinue<cr>",                                            desc = "Continue" },
      { "<leader>br", "<cmd>lua require('dap').repl.toggle({ height = 10 })<cr>",        desc = "Toggle REPL" },
      --{ "<leader>bn", "<cmd>DapStepOver<cr>", desc = "Step Over" },
      --{ "<leader>bs", "<cmd>DapStepInto<cr>", desc = "Step Into" },
      --{ "<leader>bo", "<cmd>DapStepOut<cr>", desc = "Step Out" },
      { "<leader>bv", "<cmd>DapVirtualTextToggle<cr>",                                   desc = "Toggle Virtual Text" },
      --{ "<leader>bp", "<cmd>DapPause<cr>", desc = "Pause" },
      -- Hover is kinda painful to use due to the API
      --{ "<leader>bh", "<cmd>lua dap_hover = require('dap').hover()<cr>", desc = "Hover" },
      { "<leader>bp", "<cmd>lua if dap_scopes then dap_scopes.toggle() end<cr>",         desc = "Toggle Scopes" },
      { "<leader>bf", "<cmd>lua if dap_frames then dap_frames.toggle() end<cr>",         desc = "Toggle Frames" },
      { "<leader>be", "<cmd>lua if dap_expression then dap_expression.toggle() end<cr>", desc = "Toggle Expression" },
      { "<leader>bt", "<cmd>lua if dap_threads then dap_threads.toggle() end<cr>",       desc = "Toggle Threads" },
    },
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = { "cppdbg", "codelldb" },
      })
      require("overseer").setup()
      local dap = require("dap")
      dap.adapters.cppdbg = {
        id = 'cppdbg',
        type = 'executable',
        command = vim.fn.stdpath("data") .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
        options = { detached = false }
      }
      dap.adapters.codelldb = {
        type = 'executable',
        command = 'codelldb',
        -- uncomment on windows
        -- detached = false,
      }
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
      }
      dap.adapters.lldb = {
        type = "executable",
        command = "lldb-dap",
      }
      local function exe_picker()
        local home = vim.loop.os_homedir()
        local cmd = "fd --type executable --max-depth 6 --no-ignore --full-path '/build.*'"
        return sync_picker("Choose an executable", vim.fn.systemlist(cmd))
      end
      local function args_picker()
        return vim.fn.input('Extra args: ')
      end
      local function pid_picker()
        local cmd = "ps -u \"$USER\" -o ppid=,pid=,args= | awk '$1 == 1 { $1=\"\"; print substr($0,2) }'"
        local selection = sync_picker("Choose a process", vim.fn.systemlist(cmd))
        return selection:match("^(%d+)")
      end
      dap.configurations.cpp = {
        -- Put the same data into inside launch.json under "configurations" for
        -- each executable that can be debugged to get shortcuts
        {
          name = "cppdbg",
          type = "cppdbg",
          request = "launch",
          program = exe_picker,
          args = args_picker,
          cwd = '${workspaceFolder}',
          preLaunchTask = "Compile",
          stopAtEntry = false,
          setupCommands = {
            {
              text = '-enable-pretty-printing',
              description = 'enable pretty printing',
              ignoreFailures = false,
            },
          },
        },
        {
          name = "codelldb",
          type = "codelldb",
          request = "launch",
          program = exe_picker,
          args = function() vim.split(args_picker(), "%s+") end,
          cwd = '${workspaceFolder}',
          preLaunchTask = "Compile",
          stopOnEntry = false,
        },
        --{
        --  name = 'Attach to gdbserver :1234',
        --  type = 'cppdbg',
        --  request = 'launch',
        --  MIMode = 'gdb',
        --  miDebuggerServerAddress = 'localhost:1234',
        --  miDebuggerPath = '/usr/bin/gdb',
        --  cwd = '${workspaceFolder}',
        --  program = function()
        --    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        --  end,
        --  setupCommands = {
        --    {
        --      text = '-enable-pretty-printing',
        --      description =  'enable pretty printing',
        --      ignoreFailures = false,
        --    },
        --  },
        --},
        {
          name = "gdb",
          type = "gdb",
          request = "launch",
          program = exe_picker,
          args = args_picker,
          cwd = "${workspaceFolder}",
          preLaunchTask = "Compile",
          stopAtBeginningOfMainSubprogram = false,
        },
        {
          name = "gdb attach to process",
          type = "gdb",
          request = "attach",
          program = exe_picker,
          pid = pid_picker,
          cwd = '${workspaceFolder}'
        },
        --{
        --  name = 'gdb attach to server',
        --  type = 'gdb',
        --  request = 'attach',
        --  target = 'localhost:1234',
        --  program = function()
        --     return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        --  end,
        --  cwd = '${workspaceFolder}'
        --},
        {
          name = "lldb",
          type = "lldb",
          request = "launch",
          program = exe_picker,
          args = args_picker,
          cwd = '${workspaceFolder}',
          preLaunchTask = "Compile",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp
      --dap.configurations.rust = dap.configurations.cpp
      dap.defaults.fallback.terminal_win_cmd = function()
        return vim.api.nvim_create_buf(false, true)
      end
      local vtext = require('nvim-dap-virtual-text')
      vtext.setup({ virt_text_pos = 'eol' })
      dap.listeners.after.event_initialized['widget_setup'] = function()
        local widgets = require('dap.ui.widgets')
        dap_hover = nil
        dap_scopes = widgets.sidebar(widgets.scopes, { height = 10 }, 'belowright split')
        dap_scopes.open()
        dap_frames = widgets.centered_float(widgets.frames)
        dap_frames.close()
        dap_expression = widgets.centered_float(widgets.expression)
        dap_expression.close()
        dap_threads = widgets.centered_float(widgets.threads)
        dap_threads.close()
      end

      local function close_widgets()
        dap.repl.close()
        if dap_scopes then dap_scopes.close() end
        if dap_frames then dap_frames.close() end
        if dap_expression then dap_expression.close() end
        if dap_threads then dap_threads.close() end
        if dap_hover then dap_hover.close() end
        vtext.disable()
      end

      dap.listeners.before.event_terminated['widget_setup'] = close_widgets
      dap.listeners.before.event_exited['widget_setup'] = close_widgets

      local saved_map = {}
      local debug_map = {
        b = dap.toggle_breakpoint,
        n = dap.step_over,
        s = dap.step_into,
        u = dap.up,
        d = dap.down,
        c = dap.continue,
        p = dap.pause,
        f = dap.step_out,
        x = dap.run_to_cursor,
        o = function()
          if dap_hover then
            dap_hover.close()
          else
            dap_hover = dap.hover()
          end
        end,
      }
      local function restore_mappings()
        for key, mapping in pairs(saved_map) do
          if #mapping == 0 then
            -- if it's empty, there was no mapping before, so we need to delete
            -- the mapping
            vim.keymap.del('n', key)
          else
            vim.fn.mapset(mapping)
          end
        end
        saved_map = {}
      end
      debug_map['q'] = function()
        dap.disconnect(nil, function()
          close_widgets()
          restore_mappings()
        end)
      end
      dap.listeners.after.event_initialized['keys'] = function()
        local dap = require('dap')
        saved_map = {}
        for key, _ in pairs(debug_map) do
          saved_map[key] = vim.fn.maparg(key, 'n', false, true)
        end
        for key, fun in pairs(debug_map) do
          vim.keymap.set("n", key, fun)
        end
      end
      dap.listeners.before.event_terminated['keys'] = restore_mappings
      dap.listeners.before.event_exited['keys'] = restore_mappings
    end,
  },
  {
    'smoka7/hop.nvim',
    keys = {
      { "<leader>h", "<cmd>HopWord<cr>", mode = { 'n', 'v' }, desc = "Hop Word" }
    },
    config = function()
      require('hop').setup({})
    end,
  },
  {
    'stevearc/aerial.nvim',
    keys = {
      { "<leader>a", "<cmd>AerialToggle<cr>", desc = "Toggle Aerial" }
    },
    config = function()
      require('aerial').setup({
        -- prioritize lsp over treesitter
        backends = { 'lsp', 'treesitter', 'markdown', 'asciidoc', 'man' },
        layout = {
          max_width = { 0.5 },
        },
        close_on_select = true,
        autojump = true,
        on_attach = function(bufnr)
          vim.keymap.set("n", "q", "<cmd>AerialClose<CR>", { buffer = bufnr })
        end,
      })
    end
  },
  {
    "FabijanZulj/blame.nvim",
    keys = {
      { "<leader>gb", "<cmd>Blame window<cr>",  desc = "Git Blame" },
      { "<leader>gv", "<cmd>Blame virtual<cr>", desc = "Git Blame (Virtual Text)" },
    },
    lazy = false,
    config = function()
      require('blame').setup()
    end,
  },
  {
    "NeogitOrg/neogit",
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "telescope.nvim",
    },
    config = function()
      require('neogit').setup({
        mappings = {
          status = {
            ['K'] = false, -- Keep our mapping for K instead of using neogit's
          }
        },
      })
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup()
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>mt", "<cmd>lua toggle_shell()<cr>",   desc = "Terminal" },
      { "<leader>gl", "<cmd>lua toggle_lazygit()<cr>", desc = "Lazygit" },
    },
    version = "*",
    config = true,
    config = function()
      require('toggleterm').setup({
        size = function(term)
          return vim.o.lines - 10
        end,
        open_mapping = [[<c-z>]],
        direction = 'horizontal',
        float_opts = {
          winblend = 10,
          border = '',
        },
        autochdir = true,
        persist_size = false,
        --shade_terminals = false,
        shading_factor = 1,
      })

      -- We at least ensure that we use the current window dimensions as of the
      -- time the terminal is created
      local Terminal = require('toggleterm.terminal').Terminal

      -- Subtracting 1 from the height leaves space for the status line
      local ashell = nil
      function toggle_shell()
        if not ashell then
          ashell = Terminal:new({
            --float_opts = { width = vim.o.columns, height = vim.o.lines - 1 },
            on_close = function(term) shell = nil end,
          })
        end
        ashell:toggle()
      end

      local lazygit = nil
      function toggle_lazygit()
        if not lazygit then
          lazygit = Terminal:new({
            cmd = 'lazygit',
            --float_opts = { width = vim.o.columns, height = vim.o.lines - 1 },
            on_close = function(term) lazygit = nil end,
          })
        end
        lazygit:toggle()
      end
    end,
  },
})

-- LSP capabilities necessary for nvim-cmp completion
local caps = require('cmp_nvim_lsp').default_capabilities()

require('lspconfig').clangd.setup({
  cmd = {
    -- '/usr/llvm/19/bin/clangd',
    'clangd',
    -- IIUC, clangd doesn't recognize c++ as a compiler, so we have to
    -- whitelist it here to give clangd permission to run it and detect that
    -- it's actually gcc
    '--query-driver=/usr/bin/c++',
    -- In particular, clangd inserts the wrong Qt headers (see
    -- https://github.com/clangd/clangd/issues/374)
    '--header-insertion=never',
  },
  capabilities = caps,
  --on_attach = function(client, bufnr)
  --end,
})

vim.keymap.set('n', '<leader>pl', '<cmd>Lazy<cr>', { desc = "Lazy package manager" })

-- Global mappings.
vim.keymap.set('n', '<leader>df', vim.diagnostic.open_float, { desc = "Open floating diagnostics window" })
vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_prev, { desc = "Go to next diagnostic" })
vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_next, { desc = "Go to previous diagnostic" })
vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { desc = "Add diagnostics to location list" })
local hide_diagnostics = function()
  --vim.diagnostic.hide(nil, 0)
  vim.diagnostic.config({ virtual_text = false })
end
local show_diagnostics = function()
  --vim.diagnostic.show(nil, 0)
  vim.diagnostic.config({ virtual_text = true })
end
vim.keymap.set('n', '<leader>dh', hide_diagnostics, { desc = 'Hide right margin diagnostics' })
vim.keymap.set('n', '<leader>ds', show_diagnostics, { desc = 'Show right margin diagnostics' })

-- Add buffer-local key mappings when LSP becomes active
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP key bindings',
  callback = function(event)
    -- simplify registering key bindings with which-key
    local wk = require("which-key")
    wk.add({ { "<leader>l", buffer = event.buf, group = "LSP" } })
    local map_keys = function(keys, cmd, desc)
      wk.add({ { keys, cmd, buffer = event.buf, desc = desc } })
    end
    -- helper for checking for binding keys to function only if it exists
    local try_map_keys = function(keys, cmd, desc)
      if cmd ~= nil then
        map_keys(keys, cmd, desc)
      end
    end
    try_map_keys('<leader>la', vim.lsp.buf.code_action, 'Perform code action')
    try_map_keys('<leader>lh', vim.lsp.buf.hover, 'Hover')
    try_map_keys('<leader>ld', vim.lsp.buf.definition, 'Go to definition')
    try_map_keys('<leader>lD', vim.lsp.buf.declaration, 'Go to declaration')
    try_map_keys('<leader>li', vim.lsp.buf.implementation, 'Go to implementation')
    try_map_keys('<leader>lo', vim.lsp.buf.type_definition, 'Go to type definition')
    try_map_keys('<leader>lr', vim.lsp.buf.references, 'References')
    try_map_keys('<leader>ls', vim.lsp.buf.signature_help, 'Signature help')
    try_map_keys('<leader>lR', vim.lsp.buf.rename, 'Rename')
    try_map_keys('<leader>ln', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
      'Toggle inlay hints')
    if vim.lsp.buf.format ~= nil then
      -- NOTE: Editing buffer while formatting asynchronously "can lead to unexpected changes"
      map_keys('<leader>lf', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer')
      vim.api.nvim_create_autocmd("BufWritePre", {
        desc = 'Format on save',
        buffer = event.buf,
        callback = function() vim.lsp.buf.format() end,
      })
    end
    -- Bind the source/header switch only if this is clangd
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client.name == 'clangd' then
      map_keys('<leader>lt', vim.cmd.ClangdSwitchSourceHeader, 'Toggle between source and header')
      map_keys('<leader>lI', vim.cmd.ClangdSymbolInfo, 'Symbol Info')
      map_keys('<leader>lm', vim.cmd.ClangdMemoryUsage, 'Memory Usage')
      map_keys('<leader>lx', vim.cmd.ClangdAST, 'AST')
      map_keys('<leader>ly', vim.cmd.ClangdTypeHierarchy, 'Type Hierarchy')
    end
  end,
})

-- vim.api.nvim_create_autocmd("FileChangedShellPost", {
--   desc = 'Destroy buffers for deleted files',
--   callback = function (args)
--     if vim.v.fcs_reason == "deleted" then
--       vim.api.nvim_buf_delete(args.buf, { force = true })
--     end
--   end,
-- })

local curwd = nil
local function changecwd(wd)
  curwd = wd
  vim.cmd("cd " .. vim.fn.fnameescape(wd))
  vim.notify("CWD changed to " .. wd, vim.log.levels.INFO)
end

local function relpath(...)
  return vim.fs.joinpath(...)
end

local function abspath(...)
  return vim.fn.fnamemodify(relpath(...), ":p")
end

local function homepath(...)
  return abspath(vim.loop.os_homedir(), ...)
end

local function configpath(...)
  return abspath(homepath('.config'), ...)
end

function find_project_files()
  require('telescope.builtin').find_files({
    find_command = { 'fd', '-t=file', '-e=cpp', '-e=hpp', '-e=h', '-e=qml' },
    sort_lastused = true,
  })
end

function find_project()
  local cmd = "fd --type d --max-depth 1"
  local projects = homepath('projects')
  local src = vim.fn.systemlist("cd " .. vim.fn.shellescape(projects) .. " && " .. cmd)
  async_picker("Choose a project", src, function(selection)
    changecwd(abspath(projects, selection))
    vim.cmd("Yazi cwd")
  end)
end

-- This is for setting the cwd for neovim, usually to a project containing a
-- .git directory. It can also move upwards so that you can move from a
-- submodule to the parent directory.
function setwd(always_up)
  local anchor_names = {
    '.git',
  }
  if always_up then
    -- lazy way of detecting home directory
    anchor_names[#anchor_names + 1] = ".config"
  end

  -- If we've already set a working dir, start from the parent of the current
  -- working directory. If we haven't, start from the current file's directory.
  -- If the current file has no directory, start from the user's home
  -- directory.
  local path = (always_up and { curwd } or { nil })[1]
  if path == nil then
    path = vim.api.nvim_buf_get_name(0)
    if path == '' then
      changecwd(vim.loop.os_homedir())
      return
    end
  end
  path = vim.fs.dirname(path)

  local anchor_file = vim.fs.find(anchor_names, { path = path, upward = true })[1]
  if anchor_file ~= nil then
    changecwd(vim.fs.dirname(anchor_file))
  end
end

function edit_nvim_config()
  vim.cmd("edit " .. abspath(vim.fn.stdpath('config'), 'init.lua'))
end

function edit_sway_config()
  vim.cmd("edit " .. configpath('sway', 'config'))
end

function edit_fish_config()
  vim.cmd("edit " .. configpath('fish', 'config.fish'))
end

function go_config()
  changecwd(homepath('.config'))
  vim.cmd("Yazi cwd")
end

require("which-key").add({
  { "<leader> ",   "<cmd>e #<cr>",                                                                                  desc = "Switch to most recent buffer" },
  { "<leader>b",   group = "Debugger" },
  { "<leader>c",   group = "Colors" },
  { "<leader>cb",  "<cmd>exec &bg=='light'? 'set bg=dark' : 'set bg=light'<cr>",                                    desc = "Toggle light/dark background" },
  { "<leader>cd",  "<cmd>colorscheme rose-pine-dawn<cr>",                                                           desc = "Rose Pine Dawn" },
  { "<leader>ce",  "<cmd>colorscheme everforest<cr><cmd>set bg=light<cr>",                                          desc = "Everforest" },
  { "<leader>cg",  "<cmd>colorscheme gruvbox<cr>",                                                                  desc = "Gruvbox" },
  { "<leader>cm",  "<cmd>colorscheme monokai_soda<cr>",                                                             desc = "Monokai Soda" },
  { "<leader>co",  "<cmd>colorscheme onedark_dark<cr>",                                                             desc = "OneDark Dark" },
  { "<leader>cp",  "<cmd>colorscheme monokai_pro<cr>",                                                              desc = "Monokai Pro" },
  { "<leader>cr",  "<cmd>colorscheme monokai_ristretto<cr>",                                                        desc = "Monokai Ristretto" },
  { "<leader>d",   group = "Diagnostics" },
  { "<leader>f",   group = "Find" },
  { "<leader>fb",  "<cmd>lua require('telescope.builtin').buffers({ sort_lastused = true })<cr>",                   desc = "Buffers" },
  { "<leader>ff",  "<cmd>lua find_project_files()<cr>",                                                             desc = "Project files" },
  { "<leader>fa",  "<cmd>lua require('telescope.builtin').find_files({ hidden = true, sort_lastused = true })<cr>", desc = "All files" },
  { "<leader>fg",  "<cmd>lua require('telescope.builtin').live_grep({})<cr>",                                       desc = "Grep" },
  { "<leader>fo",  "<cmd>lua require('telescope.builtin').oldfiles({})<cr>",                                        desc = "Previously open files" },
  { "<leader>g",   group = "Git" },
  { "<leader>m",   group = "Misc" },
  { "<leader>p",   group = "Package Management" },
  { "<leader>q",   group = "Quickfix/Location" },
  { "<leader>ql",  "<cmd>LLToggle!<cr>",                                                                            desc = "Toggle Location List" },
  { "<C-j>",       "<cmd>QNext<cr>",                                                                                desc = "Next" },
  { "<C-k>",       "<cmd>QPrev<cr>",                                                                                desc = "Previous" },
  { "<leader>qq",  "<cmd>QFToggle!<cr>",                                                                            desc = "Toggle QuickFix" },
  { "<leader>r",   group = "Project Root" },
  { "<leader>rr",  "<cmd>lua setwd(false)<cr>",                                                                     desc = "Find project root" },
  { "<leader>ru",  "<cmd>lua setwd(true)<cr>",                                                                      desc = "Move project root upward" },
  { "<leader>rf",  "<cmd>lua find_project()<cr>",                                                                   desc = "Find project" },
  { "<leader>rn",  "<cmd>lua edit_nvim_config()<cr>",                                                               desc = "Edit neovim config" },
  { "<leader>rc",  "<cmd>lua go_config()<cr>",                                                                      desc = "Browse config directory" },
  { "<leader>rs",  "<cmd>lua edit_sway_config()<cr>",                                                               desc = "Edit sway config" },
  { "<leader>ri",  "<cmd>lua edit_fish_config()<cr>",                                                               desc = "Edit fish config" },
  { "<leader>t",   group = "Telescope" },
  { "<leader>tb",  group = "Builtins" },
  { "<leader>tb/", "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find({})<cr>",                       desc = "Search current buffer" },
  { "<leader>tbC", "<cmd>lua require('telescope.builtin').commands({})<cr>",                                        desc = "Commands" },
  { "<leader>tbG", "<cmd>lua require('telescope.builtin').grep_string({})<cr>",                                     desc = "Cursor grep" },
  { "<leader>tbQ", "<cmd>lua require('telescope.builtin').quickfixhistory({})<cr>",                                 desc = "Quickfix lists" },
  { "<leader>tbh", "<cmd>lua require('telescope.builtin').command_history({})<cr>",                                 desc = "Command history" },
  { "<leader>tbj", "<cmd>lua require('telescope.builtin').jumplist({})<cr>",                                        desc = "Jump list" },
  { "<leader>tbl", "<cmd>lua require('telescope.builtin').loclist({})<cr>",                                         desc = "Location list" },
  { "<leader>tbm", "<cmd>lua require('telescope.builtin').marks({})<cr>",                                           desc = "Marks" },
  { "<leader>tbp", "<cmd>lua require('telescope.builtin').pickers({})<cr>",                                         desc = "Pickers" },
  { "<leader>tbq", "<cmd>lua require('telescope.builtin').quickfix({})<cr>",                                        desc = "Quickfix" },
  { "<leader>tbr", "<cmd>lua require('telescope.builtin').registers({})<cr>",                                       desc = "Registers" },
  { "<leader>tbs", "<cmd>lua require('telescope.builtin').colorscheme({})<cr>",                                     desc = "Colorscheme" },
  { "<leader>tbt", "<cmd>lua require('telescope.builtin').git_files({})<cr>",                                       desc = "Find git files" },
  { "<leader>tbv", "<cmd>lua require('telescope.builtin').vim_options({})<cr>",                                     desc = "Vim options" },
  { "<leader>tbz", "<cmd>lua require('telescope.builtin').spell_suggest({})<cr>",                                   desc = "Spelling" },
  { "<leader>tl",  group = "LSP" },
  { "<leader>tlC", "<cmd>lua require('telescope.builtin').lsp_outgoing_calls({})<cr>",                              desc = "Outgoing calls" },
  { "<leader>tlW", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols({})<cr>",                   desc = "Dynamic workspace symbols" },
  { "<leader>tlc", "<cmd>lua require('telescope.builtin').lsp_incoming_calls({})<cr>",                              desc = "Incoming calls" },
  { "<leader>tld", "<cmd>lua require('telescope.builtin').lsp_definitions({})<cr>",                                 desc = "Definitions" },
  { "<leader>tle", "<cmd>lua require('telescope.builtin').diagnositics({})<cr>",                                    desc = "Diagnostics" },
  { "<leader>tli", "<cmd>lua require('telescope.builtin').lsp_implementations({})<cr>",                             desc = "Implementations" },
  { "<leader>tlr", "<cmd>lua require('telescope.builtin').lsp_references({})<cr>",                                  desc = "References" },
  { "<leader>tls", "<cmd>lua require('telescope.builtin').lsp_document_symbols({})<cr>",                            desc = "Document symbols" },
  { "<leader>tlt", "<cmd>lua require('telescope.builtin').lsp_definitions({})<cr>",                                 desc = "Type Definitions" },
  { "<leader>tlw", "<cmd>lua require('telescope.builtin').lsp_workspace_symbols({})<cr>",                           desc = "Workspace symbols" },
  { "<leader>tt",  "<cmd>lua require('telescope.builtin').treesitter({})<cr>",                                      desc = "Treesitter" },
  { "<leader>w",   group = "Window" },
  { "<leader>wj",  "<cmd>wincmd j<cr>",                                                                             desc = "Down" },
  { "<leader>wk",  "<cmd>wincmd k<cr>",                                                                             desc = "Up" },
  { "<leader>wh",  "<cmd>wincmd h<cr>",                                                                             desc = "Left" },
  { "<leader>wl",  "<cmd>wincmd l<cr>",                                                                             desc = "Right" },
  { "<leader>wo",  "<cmd>wincmd o<cr>",                                                                             desc = "Close other windows" },
  { "<leader>ww",  "<cmd>wincmd w<cr>",                                                                             desc = "Previous" },
  { "<leader>y",   group = "Yazi" },
})

vim.cmd.colorscheme("gruvbox")
--vim.opt.background = "light"

--vim.opt.guifont = "Droid Sans Mono:h22"
vim.opt.guifont = "Droid Sans Mono"
if vim.g.neovide then
  vim.g.neovide_scale_factor = 1
  vim.keymap.set({ "n", "v" }, "<leader>=", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>",
    { desc = "Increase font size" })
  vim.keymap.set({ "n", "v" }, "<leader>-", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>",
    { desc = "Decrease font size" })
  vim.keymap.set({ "n", "v" }, "<leader>0", ":lua vim.g.neovide_scale_factor = 1.5<CR>", { desc = "Reset font size" })
end

-- Don't display a ridiculous number of completions
vim.opt.pumheight = 10

-- Default tab crap
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Highlight the line the cursor is on
vim.opt.cursorline = true

-- nowrap
vim.opt.wrap = false

-- enable virtualedit mode
vim.opt.virtualedit = "all"

-- Use textwidth to mark character limit
vim.opt.colorcolumn = "+1"

-- Whitespace silliness
vim.opt.listchars = {
  --eol = '$',
  --space = '.',
  trail = '+',
  --extends = '>',
  --precedes = '<',
  nbsp = 'x',
  tab = '>-',
}
vim.opt.list = true

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false -- disable fold at startup
vim.keymap.set('n', '<leader>mf', '<cmd>set foldenable!<cr>', { desc = "Toggle Folding" })

-- Line numbers
vim.opt.number = true

-- Always use system clipboard (requires wl-clipboard on wayland)
-- (See :h provider-clipboard)
vim.opt.clipboard = "unnamedplus"

vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '0', 'g0')
vim.keymap.set('n', '$', 'g$')
vim.keymap.set('v', 'j', 'gj')
vim.keymap.set('v', 'k', 'gk')
vim.keymap.set('v', '0', 'g0')
vim.keymap.set('v', '$', 'g$')
vim.keymap.set('n', 'J', '<c-d>')
vim.keymap.set('n', 'K', '<c-u>')
vim.keymap.set('n', 'H', 'zH')
vim.keymap.set('n', 'L', 'zL')
vim.keymap.set('n', '<c-q>', 'q')
vim.keymap.set('n', 'q', '<nop>')
vim.keymap.set('n', '<esc>', ':noh<cr><esc>', { silent = true })
-- make 0 go to the actual beginning of the line
local function go_linestart()
  local row = vim.fn.line(".")
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end
vim.keymap.set("n", "0", go_linestart)
vim.keymap.set("v", "0", go_linestart)
-- Make $ behave like it does when not in virtualedit mode. (Honestly, who
-- would ever want the other behavior?) This also tries to place the cursor on
-- the right edge of the screen if we're moving horizontally backward.
local function go_eol()
  local win = vim.api.nvim_get_current_win()
  local row, oldcol = unpack(vim.api.nvim_win_get_cursor(win))
  local line = vim.fn.getline(row)
  local newcol = #line - 1
  vim.api.nvim_win_set_cursor(0, { row, newcol })

  -- Place the cursor on the right edge of the screen if we're moving
  -- horizontally backward. Note that in virtualedit vim returns the end of
  -- the column as the position no matter where you are, so this could really
  -- be ==.
  if newcol <= oldcol then
    local width = vim.api.nvim_win_get_width(win)
    local view = vim.fn.winsaveview()
    view.leftcol = math.max(newcol - width, 0)
    vim.fn.winrestview(view)
  end
end
vim.keymap.set("n", "$", go_eol)
vim.keymap.set("v", "$", go_eol)
