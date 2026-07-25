#if defined _navigation_debug_inc
 #endinput
#endif
#define _navigation_debug_inc

public Action Command_BNInspect(int client, int args)
{
    int target = ResolveNavigationCommandTarget(client, args);
    if (target == 0) return Plugin_Handled;
    int slot = ResolveClientArea(target, true);
    char statusName[24], profileName[24], purposeName[24];
    GetRouteStatusName(g_RouteStatus[target], statusName, sizeof(statusName));
    GetRouteProfileName(g_RouteProfile[target], profileName, sizeof(profileName));
    GetRoutePurposeName(g_RoutePurpose[target], purposeName, sizeof(purposeName));
    ReplyToCommand(client, "[BotNav] %N available=%d area=%d areaId=%d route=%s profile=%s purpose=%s priority=%d", target, g_GraphReady, slot, slot == BN_INVALID_AREA ? 0 : g_AreaId[slot], statusName, profileName, purposeName, g_RoutePriority[target]);
    ReplyToCommand(client, "[BotNav] routeAreas=%d cursor=%d distance=%.1f danger=%.2f cost=%.1f confidence=%.2f age=%.2f reason=%s", g_RouteLength[target], g_RouteCursor[target], g_RouteDistance[target], g_RouteDanger[target], g_RouteCost[target], g_RouteConfidence[target], GetGameTime() - g_RouteCreatedAt[target], g_RouteFailure[target]);
    if (g_RouteStatus[target] == BNRoute_Active) ReplyToCommand(client, "[BotNav] goal=(%.0f %.0f %.0f) next=(%.0f %.0f %.0f)", g_RouteGoal[target][0], g_RouteGoal[target][1], g_RouteGoal[target][2], g_RouteNextPoint[target][0], g_RouteNextPoint[target][1], g_RouteNextPoint[target][2]);
    return Plugin_Handled;
}

public Action Command_BNArea(int client, int args)
{
    int target = ResolveNavigationCommandTarget(client, args);
    if (target == 0) return Plugin_Handled;
    int slot = ResolveClientArea(target, true);
    if (slot == BN_INVALID_AREA) { ReplyToCommand(client, "[BotNav] No nav area could be resolved for %N.", target); return Plugin_Handled; }
    int team = GetClientTeam(target);
    PrepareObserverThreatContext(target);
    ReplyToCommand(client, "[BotNav] area slot=%d id=%d navIndex=%d center=(%.0f %.0f %.0f) size=%.0fx%.0f edges=%d labels=0x%X", slot, g_AreaId[slot], g_AreaIndex[slot], g_AreaCenter[slot][0], g_AreaCenter[slot][1], g_AreaCenter[slot][2], g_AreaWidth[slot], g_AreaLength[slot], g_AreaEdgeCount[slot], g_AreaLabels[slot]);
    ReplyToCommand(client, "[BotNav] openness=%.2f cover=%.2f choke=%.2f highGround=%.2f danger=%.2f control=%.2f traffic=%.2f", g_AreaOpenness[slot], g_AreaCover[slot], g_AreaChoke[slot], g_AreaHighGround[slot], GetObserverAreaDanger(target, slot), team >= 2 && team <= 3 ? g_AreaControl[team][slot] : 0.0, team >= 2 && team <= 3 ? g_AreaTraffic[team][slot] : 0.0);
    return Plugin_Handled;
}

public Action Command_BNRoute(int client, int args)
{
    int target = ResolveNavigationCommandTarget(client, args);
    if (target == 0) return Plugin_Handled;
    if (g_RouteStatus[target] != BNRoute_Active)
    {
        char statusName[24];
        GetRouteStatusName(g_RouteStatus[target], statusName, sizeof(statusName));
        ReplyToCommand(client, "[BotNav] %N has no active route (%s: %s).", target, statusName, g_RouteFailure[target]);
        return Plugin_Handled;
    }
    char route[512];
    for (int i = 0; i < g_RouteLength[target] && i < 24; i++)
    {
        char item[24];
        Format(item, sizeof(item), "%s%d", i == 0 ? "" : " -> ", g_AreaId[g_RouteAreas[target][i]]);
        StrCat(route, sizeof(route), item);
    }
    ReplyToCommand(client, "[BotNav] %N route: %s%s", target, route, g_RouteLength[target] > 24 ? " -> ..." : "");
    return Plugin_Handled;
}

