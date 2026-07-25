#if defined _navigation_graph_inc
 #endinput
#endif
#define _navigation_graph_inc

void TryBuildNavigationGraph()
{
    if (!g_NavEnabled.BoolValue || !g_NavLibraryAvailable) return;
    if (!NavMesh_Exists())
    {
        DisableGraphSafely("no .nav mesh exists for this map");
        return;
    }

    ResetGraphStorage();
    int gridX = NavMesh_GetGridSizeX();
    int gridY = NavMesh_GetGridSizeY();
    if (gridX <= 0 || gridY <= 0)
    {
        DisableGraphSafely("nav grid dimensions are invalid");
        return;
    }

    ArrayStack stack = new ArrayStack();
    char key[24];
    for (int x = 0; x < gridX && g_AreaCount < BN_MAX_AREAS; x++)
    {
        for (int y = 0; y < gridY && g_AreaCount < BN_MAX_AREAS; y++)
        {
            stack.Clear();
            NavMesh_GetAreasOnGrid(stack, x, y);
            while (!stack.Empty && g_AreaCount < BN_MAX_AREAS)
            {
                int navIndex = stack.Pop();
                IntToString(navIndex, key, sizeof(key));
                int existing;
                if (g_AreaSlotByIndex.GetValue(key, existing)) continue;

                int slot = g_AreaCount++;
                g_AreaSlotByIndex.SetValue(key, slot);
                g_AreaIndex[slot] = navIndex;
                g_AreaId[slot] = NavMeshArea_GetID(navIndex);
                NavMeshArea_GetCenter(navIndex, g_AreaCenter[slot]);
                NavMeshArea_GetExtentLow(navIndex, g_AreaMins[slot]);
                NavMeshArea_GetExtentHigh(navIndex, g_AreaMaxs[slot]);
                g_AreaWidth[slot] = FloatAbs(g_AreaMaxs[slot][0] - g_AreaMins[slot][0]);
                g_AreaLength[slot] = FloatAbs(g_AreaMaxs[slot][1] - g_AreaMins[slot][1]);
                g_AreaHeight[slot] = g_AreaCenter[slot][2];
                g_AreaLastDynamic[slot] = GetGameTime();
            }
        }
    }
    delete stack;

    if (g_AreaCount <= 0)
    {
        DisableGraphSafely("the nav parser returned zero areas");
        return;
    }

    BuildGraphEdges();
    AnalyzeStaticGeometryInitial();
    LoadNavigationMetadata();
    g_StaticAnalysisCursor = 0;
    g_StaticAnalysisComplete = false;
    g_GraphReady = true;
    ResetDynamicOverlay();
    UpdatePlayerAreas(GetGameTime(), true);

    LogMessage("[BotNav] Cached %d nav areas and %d directed connections.", g_AreaCount, g_EdgeCount);
}

void ResetGraphStorage()
{
    int oldCount = g_AreaCount;
    g_AreaCount = 0;
    g_EdgeCount = 0;
    g_GraphReady = false;
    g_StaticAnalysisComplete = false;
    g_AreaSlotByIndex.Clear();

    for (int slot = 0; slot < oldCount; slot++)
    {
        g_AreaIndex[slot] = BN_INVALID_AREA;
        g_AreaId[slot] = 0;
        g_AreaLabels[slot] = BNArea_None;
        g_AreaEdgeStart[slot] = 0;
        g_AreaEdgeCount[slot] = 0;
        g_AreaOpenness[slot] = 0.0;
        g_AreaCover[slot] = 0.0;
        g_AreaChoke[slot] = 0.0;
        g_AreaHighGround[slot] = 0.0;
    }
}

