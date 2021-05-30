#pragma once

#ifdef DLL1_EXPORTS
#define DLL1_API __declspec(dllexport)
#else
#define DLL1_API __declspec(dllimport)
#endif

extern "C" DLL1_API void mirrorPixelsCpp(unsigned char*& pixels, int width, int height_top, int height_bot);