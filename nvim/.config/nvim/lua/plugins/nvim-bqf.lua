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
  },
}
