#if defined _navigation_route_cost_inc
 #endinput
#endif
#define _navigation_route_cost_inc

float CalculateEdgeTacticalCost(int client, int fromSlot, int toSlot, float distance, BNRouteProfile profile, BNMovementPurpose purpose)
{
    int team = GetClientTeam(client);
    float danger = GetObserverAreaDanger(client, toSlot);
    float traffic = team >= 2 && team <= 3 ? g_AreaTraffic[team][toSlot] : 0.0;
    float control = team >= 2 && team <= 3 ? g_AreaControl[team][toSlot] : 0.0;
    float cost = distance;
    float dangerWeight = 80.0;
    float trafficWeight = 8.0;
    float controlReward = 15.0;
    float coverReward = 0.0;

    switch (profile)
    {
        case BNProfile_Fastest: { dangerWeight = 28.0; trafficWeight = 2.0; controlReward = 4.0; }
        case BNProfile_Safest: { dangerWeight = 145.0; trafficWeight = 5.0; controlReward = 32.0; coverReward = 25.0; }
        case BNProfile_Retreat: { dangerWeight = 170.0; trafficWeight = 3.0; controlReward = 48.0; coverReward = 38.0; }
        case BNProfile_Flank: { dangerWeight = 78.0; trafficWeight = 28.0; controlReward = 5.0; coverReward = 14.0; }
        case BNProfile_Push: { dangerWeight = 65.0; trafficWeight = -4.0; controlReward = 18.0; coverReward = 8.0; }
        case BNProfile_Support: { dangerWeight = 135.0; trafficWeight = -2.0; controlReward = 38.0; coverReward = 32.0; }
        case BNProfile_Defensive: { dangerWeight = 92.0; trafficWeight = -3.0; controlReward = 28.0; coverReward = 30.0; }
        case BNProfile_Stealth: { dangerWeight = 115.0; trafficWeight = 35.0; controlReward = -4.0; coverReward = 34.0; }
    }

    cost += danger * dangerWeight;
    cost += traffic * trafficWeight;
    cost -= control * controlReward;
    cost -= g_AreaCover[toSlot] * coverReward;
    cost += FloatAbs(g_AreaHeight[toSlot] - g_AreaHeight[fromSlot]) * 0.18;

    int labels = g_AreaLabels[toSlot];
    if ((labels & BNArea_DeadEnd) != 0 && (profile == BNProfile_Retreat || purpose == BNPurpose_Retreat)) cost += 850.0;
    if ((labels & BNArea_ExposedCrossing) != 0 && (profile == BNProfile_Safest || profile == BNProfile_Support)) cost += 110.0;
    if ((labels & BNArea_Choke) != 0 && profile == BNProfile_Flank) cost += 90.0;
    if ((labels & BNArea_FlankConnection) != 0 && (profile == BNProfile_Flank || profile == BNProfile_Stealth)) cost -= 75.0;
    if ((labels & BNArea_MainRoute) != 0 && profile == BNProfile_Flank) cost += 120.0;
    if ((labels & BNArea_Defensive) != 0 && profile == BNProfile_Defensive) cost -= 70.0;
    if ((labels & BNArea_ObjectiveApproach) != 0 && (profile == BNProfile_Push || purpose == BNPurpose_Capture)) cost -= 60.0;

    TFClassType classType = TF2_GetPlayerClass(client);
    if (classType == TFClass_Medic && (labels & BNArea_ExposedCrossing) != 0) cost += 85.0;
    if (classType == TFClass_Heavy && (labels & BNArea_LongSightline) != 0) cost += 55.0;
    if (classType == TFClass_Scout && profile == BNProfile_Flank && (labels & BNArea_Wide) != 0) cost -= 25.0;
    if (classType == TFClass_Spy && profile == BNProfile_Stealth && g_AreaTraffic[team][toSlot] < 0.8) cost -= 35.0;
    return FloatMax(cost, distance * 0.25);
}

float GetHeuristicWeight(BNRouteProfile profile)
{
    switch (profile)
    {
        case BNProfile_Fastest: return 1.18;
        case BNProfile_Flank, BNProfile_Stealth: return 0.82;
        case BNProfile_Retreat, BNProfile_Safest, BNProfile_Support: return 0.72;
    }
    return 1.0;
}

