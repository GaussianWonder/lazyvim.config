local M = {}

--- First window showing `buf` that is not hidden via `nvim_win_set_config({ hide = true })`.
---@param buf? integer
---@return integer? win
function M.buf_win(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
    if not (ok and cfg.hide) then
      return win
    end
  end
end

--- Files selected in a snacks picker (falls back to the item under the cursor).
---@param picker snacks.Picker
---@return snacks.picker.Item[]
function M.picker_items(picker)
  return vim.tbl_filter(function(item)
    return item.file ~= nil
  end, picker:selected({ fallback = true }))
end

--- The snacks explorer picker, if open.
---@return snacks.Picker?
function M.explorer()
  return Snacks.picker.get({ source = "explorer" })[1]
end

return M
