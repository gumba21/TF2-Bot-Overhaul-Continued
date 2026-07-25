#if defined _navigation_route_api_inc
 #endinput
#endif
#define _navigation_route_api_inc

public any Native_BNIsAvailable(Handle plugin, int numParams)
{
    return g_NavEnabled != null && g_NavEnabled.BoolValue && g_GraphReady;
}

public any Native_BNGetAreaFromPosition(Handle plugin, int numParams)
{
    float position[3];
    GetNativeArray(1, position, 3);
    int slot = FindAreaSlotFromPosition(position, true);
    return slot == BN_INVALID_AREA ? 0 : g_AreaId[slot];
}

public any Native_BNGetCurrentAreaForClient(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int slot = ResolveClientArea(client);
    return slot == BN_INVALID_AREA ? 0 : g_AreaId[slot];
}

public any Native_BNGetAreaCenter(Handle plugin, int numParams)
{
    int slot = FindAreaSlotById(GetNativeCell(1));
    if (slot == BN_INVALID_AREA) return false;
    SetNativeArray(2, g_AreaCenter[slot], 3);
    return true;
}

public any Native_BNGetAreaBounds(Handle plugin, int numParams)
{
    int slot = FindAreaSlotById(GetNativeCell(1));
    if (slot == BN_INVALID_AREA) return false;
    SetNativeArray(2, g_AreaMins[slot], 3);
    SetNativeArray(3, g_AreaMaxs[slot], 3);
    return true;
}

public any Native_BNGetAreaLabels(Handle plugin, int numParams)
{
    int slot = FindAreaSlotById(GetNativeCell(1));
    return slot == BN_INVALID_AREA ? 0 : g_AreaLabels[slot];
}

public any Native_BNGetAreaDanger(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    int slot = FindAreaSlotById(GetNativeCell(2));
    if (slot == BN_INVALID_AREA) return view_as<int>(0.0);
    PrepareObserverThreatContext(observer);
    return view_as<int>(GetObserverAreaDanger(observer, slot));
}

public any Native_BNGetAreaControl(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    int slot = FindAreaSlotById(GetNativeCell(2));
    if (team < 2 || team > 3 || slot == BN_INVALID_AREA) return view_as<int>(0.0);
    return view_as<int>(g_AreaControl[team][slot]);
}

public any Native_BNGetAreaTraffic(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    int slot = FindAreaSlotById(GetNativeCell(2));
    if (team < 2 || team > 3 || slot == BN_INVALID_AREA) return view_as<int>(0.0);
    return view_as<int>(g_AreaTraffic[team][slot]);
}

public any Native_BNRequestRoute(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    float goal[3];
    GetNativeArray(2, goal, 3);
    return RequestClientRoute(client, goal, view_as<BNRouteProfile>(GetNativeCell(3)), view_as<BNMovementPurpose>(GetNativeCell(4)), GetNativeCell(5), view_as<float>(GetNativeCell(6)), view_as<float>(GetNativeCell(7)), GetNativeCell(8) != 0);
}

public any Native_BNCancelRoute(Handle plugin, int numParams)
{
    CancelClientRoute(GetNativeCell(1), BNRoute_Cancelled, "cancelled by consumer");
    return 0;
}

public any Native_BNGetRouteStatus(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients) return view_as<int>(BNRoute_None);
    return view_as<int>(g_RouteStatus[client]);
}

public any Native_BNGetNextTraversalPoint(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients || g_RouteStatus[client] != BNRoute_Active) return false;
    SetNativeArray(2, g_RouteNextPoint[client], 3);
    return true;
}

public any Native_BNGetRouteMetrics(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients || g_RouteStatus[client] == BNRoute_None) return false;
    SetNativeCellRef(2, view_as<int>(g_RouteDistance[client]));
    SetNativeCellRef(3, view_as<int>(g_RouteDanger[client]));
    SetNativeCellRef(4, view_as<int>(g_RouteCost[client]));
    SetNativeCellRef(5, view_as<int>(g_RouteConfidence[client]));
    return true;
}

