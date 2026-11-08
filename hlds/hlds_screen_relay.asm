; hlds_screen_relay.asm
; NASM x86-64 Linux port of hlds/hlds_screen_relay.cpp
; (github.com/djearthquake/amxx/tree/main/hlds/hlds_screen_relay.cpp)
;
; Same behaviour as the C++ original, Windows-only branches dropped:
;   - prompts for IP / user / screen session / log dir / log file
;   - caches them in .amxx_pipe_cache (5 lines, save_cache/load_cache)
;   - ssh (ControlMaster multiplex) -> screen -S <name> -X stuff '<cmd>'
;   - commands: exit|quit, clear|cls, +, -, relay, anything else = send to screen
;   - after a send: raster bar, chime, tail log snapshot, SPACE expands
;   - on exit: screen logfile flush 10, ssh -O exit
;
; Build (Linux, needs libreadline):
;   nasm -f elf64 hlds_screen_relay.asm -o hlds_screen_relay.o
;   gcc -no-pie hlds_screen_relay.o -o hlds_screen_relay -lreadline
;   ./hlds_screen_relay
;
; NOTE: this is a faithful hand-written assembly port (libc + readline),
; not objdump output. Keep the .cpp for Windows builds.

default rel
bits 64

extern printf, fprintf, snprintf, system, strcmp, strcpy, strlen
extern fopen, fgets, fclose, fflush, free
extern readline, add_history, usleep
extern stdin, stderr, stdout

; ------------------------------------------------------------- data
section .data
CACHE_FILE:      db ".amxx_pipe_cache",0
SSH_BINARY:      db "ssh",0
PRIVATE_KEY:     db "~/.ssh/id_ed25519",0
str_exit:        db "exit",0
str_quit:        db "quit",0
str_clear:       db "clear",0
str_cls:         db "cls",0
str_relay:       db "relay",0
str_space:       db " ",0
str_empty:       db 0
str_rb:          db "rb",0
str_wb:          db "wb",0

fmt_c64:         db "",27,"[2J",27,"[H",27,"[1;44;33m**** COMMODORE 64 BASIC V2 ****",27,"[0m",10
                 db "",27,"[1;44;36m64K RAM SYSTEM  38911 BASIC BYTES FREE",27,"[0m",10,10,0
fmt_ip:          db "Enter Server IP [%s] : ",0
fmt_user:        db "Enter Server User [%s] : ",0
fmt_screen:      db "Enter Session Name ($MOD) [%s] : ",0
fmt_logdir:      db "Enter Log Directory [%s] : ",0
fmt_logfile:     db "Enter Log File [%s] : ",0
fmt_lines:       db "%s",10,0
fmt_active:      db "",27,"[1;32mSecure Multiplex Shell Active.",27,"[0m Use UP/DOWN arrows for history.",10,10,0
prompt_str:      db "",27,"[1;36mhlds_screen_relay>",27,"[0m ",0
fmt_grew:        db ">> Window grew to %d lines.",10,0
fmt_shrunk:      db ">> Window shrunk to %d lines.",10,0
fmt_relay_in:    db "",27,"[1;44;33m==== ENTERING LIVE RETRO STREAM MODE (Press Ctrl+C to drop back) ====",27,"[0m",10,0
fmt_relay_out:   db 10,"",27,"[1;44;37m==== STREAM TERMINATED: DROPPING BACK TO CORE CONSOLE ==== ",27,"[0m",10,0
fmt_log_head:    db "",27,"[1;44;37m------------------ SERVER LOG RESPONSE [ -%d lines ] ------------------",27,"[0m",10,0
fmt_log_foot:    db "",27,"[1;44;33m=================================================================================",27,"[0m",10,0
fmt_expand:      db "",27,"[1;36m[ SPACE + ENTER ]: Expand view  |  [ ENTER ]: Accept snapshot & return to prompt",27,"[0m",10,0
fmt_error:       db "",27,"[1;31m[Error: Multiplex secure pathway failed to deliver payload.]",27,"[0m",10,0
fmt_baseflags:   db ' -i "%s" -o ControlMaster=auto -o ControlPath=".ssh_mux_%%h_%%p_%%r" -o ControlPersist=10m ',0
fmt_flush0:      db '%s%s%s@%s "screen -S %s -X logfile flush 0" >/dev/null 2>&1',0
fmt_flush10:     db '%s%s%s@%s "screen -S %s -X logfile flush 10" >/dev/null 2>&1',0
fmt_tail_f:      db '%s%s%s@%s "tail -f -n %d %s/%s"',0
fmt_fetch:       db '%s%s%s@%s "tail -n %d %s/%s | grep -v AMXX-PIPE-SYNC-DONE" 2>/dev/null',0
fmt_send:        db "%s%s%s@%s ",34,"screen -S %s -X eval ",92,34,"stuff ",39,"%s",39,92,34," ",92,34,"stuff ",92,"015",92,34,34," 2>/dev/null",0
fmt_exit_mux:    db "%s%s-O exit %s@%s 2>/dev/null",0
fmt_raster:      db 13,"%s [ LOADING STREAM DATA ] ===================================== ",27,"[0m",13,0
fmt_reset_nl:    db "",27,"[0m",10,0

