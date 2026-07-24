#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

int multiplier;
int regencount;

Handle RegenTime;
Handle UpgradeTime;
Handle PowerupTime;

public Plugin myinfo=
{
	name = "MvM Fake Bot Upgrades",
	author = "EfeDursun125",
	description = "Allows Bots to play MvM",
	version = "1.0",
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public void OnPluginStart()
{
	HookEvent("mvm_wave_complete", FakeUpgrade);
	HookEvent("mvm_wave_failed", FakeUpgrade2);
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
	if(GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		multiplier == 1.1;
		regencount == 0;
	}
}

public void OnClientPutInServer(int iClient)
{
	if(GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		int team = GetClientTeam(iClient);
		if(team == 3)
		{
			SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action FakeUpgrade(Handle event, const char[] name, bool dontBroadcast)
{
	int upgradechance = GetRandomInt(1, 2);

	if(multiplier < 2.2 && upgradechance == 1)
	{
		multiplier += 0.2;
	}
	
	if(regencount < 10 && upgradechance == 2)
	{
		regencount += 2;
	}
}

public Action FakeUpgrade2(Handle event , const char[] name, bool dontBroadcast)
{
	if(multiplier > 1.2)
	{
		multiplier -= 0.2;
	}
	
	if(regencount > 3)
	{
		regencount -= 2;
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if(attacker > MAXPLAYERS || attacker < 0) {
		return Plugin_Continue;
	}

	if(multiplier == 1.0) {
		return Plugin_Continue;
	} else {
		damage *= multiplier;
		return Plugin_Changed;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	if(IsValidClient(client) && GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client) && GameRules_GetProp("m_bPlayingMannVsMachine"))
			{
				TFClassType class = TF2_GetPlayerClass(client);
				int iEnt = -1;
				int iEnt2 = -1;
				int iEnt3 = -1;
				int team = GetClientTeam(client);
				int CurrentHealth = GetClientHealth(client);
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));
				
				int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
				SetEntData(client, ammoOffset + 4, 300);
				
				if(RegenTime == INVALID_HANDLE)
				{
					RegenTime = CreateTimer(2.0, ResetRegenTime);
				}
				
				if(RegenTime == INVALID_HANDLE && CurrentHealth < MaxHealth)
				{
					SetEntityHealth(client, regencount);
				}
				
				if(PowerupTime == INVALID_HANDLE)
				{
					PowerupTime = CreateTimer(5.0, ResetPowerupTime);
				}
				
				if (StrContains(currentMap, "mvm_ghost_town" , false) != -1)
				{
					if(UpgradeTime == INVALID_HANDLE)
					{
						UpgradeTime = CreateTimer(30.0, ResetUpgradeTime);
					}
					if(UpgradeTime == INVALID_HANDLE)
					{
						int upgradechance = GetRandomInt(1, 2);

						if(multiplier < 2.2 && upgradechance == 1)
						{
							multiplier += 0.2;
						}
	
						if(regencount < 10 && upgradechance == 2)
						{
							regencount += 2;
						}
					}
					if((iEnt2 = FindEntityByClassname(iEnt2, "item_powerup_rune")) != INVALID_ENT_REFERENCE)
					{
						AcceptEntityInput(iEnt2, "Kill");
					}
					if((iEnt3 = FindEntityByClassname(iEnt3, "item_powerup_rune_temp")) != INVALID_ENT_REFERENCE)
					{
						AcceptEntityInput(iEnt3, "Kill");
					}
				}
				
				if(class != TFClass_Engineer && class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Medic && team == 2 && IsWeaponSlotActive(client, 0))
				{
					if((iEnt = FindEntityByClassname(iEnt, "tank_boss")) != INVALID_ENT_REFERENCE)
					{
						float clientOrigin[3];
						float fEntityLocation[3];
						GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntityLocation);
						GetClientAbsOrigin(client, clientOrigin);
				
						float chainDistance2;
						chainDistance2 = GetVectorDistance(clientOrigin, fEntityLocation);

						if(chainDistance2 < 1250.0 && buttons & IN_ATTACK)
						{
							if(PowerupTime == INVALID_HANDLE)
							{
								int chance = GetRandomInt(1, 5);
								if(chance == 1)
								{
									TF2_AddCondition(client, TFCond_HalloweenCritCandy, 5.0);
									PrintToChatAll("%N has used their CRIT BOOST Power Up Canteen!", client);
								}
							}
						}
					}
					else
					{
						for(int search = 1; search <= MaxClients; search++)
						{
							if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
							{
								float clientOrigin[3];
								float searchOrigin[3];
								GetClientAbsOrigin(search, searchOrigin);
								GetClientAbsOrigin(client, clientOrigin);

								float chainDistance2;
								chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

								if(chainDistance2 < 1250.0 && buttons & IN_ATTACK && GetHealth(search) > 1000.0)
								{
									if(PowerupTime == INVALID_HANDLE)
									{
										int chance = GetRandomInt(1, 10);
										if(chance == 1)
										{
											TF2_AddCondition(client, TFCond_HalloweenCritCandy, 5.0);
											PrintToChatAll("%N has used their CRIT BOOST Power Up Canteen!", client);
										}
										if(chance == 2)
										{
											TF2_AddCondition(client, TFCond_Ubercharged, 5.0);
											PrintToChatAll("%N has used their UBERCHARGE Power Up Canteen!", client);
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

public Action BotSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		int botid = GetClientOfUserId(GetEventInt(event, "userid"));
		//TFClassType class = TF2_GetPlayerClass(botid);
		int botteam = GetClientTeam(botid);
		char currentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(currentMap, sizeof(currentMap));
	
		if(IsFakeClient(botid))
		{
			if(IsPlayerAlive(botid))
			{
				if(botteam == 2 && GameRules_GetProp("m_bPlayingMannVsMachine"))
				{
					TF2_AddCondition(botid, TFCond_PreventDeath, TFCondDuration_Infinite);
					TF2_AddCondition(botid, TFCond_TmpDamageBonus, TFCondDuration_Infinite);
					TF2_AddCondition(botid, TFCond_DodgeChance, TFCondDuration_Infinite);
				}
				if (StrContains(currentMap, "mvm_ghost_town" , false) != -1 && botteam == 2)
				{
					int random = GetRandomInt(1,14);
					switch(random)
					{
						case 1:
						{
							FakeClientCommand(botid, "addcond 90");
						}
						case 2:
						{
							FakeClientCommand(botid, "addcond 91");
						}
						case 3:
						{
							FakeClientCommand(botid, "addcond 92");
						}
						case 4:
						{
							FakeClientCommand(botid, "addcond 93");
						}
						case 5:
						{
							FakeClientCommand(botid, "addcond 94");
						}
						case 6:
						{
							FakeClientCommand(botid, "addcond 95");
						}
						case 7:
						{
							FakeClientCommand(botid, "addcond 96");
						}
						case 8:
						{
							FakeClientCommand(botid, "addcond 97");
						}
						case 9:
						{
							FakeClientCommand(botid, "addcond 103");
						}
						case 10:
						{
							FakeClientCommand(botid, "addcond 107");
						}
						case 11:
						{
							FakeClientCommand(botid, "addcond 109");
						}
						case 12:
						{
							FakeClientCommand(botid, "addcond 110");
						}
						case 13:
						{
							FakeClientCommand(botid, "addcond 111");
						}
						case 14:
						{
							FakeClientCommand(botid, "addcond 113");
						}
					}
				}
			}
		}
	}
}

public Action ResetRegenTime(Handle timer)
{
	RegenTime = INVALID_HANDLE;
}

public Action ResetUpgradeTime(Handle timer)
{
	UpgradeTime = INVALID_HANDLE;
}

public Action ResetPowerupTime(Handle timer)
{
	PowerupTime = INVALID_HANDLE;
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

bool IsValidClient(int client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}