public Action Command_BNDanger(int client, int args)
{
    int target = ResolveNavigationCommandTarget(client, args);
    if (target == 0) return Plugin_Handled;
    int slot = ResolveClientArea(target, true);
    if (slot == BN_INVALID_AREA) return Plugin_Handled;
    PrepareObserverThreatContext(target);
    ReplyToCommand(client, "[BotNav] Area %d danger %.2f; known Sniper areas=%d.", g_AreaId[slot], GetObserverAreaDanger(target, slot), g_ContextSniperCount);
    int start = g_AreaEdgeStart[slot];
    for (int edge = start; edge < start + g_AreaEdgeCount[slot] && edge < start + 8; edge++)
    {
        int neighbor = g_EdgeTarget[edge];
        ReplyToCommand(client, "  neighbor %d danger=%.2f damage=%.2f death=%.2f", g_AreaId[neighbor], GetObserverAreaDanger(target, neighbor), g_AreaDamageHeat[GetClientTeam(target)][neighbor], g_AreaDeathHeat[GetClientTeam(target)][neighbor]);
    }
    return Plugin_Handled;
}

public Action Command_BNControl(int client, int args)
{
    int target = ResolveNavigationCommandTarget(client, args);
    if (target == 0) return Plugin_Handled;
    int slot = ResolveClientArea(target, true);
    if (slot == BN_INVALID_AREA) return Plugin_Handled;
    ReplyToCommand(client, "[BotNav] Area %d: RED control=%.2f traffic=%.2f | BLU control=%.2f traffic=%.2f", g_AreaId[slot], g_AreaControl[2][slot], g_AreaTraffic[2][slot], g_AreaControl[3][slot], g_AreaTraffic[3][slot]);
    return Plugin_Handled;
}

public Action Command_BNGroups(int client, int args)
{
    if (!g_KnowledgeAvailable || !BK_IsEnabled()) { ReplyToCommand(client, "[BotNav] Battlefield Knowledge is unavailable; nav graph remains usable without group context."); return Plugin_Handled; }
    float redFront[3], blueFront[3], redConfidence, blueConfidence;
    bool red = BK_GetFrontLine(2, redFront, redConfidence);
    bool blue = BK_GetFrontLine(3, blueFront, blueConfidence);
    ReplyToCommand(client, "[BotNav] Knowledge states RED=%d BLU=%d", BK_GetTeamState(2), BK_GetTeamState(3));
    if (red) ReplyToCommand(client, "  RED front=(%.0f %.0f %.0f) confidence=%.2f", redFront[0], redFront[1], redFront[2], redConfidence);
    if (blue) ReplyToCommand(client, "  BLU front=(%.0f %.0f %.0f) confidence=%.2f", blueFront[0], blueFront[1], blueFront[2], blueConfidence);
    return Plugin_Handled;
}

public Action Command_BNRebuild(int client, int args)
{
    TryBuildNavigationGraph();
    ReplyToCommand(client, "[BotNav] Rebuild requested. ready=%d areas=%d edges=%d", g_GraphReady, g_AreaCount, g_EdgeCount);
    return Plugin_Handled;
}

int ResolveNavigationCommandTarget(int client, int args)
{
    if (args < 1)
    {
        if (client >= 1 && client <= MaxClients && IsClientInGame(client)) return client;
        ReplyToCommand(client, "[BotNav] Supply a target from the server console.");
        return 0;
    }
    char pattern[64];
    GetCmdArg(1, pattern, sizeof(pattern));
    return FindTarget(client, pattern, true, false);
}

