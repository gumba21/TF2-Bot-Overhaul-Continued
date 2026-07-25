#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <bot_knowledge>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1.0"
#define BK_MAX_GROUPS 16
#define BK_MAX_BUILDINGS 128
#define BK_MAX_OBJECTIVES 32
#define BK_INVALID_SLOT -1
#define BK_MAD_MILK_INDEX 222
#define BK_FESTIVE_MAD_MILK_INDEX 1121

public Plugin myinfo =
{
    name = "TF2 Bot Battlefield Knowledge",
    author = "gumba21 / OpenAI",
    description = "Perception-aware shared battlefield information for TF2 bots",
    version = PLUGIN_VERSION,
    url = "https://github.com/gumba21/TF2-Bot-Overhaul-Continued"
};

ConVar g_CvarEnabled;
ConVar g_CvarDebug;
ConVar g_CvarUpdateRate;
ConVar g_CvarGroupRate;
ConVar g_CvarDirectorRate;
ConVar g_CvarMemoryDuration;
ConVar g_CvarConfidenceDecay;
ConVar g_CvarSpatialCellSize;
ConVar g_CvarObserverBudget;
ConVar g_CvarTeamSharing;
ConVar g_CvarUnfairAccess;
ConVar g_CvarVisionDistance;
ConVar g_CvarVisionFov;
ConVar g_CvarHearingDistance;
ConVar g_CvarGroupDistance;
ConVar g_CvarMadMilkEnabled;
ConVar g_CvarMadMilkThreshold;

// Authoritative player registry. Fair consumers never receive this directly.
bool g_WorldConnected[MAXPLAYERS + 1];
bool g_WorldAlive[MAXPLAYERS + 1];
bool g_WorldIsBot[MAXPLAYERS + 1];
int g_WorldTeam[MAXPLAYERS + 1];
TFClassType g_WorldClass[MAXPLAYERS + 1];
int g_WorldHealth[MAXPLAYERS + 1];
int g_WorldMaxHealth[MAXPLAYERS + 1];
float g_WorldHealthPercent[MAXPLAYERS + 1];
float g_WorldPosition[MAXPLAYERS + 1][3];
float g_WorldVelocity[MAXPLAYERS + 1][3];
float g_WorldLastPosition[MAXPLAYERS + 1][3];
float g_WorldLastDamageAt[MAXPLAYERS + 1];
float g_WorldLastDamageDealtAt[MAXPLAYERS + 1];
int g_WorldLabels[MAXPLAYERS + 1];
BKMovementState g_WorldMovement[MAXPLAYERS + 1];
BKCombatState g_WorldCombat[MAXPLAYERS + 1];
int g_PlayerCellX[MAXPLAYERS + 1];
int g_PlayerCellY[MAXPLAYERS + 1];
int g_PlayerCellZ[MAXPLAYERS + 1];

// Cached indexes.
int g_TeamMask[4];
int g_AliveTeamMask[4];
int g_BurningTeamMask[4];
int g_CriticalTeamMask[4];
int g_ClassTeamMask[4][10];

// Observer-scoped player knowledge.
bool g_KnownPlayer[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_PlayerVisible[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_KnownPosition[MAXPLAYERS + 1][MAXPLAYERS + 1][3];
float g_KnownVelocity[MAXPLAYERS + 1][MAXPLAYERS + 1][3];
float g_KnownConfidence[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_KnownUncertainty[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_KnownFirstAt[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_KnownConfirmedAt[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_KnownUpdatedAt[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_KnownExpiresAt[MAXPLAYERS + 1][MAXPLAYERS + 1];
BKKnowledgeSource g_KnownSource[MAXPLAYERS + 1][MAXPLAYERS + 1];
BKKnowledgeScope g_KnownScope[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_KnownLabels[MAXPLAYERS + 1][MAXPLAYERS + 1];

// Building registry and observer knowledge.
bool g_BuildingActive[BK_MAX_BUILDINGS];
int g_BuildingEntity[BK_MAX_BUILDINGS];
int g_BuildingTeam[BK_MAX_BUILDINGS];
BKEntityKind g_BuildingKind[BK_MAX_BUILDINGS];
int g_BuildingHealth[BK_MAX_BUILDINGS];
float g_BuildingPosition[BK_MAX_BUILDINGS][3];
bool g_KnownBuilding[MAXPLAYERS + 1][BK_MAX_BUILDINGS];
float g_KnownBuildingConfidence[MAXPLAYERS + 1][BK_MAX_BUILDINGS];
float g_KnownBuildingPosition[MAXPLAYERS + 1][BK_MAX_BUILDINGS][3];
float g_KnownBuildingUpdatedAt[MAXPLAYERS + 1][BK_MAX_BUILDINGS];

// Objective registry.
bool g_ObjectiveActive[BK_MAX_OBJECTIVES];
int g_ObjectiveEntity[BK_MAX_OBJECTIVES];
float g_ObjectivePosition[BK_MAX_OBJECTIVES][3];
char g_ObjectiveClassname[BK_MAX_OBJECTIVES][64];
float g_LastObjectiveEventAt;

// Stable group records.
bool g_GroupActive[BK_MAX_GROUPS];
int g_GroupId[BK_MAX_GROUPS];
int g_GroupTeam[BK_MAX_GROUPS];
int g_GroupMembers[BK_MAX_GROUPS];
int g_GroupMemberCount[BK_MAX_GROUPS];
float g_GroupCentroid[BK_MAX_GROUPS][3];
float g_GroupVelocity[BK_MAX_GROUPS][3];
float g_GroupRadius[BK_MAX_GROUPS];
float g_GroupCohesion[BK_MAX_GROUPS];
float g_GroupConfidence[BK_MAX_GROUPS];
float g_GroupUpdatedAt[BK_MAX_GROUPS];
BKMovementState g_GroupMovement[BK_MAX_GROUPS];

int g_PreviousGroupId[BK_MAX_GROUPS];
int g_PreviousGroupTeam[BK_MAX_GROUPS];
int g_PreviousGroupMembers[BK_MAX_GROUPS];
int g_PreviousGroupCount;
int g_NextGroupId = 1;
int g_MainGroupSlot[4];

BKTeamState g_TeamState[4];
float g_FrontLine[4][3];
float g_FrontLineConfidence[4];
float g_LastGroupUpdate;
float g_LastDirectorUpdate;
float g_LastRegistryUpdate;
int g_ObserverCursor = 1;

// Optional Mad Milk pilot state. Disabled by default.
bool g_MilkPending[MAXPLAYERS + 1];
float g_MilkTarget[MAXPLAYERS + 1][3];
float g_MilkPendingUntil[MAXPLAYERS + 1];
float g_MilkCooldownUntil[MAXPLAYERS + 1];

Handle g_UpdateTimer;

#include "knowledge/knowledge_lifecycle.inc"
#include "knowledge/knowledge_registry.inc"
#include "knowledge/knowledge_perception.inc"
#include "knowledge/knowledge_groups.inc"
#include "knowledge/knowledge_queries.inc"
#include "knowledge/knowledge_runtime.inc"
#include "knowledge/knowledge_debug.inc"
