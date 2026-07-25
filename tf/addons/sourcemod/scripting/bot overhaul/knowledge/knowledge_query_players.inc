#if defined _knowledge_query_players_inc
 #endinput
#endif
#define _knowledge_query_players_inc

bool GetLargestKnownEnemyCluster(
    int observer,
    float centroid[3],
    int &memberCount,
    float &cohesion,
    float &confidence
)
{
    int observerTeam = g_WorldTeam[observer];
    if (observerTeam < 2) return false;

    int enemyTeam = observerTeam == 2 ? 3 : 2;
    int bestCount = 0;
    float bestScore = 0.0;
    float bestCentroid[3];
    float bestCohesion = 0.0;
    float bestConfidence = 0.0;

    for (int slot = 0; slot < BK_MAX_GROUPS; slot++)
    {
        if (!g_GroupActive[slot] || g_GroupTeam[slot] != enemyTeam) continue;

        int knownCount = 0;
        float localCentroid[3];
        float confidenceTotal = 0.0;
        ZeroVector(localCentroid);
        for (int subject = 1; subject <= MaxClients; subject++)
        {
            if (!MaskHasClient(g_GroupMembers[slot], subject)
                || !g_KnownPlayer[observer][subject]
                || g_KnownConfidence[observer][subject] < 0.25) continue;

            knownCount++;
            AddVectors(localCentroid, g_KnownPosition[observer][subject], localCentroid);
            confidenceTotal += g_KnownConfidence[observer][subject];
        }
        if (knownCount == 0) continue;

        ScaleVector(localCentroid, 1.0 / float(knownCount));
        float averageConfidence = confidenceTotal / float(knownCount);
        float localCohesion = CalculateKnownCohesion(observer, slot, localCentroid);
        float score = float(knownCount) * 10.0 + localCohesion * 6.0 + averageConfidence * 5.0;
        if (score > bestScore)
        {
            bestScore = score;
            bestCount = knownCount;
            CopyVector(localCentroid, bestCentroid);
            bestCohesion = localCohesion;
            bestConfidence = averageConfidence;
        }
    }

    if (bestCount == 0) return false;
    CopyVector(bestCentroid, centroid);
    memberCount = bestCount;
    cohesion = bestCohesion;
    confidence = bestConfidence;
    return true;
}

float CalculateKnownCohesion(int observer, int groupSlot, const float centroid[3])
{
    int count = 0;
    float totalDistance = 0.0;
    for (int subject = 1; subject <= MaxClients; subject++)
    {
        if (!MaskHasClient(g_GroupMembers[groupSlot], subject)
            || !g_KnownPlayer[observer][subject]
            || g_KnownConfidence[observer][subject] < 0.25) continue;
        totalDistance += GetVectorDistance(g_KnownPosition[observer][subject], centroid);
        count++;
    }
    if (count <= 1) return 0.0;
    return ClampFloat(1.0 - (totalDistance / float(count)) / FloatMax(g_CvarGroupDistance.FloatValue, 1.0), 0.0, 1.0);
}

int QueryKnownEnemies(int observer, int[] results, int maximumResults, float minimumConfidence)
{
    if (!IsValidKnowledgeObserver(observer)) return 0;
    int count = 0;
    int observerTeam = g_WorldTeam[observer];
    for (int subject = 1; subject <= MaxClients && count < maximumResults; subject++)
    {
        if (!g_KnownPlayer[observer][subject]
            || g_WorldTeam[subject] == observerTeam
            || g_WorldTeam[subject] < 2
            || g_KnownConfidence[observer][subject] < minimumConfidence) continue;
        results[count++] = subject;
    }
    return count;
}

int QueryBurningTeammates(
    int observer,
    int[] results,
    int maximumResults,
    float maximumDistance,
    float minimumConfidence
)
{
    if (!IsValidKnowledgeObserver(observer)) return 0;
    int count = 0;
    int candidates = g_BurningTeamMask[g_WorldTeam[observer]];
    for (int subject = 1; subject <= MaxClients && count < maximumResults; subject++)
    {
        if (subject == observer || !MaskHasClient(candidates, subject)) continue;
        float confidence = 1.0;
        if (g_WorldIsBot[observer] && g_KnownPlayer[observer][subject]) confidence = g_KnownConfidence[observer][subject];
        if (confidence < minimumConfidence) continue;
        if (GetVectorDistance(g_WorldPosition[observer], g_WorldPosition[subject]) > maximumDistance) continue;
        results[count++] = subject;
    }
    return count;
}
