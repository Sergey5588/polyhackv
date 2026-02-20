#include <raylib.h>



int main() {
	InitWindow(800,800, "Hello world!");
	Camera3D cam = {0};
	cam.position = (Vector3){ 0.0f, 10.0f, 10.0f };  // Camera position
    cam.target = (Vector3){ 0.0f, 0.0f, 0.0f };      // Camera looking at point
    cam.up = (Vector3){ 0.0f, 1.0f, 0.0f };          // Camera up vector (rotation towards target)
    cam.fovy = 45.0f;                                // Camera field-of-view Y
    cam.projection = CAMERA_PERSPECTIVE;             // Camera mode type
													
	Vector3 cubePos = (Vector3){0,0,0};
	while(!WindowShouldClose()) {
		UpdateCamera(&cam, CAMERA_FREE);
		BeginDrawing();
		{
			BeginMode3D(cam);
			{
				DrawCube(cubePos, 2.0f, 2.0f, 2.0f, RED);
                DrawCubeWires(cubePos, 2.0f, 2.0f, 2.0f, MAROON);

                DrawGrid(10, 1.0f);
				ClearBackground(WHITE);

			}
			EndMode3D();
			DrawFPS(10,10);
		}
		EndDrawing();
	}
	return 0;
}
