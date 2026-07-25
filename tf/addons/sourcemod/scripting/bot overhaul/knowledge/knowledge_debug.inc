#if defined _knowledge_debug_inc
 #endinput
#endif
#define _knowledge_debug_inc

public Action Command_BKInspect(int client, int args)
{
    int observer = ResolveCommandTarget(client, args);
    if (observer <= 0)
    {
        ReplyToCommand(client, "[BK] Supply a valid target.");
        return Plugin_Handled;
    }

    ReplyToCommand(client, "[BK] Observer %N team=%d class=%d team_state=%d", observer, g_WorldTeam[observer], view_as<int>(g_WorldClass[observer]), view_as<int>(g_TeamState[g_WorldTeam[observer]]));

    int knownCount = 0;
    float now = GetGameTime();
    for (int subject = 1; subject <= MaxClients; subject++)
    {
        if (!g_KnownPlayer[observer][subject] || g_WorldTeam[subject] == g_WorldTeam[observer])
        {
            continue;
        }

        knownCount++;
        ReplyToCommand(
            client,
            "[BK] enemy=%N visible=%d conf=%.2f uncertainty=%.0f age=%.2f source=%d labels=0x%08x",
            subject,
            g_PlayerVisible[observer][subject],
            g_KnownConfidence[observer][subject],
            g_KnownUncertainty[observer][subject],
            now - g_KnownConfirmedAt[observer][subject],
            view_as<int>(g_KnownSource[observer][subject]),
            g_KnownLabels[observer][subject]
        );
    }

    ReplyToCommand(client, "[BK] known enemies: %d", knownCount);
    return Plugin_Handled;
}

public Action Command_BKMemory(int client, int args)
{
    int observer = ResolveCommandTarget(client, args);
    if (observer <= 0)
    {
        ReplyToCommand(client, "[BK] Supply a valid target.");
        return Plugin_Handled;
    }

    float now = GetGameTime();
    for (int subject = 1; subject <= MaxClients; subject++)
    {
        if (!g_KnownPlayer[observer][subject] || g_PlayerVisible[observer][subject])
        {
            continue;
        }

        ReplyToCommand(
            client,
            "[BK] memory observer=%N subject=%N conf=%.2f uncertainty=%.0f age=%.2f pos=(%.0f %.0f %.0f)",
            observer,
            subject,
            g_KnownConfidence[observer][subject],
            g_KnownUncertainty[observer][subject],
            now - g_KnownConfirmedAt[observer][subject],
            g_KnownPosition[observer][subject][0],
            g_KnownPosition[observer][subject][1],
            g_KnownPosition[observer][subject][2]
        );
    }

    return Plugin_Handled;
}

public Action Command_BKGroups(int client, int args)
{
    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        if (!g_GroupActive[slot])
        {
            continue;
        }

        ReplyToCommand(
            client,
            "[BK] group=%d team=%d members=%d cohesion=%.2f radius=%.0f movement=%d centroid=(%.0f %.0f %.0f)",
            g_GroupId[slot],
            g_GroupTeam[slot],
            g_GroupMemberCount[slot],
            g_GroupCohesion[slot],
            g_GroupRadius[slot],
            view_as<int>(g_GroupMovement[slot]),
            g_GroupCentroid[slot][0],
            g_GroupCentroid[slot][1],
            g_GroupCentroid[slot][2]
        );
    }

    ReplyToCommand(
        client,
        "[BK] RED state=%d BLU state=%d front=(%.0f %.0f %.0f) confidence=%.2f",
        view_as<int>(g_TeamState[2]),
        view_as<int>(g_TeamState[3]),
        g_FrontLine[2][0],
        g_FrontLine[2][1],
        g_FrontLine[2][2],
        g_FrontLineConfidence[2]
    );
    return Plugin_Handled;
}

int ResolveCommandTarget(int client, int args)
{
    if (args > 0)
    {
        char argument[64];
        GetCmdArg(1, argument, sizeof(argument));
        return FindTarget(client, argument, true, false);
    }

    if (client > 0 && IsClientInGame(client))
    {
        int aimed = GetClientAimTarget(client, true);
        if (aimed >= 1 && aimed <= MaxClients)
        {
            return aimed;
        }
        return client;
    }

    return 0;
}

