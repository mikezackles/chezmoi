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

vim.g.mapleader = " " -- should be set before requiring lazy
vim.g.bones_compat = 1 -- silliness to tell zenbones colorscheme we're not installing color picker plugin

require("lazy").setup({
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
  },
  {
    "nvim-telescope/telescope.nvim", branch = '0.1.x',
    dependencies = {
      "nvim-lua/plenary.nvim",
      "telescope-fzf-native.nvim",
    },
    config = function(_, opts)
      local telescope = require('telescope')
      telescope.setup(opts)
      telescope.load_extension('fzf')
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && ' ..
            'cmake --build build --config Release && ' ..
            'cmake --install build --prefix build',
  },
  { "nvim-tree/nvim-web-devicons" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function ()
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
    config = function ()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      local has_words_before = function ()
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
  {
    "lukas-reineke/indent-blankline.nvim", main = "ibl",
    config = function()
      require("ibl").setup({
        scope = {
          show_start = false,
          show_end = false,
        },
      })
    end,
  },
  -- colorschemes
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = true },
  { "rose-pine/neovim", priority = 1000 },
  { "olimorris/onedarkpro.nvim", priority = 1000 },
  { "neanias/everforest-nvim", priority = 1000 },
  { "rebelot/kanagawa.nvim", priority = 1000 },
  { "tanvirtin/monokai.nvim", priority = 1000 },
  { "stevearc/qf_helper.nvim",
    config = function ()
      require("qf_helper").setup({
        quickfix = {
          default_bindings = false,
        },
      })
    end,
  },
})

-- LSP capabilities necessary for nvim-cmp completion
local caps = require('cmp_nvim_lsp').default_capabilities()

