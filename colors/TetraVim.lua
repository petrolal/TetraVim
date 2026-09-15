-- TetraVim "Tetris" palette colour scheme.
-- Usage: `:colorscheme TetraVim` (or `vim.cmd.colorscheme("TetraVim")`).
-- The heavy lifting lives in `TetraVim.theme.tetris` so the same highlight
-- set can also be applied directly by the theme loader without going
-- through `:colorscheme`.
require("TetraVim.theme.tetris").apply()
