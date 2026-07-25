#if defined _navigation_dynamic_inc
 #endinput
#endif
#define _navigation_dynamic_inc

void ResetNavigationState(bool resetGraph)
{
    if (resetGraph) ResetGraphStorage();
    ResetDynamicOverlay();
    CancelAllRoutes("navigation reset");
    for (int client = 1; client <= MaxClients; client++) ResetClientNavigation(client);
    g_LastDynamicUpdate = GetGameTime();
    g_LastControlUpdate = g_LastDynamicUpdate;
    g_StaticAnalysisCursor = 0;
    g_RouteCalculationTotal = 0.0;
    g_RouteCalculationMaximum = 0.0;
    g_RouteCalculationCount = 0;
    g_RouteCacheHits = 0;
}

void ResetDynamicOverlay()
{
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        for (int team = 0; team < 4; team++)
        {
            g_AreaDamageHeat[team][slot] = 0.0;
            g_AreaDeathHeat[team][slot] = 0.0;
            g_AreaTraffic[team][slot] = 0.0;
            g_AreaControl[team][slot] = 0.0;
            g_AreaPresence[team][slot] = 0.0;
            g_AreaCombat[team][slot] = 0.0;
        }
        g_AreaLastDynamic[slot] = GetGameTime();
    }
}

void ResetClientNavigation(int client)
{
    if (client < 1 || client > MaxClients) return;
    g_ClientArea[client] = BN_INVALID_AREA;
    g_ClientNextAreaUpdate[client] = 0.0;
    g_ClientLastAreaPosition[client][0] = 0.0;
    g_ClientLastAreaPosition[client][1] = 0.0;
    g_ClientLastAreaPosition[client][2] = 0.0;
    CancelClientRoute(client, BNRoute_None, "client reset");
}

void UpdatePlayerAreas(float now, bool force = false)
{
    if (!g_GraphReady) return;

    for (int team = 0; team < 4; team++)
    {
        for (int slot = 0; slot < g_AreaCount; slot++) g_AreaPresence[team][slot] = 0.0;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsPlayerAlive(client))
        {
            g_ClientArea[client] = BN_INVALID_AREA;
            continue;
        }

        float position[3];
        GetClientAbsOrigin(client, position);
        bool moved = GetVectorDistance(position, g_ClientLastAreaPosition[client]) > 96.0;
        if (force || moved || now >= g_ClientNextAreaUpdate[client] || g_ClientArea[client] == BN_INVALID_AREA)
        {
            g_ClientArea[client] = FindAreaSlotFromPosition(position, true);
            CopyVector3(position, g_ClientLastAreaPosition[client]);
            g_ClientNextAreaUpdate[client] = now + g_NavAreaUpdateRate.FloatValue;
        }

        int slot = g_ClientArea[client];
        int team = GetClientTeam(client);
        if (slot == BN_INVALID_AREA || team < 2 || team > 3) continue;
        g_AreaPresence[team][slot] += 1.0;
        g_AreaTraffic[team][slot] = ClampFloat(g_AreaTraffic[team][slot] + 0.08, 0.0, 8.0);
    }
}

int ResolveClientArea(int client, bool force = false)
{
    if (client < 1 || client > MaxClients || !IsClientInGame(client)) return BN_INVALID_AREA;
    if (force || g_ClientArea[client] == BN_INVALID_AREA)
    {
        float position[3];
        GetClientAbsOrigin(client, position);
        g_ClientArea[client] = FindAreaSlotFromPosition(position, true);
        CopyVector3(position, g_ClientLastAreaPosition[client]);
    }
    return g_ClientArea[client];
}

void UpdateDynamicOverlay(float now)
{
    float elapsed = now - g_LastDynamicUpdate;
    if (elapsed <= 0.0) return;
    g_LastDynamicUpdate = now;

    float damageDecay = Pow(0.5, elapsed / g_NavDamageHalfLife.FloatValue);
    float deathDecay = Pow(0.5, elapsed / g_NavDeathHalfLife.FloatValue);
    float trafficDecay = Pow(0.5, elapsed / 12.0);
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        for (int team = 2; team <= 3; team++)
        {
            g_AreaDamageHeat[team][slot] *= damageDecay;
            g_AreaDeathHeat[team][slot] *= deathDecay;
            g_AreaTraffic[team][slot] *= trafficDecay;
            float immediate = g_AreaPresence[team][slot] * 0.60
                + g_AreaDamageHeat[team][slot] * 0.25
                + g_AreaDeathHeat[team][slot] * 0.50;
            g_AreaCombat[team][slot] += (immediate - g_AreaCombat[team][slot]) * ClampFloat(elapsed * 2.0, 0.0, 1.0);
        }
        g_AreaLastDynamic[slot] = now;
    }

    if (now - g_LastControlUpdate >= g_NavControlUpdateRate.FloatValue)
    {
        UpdateAreaControl();
        g_LastControlUpdate = now;
    }
}

