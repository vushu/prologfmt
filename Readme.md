# prologfmt

A Prolog formatter that follows SWI-Prolog’s formatting conventions, with the exception of tests, where we insert newline to improve readability.

## Usage:

```
make
./prologfmt messy.pl > formatted.pl

// in-place format
./prologfmt -i messy.pl

// using stdin, useful for editors
cat messy.pl | prologfmt

// or explicitly:

prologfmt --stdin < file.pl
```

## Vim

This assumes that prologfmt is added to `PATH` 

Trigger on `<leader>f`

```vim
innoremap <leader>f :call PrologFormat()<CR>

function! PrologFormat()
  let l:pos = getpos('.')
  %!prologfmt
  call setpos('.', l:pos)
endfunction
```

```lua
vim.keymap.set("n", "<leader>f", function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.cmd("%!prologfmt")
  vim.api.nvim_win_set_cursor(0, cursor)
end)
```

On save
```vim
autocmd BufWritePre *.pl call PrologFormat()
```

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.pl",
  callback = prolog_format,
})
```
