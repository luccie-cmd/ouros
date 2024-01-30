org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A


;
; FAT12 header
; 
jmp short start
nop

; bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
; bdb_bytes_per_sector:       dw 512
; bdb_sectors_per_cluster:    db 1
; bdb_reserved_sectors:       dw 1
; bdb_fat_count:              db 2
; bdb_dir_entries_count:      dw 0E0h
; bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
; bdb_media_descriptor_type:  db 0F8h                 ; F8 = standard hard drive
; bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
; bdb_sectors_per_track:      dw 18
; bdb_heads:                  dw 2
; bdb_hidden_sectors:         dd 0
; bdb_large_sector_count:     dd 0

; ; extended boot record
; fat32_sectors_per_fat:      dd 0
; fat32_flags:                dw 0
; fat32_fat_version_number:   dw 0
; fat32_rootdir_cluster:      dd 0
; fat32_fsinfo_sector:        dw 0
; fat32_backup_boot_sector:   dw 0
; fat32_reserved:             times 12 db 0
ebr_drive_number:           db 80h                    ; 0x00 floppy, 0x80 hdd, useless
;                             db 0                    ; reserved
; ebr_signature:              db 29h
; ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
; ebr_volume_label:           db 'OUR      OS'        ; 11 bytes, padded with spaces
; ebr_system_id:              db 'FAT32   '           ; 8 bytes

times 90-($-$$) db 0

;
; Code goes here
;

start:
    ; setup data segments
    mov ax, 0           ; can't set ds/es directly
    mov ds, ax
    mov es, ax
    
    ; setup stack
    mov ss, ax
    mov sp, 0x7C00              ; stack grows downwards from where we are loaded in memory

    ; some BIOSes might start us at 07C0:0000 instead of 0000:7C00, make sure we are in the
    ; expected location
    push es
    push word .after
    retf

.after:

    ; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl
    ; load stage2
    mov si, stage2_location

    mov ax, STAGE2_LOAD_SEGMENT         ; set segment registers
    mov es, ax

    mov bx, STAGE2_LOAD_OFFSET

.loop:
    mov eax, [si]
    add si, 4
    mov cl, [si]
    inc si

    cmp eax, 0
    je .read_finish

    call disk_read

    xor ch, ch
    shl cx, 5
    mov di, es
    add di, cx
    mov es, di

    jmp .loop

.read_finish:
    
    ; jump to our kernel
    mov dl, [ebr_drive_number]          ; boot device in dl

    mov ax, STAGE2_LOAD_SEGMENT         ; set segment registers
    mov ds, ax
    mov es, ax

    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot             ; should never happen

    cli                                 ; disable interrupts, this way CPU can't get out of "halt" state
    hlt


;
; Error handlers
;

floppy_error:
    mov si, msg_read_failed
    call puts

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot

halt:
    cli                         ; disable interrupts, this way CPU can't get out of "halt" state
    hlt


;
; Prints a string to the screen
; Params:
;   - ds:si points to string
;
puts:
    ; save registers we will modify
    push si
    push ax
    push bx

.loop:
    lodsb               ; loads next character in al
    or al, al           ; verify if next character is null?
    jz .done

    mov ah, 0x0E        ; call bios interrupt
    mov bh, 0           ; set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret

;
; Disk routines
;


;
; Reads sectors from a disk
; Parameters:
;   - eax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

    push eax                            ; save registers we will modify
    push bx
    push cx
    push dx
    push si
    push di

    ; with extensions
    mov [extensions_dap.lba], eax
    mov [extensions_dap.segment], es
    mov [extensions_dap.offset], bx
    mov [extensions_dap.count], cl

    mov ah, 0x42
    mov si, extensions_dap
    mov di, 3                           ; retry count

.retry:
    pusha                               ; save all registers, we don't know what bios modifies
    stc                                 ; set carry flag, some BIOS'es don't set it
    int 13h                             ; carry flag cleared = success
    jnc .done                           ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop eax                            ; restore registers modified
    ret


;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_read_failed:        db 'Read from disk failed!', ENDL, 0

extensions_dap:
    .size:              db 10h
                        db 0
    .count:             dw 0
    .offset:            dw 0
    .segment:           dw 0
    .lba:               dq 0



STAGE2_LOAD_SEGMENT     equ 0x0
STAGE2_LOAD_OFFSET      equ 0x500

times 510-30-($-$$) db 0
stage2_location:        times 30 db 0
dw 0AA55h