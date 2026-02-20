// monument_clone.c
// Monument Valley style prototype using raylib
// Includes:
// - A* pathfinding
// - Equal-time node movement
// - Proper mid-movement interruption
// - Impossible geometry projection connections

#include "raylib.h"
#include "raymath.h"
#include <math.h>
#include <stdbool.h>

#define MAX_NODES 128
#define MAX_NEIGHBORS 16
#define MAX_PATH 128

#define MOVE_DURATION 0.4f

//--------------------------------------------------
// Math Helpers
//--------------------------------------------------

static float Vec3Distance(Vector3 a, Vector3 b)
{
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    float dz = a.z - b.z;

    return sqrtf(dx*dx + dy*dy + dz*dz);
}

static Vector3 Vec3Lerp(Vector3 a, Vector3 b, float t)
{
    return (Vector3){
        a.x + (b.x - a.x)*t,
        a.y + (b.y - a.y)*t,
        a.z + (b.z - a.z)*t
    };
}

//--------------------------------------------------
// Graph System
//--------------------------------------------------

typedef struct Node
{
    int id;
    Vector3 position;

    int neighbors[MAX_NEIGHBORS];
    int neighborCount;

} Node;

typedef struct Graph
{
    Node nodes[MAX_NODES];
    int nodeCount;

} Graph;

static void GraphInit(Graph* g)
{
    g->nodeCount = 0;
}

static int GraphAddNode(Graph* g, Vector3 pos)
{
    int id = g->nodeCount++;

    g->nodes[id].id = id;
    g->nodes[id].position = pos;
    g->nodes[id].neighborCount = 0;

    return id;
}

static void GraphAddEdge(Graph* g, int a, int b)
{
    g->nodes[a].neighbors[g->nodes[a].neighborCount++] = b;
    g->nodes[b].neighbors[g->nodes[b].neighborCount++] = a;
}

//--------------------------------------------------
// Impossible Geometry Check
//--------------------------------------------------

static bool IsConnectionActive(Graph* g, int a, int b, Camera3D* cam)
{
    Vector2 sa = GetWorldToScreen(g->nodes[a].position, *cam);
    Vector2 sb = GetWorldToScreen(g->nodes[b].position, *cam);

    float screenDist = Vector2Distance(sa, sb);

    return screenDist < 80.0f * (45/cam->fovy);
}

//--------------------------------------------------
// Pathfinding
//--------------------------------------------------

typedef struct PathNode
{
    float g;
    float f;
    int parent;

    bool open;
    bool closed;

} PathNode;

typedef struct Path
{
    int nodes[MAX_PATH];
    int count;

} Path;

static float Heuristic(Graph* g, int a, int b)
{
    return Vec3Distance(g->nodes[a].position, g->nodes[b].position);
}

static bool FindPath(Graph* g, int start, int goal, Camera3D* cam, Path* outPath)
{
    PathNode pn[MAX_NODES];

    for(int i=0;i<g->nodeCount;i++)
    {
        pn[i].g = 999999;
        pn[i].f = 999999;
        pn[i].parent = -1;
        pn[i].open = false;
        pn[i].closed = false;
    }

    pn[start].g = 0;
    pn[start].f = Heuristic(g,start,goal);
    pn[start].open = true;

    while(true)
    {
        int current = -1;
        float best = 999999;

        for(int i=0;i<g->nodeCount;i++)
        {
            if(pn[i].open && pn[i].f < best)
            {
                best = pn[i].f;
                current = i;
            }
        }

        if(current == -1)
            return false;

        if(current == goal)
            break;

        pn[current].open = false;
        pn[current].closed = true;

        Node* n = &g->nodes[current];

        for(int i=0;i<n->neighborCount;i++)
        {
            int nb = n->neighbors[i];

            if(!IsConnectionActive(g,current,nb,cam))
                continue;

            if(pn[nb].closed)
                continue;

            float tentative = pn[current].g +
                Vec3Distance(
                    g->nodes[current].position,
                    g->nodes[nb].position);

            if(!pn[nb].open)
                pn[nb].open = true;

            if(tentative >= pn[nb].g)
                continue;

            pn[nb].parent = current;
            pn[nb].g = tentative;
            pn[nb].f = tentative + Heuristic(g,nb,goal);
        }
    }

    outPath->count = 0;

    int cur = goal;

    while(cur != -1)
    {
        outPath->nodes[outPath->count++] = cur;
        cur = pn[cur].parent;
    }

    for(int i=0;i<outPath->count/2;i++)
    {
        int t = outPath->nodes[i];
        outPath->nodes[i] = outPath->nodes[outPath->count-1-i];
        outPath->nodes[outPath->count-1-i] = t;
    }

    return true;
}

//--------------------------------------------------
// Player System
//--------------------------------------------------

typedef struct Player
{
    Vector3 position;

    int currentNode;
    int fromNode;
    int toNode;

    Path path;

    int pathIndex;

    float moveT;

    bool moving;

} Player;

