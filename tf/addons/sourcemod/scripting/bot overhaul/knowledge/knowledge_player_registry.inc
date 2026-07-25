#if defined _knowledge_player_registry_inc
 #endinput
#endif
#define _knowledge_player_registry_inc

void UpdateWorldRegistry(float now)
{
    ResetIndexes();

    for (int client = 1; client <= MaxClients; client++)
    {
        UpdateWorldPlayer(client, now);
    }

    RefreshBuildingRegistry();
    g_LastRegistryUpdate = now;
}

void UpdateWorldPlayer(int client, float now)
{
    if (!IsClientInGame(client))
    {
        ClearWorldPlayer(client);
        return;
    }

    g_WorldConnected[client] = true;
    g_WorldAlive[client] = IsPlayerAlive(client);
    g_WorldIsBot[client] = IsFakeClient(client);
    g_WorldTeam[client] = GetClientTeam(client);
    g_WorldClass[client] = TF2_GetPlayerClass(client);

    CopyVector(g_WorldPosition[client], g_WorldLastPosition[client]);
    GetClientAbsOrigin(client, g_WorldPosition[client]);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_WorldVelocity[client]);

    g_WorldHealth[client] = g_WorldAlive[client] ? GetClientHealth(client) : 0;
    g_WorldMaxHealth[client] = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    if (g_WorldMaxHealth[client] <= 0)
    {
        g_WorldMaxHealth[client] = 1;
    }
    g_WorldHealthPercent[client] = float(g_WorldHealth[client]) / float(g_WorldMaxHealth[client]);

    g_WorldLabels[client] = BuildPlayerLabels(client, now);
    g_WorldCombat[client] = ClassifyCombatState(client, now);
    g_WorldMovement[client] = ClassifyMovementState(client);

    float cellSize = g_CvarSpatialCellSize.FloatValue;
    g_PlayerCellX[client] = RoundToFloor(g_WorldPosition[client][0] / cellSize);
    g_PlayerCellY[client] = RoundToFloor(g_WorldPosition[client][1] / cellSize);
    g_PlayerCellZ[client] = RoundToFloor(g_WorldPosition[client][2] / cellSize);

    int team = g_WorldTeam[client];
    if (team >= 0 && team < 4)
    {
        int bit = ClientBit(client);
        g_TeamMask[team] |= bit;
        if (g_WorldAlive[client])
        {
            g_AliveTeamMask[team] |= bit;
        }
        if ((g_WorldLabels[client] & BKLabel_Burning) != 0)
        {
            g_BurningTeamMask[team] |= bit;
        }
        if ((g_WorldLabels[client] & BKLabel_CriticalHealth) != 0)
        {
            g_CriticalTeamMask[team] |= bit;
        }

        int classIndex = view_as<int>(g_WorldClass[client]);
        if (classIndex >= 0 && classIndex < 10)
        {
            g_ClassTeamMask[team][classIndex] |= bit;
        }
    }
}

void ClearWorldPlayer(int client)
{
    g_WorldConnected[client] = false;
    g_WorldAlive[client] = false;
    g_WorldIsBot[client] = false;
    g_WorldTeam[client] = 0;
    g_WorldClass[client] = TFClass_Unknown;
    g_WorldHealth[client] = 0;
    g_WorldMaxHealth[client] = 1;
    g_WorldHealthPercent[client] = 0.0;
    ZeroVector(g_WorldPosition[client]);
    ZeroVector(g_WorldVelocity[client]);
    ZeroVector(g_WorldLastPosition[client]);
    g_WorldLabels[client] = BKLabel_None;
    g_WorldMovement[client] = BKMove_Unknown;
    g_WorldCombat[client] = BKCombat_None;
}

void ResetIndexes()
{
    for (int team = 0; team < 4; team++)
    {
        g_TeamMask[team] = 0;
        g_AliveTeamMask[team] = 0;
        g_BurningTeamMask[team] = 0;
        g_CriticalTeamMask[team] = 0;
        for (int classIndex = 0; classIndex < 10; classIndex++)
        {
            g_ClassTeamMask[team][classIndex] = 0;
        }
    }
}

int BuildPlayerLabels(int client, float now)
{
    int labels = g_WorldAlive[client] ? BKLabel_Alive : BKLabel_Dead;
    if (!g_WorldAlive[client])
    {
        return labels;
    }

    if (TF2_IsPlayerInCondition(client, TFCond_OnFire)) labels |= BKLabel_Burning;
    if (TF2_IsPlayerInCondition(client, TFCond_Bleeding)) labels |= BKLabel_Bleeding;
    if (TF2_IsPlayerInCondition(client, TFCond_Jarated)) labels |= BKLabel_Jarated;
    if (TF2_IsPlayerInCondition(client, TFCond_Milked)) labels |= BKLabel_Milked;
    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) labels |= BKLabel_Cloaked;
    if (TF2_IsPlayerInCondition(client, TFCond_Disguised)) labels |= BKLabel_Disguised;
    if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || TF2_IsPlayerInCondition(client, TFCond_UberchargeFading)) labels |= BKLabel_Invulnerable;
    if (TF2_IsPlayerInCondition(client, TFCond_Zoomed)) labels |= BKLabel_Scoped;
    if ((GetEntityFlags(client) & FL_ONGROUND) == 0) labels |= BKLabel_Airborne;
    if (g_WorldHealth[client] > g_WorldMaxHealth[client]) labels |= BKLabel_Overhealed;

    float healthPercent = g_WorldHealthPercent[client];
    if (healthPercent <= 0.25) labels |= BKLabel_CriticalHealth;
    else if (healthPercent <= 0.50) labels |= BKLabel_LowHealth;
    else labels |= BKLabel_Healthy;

    if (now - g_WorldLastDamageAt[client] <= 1.5) labels |= BKLabel_UnderFire | BKLabel_InCombat;
    else if (now - g_WorldLastDamageDealtAt[client] <= 1.5) labels |= BKLabel_InCombat;

    return labels;
}

BKCombatState ClassifyCombatState(int client, float now)
{
    bool underFire = now - g_WorldLastDamageAt[client] <= 1.5;
    bool dealingDamage = now - g_WorldLastDamageDealtAt[client] <= 1.5;

    if (underFire && g_WorldHealthPercent[client] <= 0.35) return BKCombat_Losing;
    if (underFire) return BKCombat_UnderFire;
    if (dealingDamage) return BKCombat_Active;
    return BKCombat_None;
}

BKMovementState ClassifyMovementState(int client)
{
    if (GetVectorLength(g_WorldVelocity[client]) < 30.0) return BKMove_Stationary;
    return BKMove_Unknown;
}
