" Location:     autoload/run.vim

" Section:      functions 

function! run#PromptCommand(current = "") " {{{

    return input("Compiler command: ", a:current, "file")

endfunction " }}}

function! run#SetCmdFiletype(ft, file, buffer = 1) " {{{

    " this looks ugly but I swear it's the only way to do it because we cannot
    " run empty() if the var don't exist and we only need to run the case if the
    " autoset is 1
    if g:Run_auto_set_cmd == 1

        if a:buffer

            if exists('b:Run_compiler_cmd')
                if !empty(b:Run_compiler_cmd)
                    return
                endif
            else
                let b:Run_compiler_cmd = ''
            endif

        else

            if exists('g:Run_compiler_cmd')
                if !empty(g:Run_compiler_cmd)
                    return
                endif
            else
                let g:Run_compiler_cmd = ''
            endif

        endif

    endif

    if !exists('b:Run_compiler_cmd') && a:buffer
        let b:Run_compiler_cmd = ''
    endif

    if !exists('g:Run_compiler_cmd') && !a:buffer
        let g:Run_compiler_cmd = ''
    endif

    if a:buffer
        let b:Run_compiler_cmd = get(g:Run_filetype_defaults, a:ft, b:Run_compiler_cmd)
        let b:Run_compiler_cmd = substitute(b:Run_compiler_cmd, "$#", a:file, "g")
    else
        let g:Run_compiler_cmd = get(g:Run_filetype_defaults, a:ft, g:Run_compiler_cmd)
        let g:Run_compiler_cmd = substitute(g:Run_compiler_cmd, "$#", a:file, "g")
    endif

endfunction " }}}

function! run#AutocmdSetFiletype(ft, file) "{{{
    if g:Run_auto_set_cmd_bufonly
        call run#SetCmdFiletype(a:ft, a:file, 1)
    else
        call run#SetCmdFiletype(a:ft, a:file, 0)
    endif
endfunction " }}}

function! run#Async(cmd = '') " {{{

    if !exists('g:run_async_jobs')
        let g:run_async_jobs = []
    endif

    if has('nvim')
        let job = jobstart(a:cmd)
    else
        let job = job_start(a:cmd)
    endif
    call add(g:run_async_jobs, job)

endfunction " }}}

function! run#ListAsyncComplete(A = '', L = '', P = '') " {{{
    if has('nvim')
        return run#ListAsyncCompleteNvim()
    else
        return run#ListAsyncCompleteVim()
    endif
endfunction

function! run#ListAsyncCompleteNvim()
    let l:r = []
    let l:ind = 0
    while l:ind < len(g:run_async_jobs)

        try
            let l:pid = jobpid(g:run_async_jobs[l:ind])
        catch *
            unlet g:run_async_jobs[l:ind]
            continue
        endtry

        call add(l:r, substitute(system('ps -q ' .. pid .. ' -o comm='), "\n", "", "g"))

        let l:ind += 1
    endwhile
    return l:r
endfunction

function! s:ActuallyList2Str(list = [])
    " i really dont belive i must implement it from scratch
    let l:ret = ""
    for l:str in a:list
        let l:ret ..= l:str
    endfor
    return l:ret
endfunction

function! run#ListAsyncCompleteVim()
    let l:r = []
    let l:ind = 0
    while l:ind < len(g:run_async_jobs)

        if job_status(g:run_async_jobs[l:ind]) == "dead"
            unlet g:run_async_jobs[l:ind]
            continue
        endif

        call add(l:r, s:ActuallyList2Str(job_info(g:run_async_jobs[l:ind])["cmd"]))

        let l:ind += 1
    endwhile
    return l:r
endfunction " }}}

function! run#ListAsync() " {{{

    " just reuse the other one
    for l:proc in run#ListAsyncComplete()
        echo l:proc
    endfor

endfunction " }}}

function! run#KillAsync(job) " {{{
    let l:ind = 0

    if has('nvim')
        while l:ind < len(g:run_async_jobs)

            let pid = jobpid(g:run_async_jobs[l:ind])

            if ( a:job.."\n" ) == system('ps -q '..pid..' -o comm=')
                call jobstop(g:run_async_jobs[l:ind])
                unlet g:run_async_jobs[l:ind]
                return
            endif

            let l:ind += 1
        endwhile

    else " vim

        while l:ind < len(g:run_async_jobs)
            if s:ActuallyList2Str(job_info(g:run_async_jobs[l:ind])["cmd"]) == a:job
                call job_stop(g:run_async_jobs[l:ind])
                unlet g:run_async_jobs[l:ind]
                return
            endif

            let l:ind += 1
        endwhile
    endif

    echoerr 'No such process running!'

