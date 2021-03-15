[BITS 32]

global k_read_CPUID, k_switch_exec_64bitKernel

SECTION .text

;CUPID ��ȯ
;parameter DWORD dwEAX, DWORD* pdwEAX, pdwEBX, pdwECX, pdwEDX

k_read_CPUID:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi


    ;EAX�������� ������ CUPID ��ɾ� ����

    mov eax, dword[ebp + 8] ;�Ķ���� 1(dwEAX)�� eax�� ����
    cpuid                   ;cpuid��ɾ� ����

    ;��ȯ�� ���� �Ķ���Ϳ� ����

    ;*pdwEAX
    mov esi, dword [ebp + 12]
    mov dword[esi], eax

    ;*pdwEBX
    mov esi, dword [ebp + 16]
    mov dword[esi], ebx

    ;*pdwECX
    mov esi, dword [ebp + 20]
    mov dword[esi], ecx

    ;*pdwEDX
    mov esi, dword [ebp + 24]
    mov dword[esi], edx

    pop esi     ;return
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

    ;IA-32e���� ��ȯ�ϰ� 64��Ʈ Ŀ���� ����
    ;�Ķ���� ����


k_switch_exec_64bitKernel:

    ;CR4 ��Ʈ�� ���������� PAE��Ʈ�� 1�� ����
    mov eax, cr4
    or eax, 0x20        ;PAE��Ʈ(��Ʈ 5)�� 1�� ����
    mov cr4, eax        ;PAE��Ʈ�� 1�� ������ ����  CR4 ��Ʈ�� ���������� ����

    ;CR3 ��Ʈ�� �������Ϳ� PML4 ���̺��� ��巹���� ĳ�� Ȱ��ȭ
    mov eax, 0x100000   ;EAX�������Ϳ� PML4 ���̺��� �����ϴ� 0x100000(1M)�� ����
    mov cr3, eax        ;CR3 ��Ʈ�� �������Ϳ� 0x100000(1M)�� ����

    ;IA32_EFER.LME�� 1�� �����Ͽ� IA-32e ��带 Ȱ��ȭ
    mov ecx, 0xC0000080 ;IA32_EFER MSR���������� ��巹���� ����
    rdmsr               ;MSR �������͸� �б�

    or eax, 0x0100      ;EAX�������Ϳ� ����� IA32)EFER MSR�� ���� 32��Ʈ���� LME��Ʈ(��Ʈ8)�� 1�� ����
    wrmsr               ;MSR�������Ϳ� ����

    ;CR0 ��Ʈ�� �������͸� NW��Ʈ(��Ʈ29) = 0, CD ��Ʈ(��Ʈ 30) = 0, PG ��Ʈ(��Ʈ31) = 1�� �����Ͽ� ĳ�� ��ɰ� ����¡ ����� Ȱ��ȭ
    mov eax, cr0        ;EAX �������Ϳ� CR0 ��Ʈ�� �������͸� ����
    or eax, 0xE0000000  ;NW��Ʈ(��Ʈ29), CD��Ʈ(��Ʈ 30), PG��Ʈ(��Ʈ31)�� ��� 1�� ����
    xor eax, 0x60000000 ;NW��Ʈ(��Ʈ29)�� CD��Ʈ(��Ʈ 30)�� XOR�Ͽ� 0���� ����
    mov cr0, eax        ;NW��Ʈ = 0, CD��Ʈ = 0, PG��Ʈ = 1�� ������ ���� �ٽ� cr0 ��Ʈ�� �������Ϳ� ����

    jmp 0x08:0x200000

    jmp $


