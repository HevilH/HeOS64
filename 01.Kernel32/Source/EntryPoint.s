[ORG 0x00]
[BITS 16]

SECTION .text

;�ڵ念��


START:
    mov ax, 0x1000  ; ��ȣ ��� ��Ʈ�� ����Ʈ�� ���� ��巹��(0x10000)��
                    ; ���׸�Ʈ �������� ������ ��ȯ
    mov ds, ax      ; DS ���׸�Ʈ �������Ϳ� ����
    mov es, ax      ; ES ���׸�Ʈ �������Ϳ� ����

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; A20 ����Ʈ�� Ȱ��ȭ
    ; BIOS�� �̿��� ��ȯ�� �������� �� �ý��� ��Ʈ�� ��Ʈ�� ��ȯ �õ�
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; BIOS ���񽺸� ����ؼ� A20 ����Ʈ�� Ȱ��ȭ
    mov ax, 0x2401          ; A20 ����Ʈ Ȱ��ȭ ���� ����
    int 0x15                ; BIOS ���ͷ�Ʈ ���� ȣ��

    jc .A20GATEERROR        ; A20 ����Ʈ Ȱ��ȭ�� �����ߴ��� Ȯ��
    jmp .A20GATESUCCESS

.A20GATEERROR:
    ; ���� �߻� ��, �ý��� ��Ʈ�� ��Ʈ�� ��ȯ �õ�
    in al, 0x92     ; �ý��� ��Ʈ�� ��Ʈ(0x92)���� 1 ����Ʈ�� �о� AL �������Ϳ� ����
    or al, 0x02     ; ���� ���� A20 ����Ʈ ��Ʈ(��Ʈ 1)�� 1�� ����
    and al, 0xFE    ; �ý��� ���� ������ ���� 0xFE�� AND �����Ͽ� ��Ʈ 0�� 0���� ����
    out 0x92, al    ; �ý��� ��Ʈ�� ��Ʈ(0x92)�� ����� ���� 1 ����Ʈ ����

.A20GATESUCCESS:
    cli             ; ���ͷ�Ʈ�� �߻����� ���ϵ��� ����
    lgdt [ GDTR ]   ; GDTR �ڷᱸ���� ���μ����� �����Ͽ� GDT ���̺��� �ε�

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ��ȣ���� ����
    ; Disable Paging, Disable Cache, Internal FPU, Disable Align Check,
    ; Enable ProtectedMode
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, 0x4000003B ; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax        ; CR0 ��Ʈ�� �������Ϳ� ������ ������ �÷��׸� �����Ͽ�
                        ; ��ȣ ���� ��ȯ

    ; Ŀ�� �ڵ� ���׸�Ʈ�� 0x00�� �������� �ϴ� ������ ��ü�ϰ� EIP�� ���� 0x00�� �������� �缳��
    ; CS ���׸�Ʈ ������ : EIP
    jmp dword 0x18: ( PROTECTMODE - $$ + 0x10000 )



;��ȣ���� ����

[BITS 32]
PROTECTMODE:
    mov ax, 0x20  ;��ȣ��Ʈ Ŀ�ο� ������ ���׸�Ʈ ��ũ���͸� AX�������Ϳ� ����
    mov ds, ax ;DS���׸�Ʈ �����Ϳ� ����
    mov es, ax ;ES���׸�Ʈ �����Ϳ� ����
    mov fs, ax ;FS���׸�Ʈ �����Ϳ� ����
    mov gs, ax ;GS���׸�Ʈ �����Ϳ� ����

    ;������ 0x00000000~0x0000FFFF ������ 64kb ũ��� ����

    mov ss, ax         ;SS���׸�Ʈ �����Ϳ� ����
    mov esp, 0xFFFE    ;ESP���������� ��巹���� 0xFFFE�� ����
    mov ebp, 0xFFFE    ;EBP���������� ��巹���� 0xFFFE�� ����

    ;ȭ�鿡 ��ȣ��� ��ȯ �޽��� ���

    push (SWITCHSUCCESSMESSAGE - $$ + 0x10000) ;����� �޽����� ��巹���� ���ÿ� ����
    push 2                  ;Y��ǥ(2) ���ÿ� ����
    push 0                  ;ȭ�� X��ǥ(0) ���ÿ� ����
    call PRINTMESSAGE
    add esp, 12             ;������ �Ķ���� ����

    jmp dword 0x18: 0x10200 ;cĿ�� ��Ʈ�� ����Ʈ�� �̵�



;�Լ��ڵ� ����
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;�޽�������Լ� �Ű����� x,y��ǥ, ���ڿ�

