#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

Handle AttackTimer;

public Plugin myinfo = 
{
	name = "TF2 MVM RED SNIPER BOT FIX",
	author = "EfeDursun125",
	description = "Now sniper bots shoting!",
	version = "1.0",
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

float moveBackwards(float vel[3], float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

float moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsValidClient(client) && GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				float camangle[3];
				float clientEyes[3];
				float targetEyes[3];
				GetClientEyePosition(client, clientEyes);
				TFClassType class = TF2_GetPlayerClass(client);
				int team = GetClientTeam(client);
				int Ent = Client_GetClosest(clientEyes, client);
				
				if(class == TFClass_Sniper && IsWeaponSlotActive(client, 0) && team == 2)
				{
					if(Ent != -1)
					{
						float vec[3];
						float angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						MakeVectorFromPoints(targetEyes, clientEyes, vec);
						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;
						ClampAngle(camangle);
						targetEyes[2] += 70.0;
						
						float location_check[3];
						GetClientAbsOrigin(client, location_check);

						float chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);
						
						if(chainDistance < 500.0)
						{
							vel = moveBackwards(vel,300.0);
						}
						
						if(AttackTimer == INVALID_HANDLE)
						{
							AttackTimer = CreateTimer(5.5, ResetAttackTimer);
							if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								buttons |= IN_ATTACK;
							}
							else
							{
								vel = moveForward(vel,300.0);
								buttons |= IN_ATTACK;
							}
						}
						
						if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
							buttons |= IN_ATTACK2;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action ResetAttackTimer(Handle timer)
{
	AttackTimer = INVALID_HANDLE;
}

bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int Client_GetClosest(float vecOrigin_center[3], const int client)
{
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged) || TF2_IsPlayerInCondition(client, TFCond_Disguised))
				continue;
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
	}
	return closestEdict;
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock float TF_GetUberLevel(int client)
{
	int index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	else
		return 0.0;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

public bool Filter(int entity, int mask)
{
	return !(IsValidClient(entity));
}