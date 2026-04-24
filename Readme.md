# prologfmt

A prolog formatter, which is using swi-prolog's formatting scheme,
besides for test where we add newline for readability.

## Usage:

```
make
./prologfmt messy.pl > formatted.pl

// in-place format
./prologfmt -i messy.pl
```

## Vim

This assumes that prologfmt is added to `PATH` 

Trigger on `<leader>f`

```
autocmd FileType prolog nnoremap <buffer> <leader>f :call system('prologfmt -i ' . expand('%'))<CR>:edit!<CR>
```

On save
```
autocmd BufWritePre *.pl,*.prolog call system('prologfmt -i ' . expand('%'))
autocmd BufWritePost *.pl,*.prolog edit!
```