void UpdateAreaControl()
{
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        for (int team = 2; team <= 3; team++)
        {
            float localFriendly = g_AreaPresence[team][slot];
            int start = g_AreaEdgeStart[slot];
            for (int edge = start; edge < start + g_AreaEdgeCount[slot]; edge++)
            {
                int neighbor = g_EdgeTarget[edge];
                localFriendly += g_AreaPresence[team][neighbor] * 0.35;
            }

            // Control used by fair route requests is based only on friendly presence,
            // friendly traffic, and known team damage outcomes. Hidden enemy positions
            // enter route cost separately through observer-scoped Battlefield Knowledge.
            float friendlySignal = ClampFloat(localFriendly / 3.0, 0.0, 1.0);
            float trafficSignal = ClampFloat(g_AreaTraffic[team][slot] / 6.0, 0.0, 1.0);
            float lossPenalty = ClampFloat(g_AreaDamageHeat[team][slot] * 0.08 + g_AreaDeathHeat[team][slot] * 0.14, 0.0, 0.65);
            float target = ClampFloat(friendlySignal * 0.78 + trafficSignal * 0.22 - lossPenalty, 0.0, 1.0);
            g_AreaControl[team][slot] += (target - g_AreaControl[team][slot]) * 0.35;
        }
    }
}

void AddDangerHeat(int affectedTeam, int slot, float amount, bool death)
{
    if (affectedTeam < 2 || affectedTeam > 3 || slot < 0 || slot >= g_AreaCount) return;
    AddDangerHeatDirect(affectedTeam, slot, amount, death);

    int start = g_AreaEdgeStart[slot];
    for (int edge = start; edge < start + g_AreaEdgeCount[slot]; edge++)
    {
        AddDangerHeatDirect(affectedTeam, g_EdgeTarget[edge], amount * 0.38, death);
    }
}

void AddDangerHeatDirect(int team, int slot, float amount, bool death)
{
    if (death) g_AreaDeathHeat[team][slot] = ClampFloat(g_AreaDeathHeat[team][slot] + amount, 0.0, 12.0);
    else g_AreaDamageHeat[team][slot] = ClampFloat(g_AreaDamageHeat[team][slot] + amount, 0.0, 12.0);
}

float GetBaseAreaDanger(int team, int slot)
{
    if (team < 2 || team > 3 || slot < 0 || slot >= g_AreaCount) return 0.0;
    return g_AreaDamageHeat[team][slot] * 0.45
        + g_AreaDeathHeat[team][slot] * 0.85
        + g_AreaCombat[team][slot] * 0.30;
}

float GetObserverAreaDanger(int observer, int slot)
{
    if (observer < 1 || observer > MaxClients || slot < 0 || slot >= g_AreaCount) return 0.0;
    int team = IsClientInGame(observer) ? GetClientTeam(observer) : 0;
    float danger = GetBaseAreaDanger(team, slot);

    if (g_KnowledgeAvailable && BK_IsEnabled())
    {
        if (g_ContextThreatSeen[slot] != g_ContextThreatGeneration)
        {
            g_ContextThreatSeen[slot] = g_ContextThreatGeneration;
            g_ContextKnowledgeThreat[slot] = BK_GetThreatAtPosition(observer, g_AreaCenter[slot]);
        }
        danger += g_ContextKnowledgeThreat[slot] * 0.85;
    }

    for (int i = 0; i < g_ContextSniperCount; i++)
    {
        int threatSlot = g_ContextSniperArea[i];
        float distance = GetVectorDistance(g_AreaCenter[slot], g_AreaCenter[threatSlot]);
        if (distance < 2400.0 && (g_AreaLabels[slot] & (BNArea_Open | BNArea_LongSightline | BNArea_ExposedCrossing)) != 0)
        {
            danger += ClampFloat(1.0 - distance / 2400.0, 0.0, 1.0)
                * g_NavSniperDanger.FloatValue * g_ContextSniperConfidence[i];
        }
    }
    return danger;
}

void PrepareObserverThreatContext(int observer)
{
    g_ContextObserver = observer;
    g_ContextSentryCount = 0;
    g_ContextSniperCount = 0;
    g_ContextThreatGeneration++;
    if (g_ContextThreatGeneration <= 0)
    {
        g_ContextThreatGeneration = 1;
        for (int slot = 0; slot < g_AreaCount; slot++) g_ContextThreatSeen[slot] = 0;
    }
    if (!g_KnowledgeAvailable || !BK_IsEnabled()) return;

    int enemies[MAXPLAYERS];
    int enemyCount = BK_GetKnownEnemies(observer, enemies, sizeof(enemies), 0.25);
    for (int i = 0; i < enemyCount && g_ContextSniperCount < BN_MAX_CONTEXT_THREATS; i++)
    {
        int enemy = enemies[i];
        if (!IsClientInGame(enemy) || TF2_GetPlayerClass(enemy) != TFClass_Sniper) continue;
        float position[3];
        float confidence;
        float uncertainty;
        if (!BK_GetLastKnownPosition(observer, enemy, position, confidence, uncertainty)) continue;
        int slot = FindAreaSlotFromPosition(position, true);
        if (slot == BN_INVALID_AREA) continue;
        g_ContextSniperArea[g_ContextSniperCount] = slot;
        g_ContextSniperConfidence[g_ContextSniperCount] = confidence * ClampFloat(1.0 - uncertainty / 1400.0, 0.25, 1.0);
        g_ContextSniperCount++;
    }
}

bool AreAreaSlotsAdjacent(int first, int second)
{
    if (first < 0 || second < 0 || first >= g_AreaCount || second >= g_AreaCount) return false;
    int start = g_AreaEdgeStart[first];
    for (int edge = start; edge < start + g_AreaEdgeCount[first]; edge++)
    {
        if (g_EdgeTarget[edge] == second) return true;
    }
    return false;
}
