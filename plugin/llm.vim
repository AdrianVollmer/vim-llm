" llm.vim - Interface to the llm command-line tool
" Maintainer: Auto-generated
" Version: 1.0

if exists('g:loaded_llm')
  finish
endif
let g:loaded_llm = 1

let s:save_cpo = &cpo
set cpo&vim

" Configuration: Enable line wrap in diff views (default: 1)
if !exists('g:llm_diff_wrap')
  let g:llm_diff_wrap = 1
endif

" Configuration: Path to the llm command (default: 'llm')
if !exists('g:llm_command')
  let g:llm_command = 'llm'
endif

" Main command: :Llm <template> [<prompt>...]
command! -range=% -nargs=+ -complete=customlist,s:CompleteTemplates Llm
      \ call s:ExecuteLlm(<line1>, <line2>, <f-args>)

" Get list of available templates for tab completion
function! s:CompleteTemplates(ArgLead, CmdLine, CursorPos) abort
  let l:templates_output = system(g:llm_command . ' templates list 2>/dev/null')
  if v:shell_error != 0
    return []
  endif

  let l:templates = []
  for l:line in split(l:templates_output, "\n")
    let l:template = matchstr(l:line, '^\s*\zs\S\+')
    if !empty(l:template) && l:template !~ '^-'
      call add(l:templates, l:template)
    endif
  endfor

  return filter(l:templates, 'v:val =~ "^" . a:ArgLead')
endfunction

" Execute llm command with visual selection as input
function! s:ExecuteLlm(line1, line2, ...) abort
  if a:0 < 1
    echoerr 'Usage: :llm <template> [<prompt>...]'
    return
  endif

  let l:template = a:1
  let l:prompt = a:0 > 1 ? join(a:000[1:], ' ') : ''

  " Get the selected lines
  let l:lines = getline(a:line1, a:line2)
  let l:input = join(l:lines, "\n")

  " Build the llm command
  let l:cmd = g:llm_command . ' -t ' . shellescape(l:template)
  if !empty(l:prompt)
    let l:cmd .= ' ' . shellescape(l:prompt)
  endif

  " Execute llm with input
  let l:output = system(l:cmd, l:input)

  if v:shell_error != 0
    echoerr 'llm command failed: ' . l:output
    return
  endif

  " Clear command line and redraw to avoid "Press ENTER" prompt
  redraw

  " Present the diff
  call s:ShowDiff(l:lines, split(l:output, "\n", 1), a:line1, a:line2)
endfunction

" Show diff and allow accepting hunks
function! s:ShowDiff(original, modified, line1, line2) abort
  " Store current buffer info
  let l:current_buf = bufnr('%')
  let l:current_win = win_getid()

  " Enable diff mode on current buffer (original on left)
  diffthis

  " Set line wrap if configured
  if g:llm_diff_wrap
    setlocal wrap
  endif

  " Create vertical split on the right with a new buffer
  rightbelow vnew

  " Copy entire content from original buffer
  let l:lines = getbufline(l:current_buf, 1, '$')
  call setline(1, l:lines)

  " Replace the selected lines with llm output
  if a:line1 == a:line2 && len(a:modified) == 1 && a:modified[0] == ''
    " Special case: empty output, just delete the lines
    execute a:line1 . ',' . a:line2 . 'delete _'
  else
    " Delete original selection
    execute a:line1 . ',' . a:line2 . 'delete _'
    " Insert modified lines
    call append(a:line1 - 1, a:modified)
    " Remove extra blank line if present
    if a:line1 + len(a:modified) - 1 <= line('$') &&
          \ getline(a:line1 + len(a:modified) - 1) == ''
      execute (a:line1 + len(a:modified) - 1) . 'delete _'
    endif
  endif

  " Set up the modified buffer
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  file [LLM\ Proposal]

  " Enable diff mode on the new buffer
  diffthis

  " Set line wrap if configured
  if g:llm_diff_wrap
    setlocal wrap
  endif

  " Store the buffer numbers for diffget/diffput
  let l:modified_bufnr = bufnr('%')

  " Store information for accepting changes
  let b:llm_original_buf = l:current_buf
  let b:llm_original_win = l:current_win
  let b:llm_modified_bufnr = l:modified_bufnr

  " Create commands for the diff buffer
  command! -buffer LlmAcceptAll call s:AcceptAllChanges()
  command! -buffer LlmAcceptHunk call s:AcceptHunk()
  command! -buffer LlmClose call s:CloseDiff()

  " Create key mappings for easier navigation
  nnoremap <buffer> <silent> dp :LlmAcceptHunk<CR>
  nnoremap <buffer> <silent> <Leader>a :LlmAcceptAll<CR>
  nnoremap <buffer> <silent> <Leader>q :LlmClose<CR>

  " Return focus to the original buffer
  call win_gotoid(l:current_win)

  " Clear command line to avoid "Press ENTER" prompt
  redraw!
endfunction

" Close the diff view
function! s:CloseDiff() abort
  let l:original_win = exists('b:llm_original_win') ? b:llm_original_win : 0
  let l:original_buf = exists('b:llm_original_buf') ? b:llm_original_buf : 0

  " Close the proposal buffer
  close

  " Disable diff mode in original window
  if l:original_win != 0 && win_id2win(l:original_win) > 0
    call win_gotoid(l:original_win)
    diffoff
  endif

  echo 'Diff closed'
endfunction

" Accept a single hunk under cursor (put to original buffer)
function! s:AcceptHunk() abort
  if !exists('b:llm_original_buf')
    echoerr 'Not in LLM diff view'
    return
  endif

  " Use vim's built-in diffput to push the hunk to the original buffer
  execute 'diffput' b:llm_original_buf

  echo 'Hunk pushed to original. Use ]c to go to next hunk, or :LlmAcceptAll to accept all remaining.'
endfunction

" Accept all changes and close diff
function! s:AcceptAllChanges() abort
  if !exists('b:llm_original_buf')
    echoerr 'No LLM changes to accept'
    return
  endif

  let l:original_buf = b:llm_original_buf
  let l:original_win = b:llm_original_win

  " Get current content of the proposal buffer
  let l:all_lines = getline(1, '$')

  " Switch to original buffer and replace content using change commands
  if win_id2win(l:original_win) > 0
    call win_gotoid(l:original_win)
  endif

  " Use proper vim commands to maintain undo history
  let l:last_line = line('$')
  let l:new_last_line = len(l:all_lines)

  " Change existing lines
  for l:i in range(1, min([l:last_line, l:new_last_line]))
    call setline(l:i, l:all_lines[l:i - 1])
  endfor

  " Add or remove lines as needed
  if l:new_last_line > l:last_line
    " Add remaining lines
    call append(l:last_line, l:all_lines[l:last_line :])
  elseif l:new_last_line < l:last_line
    " Delete extra lines
    execute (l:new_last_line + 1) . ',' . l:last_line . 'delete _'
  endif

  " Close the proposal buffer
  let l:proposal_win = bufwinnr('[LLM Proposal]')
  if l:proposal_win > 0
    execute l:proposal_win . 'close'
  endif

  " Turn off diff mode
  diffoff

  echo 'All changes accepted'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
