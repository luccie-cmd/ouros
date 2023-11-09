org 0x500

main:
    mov si, msg
    call puts
.halt:
    cli
    hlt
    jmp .halt

puts:
    push ax
    mov ah, 0x0e

.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop

.done:
    pop ax
    ret
msg: db "Hello From stage2", 0x0d, 0x0a, 0