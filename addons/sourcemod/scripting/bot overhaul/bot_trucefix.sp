#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

int Truce = 0;
int CorrectMap = 0;

public Plugin myinfo = 
{
	name = "Bot Truce Fix",
	author = "Showin",
	description = "nope",
	version = "1.0",
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public void OnPluginStart()
{
	HookEvent("merasmus_summoned", TruceStarted);
	HookEvent("merasmus_killed", TruceEnded);
	HookEvent("merasmus_escaped", TruceEnded);
	HookEvent("eyeball_boss_summoned", TruceStarted);
	HookEvent("eyeball_boss_killed", TruceEnded);
	HookEvent("eyeball_boss_escaped", TruceEnded);
}

public void OnMapStart()
{
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if ( StrContains( currentMap, "koth_lakeside_event" , false) != -1 || StrContains( currentMap, "koth_viaduct_event" , false) != -1)
	{
		CorrectMap = 1;

	}
	else
	{		
		CorrectMap = 0;
		
	}
}

public Action TruceStarted(Handle event , const char[] name , bool dontBroadcast)
{
	Truce = 1;
}

public Action TruceEnded(Handle event , const char[] name , bool dontBroadcast)
{
	Truce = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(CorrectMap == 1 && Truce == 1)
	{
		if(IsValidClient(client))
		{
			if(IsFakeClient(client))
			{
				if(IsPlayerAlive(client))
				{
					TFClassType class = TF2_GetPlayerClass(client);
					if(class != TFClass_Medic &&  class != TFClass_Engineer)
					{	
						// Go Towards Eye Boss
						int BOSSENT = -1;
						if((BOSSENT = FindEntityByClassname(BOSSENT, "eyeball_boss")) != INVALID_ENT_REFERENCE)
						{
							float clientOrigin[3];
							float BOSSENTOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(BOSSENT, Prop_Send, "m_vecOrigin", BOSSENTOrigin);

							float BOSSENTDistance;
							BOSSENTDistance = GetVectorDistance(clientOrigin, BOSSENTOrigin);

							if(IsPointVisibleTank(clientOrigin, BOSSENTOrigin))
							{
								TF2_LookAtBuilding(client, BOSSENTOrigin, 0.055);
								buttons |= IN_ATTACK;
								if(BOSSENTDistance > 50.0 && BOSSENTDistance < 3000.0)
								{
									vel = moveForward(vel,300.0);
								}

							}
							else
							{
								buttons &= ~IN_ATTACK;
								buttons &= ~IN_ATTACK2;
							}
						}

						// Go Towards Merasmus Boss
						int BOSSENT2 = -1;
						if((BOSSENT2 = FindEntityByClassname(BOSSENT2, "merasmus")) != INVALID_ENT_REFERENCE)
						{
							float clientOrigin[3];
							float BOSSENT2Origin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(BOSSENT2, Prop_Send, "m_vecOrigin", BOSSENT2Origin);

							float BOSSENT2Distance;
							BOSSENT2Distance = GetVectorDistance(clientOrigin, BOSSENT2Origin);

							if(IsPointVisibleTank(clientOrigin, BOSSENT2Origin))
							{
								TF2_LookAtBuilding(client, BOSSENT2Origin, 0.055);
								buttons |= IN_ATTACK;
								if(BOSSENT2Distance > 50.0 && BOSSENT2Distance < 3000.0)
								{
									vel = moveForward(vel,300.0);
								}

							}
							else
							{
								buttons &= ~IN_ATTACK;
								buttons &= ~IN_ATTACK2;
							}
						}

						// Go Towards Merasmus Props
						int BOSSENT3 = -1;
						if((BOSSENT3 = FindEntityByClassname(BOSSENT3, "tf_merasmus_trick_or_treat_prop")) != INVALID_ENT_REFERENCE)
						{
							float clientOrigin[3];
							float BOSSENT3Origin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(BOSSENT3, Prop_Send, "m_vecOrigin", BOSSENT3Origin);

							float BOSSENT3Distance;
							BOSSENT3Distance = GetVectorDistance(clientOrigin, BOSSENT3Origin);

							if(IsPointVisibleTank(clientOrigin, BOSSENT3Origin))
							{
								TF2_LookAtBuilding(client, BOSSENT3Origin, 0.055);
								buttons |= IN_ATTACK;
								if(BOSSENT3Distance > 50.0 && BOSSENT3Distance < 3000.0)
								{
									vel = moveForward(vel,300.0);
								}

							}
							else
							{
								buttons &= ~IN_ATTACK;
								buttons &= ~IN_ATTACK2;
							}
						}

					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

bool IsValidClient( int client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

public bool Filter(int entity, int mask)
{
	return !(IsValidClient(entity));
}

public bool TraceRayDontHitPlayers(int entity, int mask)
{
	if(entity <= MaxClients)
	{
	return false;
	}
	return true;
}

stock void TF2_LookAtBuilding(int client, float flGoal[3], float flAimSpeed = 0.05) // Smooth Aim From Pelipoika
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);

	float FixBuildingAngle[3];
	FixBuildingAngle[1] += 180.0; // Fix For Aim Building's angle

	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);

	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) + FixBuildingAngle[1] * flAimSpeed;

	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

stock void TF2_LookAtPos(int client, float flGoal[3], float flAimSpeed = 0.05) // Smooth Aim From Pelipoika
{
    float flPos[3];
    GetClientEyePosition(client, flPos);

    float flAng[3];
    GetClientEyeAngles(client, flAng);
    
    // get normalised direction from target to client
    float desired_dir[3];
    MakeVectorFromPoints(flPos, flGoal, desired_dir);
    GetVectorAngles(desired_dir, desired_dir);
    
    // ease the current direction to the target direction
    flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
    flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;
	
    TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

stock float AngleNormalize(float angle)
{
    angle = fmodf(angle, 360.0);
    if (angle > 89) 
    {
        angle -= 360;
    }
    if (angle < -89)
    {
        angle += 360;
    }
    
    return angle;
}

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
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

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuffTank(int entity, int mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}