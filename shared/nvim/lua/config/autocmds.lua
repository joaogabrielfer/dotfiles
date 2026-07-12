local group = vim.api.nvim_create_augroup("dotfiles", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  pattern = "*.md",
  callback = function(event)
    local vault = vim.fs.normalize(vim.fn.expand("~/personal/notas"))
    local path = vim.fs.normalize(vim.api.nvim_buf_get_name(event.buf))
    local command = vim.startswith(path, vault .. "/") and "RenderMarkdown disable" or "RenderMarkdown enable"
    pcall(vim.cmd, command)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "qf",
  callback = function(event)
    vim.keymap.set("n", "dd", function()
      local items = vim.fn.getqflist()
      local index = vim.api.nvim_win_get_cursor(0)[1]
      if #items == 0 then
        return
      end

      table.remove(items, index)
      vim.fn.setqflist(items, "r")
      if #items > 0 then
        vim.api.nvim_win_set_cursor(0, { math.min(index, #items), 0 })
      end
    end, { buffer = event.buf, desc = "Delete quickfix item" })
  end,
})

local diagnostic_count = -1
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = vim.api.nvim_create_augroup("dotfiles.diagnostics", { clear = true }),
  callback = function()
    local quickfix = vim.fn.getqflist({ title = 1, size = 1 })
    if quickfix.size ~= 0 and quickfix.title ~= "Diagnostics" then
      return
    end

    local diagnostics = vim.diagnostic.get(nil, {
      severity = { min = vim.diagnostic.severity.WARN },
    })

    if #diagnostics > 0 then
      vim.diagnostic.setqflist({
        open = false,
        title = "Diagnostics",
        severity = { min = vim.diagnostic.severity.WARN },
      })
    else
      vim.fn.setqflist({}, "r", { title = "Diagnostics" })
    end

    if #diagnostics == diagnostic_count then
      return
    end

    if #diagnostics > 0 then
      vim.notify(("%d errors/warnings listed"):format(#diagnostics), vim.log.levels.WARN, { title = "LSP" })
    elseif diagnostic_count > 0 then
      vim.notify("Diagnostics resolved", vim.log.levels.INFO, { title = "LSP" })
    end
    diagnostic_count = #diagnostics
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("dotfiles.lsp", { clear = true }),
  callback = function(event)
    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
    local bufnr = event.buf

    if client:supports_method("textDocument/linkedEditingRange") then
      vim.lsp.linked_editing_range.enable(true, { bufnr = bufnr, client_id = client.id })
    end

    if vim.bo[bufnr].filetype ~= "rust" or client.name ~= "rust-analyzer" then
      return
    end

    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client:supports_method("textDocument/formatting") and not vim.b[bufnr].rust_format_on_save then
      vim.b[bufnr].rust_format_on_save = true
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("dotfiles.rust-format", { clear = false }),
        buffer = bufnr,
        callback = function()
          local ok, message = pcall(vim.lsp.buf.format, {
            bufnr = bufnr,
            id = client.id,
            timeout_ms = 2000,
          })
          if not ok then
            vim.notify("rustfmt failed: " .. tostring(message), vim.log.levels.WARN)
          end
        end,
      })
    end
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = true,
})