endfunction " }}}

function! run#Run(args = '') " {{{

    let command=&shell

    if !empty(a:args)
        let command=a:args
    endif

    if exists('g:Run_run_before')
        execute g:Run_run_before
    endif

    if has('nvim')
        execute g:Run_runwin_cmd 'term://'command
        autocmd TermClose <buffer> bd
        normal a
    else
        if g:Run_runwin_vsp
            execute 'vert term ++close' command
        elseif g:Run_runwin_cur
            execute 'term ++close ++curwin' command
        else
            execute 'term ++close' command
        endif
    endif

endfunction " }}}

" if running on plain Vim, we remove the buftype of terminal of the run-compiler
" buffer so it won't be automatically wiped
if !has('nvim')
    function! run#ExitJobHandler(job = 0, status = 0)
        for l:bufr in getbufinfo()
            if getbufvar(l:bufr.bufnr, '&filetype') == 'run-compiler'
                call setbufvar(l:bufr.bufnr, '&buftype', '')
            endif
        endfor
    endfunction
endif

function! run#Compile(args = '') " Compile {{{

    " this block tests if we should run the buffer-local cmd or the global one
    "
    " buffer-local: if have a valid buffer-local value and no arguments
    " global:       if don't, and then checks to see if have a valid global one,
    " and if not, sets it with the run#PromptCommand
    if !empty(a:args)
        let g:Run_compiler_cmd = a:args
        let l:cmd = g:Run_compiler_cmd
    else
        if exists('b:Run_compiler_cmd') && !empty(b:Run_compiler_cmd)
                let l:cmd = b:Run_compiler_cmd
        else
            if !exists('g:Run_compiler_cmd') || empty(g:Run_compiler_cmd)
                let g:Run_compiler_cmd = run#PromptCommand("")
            endif

            if empty(g:Run_compiler_cmd)
                return
            else
                let l:cmd = g:Run_compiler_cmd
            endif
        endif
    endif

    " kill an possibly already-running compilation
    for l:bufr in getbufinfo()
        if getbufvar(l:bufr.bufnr, '&filetype') == 'run-compiler'
            execute 'bdelete' l:bufr.bufnr
        endif
    endfor

    if exists('g:Run_compile_before')
        execute g:Run_compile_before
    endif

    if has('nvim')
        execute g:Run_compilewin_cmd 'term://'l:cmd
        autocmd TermClose <buffer> call feedkeys("\<C-\>\<C-n>")
        normal a
    else
        call term_start([&shell, '-c', l:cmd..' ; echo -e "\n[Process exited $?]"'], {'exit_cb': function('run#ExitJobHandler'), 'term_finish': 'open', 'curwin': g:Run_compilewin_cur, 'vertical': g:Run_compilewin_vsp})
    endif
    set filetype=run-compiler

endfunction " }}}

function! run#CompileBuffer(cmd = '') "{{{
    if !exists('b:Run_compiler_cmd') || empty(b:Run_compiler_cmd)
        let b:Run_compiler_cmd = run#PromptCommand("")
    endif
    Compile
endfunction " }}}

function! run#CompileReset(buffer = 0) " {{{

    if !a:buffer
        if !exists('g:Run_compiler_cmd')
            let g:Run_compiler_cmd = ""
        endif
        let g:Run_compiler_cmd = run#PromptCommand(g:Run_compiler_cmd)
        Compile
    else
        if !exists('b:Run_compiler_cmd')
            let b:Run_compiler_cmd = ""
        endif
        let b:Run_compiler_cmd = run#PromptCommand(b:Run_compiler_cmd)
        CompileBuffer
    endif

endfunction " }}}

function! run#CompileAuto(buffer) " {{{
    if a:buffer
        let b:Run_compiler_cmd = ''
    else
        let g:Run_compiler_cmd = ''
    endif
    call run#SetCmdFiletype(getbufvar(bufnr('%'), '&filetype'), bufname(bufnr('%')), a:buffer)
    Compile
endfunction " }}}

function! run#Execute(args = '') " Execute {{{
    if empty(a:args)
        if !(exists('g:Run_execute_cmd') && !empty(g:Run_execute_cmd))
            echo 'No execute command set'
            return
        endif
    else
        let g:Run_execute_cmd = a:args
    endif

    execute g:Run_execute_cmd
endfunction " }}}
