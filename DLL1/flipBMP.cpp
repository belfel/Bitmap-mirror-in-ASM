#include "pch.h"
#include "flipBMP.h"


void mirrorPixelsCpp(unsigned char*& pixels, int w, int h_t, int h_b)
{
	unsigned char temp[3];
	int padded = 0;
	if (w % 4)
		padded = 4 - (w % 4);
	for (int r = h_b; r < h_t; r++)
		for (int c = 0; c < w / 2; c++)
		{
			// Kopia piksela z prawej strony
			temp[0] = pixels[r * w * 3 + (w - 1 - c) * 3 - padded];									// B
			temp[1] = pixels[r * w * 3 + (w - 1 - c) * 3 + 1 - padded];								// G
			temp[2] = pixels[r * w * 3 + (w - 1 - c) * 3 + 2 - padded];								// R

			// Nadpisanie piksela z prawej strony odpowiadaj¹cym z lewej strony
			pixels[r * w * 3 + (w - 1 - c) * 3 - padded] = pixels[r * w * 3 + c * 3];			// B
			pixels[r * w * 3 + (w - 1 - c) * 3 + 1 - padded] = pixels[r * w * 3 + c * 3 + 1];	// G
			pixels[r * w * 3 + (w - 1 - c) * 3 + 2 - padded] = pixels[r * w * 3 + c * 3 + 2];	// R

			// Nadpisenie piksela z lewej strony kopi¹ odpowiadaj¹cego z prawej strony
			pixels[r * w * 3 + c * 3] = temp[0];												// B
			pixels[r * w * 3 + c * 3 + 1] = temp[1];											// G
			pixels[r * w * 3 + c * 3 + 2] = temp[2];											// R
		}
}