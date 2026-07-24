#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

float flag_pos[3];
float flag_pos2[3];
float flag_pos3[3];
float flag_pos4[3];
int Payload = 0;

public Plugin myinfo =
{
	name= "TFBots on PLR",
	author= "tRololo312312, edited by EfeDursun125",
	description= "Allows Bots to play Payload Race.",
	version= "1.2",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

public void OnMapStart()
{
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if ( StrContains( currentMap, "plr_" , false) != -1)
	{
		Payload = 1;
		HookEvent("teamplay_round_start", RoundStarted);
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.1, FindFlag,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{		
		Payload = 0;
		
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

public Action RoundStarted(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, LoadStuff);
	CreateTimer(0.1, LoadStuff2);
}

public Action LoadStuff(Handle timer)
{
	char nameblue[] = "bluebotflag";
	char classblue[] = "item_teamflag";
	int ent = FindEntityByTargetname(nameblue, classblue);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		int teamflags = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags))
		{
			DispatchKeyValue(teamflags, "targetname", "bluebotflag");
			DispatchKeyValue(teamflags, "trail_effect", "0");
			DispatchKeyValue(teamflags, "ReturnTime", "1");
			DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags);
			SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
		}
	}
}

public Action LoadStuff2(Handle timer)
{
	char namered[] = "redbotflag";
	char classred[] = "item_teamflag";
	int ent = FindEntityByTargetname(namered, classred);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		int teamflags2 = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags2))
		{
			DispatchKeyValue(teamflags2, "targetname", "redbotflag");
			DispatchKeyValue(teamflags2, "trail_effect", "0");
			DispatchKeyValue(teamflags2, "ReturnTime", "1");
			DispatchKeyValue(teamflags2, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags2);
			SetEntProp(teamflags2, Prop_Send, "m_iTeamNum", 2);
		}
	}
}

public Action FindFlag(Handle timer)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
}

public Action MoveTimer(Handle timer)
{
	char namered[] = "redbotflag";
	char classred[] = "item_teamflag";
	char nameblue[] = "bluebotflag";
	char classblue[] = "item_teamflag";
	int cartEnt2 = -1;
	int cartEnt = -1;
	int random = GetRandomInt(1,22);
	switch(random)
	{
		case 1:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 2:
		{
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent = FindEntityByTargetname(nameblue, classblue);
						int ent2 = FindEntityByTargetname(namered, classred);
						int team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos4);
								TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 3:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent2 = FindEntityByTargetname(namered, classred);
						int team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 4:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent = FindEntityByTargetname(nameblue, classblue);
						int team = GetClientTeam(client);
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos4);
								TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 5:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent2 = FindEntityByTargetname(namered, classred);
					if(ent2 != -1)
					{
						TeleportEntity(ent2, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 6:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent2 = FindEntityByTargetname(nameblue, classblue);
					if(ent2 != -1)
					{
						TeleportEntity(ent2, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 7:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 8:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 9:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 10:
		{
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent = FindEntityByTargetname(nameblue, classblue);
						int ent2 = FindEntityByTargetname(namered, classred);
						int team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 11:
		{
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent = FindEntityByTargetname(nameblue, classblue);
						int ent2 = FindEntityByTargetname(namered, classred);
						int team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 12:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 13:
		{
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent = FindEntityByTargetname(nameblue, classblue);
						int ent2 = FindEntityByTargetname(namered, classred);
						int team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos4);
								TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 14:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 15:
		{
			int ent = FindEntityByTargetname(nameblue, classblue);
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			for(int client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						int ent2 = FindEntityByTargetname(namered, classred);
						int team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 16:
		{
			int ent = FindEntityByTargetname(nameblue, classblue);
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "func_capturezone")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
				int ent = FindEntityByTargetname(namered, classred);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 17:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt = FindEntityByClassname(cartEnt, "func_capturezone")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos2);
				int ent = FindEntityByTargetname(namered, classred);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 18:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 19:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "item_healthkit_full")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
				int ent = FindEntityByTargetname(namered, classred);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 20:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "item_healthkit_full")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
				int ent = FindEntityByTargetname(nameblue, classblue);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 21:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					int ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 22:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					int ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
}

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
