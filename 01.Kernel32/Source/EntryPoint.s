[ORG 0x00]
[BITS 16]

SECTION .text

;코드영역


START:
    mov ax, 0x1000  ; 보호 모드 엔트리 포인트의 시작 어드레스(0x10000)를
                    ; 세그먼트 레지스터 값으로 변환
    mov ds, ax      ; DS 세그먼트 레지스터에 설정
    mov es, ax      ; ES 세그먼트 레지스터에 설정

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; A20 게이트를 활성화
    ; BIOS를 이용한 전환이 실패했을 때 시스템 컨트롤 포트로 전환 시도
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; BIOS 서비스를 사용해서 A20 게이트를 활성화
    mov ax, 0x2401          ; A20 게이트 활성화 서비스 설정
    int 0x15                ; BIOS 인터럽트 서비스 호출

    jc .A20GATEERROR        ; A20 게이트 활성화가 성공했는지 확인
    jmp .A20GATESUCCESS

.A20GATEERROR:
    ; 에러 발생 시, 시스템 컨트롤 포트로 전환 시도
    in al, 0x92     ; 시스템 컨트롤 포트(0x92)에서 1 바이트를 읽어 AL 레지스터에 저장
    or al, 0x02     ; 읽은 값에 A20 게이트 비트(비트 1)를 1로 설정
    and al, 0xFE    ; 시스템 리셋 방지를 위해 0xFE와 AND 연산하여 비트 0를 0으로 설정
    out 0x92, al    ; 시스템 컨트롤 포트(0x92)에 변경된 값을 1 바이트 설정

.A20GATESUCCESS:
    cli             ; 인터럽트가 발생하지 못하도록 설정
    lgdt [ GDTR ]   ; GDTR 자료구조를 프로세서에 설정하여 GDT 테이블을 로드

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 보호모드로 진입
    ; Disable Paging, Disable Cache, Internal FPU, Disable Align Check,
    ; Enable ProtectedMode
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, 0x4000003B ; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax        ; CR0 컨트롤 레지스터에 위에서 저장한 플래그를 설정하여
                        ; 보호 모드로 전환

    ; 커널 코드 세그먼트를 0x00을 기준으로 하는 것으로 교체하고 EIP의 값을 0x00을 기준으로 재설정
    ; CS 세그먼트 셀렉터 : EIP
    jmp dword 0x18: ( PROTECTMODE - $$ + 0x10000 )



;보호모드로 진입

[BITS 32]
PROTECTMODE:
    mov ax, 0x20  ;보호모트 커널용 데이터 세그먼트 디스크립터를 AX레지스터에 저장
    mov ds, ax ;DS세그먼트 설렉터에 설정
    mov es, ax ;ES세그먼트 셀렉터에 설정
    mov fs, ax ;FS세그먼트 셀렉터에 설정
    mov gs, ax ;GS세그먼트 셀렉터에 설정

    ;스택을 0x00000000~0x0000FFFF 영역에 64kb 크기로 생성

    mov ss, ax         ;SS세그먼트 셀렉터에 설정
    mov esp, 0xFFFE    ;ESP레지스터의 어드레스를 0xFFFE로 설정
    mov ebp, 0xFFFE    ;EBP레지스터의 어드레스를 0xFFFE로 설정

    ;화면에 보호모드 전환 메시지 출력

    push (SWITCHSUCCESSMESSAGE - $$ + 0x10000) ;출력할 메시지의 어드레스를 스택에 삽입
    push 2                  ;Y좌표(2) 스택에 삽입
    push 0                  ;화면 X좌표(0) 스택에 삽입
    call PRINTMESSAGE
    add esp, 12             ;삽입한 파라미터 제거

    jmp dword 0x18: 0x10200 ;c커널 엔트리 포인트로 이동



;함수코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;메시지출력함수 매개변수 x,y좌표, 문자열

