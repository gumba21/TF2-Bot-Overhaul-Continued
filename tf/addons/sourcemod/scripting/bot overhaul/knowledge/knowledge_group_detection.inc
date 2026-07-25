#if defined _knowledge_group_detection_inc
 #endinput
#endif
#define _knowledge_group_detection_inc

void RebuildGroups(float now)
{
    SavePreviousGroups();
    ClearGroups();

    int nextSlot = 0;
    for (int team = 2; team <= 3 && nextSlot < BK_MAX_GROUPS; team++)
    {
        int remaining = g_AliveTeamMask[team];
        while (remaining != 0 && nextSlot < BK_MAX_GROUPS)
        {
            int seed = FirstClientInMask(remaining);
            if (seed == 0) break;

            int groupMask = ClientBit(seed);
            remaining &= ~ClientBit(seed);
            bool added = true;
            while (added)
            {
                added = false;
                for (int candidate = 1; candidate <= MaxClients; candidate++)
                {
                    if (!MaskHasClient(remaining, candidate)) continue;
                    if (ShouldJoinGroup(candidate, groupMask))
                    {
                        groupMask |= ClientBit(candidate);
                        remaining &= ~ClientBit(candidate);
                        added = true;
                    }
                }
            }

            CreateGroupRecord(nextSlot, team, groupMask, now);
            nextSlot++;
        }
    }

    SelectMainGroups();
    ClassifyGroupMovement();
}

bool ShouldJoinGroup(int candidate, int groupMask)
{
    float maximumDistance = g_CvarGroupDistance.FloatValue;
    for (int member = 1; member <= MaxClients; member++)
    {
        if (!MaskHasClient(groupMask, member)) continue;
        if (GetVectorDistance(g_WorldPosition[candidate], g_WorldPosition[member]) > maximumDistance) continue;

        float candidateSpeed = GetVectorLength(g_WorldVelocity[candidate]);
        float memberSpeed = GetVectorLength(g_WorldVelocity[member]);
        if (candidateSpeed < 35.0 || memberSpeed < 35.0) return true;

        float candidateDirection[3];
        float memberDirection[3];
        NormalizeVector(g_WorldVelocity[candidate], candidateDirection);
        NormalizeVector(g_WorldVelocity[member], memberDirection);
        if (GetVectorDotProduct(candidateDirection, memberDirection) >= -0.20) return true;
    }
    return false;
}

void CreateGroupRecord(int slot, int team, int memberMask, float now)
{
    g_GroupActive[slot] = true;
    g_GroupTeam[slot] = team;
    g_GroupMembers[slot] = memberMask;
    g_GroupMemberCount[slot] = CountMaskClients(memberMask);
    g_GroupUpdatedAt[slot] = now;
    g_GroupConfidence[slot] = 1.0;
    ZeroVector(g_GroupCentroid[slot]);
    ZeroVector(g_GroupVelocity[slot]);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!MaskHasClient(memberMask, client)) continue;
        AddVectors(g_GroupCentroid[slot], g_WorldPosition[client], g_GroupCentroid[slot]);
        AddVectors(g_GroupVelocity[slot], g_WorldVelocity[client], g_GroupVelocity[slot]);
    }

    float divisor = float(g_GroupMemberCount[slot]);
    ScaleVector(g_GroupCentroid[slot], 1.0 / divisor);
    ScaleVector(g_GroupVelocity[slot], 1.0 / divisor);

    float totalDistance = 0.0;
    float maximumDistance = 0.0;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!MaskHasClient(memberMask, client)) continue;
        float distance = GetVectorDistance(g_WorldPosition[client], g_GroupCentroid[slot]);
        totalDistance += distance;
        maximumDistance = FloatMax(maximumDistance, distance);
    }

    float averageDistance = totalDistance / divisor;
    g_GroupRadius[slot] = maximumDistance;
    g_GroupCohesion[slot] = ClampFloat(1.0 - averageDistance / FloatMax(g_CvarGroupDistance.FloatValue, 1.0), 0.0, 1.0);
    g_GroupId[slot] = MatchPreviousGroup(team, memberMask);
}

