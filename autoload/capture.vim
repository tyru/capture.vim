" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:is_mswin = has('win16') || has('win95') || has('win32') || has('win64')
let g:capture_open_command = get(g:, 'capture_open_command', 'belowright split')

let s:running = 0

function! capture#__cmd_capture_stub__(...)
    if s:running
        throw 'capture: nested'
    endif
    try
        let s:running = 1
        return call('s:cmd_capture', a:000)
    finally
        let s:running = 0
    endtry
endfunction

function! s:cmd_capture(q_args, createbuf)
    " Get rid of cosmetic characters.
    let q_args = a:q_args
    let q_args = substitute(q_args, '^[\t :]+', '', '')
    let q_args = substitute(q_args, '\s+$', '', '')

    if q_args !=# '' && q_args[0] ==# '!'
        let args   = substitute(q_args, '^[ :]*!', '', '')
        let output = system(args)
    else
        let throwpoint = 0
        try
            let throwpoint = 1
            redir => output
            let throwpoint = 2
            silent execute q_args
        catch /^capture: nested$/
            call s:error(':Capture cannot be nested due to Vim :redir limitation.')
            return
        catch
            if throwpoint is 1
                call s:error('capture: nested :redir cannot work')
                redir END
            else " if throwpoint is 2
                call s:error("capture: '".q_args."' caused an error: ".v:exception)
            endif
            return
        finally
            redir END
        endtry
        let output = substitute(output, '^\n\+', '', '')
    endif

    let capture_winnr = s:get_capture_winnr()
    if !a:createbuf && capture_winnr ># 0
        " Jump to existing capture window.
        execute capture_winnr 'wincmd w'
        " Format existing buffer.
        if len(b:capture_commands) is 1
            " NOTE: ':put' doesn't ignore comment string ("),
            " so don't use it in expression!
            setlocal noreadonly
            1put! =b:capture_commands[0].':'
            setlocal readonly
            " Rename buffer name.
            call s:name_append_bufname(b:capture_commands + [q_args])
        endif
        " Append new output.
        let lines = ["", q_args.":"] + split(output, '\n')
        setlocal noreadonly
        call setline(line('$') + 1, lines)
        setlocal readonly
    else
        " Create new capture buffer & window.
        try
            call s:create_capture_buffer(q_args)
        catch
            call s:error("capture: could not create capture buffer: ".v:exception)
            return
        endtry
        " Set command output.
        setlocal noreadonly
        call setline(1, split(output, '\n'))
        setlocal readonly
    endif
    " Save executed commands.
    if exists('b:capture_commands')
        call add(b:capture_commands, q_args)
    else
        let b:capture_commands = [q_args]
    endif
endfunction

function! s:get_capture_winnr()
    " Current window has higher priority
    " than other windows.
    for nr in [winnr()] + range(1, winnr('$'))
        if getwinvar(nr, '&filetype') ==# 'capture'
            return nr
        endif
    endfor
    return -1
endfunction

function! s:create_capture_buffer(q_args)
    silent execute g:capture_open_command
    call s:name_first_bufname(a:q_args)
    setlocal buftype=nofile bufhidden=unload noswapfile nobuflisted
    setfiletype capture
endfunction

function! s:name_first_bufname(q_args)
    " Get rid of invalid characters of buffer name on MS Windows.
    let q_args = a:q_args
    if s:is_mswin
        let q_args = substitute(q_args, '[?*\\]', '_', 'g')
    endif
    " Generate a unique buffer name.
    let bufname = s:generate_unique_bufname(q_args)
    let b:capture_bufnamenr = bufname.nr
    call s:set_bufname(bufname.bufname)
endfunction

function! s:name_append_bufname(commands)
    let firstcmd = '^[a-zA-Z][a-zA-Z0-9_]\+\ze'
    let cmdlist = ''
    for cmd in a:commands[:1]
        let cmdlist .=
        \   (cmdlist ==# '' ? '' : ',') .
        \   matchstr(cmd, firstcmd)
    endfor
    let cmdlist .= ',...'
    " Generate a unique buffer name.
    let bufname = s:generate_unique_bufname(cmdlist)
    let b:capture_bufnamenr = bufname.nr
    call s:set_bufname(bufname.bufname)
endfunction

function! s:generate_unique_bufname(string)
    let nr = get(b:, 'capture_bufnamenr', 0)
    let bufname = '[Capture #'.nr.' "'.a:string.'"]'
    while bufexists(bufname)
        let nr += 1
        let bufname = '[Capture #'.nr.': "'.a:string.'"]'
    endwhile
    return {'nr': nr, 'bufname': bufname}
endfunction

function! s:set_bufname(bufname)
    " Avoid |backtick-expansion|.
    let bufnr = bufnr(a:bufname)
    if bufnr == -1
        enew
        " NOTE: Can not use the (") for ':file'
        file `=substitute(a:bufname, '"', "'", 'g')`
    else
        execute bufnr 'buffer'
    endif
endfunction

function! s:error(msg)
    try
        echohl ErrorMsg
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
