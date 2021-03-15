[BITS 64]

SECTION .text

extern Main

START:
    mov ax, 0x10   ;IA-32��� Ŀ�ο� ������ ���׸�Ʈ ��ũ���͸� ax�������Ϳ� ����
    mov ds, ax     ;DS���׸�Ʈ �����Ϳ� ����
    mov es, ax
    mov fs, ax
    mov gs, ax

    ;������ 0x600000-0x6FFFFF ������ 	1MB ũ��� ����
    mov ss, ax         ;SS ���׸�Ʈ �����Ϳ� ����
    mov rsp, 0x6FFFF8  ;RSP ���������� ��巹���� 0x6FFFF8�� ����
    mov rbp, 0x6FFFF8  ;RBP ���������� ��巹���� 0x6FFFF8�� ����

    call Main

    jmp $
