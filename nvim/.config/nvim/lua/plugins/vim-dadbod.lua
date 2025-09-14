return {
  "tpope/vim-dadbod",
  lazy = true,
  cmd = { "DB", "DBUI" },
  dependencies = {
    "kristijanhusak/vim-dadbod-ui",
    "kristijanhusak/vim-dadbod-completion",
  },
  config = function()
    vim.g.db_ui_use_nerd_fonts = true
    vim.g.db_ui_save_location = "~/.local/share/db_ui"
  end,
}
