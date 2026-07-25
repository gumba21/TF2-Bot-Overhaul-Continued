#if defined _knowledge_query_tactics_inc
 #endinput
#endif
#define _knowledge_query_tactics_inc

float CalculateThreatAtPosition(int observer, const float position[3])
{
    if (!IsValidKnowledgeObserver(observer)) return 0.0;

    float threat = 0.0;
    int observerTeam = g_WorldTeam[observer];
    for (int subject = 1; subject <= MaxClients; subject++)
    {
        if (!g_KnownPlayer[observer][subject]
            || g_WorldTeam[subject] == observerTeam
            || g_KnownConfidence[observer][subject] < 0.20) continue;

        float distance = GetVectorDistance(position, g_KnownPosition[observer][subject]);
        float rangeWeight = ClampFloat(1.0 - distance / 2200.0, 0.0, 1.0);
        float classWeight = GetClassThreatWeight(g_WorldClass[subject]);
        float healthWeight = ClampFloat(g_WorldHealthPercent[subject], 0.20, 1.25);
        float visibilityWeight = g_PlayerVisible[observer][subject] ? 1.0 : 0.72;
        threat += rangeWeight * classWeight * healthWeight * visibilityWeight * g_KnownConfidence[observer][subject];
    }

    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        if (!g_KnownBuilding[observer][slot]
            || g_BuildingTeam[slot] == observerTeam
            || g_BuildingKind[slot] != BKEntity_Sentry) continue;

        float distance = GetVectorDistance(position, g_KnownBuildingPosition[observer][slot]);
        threat += ClampFloat(1.0 - distance / 1600.0, 0.0, 1.0) * 2.0 * g_KnownBuildingConfidence[observer][slot];
    }
    return threat;
}

float GetClassThreatWeight(TFClassType classType)
{
    switch (classType)
    {
        case TFClass_Heavy: return 1.35;
        case TFClass_Soldier: return 1.25;
        case TFClass_DemoMan: return 1.25;
        case TFClass_Sniper: return 1.20;
        case TFClass_Medic: return 1.15;
        case TFClass_Pyro: return 1.10;
        case TFClass_Spy: return 1.10;
        case TFClass_Engineer: return 1.05;
    }
    return 1.0;
}

bool FindBestMadMilkTargetInternal(
    int observer,
    float target[3],
    int &enemyCount,
    int &burningAllies,
    float &utility
)
{
    enemyCount = 0;
    burningAllies = 0;
    utility = 0.0;
    ZeroVector(target);
    if (!IsValidKnowledgeObserver(observer) || !g_WorldAlive[observer]) return false;

    float bestUtility = 0.0;
    float bestTarget[3];
    if ((g_WorldLabels[observer] & BKLabel_Burning) != 0)
    {
        CopyVector(g_WorldPosition[observer], bestTarget);
        bestTarget[2] -= 32.0;
        bestUtility = 70.0 + (1.0 - g_WorldHealthPercent[observer]) * 25.0;
    }

    int burningClients[MAXPLAYERS];
    int burningCount = QueryBurningTeammates(observer, burningClients, sizeof(burningClients), 750.0, 0.35);
    if (burningCount > 0)
    {
        int bestTeammate = burningClients[0];
        float lowestHealth = g_WorldHealthPercent[bestTeammate];
        for (int i = 1; i < burningCount; i++)
        {
            int teammate = burningClients[i];
            if (g_WorldHealthPercent[teammate] < lowestHealth)
            {
                bestTeammate = teammate;
                lowestHealth = g_WorldHealthPercent[teammate];
            }
        }

        float extinguishUtility = 48.0 + float(burningCount) * 13.0 + (1.0 - lowestHealth) * 18.0;
        if (extinguishUtility > bestUtility)
        {
            bestUtility = extinguishUtility;
            CopyVector(g_WorldPosition[bestTeammate], bestTarget);
            burningAllies = burningCount;
            enemyCount = 0;
        }
    }

    float clusterTarget[3];
    int clusterCount;
    float cohesion;
    float confidence;
    if (GetLargestKnownEnemyCluster(observer, clusterTarget, clusterCount, cohesion, confidence))
    {
        float distance = GetVectorDistance(g_WorldPosition[observer], clusterTarget);
        float followup = float(CountNearbyKnownTeammates(observer, clusterTarget, 1000.0));
        float clusterUtility = 18.0 + float(clusterCount) * 13.0 + cohesion * 24.0
            + confidence * 16.0 + followup * 4.0 - distance / 120.0;
        if (clusterUtility > bestUtility)
        {
            bestUtility = clusterUtility;
            CopyVector(clusterTarget, bestTarget);
            enemyCount = clusterCount;
            burningAllies = 0;
        }
    }

    if (bestUtility <= 0.0) return false;
    CopyVector(bestTarget, target);
    utility = bestUtility;
    return true;
}

int CountNearbyKnownTeammates(int observer, const float position[3], float radius)
{
    int count = 0;
    int candidates = g_AliveTeamMask[g_WorldTeam[observer]];
    for (int client = 1; client <= MaxClients; client++)
    {
        if (MaskHasClient(candidates, client)
            && GetVectorDistance(g_WorldPosition[client], position) <= radius) count++;
    }
    return count;
}
