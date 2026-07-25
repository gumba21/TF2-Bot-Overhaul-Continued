#if defined _navigation_core_inc
 #endinput
#endif
#define _navigation_core_inc

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMax)
{
    if (GetEngineVersion() != Engine_TF2)
    {
        strcopy(error, errorMax, "TF2 Bot Tactical Navigation only supports Team Fortress 2.");
        return APLRes_Failure;
    }

    RegPluginLibrary("bot_navigation");
    CreateNative("BN_IsAvailable", Native_BNIsAvailable);
    CreateNative("BN_GetAreaFromPosition", Native_BNGetAreaFromPosition);
    CreateNative("BN_GetCurrentAreaForClient", Native_BNGetCurrentAreaForClient);
    CreateNative("BN_GetAreaCenter", Native_BNGetAreaCenter);
    CreateNative("BN_GetAreaBounds", Native_BNGetAreaBounds);
    CreateNative("BN_GetAreaLabels", Native_BNGetAreaLabels);
    CreateNative("BN_GetAreaDanger", Native_BNGetAreaDanger);
    CreateNative("BN_GetAreaControl", Native_BNGetAreaControl);
    CreateNative("BN_GetAreaTraffic", Native_BNGetAreaTraffic);
    CreateNative("BN_RequestRoute", Native_BNRequestRoute);
    CreateNative("BN_CancelRoute", Native_BNCancelRoute);
    CreateNative("BN_GetRouteStatus", Native_BNGetRouteStatus);
    CreateNative("BN_GetNextTraversalPoint", Native_BNGetNextTraversalPoint);
    CreateNative("BN_GetRouteMetrics", Native_BNGetRouteMetrics);
    CreateNative("BN_GetSafestNearbyArea", Native_BNGetSafestNearbyArea);
    CreateNative("BN_GetRetreatDestination", Native_BNGetRetreatDestination);
    CreateNative("BN_GetBestFlankApproach", Native_BNGetBestFlankApproach);

    MarkNativeAsOptional("NavMesh_Exists");
    MarkNativeAsOptional("NavMesh_GetGridSizeX");
    MarkNativeAsOptional("NavMesh_GetGridSizeY");
    MarkNativeAsOptional("NavMesh_GetAreasOnGrid");
    MarkNativeAsOptional("NavMesh_GetNearestArea");
    MarkNativeAsOptional("NavMeshArea_GetID");
    MarkNativeAsOptional("NavMeshArea_GetCenter");
    MarkNativeAsOptional("NavMeshArea_GetExtentLow");
    MarkNativeAsOptional("NavMeshArea_GetExtentHigh");
    MarkNativeAsOptional("NavMeshArea_GetAdjacentList");
    MarkNativeAsOptional("NavMeshArea_ComputeClosestPointInPortal");
    MarkNativeAsOptional("NavMeshArea_GetClosestPointOnArea");

    MarkNativeAsOptional("BK_IsEnabled");
    MarkNativeAsOptional("BK_GetKnownEnemies");
    MarkNativeAsOptional("BK_GetLastKnownPosition");
    MarkNativeAsOptional("BK_GetFrontLine");
    MarkNativeAsOptional("BK_GetThreatAtPosition");
    MarkNativeAsOptional("BK_GetLargestEnemyCluster");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_NavEnabled = CreateConVar("tf_bot_navigation_enabled", "1", "Enable Tactical Navigation tracking and observation mode.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_NavDebug = CreateConVar("tf_bot_navigation_debug", "0", "Enable Tactical Navigation diagnostics.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_NavExtensionRequired = CreateConVar("tf_bot_navigation_extension_required", "0", "Treat missing nav access as a hard requirement instead of falling back.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_NavUpdateRate = CreateConVar("tf_bot_navigation_update_rate", "0.10", "Base Tactical Navigation update rate.", FCVAR_NONE, true, 0.05, true, 1.0);
    g_NavAreaUpdateRate = CreateConVar("tf_bot_navigation_area_update_rate", "0.20", "Player-to-area update rate.", FCVAR_NONE, true, 0.05, true, 2.0);
    g_NavControlUpdateRate = CreateConVar("tf_bot_navigation_control_update_rate", "0.50", "Dynamic control update rate.", FCVAR_NONE, true, 0.10, true, 3.0);
    g_NavRouteBudget = CreateConVar("tf_bot_navigation_route_budget", "2", "Maximum queued route requests processed per navigation tick.", FCVAR_NONE, true, 1.0, true, 16.0);
    g_NavMaxNodes = CreateConVar("tf_bot_navigation_max_nodes", "1400", "Maximum A* nodes expanded for one route.", FCVAR_NONE, true, 64.0, true, 8192.0);
    g_NavRouteCacheTime = CreateConVar("tf_bot_navigation_route_cache_time", "2.0", "Time an unchanged route request may reuse its current route.", FCVAR_NONE, true, 0.0, true, 15.0);
    g_NavDamageHalfLife = CreateConVar("tf_bot_navigation_damage_half_life", "7.0", "Damage danger half-life in seconds.", FCVAR_NONE, true, 1.0, true, 60.0);
    g_NavDeathHalfLife = CreateConVar("tf_bot_navigation_death_half_life", "14.0", "Death danger half-life in seconds.", FCVAR_NONE, true, 1.0, true, 120.0);
    g_NavSentryDanger = CreateConVar("tf_bot_navigation_sentry_danger", "3.0", "Route penalty for legitimately known Sentry coverage.", FCVAR_NONE, true, 0.0, true, 10.0);
    g_NavSniperDanger = CreateConVar("tf_bot_navigation_sniper_danger", "2.2", "Route penalty for legitimately known Sniper exposure.", FCVAR_NONE, true, 0.0, true, 10.0);
    g_NavMedicPilot = CreateConVar("tf_bot_navigation_medic_pilot", "0", "Enable Medic safety-routing pilot.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_NavScoutPilot = CreateConVar("tf_bot_navigation_scout_pilot", "0", "Enable Scout flank-routing pilot.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_NavRetreatPilot = CreateConVar("tf_bot_navigation_retreat_pilot", "0", "Enable generic emergency-retreat pilot.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_NavDrawRoutes = CreateConVar("tf_bot_navigation_draw_routes", "0", "Draw active route traversal points for admins.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_NavLogRoutes = CreateConVar("tf_bot_navigation_log_routes", "0", "Log route scoring and failures.", FCVAR_NONE, true, 0.0, true, 1.0);

    RegAdminCmd("sm_bn_inspect", Command_BNInspect, ADMFLAG_GENERIC, "sm_bn_inspect [target] - inspect a bot's navigation request and route.");
    RegAdminCmd("sm_bn_area", Command_BNArea, ADMFLAG_GENERIC, "Inspect the nav area beneath the caller or target.");
    RegAdminCmd("sm_bn_route", Command_BNRoute, ADMFLAG_GENERIC, "sm_bn_route [target] - print an active tactical route.");
    RegAdminCmd("sm_bn_danger", Command_BNDanger, ADMFLAG_GENERIC, "Inspect nearby tactical danger.");
    RegAdminCmd("sm_bn_control", Command_BNControl, ADMFLAG_GENERIC, "Inspect nearby team control.");
    RegAdminCmd("sm_bn_groups", Command_BNGroups, ADMFLAG_GENERIC, "Inspect Knowledge/Nav group context.");
    RegAdminCmd("sm_bn_rebuild", Command_BNRebuild, ADMFLAG_ROOT, "Rebuild the cached tactical navigation graph.");

    HookEvent("player_hurt", Event_BNPlayerHurt, EventHookMode_Post);
    HookEvent("player_death", Event_BNPlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", Event_BNPlayerLifecycle, EventHookMode_Post);
    HookEvent("player_team", Event_BNPlayerLifecycle, EventHookMode_Post);
    HookEvent("player_changeclass", Event_BNPlayerLifecycle, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_BNRoundReset, EventHookMode_PostNoCopy);

    g_RouteQueue = new ArrayList();
    g_AreaSlotByIndex = new StringMap();
    RefreshDependencyState();
    ResetNavigationState(true);
    RestartNavigationTimer();
}

public void OnAllPluginsLoaded()
{
    RefreshDependencyState();
    TryBuildNavigationGraph();
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "navmesh") || StrEqual(name, "bot_knowledge"))
    {
        RefreshDependencyState();
        TryBuildNavigationGraph();
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "navmesh") || StrEqual(name, "bot_knowledge"))
    {
        RefreshDependencyState();
        if (StrEqual(name, "navmesh"))
        {
            g_GraphReady = false;
            CancelAllRoutes("nav access removed");
        }
    }
}

public void OnConfigsExecuted()
{
    RestartNavigationTimer();
}

public void OnMapStart()
{
    g_DebugBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
    ResetNavigationState(true);
    CreateTimer(0.5, Timer_DelayedGraphBuild, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
    ResetNavigationState(true);
}

public void OnClientPutInServer(int client)
{
    ResetClientNavigation(client);
}

public void OnClientDisconnect(int client)
{
    ResetClientNavigation(client);
}

public void OnNavMeshLoaded(bool success)
{
    RefreshDependencyState();
    if (success) TryBuildNavigationGraph();
    else DisableGraphSafely("the map navigation mesh could not be loaded");
}

public Action Timer_DelayedGraphBuild(Handle timer)
{
    TryBuildNavigationGraph();
    return Plugin_Stop;
}

void RefreshDependencyState()
{
    g_NavLibraryAvailable = LibraryExists("navmesh") && GetFeatureStatus(FeatureType_Native, "NavMesh_Exists") == FeatureStatus_Available;
    g_KnowledgeAvailable = LibraryExists("bot_knowledge") && GetFeatureStatus(FeatureType_Native, "BK_IsEnabled") == FeatureStatus_Available;
}

void DisableGraphSafely(const char[] reason)
{
    if (g_NavExtensionRequired != null && g_NavExtensionRequired.BoolValue)
    {
        LogError("[BotNav] Required navigation access unavailable: %s", reason);
    }
    else
    {
        LogMessage("[BotNav] Tactical Navigation observation disabled: %s. Existing bot behavior remains active.", reason);
    }
    g_GraphReady = false;
    CancelAllRoutes(reason);
}

void RestartNavigationTimer()
{
    delete g_NavigationTimer;
    float interval = g_NavUpdateRate != null ? g_NavUpdateRate.FloatValue : 0.10;
    g_NavigationTimer = CreateTimer(interval, Timer_NavigationUpdate, _, TIMER_REPEAT);
}

public Action Timer_NavigationUpdate(Handle timer)
{
    if (!g_NavEnabled.BoolValue || !g_GraphReady) return Plugin_Continue;

    float now = GetGameTime();
    UpdatePlayerAreas(now);
    RunStaticAnalysisBudget(8);
    UpdateDynamicOverlay(now);
    ProcessRouteQueue(g_NavRouteBudget.IntValue);
    UpdateActiveRoutes(now);
    EvaluatePilotRequests(now);
    if (g_NavDrawRoutes.BoolValue) DrawActiveRoutes();
    return Plugin_Continue;
}

public Action Event_BNPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim < 1 || victim > MaxClients || !IsClientInGame(victim)) return Plugin_Continue;
    int damage = event.GetInt("damageamount");
    int slot = ResolveClientArea(victim, true);
    if (slot != BN_INVALID_AREA) AddDangerHeat(GetClientTeam(victim), slot, float(damage) / 45.0, false);
    return Plugin_Continue;
}

public Action Event_BNPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim < 1 || victim > MaxClients) return Plugin_Continue;
    int slot = g_ClientArea[victim];
    if (slot != BN_INVALID_AREA) AddDangerHeat(GetClientTeam(victim), slot, 2.5, true);
    CancelClientRoute(victim, BNRoute_Cancelled, "client died");
    return Plugin_Continue;
}

public Action Event_BNPlayerLifecycle(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client >= 1 && client <= MaxClients) ResetClientNavigation(client);
    return Plugin_Continue;
}

public Action Event_BNRoundReset(Event event, const char[] name, bool dontBroadcast)
{
    ResetDynamicOverlay();
    CancelAllRoutes("round reset");
    return Plugin_Continue;
}
