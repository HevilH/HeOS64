#ifndef __TYPES_H__
#define __TYPES_H__

#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int
#define QWORD unsigned long
#define BOOL unsigned char

#define TRUE 1
#define FALSE 0
#define NULL 0

#pragma pack(push, 1)

//���� ��� �� �ؽ�Ʈ ��� ȭ���� �����ϴ� �ڷᱸ��
typedef struct kCharactorStruct{
	BYTE b_charactor;
	BYTE b_attr;
}CHARACTER;

#pragma pack(pop)
#endif /*__TYPES_H__*/