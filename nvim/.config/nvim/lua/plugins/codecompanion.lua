return {
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
    opts = {
      -- ponytail: built-in claude_code ACP adapter spawns the `claude-agent-acp`
      -- binary from PATH; install with: pnpm add -g @agentclientprotocol/claude-agent-acp
      adapters = {
        acp = {
          claude_code = function()
            local adapter = require('codecompanion.adapters').extend('claude_code', {})
            -- Upstream default forwards the literal string "CLAUDE_CODE_OAUTH_TOKEN"
            -- as bearer token when that env var is unset -> 401. Drop env so the
            -- Claude Agent SDK falls back to the `claude` CLI login credentials.
            adapter.env = {}
            return adapter
          end,
        },
      },
      interactions = {
        chat = { adapter = 'claude_code' },
        inline = { adapter = 'claude_code' },
      },
    },
  },
}
