#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

int g_bIsSetupTime = 0;
int Payload = 0;

public Plugin myinfo = 
{
	name = "Bot Setup Time Fun",
	author = "tRololo312312 / luki1412 / Showin",
	description = "nope",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198039186809"
}

public void OnMapStart()
{
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if ( StrContains( currentMap, "pl_" , false) != -1 || StrContains( currentMap, "cp_dustbowl" , false) != -1 || StrContains( currentMap, "cp_egypt_final" , false) != -1 || StrContains( currentMap, "cp_gorge" , false) != -1 || StrContains( currentMap, "cp_gravelpit" , false) != -1 || StrContains( currentMap, "cp_junction_final" , false) != -1 || StrContains( currentMap, "cp_mountainlab" , false) != -1 || StrContains( currentMap, "cp_steel" , false) != -1 || StrContains( currentMap, "cp_mercenarypark" , false) != -1 || StrContains( currentMap, "cp_snowplow" , false) != -1 || StrContains( currentMap, "cp_mossrock" , false) != -1)
	{
		Payload = 1;

	}
	else
	{		
		Payload = 0;
		
	}
}

float moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

float moveBackwards(float vel[3], float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", SetupStarted);
	HookEvent("teamplay_setup_finished", RoundStarted);
}

public Action RoundStarted(Handle event , const char[] name, bool dontBroadcast)
{
	g_bIsSetupTime = 0;
}

public Action SetupStarted(Handle event,const char[] name, bool dontBroadcast)
{
	g_bIsSetupTime = 1;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(Payload == 1)
	{
		if(IsValidClient(client))
		{
			if(IsFakeClient(client))
			{
				if(IsPlayerAlive(client))
				{
					TFClassType class = TF2_GetPlayerClass(client);
					int team = GetClientTeam(client);
					
					if(g_bIsSetupTime == 1)
					{
						if(team == 3)
						{
							if(class != TFClass_Spy && class != TFClass_Medic && class != TFClass_Sniper && class != TFClass_Engineer)
							{
								vel = moveForward(vel,400.0);
							}
						}
						
						// This will make red not go too close to the blue players and die instantly!
						if(team == 2)
						{
							if(class != TFClass_Spy && class != TFClass_Medic && class != TFClass_Sniper && class != TFClass_Engineer)
							{
								for (int search = 1; search <= MaxClients; search++)
								{
									if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
									{
										float clientOrigin[3];
										float searchOrigin[3];
										GetClientAbsOrigin(search, searchOrigin);
										GetClientAbsOrigin(client, clientOrigin);
										float chainDistance2;
										chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);
										
										if(chainDistance2 < 500.0)
										{
											vel = moveBackwards(vel,400.0);
										}
									}
								}
							}
							
							if(class == TFClass_DemoMan)
							{
								if(buttons & IN_ATTACK2)
								{
									buttons &= ~IN_ATTACK2;
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

bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

public bool Filter(int entity, int mask)
{
	return !(IsValidClient(entity));
}