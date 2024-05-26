return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    config = function()
      require("neo-tree").setup({
	 filesystem = {
          filtered_items = {
            visible = true, -- when true, they will just be displayed differently than normal items
            hide_dotfiles = false,
            hide_gitignored = true,
          --   hide_hidden = true, -- only works on Windows for hidden files/directories
          --   hide_by_name = {
          --     --"node_modules"
          --   },
          --   hide_by_pattern = { -- uses glob style patterns
          --     --"*.meta",
          --     --"*/src/*/tsconfig.json",
          --   },
          --   always_show = { -- remains visible even if other settings would normally hide it
          --     --".gitignored",
          --   },
          --   never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
          --     --".DS_Store",
          --     --"thumbs.db"
          --   },
          --   never_show_by_pattern = { -- uses glob style patterns
          --     --".null-ls_*",
          --   },
          },
          follow_current_file = {
            enabled = true, -- This will find and focus the file in the active buffer every time
            --               -- the current file is changed while the tree is open.
            -- leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          }
	}
      })
      vim.keymap.set(
	"n",
	"<leader>n",
	":Neotree filesystem reveal left<CR>",
	{ desc = "Show [N]eo-tree filesystem" }
      )
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "stevearc/oil.nvim",
    opts = {
      default_file_explorer = false,
    },
    -- Optional dependencies
    -- dependencies = { "nvim-tree/nvim-web-devicons" },
    -- config = function()
    -- require("oil").setup()
    -- end,
  },
}