PRINTMESSAGE:
    push ebp      ;�������� ���� ����, �Լ� ����
    mov ebp, esp
    push esi
    push edi
    push eax
    push ecx
    push edx

    ;X,Y�� ��ǥ�� ���� �޸��� ��巹�� ���

    ;Y��ǥ�� ���� ��巹���� ����
    mov eax, dword[ebp + 12] ;ȭ�� ��ǥ Y(2)�� EAX�������Ϳ� ����
    mov esi, 160             ;�� ������ ����Ʈ ��(2* 80)�� ESI�������Ϳ� ����
    mul esi                  ;EAX�������Ϳ� ESI�������͸� ���Ͽ� ȭ�� Y��巹�� ���
    mov edi, eax             ;���� ȭ�� Y��巹���� EDI�������Ϳ� ����

    ;X��ǥ �̿��ؼ� 2�� ���� ���� ��巹�� ����
    mov eax, dword[ebp + 8]  ;ȭ����ǥ X(1)�� EAX�������Ϳ� ����
    mov esi, 2               ;�� ���ڸ� ��Ÿ���� ����Ʈ ��(2)�� ESI�������Ϳ� ����
    mul esi                  ;Y����Ҷ��� ����
    add edi, eax             ;Y��巹���� ���� Y��巹���� ���ؼ� ���� ���� �޸� ��巹���� ���

    ;����� ���ڿ��� ��巹��
    mov esi, dword[ebp + 16] ;����� ���ڿ��� ��巹��

.MESSAGELOOP:            ;�޽��� ���
    mov cl, byte[esi]    ;
    cmp cl, 0
    je .MESSAGEEND
    mov byte[edi + 0xB8000], cl
    add esi, 1
    add edi, 2
    jmp .MESSAGELOOP

.MESSAGEEND:       ;�������Ͱ� ����
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret;        �Լ�����


;������ ����
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;�Ʒ��� �����͸� 8����Ʈ�� ���� �����ϱ� ���� �߰�
align 8, db 0

;GDTR�� ���� 8byte�� �����ϱ� ���� �߰�
dw 0x0000
;GDTR�ڷᱸ�� ����
GDTR:
    dw GDTEND - GDT - 1      ;�Ʒ��� ��ġ�ϴ� GDT���̺��� ��ü ũ��
    dd (GDT - $$ + 0x10000)  ;�Ʒ��� ��ġ�ϴ� GDT���̺��� ���� ��巹��

;GDT ���̺� ����
GDT:
    ;NULL��ũ����, �ݵ�� 0���� �ʱ�ȭ
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

    ;IA-32e ��� Ŀ�ο� �ڵ� ���׸�Ʈ ��ũ����
    IA_32eCODEDESCRIPTOR:
        dw 0xFFFF   ;LIMIT [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base [23:16]
        db 0x9A     ;P=1, DPL=0, Code Segment, Execute/Read
        db 0xAF     ;G=1, D=0, L=1, Limit[19:16]
        db 0x00     ;Base [31:24]

    ;IA-32e ��� Ŀ�ο� ������ ���׸�Ʈ ��ũ����
    IA_32eDATADESCRIPTOR:
        dw 0xFFFF   ;LIMIT [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base [23:16]
        db 0x92     ;P=1, DPL=0, DATA Segment, Read/Write
        db 0xAF     ;G=1, D=0, L=1, Limit[19:16]
        db 0x00     ;Base [31:24]

    ;��ȣ ��� Ŀ�ο� �ڵ� ���׸�Ʈ ��ũ����
    CODEDESCRIPTOR:
        dw 0xFFFF   ;LIMIT [15:0]
        dw 0x0000   ;BASE [15:0]
        db 0x00     ;BASE [23:16]
        db 0x9A     ;P=1, DPL=0, Code Segment, Execute/Read
        db 0xCF     ;G=1, D=1, L=0, Limit[19:16]
        db 0x00     ;Base [31:24]

    ;��ȣ ��� Ŀ�ο� ������ ���׸�Ʈ ��ũ����
    DATADESCRIPTOR:
        dw 0xFFFF   ;Limit [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base [23:16]
        db 0x92     ;P=1, DPL=0, Data Segmentm, Read/Write
        db 0xCF     ;G=1, D=1, L=0, Limit[19:16]
        db 0x00     ;Base [31:24]
GDTEND:

;��ȣ��� ��ȯ �޽���
SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success!', 0

times 512 - ($ - $$) db 0x00   ;������ 0���� ä��
