-- Auto-detect a project root (walking up from this buffer) and point `:make`
-- at its build dir. Avoids needing 'exrc' or per-project config files.
--
-- Use '.git' rather than 'CMakeLists.txt' as the marker: CMake projects with
-- subdirectories normally have a 'CMakeLists.txt' in *every* subdirectory, so
-- that marker would match the nearest one instead of the true project root.
local root = vim.fs.root(0, '.git')
if root then vim.bo.makeprg = 'cmake --build ' .. vim.fn.fnameescape(root .. '/build') end

-- `:Run` executes the binary CMake builds from this exact source file, relying
-- on CMake's default output layout (mirrors the source tree under 'build/',
-- e.g. 'src/01-fundamentals/00-hello.cpp' -> 'build/src/01-fundamentals/00-hello').
vim.api.nvim_buf_create_user_command(0, 'Run', function()
  if not root then
    vim.notify('No .git root found', vim.log.levels.ERROR)
    return
  end
  local rel = vim.api.nvim_buf_get_name(0):sub(#root + 2):gsub('%.%w+$', '')
  local bin = root .. '/build/' .. rel
  if vim.fn.executable(bin) ~= 1 then
    vim.notify('Binary not found, build first: ' .. bin, vim.log.levels.WARN)
    return
  end
  vim.cmd('botright 15new')
  vim.bo.bufhidden = 'wipe'
  local job = vim.fn.jobstart({ bin }, { term = true, cwd = root })
  if job <= 0 then
    vim.notify('Failed to start: ' .. bin, vim.log.levels.ERROR)
    vim.cmd('close')
    return
  end
  vim.cmd('startinsert')
end, {})
