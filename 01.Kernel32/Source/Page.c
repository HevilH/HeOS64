#include "Page.h"

void k_init_PageTables(void){

	PML4ENTRY *pst_PML4_entry;
	PDPTENTRY *pst_PDPT_entry;
	PDENTRY *pst_PD_entry;
	DWORD dw_map_addr;
	int i;

	//PML4 테이블 생성
	pst_PML4_entry = (PML4ENTRY*) 0x100000;
	k_set_PageEntryData(&(pst_PML4_entry[0]), 0x00, 0x101000, PAGE_FLAGS_DEFAULT, 0);
	for(i = 1; i < PAGE_MAXENTRYCOUNT; i++)
		k_set_PageEntryData(&(pst_PML4_entry[i]), 0, 0, 0, 0);

	//페이지 디렉토리 포인터 테이블 생성
	pst_PDPT_entry = (PDPTENTRY*) 0x101000;

	for(i = 0; i < 64; i++)
		k_set_PageEntryData(&(pst_PDPT_entry[i]), 0, 0x102000 + (i * PAGE_TABLESIZE), PAGE_FLAGS_DEFAULT, 0);
	for(i = 64; i < PAGE_MAXENTRYCOUNT; i++)
		k_set_PageEntryData(&(pst_PDPT_entry[i]), 0, 0, 0, 0);

	//페이지 디렉토리 테이블 생성
	pst_PD_entry = (PDENTRY*) 0x102000;
	dw_map_addr = 0;
	for(i = 0; i < PAGE_MAXENTRYCOUNT * 64; i++){
		k_set_PageEntryData(&(pst_PD_entry[i]), (i * (PAGE_DEFAULTSIZE >> 20)) >> 12, dw_map_addr, PAGE_FLAGS_DEFAULT|PAGE_FLAGS_PS, 0);
		dw_map_addr += PAGE_DEFAULTSIZE;
	}
}

void k_set_PageEntryData(PTENTRY* pst_entry, DWORD dw_upper_base_addr, DWORD dw_lower_base_addr, DWORD dw_lower_flags, DWORD dw_upper_flags){
	pst_entry->dw_attr_and_lower_base_addr = dw_lower_base_addr | dw_lower_flags;
	pst_entry->dw_upper_base_addr_and_EXB = (dw_upper_base_addr & 0xFF) | dw_upper_flags;
}
