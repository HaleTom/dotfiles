"=============================================================================
" FILE: vba.vim
" AUTHOR:  Yu Huang <paulhybryant@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Global options definition. "{{{
call neobundle#util#set_default(
      \ 'g:neobundle#types#vba#calc_hash_command',
      \ executable('sha1sum') ? 'sha1sum' :
      \ executable('md5sum') ? 'md5sum' : '')
"}}}

function! neobundle#types#vba#define() "{{{
  return s:type
endfunction"}}}

let s:type = {
      \ 'name' : 'vba',
      \ }

function! s:type.detect(path, opts) "{{{
  " No auto detect.
  let type = ''
  let name = ''

  if a:path =~# '^https:.*\.vba\(\.gz\)\?$'
    " HTTPS
    " .*.vba / .*.vba.gz
    let name = fnamemodify(split(a:path, ':')[-1],
          \ ':s?/$??:t:s?\c\.vba\(\.gz\)*\s*$??')
    let type = 'vba'
  endif

  return type == '' ?  {} :
        \ { 'name': name, 'uri' : a:path, 'type' : type }
endfunction"}}}
function! s:type.get_sync_command(bundle) "{{{
  let path = a:bundle.path

  if !isdirectory(path)
    " Create script type directory.
    call mkdir(path, 'p')
  endif

  let filename = path . '/' . get(a:bundle,
        \ 'type__filename', fnamemodify(a:bundle.uri, ':t'))
  let a:bundle.type__filepath = filename

  if executable('curl')
    let cmd = printf('curl --fail -s -o "%s" "%s" && ', filename, a:bundle.uri)
  elseif executable('wget')
    let cmd = printf('wget -q -O "%s" "%s" && ', filename, a:bundle.uri)
  else
    return 'E: curl or wget command is not available!'
  endif
  let cmd .= printf(' %s -u NONE' .
        \ ' -c "set nocompatible"' .
        \ ' -c "filetype plugin on"' .
        \ ' -c "runtime plugin/gzip.vim"' .
        \ ' -c "runtime plugin/vimballPlugin.vim"' .
        \ ' -c "edit %s"' .
        \ ' -c "UseVimball %s"' .
        \ ' -c "q"', v:progpath, filename, path)
  " let cmd .= printf(' rm %s &&', filename)
  " let cmd .= printf(' rm %s/.VimballRecord', path)

  return cmd
endfunction"}}}
function! s:type.get_revision_number_command(bundle) "{{{
  if g:neobundle#types#vba#calc_hash_command == ''
    return ''
  endif

  if !has_key(a:bundle, 'type__filepath') || !filereadable(a:bundle.type__filepath)
    " Not Installed.
    return ''
  endif

  " Calc hash.
  return printf('%s %s',
        \ g:neobundle#types#vba#calc_hash_command,
        \ a:bundle.type__filepath)
endfunction"}}}
function! s:type.get_revision_lock_command(bundle) "{{{
  let new_rev = matchstr(a:bundle.new_rev, '^\S\+')
  if a:bundle.rev != '' && new_rev != '' &&
        \ new_rev !=# a:bundle.rev
    " Revision check.
    return printf('E: revision digest is not matched : "%s"(got) and "%s"(rev).',
          \ new_rev, a:bundle.rev)
  endif

  " Not supported.
  return ''
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
