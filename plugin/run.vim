" Title:        run.vim
" Description:  Automate compiling and running for Vim
" Last Change:  4 September 2022
" Mainteiner:   Gabriel G. de Brito https://github.com/gboncoffee
" Location:     plugin/run.vim

if exists('g:autoloaded_run')
    finish
endif

let g:autoloaded_run = 1

" Section:      config

if has('nvim')
    if !exists('g:Run_runwin_cmd')
        let g:Run_runwin_cmd = 'split'
    endif

    if !exists('g:Run_compilewin_cmd')
        let g:Run_compilewin_cmd = 'split'
    endif
else
    if !exists('g:Run_compilewin_vsp')
        let g:Run_compilewin_vsp = 0
    endif
    if !exists('g:Run_compilewin_cur')
        let g:Run_compilewin_cur = 0
    endif
    if !exists('g:Run_runwin_vsp')
        let g:Run_runwin_vsp = 0
    endif
    if !exists('g:Run_runwin_cur')
        let g:Run_runwin_cur = 0
    endif
endif

if !exists('g:Run_auto_set_cmd')
    let g:Run_auto_set_cmd = 0
endif

if !exists('g:Run_auto_set_cmd_bufonly')
    let g:Run_auto_set_cmd_bufonly = 1
endif

function! RunGetDefaultCompilers() " {{{
    " we use $# as a placeholder for the matching file by arbitrary choice and
    " because I think one never would want to use it for other purpouse.
    return { 
                \ 'rust':       'cargo test',
                \ 'go':         'go run',
                \ 'java':       'mvn clean test',
                \ 'typescript': 'tsc -p package.json',
                \ 'coffee':     'coffee -c $#',
                \ 'ruby':       'bin/rails test',
                \ 'php':        './vendor/bin/phpunit tests',
                \ 'scdoc':      'scdoc < $# > $#.1',
                \ 'markdown':   'markdown $# > $#.html',
                \ 'tex':        'pdflatex $#',
                \ 'javascript': 'node $#',
                \ 'julia':      'julia $#',
                \ 'python':     'python $#',
                \ 'lua':        'lua $#',
                \ 'sh':         'sh $#',
                \ 'perl':       'perl $#',
                \ 'pascal':     'fpc $#',
                \ 'c':          'make',
                \ 'cpp':        'make',
                \ 'fortran':    'make',
                \ 'asm':        'make',
                \ 'make':       'make',
                \ }
endfunction " }}}

if !exists('g:Run_filetype_defaults')
    let g:Run_filetype_defaults = RunGetDefaultCompilers()
endif

" Section:      commands

command! -complete=file     -nargs=* Run                 call run#Run(<q-args>)
command! -complete=file     -nargs=* Compile             call run#Compile(<q-args>)
command! -complete=file     -nargs=* CompileBuffer       call run#CompileBuffer(<q-args>)
command! -complete=file     -nargs=* CompileReset        call run#CompileReset()
command! -complete=file     -nargs=* CompileBufferReset  call run#CompileReset(1)
command! -complete=file     -nargs=* CompileAuto         call run#CompileAuto(0)
command! -complete=file     -nargs=* CompileAutoBuffer   call run#CompileAuto(1)
command! -complete=command  -nargs=* Execute             call run#Execute(<q-args>)
command! -complete=file     -nargs=* Async               call run#Async(<q-args>)
command!                             AsyncList           call run#ListAsync()
command! -complete=customlist,run#ListAsyncComplete -nargs=* AsyncKill call run#KillAsync(<q-args>)

" Section:      autocmds

if g:Run_auto_set_cmd
    augroup Run
        autocmd!
        autocmd FileType * call run#AutocmdSetFiletype(expand('<amatch>'), expand('<afile>'))
    augroup END
endif
