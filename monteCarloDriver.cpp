#include <stdio.h>
#include <random>
#include <chrono>
#include <windows.h>
#include <winuser.h>


extern "C"
{	
	int generateRandomNumber(int upper)
	{
		std::random_device rd; 
		std::mt19937 gen(rd());
		std::uniform_int_distribution<> dis(0, upper);
		return dis(gen);
	}

	void clearScreen()
	{	
		COORD cursorPosition;
		cursorPosition.X = 1;
		cursorPosition.Y = 0;
		SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), cursorPosition);
	}

	void asmMain();
};


int main()
{
	system("cls");
	clearScreen();
	asmMain();
	printf("\nReturned from asmfunc\n");
}
