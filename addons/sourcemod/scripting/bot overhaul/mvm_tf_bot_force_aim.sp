#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "BotAimMvM",
	author = "tRololo312312",
	description = "Makes Bots on MvM not so useless",
	version = "1.1",
	url = "http://steamcommunity.com/profiles/76561198039186809"
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		if(IsValidClient(client))
		{
			if(IsFakeClient(client))
			{
				if(IsPlayerAlive(client))
				{
					int team = GetClientTeam(client);
					if(team == 2)
					{
						float camangle[3];
						float clientEyes[3];
						float targetEyes[3];
						float fEntityLocation[3];
						GetClientEyePosition(client, clientEyes);
						TFClassType class = TF2_GetPlayerClass(client);
						int iEnt = -1;
						int Ent = Client_GetClosest(clientEyes, client);
						if((iEnt = FindEntityByClassname(iEnt, "entity_revive_marker")) != INVALID_ENT_REFERENCE && class == TFClass_Medic)
						{
							if(IsValidEntity(iEnt))
							{
								float vec[3];
								float angle[3];
								GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntityLocation);
								GetEntPropVector(iEnt, Prop_Data, "m_angRotation", angle);
								fEntityLocation[2] += 33.5;
								MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
								GetVectorAngles(vec, camangle);
								camangle[0] *= -1.0;
								camangle[1] += 180.0;
								ClampAngle(camangle);
	
								float location_check[3];
								GetClientAbsOrigin(client, location_check);
	
								float chainDistance;
								chainDistance = GetVectorDistance(location_check,targetEyes);
	
								if(IsPointVisibleTank(clientEyes, fEntityLocation))
								{
									int iMediGun = GetPlayerWeaponSlot(client, 1);
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMediGun);
									if(chainDistance <175.0)
									{
										ScaleVector(vec, 400.0);
									}
									else
									{
										ScaleVector(vec, -400.0);
									}
									vec[2] = -450.0;
									//TeleportEntity(client, NULL_VECTOR, camangle, vec);
									TF2_LookAtBuilding(client, targetEyes, 0.080);
									buttons |= IN_ATTACK;
								}
							}
						}
						else if((iEnt = FindEntityByClassname(iEnt, "tank_boss")) != INVALID_ENT_REFERENCE)
						{
							if(IsValidEntity(iEnt))
							{
								float vec[3];
								float angle[3];
								GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntityLocation);
								GetEntPropVector(iEnt, Prop_Data, "m_angRotation", angle);
								fEntityLocation[2] += 33.5;
								MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
								GetVectorAngles(vec, camangle);
								camangle[0] *= -1.0;
								camangle[1] += 180.0;
								ClampAngle(camangle);
	
								float location_check[3];
								GetClientAbsOrigin(client, location_check);
	
								float chainDistance;
								chainDistance = GetVectorDistance(location_check,fEntityLocation);
	
								if(class == TFClass_Pyro && chainDistance <400.0)
								{
									GetAngleVectors(camangle, vec, NULL_VECTOR, NULL_VECTOR);
									ScaleVector(vec, 400.0);
									vec[2] = -450.0;
									if(IsPointVisibleTank(clientEyes, fEntityLocation))
									{
										//TeleportEntity(client, NULL_VECTOR, camangle, vec);
										TF2_LookAtBuilding(client, targetEyes, 0.080);
										buttons |= IN_ATTACK;
									}
								}
								else if(chainDistance <400.0)
								{
									if(IsPointVisibleTank(clientEyes, fEntityLocation))
									{
										//TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
										TF2_LookAtBuilding(client, targetEyes, 0.080);
										buttons |= IN_ATTACK;
									}
								}
							}
						}
						else if(Ent != -1)
						{
							float vec[3];
							float angle[3];
							GetClientAbsOrigin(Ent, targetEyes);
							GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
							if(GetClientButtons(Ent) & IN_DUCK)
							{
								targetEyes[2] += 15.0;
							}
							else
							{
								targetEyes[2] += 33.5;
							}
							MakeVectorFromPoints(targetEyes, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);
	
							float location_check[3];
							GetClientAbsOrigin(client, location_check);
	
							float chainDistance;
							chainDistance = GetVectorDistance(location_check,targetEyes);
							
							if(chainDistance < 1000.0 && TF2_IsPlayerInCondition(Ent, TFCond_DefenseBuffNoCritBlock))
							{
								GetAngleVectors(camangle, vec, NULL_VECTOR, NULL_VECTOR);
								if(chainDistance < 175.0)
								{
									ScaleVector(vec, -400.0);
								}
								else
								{
									ScaleVector(vec, 400.0);
								}
								vec[2] = -450.0;
								buttons |= IN_ATTACK;
								//TeleportEntity(client, NULL_VECTOR, camangle, vec);
								TF2_LookAtBuilding(client, targetEyes, 0.080);
							}
							else if(class == TFClass_Pyro && chainDistance <400.0)
							{
								GetAngleVectors(camangle, vec, NULL_VECTOR, NULL_VECTOR);
								if(chainDistance <175.0)
								{
									ScaleVector(vec, -400.0);
								}
								else
								{
									ScaleVector(vec, 400.0);
								}
								vec[2] = -450.0;
								buttons |= IN_ATTACK;
								//TeleportEntity(client, NULL_VECTOR, camangle, vec);
								TF2_LookAtBuilding(client, targetEyes, 0.080);
							}
							else
							{
								//TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
								TF2_LookAtBuilding(client, targetEyes, 0.080);
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
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
			TFClassType class = TF2_GetPlayerClass(client);
			if(class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Sniper)
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

stock bool IsPointVisible(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

public bool TraceEntityFilterStuffTank(int entity, int mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}  

stock float AngleNormalize(float angle)
{
    angle = fmodf(angle, 360.0);
    if (angle > 180) 
    {
        angle -= 360;
    }
    if (angle < -180)
    {
        angle += 360;
    }
    
    return angle;
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
