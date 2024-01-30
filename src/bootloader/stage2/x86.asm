section .text

%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; 5 - enable interrupts
    sti

%endmacro

%macro enter_cdecl 0
    push ebp
    mov ebp, esp
%endmacro

%macro exit_cdecl 0
    mov esp, ebp
    pop ebp
%endmacro


%macro x86_EnterProtectedMode 0
    cli

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode

.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro

; Convert linear address to segment:offset address
; Args:
;    1 - linear address
;    2 - (out) target segment (e.g. es)
;    3 - target 32-bit register to use (e.g. eax)
;    4 - target lower 16-bit half of #3 (e.g. ax)

%macro LinearToSegOffset 4

    mov %3, %1      ; linear address to eax
    shr %3, 4
    mov %2, %4
    mov %3, %1      ; linear address to eax
    and %3, 0xf

%endmacro

; x86_outb(uint16_t port, uint8_t value)
global x86_outb
x86_outb:
    [bits 32]
    mov dx, [esp+4]
    mov al, [esp+8]
    out dx, al
    ret

global x86_inb
x86_inb:
    [bits 32]
    mov dx, [esp + 4]
    xor eax, eax
    in al, dx
    ret

; bool ASMCALL x86_disk_reset(uint8_t drive);
global x86_disk_reset
x86_disk_reset:
    [bits 32]
    enter_cdecl

    x86_EnterRealMode
    [bits 16]

    mov ah, 0
    mov dl, [bp + 8]    ; dl - drive
    stc
    int 13h

    mov eax, 1
    sbb eax, 0           ; 1 on success, 0 on fail   

    push eax

    x86_EnterProtectedMode
    [bits 32]

    pop eax

    exit_cdecl
    ret

; bool    ASMCALL x86_disk_read(uint8_t drive,
;                          uint16_t cylinder,
;                          uint16_t sector,
;                          uint16_t head,
;                          uint8_t count,
;                          void* DataOut);
global x86_disk_read
x86_disk_read:
    [bits 32]

    ; make new call frame
    enter_cdecl

    x86_EnterRealMode
    [bits 16]

    ; save modified regs
    push ebx
    push es

    ; setup args
    mov dl, [bp + 8]    ; dl - drive

    mov ch, [bp + 12]    ; ch - cylinder (lower 8 bits)
    mov cl, [bp + 13]    ; cl - cylinder to bits 6-7
    shl cl, 6
    
    mov al, [bp + 16]    ; cl - sector to bits 0-5
    and al, 3Fh
    or cl, al

    mov dh, [bp + 20]   ; dh - head

    mov al, [bp + 24]   ; al - count

    LinearToSegOffset [bp + 28], es, ebx, bx

    ; call int13h
    mov ah, 02h
    stc
    int 13h

    ; set return value
    mov eax, 1
    sbb eax, 0           ; 1 on success, 0 on fail   

    ; restore regs
    pop es
    pop ebx

    push eax

    x86_EnterProtectedMode
    [bits 32]

    pop eax

    ; restore old call frame
    exit_cdecl
    ret

; bool    ASMCALL x86_get_drive_params(uint8_t drive, uint32_t *cylinders, uint32_t *heads, uint32_t *spt, uint64_t *absolute_sectors);
global x86_get_drive_params
x86_get_drive_params:
    [bits 32]
    enter_cdecl

    x86_EnterRealMode
    [bits 16]

    push si

    mov dl, [bp + 8] ;  dl = drive
    mov si, result
    mov ah, 48H
    stc
    int 13h

    ; set return value
    mov eax, 1
    sbb eax, 0           ; 1 on success, 0 on fail
    push eax
    mov eax, [result.cylinders]
    mov ebx, [bp + 12]     ; Pointer to cylinders
    mov [ebx], eax

    mov eax, [result.heads]
    mov ebx, [bp + 16]     ; Pointer to heads
    mov [ebx], eax

    mov eax, [result.spt]
    mov ebx, [bp + 20]     ; Pointer to spt
    mov [ebx], eax

    mov eax, [result.absolute_sectors]
    mov ebx, [bp + 24]     ; Pointer to absolute_sectors
    mov [ebx], eax
    pop eax
    pop si
    
    push eax
    x86_EnterProtectedMode
    [bits 32]    

    pop eax

    exit_cdecl
    [bits 32]
    ret

result:
    .size: dw 1Eh
    .info: dw 0
    .cylinders: dd 0
    .heads: dd 0
    .spt: dd 0
    .absolute_sectors: dq 0
    .bytes_per_sector: dw 0
    .edd: dd 0