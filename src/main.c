#include <raylib.h>



int main() {
	InitWindow(800,800, "Hello world!");
	while(!WindowShouldClose()) {
		BeginDrawing();
		{
			ClearBackground(WHITE);
			DrawCircle(400,400, 100, BLACK);
		}
		EndDrawing();
	}
	return 0;
}