bool ReconstructClientRoute(int client, int startSlot, int endSlot)
{
    int reversed[BN_MAX_ROUTE_AREAS];
    int count = 0;
    int current = endSlot;
    while (current != BN_INVALID_AREA && count < BN_MAX_ROUTE_AREAS)
    {
        reversed[count++] = current;
        if (current == startSlot) break;
        current = g_SearchParent[current];
    }
    if (count <= 0 || reversed[count - 1] != startSlot) return false;
    g_RouteLength[client] = count;
    for (int i = 0; i < count; i++) g_RouteAreas[client][i] = reversed[count - i - 1];
    return true;
}

void CalculateRouteMetrics(int client)
{
    g_RouteDistance[client] = 0.0;
    g_RouteDanger[client] = 0.0;
    PrepareObserverThreatContext(client);
    for (int i = 1; i < g_RouteLength[client]; i++)
    {
        int previous = g_RouteAreas[client][i - 1];
        int current = g_RouteAreas[client][i];
        g_RouteDistance[client] += GetVectorDistance(g_AreaCenter[previous], g_AreaCenter[current]);
        g_RouteDanger[client] += GetObserverAreaDanger(client, current);
    }
    if (g_RouteLength[client] > 1) g_RouteDanger[client] /= float(g_RouteLength[client] - 1);
    g_RouteConfidence[client] = ClampFloat(1.0 - g_RouteDanger[client] / 9.0, 0.15, 1.0);
}

void UpdateActiveRoutes(float now)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (g_RouteStatus[client] != BNRoute_Active) continue;
        if (!IsClientInGame(client) || !IsPlayerAlive(client)) { CancelClientRoute(client, BNRoute_Cancelled, "client unavailable"); continue; }
        if (now >= g_RouteExpiresAt[client]) { CancelClientRoute(client, BNRoute_Cancelled, "route expired"); continue; }
        float position[3];
        GetClientAbsOrigin(client, position);
        if (GetVectorDistance(position, g_RouteNextPoint[client]) <= 90.0)
        {
            g_RouteCursor[client]++;
            if (g_RouteCursor[client] >= g_RouteLength[client]) { CancelClientRoute(client, BNRoute_Complete, "goal reached"); continue; }
            UpdateTraversalPoint(client);
        }
    }
}

void UpdateTraversalPoint(int client)
{
    if (g_RouteCursor[client] <= 0 || g_RouteCursor[client] >= g_RouteLength[client])
    {
        CopyVector3(g_RouteGoal[client], g_RouteNextPoint[client]);
        return;
    }
    int fromSlot = g_RouteAreas[client][g_RouteCursor[client] - 1];
    int toSlot = g_RouteAreas[client][g_RouteCursor[client]];
    float fromPosition[3];
    GetClientAbsOrigin(client, fromPosition);
    int direction = FindEdgeDirection(fromSlot, toSlot);
    bool portal = direction >= 0 && NavMeshArea_ComputeClosestPointInPortal(g_AreaIndex[fromSlot], g_AreaIndex[toSlot], direction, fromPosition, g_RouteNextPoint[client]);
    if (!portal) CopyVector3(g_AreaCenter[toSlot], g_RouteNextPoint[client]);
    float dx = g_AreaCenter[toSlot][0] - g_AreaCenter[fromSlot][0];
    float dy = g_AreaCenter[toSlot][1] - g_AreaCenter[fromSlot][1];
    float length = SquareRoot(dx * dx + dy * dy);
    if (length > 1.0)
    {
        float offset = float((client % 5) - 2) * 14.0;
        g_RouteNextPoint[client][0] += (-dy / length) * offset;
        g_RouteNextPoint[client][1] += (dx / length) * offset;
        float clamped[3];
        NavMeshArea_GetClosestPointOnArea(g_AreaIndex[toSlot], g_RouteNextPoint[client], clamped);
        CopyVector3(clamped, g_RouteNextPoint[client]);
    }
}

int FindEdgeDirection(int fromSlot, int toSlot)
{
    int start = g_AreaEdgeStart[fromSlot];
    for (int edge = start; edge < start + g_AreaEdgeCount[fromSlot]; edge++) if (g_EdgeTarget[edge] == toSlot) return g_EdgeDirection[edge];
    return -1;
}

void CancelClientRoute(int client, BNRouteStatus status, const char[] reason)
{
    if (client < 1 || client > MaxClients) return;
    g_RouteStatus[client] = status;
    g_RouteLength[client] = 0;
    g_RouteCursor[client] = 0;
    g_RoutePriority[client] = 0;
    g_RouteInterruptible[client] = true;
    g_RouteMinimumUntil[client] = 0.0;
    g_RouteExpiresAt[client] = 0.0;
    g_RouteDistance[client] = 0.0;
    g_RouteDanger[client] = 0.0;
    g_RouteCost[client] = 0.0;
    g_RouteConfidence[client] = 0.0;
    strcopy(g_RouteFailure[client], sizeof(g_RouteFailure[]), reason);
}

