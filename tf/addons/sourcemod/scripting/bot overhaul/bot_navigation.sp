#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <navmesh>
#include <bot_knowledge>
#include <bot_navigation>

#pragma semicolon 1
#pragma newdecls required

#define BN_VERSION "1.2.0"
#define BN_MAX_AREAS 8192
#define BN_MAX_EDGES 49152
#define BN_MAX_ROUTE_AREAS 96
#define BN_MAX_CONTEXT_THREATS 24
#define BN_INVALID_AREA -1

public Plugin myinfo =
{
    name = "TF2 Bot Tactical Navigation",
    author = "gumba21 / OpenAI",
    description = "Nav-mesh tactical routing and movement requests for TF2 bots",
    version = BN_VERSION,
    url = "https://github.com/gumba21/TF2-Bot-Overhaul-Continued"
};

ConVar g_NavEnabled;
ConVar g_NavDebug;
ConVar g_NavExtensionRequired;
ConVar g_NavUpdateRate;
ConVar g_NavAreaUpdateRate;
ConVar g_NavControlUpdateRate;
ConVar g_NavRouteBudget;
ConVar g_NavMaxNodes;
ConVar g_NavRouteCacheTime;
ConVar g_NavDamageHalfLife;
ConVar g_NavDeathHalfLife;
ConVar g_NavSentryDanger;
ConVar g_NavSniperDanger;
ConVar g_NavMedicPilot;
ConVar g_NavScoutPilot;
ConVar g_NavRetreatPilot;
ConVar g_NavDrawRoutes;
ConVar g_NavLogRoutes;

bool g_NavLibraryAvailable;
bool g_KnowledgeAvailable;
bool g_GraphReady;
bool g_StaticAnalysisComplete;
int g_AreaCount;
int g_EdgeCount;
StringMap g_AreaSlotByIndex;

int g_AreaIndex[BN_MAX_AREAS];
int g_AreaId[BN_MAX_AREAS];
float g_AreaCenter[BN_MAX_AREAS][3];
float g_AreaMins[BN_MAX_AREAS][3];
float g_AreaMaxs[BN_MAX_AREAS][3];
float g_AreaWidth[BN_MAX_AREAS];
float g_AreaLength[BN_MAX_AREAS];
float g_AreaHeight[BN_MAX_AREAS];
float g_AreaOpenness[BN_MAX_AREAS];
float g_AreaCover[BN_MAX_AREAS];
float g_AreaChoke[BN_MAX_AREAS];
float g_AreaHighGround[BN_MAX_AREAS];
int g_AreaLabels[BN_MAX_AREAS];
int g_AreaEdgeStart[BN_MAX_AREAS];
int g_AreaEdgeCount[BN_MAX_AREAS];
int g_EdgeTarget[BN_MAX_EDGES];
float g_EdgeDistance[BN_MAX_EDGES];
int g_EdgeDirection[BN_MAX_EDGES];

float g_AreaDamageHeat[4][BN_MAX_AREAS];
float g_AreaDeathHeat[4][BN_MAX_AREAS];
float g_AreaTraffic[4][BN_MAX_AREAS];
float g_AreaControl[4][BN_MAX_AREAS];
float g_AreaPresence[4][BN_MAX_AREAS];
float g_AreaCombat[4][BN_MAX_AREAS];
float g_AreaLastDynamic[BN_MAX_AREAS];

int g_ClientArea[MAXPLAYERS + 1];
float g_ClientLastAreaPosition[MAXPLAYERS + 1][3];
float g_ClientNextAreaUpdate[MAXPLAYERS + 1];
float g_NextPilotEvaluation[MAXPLAYERS + 1];
float g_PilotLastProgressAt[MAXPLAYERS + 1];
float g_PilotLastPosition[MAXPLAYERS + 1][3];

BNRouteStatus g_RouteStatus[MAXPLAYERS + 1];
BNRouteProfile g_RouteProfile[MAXPLAYERS + 1];
BNMovementPurpose g_RoutePurpose[MAXPLAYERS + 1];
int g_RoutePriority[MAXPLAYERS + 1];
bool g_RouteInterruptible[MAXPLAYERS + 1];
float g_RouteMinimumUntil[MAXPLAYERS + 1];
float g_RouteExpiresAt[MAXPLAYERS + 1];
float g_RouteCreatedAt[MAXPLAYERS + 1];
float g_RouteGoal[MAXPLAYERS + 1][3];
int g_RouteGoalArea[MAXPLAYERS + 1];
int g_RouteAreas[MAXPLAYERS + 1][BN_MAX_ROUTE_AREAS];
int g_RouteLength[MAXPLAYERS + 1];
int g_RouteCursor[MAXPLAYERS + 1];
float g_RouteDistance[MAXPLAYERS + 1];
float g_RouteDanger[MAXPLAYERS + 1];
float g_RouteCost[MAXPLAYERS + 1];
float g_RouteConfidence[MAXPLAYERS + 1];
float g_RouteNextPoint[MAXPLAYERS + 1][3];
char g_RouteFailure[MAXPLAYERS + 1][64];

ArrayList g_RouteQueue;
int g_SearchGeneration;
int g_SearchSeen[BN_MAX_AREAS];
int g_SearchClosed[BN_MAX_AREAS];
int g_SearchParent[BN_MAX_AREAS];
float g_SearchG[BN_MAX_AREAS];
float g_SearchF[BN_MAX_AREAS];
int g_SearchHeap[BN_MAX_AREAS];
int g_SearchHeapLength;
int g_SearchNodesExpanded;

int g_ContextSentryArea[BN_MAX_CONTEXT_THREATS];
float g_ContextSentryConfidence[BN_MAX_CONTEXT_THREATS];
int g_ContextSentryCount;
int g_ContextSniperArea[BN_MAX_CONTEXT_THREATS];
float g_ContextSniperConfidence[BN_MAX_CONTEXT_THREATS];
int g_ContextSniperCount;
int g_ContextObserver;
int g_ContextThreatGeneration;
int g_ContextThreatSeen[BN_MAX_AREAS];
float g_ContextKnowledgeThreat[BN_MAX_AREAS];

float g_RouteCalculationTotal;
float g_RouteCalculationMaximum;
int g_RouteCalculationCount;
int g_RouteCacheHits;
float g_LastDynamicUpdate;
float g_LastControlUpdate;
int g_StaticAnalysisCursor;
Handle g_NavigationTimer;
int g_DebugBeamSprite = -1;

#include "navigation/navigation_core.inc"
#include "navigation/navigation_graph.inc"
#include "navigation/navigation_dynamic.inc"
#include "navigation/navigation_routes.inc"
#include "navigation/navigation_pilots.inc"
#include "navigation/navigation_debug.inc"