public any Native_BNGetSafestNearbyArea(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    float radius = view_as<float>(GetNativeCell(2));
    float destination[3];
    if (!FindSafestNearbyArea(observer, radius, destination, false)) return false;
    SetNativeArray(3, destination, 3);
    return true;
}

public any Native_BNGetRetreatDestination(Handle plugin, int numParams)
{
    float destination[3];
    if (!FindRetreatDestination(GetNativeCell(1), destination)) return false;
    SetNativeArray(2, destination, 3);
    return true;
}

public any Native_BNGetBestFlankApproach(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    float goal[3];
    float destination[3];
    GetNativeArray(2, goal, 3);
    if (!FindBestFlankApproach(observer, goal, destination)) return false;
    SetNativeArray(3, destination, 3);
    return true;
}

bool RequestClientRoute(int client, const float goal[3], BNRouteProfile profile, BNMovementPurpose purpose, int priority, float minimumDuration, float lifetime, bool interruptible)
{
    if (!g_GraphReady || client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) return false;
    float now = GetGameTime();
    if (g_RouteStatus[client] == BNRoute_Active || g_RouteStatus[client] == BNRoute_Pending)
    {
        if (priority < g_RoutePriority[client]) return false;
        if (!g_RouteInterruptible[client] && now < g_RouteMinimumUntil[client]) return false;
        if (profile == g_RouteProfile[client] && purpose == g_RoutePurpose[client] && GetVectorDistance(goal, g_RouteGoal[client]) < 96.0 && now - g_RouteCreatedAt[client] <= g_NavRouteCacheTime.FloatValue)
        {
            g_RouteCacheHits++;
            g_RouteExpiresAt[client] = now + lifetime;
            return true;
        }
    }

    CopyVector3(goal, g_RouteGoal[client]);
    g_RouteGoalArea[client] = FindAreaSlotFromPosition(goal, true);
    if (g_RouteGoalArea[client] == BN_INVALID_AREA)
    {
        CancelClientRoute(client, BNRoute_Failed, "goal is outside known nav areas");
        return false;
    }

    g_RouteProfile[client] = profile;
    g_RoutePurpose[client] = purpose;
    g_RoutePriority[client] = priority;
    g_RouteInterruptible[client] = interruptible;
    g_RouteMinimumUntil[client] = now + FloatMax(minimumDuration, 0.0);
    g_RouteExpiresAt[client] = now + FloatMax(lifetime, 0.25);
    g_RouteCreatedAt[client] = now;
    g_RouteStatus[client] = BNRoute_Pending;
    g_RouteLength[client] = 0;
    g_RouteCursor[client] = 0;
    strcopy(g_RouteFailure[client], sizeof(g_RouteFailure[]), "queued");
    if (!QueueContainsClient(client)) g_RouteQueue.Push(client);
    return true;
}

bool QueueContainsClient(int client)
{
    for (int i = 0; i < g_RouteQueue.Length; i++) if (g_RouteQueue.Get(i) == client) return true;
    return false;
}

void ProcessRouteQueue(int budget)
{
    for (int processed = 0; processed < budget && g_RouteQueue.Length > 0; processed++)
    {
        int client = g_RouteQueue.Get(0);
        g_RouteQueue.Erase(0);
        if (client < 1 || client > MaxClients || g_RouteStatus[client] != BNRoute_Pending) continue;
        CalculateClientRoute(client);
    }
}

