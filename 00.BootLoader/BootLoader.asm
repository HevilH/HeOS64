[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START             ;CS���׸�Ʈ �������� �ʱ�ȭ, START���̺�� �̵�

TOTALSECTORCOUNT: dw 0x06    ;��Ʈ�δ��� ������ OS�̹����� ũ��, �ִ� 1152���ͱ��� ����
KERNEL32SECTORCOUNT: dw 0x05 ;��ȣ��� Ŀ���� �� ���ͼ�
;�ڵ念��

START:

    mov ax, 0x07C0
    mov ds, ax          ;ds���׸�Ʈ �������� �ʱ�ȭ
    mov ax, 0xB800
    mov es, ax          ;���� �޸��� ���� ��巹���� es���׸�Ʈ �������� �ʱ�ȭ

    mov ax, 0x0000      ;���� ���׸�Ʈ�� ���� ��巹��0x0000�� ���׸�Ʈ �������� ������ ��ȯ
    mov ss, ax          ;ss���׸�Ʈ ���������� ����
    mov sp, 0xFFFE      ;sp���������� ��巹���� oxfffe�� ����
    mov bp, 0xFFFE      ;���� ����

    mov si, 0     ;si�������� �ʱ�ȭ

 ;ȭ���� ��� ����� �ʱ�ȭ
.SCREENCLEARLOOP:

    mov byte [es : si], 0
    mov byte [es : si + 1], 0x0A
    add si, 2
    cmp si, 80 * 25 * 2
    jl .SCREENCLEARLOOP

    ;ȭ�� ��ܿ� ���� �޽��� ���
    push MESSAGE1        ;����� �޽����� �ּҸ� ���ÿ� ����
    push 0               ;Y��ǥ ����
    push 0               ;X��ǥ ����
    call PRINTMESSAGE    ;PRINTMESSAGE �Լ� ȣ��
    add sp, 6            ;������ �Ķ���� ����


    push IMAGELOADINGMESSAGE ;����� �޽����� �ּҸ� ���ÿ� ����
    push 1               ;Y��ǥ ����
    push 0               ;X��ǥ ����
    call PRINTMESSAGE    ;PRINTMESSAGE �Լ� ȣ��
    add sp, 6

;��ũ���� OS�̹����� �ε�
;��ũ �б� ���� ����
RESETDISK:

    ;BIOS Reset Function ȣ��
    ;���� ��ȣ 0, ����̺� ��ȣ(0 = Floppy)
    mov ax, 0
    mov dl, 0
    int 0x13
    ;������ �߻��ϸ� ���� ó���� �̵�
    jc HANDLEDISKERROR

    ;��ũ���� ���͸� ����
    ;��ũ�� ������ �޸𸮷� ������ ��巹��(ES:BX)�� 0x10000���� ����

    mov si, 0x1000        ;OS�̹����� 0x10000�� ������ ����
    mov es, si            ;ES���׸�Ʈ �������Ϳ� �� ����
    mov bx, 0x0000        ;BX�������Ϳ� 0x0000�� ����
                          ;��巹�� 0x1000:0x0000(0x10000)���� ��������

    mov di, word[TOTALSECTORCOUNT] ;������ OS�̹��� ���� ���� DI�������Ϳ� ����

;��ũ�� �����͸� ����
READDATA:

    ;��� ���͸� �� �о����� Ȯ��
    cmp di, 0             ;������ OS�̹����� ���� ���� 0�� ��
    je READEND            ;������ ���� ���� 0�̶�� READEND�� �̵�
    sub di, 0x1           ;���� �� ����

    ;BIOS Read Function ȣ��
    mov ah, 0x02          ;BIOS ���� ��ȣ2(Read Sector)
    mov al, 0x1           ;���� ���� ���� 1
    mov ch, byte [TRACKNUMBER]    ;���� Ʈ�� ��ȣ ����
    mov cl, byte [SECTORNUMBER]   ;���� ���� ��ȣ ����
    mov dh, byte [HEADNUMBER]     ;���� ��� ��ȣ ����
    mov dl, 0x00                  ;���� ����̺� ��ȣ(0 = Floppy) ����
    int 0x13                      ;���ͷ�Ʈ ���� ����
    jc HANDLEDISKERROR            ;������ �߻������� HANDLEDISKERROR�� �̵�

    ;������ ��巹����  Ʈ��, ���, ���� ��巹�� ���
    add si, 0x0020    ;512(0x200)����Ʈ��ŭ �о����Ƿ�, �̸� ���׸�Ʈ �������� ������ ��ȯ
    mov es, si        ;ES ���׸�Ʈ �������Ϳ� ���ؼ� ��巹���� �� ���� ��ŭ ����

    ;�� ���͸� �о����Ƿ� ���� ��ȣ�� ������Ű�� ������ ����(18)���� �о����� �Ǵ�
    ;������ ���Ͱ� �ƴϸ� ���� �б�� �̵�

    mov al, byte[SECTORNUMBER]    ;���� ��ȣ�� AL�������Ϳ� ����
    add al, 0x01                  ;���� ��ȣ 1����
    mov byte[SECTORNUMBER], al    ;������Ų ���� ��ȣ�� SECTORNUMBER�� �ٽ� ����
    cmp al, 19                    ;������Ų ���� ��ȣ�� 19�� ��
    jl READDATA                   ;���� ��ȣ�� 19�̸��̶�� READDATA�� �̵�

    ;������ ���ͱ��� �о�����(���� ��ȣ == 19)��带 ���(0->1, 1->0)�ϰ� ���͹�ȣ�� 1�� ����
    xor byte[HEADNUMBER], 0x01    ;����ȣ�� 0x01�� xor�Ͽ� ���
    mov byte[SECTORNUMBER], 0x01  ;���� ��ȣ�� �ٽ� 1�� ����

    ;���� ��尡 1->0���� �ٲ������ ���� ��带 ��� ���� ���̹Ƿ� �Ʒ��� �̵��Ͽ� Ʈ�� ��ȣ�� 1����
    cmp byte[HEADNUMBER], 0x00    ;����ȣ�� 0x00�� ��
    jne READDATA                  ;����ȣ�� 0�� �ƴϸ� READDATA�� �̵�

    ;Ʈ���� 1 ������Ų �� �ٽ� ���� �б�� �̵�
    add byte[TRACKNUMBER], 0x01   ;Ʈ�� ��ȣ�� 1 ����
    jmp READDATA                  ;READDATA�� �̵�

READEND:

    ;OS�̹����� �Ϸ�Ǿ��ٴ� �޽��� ���

    push LOADINGCOMPLETEMESSAGE   ;����� �޽����� ��巹���� ���ÿ� ����
    push 1                        ;ȭ�� Y��ǥ(1)�� ���ÿ� ����
    push 20                       ;ȭ�� X��ǥ(20)�� ���ÿ� ����
    call PRINTMESSAGE             ;PRINTMESSAGE �Լ� ȣ��
    add sp, 6                     ;������ �Ķ���� ����

    ;�ε��� ���� OS�̹��� ����
    jmp 0x1000:0x0000

;�Լ� �ڵ� ����

;��ũ ������ ó���ϴ� �Լ�
HANDLEDISKERROR:
    push DISKERRORMESSAGE         ;���� ���ڿ��� ��巹���� ���ÿ� ����
    push 1
    push 20
    call PRINTMESSAGE

    jmp $

;�޽����� ȣ���ϴ� �Լ�
;�Ű�����: x, y, str

PRINTMESSAGE:
    push bp                       ;���̽� �����Ϳ� �������͸� ���ÿ� ����
    mov bp, sp                    ;BP�������Ϳ� ���� ������ ���������� ���� ����, BP�������͸� �̿��ؼ� �Ķ���Ϳ� ������ ����

    push es                       ;ES���׸�Ʈ ���� DX�������ͱ��� ���ÿ� ����
    push si                       ;�� ������������ ���� �������� ���� ���ÿ� ����
    push di
    push ax
    push cx
    push dx

    ;ES ���׸�Ʈ �������Ϳ� ���� ��� ��巹�� ����
    mov ax, 0xB800                ;���� ���� ��巹��(0x0B8000)�� ���׸�Ʈ �������� ������ ��ȯ
    mov es, ax                    ;ES���׸�Ʈ �������Ϳ� ����

    mov ax, word[bp + 6]
    mov si, 160
    mul si
    mov di, ax

    mov ax, word[bp + 4]
    mov si, 2
    mul si
    add di, ax

    mov si, word[bp + 8]

.MESSAGELOOP:               ;�޽������
    mov cl, byte [si]
    cmp cl, 0
    je .MESSAGEEND
    mov byte [ es:di ], cl
    add si, 1
    add di, 2
    jmp .MESSAGELOOP

.MESSAGEEND:
    pop dx                        ;�������� �� ����
    pop cx
    pop ax
    pop di
    pop si
    pop es
    pop bp
    ret

;������ ����
MESSAGE1: db 'MINT64 OS BOOT LOADER START', 0 ;�������� 0���� �����ؼ� .MESSAGELOOP���� ���ڿ��� ����Ǿ����� �� �� �ֵ��� ��
DISKERRORMESSAGE: db 'DISK ERROR', 0
IMAGELOADINGMESSAGE: db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db 'Complete!', 0

;��ũ �б⿡ ���õ� ������
SECTORNUMBER: db 0x02
HEADNUMBER: db 0x00
TRACKNUMBER: db 0x00

    times 510 - ($ - $$) db 0x00



    db 0x55
    db 0xAA