snd_ok:   db "speaker-test -t sine -f 440 -l 1 >/dev/null 2>&1 & (sleep 0.12 && killall speaker-test >/dev/null 2>&1) &",0
snd_fail: db "speaker-test -t sine -f 220 -l 1 >/dev/null 2>&1 & (sleep 0.25 && killall speaker-test >/dev/null 2>&1) &",0

c0: db "",27,"[44;36m",0
c1: db "",27,"[44;37m",0
c2: db "",27,"[45;33m",0
c3: db "",27,"[40;32m",0
c4: db "",27,"[44;33m",0
align 8
colors: dq c0,c1,c2,c3,c4

; -------------------------------------------------------------- bss
section .bss
align 8
cfg_ip:      resb 256
cfg_user:    resb 256
cfg_screen:  resb 256
cfg_logdir:  resb 512
cfg_logfile: resb 256
inputbuf:    resb 1024
cmdbuf:      resb 4096
escaped:     resb 1024
keybuf:      resb 512
baseflags:   resb 1024

; ------------------------------------------------------------- text
section .text
global main

; trim_cr(rdi=buf) -- strip all CR/LF in place
trim_cr:
        xor ecx,ecx          ; read idx
        xor edx,edx          ; write idx
.tloop: mov al,[rdi+rcx]
        test al,al
        jz .tdone
        cmp al,13
        je .tskip
        cmp al,10
        je .tskip
        mov [rdi+rdx],al
        inc rdx
.tskip: inc rcx
        jmp .tloop
.tdone: mov byte [rdi+rdx],0
        ret