void CancelAllRoutes(const char[] reason)
{
    if (g_RouteQueue != null) g_RouteQueue.Clear();
    for (int client = 1; client <= MaxClients; client++) CancelClientRoute(client, BNRoute_Cancelled, reason);
}

bool FindSafestNearbyArea(int observer, float radius, float destination[3], bool retreatOnly)
{
    int current = ResolveClientArea(observer, true);
    if (current == BN_INVALID_AREA) return false;
    PrepareObserverThreatContext(observer);
    int team = GetClientTeam(observer);
    int best = current;
    float bestScore = -999999.0;
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        float distance = GetVectorDistance(g_AreaCenter[current], g_AreaCenter[slot]);
        if (distance > radius) continue;
        int labels = g_AreaLabels[slot];
        if (retreatOnly && (labels & BNArea_DeadEnd) != 0) continue;
        float score = g_AreaControl[team][slot] * 120.0 + g_AreaCover[slot] * 55.0 - GetObserverAreaDanger(observer, slot) * 95.0 - distance * 0.025;
        if ((labels & BNArea_DeadEnd) != 0) score -= 120.0;
        if ((labels & BNArea_ExposedCrossing) != 0) score -= 35.0;
        if (score > bestScore) { bestScore = score; best = slot; }
    }
    CopyVector3(g_AreaCenter[best], destination);
    return true;
}

bool FindRetreatDestination(int observer, float destination[3])
{
    if (FindSafestNearbyArea(observer, 2200.0, destination, true)) return true;
    return GetFriendlyTeamCentroid(observer, destination, true) > 0;
}

bool FindBestFlankApproach(int observer, const float goal[3], float destination[3])
{
    int goalSlot = FindAreaSlotFromPosition(goal, true);
    if (goalSlot == BN_INVALID_AREA) return false;
    int team = GetClientTeam(observer);
    PrepareObserverThreatContext(observer);
    int best = goalSlot;
    float bestScore = -999999.0;
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        float distance = GetVectorDistance(g_AreaCenter[slot], g_AreaCenter[goalSlot]);
        if (distance > 1300.0) continue;
        float score = -distance * 0.04 - g_AreaTraffic[team][slot] * 18.0 - GetObserverAreaDanger(observer, slot) * 70.0 + g_AreaCover[slot] * 35.0;
        if ((g_AreaLabels[slot] & BNArea_FlankConnection) != 0) score += 80.0;
        if ((g_AreaLabels[slot] & BNArea_MainRoute) != 0) score -= 55.0;
        if (score > bestScore) { bestScore = score; best = slot; }
    }
    CopyVector3(g_AreaCenter[best], destination);
    return true;
}

void HeapPush(int slot)
{
    if (g_SearchHeapLength >= BN_MAX_AREAS) return;
    int index = g_SearchHeapLength++;
    g_SearchHeap[index] = slot;
    while (index > 0)
    {
        int parent = (index - 1) / 2;
        if (g_SearchF[g_SearchHeap[parent]] <= g_SearchF[g_SearchHeap[index]]) break;
        int temporary = g_SearchHeap[parent];
        g_SearchHeap[parent] = g_SearchHeap[index];
        g_SearchHeap[index] = temporary;
        index = parent;
    }
}

int HeapPop()
{
    if (g_SearchHeapLength <= 0) return BN_INVALID_AREA;
    int result = g_SearchHeap[0];
    g_SearchHeapLength--;
    if (g_SearchHeapLength > 0)
    {
        g_SearchHeap[0] = g_SearchHeap[g_SearchHeapLength];
        int index = 0;
        while (true)
        {
            int left = index * 2 + 1;
            int right = left + 1;
            if (left >= g_SearchHeapLength) break;
            int smallest = left;
            if (right < g_SearchHeapLength && g_SearchF[g_SearchHeap[right]] < g_SearchF[g_SearchHeap[left]]) smallest = right;
            if (g_SearchF[g_SearchHeap[index]] <= g_SearchF[g_SearchHeap[smallest]]) break;
            int temporary = g_SearchHeap[index];
            g_SearchHeap[index] = g_SearchHeap[smallest];
            g_SearchHeap[smallest] = temporary;
            index = smallest;
        }
    }
    return result;
}

void RecordRouteTiming(float duration)
{
    g_RouteCalculationTotal += duration;
    if (duration > g_RouteCalculationMaximum) g_RouteCalculationMaximum = duration;
    g_RouteCalculationCount++;
}
