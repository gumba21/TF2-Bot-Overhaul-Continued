#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.0"

public Plugin myinfo = 
{
	name = "TFBot Collect Money",
	author = "EfeDursun125",
	description = "TFBots now collecting money!",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

float moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	if(IsValidClient(client) && GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				int team = GetClientTeam(client);
				if(team == 2)
				{
					float clientEyes[3];
					float targetEyes[3];
					int iEnt = -1;
					int iEnt2 = -1;
					int iEnt3 = -1;
					int iEnt4 = -1;
					int iCash = 5;
					int iCash2 = 10;
					int iCash3 = 25;
					int iCash4 = 15;
					int FakeCash = 1200;
					int Ent = Client_GetClosest(clientEyes, client);
					GetClientEyePosition(client, clientEyes);
					TFClassType class = TF2_GetPlayerClass(client);
				
					if((iEnt = FindEntityByClassname(iEnt, "item_currencypack_small")) != INVALID_ENT_REFERENCE)
					{
						for (int search = 1; search <= MaxClients; search++)
						{
							if (Ent == -1 && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)) && class == TFClass_Scout)
							{
								float flAimSpeed = 0.05;
								float vec[3];
								float angle[3];
							
								GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", targetEyes);
								GetEntPropVector(iEnt, Prop_Data, "m_angRotation", angle);
							
								float flGoal[3];
								GetClientAbsOrigin(search, flGoal);
							
								float flPos[3];
								GetClientEyePosition(client, flPos);

								float flAng[3];
								GetClientEyeAngles(client, flAng);
							
								MakeVectorFromPoints(targetEyes, clientEyes, vec);
								GetVectorAngles(vec, flAng);
								flAng[0] *= GetRandomFloat(-1.0, 1.0);
								flAng[1] += GetRandomFloat(-180.0, 180.0);
								ClampAngle(flAng);
							
								targetEyes[2] += 0;
								targetEyes[1] += 0;
							
								float desired_dir[3];
								MakeVectorFromPoints(flPos, flGoal, desired_dir);
								GetVectorAngles(desired_dir, desired_dir);

								flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
								flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;
							
								if(IsPointVisibleTank(targetEyes, flPos))
								{
									TF2_LookAtPos(client, targetEyes, 0.075);
									vel = moveForward(vel,300.0);
								}
							}
						}
					}
					else if((iEnt2 = FindEntityByClassname(iEnt2, "item_currencypack_medium")) != INVALID_ENT_REFERENCE)
					{
						for (int search = 1; search <= MaxClients; search++)
						{
							if (Ent == -1 && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)) && class == TFClass_Scout)
							{
								float flAimSpeed = 0.05;
								float vec[3];
								float angle[3];
							
								GetEntPropVector(iEnt2, Prop_Send, "m_vecOrigin", targetEyes);
								GetEntPropVector(iEnt2, Prop_Data, "m_angRotation", angle);
							
								float flGoal[3];
								GetClientAbsOrigin(search, flGoal);
							
								float flPos[3];
								GetClientEyePosition(client, flPos);

								float flAng[3];
								GetClientEyeAngles(client, flAng);
							
								MakeVectorFromPoints(targetEyes, clientEyes, vec);
								GetVectorAngles(vec, flAng);
								flAng[0] *= GetRandomFloat(-1.0, 1.0);
								flAng[1] += GetRandomFloat(-180.0, 180.0);
								ClampAngle(flAng);
							
								targetEyes[2] += 0;
								targetEyes[1] += 0;
							
								float desired_dir[3];
								MakeVectorFromPoints(flPos, flGoal, desired_dir);
								GetVectorAngles(desired_dir, desired_dir);

								flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
								flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;
							
								if(IsPointVisibleTank(targetEyes, flPos))
								{
									TF2_LookAtPos(client, targetEyes, 0.075);
									vel = moveForward(vel,300.0);
								}
							}
						}
					}
					else if((iEnt3 = FindEntityByClassname(iEnt3, "item_currencypack_large")) != INVALID_ENT_REFERENCE)
					{
						for (int search = 1; search <= MaxClients; search++)
						{
							if (Ent == -1 && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)) && class == TFClass_Scout)
							{
								float flAimSpeed = 0.05;
								float vec[3];
								float angle[3];
							
								GetEntPropVector(iEnt3, Prop_Send, "m_vecOrigin", targetEyes);
								GetEntPropVector(iEnt3, Prop_Data, "m_angRotation", angle);
							
								float flGoal[3];
								GetClientAbsOrigin(search, flGoal);
							
								float flPos[3];
								GetClientEyePosition(client, flPos);

								float flAng[3];
								GetClientEyeAngles(client, flAng);
							
								MakeVectorFromPoints(targetEyes, clientEyes, vec);
								GetVectorAngles(vec, flAng);
								flAng[0] *= GetRandomFloat(-1.0, 1.0);
								flAng[1] += GetRandomFloat(-180.0, 180.0);
								ClampAngle(flAng);
							
								targetEyes[2] += 0;
								targetEyes[1] += 0;
							
								float desired_dir[3];
								MakeVectorFromPoints(flPos, flGoal, desired_dir);
								GetVectorAngles(desired_dir, desired_dir);

								flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
								flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;
								
								if(IsPointVisibleTank(targetEyes, flPos))
								{
									TF2_LookAtPos(client, targetEyes, 0.075);
									vel = moveForward(vel,300.0);
								}
							}
						}
					}
					else if((iEnt4 = FindEntityByClassname(iEnt4, "item_currencypack_custom")) != INVALID_ENT_REFERENCE)
					{
						for (int search = 1; search <= MaxClients; search++)
						{
							if (Ent == -1 && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)) && class == TFClass_Scout)
							{
								float flAimSpeed = 0.05;
								float vec[3];
								float angle[3];
							
								GetEntPropVector(iEnt4, Prop_Send, "m_vecOrigin", targetEyes);
								GetEntPropVector(iEnt4, Prop_Data, "m_angRotation", angle);
							
								float flGoal[3];
								GetClientAbsOrigin(search, flGoal);
							
								float flPos[3];
								GetClientEyePosition(client, flPos);

								float flAng[3];
								GetClientEyeAngles(client, flAng);
							
								MakeVectorFromPoints(targetEyes, clientEyes, vec);
								GetVectorAngles(vec, flAng);
								flAng[0] *= GetRandomFloat(-1.0, 1.0);
								flAng[1] += GetRandomFloat(-180.0, 180.0);
								ClampAngle(flAng);
							
								targetEyes[2] += 0;
								targetEyes[1] += 0;
							
								float desired_dir[3];
								MakeVectorFromPoints(flPos, flGoal, desired_dir);
								GetVectorAngles(desired_dir, desired_dir);

								flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
								flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;
							
								if(IsPointVisibleTank(targetEyes, flPos))
								{
									TF2_LookAtPos(client, targetEyes, 0.075);
									vel = moveForward(vel,300.0);
								}
							}
						}
					}
					
					if(GetCash(client) < 0)
					{
						SetCash(client, GetCash(client)+FakeCash);
					}
					
					while ((iEnt = FindEntityByClassname(iEnt, "item_currencypack_small")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							
							float clientOrigin2[3];
							GetClientAbsOrigin(client, clientOrigin2);
						
							float location_check[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", location_check);
							
							float chainDistance;
							chainDistance = GetVectorDistance(location_check,clientOrigin);
							
							if(chainDistance < 125.0)
							{
								vel = moveForward(vel,300.0);
							}

							if(chainDistance < 75.0)
							{
								clientOrigin2[2] -= 1000.0;
								TeleportEntity(iEnt, clientOrigin2, NULL_VECTOR, NULL_VECTOR);
								vel = moveForward(vel,300.0);
								AcceptEntityInput(iEnt, "Kill");
								for (int search = 1; search <= MaxClients; search++)
								{
									int redteam = GetClientTeam(search);
									if(!IsFakeClient(search) && IsPlayerAlive(search))
									{
										float Player[3];
										GetClientAbsOrigin(search, Player);
										TeleportEntity(iEnt, Player, NULL_VECTOR, NULL_VECTOR);
										SetCash(search, GetCash(search)+iCash);
									}
									else if(redteam == 2)
									{
										SetCash(search, GetCash(search)+iCash);
										AcceptEntityInput(iEnt, "Kill");
									}
								}
							}
						}
					}
					
					while ((iEnt2 = FindEntityByClassname(iEnt2, "item_currencypack_medium")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt2))
						{
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							
							float clientOrigin2[3];
							GetClientAbsOrigin(client, clientOrigin2);
						
							float location_check[3];
							GetEntPropVector(iEnt2, Prop_Send, "m_vecOrigin", location_check);
							
							float chainDistance;
							chainDistance = GetVectorDistance(location_check,clientOrigin);
							
							if(chainDistance < 125.0)
							{
								vel = moveForward(vel,300.0);
							}

							if(chainDistance < 75.0)
							{
								clientOrigin2[2] -= 1000.0;
								TeleportEntity(iEnt2, clientOrigin2, NULL_VECTOR, NULL_VECTOR);
								vel = moveForward(vel,300.0);
								AcceptEntityInput(iEnt2, "Kill");
								for (int search = 1; search <= MaxClients; search++)
								{
									int redteam = GetClientTeam(search);
									if(!IsFakeClient(search) && IsPlayerAlive(search))
									{
										float Player[3];
										GetClientAbsOrigin(search, Player);
										TeleportEntity(iEnt2, Player, NULL_VECTOR, NULL_VECTOR);
										SetCash(search, GetCash(search)+iCash2);
									}
									else if(redteam == 2)
									{
										SetCash(search, GetCash(search)+iCash2);
										AcceptEntityInput(iEnt2, "Kill");
									}
								}
							}
						}
					}
					
					while ((iEnt3 = FindEntityByClassname(iEnt3, "item_currencypack_large")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt3))
						{
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							
							float clientOrigin2[3];
							GetClientAbsOrigin(client, clientOrigin2);
						
							float location_check[3];
							GetEntPropVector(iEnt3, Prop_Send, "m_vecOrigin", location_check);
							
							float chainDistance;
							chainDistance = GetVectorDistance(location_check,clientOrigin);
							
							if(chainDistance < 125.0)
							{
								vel = moveForward(vel,300.0);
							}

							if(chainDistance < 75.0)
							{
								clientOrigin2[2] -= 1000.0;
								TeleportEntity(iEnt3, clientOrigin2, NULL_VECTOR, NULL_VECTOR);
								vel = moveForward(vel,300.0);
								AcceptEntityInput(iEnt3, "Kill");
								for (int search = 1; search <= MaxClients; search++)
								{
									int redteam = GetClientTeam(search);
									if(!IsFakeClient(search) && IsPlayerAlive(search))
									{
										float Player[3];
										GetClientAbsOrigin(search, Player);
										TeleportEntity(iEnt3, Player, NULL_VECTOR, NULL_VECTOR);
										SetCash(search, GetCash(search)+iCash3);
									}
									else if(redteam == 2)
									{
										SetCash(search, GetCash(search)+iCash3);
										AcceptEntityInput(iEnt3, "Kill");
									}
								}
							}
						}
					}
					
					while ((iEnt4 = FindEntityByClassname(iEnt4, "item_currencypack_custom")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt4))
						{
							//iCash4 = GetEntProp(iEnt4, Prop_Send, "m_nCurrencyAmount");
							
							float clientOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							
							float clientOrigin2[3];
							GetClientAbsOrigin(client, clientOrigin2);
						
							float location_check[3];
							GetEntPropVector(iEnt4, Prop_Send, "m_vecOrigin", location_check);
							
							float chainDistance;
							chainDistance = GetVectorDistance(location_check,clientOrigin);
							
							if(chainDistance < 125.0)
							{
								vel = moveForward(vel,300.0);
							}

							if(chainDistance < 75.0)
							{
								clientOrigin2[2] -= 1000.0;
								TeleportEntity(iEnt4, clientOrigin2, NULL_VECTOR, NULL_VECTOR);
								vel = moveForward(vel,300.0);
								AcceptEntityInput(iEnt4, "Kill");
								for (int search = 1; search <= MaxClients; search++)
								{
									if (IsValidClient(search))
									{
										int redteam = GetClientTeam(search);
										if(!IsFakeClient(search) && IsPlayerAlive(search))
										{
											float Player[3];
											GetClientAbsOrigin(search, Player);
											TeleportEntity(iEnt4, Player, NULL_VECTOR, NULL_VECTOR);
											SetCash(search, GetCash(search)+iCash4);
										}
										else if(redteam == 2)
										{
											SetCash(search, GetCash(search)+iCash4);
											AcceptEntityInput(iEnt4, "Kill");
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock void TF2_LookAtPos(int client, float flGoal[3], float flAimSpeed = 0.05)
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

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}  

stock float GetAngle(const float coords1[3], const float coords2[3])
{
	float angle = RadToDeg(ArcTangent((coords2[1] - coords1[1]) / (coords2[0] - coords1[0])));
	if (coords2[0] < coords1[0])
	{
		if (angle > 0.0) angle -= 180.0;
		else angle += 180.0;
	}
	return angle;
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
			if(TF2_IsPlayerInCondition(i, TFCond_Disguised) || TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
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

stock int GetClientEntityCount(int client, const char[] search)
{
    if (!IsValidClient(client))
    {
        return 0;
    }
    
    int count;
    char classname[64];
    for (int i = MaxClients; i < GetMaxEntities(); i++)
    {
        if (!IsValidEntity(i))
        {
            continue;
        }
        
        GetEntityClassname(i, classname, sizeof(classname));
        if (!StrEqual(search, classname))
        {
            continue;
        }
        
        int owner = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity");
        if (owner != client)
        {
            continue;
        }
        
        count++;
    }
    
    return count;
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

stock void SetCash(int client, int iAmount)
{
	if(iAmount < 0) iAmount = 0;
	SetEntProp(client, Prop_Send, "m_nCurrency", iAmount);
}

stock int GetCash(int client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

bool IsValidClient( int client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}