bool CalculateClientRoute(int client)
{
    int startSlot = ResolveClientArea(client, true);
    int goalSlot = g_RouteGoalArea[client];
    if (startSlot == BN_INVALID_AREA || goalSlot == BN_INVALID_AREA)
    {
        CancelClientRoute(client, BNRoute_Failed, "missing start or goal area");
        return false;
    }

    float started = GetEngineTime();
    PrepareObserverThreatContext(client);
    g_SearchGeneration++;
    if (g_SearchGeneration <= 0)
    {
        g_SearchGeneration = 1;
        for (int slot = 0; slot < g_AreaCount; slot++)
        {
            g_SearchSeen[slot] = 0;
            g_SearchClosed[slot] = 0;
        }
    }
    g_SearchHeapLength = 0;
    g_SearchNodesExpanded = 0;
    g_SearchSeen[startSlot] = g_SearchGeneration;
    g_SearchG[startSlot] = 0.0;
    g_SearchF[startSlot] = GetVectorDistance(g_AreaCenter[startSlot], g_AreaCenter[goalSlot]);
    g_SearchParent[startSlot] = BN_INVALID_AREA;
    HeapPush(startSlot);

    bool found = false;
    int bestSlot = startSlot;
    float bestHeuristic = g_SearchF[startSlot];
    int maxNodes = g_NavMaxNodes.IntValue;
    while (g_SearchHeapLength > 0 && g_SearchNodesExpanded < maxNodes)
    {
        int current = HeapPop();
        if (current == BN_INVALID_AREA || g_SearchClosed[current] == g_SearchGeneration) continue;
        g_SearchClosed[current] = g_SearchGeneration;
        g_SearchNodesExpanded++;
        float heuristic = GetVectorDistance(g_AreaCenter[current], g_AreaCenter[goalSlot]);
        if (heuristic < bestHeuristic) { bestHeuristic = heuristic; bestSlot = current; }
        if (current == goalSlot) { found = true; bestSlot = current; break; }

        int start = g_AreaEdgeStart[current];
        for (int edge = start; edge < start + g_AreaEdgeCount[current]; edge++)
        {
            int next = g_EdgeTarget[edge];
            if (g_SearchClosed[next] == g_SearchGeneration) continue;
            float edgeCost = CalculateEdgeTacticalCost(client, current, next, g_EdgeDistance[edge], g_RouteProfile[client], g_RoutePurpose[client]);
            if (edgeCost >= 1000000.0) continue;
            float tentative = g_SearchG[current] + edgeCost;
            if (g_SearchSeen[next] != g_SearchGeneration || tentative < g_SearchG[next])
            {
                g_SearchSeen[next] = g_SearchGeneration;
                g_SearchParent[next] = current;
                g_SearchG[next] = tentative;
                float h = GetVectorDistance(g_AreaCenter[next], g_AreaCenter[goalSlot]);
                g_SearchF[next] = tentative + h * GetHeuristicWeight(g_RouteProfile[client]);
                HeapPush(next);
            }
        }
    }

    if (!found && bestHeuristic > 320.0)
    {
        CancelClientRoute(client, BNRoute_Failed, g_SearchNodesExpanded >= maxNodes ? "route search budget exhausted" : "no connected route");
        RecordRouteTiming(GetEngineTime() - started);
        return false;
    }
    if (!ReconstructClientRoute(client, startSlot, bestSlot))
    {
        CancelClientRoute(client, BNRoute_Failed, "route exceeded storage limit");
        RecordRouteTiming(GetEngineTime() - started);
        return false;
    }

    g_RouteStatus[client] = BNRoute_Active;
    g_RouteCursor[client] = g_RouteLength[client] > 1 ? 1 : 0;
    g_RouteCost[client] = g_SearchG[bestSlot];
    CalculateRouteMetrics(client);
    UpdateTraversalPoint(client);
    strcopy(g_RouteFailure[client], sizeof(g_RouteFailure[]), found ? "success" : "closest reachable area");
    RecordRouteTiming(GetEngineTime() - started);
    if (g_NavLogRoutes.BoolValue)
    {
        LogMessage("[BotNav] %N route profile=%d purpose=%d areas=%d distance=%.1f danger=%.2f cost=%.1f confidence=%.2f nodes=%d", client, g_RouteProfile[client], g_RoutePurpose[client], g_RouteLength[client], g_RouteDistance[client], g_RouteDanger[client], g_RouteCost[client], g_RouteConfidence[client], g_SearchNodesExpanded);
    }
    return true;
}
