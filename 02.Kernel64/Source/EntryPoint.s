[BITS 64]

SECTION .text

extern Main

START:
    mov ax, 0x10   ;IA-32모드 커널용 데이터 세그먼트 디스크립터를 ax레지스터에 저장
    mov ds, ax     ;DS세그먼트 셀렉터에 설정
    mov es, ax
    mov fs, ax
    mov gs, ax

    ;스택을 0x600000-0x6FFFFF 영역에 	1MB 크기로 생성
    mov ss, ax         ;SS 세그먼트 셀렉터에 설정
    mov rsp, 0x6FFFF8  ;RSP 레지스터의 어드레스를 0x6FFFF8로 설정
    mov rbp, 0x6FFFF8  ;RBP 레지스터의 어드레스를 0x6FFFF8로 설정

    call Main

    jmp $
