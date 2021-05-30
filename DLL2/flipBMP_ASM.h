#pragma once

#ifdef DLL2_EXPORTS
#define DLL2_API __declspec(dllexport)
#else
#define DLL2_API __declspec(dllimport)
#endif

#include<Windows.h>


extern "C" DLL2_API void MirrorASM(unsigned char*, DWORD, DWORD, DWORD);