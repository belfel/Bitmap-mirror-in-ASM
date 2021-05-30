#include<fstream>
#include<iostream>
#include<chrono>
#include<thread>
#include<string>
#include "flipBMP.h"
#include "flipBMP_ASM.h"


using namespace std;

void saveBMP(const char* filename, int size, unsigned char* header, unsigned char* pixels)
{
	FILE* f;
	f = fopen(filename, "wb");
	fwrite(header, 1, 54, f);
	fwrite(pixels, 1, size, f);
	fclose(f);
}

void menu(char* output, int threads, int width, int height, int padded, unsigned char* header, unsigned char*& pixels)
{
	system("cls");
	cout << "1. Wykonaj odwracanie w C.\n2. Wykonaj odwracanie w ASM.\n3. Zmien liczbe watkow.\n\n9. Wyjdz." << endl;
	cout << "\n\nAktualna liczba watkow: " << threads << "\n\n" << endl;
	cout << "Wybor (1-9): ";
	int o;
	cin >> o;
	thread* ttab = new thread[threads];

	if (o == 1)
	{
		for (int i = 0; i < threads; i++)
			ttab[i] = thread(mirrorPixelsCpp, ref(pixels), padded / 3, height / threads * (i + 1), height / threads * i);
		auto start = chrono::high_resolution_clock::now();
		for (int i = 0; i < threads; i++)
			ttab[i].join();
		auto elapsed = std::chrono::high_resolution_clock::now() - start;
		long miliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
		cout << "\nCzas wykonania dla " << threads << " watkow: " << miliseconds << " ms" << endl;
		//saveBMP(output, height * padded, header, pixels);
		int enter;
		cin >> enter;
		delete[] ttab;
		menu(output, threads, width, height, padded, header, pixels);
	}

	else if (o == 2)
	{
		for (int i = 0; i < threads; i++)
			ttab[i] = thread(MirrorASM, ref(pixels), padded, height / threads * (i + 1), height / threads * i + 1);
		auto start = chrono::high_resolution_clock::now();
		for (int i = 0; i < threads; i++)
			ttab[i].join();
		auto elapsed = std::chrono::high_resolution_clock::now() - start;
		long miliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
		cout << "\nCzas wykonania dla " << threads << " watkow: " << miliseconds << " ms" << endl;
		saveBMP(output, height * padded, header, pixels);
		int enter;
		cin >> enter;
		delete[] ttab;
		menu(output, threads, width, height, padded, header, pixels);
	}

	else if (o == 3)
	{
		system("cls");
		cout << "\nLiczba watkow: ";
		int t;
		cin >> t;
		menu(output, t, width, height, padded, header, pixels);
	}

	else if (o == 9)
	{
		delete[] ttab;
		exit(0);
	}

	else
	{
		menu(output, threads, width, height, padded, header, pixels);
	}
}

int main(int argc, char* argv[])
{
	char input[] = "test.bmp";
	char output[] = "mirrored.bmp";
	int threads = 4;

	for (int i = 1; i < argc; i++)
	{
		if (strcmp(argv[i], "-i") == 0)
			strcpy(input, argv[i + 1]);
		else if (strcmp(argv[i], "-o") == 0)
			strcpy(output, argv[i + 1]);
		else if (strcmp(argv[i], "-t") == 0)
			threads = atoi(argv[i + 1]);
	}

	unsigned char header[54];
	FILE* f;
	f = fopen(input, "rb");
	fread(header, 1, 54, f);

	int width = *(int*)&header[18];
	int height = *(int*)&header[22];
	int padded = (width * 3 + 3) & (~3);
	int size = padded * height;
	unsigned char* pixels = new unsigned char[size];

	fread(pixels, 1, size, f);
	fclose(f);

	menu(output, threads, width, height, padded, header, pixels);
	
	delete[] pixels;
}