-- Leader keys: set before plugins load so their mappings pick them up.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Share the unnamed register with the system clipboard.
-- Yank, delete, change, and put all go through it.
vim.opt.clipboard = "unnamedplus"

-- Plugins, managed by the built-in vim.pack.
-- Add entries here; they install on next startup. Update with :lua vim.pack.update()
vim.pack.add({
  "https://github.com/ibhagwan/fzf-lua", -- requires the fzf binary on PATH
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/EdenEast/nightfox.nvim",
  "https://github.com/nvzone/volt", -- required by floaterm
  "https://github.com/nvzone/floaterm",
  "https://github.com/hrsh7th/nvim-cmp",
  "https://github.com/hrsh7th/cmp-nvim-lsp", -- feeds LSP results into nvim-cmp
})

-- Pure black background: bg1 is the editor, bg0 is floats, sidebars and the statusline.
require("nightfox").setup({
  palettes = {
    carbonfox = { bg0 = "#000000", bg1 = "#000000" },
  },
})
vim.cmd.colorscheme("carbonfox")

-- LSP: servers are installed by Mason and configured by nvim-lspconfig.
-- Names below are nvim-lspconfig names, see :help lspconfig-all
local servers = {
  "clangd", -- C, C++
  "rust_analyzer", -- Rust
  "gopls", -- Go
  "lua_ls", -- Lua
  "asm_lsp", -- Assembly
  "pyright", -- Python
  "jdtls", -- Java
  "texlab", -- LaTeX
  "ts_ls", -- TypeScript, JavaScript
  "eslint", -- JS/TS linting; needs eslint in the project
  "html", -- HTML
  "cssls", -- CSS
  "stylua", -- Lua formatting
}

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = servers,
  automatic_enable = false, -- enabled explicitly below
})

-- Teach lua_ls about the Neovim runtime, so `vim` isn't flagged in this config.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    },
  },
})

-- Tell servers what nvim-cmp supports, such as snippets.
vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

vim.lsp.enable(servers)

-- LSP keymaps, set only in buffers with a server attached.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
    vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { buffer = args.buf, desc = "Show symbol signature" })
    vim.keymap.set("n", "gr", function()
      require("fzf-lua").lsp_references()
    end, { buffer = args.buf, nowait = true, desc = "Show references" }) -- nowait blocks the default gr* keymaps
    vim.keymap.set("n", "gu", function()
      require("fzf-lua").lsp_references({ includeDeclaration = false })
    end, { buffer = args.buf, desc = "Go to usages" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = args.buf, desc = "Rename symbol" })
    vim.keymap.set("n", "<leader>ra", vim.lsp.buf.code_action, { buffer = args.buf, desc = "Code action" })
  end,
})

-- Completion
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      vim.snippet.expand(args.body)
    end,
  },
  -- Also adds <C-n>/<C-p> to select, <C-y> to confirm, <C-e> to dismiss.
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
  }),
  sources = {
    { name = "nvim_lsp" },
  },
})

-- Floating terminal: Esc leaves terminal mode, without affecting fzf-lua's terminals.
-- volt binds Esc and q in Normal mode to destroy every terminal, and rebinds them
-- whenever a terminal is added, so override them here to hide the float instead.
require("floaterm").setup({
  mappings = {
    term = function(buf)
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = buf })
      for _, target in ipairs({ buf, require("floaterm.state").sidebuf }) do
        for _, key in ipairs({ "<Esc>", "q" }) do
          vim.keymap.set("n", key, function()
            require("floaterm").toggle()
          end, { buffer = target, desc = "Hide floating terminal" })
        end
      end
    end,
  },
})

-- Keymaps
vim.keymap.set("n", "<leader>f", function()
  require("fzf-lua").files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>/", function()
  require("fzf-lua").buffers()
end, { desc = "Find open buffers" })
vim.keymap.set("n", "<leader>t", function()
  require("floaterm").toggle()
end, { desc = "Toggle floating terminal" })

-- Windows
vim.keymap.set("n", "<leader>ws", "<C-w>v", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
