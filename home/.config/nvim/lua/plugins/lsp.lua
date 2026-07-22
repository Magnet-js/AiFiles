-- language servers: binaries come from nix (home.nix), configs from nvim-lspconfig
return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    vim.lsp.enable({ 'gopls', 'ts_ls' })

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local map = function(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
        end
        map('gd', vim.lsp.buf.definition, 'Go to definition')
        map('grn', vim.lsp.buf.rename, 'Rename symbol')
        map('gra', vim.lsp.buf.code_action, 'Code action')
        map('grr', vim.lsp.buf.references, 'References')
        map('K', vim.lsp.buf.hover, 'Hover docs')
      end,
    })

    -- gofmt on save
    vim.api.nvim_create_autocmd('BufWritePre', {
      pattern = '*.go',
      callback = function() vim.lsp.buf.format() end,
    })
  end,
}
