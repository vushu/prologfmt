# prologfmt

A Prolog formatter that follows SWI-Prolog’s formatting conventions, except in tests where additional newlines are inserted to improve readability.

## Usage:

```
make
./prologfmt messy.pl > formatted.pl

// in-place format
./prologfmt -i messy.pl

// using stdin
cat messy.pl | prologfmt

// or explicitly:

prologfmt --stdin < file.pl
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
