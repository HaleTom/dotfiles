" sourced at beginning of vimrc

""""""""""""""""" Begin neobundle """""""""""""""""""""
" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

if has('vim_starting')
  if &compatible
    set nocompatible               " Be iMproved
  endif

" Required:
  set runtimepath+=$VIMFILES/bundle/neobundle.vim/
endif

" for vundle but not required for neobundle
" filetype off

" Required:
call neobundle#begin(expand($VIMFILES."/bundle"))

" Required: Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'
 
" My Bundles here:
" Refer to |:NeoBundle-examples|.
" Note: You don't set neobundle setting in .gvimrc!

" github repos
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'haya14busa/incsearch.vim'
NeoBundle 'tpope/vim-bundler.git'
NeoBundle 'tpope/vim-rails.git'
NeoBundle 'tpope/vim-rake.git'
NeoBundle 'tpope/vim-projectionist'
NeoBundle 'tpope/vim-fugitive'
" 
" surround.vim: quoting/parenthesizing made simple
NeoBundle 'tpope/vim-surround' " 
 
" repeat.vim: enable repeating supported NeoBundle maps with "."
NeoBundle 'tpope/vim-repeat' " 

""""""""NeoBundle 'msanders/snipmate.vim'

NeoBundle 'majutsushi/tagbar'
" http://vimawesome.com/plugin/jellybeans-vim
NeoBundle 'nanotech/jellybeans.vim'
" http://vimawesome.com/plugin/vim-css-color-the-story-of-us
NeoBundle 'ap/vim-css-color'
" http://vimawesome.com/plugin/rainbow-parentheses-vim 
NeoBundle 'kien/rainbow_parentheses.vim'
 
" Visual grouping of indented lines
" http://vimawesome.com/plugin/indent-guides
NeoBundle 'nathanaelkane/vim-indent-guides'

" Fuzzy file, buffer, mru, tag, etc finder
" http://kien.github.io/ctrlp.vim/
NeoBundle 'kien/ctrlp.vim' " 
" 
" simplifies the transition between multiline and single-line code
" gS split / gJ join
NeoBundle 'AndrewRadev/splitjoin.vim' " 

NeoBundle 'vim-scripts/taglist.vim'
" http://www.vim.org/scripts/script.php?script_id=273 is newer
" but NeoBundle 'taglist' hangs :(

" An extensible & universal comment vim-NeoBundle that also handles embedded filetypes
" Supports nested quotes and vim movement
NeoBundle 'tomtom/tcomment_vim' " https://github.com/vim-scripts/tComment

" Solarized colorscheme
" http://ethanschoonover.com/solarized
NeoBundle 'altercation/vim-colors-solarized' " 

" Vim motions on speed! 
NeoBundle 'easymotion/vim-easymotion' " https://github.com/easymotion/vim-easymotion

" UltiSnips - The ultimate snippet solution for Vim
NeoBundle 'SirVer/ultisnips' " https://github.com/SirVer/ultisnips

" Snippets are separated from the engine.
NeoBundle 'honza/vim-snippets' " 

" supertab is used to have both ultisnips and YCM working at the same time
NeoBundle 'ervandew/supertab' " https://github.com/ervandew/supertab

" Access branched undo versions
" http://sjl.bitbucket.org/gundo.vim/
NeoBundle 'sjl/gundo.vim' " https://github.com/sjl/gundo.vim

" Silver searcher (speed up CtrlP list time)
" https://blog.kowalczyk.info/software/the-silver-searcher-for-windows.html
" Vim plugin for the_silver_searcher, 'ag', a replacement for the Perl module / CLI script 'ack'
NeoBundle 'rking/ag.vim' " https://github.com/rking/ag.vim

"NeoBundle '' " 

"NeoBundle '' " 

"NeoBundle '' " 

"NeoBundle '' " 

" vim-scripts repos
"NeoBundle 'TagList'

" non github repos
"NeoBundle 'git://git.wincent.com/command-t.git'
   
call neobundle#end()         " required
filetype plugin indent on    " required as turned off above

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

" Brief help
" :PluginUpdate        - update plugins
" :PluginList          - list configured plugins
" :PluginInstall(!)    - install (update) plugins
" :PluginSearch(!) foo - search (or refresh cache first) for foo
" :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"
" see :h vundle for more details or wiki for FAQ
""""""""""""""""" End neobundle """""""""""""""""""""