static int FindClosestNode(Graph* g, Vector3 pos)
{
    int closest = 0;
    float best = 999999;

    for(int i=0;i<g->nodeCount;i++)
    {
        float d = Vec3Distance(pos, g->nodes[i].position);

        if(d < best)
        {
            best = d;
            closest = i;
        }
    }

    return closest;
}

static void PlayerSetPath(Player* p, Graph* g, Path* path)
{
    if(path->count < 2)
        return;

    p->path = *path;

    p->pathIndex = 1;

    p->fromNode = path->nodes[0];
    p->toNode = path->nodes[1];

    p->moveT = 0;

    p->moving = true;
}

static void PlayerUpdate(Player* p, Graph* g, float dt)
{
    if(!p->moving)
        return;

    p->moveT += dt / MOVE_DURATION;

    Vector3 a = g->nodes[p->fromNode].position;
    Vector3 b = g->nodes[p->toNode].position;

    if(p->moveT >= 1.0f)
    {
        p->position = b;

        p->currentNode = p->toNode;

        p->pathIndex++;

        if(p->pathIndex >= p->path.count)
        {
            p->moving = false;
            return;
        }

        p->fromNode = p->currentNode;
        p->toNode = p->path.nodes[p->pathIndex];

        p->moveT = 0;
    }
    else
    {
        p->position = Vec3Lerp(a,b,p->moveT);
    }
}

//--------------------------------------------------
// Level
//--------------------------------------------------

static void CreateLevel(Graph* g)
{
    GraphInit(g);

    int n0 = GraphAddNode(g,(Vector3){0,0,0});
    int n1 = GraphAddNode(g,(Vector3){2,0,0});
    int n2 = GraphAddNode(g,(Vector3){4,0,0});
    int n3 = GraphAddNode(g,(Vector3){4,2,0});
    int n4 = GraphAddNode(g,(Vector3){4,4,0});

    GraphAddEdge(g,n0,n1);
    GraphAddEdge(g,n1,n2);
    GraphAddEdge(g,n2,n3);
    GraphAddEdge(g,n3,n4);

    GraphAddEdge(g,n0,n4); // impossible connection
}

//--------------------------------------------------
// Rendering
//--------------------------------------------------

static void DrawGraph(Graph* g, bool debug)
{
    for(int i=0;i<g->nodeCount;i++)
    {
        DrawCube(g->nodes[i].position,0.5f,0.2f,0.5f,LIGHTGRAY);

        if(debug)
        {
            DrawSphere(g->nodes[i].position,0.15f,RED);

            for(int j=0;j<g->nodes[i].neighborCount;j++)
            {
                int nb = g->nodes[i].neighbors[j];

                DrawLine3D(
                    g->nodes[i].position,
                    g->nodes[nb].position,
                    DARKGRAY);
            }
        }
    }
}

static int GetClickedNode(Graph* g, Camera3D cam)
{
    Vector2 mouse = GetMousePosition();

    int closest = -1;
    float bestDist = 999999;

    for(int i = 0; i < g->nodeCount; i++)
    {
        Vector2 screenPos = GetWorldToScreen(g->nodes[i].position, cam);

        float dist = Vector2Distance(mouse, screenPos);

        if(dist < 30.0f && dist < bestDist)
        {
            bestDist = dist;
            closest = i;
        }
    }

    return closest;
}
//--------------------------------------------------
// Main
//--------------------------------------------------

int main()
{
    InitWindow(1280,800,"Monument Valley Clone");

    Camera3D cam =
    {
        .position = {6,6,6},
        .target = {2,2,0},
        .up = {0,1,0},
        .fovy = 10,
        .projection = CAMERA_ORTHOGRAPHIC
    };

    Graph graph;
    CreateLevel(&graph);

    Player player = {0};

    player.currentNode = 0;
    player.position = graph.nodes[0].position;

    bool debug = true;

    SetTargetFPS(60);

    while(!WindowShouldClose())
    {
        float dt = GetFrameTime();

        if(IsMouseButtonPressed(MOUSE_LEFT_BUTTON))
        {
            int clicked = GetClickedNode(&graph,cam);

            if(clicked != -1)
            {
                player.currentNode =
                    FindClosestNode(&graph,player.position);

                Path path;

                if(FindPath(&graph,player.currentNode,clicked,&cam,&path))
                    PlayerSetPath(&player,&graph,&path);
            }
        }

        if(IsKeyPressed(KEY_F1))
            debug = !debug;

        PlayerUpdate(&player,&graph,dt);

        BeginDrawing();

        ClearBackground(RAYWHITE);

        BeginMode3D(cam);

        DrawGraph(&graph,debug);

        DrawCube(player.position,0.4f,0.7f,0.4f,BLUE);

        EndMode3D();

        DrawText("Click nodes to move",10,10,20,BLACK);

        EndDrawing();
    }

    CloseWindow();
}
