[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START             ;CS세그먼트 레지스터 초기화, START레이블로 이동

TOTALSECTORCOUNT: dw 0x06    ;부트로더를 제외한 OS이미지의 크기, 최대 1152섹터까지 가능
KERNEL32SECTORCOUNT: dw 0x05 ;보호모드 커널의 총 섹터수
;코드영역

START:

    mov ax, 0x07C0
    mov ds, ax          ;ds세그먼트 레지스터 초기화
    mov ax, 0xB800
    mov es, ax          ;비디오 메모리의 시작 어드레스로 es세그먼트 레지스터 초기화

    mov ax, 0x0000      ;스택 세그먼트의 시작 어드레스0x0000을 세그먼트 레지스터 값으로 변환
    mov ss, ax          ;ss세그먼트 레지스터의 설정
    mov sp, 0xFFFE      ;sp레지스터의 어드레스를 oxfffe로 설정
    mov bp, 0xFFFE      ;위와 같음

    mov si, 0     ;si레지스터 초기화

 ;화면을 모두 지우고 초기화
.SCREENCLEARLOOP:

    mov byte [es : si], 0
    mov byte [es : si + 1], 0x0A
    add si, 2
    cmp si, 80 * 25 * 2
    jl .SCREENCLEARLOOP

    ;화면 상단에 시작 메시지 출력
    push MESSAGE1        ;출력할 메시지의 주소를 스택에 삽입
    push 0               ;Y좌표 삽입
    push 0               ;X좌표 삽입
    call PRINTMESSAGE    ;PRINTMESSAGE 함수 호출
    add sp, 6            ;삽입한 파라미터 제거


    push IMAGELOADINGMESSAGE ;출력할 메시지의 주소를 스택에 삽입
    push 1               ;Y좌표 삽입
    push 0               ;X좌표 삽입
    call PRINTMESSAGE    ;PRINTMESSAGE 함수 호출
    add sp, 6

;디스크에서 OS이미지를 로딩
;디스크 읽기 전에 리셋
RESETDISK:

    ;BIOS Reset Function 호출
    ;서비스 번호 0, 드라이브 번호(0 = Floppy)
    mov ax, 0
    mov dl, 0
    int 0x13
    ;에러가 발생하면 에러 처리로 이동
    jc HANDLEDISKERROR

    ;디스크에서 섹터를 읽음
    ;디스크의 내용을 메모리로 복사할 어드레스(ES:BX)를 0x10000으로 설정

    mov si, 0x1000        ;OS이미지를 0x10000에 복사할 예정
    mov es, si            ;ES세그먼트 레지스터에 값 저장
    mov bx, 0x0000        ;BX레지스터에 0x0000을 저장
                          ;어드레스 0x1000:0x0000(0x10000)으로 최종설정

    mov di, word[TOTALSECTORCOUNT] ;복사할 OS이미지 섹터 수를 DI레지스터에 저장

;디스크의 데이터를 읽음
READDATA:

    ;모든 섹터를 다 읽었는지 확인
    cmp di, 0             ;복사할 OS이미지의 섹터 수를 0과 비교
    je READEND            ;복사할 섹터 수가 0이라면 READEND로 이동
    sub di, 0x1           ;섹터 수 감소

    ;BIOS Read Function 호출
    mov ah, 0x02          ;BIOS 서비스 번호2(Read Sector)
    mov al, 0x1           ;읽을 섹터 수는 1
    mov ch, byte [TRACKNUMBER]    ;읽을 트랙 번호 설정
    mov cl, byte [SECTORNUMBER]   ;읽을 섹터 번호 설정
    mov dh, byte [HEADNUMBER]     ;읽을 헤드 번호 설정
    mov dl, 0x00                  ;읽을 드라이브 번호(0 = Floppy) 설정
    int 0x13                      ;인터럽트 서비스 수행
    jc HANDLEDISKERROR            ;에러가 발생했으면 HANDLEDISKERROR로 이동

    ;복사할 어드레스와  트랙, 헤드, 섹터 어드레스 계산
    add si, 0x0020    ;512(0x200)바이트만큼 읽었으므로, 이를 세그먼트 레지스터 값으로 변환
    mov es, si        ;ES 세그먼트 레지스터에 더해서 어드레스를 한 섹터 만큼 증가

    ;한 섹터를 읽었으므로 섹터 번호를 증가시키고 마지막 섹터(18)까지 읽었는지 판단
    ;마지막 섹터가 아니면 섹터 읽기로 이동

    mov al, byte[SECTORNUMBER]    ;섹터 번호를 AL레지스터에 설정
    add al, 0x01                  ;섹터 번호 1증가
    mov byte[SECTORNUMBER], al    ;증가시킨 섹터 번호를 SECTORNUMBER에 다시 설정
    cmp al, 19                    ;증가시킨 섹터 번호를 19와 비교
    jl READDATA                   ;섹터 번호가 19미만이라면 READDATA로 이동

    ;마지막 섹터까지 읽었으면(섹터 번호 == 19)헤드를 토글(0->1, 1->0)하고 섹터번호를 1로 설정
    xor byte[HEADNUMBER], 0x01    ;헤드번호를 0x01과 xor하여 토글
    mov byte[SECTORNUMBER], 0x01  ;섹터 번호를 다시 1로 설정

    ;만약 헤드가 1->0으로 바뀌었으면 약쪽 헤드를 모두 읽은 것이므로 아래로 이동하여 트랙 번호를 1증가
    cmp byte[HEADNUMBER], 0x00    ;헤드번호를 0x00과 비교
    jne READDATA                  ;헤드번호가 0이 아니면 READDATA로 이동

    ;트랙을 1 증가시킨 후 다시 섹터 읽기로 이동
    add byte[TRACKNUMBER], 0x01   ;트랙 번호를 1 증가
    jmp READDATA                  ;READDATA로 이동

READEND:

    ;OS이미지가 완료되었다는 메시지 출력

    push LOADINGCOMPLETEMESSAGE   ;출력할 메시지의 어드레스를 스택에 삽입
    push 1                        ;화면 Y좌표(1)를 스택에 삽입
    push 20                       ;화면 X좌표(20)을 스택에 삽입
    call PRINTMESSAGE             ;PRINTMESSAGE 함수 호출
    add sp, 6                     ;삽입한 파라미터 제거

    ;로딩한 가상 OS이미지 실행
    jmp 0x1000:0x0000

;함수 코드 영역

;디스크 에러를 처리하는 함수
HANDLEDISKERROR:
    push DISKERRORMESSAGE         ;에러 문자열의 어드레스를 스택에 삽입
    push 1
    push 20
    call PRINTMESSAGE

    jmp $

;메시지를 호출하는 함수
;매개변수: x, y, str

PRINTMESSAGE:
    push bp                       ;베이스 포인터에 레지스터를 스택에 삽입
    mov bp, sp                    ;BP레지스터에 스택 포인터 레지스터의 값을 설정, BP레지스터를 이용해서 파라미터에 접근할 목적

    push es                       ;ES세그먼트 부터 DX레지스터까지 스택에 삽입
    push si                       ;전 포르시져에서 쓰전 레지스터 값들 스택에 저장
    push di
    push ax
    push cx
    push dx

    ;ES 세그먼트 레지스터에 비디오 모드 어드레스 설정
    mov ax, 0xB800                ;비디오 시작 어드레스(0x0B8000)를 세그먼트 레지스터 값으로 변환
    mov es, ax                    ;ES세그먼트 레지스터에 설정

    mov ax, word[bp + 6]
    mov si, 160
    mul si
    mov di, ax

    mov ax, word[bp + 4]
    mov si, 2
    mul si
    add di, ax

    mov si, word[bp + 8]

.MESSAGELOOP:               ;메시지출력
    mov cl, byte [si]
    cmp cl, 0
    je .MESSAGEEND
    mov byte [ es:di ], cl
    add si, 1
    add di, 2
    jmp .MESSAGELOOP

.MESSAGEEND:
    pop dx                        ;레지스터 값 복원
    pop cx
    pop ax
    pop di
    pop si
    pop es
    pop bp
    ret

;데이터 영역
MESSAGE1: db 'MINT64 OS BOOT LOADER START', 0 ;마지막은 0으로 설정해서 .MESSAGELOOP에서 문자열이 종료되었음을 알 수 있도록 함
DISKERRORMESSAGE: db 'DISK ERROR', 0
IMAGELOADINGMESSAGE: db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db 'Complete!', 0

;디스크 읽기에 관련된 변수들
SECTORNUMBER: db 0x02
HEADNUMBER: db 0x00
TRACKNUMBER: db 0x00

    times 510 - ($ - $$) db 0x00



    db 0x55
    db 0xAA
