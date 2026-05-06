# prologfmt

A Prolog formatter that follows SWI-Prolog’s formatting conventions, with the exception of

- tests, where we insert newline to improve readability.
- wraps when exceeding 80 characters.

## Install 

Build the executable yourself by running
```bash
make
```

or get the executable from 
https://github.com/vushu/prologfmt/releases/

Then add to `PATH` or 
```bash
sudo cp prologfmt /usr/local/bin/
sudo chmod +x /usr/local/bin/prologfmt
```

## Usage:

```bash
# for help
prologfmt -h or --help

prologfmt messy.pl > formatted.pl

# in-place format
prologfmt -i messy.pl

# using stdin, useful for editors
cat messy.pl | prologfmt

# or explicitly:

prologfmt --stdin < file.pl
```

## Vim/Neovim


### Trigger on `<leader>f`

vimscript
```vim
function! PrologFormat()
  let l:pos = getpos('.')
  %!prologfmt
  call setpos('.', l:pos)
endfunction

innoremap <leader>f :call PrologFormat()<CR>
```

lua
```lua
local function prolog_format()
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.cmd("%!prologfmt")
  vim.api.nvim_win_set_cursor(0, cursor)
end

vim.keymap.set("n", "<leader>f", prolog_format)
```

### Trigger on save

vimscript
```vim
autocmd BufWritePre *.pl call PrologFormat()
```

lua
```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.pl",
  callback = prolog_format,
})
```

## Known issues 
- Inline comments gets moved to top of the clause.
- Inline comments after a `.` gets moved to top of the next clause.