# run.vim

Simple compiling and testing automation for Vim and Neovim.
# Install

Use your favorite Vim or Neovim package manager.

# Usage

The plugin defines some commands, which the most important are: `Run`,
`Compile`, `Execute` and `Async`. For a complete list see `:h run.vim`.

The plugin can be used in the global namespace (with global variables) or in the
buffer-local namespace (with buffer varibles). Read `:h run.vim` to see how to
use the buffer-local commands and how they behave.

## Run

`Run` will start a process on the `terminal`. Automatically enter terminal mode
and close the window when the process ends. You may use args to define a process
(for example, `Run python` will start a Python repl), and, if called without
args, it will default to the `shell` Vim variable.

## Compile

`Compile` will start a process like `Run`, but will leave the terminal buffer
(if one) opened when finished.

The main difference it's that when calling `Compile` with args, it'll set the
variable `g:Run_compile_cmd` to them, and if calling it without args, it'll run
whatever is in that variable.

This way, you can set the compiling command only once within a session. After
that, you can simply use `Compile` to run the same command again.

If the command is runned and `g:Run_compile_cmd` is empty or don't exist, the
user will be prompted with a command to set `g:Run_compile_cmd` to.

## Execute

`Execute` offers the same workflow from the `Compile` command, but for
executing Vim Script commands (normal Ex commands). It uses the variable
`g:Run_execute_cmd` instead, too.

## Async

`Async` run a command without any terminal, like using :!, but without
freezing the editor.

## AsyncList

`AsyncList` lists the processes openend by `Async`.

## AsyncKill

`AsyncKill` kills a process opened by `Async`.

## Settings

To specify a default compiling command, simply set `g:Run_compile_cmd` to
whatever you want on your Vim or Neovim config file.

On Neovim can also use `g:Run_runwin_cmd` and `g:Run_compilewin_cmd` to specify the
Vim command to open the terminal window for each command of run.vim: either
`split` (the default for both), `vsplit` or `tabnew`.

On Vim, you can use `g:Run_runwin_vsp`, `g:Run_runwin_cur`,
`g:Run_compilewin_vsp` and `g:Run_compilewin_cur` to specify if the terminal
should be opened vertically or in the same window.

### Automatically set command

The variable `g:Run_filetype_defaults` is a dictionary with default
compilation commands for different filetypes. This dictionary have a default
value returned by the function `RunGetDefaultCompilers`. The variable
`g:Run_auto_set_cmd` controls how the dictionary keys will be used to
automatically set `g:Run_compiler_cmd` on `FileType` events.

If `g:Run_auto_set_cmd` is 0, no auto-setting is done. If 1, auto-setting is
done only if `g:Run_compiler_cmd` is empty or don't exist and if any other
value, the command will be automatically set on every `FileType` event.

This dictionary have keys as `filetype` entries and values as their respective
compilation commands. The placeholder `$#` is used to represent the file
matched by the `FileType` event.

As a configuration example, one could use the default dictionary but overwrite
only the `javascript` filetype (defaults to `node $#`) this way in one's `vimrc` or `init.vim`:

`let g:Run_filetype_defaults=RunGetDefaultCompilers()`
`let g:Run_filetype_defaults['javascript']='deno $#'`
