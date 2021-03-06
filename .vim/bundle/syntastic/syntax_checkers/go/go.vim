"============================================================================
"File:        go.vim
"Description: Check go syntax using 'gofmt -l' followed by 'go [build|test]'
"Maintainer:  Kamil Kisiel <kamil@kamilkisiel.net>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
" This syntax checker does not reformat your source code.
" Use a BufWritePre autocommand to that end:
"   autocmd FileType go autocmd BufWritePre <buffer> Fmt
"============================================================================
function! SyntaxCheckers_go_GetLocList()
    " Check with gofmt first, since `go build` and `go test` might not report
    " syntax errors in the current file if another file with syntax error is
    " compiled first.
    let makeprg = 'gofmt -l % 1>/dev/null'
    let errorformat = '%f:%l:%c: %m,%-G%.%#'
    let errors = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat, 'defaults': {'type': 'e'} })

    if !empty(errors)
        return errors
    endif

    " Test files, i.e. files with a name ending in `_test.go`, are not
    " compiled by `go build`, therefore `go test` must be called for those.
    if match(expand('%'), '_test.go$') == -1
        let makeprg = 'go build -o /dev/null'
    else
        let makeprg = 'go test -c -o /dev/null'
    endif
    let errorformat = '%f:%l:%c:%m,%f:%l%m,%-G#%.%#'

    " The go compiler needs to either be run with an import path as an
    " argument or directly from the package directory. Since figuring out
    " the poper import path is fickle, just pushd/popd to the package.
    let popd = getcwd()
    let pushd = expand('%:p:h')
    "
    " pushd
    exec 'lcd ' . fnameescape(pushd)

    let errors = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })

    " popd
    exec 'lcd ' . fnameescape(popd)

    return errors
endfunction
