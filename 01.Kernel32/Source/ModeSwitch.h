#ifndef __MODESWITCH_H__
#define __MODESWITCH_H__

#include "Types.h"

void k_read_CPUID(DWORD dwEAX, DWORD *pdwEAX, DWORD *pdwEBX, DWORD *pdwECX, DWORD *pdwEDX);
void k_switch_exec_64bitKernel(void);

#endif

