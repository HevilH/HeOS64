[BITS 32]

global k_read_CPUID, k_switch_exec_64bitKernel

SECTION .text

;CUPID 반환
;parameter DWORD dwEAX, DWORD* pdwEAX, pdwEBX, pdwECX, pdwEDX

k_read_CPUID:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi


    ;EAX레지스터 값으로 CUPID 명령어 실행

    mov eax, dword[ebp + 8] ;파라미터 1(dwEAX)를 eax에 저장
    cpuid                   ;cpuid명령어 실행

    ;반환된 값을 파라미터에 저장

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

    ;IA-32e모드로 전환하고 64비트 커널을 수행
    ;파라미터 없음


k_switch_exec_64bitKernel:

    ;CR4 컨트롤 레지스터의 PAE비트를 1로 설정
    mov eax, cr4
    or eax, 0x20        ;PAE비트(비트 5)를 1로 설정
    mov cr4, eax        ;PAE비트가 1로 설정된 값을  CR4 컨트롤 레지스터의 저장

    ;CR3 컨트롤 레지스터에 PML4 테이블의 어드레스와 캐시 활성화
    mov eax, 0x100000   ;EAX레지스터에 PML4 테이블이 존재하는 0x100000(1M)를 저장
    mov cr3, eax        ;CR3 컨트롤 레지스터에 0x100000(1M)를 저장

    ;IA32_EFER.LME를 1로 설정하여 IA-32e 모드를 활성화
    mov ecx, 0xC0000080 ;IA32_EFER MSR레지스터의 어드레스를 저장
    rdmsr               ;MSR 레지스터를 읽기

    or eax, 0x0100      ;EAX레지스터에 저장된 IA32)EFER MSR의 하위 32비트에서 LME비트(비트8)을 1로 설정
    wrmsr               ;MSR레지스터에 쓰기

    ;CR0 컨트롤 레지스터를 NW비트(비트29) = 0, CD 비트(비트 30) = 0, PG 비트(비트31) = 1로 설정하여 캐시 기능과 페이징 기능을 활성화
    mov eax, cr0        ;EAX 레지스터에 CR0 컨트롤 레지스터를 저장
    or eax, 0xE0000000  ;NW비트(비트29), CD비트(비트 30), PG비트(비트31)을 모두 1로 설정
    xor eax, 0x60000000 ;NW비트(비트29)와 CD비트(비트 30)을 XOR하여 0으로 설정
    mov cr0, eax        ;NW비트 = 0, CD비트 = 0, PG비트 = 1로 설정한 값을 다시 cr0 컨트롤 레지스터에 저장

    jmp 0x08:0x200000

    jmp $