void ResetAllKnowledge()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        ResetClientKnowledge(client);
        ClearWorldPlayer(client);
        g_WorldLastDamageAt[client] = -9999.0;
        g_WorldLastDamageDealtAt[client] = -9999.0;
    }

    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        ClearBuildingSlot(slot);
    }

    for (int slot = 0; slot < BK_MAX_OBJECTIVES; slot++)
    {
        ClearObjectiveSlot(slot);
    }

    ClearGroups();
    g_PreviousGroupCount = 0;
    g_TeamState[2] = BKTeam_Unknown;
    g_TeamState[3] = BKTeam_Unknown;
    ZeroVector(g_FrontLine[2]);
    ZeroVector(g_FrontLine[3]);
    g_FrontLineConfidence[2] = 0.0;
    g_FrontLineConfidence[3] = 0.0;
    g_LastGroupUpdate = 0.0;
    g_LastDirectorUpdate = 0.0;
    g_LastRegistryUpdate = 0.0;
    g_LastObjectiveEventAt = 0.0;
    ResetIndexes();
}

void ResetRoundKnowledge()
{
    for (int observer = 1; observer <= MaxClients; observer++)
    {
        for (int subject = 1; subject <= MaxClients; subject++)
        {
            ClearPlayerKnowledge(observer, subject);
        }
        g_MilkPending[observer] = false;
        g_MilkCooldownUntil[observer] = 0.0;
    }

    ClearGroups();
    g_PreviousGroupCount = 0;
    g_LastGroupUpdate = 0.0;
    g_LastDirectorUpdate = 0.0;
}

void ResetClientKnowledge(int client)
{
    for (int subject = 1; subject <= MaxClients; subject++)
    {
        ClearPlayerKnowledge(client, subject);
    }

    for (int observer = 1; observer <= MaxClients; observer++)
    {
        ClearPlayerKnowledge(observer, client);
    }

    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        g_KnownBuilding[client][slot] = false;
        g_KnownBuildingConfidence[client][slot] = 0.0;
        ZeroVector(g_KnownBuildingPosition[client][slot]);
        g_KnownBuildingUpdatedAt[client][slot] = 0.0;
    }

    g_MilkPending[client] = false;
    ZeroVector(g_MilkTarget[client]);
    g_MilkPendingUntil[client] = 0.0;
    g_MilkCooldownUntil[client] = 0.0;
}

void ClearSubjectFromAllObservers(int subject)
{
    for (int observer = 1; observer <= MaxClients; observer++)
    {
        ClearPlayerKnowledge(observer, subject);
    }
}

void ClearPlayerKnowledge(int observer, int subject)
{
    g_KnownPlayer[observer][subject] = false;
    g_PlayerVisible[observer][subject] = false;
    ZeroVector(g_KnownPosition[observer][subject]);
    ZeroVector(g_KnownVelocity[observer][subject]);
    g_KnownConfidence[observer][subject] = 0.0;
    g_KnownUncertainty[observer][subject] = 0.0;
    g_KnownFirstAt[observer][subject] = 0.0;
    g_KnownConfirmedAt[observer][subject] = 0.0;
    g_KnownUpdatedAt[observer][subject] = 0.0;
    g_KnownExpiresAt[observer][subject] = 0.0;
    g_KnownSource[observer][subject] = BKSource_None;
    g_KnownScope[observer][subject] = BKScope_WorldOnly;
    g_KnownLabels[observer][subject] = BKLabel_None;
}

bool IsValidKnowledgeObserver(int observer)
{
    return observer >= 1 && observer <= MaxClients && g_WorldConnected[observer];
}

int ClientBit(int client)
{
    return 1 << (client - 1);
}

bool MaskHasClient(int mask, int client)
{
    return (mask & ClientBit(client)) != 0;
}

int FirstClientInMask(int mask)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (MaskHasClient(mask, client))
        {
            return client;
        }
    }
    return 0;
}

int CountMaskClients(int mask)
{
    int count = 0;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (MaskHasClient(mask, client))
        {
            count++;
        }
    }
    return count;
}

void CopyVector(const float source[3], float destination[3])
{
    destination[0] = source[0];
    destination[1] = source[1];
    destination[2] = source[2];
}

void ZeroVector(float vector[3])
{
    vector[0] = 0.0;
    vector[1] = 0.0;
    vector[2] = 0.0;
}

float ClampFloat(float value, float minimumValue, float maximumValue)
{
    if (value < minimumValue)
    {
        return minimumValue;
    }
    if (value > maximumValue)
    {
        return maximumValue;
    }
    return value;
}

int IntMin(int first, int second)
{
    return first < second ? first : second;
}

float FloatMax(float first, float second)
{
    return first > second ? first : second;
}