void DrawActiveRoutes()
{
    if (g_DebugBeamSprite <= 0) return;
    int color[4] = {80, 210, 255, 180};
    for (int client = 1; client <= MaxClients; client++)
    {
        if (g_RouteStatus[client] != BNRoute_Active || !IsClientInGame(client)) continue;
        float previous[3];
        GetClientAbsOrigin(client, previous);
        previous[2] += 12.0;
        for (int i = g_RouteCursor[client]; i < g_RouteLength[client] && i < g_RouteCursor[client] + 12; i++)
        {
            float next[3];
            CopyVector3(g_AreaCenter[g_RouteAreas[client][i]], next);
            next[2] += 12.0;
            TE_SetupBeamPoints(previous, next, g_DebugBeamSprite, 0, 0, 0, 0.12, 2.0, 2.0, 1, 0.0, color, 0);
            TE_SendToAll();
            CopyVector3(next, previous);
        }
    }
}

void GetRouteStatusName(BNRouteStatus status, char[] buffer, int maximumLength)
{
    switch (status)
    {
        case BNRoute_Pending: strcopy(buffer, maximumLength, "pending");
        case BNRoute_Active: strcopy(buffer, maximumLength, "active");
        case BNRoute_Complete: strcopy(buffer, maximumLength, "complete");
        case BNRoute_Failed: strcopy(buffer, maximumLength, "failed");
        case BNRoute_Cancelled: strcopy(buffer, maximumLength, "cancelled");
        default: strcopy(buffer, maximumLength, "none");
    }
}

void GetRouteProfileName(BNRouteProfile profile, char[] buffer, int maximumLength)
{
    switch (profile)
    {
        case BNProfile_Fastest: strcopy(buffer, maximumLength, "fastest");
        case BNProfile_Safest: strcopy(buffer, maximumLength, "safest");
        case BNProfile_Retreat: strcopy(buffer, maximumLength, "retreat");
        case BNProfile_Flank: strcopy(buffer, maximumLength, "flank");
        case BNProfile_Push: strcopy(buffer, maximumLength, "push");
        case BNProfile_Support: strcopy(buffer, maximumLength, "support");
        case BNProfile_Defensive: strcopy(buffer, maximumLength, "defensive");
        case BNProfile_Stealth: strcopy(buffer, maximumLength, "stealth");
        default: strcopy(buffer, maximumLength, "fastest");
    }
}

void GetRoutePurposeName(BNMovementPurpose purpose, char[] buffer, int maximumLength)
{
    switch (purpose)
    {
        case BNPurpose_Attack: strcopy(buffer, maximumLength, "attack");
        case BNPurpose_Retreat: strcopy(buffer, maximumLength, "retreat");
        case BNPurpose_Regroup: strcopy(buffer, maximumLength, "regroup");
        case BNPurpose_Flank: strcopy(buffer, maximumLength, "flank");
        case BNPurpose_Follow: strcopy(buffer, maximumLength, "follow");
        case BNPurpose_Protect: strcopy(buffer, maximumLength, "protect");
        case BNPurpose_Capture: strcopy(buffer, maximumLength, "capture");
        case BNPurpose_Defend: strcopy(buffer, maximumLength, "defend");
        case BNPurpose_SeekHealth: strcopy(buffer, maximumLength, "seek-health");
        case BNPurpose_SeekAmmo: strcopy(buffer, maximumLength, "seek-ammo");
        case BNPurpose_Investigate: strcopy(buffer, maximumLength, "investigate");
        case BNPurpose_SearchLastKnown: strcopy(buffer, maximumLength, "search-memory");
        case BNPurpose_EscapeSentry: strcopy(buffer, maximumLength, "escape-sentry");
        case BNPurpose_CrossSightline: strcopy(buffer, maximumLength, "cross-sightline");
        default: strcopy(buffer, maximumLength, "none");
    }
}
