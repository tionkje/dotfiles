return {
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
    dependencies = {
      -- Optional: fzf integration
      {
        'junegunn/fzf',
        -- build = function()
        --   vim.fn['fzf#install']()
        -- end,
      },
      -- Optional, highly recommended: nvim-treesitter
      {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
      },
    },
    opts = {
      func_map = {
        filter = '+',
        filterr = '-',
        fzffilter = '/',
      },
    },
    config = function(_, opts)
      require('bqf').setup(opts)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'qf',
        callback = function(args)
          local map = function(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
          end
          map('u', '<cmd>colder<cr>', 'Quickfix: undo filter (older list)')
          map('<C-r>', '<cmd>cnewer<cr>', 'Quickfix: redo filter (newer list)')
        end,
      })
    end,
  },
}
