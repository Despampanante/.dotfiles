-- Auto-detect a CMake project root (walking up from this buffer) and point
-- `:make` at its build dir. Avoids needing 'exrc' or per-project config files.
local root = vim.fs.root(0, 'CMakeLists.txt')
if root then vim.bo.makeprg = 'cmake --build ' .. vim.fn.fnameescape(root .. '/build') end
