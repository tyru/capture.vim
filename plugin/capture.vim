" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if (exists('g:loaded_capture') && g:loaded_capture) || &cp
    finish
endif
let g:loaded_capture = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let g:capture_open_command = get(g:, 'capture_open_command', 'belowright new')


function! s:cmd_capture(q_args) "{{{
    if a:q_args =~# '^[ :]*!'
        let args   = substitute(a:q_args, '^[ :]*!', '', '')
        let output = system(args)
    else
        redir => output
        silent execute a:q_args
        redir END
        let output = substitute(output, '^\n\+', '', '')
    endif

    silent execute g:capture_open_command

    let bufname = s:create_unique_capture_bufname(a:q_args)
    silent file `=bufname`
    setlocal buftype=nofile bufhidden=unload noswapfile nobuflisted
    call setline(1, split(output, '\n'))
endfunction "}}}

function! s:create_unique_capture_bufname(q_args)
    let fmt = '[Capture #%d: "'.a:q_args.'"]'
    let i = 0
    let bufname = printf(fmt, i)
    while bufexists(bufname)
        let i += 1
        let bufname = printf(fmt, i)
    endwhile
    return bufname
endfunction


command!
\   -nargs=+ -complete=command
\   Capture
\   call s:cmd_capture(<q-args>)


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
