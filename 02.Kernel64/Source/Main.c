#include "Types.h"

void k_printstr(int x, int y, const char* scr_str);

void Main(){
	k_printstr(0, 10, "Switch To IA-32e Mode Success~!!");
	k_printstr(0, 11, "IA-32e C Language Kernel Start....[Pass]");
	while(1);
}
void k_printstr(int x, int y, const char* scr_str){
	CHARACTER *pst_screen = (CHARACTER*)0xB8000;
	pst_screen += (y * 80) + x;
	for(int i = 0; scr_str[i] != 0; i++){
		pst_screen[i].b_charactor = scr_str[i];
	}
}
