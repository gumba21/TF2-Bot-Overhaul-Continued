#if defined _knowledge_lifecycle_inc
 #endinput
#endif
#define _knowledge_lifecycle_inc

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMax)
{
    if (GetEngineVersion() != Engine_TF2)
    {
        strcopy(error, errorMax, "TF2 Bot Battlefield Knowledge only supports Team Fortress 2.");
        return APLRes_Failure;
    }

    RegPluginLibrary("bot_knowledge");
    CreateNative("BK_IsEnabled", Native_IsEnabled);
    CreateNative("BK_GetKnownEnemies", Native_GetKnownEnemies);
    CreateNative("BK_GetBurningTeammates", Native_GetBurningTeammates);
    CreateNative("BK_GetLastKnownPosition", Native_GetLastKnownPosition);
    CreateNative("BK_GetLargestEnemyCluster", Native_GetLargestEnemyCluster);
    CreateNative("BK_GetTeamState", Native_GetTeamState);
    CreateNative("BK_GetFrontLine", Native_GetFrontLine);
    CreateNative("BK_GetThreatAtPosition", Native_GetThreatAtPosition);
    CreateNative("BK_FindBestMadMilkTarget", Native_FindBestMadMilkTarget);
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_CvarEnabled = CreateConVar("tf_bot_knowledge_enabled", "1", "Enable the Battlefield Knowledge System.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_CvarDebug = CreateConVar("tf_bot_knowledge_debug", "0", "Enable verbose Battlefield Knowledge debug output.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_CvarUpdateRate = CreateConVar("tf_bot_knowledge_update_rate", "0.10", "Base update interval.", FCVAR_NONE, true, 0.05, true, 1.0);
    g_CvarGroupRate = CreateConVar("tf_bot_knowledge_group_update_rate", "0.50", "Group-analysis interval.", FCVAR_NONE, true, 0.20, true, 3.0);
    g_CvarDirectorRate = CreateConVar("tf_bot_knowledge_director_update_rate", "0.75", "Battlefield director-analysis interval.", FCVAR_NONE, true, 0.25, true, 5.0);
    g_CvarMemoryDuration = CreateConVar("tf_bot_knowledge_memory_duration", "7.0", "Maximum ordinary memory lifetime.", FCVAR_NONE, true, 1.0, true, 30.0);
    g_CvarConfidenceDecay = CreateConVar("tf_bot_knowledge_confidence_decay", "0.12", "Confidence lost per second after confirmation.", FCVAR_NONE, true, 0.01, true, 1.0);
    g_CvarSpatialCellSize = CreateConVar("tf_bot_knowledge_spatial_cell_size", "768.0", "Spatial bucket size.", FCVAR_NONE, true, 256.0, true, 2048.0);
    g_CvarObserverBudget = CreateConVar("tf_bot_knowledge_max_queries_per_frame", "6", "Observers updated per knowledge tick.", FCVAR_NONE, true, 1.0, true, 32.0);
    g_CvarTeamSharing = CreateConVar("tf_bot_knowledge_team_sharing", "1", "Share high-value observations with nearby teammates.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_CvarUnfairAccess = CreateConVar("tf_bot_knowledge_unfair_access", "0", "Allow bots to receive omnipresent server-truth knowledge.", FCVAR_CHEAT, true, 0.0, true, 1.0);
    g_CvarVisionDistance = CreateConVar("tf_bot_knowledge_vision_distance", "2600.0", "Maximum ordinary perception distance.", FCVAR_NONE, true, 256.0, true, 8192.0);
    g_CvarVisionFov = CreateConVar("tf_bot_knowledge_vision_fov", "155.0", "Ordinary perception field of view.", FCVAR_NONE, true, 30.0, true, 360.0);
    g_CvarHearingDistance = CreateConVar("tf_bot_knowledge_hearing_distance", "1150.0", "Distance for weapon and damage hearing.", FCVAR_NONE, true, 128.0, true, 4096.0);
    g_CvarGroupDistance = CreateConVar("tf_bot_knowledge_group_distance", "725.0", "Maximum connected distance for provisional group membership.", FCVAR_NONE, true, 200.0, true, 1600.0);
    g_CvarMadMilkEnabled = CreateConVar("tf_bot_knowledge_mad_milk", "0", "Enable the observation-tested Mad Milk pilot.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_CvarMadMilkThreshold = CreateConVar("tf_bot_knowledge_mad_milk_threshold", "62.0", "Minimum utility required for Mad Milk use.", FCVAR_NONE, true, 0.0, true, 200.0);

    RegAdminCmd("sm_bk_inspect", Command_BKInspect, ADMFLAG_GENERIC, "sm_bk_inspect [target] - inspect observer-scoped battlefield knowledge.");
    RegAdminCmd("sm_bk_groups", Command_BKGroups, ADMFLAG_GENERIC, "Display current group and battlefield analysis.");
    RegAdminCmd("sm_bk_memory", Command_BKMemory, ADMFLAG_GENERIC, "sm_bk_memory [target] - display remembered enemies.");

    HookEvent("player_spawn", Event_PlayerLifecycle, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
    HookEvent("player_team", Event_PlayerLifecycle, EventHookMode_Post);
    HookEvent("player_changeclass", Event_PlayerLifecycle, EventHookMode_Post);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
    HookEvent("object_built", Event_ObjectChanged, EventHookMode_Post);
    HookEvent("object_destroyed", Event_ObjectChanged, EventHookMode_Post);
    HookEvent("teamplay_point_captured", Event_ObjectiveChanged, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_RoundReset, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", Event_RoundReset, EventHookMode_PostNoCopy);

    AutoExecConfig(true, "tf_bot_knowledge");
    ResetAllKnowledge();
    RestartUpdateTimer();
}

public void OnConfigsExecuted()
{
    RestartUpdateTimer();
}

public void OnMapStart()
{
    ResetAllKnowledge();
    CreateTimer(0.2, Timer_ScanMapEntities, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
    ResetAllKnowledge();
}

public void OnClientPutInServer(int client)
{
    ResetClientKnowledge(client);
    UpdateWorldPlayer(client, GetGameTime());
}

public void OnClientDisconnect(int client)
{
    ClearSubjectFromAllObservers(client);
    ResetClientKnowledge(client);
    ClearWorldPlayer(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    BKEntityKind kind = GetBuildingKind(classname);
    if (kind != BKEntity_None)
    {
        RegisterBuilding(entity, kind);
        return;
    }

    if (IsObjectiveClassname(classname))
    {
        RegisterObjective(entity, classname);
    }
}

public void OnEntityDestroyed(int entity)
{
    int buildingSlot = FindBuildingSlot(entity);
    if (buildingSlot != BK_INVALID_SLOT)
    {
        ClearBuildingSlot(buildingSlot);
    }

    int objectiveSlot = FindObjectiveSlot(entity);
    if (objectiveSlot != BK_INVALID_SLOT)
    {
        ClearObjectiveSlot(objectiveSlot);
    }
}

void RestartUpdateTimer()
{
    delete g_UpdateTimer;
    float interval = g_CvarUpdateRate != null ? g_CvarUpdateRate.FloatValue : 0.10;
    g_UpdateTimer = CreateTimer(interval, Timer_KnowledgeUpdate, _, TIMER_REPEAT);
}

public Action Timer_KnowledgeUpdate(Handle timer)
{
    if (!g_CvarEnabled.BoolValue)
    {
        return Plugin_Continue;
    }

    float now = GetGameTime();
    UpdateWorldRegistry(now);

    int observerBudget = g_CvarObserverBudget.IntValue;
    for (int i = 0; i < observerBudget; i++)
    {
        int observer = NextObserver();
        if (observer == 0)
        {
            break;
        }

        UpdateObserverKnowledge(observer, now);
        UpdateObserverBuildingKnowledge(observer, now);
    }

    if (now - g_LastGroupUpdate >= g_CvarGroupRate.FloatValue)
    {
        RebuildGroups(now);
        g_LastGroupUpdate = now;
    }

    if (now - g_LastDirectorUpdate >= g_CvarDirectorRate.FloatValue)
    {
        UpdateBattlefieldAnalysis(now);
        g_LastDirectorUpdate = now;
    }

    return Plugin_Continue;
}

public Action Timer_ScanMapEntities(Handle timer)
{
    ScanExistingEntities();
    return Plugin_Stop;
}

int NextObserver()
{
    for (int attempts = 0; attempts < MaxClients; attempts++)
    {
        g_ObserverCursor++;
        if (g_ObserverCursor > MaxClients)
        {
            g_ObserverCursor = 1;
        }

        if (g_WorldConnected[g_ObserverCursor] && g_WorldAlive[g_ObserverCursor] && g_WorldIsBot[g_ObserverCursor])
        {
            return g_ObserverCursor;
        }
    }

    return 0;
}