void BuildGraphEdges()
{
    ArrayList neighbors = new ArrayList();
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        g_AreaEdgeStart[slot] = g_EdgeCount;
        neighbors.Clear();
        CNavArea area = CNavArea(g_AreaIndex[slot]);
        area.GetAdjacentList(NAV_DIR_COUNT, neighbors);
        for (int i = 0; i < neighbors.Length && g_EdgeCount < BN_MAX_EDGES; i++)
        {
            CNavArea adjacent = view_as<CNavArea>(neighbors.Get(i));
            int targetSlot = GetAreaSlotFromNavIndex(adjacent.Index);
            if (targetSlot == BN_INVALID_AREA || targetSlot == slot) continue;

            g_EdgeTarget[g_EdgeCount] = targetSlot;
            g_EdgeDistance[g_EdgeCount] = GetVectorDistance(g_AreaCenter[slot], g_AreaCenter[targetSlot]);
            g_EdgeDirection[g_EdgeCount] = area.ComputeDirection(g_AreaCenter[targetSlot]);
            g_EdgeCount++;
            g_AreaEdgeCount[slot]++;
        }
    }
    delete neighbors;
}

void AnalyzeStaticGeometryInitial()
{
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        float smaller = FloatMin(g_AreaWidth[slot], g_AreaLength[slot]);
        float larger = FloatMax(g_AreaWidth[slot], g_AreaLength[slot]);
        int degree = g_AreaEdgeCount[slot];
        int labels = BNArea_None;

        if (smaller < 96.0) labels |= BNArea_Narrow;
        if (smaller > 280.0 && larger > 420.0) labels |= BNArea_Wide;
        if (degree <= 1) labels |= BNArea_DeadEnd;
        if (degree >= 4) labels |= BNArea_Intersection;
        if (smaller < 150.0 && larger > smaller * 2.1) labels |= BNArea_Corridor;

        float narrowness = 1.0 - ClampFloat(smaller / 320.0, 0.0, 1.0);
        float bridgeValue = degree >= 2 && degree <= 3 ? 1.0 : 0.35;
        g_AreaChoke[slot] = ClampFloat(narrowness * bridgeValue, 0.0, 1.0);
        if (g_AreaChoke[slot] >= 0.58) labels |= BNArea_Choke;

        float neighborHeight = 0.0;
        int neighborCount = 0;
        int start = g_AreaEdgeStart[slot];
        for (int edge = start; edge < start + g_AreaEdgeCount[slot]; edge++)
        {
            neighborHeight += g_AreaHeight[g_EdgeTarget[edge]];
            neighborCount++;
        }
        if (neighborCount > 0)
        {
            float delta = g_AreaHeight[slot] - neighborHeight / float(neighborCount);
            g_AreaHighGround[slot] = ClampFloat(delta / 160.0, -1.0, 1.0);
            if (g_AreaHighGround[slot] > 0.28) labels |= BNArea_HighGround;
            if (g_AreaHighGround[slot] < -0.28) labels |= BNArea_LowGround;
        }

        g_AreaLabels[slot] = labels;
    }
}

void RunStaticAnalysisBudget(int budget)
{
    if (!g_GraphReady || g_StaticAnalysisComplete) return;

    for (int work = 0; work < budget && g_StaticAnalysisCursor < g_AreaCount; work++, g_StaticAnalysisCursor++)
    {
        AnalyzeAreaVisibility(g_StaticAnalysisCursor);
    }

    if (g_StaticAnalysisCursor >= g_AreaCount)
    {
        g_StaticAnalysisComplete = true;
        if (g_NavDebug.BoolValue) LogMessage("[BotNav] Static trace analysis completed for %d areas.", g_AreaCount);
    }
}