PRINTMESSAGE:
    push ebp      ;레지스터 정보 저장, 함수 시작
    mov ebp, esp
    push esi
    push edi
    push eax
    push ecx
    push edx

    ;X,Y의 좌표로 비디오 메모리의 어드레스 계산

    ;Y좌표로 라인 어드레스를 구함
    mov eax, dword[ebp + 12] ;화면 좌표 Y(2)를 EAX레지스터에 저장
    mov esi, 160             ;한 라인의 바이트 수(2* 80)를 ESI레지스터에 설정
    mul esi                  ;EAX레지스터와 ESI레지스터를 곱하여 화면 Y어드레스 계산
    mov edi, eax             ;계산된 화면 Y어드레스를 EDI레지스터에 설정

    ;X좌표 이용해서 2를 곱해 최종 어드레스 구함
    mov eax, dword[ebp + 8]  ;화면좌표 X(1)를 EAX레지스터에 저장
    mov esi, 2               ;한 문자를 나타내는 바이트 수(2)를 ESI레지스터에 설정
    mul esi                  ;Y계산할때와 동일
    add edi, eax             ;Y어드레스와 계산된 Y어드레스를 더해서 실제 비디오 메모리 어드레스를 계산

    ;출력할 문자열의 어드레스
    mov esi, dword[ebp + 16] ;출력할 문자열의 어드레스

.MESSAGELOOP:            ;메시지 출력
    mov cl, byte[esi]    ;
    cmp cl, 0
    je .MESSAGEEND
    mov byte[edi + 0xB8000], cl
    add esi, 1
    add edi, 2
    jmp .MESSAGELOOP

.MESSAGEEND:       ;레지스터값 복원
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret;        함수복귀


;데이터 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;아래의 데이터를 8바이트에 맞춰 정렬하기 위해 추가
align 8, db 0

;GDTR의 끝을 8byte로 정렬하기 위해 추가
dw 0x0000
;GDTR자료구조 정의
GDTR:
    dw GDTEND - GDT - 1      ;아래에 위치하는 GDT테이블의 전체 크기
    dd (GDT - $$ + 0x10000)  ;아래에 위치하는 GDT테이블의 시작 어드레스

;GDT 테이블 정의
GDT:
    ;NULL디스크립터, 반드시 0으로 초기화
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

    ;IA-32e 모드 커널용 코드 세그먼트 디스크립터
    IA_32eCODEDESCRIPTOR:
        dw 0xFFFF   ;LIMIT [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base [23:16]
        db 0x9A     ;P=1, DPL=0, Code Segment, Execute/Read
        db 0xAF     ;G=1, D=0, L=1, Limit[19:16]
        db 0x00     ;Base [31:24]

    ;IA-32e 모드 커널용 데이터 세그먼트 디스크립터
    IA_32eDATADESCRIPTOR:
        dw 0xFFFF   ;LIMIT [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base [23:16]
        db 0x92     ;P=1, DPL=0, DATA Segment, Read/Write
        db 0xAF     ;G=1, D=0, L=1, Limit[19:16]
        db 0x00     ;Base [31:24]

    ;보호 모드 커널용 코드 세그먼트 디스크립터
    CODEDESCRIPTOR:
        dw 0xFFFF   ;LIMIT [15:0]
        dw 0x0000   ;BASE [15:0]
        db 0x00     ;BASE [23:16]
        db 0x9A     ;P=1, DPL=0, Code Segment, Execute/Read
        db 0xCF     ;G=1, D=1, L=0, Limit[19:16]
        db 0x00     ;Base [31:24]

    ;보호 모드 커널용 데이터 세그먼트 디스크립터
    DATADESCRIPTOR:
        dw 0xFFFF   ;Limit [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base [23:16]
        db 0x92     ;P=1, DPL=0, Data Segmentm, Read/Write
        db 0xCF     ;G=1, D=1, L=0, Limit[19:16]
        db 0x00     ;Base [31:24]
GDTEND:

;보호모드 전환 메시지
SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success!', 0

times 512 - ($ - $$) db 0x00   ;나머지 0으로 채움
