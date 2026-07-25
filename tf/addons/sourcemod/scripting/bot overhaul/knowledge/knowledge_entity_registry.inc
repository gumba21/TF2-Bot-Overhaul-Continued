#if defined _knowledge_entity_registry_inc
 #endinput
#endif
#define _knowledge_entity_registry_inc

void ScanExistingEntities()
{
    char buildingClasses[][] =
    {
        "obj_sentrygun",
        "obj_dispenser",
        "obj_teleporter"
    };

    for (int i = 0; i < sizeof(buildingClasses); i++)
    {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, buildingClasses[i])) != -1)
        {
            RegisterBuilding(entity, GetBuildingKind(buildingClasses[i]));
        }
    }

    char objectiveClasses[][] =
    {
        "team_control_point",
        "team_train_watcher",
        "item_teamflag",
        "func_capturezone",
        "trigger_capture_area"
    };

    for (int i = 0; i < sizeof(objectiveClasses); i++)
    {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, objectiveClasses[i])) != -1)
        {
            RegisterObjective(entity, objectiveClasses[i]);
        }
    }
}

BKEntityKind GetBuildingKind(const char[] classname)
{
    if (StrEqual(classname, "obj_sentrygun")) return BKEntity_Sentry;
    if (StrEqual(classname, "obj_dispenser")) return BKEntity_Dispenser;
    if (StrEqual(classname, "obj_teleporter")) return BKEntity_Teleporter;
    return BKEntity_None;
}

bool IsObjectiveClassname(const char[] classname)
{
    return StrEqual(classname, "team_control_point")
        || StrEqual(classname, "team_train_watcher")
        || StrEqual(classname, "item_teamflag")
        || StrEqual(classname, "func_capturezone")
        || StrEqual(classname, "trigger_capture_area");
}

void RegisterBuilding(int entity, BKEntityKind kind)
{
    if (entity <= MaxClients || entity >= GetMaxEntities() || FindBuildingSlot(entity) != BK_INVALID_SLOT)
    {
        return;
    }

    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        if (!g_BuildingActive[slot])
        {
            g_BuildingActive[slot] = true;
            g_BuildingEntity[slot] = entity;
            g_BuildingKind[slot] = kind;
            return;
        }
    }
}

void RegisterObjective(int entity, const char[] classname)
{
    if (entity <= MaxClients || entity >= GetMaxEntities() || FindObjectiveSlot(entity) != BK_INVALID_SLOT)
    {
        return;
    }

    for (int slot = 0; slot < BK_MAX_OBJECTIVES; slot++)
    {
        if (!g_ObjectiveActive[slot])
        {
            g_ObjectiveActive[slot] = true;
            g_ObjectiveEntity[slot] = entity;
            strcopy(g_ObjectiveClassname[slot], sizeof(g_ObjectiveClassname[]), classname);
            if (IsValidEntity(entity))
            {
                GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_ObjectivePosition[slot]);
            }
            return;
        }
    }
}

void RefreshBuildingRegistry()
{
    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        if (!g_BuildingActive[slot]) continue;

        int entity = g_BuildingEntity[slot];
        if (!IsValidEntity(entity))
        {
            ClearBuildingSlot(slot);
            continue;
        }

        g_BuildingTeam[slot] = GetEntProp(entity, Prop_Send, "m_iTeamNum");
        g_BuildingHealth[slot] = GetEntProp(entity, Prop_Send, "m_iHealth");
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_BuildingPosition[slot]);
    }
}

int FindBuildingSlot(int entity)
{
    for (int slot = 0; slot < BK_MAX_BUILDINGS; slot++)
    {
        if (g_BuildingActive[slot] && g_BuildingEntity[slot] == entity) return slot;
    }
    return BK_INVALID_SLOT;
}

int FindObjectiveSlot(int entity)
{
    for (int slot = 0; slot < BK_MAX_OBJECTIVES; slot++)
    {
        if (g_ObjectiveActive[slot] && g_ObjectiveEntity[slot] == entity) return slot;
    }
    return BK_INVALID_SLOT;
}

void ClearBuildingSlot(int slot)
{
    g_BuildingActive[slot] = false;
    g_BuildingEntity[slot] = -1;
    g_BuildingTeam[slot] = 0;
    g_BuildingKind[slot] = BKEntity_None;
    g_BuildingHealth[slot] = 0;
    ZeroVector(g_BuildingPosition[slot]);

    for (int observer = 1; observer <= MaxClients; observer++)
    {
        g_KnownBuilding[observer][slot] = false;
        g_KnownBuildingConfidence[observer][slot] = 0.0;
        ZeroVector(g_KnownBuildingPosition[observer][slot]);
        g_KnownBuildingUpdatedAt[observer][slot] = 0.0;
    }
}

void ClearObjectiveSlot(int slot)
{
    g_ObjectiveActive[slot] = false;
    g_ObjectiveEntity[slot] = -1;
    g_ObjectiveClassname[slot][0] = '\0';
    ZeroVector(g_ObjectivePosition[slot]);
}