require('lspconfig').clangd.setup({
  cmd = {
    '/usr/llvm/18/bin/clangd',
    -- IIUC, clangd doesn't recognize c++ as a compiler, so we have to
    -- whitelist it here to give clangd permission to run it and detect that
    -- it's actually gcc
    '--query-driver=/usr/bin/c++',
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
    wk.register({ l = { name = "LSP" } }, { prefix = '<leader>', buffer = event.buf })
    local map_keys = function(keys, cmd, desc)
      wk.register({[keys] = { cmd, desc, buffer = event.buf}})
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
    if vim.lsp.buf.format ~= nil then
      -- NOTE: Editing buffer while formatting asynchronously "can lead to unexpected changes"
      map_keys('<leader>lf', function() vim.lsp.buf.format({async = true}) end, 'Format buffer')
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
      map_keys('<leader>ln', vim.cmd.ClangdToggleInlayHints, 'Toggle inlay hints')
      map_keys('<leader>lI', vim.cmd.ClangdSymbolInfo, 'Symbol Info')
      map_keys('<leader>lm', vim.cmd.ClangdMemoryUsage, 'Memory Usage')
      map_keys('<leader>lx', vim.cmd.ClangdAST, 'AST')
    end
  end,
})

require("which-key").register({
  [' '] = { "<cmd>e #<cr>", "Switch to most recent buffer" },
  b = {
    name = "Buffers",
    n = { "<cmd>bnext<cr>", "Next" },
    p = { "<cmd>bprevious<cr>", "Previous" },
  },
  q = {
    name = "Quickfix/Location",
    n = { "<cmd>QNext<cr>", "Next" },
    p = { "<cmd>QPrev<cr>", "Previous" },
    q = { "<cmd>QFToggle!<cr>", "Toggle QuickFix" },
    l = { "<cmd>LLToggle!<cr>", "Toggle Location List" },
  },
  c = {
    name = "Colors",
    b = { "<cmd>exec &bg=='light'? 'set bg=dark' : 'set bg=light'<cr>", "Toggle light/dark background" },
    g = { "<cmd>colorscheme gruvbox<cr>", "Gruvbox" },
    m = { "<cmd>colorscheme monokai_soda<cr>", "Monokai Soda" },
    r = { "<cmd>colorscheme monokai_ristretto<cr>", "Monokai Ristretto" },
    p = { "<cmd>colorscheme monokai_pro<cr>", "Monokai Pro" },
    e = { "<cmd>colorscheme everforest<cr>", "Everforest" },
    o = { "<cmd>colorscheme onedark_dark<cr>", "OneDark Dark" },
    d = { "<cmd>colorscheme rose-pine-dawn<cr>", "Rose Pine Dawn" },
  },
  d = { name = "Diagnostics" },
  p = { name = "Package Management" },
  --l = { name = "LSP" },
  f = { name = "Fold" },
  t = {
    name = "Telescope",
    b = {
      name = "Builtins",
      b = { "<cmd>lua require('telescope.builtin').buffers({})<cr>", "Buffers" },
      F = { "<cmd>lua require('telescope.builtin').oldfiles({})<cr>", "Previously open files" },
      -- TODO: Only map this in C++ files
      c = { "<cmd>lua require('telescope.builtin').find_files({ hidden = true, default_text = \".cpp$ | .hpp$ | 'meson.build \" })<cr>", "C++ files" },
      f = { "<cmd>lua require('telescope.builtin').find_files({ hidden = true })<cr>", "Find files" },
      t = { "<cmd>lua require('telescope.builtin').git_files({})<cr>", "Find git files" },
      G = { "<cmd>lua require('telescope.builtin').grep_string({})<cr>", "Cursor grep" },
      g = { "<cmd>lua require('telescope.builtin').live_grep({})<cr>", "Grep" },
      C = { "<cmd>lua require('telescope.builtin').commands({})<cr>", "Commands" },
      h = { "<cmd>lua require('telescope.builtin').command_history({})<cr>", "Command history" },
      m = { "<cmd>lua require('telescope.builtin').marks({})<cr>", "Marks" },
      s = { "<cmd>lua require('telescope.builtin').colorscheme({})<cr>", "Colorscheme" },
      q = { "<cmd>lua require('telescope.builtin').quickfix({})<cr>", "Quickfix" },
      Q = { "<cmd>lua require('telescope.builtin').quickfixhistory({})<cr>", "Quickfix lists" },
      l = { "<cmd>lua require('telescope.builtin').loclist({})<cr>", "Location list" },
      j = { "<cmd>lua require('telescope.builtin').jumplist({})<cr>", "Jump list" },
      v = { "<cmd>lua require('telescope.builtin').vim_options({})<cr>", "Vim options" },
      r = { "<cmd>lua require('telescope.builtin').registers({})<cr>", "Registers" },
      z = { "<cmd>lua require('telescope.builtin').spell_suggest({})<cr>", "Spelling" },
      ['/'] = { "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find({})<cr>", "Search current buffer" },
      p = { "<cmd>lua require('telescope.builtin').pickers({})<cr>", "Pickers" },
    },
    l = {
      name = "LSP",
      r = { "<cmd>lua require('telescope.builtin').lsp_references({})<cr>", "References" },
      c = { "<cmd>lua require('telescope.builtin').lsp_incoming_calls({})<cr>", "Incoming calls" },
      C = { "<cmd>lua require('telescope.builtin').lsp_outgoing_calls({})<cr>", "Outgoing calls" },
      s = { "<cmd>lua require('telescope.builtin').lsp_document_symbols({})<cr>", "Document symbols" },
      w = { "<cmd>lua require('telescope.builtin').lsp_workspace_symbols({})<cr>", "Workspace symbols" },
      W = { "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols({})<cr>", "Dynamic workspace symbols" },
      e = { "<cmd>lua require('telescope.builtin').diagnositics({})<cr>", "Diagnostics" },
      i = { "<cmd>lua require('telescope.builtin').lsp_implementations({})<cr>", "Implementations" },
      d = { "<cmd>lua require('telescope.builtin').lsp_definitions({})<cr>", "Definitions" },
      t = { "<cmd>lua require('telescope.builtin').lsp_definitions({})<cr>", "Type Definitions" },
    },
    t = { "<cmd>lua require('telescope.builtin').treesitter({})<cr>", "Treesitter" },
  },
}, {
  prefix = '<leader>'
})

vim.cmd.colorscheme("gruvbox")
--vim.opt.background = "light"

-- Don't display a ridiculous number of completions
vim.opt.pumheight = 10

-- Default tab crap
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Highlight the line the cursor is on
vim.opt.cursorline = true

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
vim.keymap.set('n', '<leader>ft', '<cmd>set foldenable!<cr>', { desc = "Toggle" })

-- Line numbers
vim.opt.number = true

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
vim.keymap.set('n', '<c-q>', 'q')
vim.keymap.set('n', 'q', '<nop>')
vim.keymap.set('n', '<esc>', ':noh<cr><esc>', { silent = true })