void AnalyzeAreaVisibility(int slot)
{
    float start[3];
    CopyVector3(g_AreaCenter[slot], start);
    start[2] += 42.0;
    float totalDistance = 0.0;
    int blockedDirections = 0;
    static const float directions[4][2] =
    {
        {1.0, 0.0}, {-1.0, 0.0}, {0.0, 1.0}, {0.0, -1.0}
    };

    for (int i = 0; i < 4; i++)
    {
        float finish[3];
        finish[0] = start[0] + directions[i][0] * 768.0;
        finish[1] = start[1] + directions[i][1] * 768.0;
        finish[2] = start[2];
        Handle trace = TR_TraceRayEx(start, finish, MASK_SOLID, RayType_EndPoint);
        float end[3];
        TR_GetEndPosition(end, trace);
        float distance = GetVectorDistance(start, end);
        totalDistance += distance;
        if (distance < 240.0) blockedDirections++;
        delete trace;
    }

    g_AreaOpenness[slot] = ClampFloat(totalDistance / (768.0 * 4.0), 0.0, 1.0);
    g_AreaCover[slot] = ClampFloat(float(blockedDirections) / 4.0 + (1.0 - g_AreaOpenness[slot]) * 0.35, 0.0, 1.0);

    if (g_AreaOpenness[slot] > 0.72) g_AreaLabels[slot] |= BNArea_Open | BNArea_ExposedCrossing;
    else if (g_AreaOpenness[slot] < 0.34) g_AreaLabels[slot] |= BNArea_Enclosed;
    if (g_AreaCover[slot] > 0.58) g_AreaLabels[slot] |= BNArea_Cover | BNArea_Peek;
    if (totalDistance / 4.0 > 560.0) g_AreaLabels[slot] |= BNArea_LongSightline;
    if ((g_AreaLabels[slot] & BNArea_HighGround) != 0 && g_AreaCover[slot] > 0.35) g_AreaLabels[slot] |= BNArea_Defensive;
    if ((g_AreaLabels[slot] & BNArea_Intersection) != 0 && g_AreaCover[slot] > 0.45) g_AreaLabels[slot] |= BNArea_Ambush;
}

void LoadNavigationMetadata()
{
    char map[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/bot_overhaul/navigation/%s.cfg", map);
    if (!FileExists(path)) return;

    KeyValues kv = new KeyValues("NavigationMetadata");
    if (!kv.ImportFromFile(path))
    {
        delete kv;
        LogError("[BotNav] Failed to parse optional navigation metadata: %s", path);
        return;
    }

    if (kv.GotoFirstSubKey(false))
    {
        do
        {
            int areaId = kv.GetNum("area_id", 0);
            int slot = FindAreaSlotById(areaId);
            if (slot == BN_INVALID_AREA) continue;
            char labels[256];
            kv.GetString("labels", labels, sizeof(labels));
            ApplyMetadataLabels(slot, labels);
        }
        while (kv.GotoNextKey(false));
    }
    delete kv;
}

void ApplyMetadataLabels(int slot, const char[] labels)
{
    if (StrContains(labels, "main", false) != -1) g_AreaLabels[slot] |= BNArea_MainRoute;
    if (StrContains(labels, "flank", false) != -1) g_AreaLabels[slot] |= BNArea_FlankConnection;
    if (StrContains(labels, "objective", false) != -1) g_AreaLabels[slot] |= BNArea_ObjectiveApproach;
    if (StrContains(labels, "spawn", false) != -1) g_AreaLabels[slot] |= BNArea_SpawnApproach;
    if (StrContains(labels, "cover", false) != -1) g_AreaLabels[slot] |= BNArea_Cover;
    if (StrContains(labels, "avoid", false) != -1) g_AreaLabels[slot] |= BNArea_DeadEnd;
}

int GetAreaSlotFromNavIndex(int navIndex)
{
    char key[24];
    IntToString(navIndex, key, sizeof(key));
    int slot;
    return g_AreaSlotByIndex.GetValue(key, slot) ? slot : BN_INVALID_AREA;
}

int FindAreaSlotById(int areaId)
{
    for (int slot = 0; slot < g_AreaCount; slot++)
    {
        if (g_AreaId[slot] == areaId) return slot;
    }
    return BN_INVALID_AREA;
}

int FindAreaSlotFromPosition(const float position[3], bool anyZ = false)
{
    if (!g_GraphReady || !g_NavLibraryAvailable) return BN_INVALID_AREA;
    CNavArea area = NavMesh_GetNearestArea(position, anyZ, 2048.0, false, true, -2);
    if (area == INVALID_NAV_AREA) return BN_INVALID_AREA;
    return GetAreaSlotFromNavIndex(area.Index);
}

void CopyVector3(const float source[3], float destination[3])
{
    destination[0] = source[0];
    destination[1] = source[1];
    destination[2] = source[2];
}

float ClampFloat(float value, float minimum, float maximum)
{
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
}
