call plug#begin()

" Plugin pentru completare automată
Plug 'hrsh7th/nvim-cmp'             " Completare automată completă
Plug 'hrsh7th/cmp-buffer'           " Sursa de completare din buffer
Plug 'hrsh7th/cmp-path'             " Sursa de completare din căi
Plug 'hrsh7th/cmp-nvim-lsp'         " Sursa de completare LSP
Plug 'windwp/nvim-autopairs'
Plug 'neovim/nvim-lspconfig'        " Configurare LSP
Plug 'L3MON4D3/LuaSnip'             " Motor de snippet-uri
Plug 'saadparwaiz1/cmp_luasnip'     " Integrare LuaSnip cu nvim-cmp

" Tema de culori
Plug 'catppuccin/nvim', { 'as': 'catppuccin'}

call plug#end()

" Setează liderul la spațiu
let mapleader=" "

" Funcție pentru a compila și a rula codul în terminal
function! CompileAndRunInTerminal()
  write
  vsplit | terminal bash -c "g++ % -o %:r && ./%:r"
  sleep 100m
  call feedkeys("\<C-\\>\<C-n>", 't')
  sleep 100m
  call feedkeys("i", 't') " Intră în modul insert
endfunction

" Mapări pentru leader keys
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q!<CR>
nnoremap <leader>x :call CompileAndRunInTerminal()<CR>
vnoremap <leader>y "+y
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Configurări generale
set number
set termguicolors
syntax on
set cursorline
set scrolloff=4
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent

" Setează tema de culori
colorscheme catppuccin

lua <<EOF
local cmp = require'cmp'
local lspconfig = require'lspconfig'
local luasnip = require'luasnip'
local npairs = require('nvim-autopairs')
npairs.setup({})

-- Integrarea cu nvim-cmp
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end
formatting = {
  format = function(entry, vim_item)
    -- Adaugă parantezele la completările pentru funcții
    if vim_item.kind == "Function" or vim_item.kind == "Method" then
      vim_item.abbr = vim_item.abbr .. '()'
    end
    return vim_item
  end
}
luasnip.add_snippets('cpp', {
    luasnip.parser.parse_snippet("for", "for (int ${1:i} = 0; ${1:i} < ${2:n}; ${1:i}++) {\n\t${3}\n}"),
})
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback() -- dacă Tab nu face completare, va folosi comportamentul normal
      end
    end, { 'i', 's' }),
    
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
    
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
})

-- Configurare LSP pentru C++
lspconfig.clangd.setup({})
EOF