int MatchPreviousGroup(int team, int memberMask)
{
    int bestId = 0;
    int bestOverlap = 0;
    for (int i = 0; i < g_PreviousGroupCount; i++)
    {
        if (g_PreviousGroupTeam[i] != team) continue;
        int overlap = CountMaskClients(memberMask & g_PreviousGroupMembers[i]);
        if (overlap > bestOverlap)
        {
            bestOverlap = overlap;
            bestId = g_PreviousGroupId[i];
        }
    }

    int memberCount = CountMaskClients(memberMask);
    if (bestId != 0 && bestOverlap * 2 >= memberCount) return bestId;
    return g_NextGroupId++;
}

void SavePreviousGroups()
{
    g_PreviousGroupCount = 0;
    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        if (!g_GroupActive[slot]) continue;
        g_PreviousGroupId[g_PreviousGroupCount] = g_GroupId[slot];
        g_PreviousGroupTeam[g_PreviousGroupCount] = g_GroupTeam[slot];
        g_PreviousGroupMembers[g_PreviousGroupCount] = g_GroupMembers[slot];
        g_PreviousGroupCount++;
    }
}

void ClearGroups()
{
    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        g_GroupActive[slot] = false;
        g_GroupId[slot] = 0;
        g_GroupTeam[slot] = 0;
        g_GroupMembers[slot] = 0;
        g_GroupMemberCount[slot] = 0;
        ZeroVector(g_GroupCentroid[slot]);
        ZeroVector(g_GroupVelocity[slot]);
        g_GroupRadius[slot] = 0.0;
        g_GroupCohesion[slot] = 0.0;
        g_GroupConfidence[slot] = 0.0;
        g_GroupUpdatedAt[slot] = 0.0;
        g_GroupMovement[slot] = BKMove_Unknown;
    }
    g_MainGroupSlot[2] = BK_INVALID_SLOT;
    g_MainGroupSlot[3] = BK_INVALID_SLOT;
}

void SelectMainGroups()
{
    for (int team = 2; team <= 3; team++)
    {
        int bestSlot = BK_INVALID_SLOT;
        int bestCount = -1;
        float bestCohesion = -1.0;
        for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
        {
            if (!g_GroupActive[slot] || g_GroupTeam[slot] != team) continue;
            if (g_GroupMemberCount[slot] > bestCount
                || (g_GroupMemberCount[slot] == bestCount && g_GroupCohesion[slot] > bestCohesion))
            {
                bestSlot = slot;
                bestCount = g_GroupMemberCount[slot];
                bestCohesion = g_GroupCohesion[slot];
            }
        }
        g_MainGroupSlot[team] = bestSlot;
    }
}

void ClassifyGroupMovement()
{
    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        if (!g_GroupActive[slot]) continue;
        int enemyTeam = g_GroupTeam[slot] == 2 ? 3 : 2;
        int enemyMain = g_MainGroupSlot[enemyTeam];
        float speed = GetVectorLength(g_GroupVelocity[slot]);
        if (speed < 35.0)
        {
            g_GroupMovement[slot] = BKMove_Holding;
            continue;
        }
        if (enemyMain == BK_INVALID_SLOT)
        {
            g_GroupMovement[slot] = BKMove_Unknown;
            continue;
        }

        float towardEnemy[3];
        float velocityDirection[3];
        MakeVectorFromPoints(g_GroupCentroid[slot], g_GroupCentroid[enemyMain], towardEnemy);
        NormalizeVector(towardEnemy, towardEnemy);
        NormalizeVector(g_GroupVelocity[slot], velocityDirection);
        float dot = GetVectorDotProduct(towardEnemy, velocityDirection);
        if (dot >= 0.35) g_GroupMovement[slot] = BKMove_Advancing;
        else if (dot <= -0.35) g_GroupMovement[slot] = BKMove_Retreating;
        else g_GroupMovement[slot] = BKMove_Flanking;
    }
}
