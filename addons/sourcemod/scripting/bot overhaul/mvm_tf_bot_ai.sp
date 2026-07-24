#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

float flag_pos[3];

public Plugin myinfo=
{
	name= "MvM Bots",
	author= "tRololo312312 Edit by EfeDursun125",
	description= "Allows Bots to play MvM",
	version= "1.4",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

public void OnPluginStart()
{
	HookEvent("mvm_begin_wave", RoundStarted);
	HookEvent("mvm_wave_complete", RoundStarted2);
	HookEvent("mvm_wave_failed", RoundStarted2);
}

public void OnMapStart()
{
	if(GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action RoundStarted2(Handle event , const char[] name, bool dontBroadcast)
{
	char nameflag[] = "redbotflag";
	char class[] = "item_teamflag";
	int ent = FindEntityByTargetname(nameflag, class);
	if(ent != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

public Action RoundStarted(Handle event , const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, LoadStuff);
}

public Action LoadStuff(Handle timer, any userid)
{
	int teamflags = CreateEntityByName("item_teamflag");
	if(IsValidEntity(teamflags))
	{
		DispatchKeyValue(teamflags, "targetname", "redbotflag");
		DispatchKeyValue(teamflags, "trail_effect", "0");
		DispatchKeyValue(teamflags, "ReturnTime", "1");
		DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
		DispatchSpawn(teamflags);
		SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
	}
	CreateTimer(0.5, LoadStuff2);
}

public Action LoadStuff2(Handle timer)
{
	//Changed to one of the Golden Rules(1.1)
	char name[] = "redbotflag";
	char class[] = "item_teamflag";
	int ent = FindEntityByTargetname(name, class);
	if(ent != -1)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
}

public Action OnFlagTouch(int point, int client)
{
	for(client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

//danke Forlix for dis stock :))
stock int FindEntityByTargetname(const char[] targetname, const char[] classname)
{
	char namebuf[32];
	int index = -1;
	namebuf[0] = '\0';

	while(strcmp(namebuf, targetname) != 0
	&& (index = FindEntityByClassname(index, classname)) != -1)
	GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));

	return(index);
}

public Action MoveTimer(Handle timer)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				int team = GetClientTeam(client);
				char name[] = "redbotflag";
				char class[] = "item_teamflag";
				int iEnt = -1;
				int ent = FindEntityByTargetname(name, class);
				if(ent != -1)
				{
					if((iEnt = FindEntityByClassname(iEnt, "tank_boss")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if(team == 3 && TFCond == TFCond_DefenseBuffNoCritBlock)
					{
						GetClientAbsOrigin(client, flag_pos);
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
					else if(team == 3 && GetHealth(client) > 450.0)
					{
						GetClientAbsOrigin(client, flag_pos);
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
					else if((iEnt = FindEntityByClassname(iEnt, "item_teamflag")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							if(GetEntProp(iEnt, Prop_Send, "m_iTeamNum") == 2)
							{
								float TankLoc[3];
								GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
								TankLoc[2] += 20.0;
								TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
					else if(team == 3)
					{
						GetClientAbsOrigin(client, flag_pos);
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
					else if((iEnt = FindEntityByClassname(iEnt, "item_currencypack_large")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if((iEnt = FindEntityByClassname(iEnt, "item_currencypack_medium")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if((iEnt = FindEntityByClassname(iEnt, "item_currencypack_custom")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if((iEnt = FindEntityByClassname(iEnt, "item_currencypack_small")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if((iEnt = FindEntityByClassname(iEnt, "func_capturezone")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
			}
		}
	}
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}