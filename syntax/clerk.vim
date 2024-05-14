" Vim syntax file
" Language:        Clerk
" Maintainer:       Gareth Rogers <gareth@gtrogers.com> 
" Last Change:        2024 May 13
" Remark:        This is a work in progress

if exists("b:current_syntax")
  finish
endif

:syntax clear

:syntax region clerkTodo start=/\. / end=/$/
:syntax region clerkGroup start=/\:\: / end=/$/
:syntax region clerkDone start=/x / end=/$/
:syntax match clerkDoingGlyph />/ contained
:syntax region clerkDoing start=/> / end=/$/ contains=clerkDoingGlyph
:syntax match clerkCancelledGlyph /\~/ contained
:syntax region clerkCancelled start=/\~ / end=/$/ contains=clerkCancelledGlyph
:syntax region clerkMonitoring start=/? / end=/$/
:syntax region clerkShelved start=/\/ / end=/$/

" Now
:highlight link clerkDoing Statement
:highlight link clerkMonitoring Statement
:highlight link clerkDoingGlyph Todo

" Next
:highlight link clerkTodo Comment
:highlight link clerkSheleved Comment

" Done
:highlight link clerkDone String
:highlight link clerkCancelled String
:highlight link clerkCancelledGlyph Error

" Other
:highlight link clerkGroup Underlined

let b:current_syntax = 'clerk'
