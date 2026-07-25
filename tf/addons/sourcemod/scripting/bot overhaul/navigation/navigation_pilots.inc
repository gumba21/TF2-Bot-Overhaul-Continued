#if defined _navigation_pilots_inc
 #endinput
#endif
#define _navigation_pilots_inc

void EvaluatePilotRequests(float now)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsFakeClient(client) || !IsPlayerAlive(client)) continue;
        if (now < g_NextPilotEvaluation[client]) continue;
        g_NextPilotEvaluation[client] = now + 0.75 + float(client % 5) * 0.07;
        float position[3];
        GetClientAbsOrigin(client, position);
        int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
        float health = maxHealth > 0 ? float(GetClientHealth(client)) / float(maxHealth) : 1.0;
        float threat = 0.0;
        if (g_KnowledgeAvailable && BK_IsEnabled()) threat = BK_GetThreatAtPosition(client, position);
        else
        {
            int slot = ResolveClientArea(client);
            if (slot != BN_INVALID_AREA) threat = GetBaseAreaDanger(GetClientTeam(client), slot);
        }

        if (g_NavRetreatPilot.BoolValue && (health <= 0.30 || threat >= 1.65))
        {
            float retreat[3];
            if (FindRetreatDestination(client, retreat))
            {
                RequestClientRoute(client, retreat, BNProfile_Retreat, BNPurpose_Retreat, 100, 1.0, 7.0, false);
                continue;
            }
        }

        TFClassType classType = TF2_GetPlayerClass(client);
        if (classType == TFClass_Medic && g_NavMedicPilot.BoolValue) EvaluateMedicSafetyPilot(client, health, threat);
        else if (classType == TFClass_Scout && g_NavScoutPilot.BoolValue) EvaluateScoutFlankPilot(client, threat);
    }
}

void EvaluateMedicSafetyPilot(int client, float health, float threat)
{
    if (!g_KnowledgeAvailable || !BK_IsEnabled()) return;
    float friendlyCenter[3];
    int members = GetFriendlyTeamCentroid(client, friendlyCenter, false);
    if (members < 1) return;
    float position[3];
    GetClientAbsOrigin(client, position);
    float separation = GetVectorDistance(position, friendlyCenter);
    float frontLine[3];
    float frontConfidence;
    bool hasFront = BK_GetFrontLine(GetClientTeam(client), frontLine, frontConfidence);
    bool exposedAhead = hasFront && GetVectorDistance(position, frontLine) < 420.0 && threat > 0.55;
    if (health < 0.58 || threat > 0.90 || separation > 1100.0 || exposedAhead)
    {
        BNRouteProfile profile = health < 0.45 || threat > 1.20 ? BNProfile_Retreat : BNProfile_Support;
        BNMovementPurpose purpose = profile == BNProfile_Retreat ? BNPurpose_Retreat : BNPurpose_Regroup;
        int priority = profile == BNProfile_Retreat ? 90 : 55;
        RequestClientRoute(client, friendlyCenter, profile, purpose, priority, 0.8, 6.0, profile != BNProfile_Retreat);
    }
}

void EvaluateScoutFlankPilot(int client, float threat)
{
    if (!g_KnowledgeAvailable || !BK_IsEnabled() || threat > 1.30) return;
    if (g_RouteStatus[client] == BNRoute_Active && g_RoutePurpose[client] == BNPurpose_Flank) return;
    int current = ResolveClientArea(client);
    int team = GetClientTeam(client);
    if (current == BN_INVALID_AREA || team < 2 || team > 3) return;
    float congestion = g_AreaTraffic[team][current] + g_AreaPresence[team][current] * 0.65;
    if (congestion < 1.15 && (g_AreaLabels[current] & BNArea_MainRoute) == 0) return;
    float enemyCenter[3];
    int members;
    float cohesion;
    float confidence;
    if (!BK_GetLargestEnemyCluster(client, enemyCenter, members, cohesion, confidence) || members < 1 || confidence < 0.35) return;
    float approach[3];
    if (!FindBestFlankApproach(client, enemyCenter, approach)) return;
    RequestClientRoute(client, approach, BNProfile_Flank, BNPurpose_Flank, 42, 1.2, 8.0, true);
}

int GetFriendlyTeamCentroid(int observer, float center[3], bool preferRear)
{
    center[0] = 0.0;
    center[1] = 0.0;
    center[2] = 0.0;
    if (observer < 1 || observer > MaxClients || !IsClientInGame(observer)) return 0;
    int team = GetClientTeam(observer);
    int count = 0;
    float observerPosition[3];
    GetClientAbsOrigin(observer, observerPosition);
    for (int client = 1; client <= MaxClients; client++)
    {
        if (client == observer || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != team) continue;
        float position[3];
        GetClientAbsOrigin(client, position);
        if (GetVectorDistance(observerPosition, position) > 2400.0) continue;
        if (preferRear && g_KnowledgeAvailable && BK_IsEnabled() && BK_GetThreatAtPosition(observer, position) > 1.5) continue;
        center[0] += position[0]; center[1] += position[1]; center[2] += position[2]; count++;
    }
    if (count > 0)
    {
        center[0] /= float(count); center[1] /= float(count); center[2] /= float(count);
    }
    return count;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
    if (!g_NavEnabled.BoolValue || !g_GraphReady || client < 1 || client > MaxClients) return Plugin_Continue;
    if (!IsClientInGame(client) || !IsFakeClient(client) || !IsPlayerAlive(client)) return Plugin_Continue;
    if (g_RouteStatus[client] != BNRoute_Active) return Plugin_Continue;
    float position[3];
    GetClientAbsOrigin(client, position);
    SteerTowardNavigationPoint(client, g_RouteNextPoint[client], velocity, angles, buttons);
    float now = GetGameTime();
    if (GetVectorDistance(position, g_PilotLastPosition[client]) > 55.0)
    {
        CopyVector3(position, g_PilotLastPosition[client]);
        g_PilotLastProgressAt[client] = now;
    }
    else if (now - g_PilotLastProgressAt[client] > 2.2)
    {
        g_RouteStatus[client] = BNRoute_Pending;
        if (!QueueContainsClient(client)) g_RouteQueue.Push(client);
        g_PilotLastProgressAt[client] = now;
        strcopy(g_RouteFailure[client], sizeof(g_RouteFailure[]), "stuck route recalculation");
    }
    return Plugin_Changed;
}

void SteerTowardNavigationPoint(int client, const float goal[3], float velocity[3], const float angles[3], int &buttons)
{
    float position[3];
    GetClientAbsOrigin(client, position);
    float movement[3];
    SubtractVectors(goal, position, movement);
    movement[1] = -movement[1];
    float sine = Sine(angles[1] * FLOAT_PI / 180.0);
    float cosine = Cosine(angles[1] * FLOAT_PI / 180.0);
    velocity[0] = cosine * movement[0] - sine * movement[1];
    velocity[1] = sine * movement[0] + cosine * movement[1];
    velocity[2] = 0.0;
    NormalizeVector(velocity, velocity);
    ScaleVector(velocity, 450.0);
    if (goal[2] - position[2] > 34.0 && (GetEntityFlags(client) & FL_ONGROUND) != 0) buttons |= IN_JUMP;
}
