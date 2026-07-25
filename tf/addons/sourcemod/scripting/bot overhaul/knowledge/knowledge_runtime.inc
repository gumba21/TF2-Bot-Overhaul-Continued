#if defined _knowledge_runtime_inc
 #endinput
#endif
#define _knowledge_runtime_inc

public Action OnPlayerRunCmd(
    int client,
    int &buttons,
    int &impulse,
    float velocity[3],
    float angles[3],
    int &weapon,
    int &subtype,
    int &cmdnum,
    int &tickcount,
    int &seed,
    int mouse[2]
)
{
    if (!g_CvarEnabled.BoolValue
        || !g_CvarMadMilkEnabled.BoolValue
        || !IsClientInGame(client)
        || !IsFakeClient(client)
        || !IsPlayerAlive(client)
        || TF2_GetPlayerClass(client) != TFClass_Scout)
    {
        return Plugin_Continue;
    }

    float now = GetGameTime();
    if (now < g_MilkCooldownUntil[client])
    {
        return Plugin_Continue;
    }

    int milk = GetMadMilkWeapon(client);
    if (milk == -1)
    {
        g_MilkPending[client] = false;
        return Plugin_Continue;
    }

    if (!g_MilkPending[client])
    {
        float target[3];
        int enemyCount;
        int burningAllies;
        float utility;
        if (!FindBestMadMilkTargetInternal(client, target, enemyCount, burningAllies, utility)
            || utility < g_CvarMadMilkThreshold.FloatValue)
        {
            return Plugin_Continue;
        }

        g_MilkPending[client] = true;
        CopyVector(target, g_MilkTarget[client]);
        g_MilkPendingUntil[client] = now + 0.85;
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", milk);

        if (g_CvarDebug.BoolValue)
        {
            PrintToServer("[BK] Mad Milk candidate: bot=%N enemies=%d burning_allies=%d utility=%.1f", client, enemyCount, burningAllies, utility);
        }
        return Plugin_Changed;
    }

    if (now > g_MilkPendingUntil[client])
    {
        g_MilkPending[client] = false;
        g_MilkCooldownUntil[client] = now + 1.0;
        return Plugin_Continue;
    }

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (activeWeapon != milk)
    {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", milk);
        return Plugin_Changed;
    }

    float eye[3];
    float direction[3];
    GetClientEyePosition(client, eye);
    MakeVectorFromPoints(eye, g_MilkTarget[client], direction);
    GetVectorAngles(direction, angles);

    float nextAttack = GetEntPropFloat(milk, Prop_Send, "m_flNextPrimaryAttack");
    if (nextAttack <= now)
    {
        buttons |= IN_ATTACK;
        g_MilkPending[client] = false;
        g_MilkCooldownUntil[client] = now + 8.0;
    }

    return Plugin_Changed;
}

int GetMadMilkWeapon(int client)
{
    int weapon = GetPlayerWeaponSlot(client, 1);
    if (weapon <= MaxClients || !IsValidEntity(weapon))
    {
        return -1;
    }

    int itemDefinition = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    if (itemDefinition == BK_MAD_MILK_INDEX || itemDefinition == BK_FESTIVE_MAD_MILK_INDEX)
    {
        return weapon;
    }

    return -1;
}

public void Event_PlayerLifecycle(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0)
    {
        return;
    }

    UpdateWorldPlayer(client, GetGameTime());
    if (StrEqual(name, "player_spawn"))
    {
        ClearSubjectFromAllObservers(client);
        g_MilkPending[client] = false;
        g_MilkCooldownUntil[client] = 0.0;
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim <= 0)
    {
        return;
    }

    float now = GetGameTime();
    UpdateWorldPlayer(victim, now);
    for (int observer = 1; observer <= MaxClients; observer++)
    {
        if (g_KnownPlayer[observer][victim])
        {
            g_KnownLabels[observer][victim] |= BKLabel_Dead;
            g_KnownLabels[observer][victim] &= ~BKLabel_Alive;
            g_KnownConfidence[observer][victim] = 1.0;
            g_KnownUpdatedAt[observer][victim] = now;
            g_KnownExpiresAt[observer][victim] = now + 4.0;
            g_KnownSource[observer][victim] = BKSource_ObjectiveEvent;
            g_KnownScope[observer][victim] = BKScope_TeamShared;
        }
    }
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    float now = GetGameTime();

    if (victim > 0)
    {
        g_WorldLastDamageAt[victim] = now;
    }

    if (attacker > 0 && attacker != victim)
    {
        g_WorldLastDamageDealtAt[attacker] = now;
        if (victim > 0 && g_WorldIsBot[victim] && g_WorldTeam[victim] != g_WorldTeam[attacker])
        {
            ConfirmPlayerKnowledge(victim, attacker, BKSource_DamageReceived, BKScope_BotLocal, 0.92, 80.0, now);
        }
        AddAudibleKnowledge(attacker, 0.74, 150.0, now);
    }
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        AddAudibleKnowledge(client, 0.66, 190.0, GetGameTime());
    }
}

public void Event_ObjectChanged(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("index");
    if (entity <= 0)
    {
        entity = event.GetInt("object");
    }

    if (StrEqual(name, "object_destroyed"))
    {
        int slot = FindBuildingSlot(entity);
        if (slot != BK_INVALID_SLOT)
        {
            ClearBuildingSlot(slot);
        }
    }
    else if (entity > 0 && IsValidEntity(entity))
    {
        char classname[64];
        GetEntityClassname(entity, classname, sizeof(classname));
        RegisterBuilding(entity, GetBuildingKind(classname));
    }
}

public void Event_ObjectiveChanged(Event event, const char[] name, bool dontBroadcast)
{
    g_LastObjectiveEventAt = GetGameTime();
}

public void Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
    ResetRoundKnowledge();
}
