-- TypeScript LSP: always use the project's own TypeScript (node_modules).
--
--   node_modules/typescript >= 7  ->  `tsc` (native TS 7 LSP: node_modules/.bin/tsc --lsp --stdio)
--   anything else                 ->  `vtsls` (autoUseWorkspaceTsdk picks node_modules tsserver.js,
--                                     bundled TS only when the project has none)
--
-- Why: TS 7 ships no tsserver.js, so vtsls silently falls back to its bundled TS 5.x,
-- which produces bogus diagnostics (e.g. decorator errors with experimentalDecorators).

local lock_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }

--- Project root like nvim-lspconfig's vtsls/tsc: nearest lockfile, else .git, else cwd.
--- Returns nil for Deno files (denols handles those).
---@param bufnr integer
---@return string?
local function project_root(bufnr)
  local root = vim.fs.root(bufnr, { lock_markers, { ".git" } })
  local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
  local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
  if deno_lock_root and (not root or #deno_lock_root > #root) then
    return nil
  end
  if deno_root and (not root or #deno_root >= #root) then
    return nil
  end
  return root or vim.fn.getcwd()
end

local major_cache = {} ---@type table<string, integer|false>

--- Major version of <root>/node_modules/typescript, or false if not installed.
---@param root string
---@return integer|false
local function ts_major(root)
  if major_cache[root] ~= nil then
    return major_cache[root]
  end
  local major = false
  local pkg = vim.fs.joinpath(root, "node_modules", "typescript", "package.json")
  if vim.fn.filereadable(pkg) == 1 then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), "\n"))
    if ok and type(data) == "table" and type(data.version) == "string" then
      major = tonumber(data.version:match("^(%d+)")) or false
    end
  end
  major_cache[root] = major
  return major
end

---@param root string
local function local_tsc(root)
  return vim.fs.joinpath(root, "node_modules", ".bin", "tsc")
end

---@param root string
local function is_native_ts(root)
  local major = ts_major(root)
  return major and major >= 7 and vim.fn.executable(local_tsc(root)) == 1
end

return {
  { import = "lazyvim.plugins.extras.lang.typescript" },
  {
    "neovim/nvim-lspconfig",
    -- runs after the typescript extra's opts (which enables only one of vtsls/tsc)
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        enabled = true,
        root_dir = function(bufnr, on_dir)
          local root = project_root(bufnr)
          if root and not is_native_ts(root) then
            on_dir(root)
          end
        end,
      })

      opts.servers.tsgo = { enabled = false }
      opts.servers.tsc = vim.tbl_deep_extend("force", opts.servers.tsc or {}, {
        enabled = true,
        mason = false, -- never a global/mason tsc: only the project's node_modules
        cmd = function(dispatchers, config)
          return vim.lsp.rpc.start({ local_tsc(config.root_dir), "--lsp", "--stdio" }, dispatchers)
        end,
        root_dir = function(bufnr, on_dir)
          local root = project_root(bufnr)
          if root and is_native_ts(root) then
            on_dir(root)
          end
        end,
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        -- LazyVim's tsc extra defaults (quieter than lspconfig's)
        settings = {
          ["js/ts"] = {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = false },
              parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
      })
    end,
  },
}
