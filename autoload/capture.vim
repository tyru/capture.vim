" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:is_mswin = has('win16') || has('win95') || has('win32') || has('win64')
let g:capture_open_command = get(g:, 'capture_open_command', 'belowright new')

let s:running = 0

function! capture#__cmd_capture_stub__(...) abort
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

function! s:cmd_capture(q_args, createbuf) abort
  try
    " Get rid of cosmetic characters.
    let q_args = a:q_args
    let q_args = substitute(q_args, '^[\t :]+', '', '')
    let q_args = substitute(q_args, '\s+$', '', '')
    let output = s:get_output(q_args)
    call s:write_buffer(output, q_args, a:createbuf)
    " Save executed commands.
    if exists('b:capture_commands')
      call add(b:capture_commands, q_args)
    else
      let b:capture_commands = [q_args]
    endif
  catch
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry
endfunction

function! s:get_output(q_args) abort
  let q_args = a:q_args
  if q_args !=# '' && q_args[0] ==# '!'
    let args = substitute(q_args, '^[ :]*!', '', '')
    return iconv(system(args), 'char', &encoding)
  elseif has('*execute')
    return execute(q_args)
  else
    let throwpoint = 0
    try
      let throwpoint = 1
      redir => output
      let throwpoint = 2
      silent execute q_args
    catch /^capture: nested$/
      throw ':Capture cannot be nested due to Vim :redir limitation'
    catch
      if throwpoint is 1
        redir END
        throw 'capture: nested :redir cannot work'
      else " if throwpoint is 2
        throw 'capture: ''' . q_args . ''' => ' . v:exception
      endif
    finally
      redir END
    endtry
    let output = substitute(output, '^\n\+', '', '')
    " Get rid of eol character.
    let eol_char = matchstr(&listchars, 'eol:\zs.\ze')
    if eol_char !=# ''
      let eol_char = escape(eol_char, '\')
      let output = substitute(output, '\V' . eol_char . '\v\ze[\r\n]+', '', '')
    endif
    return output
  endif
endfunction


function! s:write_buffer(output, q_args, createbuf) abort
  let capture_winnr = s:get_capture_winnr()
  let override_buffer = s:get_override_buffer(a:createbuf, capture_winnr)
  if override_buffer ==# 'appendwin'
    call s:write_buffer_appendwin(a:output, a:q_args, capture_winnr)
  else    " override_buffer ==# 'newbufwin'
    call s:write_buffer_newbufwin(a:output, a:q_args)
  endif
endfunction

" Append output to existing capture window's buffer.
function! s:write_buffer_appendwin(output, q_args, capture_winnr) abort
  " Jump to existing capture window.
  execute a:capture_winnr 'wincmd w'
  " Format existing buffer.
  if len(b:capture_commands) is 1
    1put! =b:capture_commands[0].':'
    " Rename buffer name.
    call s:name_append_bufname(b:capture_commands + [a:q_args])
  endif
  " Append new output.
  let lines = ['', a:q_args.':'] + split(a:output, '\n')
  call setline(line('$') + 1, lines)
endfunction

" Insert output to new capture buffer & window.
function! s:write_buffer_newbufwin(output, q_args) abort
  try
    call s:create_capture_buffer(a:q_args)
  catch
    throw 'capture: could not create capture buffer: ' . v:exception
  endtry
  " Set command output.
  call setline(1, split(a:output, '\n'))
endfunction

function! s:get_override_buffer(createbuf, capture_winnr) abort
  if !a:createbuf && a:capture_winnr ># 0
    return 'appendwin'
  else
    return 'newbufwin'
  endif
endfunction

function! s:get_capture_winnr() abort
  " Current window has higher priority
  " than other windows.
  for nr in [winnr()] + range(1, winnr('$'))
    if getwinvar(nr, '&filetype') ==# 'capture'
      return nr
    endif
  endfor
  return -1
endfunction

function! s:create_capture_buffer(q_args) abort
  silent execute g:capture_open_command
  call s:name_first_bufname(a:q_args)
  setlocal buftype=nofile bufhidden=unload noswapfile nobuflisted
  setfiletype capture
endfunction

function! s:name_first_bufname(q_args) abort
  " Get rid of invalid characters of buffer name on MS Windows.
  let q_args = a:q_args
  if s:is_mswin
    let q_args = substitute(q_args, '[?*\\]', '_', 'g')
  endif
  " Generate a unique buffer name.
  let bufname = s:generate_unique_bufname(q_args)
  let b:capture_bufnamenr = bufname.nr
  " NOTE: Can not use double-quote for ':file' arguments.
  silent file `=substitute(bufname.bufname, '"', "'", 'g')`
endfunction

function! s:name_append_bufname(commands) abort
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
  " NOTE: Can not use double-quote for ':file' arguments.
  silent file `=substitute(bufname.bufname, '"', "'", 'g')`
endfunction

function! s:generate_unique_bufname(string) abort
  let nr = get(b:, 'capture_bufnamenr', 0)
  let bufname = '[Capture #'.nr.' "'.a:string.'"]'
  while bufexists(bufname)
    let nr += 1
    let bufname = '[Capture #'.nr.': "'.a:string.'"]'
  endwhile
  return {'nr': nr, 'bufname': bufname}
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
