#if defined _knowledge_building_perception_inc
 #endinput
#endif
#define _knowledge_building_perception_inc

void UpdateObserverBuildingKnowledge(int observer, float now)
{
    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        if (!g_BuildingActive[slot]) continue;

        if (g_BuildingTeam[slot] == g_WorldTeam[observer])
        {
            ConfirmBuildingKnowledge(observer, slot, 1.0, now);
            continue;
        }

        float distance = GetVectorDistance(g_WorldPosition[observer], g_BuildingPosition[slot]);
        if (distance <= g_CvarVisionDistance.FloatValue
            && CanObserverSeePosition(observer, g_BuildingPosition[slot], g_BuildingEntity[slot]))
        {
            ConfirmBuildingKnowledge(observer, slot, 1.0, now);
        }
        else if (g_KnownBuilding[observer][slot])
        {
            float age = now - g_KnownBuildingUpdatedAt[observer][slot];
            g_KnownBuildingConfidence[observer][slot] = ClampFloat(1.0 - age * g_CvarConfidenceDecay.FloatValue, 0.0, 1.0);
            if (g_KnownBuildingConfidence[observer][slot] <= 0.05
                || age > g_CvarMemoryDuration.FloatValue * 2.0)
            {
                g_KnownBuilding[observer][slot] = false;
            }
        }
    }
}

void ConfirmBuildingKnowledge(int observer, int slot, float confidence, float now)
{
    g_KnownBuilding[observer][slot] = true;
    g_KnownBuildingConfidence[observer][slot] = confidence;
    CopyVector(g_BuildingPosition[slot], g_KnownBuildingPosition[observer][slot]);
    g_KnownBuildingUpdatedAt[observer][slot] = now;
}

bool CanObserverSeePosition(int observer, const float position[3], int targetEntity)
{
    float eye[3];
    GetClientEyePosition(observer, eye);
    if (!IsWithinObserverFov(observer, eye, position)) return false;

    Handle trace = TR_TraceRayFilterEx(eye, position, MASK_SHOT, RayType_EndPoint, TraceFilter_IgnoreObserver, observer);
    bool visible = !TR_DidHit(trace) || TR_GetEntityIndex(trace) == targetEntity;
    delete trace;
    return visible;
}