; escape_quotes(rdi=in, rsi=out) -- '\'' -> '\''\'''
escape_quotes:
        xor ecx,ecx
        xor edx,edx
.eloop: mov al,[rdi+rcx]
        test al,al
        jz .edone
        cmp al,39            ; '\''
        jne .enorm
        mov byte [rsi+rdx],39
        inc rdx
        mov byte [rsi+rdx],92
        inc rdx
        mov byte [rsi+rdx],39
        inc rdx
        mov byte [rsi+rdx],39
        inc rdx
        jmp .enext
.enorm: mov [rsi+rdx],al
        inc rdx
.enext: inc rcx
        jmp .eloop
.edone: mov byte [rsi+rdx],0
        ret

; load_cache() -- defaults already in .bss? need defaults: set in main first.
load_cache:
        push rbp
        mov rbp,rsp
        push rbx
        sub rsp,16
        lea rdi,[rel CACHE_FILE]
        lea rsi,[rel str_rb]
        call fopen
        test rax,rax
        jz .ldone
        mov rbx,rax          ; FILE*
        ; ip
        lea rdi,[rel cfg_ip]
        mov esi,256
        mov rdx,rbx
        call fgets
        test rax,rax
        jz .l1
        lea rdi,[rel cfg_ip]
        call trim_cr
.l1:     lea rdi,[rel cfg_user]
        mov esi,256
        mov rdx,rbx
        call fgets
        test rax,rax
        jz .l2
        lea rdi,[rel cfg_user]
        call trim_cr
.l2:     lea rdi,[rel cfg_screen]
        mov esi,256
        mov rdx,rbx
        call fgets
        test rax,rax
        jz .l3
        lea rdi,[rel cfg_screen]
        call trim_cr
.l3:     lea rdi,[rel cfg_logdir]
        mov esi,512
        mov rdx,rbx
        call fgets
        test rax,rax
        jz .l4
        lea rdi,[rel cfg_logdir]
        call trim_cr
.l4:     lea rdi,[rel cfg_logfile]
        mov esi,256
        mov rdx,rbx
        call fgets
        test rax,rax
        jz .l5
        lea rdi,[rel cfg_logfile]
        call trim_cr
.l5:     mov rdi,rbx
        call fclose
.ldone: add rsp,16
        pop rbx
        pop rbp
        ret

save_cache:
        push rbp
        mov rbp,rsp
        push rbx
        sub rsp,16
        lea rdi,[rel CACHE_FILE]
        lea rsi,[rel str_wb]
        call fopen
        test rax,rax
        jz .sdone
        mov rbx,rax
        mov rdi,rbx
        lea rsi,[rel fmt_lines]
        lea rdx,[rel cfg_ip]
        xor eax,eax
        call fprintf
        mov rdi,rbx
        lea rsi,[rel fmt_lines]
        lea rdx,[rel cfg_user]
        xor eax,eax
        call fprintf
        mov rdi,rbx
        lea rsi,[rel fmt_lines]
        lea rdx,[rel cfg_screen]
        xor eax,eax
        call fprintf
        mov rdi,rbx
        lea rsi,[rel fmt_lines]
        lea rdx,[rel cfg_logdir]
        xor eax,eax
        call fprintf
        mov rdi,rbx
        lea rsi,[rel fmt_lines]
        lea rdx,[rel cfg_logfile]
        xor eax,eax
        call fprintf
        mov rdi,rbx
        call fclose
.sdone: add rsp,16
        pop rbx
        pop rbp
        ret

perform_c64_screen_reset:
        lea rdi,[rel fmt_c64]
        xor eax,eax
        jmp printf

; play_sound_chime(rdi=success)
play_sound_chime:
        test rdi,rdi
        jnz .ok
        lea rdi,[rel snd_fail]
        jmp system
.ok:    lea rdi,[rel snd_ok]
        jmp system

; play_retro_raster_bar()
play_retro_raster_bar:
        push rbp
        mov rbp,rsp
        push rbx
        push r12
        push r13
        sub rsp,8
        xor r12d,r12d        ; sweep
.sweep: cmp r12d,2
        jae .rdone
        xor r13d,r13d        ; color idx
.color: cmp r13d,5
        jae .next
        lea rax,[rel colors]
        mov rcx,[rax+r13*8]
        lea rdi,[rel fmt_raster]
        mov rsi,rcx
        xor eax,eax
        call printf
        mov rdi,[rel stdout]
        call fflush
        mov edi,35000
        call usleep
        inc r13d
        jmp .color
.next:  inc r12d
        jmp .sweep
.rdone: lea rdi,[rel fmt_reset_nl]
        xor eax,eax
        call printf
        add rsp,8
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret

; ask(rdi=fmt, rsi=dest) -- prompt via readline, keep old if empty
; (readline for everything: mixing fgets/stdin buffering with readline
;  loses piped input, same caveat exists in the C++ std::cin version)
ask:
        push rbp
        mov rbp,rsp
        push rbx
        push r12
        push r13
        sub rsp,8
        mov rbx,rsi          ; dest
        mov r12,rdi          ; fmt
        lea rdi,[rel inputbuf]
        mov esi,1024
        mov rdx,r12
        mov rcx,rbx
        xor eax,eax
        call snprintf
        lea rdi,[rel inputbuf]
        call readline
        mov r13,rax
        test rax,rax
        jz .adone
        cmp byte [rax],0
        je .afree
        mov rdi,rbx
        mov rsi,r13
        call strcpy
.afree: mov rdi,r13
        call free
.adone: add rsp,8
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret

; ---------------------------------------------------------------- main
; locals: [rbp-16]=window_lines(dword)
main:
        push rbp
        mov rbp,rsp
        push rbx
        push r12
        push r13
        push r14
        push r15
        sub rsp,72

        ; defaults (Config{})
        lea rdi,[rel cfg_ip]
        lea rsi,[rel d_ip]
        call strcpy
        lea rdi,[rel cfg_user]
        lea rsi,[rel d_user]
        call strcpy
        lea rdi,[rel cfg_screen]
        lea rsi,[rel d_screen]
        call strcpy
        lea rdi,[rel cfg_logdir]
        lea rsi,[rel d_logdir]
        call strcpy
        lea rdi,[rel cfg_logfile]
        lea rsi,[rel d_logfile]
        call strcpy

        call load_cache
        mov dword [rbp-16],45        ; window_lines

        call perform_c64_screen_reset

        lea rdi,[rel fmt_ip]
        lea rsi,[rel cfg_ip]
        call ask
        lea rdi,[rel fmt_user]
        lea rsi,[rel cfg_user]
        call ask
        lea rdi,[rel fmt_screen]
        lea rsi,[rel cfg_screen]
        call ask
        lea rdi,[rel fmt_logdir]
        lea rsi,[rel cfg_logdir]
        call ask
        lea rdi,[rel fmt_logfile]
        lea rsi,[rel cfg_logfile]
        call ask
        call save_cache

        ; key = PRIVATE_KEY_PATH
        lea rdi,[rel keybuf]
        lea rsi,[rel PRIVATE_KEY]
        call strcpy
        ; base_flags
        lea rdi,[rel baseflags]
        mov esi,1024
        lea rdx,[rel fmt_baseflags]
        lea rcx,[rel keybuf]
        xor eax,eax
        call snprintf

        ; flush 0
        lea rdi,[rel cmdbuf]
        mov esi,4096
        lea rdx,[rel fmt_flush0]
        lea rcx,[rel SSH_BINARY]
        lea r8,[rel baseflags]
        lea r9,[rel cfg_user]
        lea rax,[rel cfg_screen]
        push rax
        lea rax,[rel cfg_ip]
        push rax
        xor eax,eax
        call snprintf
        add rsp,16
        lea rdi,[rel cmdbuf]
        call system

        call perform_c64_screen_reset
        lea rdi,[rel fmt_active]
        xor eax,eax
        call printf

.loop:  lea rdi,[rel prompt_str]
        call readline
        mov r12,rax                ; line*
        test rax,rax
        jz .exit
        mov rdi,r12
        lea rsi,[rel str_exit]
        call strcmp
        test eax,eax
        jz .free_exit
        mov rdi,r12
        lea rsi,[rel str_quit]
        call strcmp
        test eax,eax
        jz .free_exit
        cmp byte [r12],0
        je .free_cont
        mov rdi,r12
        lea rsi,[rel str_clear]
        call strcmp
        test eax,eax
        jz .do_clear
        mov rdi,r12
        lea rsi,[rel str_cls]
        call strcmp
        test eax,eax
        jz .do_clear
        ; "+"
        cmp byte [r12],'+'
        jne .not_plus
        cmp byte [r12+1],0
        jne .not_plus
        add dword [rbp-16],5
        mov esi,[rbp-16]
        lea rdi,[rel fmt_grew]
        xor eax,eax
        call printf
        jmp .free_cont
.not_plus:
        cmp byte [r12],'-'
        jne .not_minus
        cmp byte [r12+1],0
        jne .not_minus
        cmp dword [rbp-16],5
        jle .shrink_print
        sub dword [rbp-16],5
.shrink_print:
        mov esi,[rbp-16]
        lea rdi,[rel fmt_shrunk]
        xor eax,eax
        call printf
        jmp .free_cont
.not_minus:
        mov rdi,r12
        lea rsi,[rel str_relay]
        call strcmp
        test eax,eax
        jnz .send
        ; relay
        lea rdi,[rel fmt_relay_in]
        xor eax,eax
        call printf
        lea rdi,[rel cmdbuf]
        mov esi,4096
        lea rdx,[rel fmt_tail_f]
        lea rcx,[rel SSH_BINARY]
        lea r8,[rel baseflags]
        lea r9,[rel cfg_user]
        lea rax,[rel cfg_logfile]
        push rax
        lea rax,[rel cfg_logdir]
        push rax
        mov eax,[rbp-16]
        push rax
        lea rax,[rel cfg_ip]
        push rax
        xor eax,eax
        call snprintf
        add rsp,32
        lea rdi,[rel cmdbuf]
        call system
        lea rdi,[rel fmt_relay_out]
        xor eax,eax
        call printf
        jmp .free_cont

.do_clear:
        call perform_c64_screen_reset
        jmp .free_cont

.send:  mov rdi,r12
        lea rsi,[rel escaped]
        call escape_quotes
        lea rdi,[rel cmdbuf]
        mov esi,4096
        lea rdx,[rel fmt_send]
        lea rcx,[rel SSH_BINARY]
        lea r8,[rel baseflags]
        lea r9,[rel cfg_user]
        sub rsp,8                ; align for 3 stack args
        lea rax,[rel escaped]
        push rax
        lea rax,[rel cfg_screen]
        push rax
        lea rax,[rel cfg_ip]
        push rax
        xor eax,eax
        call snprintf
        add rsp,32
        lea rdi,[rel cmdbuf]
        call system
        mov r14,rax                ; save result
        mov rdi,r12
        call free                  ; free(line)
        xor r12d,r12d
        test r14,r14
        jnz .send_fail
        call play_retro_raster_bar
        mov edi,1
        call play_sound_chime
        mov r15d,[rbp-16]          ; current_view_size
.inner: mov esi,r15d
        lea rdi,[rel fmt_log_head]
        xor eax,eax
        call printf
        lea rdi,[rel cmdbuf]
        mov esi,4096
        lea rdx,[rel fmt_fetch]
        lea rcx,[rel SSH_BINARY]
        lea r8,[rel baseflags]
        lea r9,[rel cfg_user]
        lea rax,[rel cfg_logfile]
        push rax
        lea rax,[rel cfg_logdir]
        push rax
        mov eax,r15d
        push rax
        lea rax,[rel cfg_ip]
        push rax
        xor eax,eax
        call snprintf
        add rsp,32
        lea rdi,[rel cmdbuf]
        call system
        lea rdi,[rel fmt_log_foot]
        xor eax,eax
        call printf
        lea rdi,[rel fmt_expand]
        xor eax,eax
        call printf
        lea rdi,[rel str_empty]
        call readline
        mov rbx,rax
        test rax,rax
        jz .inner_done
        mov rdi,rax
        lea rsi,[rel str_space]
        call strcmp
        mov r13d,eax
        mov rdi,rbx
        call free
        test r13d,r13d
        jnz .inner_done
        mov eax,[rbp-16]
        add r15d,eax
        jmp .inner
.inner_done:
        jmp .loop

.send_fail:
        xor edi,edi
        call play_sound_chime
        mov rdi,[rel stderr]
        lea rsi,[rel fmt_error]
        xor eax,eax
        call fprintf
        jmp .loop

.free_cont:
        mov rdi,r12
        call free
        jmp .loop
.free_exit:
        mov rdi,r12
        call free
.exit:  ; flush 10
        lea rdi,[rel cmdbuf]
        mov esi,4096
        lea rdx,[rel fmt_flush10]
        lea rcx,[rel SSH_BINARY]
        lea r8,[rel baseflags]
        lea r9,[rel cfg_user]
        lea rax,[rel cfg_screen]
        push rax
        lea rax,[rel cfg_ip]
        push rax
        xor eax,eax
        call snprintf
        add rsp,16
        lea rdi,[rel cmdbuf]
        call system
        ; ssh -O exit
        lea rdi,[rel cmdbuf]
        mov esi,4096
        lea rdx,[rel fmt_exit_mux]
        lea rcx,[rel SSH_BINARY]
        lea r8,[rel baseflags]
        lea r9,[rel cfg_user]
        sub rsp,8                ; align for 1 stack arg
        lea rax,[rel cfg_ip]
        push rax
        xor eax,eax
        call snprintf
        add rsp,16
        lea rdi,[rel cmdbuf]
        call system
        xor eax,eax
        add rsp,72
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret

section .data
d_ip:      db "127.0.0.1",0
d_user:    db "server_user",0
d_screen:  db "hlds_session",0
d_logdir:  db "/path/to/hlds",0
d_logfile: db "console.log",0
