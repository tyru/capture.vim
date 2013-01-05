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


command!
\   -nargs=+ -complete=command -bang
\   Capture
\   call capture#__cmd_capture_stub__(<q-args>, <bang>0)


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
