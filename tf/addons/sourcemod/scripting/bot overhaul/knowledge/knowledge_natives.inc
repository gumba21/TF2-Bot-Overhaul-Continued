#if defined _knowledge_natives_inc
 #endinput
#endif
#define _knowledge_natives_inc

public any Native_IsEnabled(Handle plugin, int numParams)
{
    return g_CvarEnabled != null && g_CvarEnabled.BoolValue;
}

public any Native_GetKnownEnemies(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    int maximumResults = GetNativeCell(3);
    float minimumConfidence = view_as<float>(GetNativeCell(4));
    int results[MAXPLAYERS];
    int count = QueryKnownEnemies(observer, results, IntMin(maximumResults, sizeof(results)), minimumConfidence);
    SetNativeArray(2, results, count);
    return count;
}

public any Native_GetBurningTeammates(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    int maximumResults = GetNativeCell(3);
    float maximumDistance = view_as<float>(GetNativeCell(4));
    float minimumConfidence = view_as<float>(GetNativeCell(5));
    int results[MAXPLAYERS];
    int count = QueryBurningTeammates(observer, results, IntMin(maximumResults, sizeof(results)), maximumDistance, minimumConfidence);
    SetNativeArray(2, results, count);
    return count;
}

public any Native_GetLastKnownPosition(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    int subject = GetNativeCell(2);
    if (!IsValidKnowledgeObserver(observer)
        || subject < 1 || subject > MaxClients
        || !g_KnownPlayer[observer][subject]) return false;

    SetNativeArray(3, g_KnownPosition[observer][subject], 3);
    SetNativeCellRef(4, view_as<int>(g_KnownConfidence[observer][subject]));
    SetNativeCellRef(5, view_as<int>(g_KnownUncertainty[observer][subject]));
    return true;
}

public any Native_GetLargestEnemyCluster(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    float centroid[3];
    int count;
    float cohesion;
    float confidence;
    if (!GetLargestKnownEnemyCluster(observer, centroid, count, cohesion, confidence)) return false;

    SetNativeArray(2, centroid, 3);
    SetNativeCellRef(3, count);
    SetNativeCellRef(4, view_as<int>(cohesion));
    SetNativeCellRef(5, view_as<int>(confidence));
    return true;
}

public any Native_GetTeamState(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    if (team < 0 || team >= 4) return view_as<int>(BKTeam_Unknown);
    return view_as<int>(g_TeamState[team]);
}

public any Native_GetFrontLine(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    if (team < 2 || team > 3 || g_FrontLineConfidence[team] <= 0.0) return false;
    SetNativeArray(2, g_FrontLine[team], 3);
    SetNativeCellRef(3, view_as<int>(g_FrontLineConfidence[team]));
    return true;
}

public any Native_GetThreatAtPosition(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    float position[3];
    GetNativeArray(2, position, 3);
    return view_as<int>(CalculateThreatAtPosition(observer, position));
}

public any Native_FindBestMadMilkTarget(Handle plugin, int numParams)
{
    int observer = GetNativeCell(1);
    float target[3];
    int enemyCount;
    int burningAllies;
    float utility;
    if (!FindBestMadMilkTargetInternal(observer, target, enemyCount, burningAllies, utility)) return false;

    SetNativeArray(2, target, 3);
    SetNativeCellRef(3, enemyCount);
    SetNativeCellRef(4, burningAllies);
    SetNativeCellRef(5, view_as<int>(utility));
    return true;
}
