#include "Types.h"
#include "Page.h"
#include "ModeSwitch.h"

void k_printstr(int x, int y, const char* scr_str);
BOOL init_k64area(void);
BOOL is_kmemoryenough(void);
void k_copy_kernel64_imgto2Mbt(void);

void main(void){
	DWORD i;
	DWORD dwEAX, dwEBX, dwECX, dwEDX;
	char vcVendorString[13] = {0,};


	k_printstr(0, 3, "Protected Mode Kernel Start!");
	k_printstr(0, 4, "Minimum Memory Size Check.........[    ]");
	if(is_kmemoryenough() == FALSE){
		k_printstr(35, 4, "Fail");
		while(1);
	}
	k_printstr(35, 4, "Pass");
	k_printstr(0, 5, "IA-32e Kernel Area Init...........[    ]" );
	if(init_k64area() == FALSE){
		k_printstr(35, 5, "Fail");
	}
	k_printstr(35, 5, "Pass" );
	k_printstr(0, 6, "IA-32e Page Tables Init...........[    ]" );
	k_init_PageTables();
	k_printstr(35, 6, "Pass" );

	//프로세서 정보 읽기
	k_read_CPUID(0x00, &dwEAX, &dwEBX, &dwECX, &dwEDX);
	*( DWORD* ) vcVendorString = dwEBX;
	*( ( DWORD* ) vcVendorString + 1 ) = dwEDX;
	*( ( DWORD* ) vcVendorString + 2 ) = dwECX;
	k_printstr( 0, 7, "Processor Vendor String...........[            ]" );
	k_printstr( 35, 7, vcVendorString );

	k_read_CPUID( 0x80000001, &dwEAX, &dwEBX, &dwECX, &dwEDX );
	k_printstr( 0, 8, "64bit Mode Support Check..........[    ]" );
	if( dwEDX & ( 1 << 29 ) ){
	    k_printstr( 35, 8, "Pass" );
	}
	else{
	    k_printstr( 35, 8, "Fail" );
	    k_printstr( 0, 9, "This processor does not support 64bit mode~!!" );
	    while( 1 ) ;
	}
	k_printstr(0, 9, "Copy IA-32e Kernel To 2M BYTE.. ..[    ]");
	k_copy_kernel64_imgto2Mbt();
	k_printstr( 35, 9, "Pass" );
	k_printstr( 0, 10, "Switch To IA-32e Mode" );
	k_switch_exec_64bitKernel();
	while(1);
}

void k_printstr(int x, int y, const char* scr_str){
	CHARACTER *pst_screen = (CHARACTER*)0xB8000;
	pst_screen += (y * 80) + x;
	for(int i = 0; scr_str[i] != 0; i++){
		pst_screen[i].b_charactor = scr_str[i];
	}
}

BOOL init_k64area(void){
	DWORD *cur_addr = (DWORD*) 0x100000;
	while((DWORD)cur_addr < 0x600000){
		*cur_addr = 0x00;
		if(*cur_addr != 0)
			return FALSE;
		cur_addr++;
	}
	return TRUE;
}

BOOL is_kmemoryenough(void){
	DWORD *cur_addr;
	cur_addr = (DWORD*)0x100000;

	while((DWORD) cur_addr < 0x4000000){
		*cur_addr = 0x12345678;
		if(*cur_addr != 0x12345678)
			return FALSE;
		cur_addr += (0x100000 / 4);
	}
	return TRUE;
}

void k_copy_kernel64_imgto2Mbt(void){
	WORD w_kernel32_sector_cnt, w_total_kernel_sector_cnt;
	DWORD *pdw_src_addr, *pdw_dst_addr;
	int i;

	pdw_src_addr = (DWORD*) (0x10000 + (5 * 512));
	pdw_dst_addr = (DWORD*) 0x200000;
	for(i = 0; i < 512/4; i++){
		*pdw_dst_addr = *pdw_src_addr;
		pdw_dst_addr++;
		pdw_src_addr++;
	}
}
