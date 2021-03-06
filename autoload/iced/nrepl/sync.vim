let s:save_cpo = &cpo
set cpo&vim

let s:sync_resp = v:none
let s:default_timeout_ms = 500

function! s:sync(resp) abort
  let s:sync_resp = a:resp
endfunction

function! iced#nrepl#sync#send(data) abort
  let data = copy(a:data)
  let data.callback = funcref('s:sync')
  let s:sync_resp = v:none

  let timeout_ms = s:default_timeout_ms
  if has_key(data, 'timeout')
    let timeout_ms = data['timeout']
    unlet data['timeout']
  endif

  call iced#nrepl#send(data)
  call iced#util#wait({-> empty(s:sync_resp)}, timeout_ms)

  return s:sync_resp
endfunction

function! iced#nrepl#sync#clone(session) abort
  let resp = iced#nrepl#sync#send({
      \ 'op': 'clone',
      \ 'session': a:session
      \ })
  return get(resp, 'new-session', v:none)
endfunction

function! iced#nrepl#sync#close(session) abort
  return iced#nrepl#sync#send({
      \ 'op': 'close',
      \ 'session': a:session
      \ })
endfunction

function! iced#nrepl#sync#session_list() abort
  let resp = iced#nrepl#sync#send({'op': 'ls-sessions'})
  return get(resp, 'sessions', [])
endfunction

call iced#nrepl#register_handler('ls-sessions')
call iced#nrepl#register_handler('close')

let &cpo = s:save_cpo
unlet s:save_cpo
