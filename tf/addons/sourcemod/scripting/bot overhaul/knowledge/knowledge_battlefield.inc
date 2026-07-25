#if defined _knowledge_battlefield_inc
 #endinput
#endif
#define _knowledge_battlefield_inc

void UpdateBattlefieldAnalysis(float now)
{
    int redMain = g_MainGroupSlot[2];
    int blueMain = g_MainGroupSlot[3];
    if (redMain != BK_INVALID_SLOT && blueMain != BK_INVALID_SLOT)
    {
        AddVectors(g_GroupCentroid[redMain], g_GroupCentroid[blueMain], g_FrontLine[2]);
        ScaleVector(g_FrontLine[2], 0.5);
        CopyVector(g_FrontLine[2], g_FrontLine[3]);
        float confidence = (g_GroupConfidence[redMain] + g_GroupConfidence[blueMain]) * 0.5;
        g_FrontLineConfidence[2] = confidence;
        g_FrontLineConfidence[3] = confidence;
    }
    else
    {
        g_FrontLineConfidence[2] = 0.0;
        g_FrontLineConfidence[3] = 0.0;
    }

    g_TeamState[2] = DetermineTeamState(2);
    g_TeamState[3] = DetermineTeamState(3);
    UpdatePlayerTacticalLabels(now);
}

BKTeamState DetermineTeamState(int team)
{
    int aliveCount = CountMaskClients(g_AliveTeamMask[team]);
    if (aliveCount == 0) return BKTeam_Unknown;

    int groupCount = 0;
    int advancing = 0;
    int retreating = 0;
    int mainCount = 0;
    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        if (!g_GroupActive[slot] || g_GroupTeam[slot] != team) continue;
        groupCount++;
        if (slot == g_MainGroupSlot[team]) mainCount = g_GroupMemberCount[slot];
        if (g_GroupMovement[slot] == BKMove_Advancing) advancing += g_GroupMemberCount[slot];
        else if (g_GroupMovement[slot] == BKMove_Retreating) retreating += g_GroupMemberCount[slot];
    }

    if (retreating * 2 > aliveCount) return BKTeam_Retreating;
    if (advancing * 2 > aliveCount) return BKTeam_Pushing;

    float mainRatio = float(mainCount) / float(aliveCount);
    if (mainRatio >= 0.70) return BKTeam_Grouped;
    if (groupCount >= 4 || mainRatio < 0.35) return BKTeam_Scattered;
    if (groupCount >= 2) return BKTeam_Split;
    return BKTeam_Holding;
}

void UpdatePlayerTacticalLabels(float now)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!g_WorldAlive[client]) continue;

        int labels = g_WorldLabels[client];
        int groupSlot = FindGroupForClient(client);
        if (groupSlot != BK_INVALID_SLOT && g_GroupMemberCount[groupSlot] > 1) labels |= BKLabel_Grouped;
        else labels |= BKLabel_Isolated;

        if (groupSlot != BK_INVALID_SLOT)
        {
            switch (g_GroupMovement[groupSlot])
            {
                case BKMove_Advancing: labels |= BKLabel_Advancing;
                case BKMove_Retreating: labels |= BKLabel_Retreating;
                case BKMove_Holding: labels |= BKLabel_Holding;
            }
        }

        if (g_WorldClass[client] == TFClass_Medic || g_WorldClass[client] == TFClass_Engineer)
        {
            labels |= BKLabel_HighValueTarget;
        }

        int team = g_WorldTeam[client];
        if (team >= 2 && team <= 3 && g_FrontLineConfidence[team] > 0.20)
        {
            int ownMain = g_MainGroupSlot[team];
            if (ownMain != BK_INVALID_SLOT
                && GetVectorDistance(g_WorldPosition[client], g_GroupCentroid[ownMain]) > 1100.0
                && g_WorldMovement[client] != BKMove_Retreating)
            {
                labels |= BKLabel_Overextended | BKLabel_Exposed;
            }
        }

        g_WorldLabels[client] = labels;
        for (int observer = 1; observer <= MaxClients; observer++)
        {
            if (g_KnownPlayer[observer][client] && g_PlayerVisible[observer][client])
            {
                g_KnownLabels[observer][client] = labels;
                g_KnownUpdatedAt[observer][client] = now;
            }
        }
    }
}

int FindGroupForClient(int client)
{
    int bit = ClientBit(client);
    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        if (g_GroupActive[slot] && (g_GroupMembers[slot] & bit) != 0) return slot;
    }
    return BK_INVALID_SLOT;
}
