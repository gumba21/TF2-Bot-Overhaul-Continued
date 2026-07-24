#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.10"

bool g_bTouched[MAXPLAYERS+1];
bool g_bSuddenDeathMode;
bool g_bMVM;
bool g_bLateLoad;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
Handle g_hWeaponEquip;
Handle g_hWWeaponEquip;
Handle g_hGameConfig;

public Plugin myinfo = 
{
	name = "Give Bots Weapons",
	author = "luki1412 / Edited By Showin, Marqueritte",
	description = "Gives TF2 bots non-stock weapons",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if (GetEngineVersion() != Engine_TF2) 
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() 
{
	ConVar hCVversioncvar = CreateConVar("sm_gbw_version", PLUGIN_VERSION, "Give Bots Weapons version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbw_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbw_delay", "1", "Delay for giving weapons to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam = CreateConVar("sm_gbw_team", "1", "Team to give weapons to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	
	HookEvent("post_inventory_application", player_inv);
	HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	
	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Weapons");

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
	g_hGameConfig = LoadGameConfigFile("give.bots.weapons");
	
	if (!g_hGameConfig)
	{
		SetFailState("Failed to find give.bots.weapons.txt gamedata! Can't continue.");
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
		HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
		UnhookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	}
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		g_bMVM = true;
	}
}

public void OnClientDisconnect(int client)
{
	g_bTouched[client] = false;
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	int team = GetClientTeam(client);
	
	if (!g_bSuddenDeathMode && !g_bTouched[client] && !g_bMVM && IsPlayerHere(client) || team == 2 && !g_bSuddenDeathMode && !g_bTouched[client] && g_bMVM == true && IsPlayerHere(client))
	{
		g_bTouched[client] = true;
//		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam);
		float timer = GetConVarFloat(g_hCVTimer);
		
		switch (team2)
		{
			case 1:
			{
				CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
			}
			case 2:
			{
				if (team == 2)
				{
					CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 3:
			{
				if (team == 3)
				{
					CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	
		// Originally from bot_ai.
		// Showin moved easter egg here for optimization purposes.
		// If Bot's Name is Shrek then you're literally fucked.
		char botname[8];
		GetClientName(client, botname, sizeof(botname));
		if(StrEqual("Shrek", botname) || StrEqual("shrek", botname)) 
		{  
			TF2_AddCondition(client, TFCond_Kritzkrieged, TFCondDuration_Infinite);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
			TF2_AddCondition(client, TFCond_BalloonHead, TFCondDuration_Infinite);
			TF2_AddCondition(client, TFCond_BulletImmune, TFCondDuration_Infinite);
			TF2_AddCondition(client, TFCond_BlastImmune, TFCondDuration_Infinite);
			TF2_AddCondition(client, TFCond_FireImmune, TFCondDuration_Infinite);
		} 
	}
}

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;
	
	if (!GetConVarBool(g_hCVEnabled) || !IsPlayerHere(client))
	{
		return;
	}

	int team = GetClientTeam(client);
	int team2 = GetConVarInt(g_hCVTeam);
	
	switch (team2)
	{
		case 2:
		{
			if (team != 2)
			{
				return;
			}
		}
		case 3:
		{
			if (team != 3)
			{
				return;
			}
		}
	}

	if (!g_bSuddenDeathMode && !g_bMVM || !g_bSuddenDeathMode && g_bMVM == true && team == 2)
	{
		TFClassType class = TF2_GetPlayerClass(client);
		if (GameRules_GetProp("m_bPlayingMedieval") != 1)
		{
			switch (class)
			{
				case TFClass_Scout:
				{
					int rnd = GetRandomUInt(0,5);
					if(rnd == 0)
					{
						int rndskin = GetRandomUInt(0,25);
						switch (rndskin)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);							
								CreateWeapon(client, "tf_weapon_scattergun", 669); // Festive Scattergun
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 799); // Case 3 to 10 are botkilers
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 808);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 888);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 897);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 906);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 915);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 964);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 973);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 1078); // Festive FaN
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15002); // Skins down onwards
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15015);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15021);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15029);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15036);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15053);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15065);
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15069);
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15106);
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15107);
							}
							case 22:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15108);
							}
							case 23:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15131);
							}
							case 24:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15151);
							}
							case 25:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_scattergun", 15157); // The weapons are in this order https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes#Primary_.5BSlot_0.5D
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 0);
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 45);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_soda_popper", 448);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 772);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 1103);
						}
					}
					}
					int rnd2 = GetRandomUInt(0,6);
					if(rnd2 == 0)
					{	
						int rndskin2 = GetRandomUInt(0,18);
						switch (rndskin2)
						{
							case 1:
							{
								// Keep Stock Couldn't be bother to redo everything 
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 294); // Luger
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_jar_milk", 1121); // Mutated milk
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_lunchbox_drink", 1145); // Festive Bonk
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 30666); // Capper
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15013); // Case 7 to 19 Reskins
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15018);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15035);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15041);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15046);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15056);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15060);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15061);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15100);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15101);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15102);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15126);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pistol", 15148);
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 773, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_lunchbox_drink", 46, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_lunchbox_drink", 163, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_jar_milk", 222, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_cleaver", 812, 10);
						}
					}
					}
					int rnd3 = GetRandomUInt(0,6);
					if(rnd3 == 0)
					{
						int rndskin3 = GetRandomUInt(0,5);
						switch (rndskin3)
						{
							case 1:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bat", 452); // Three Runed Blade
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bat_fish", 572); // Unarmed Combat
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bat", 660); // Festive Bat
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bat", 30667); // Bat Saber
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bat_fish", 999); // Festive Mackrel
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat_wood", 44, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 221, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 317, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bat", 349, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bat", 355, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bat_giftwrap", 648, 10);
						}			
					}
					}
				}
				case TFClass_Sniper:
				{
					int rnd = GetRandomUInt(0,6);
					if(rnd == 0)
					{
						int rndskin = GetRandomUInt(0,29);
						switch (rndskin)
						{
							case 1:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 664); // Festive Sniper Rifle
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 851); // AWPer Hand
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_compound_bow", 1005); // Festive Bow
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_compound_bow", 1092); // Compound Bow
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 792); // Bot Killers
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 801);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 881);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 890);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 899);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 908);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 957);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 966);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15000); // Reskins
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15007);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15019);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15023);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15033);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15059);
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15070);
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15071);
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15072);
							}
							case 22:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15070);
							}
							
							case 23:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15111);
							}
							case 24:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15112);
							}
							case 25:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15135);
							}
							case 26:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15136);
							}
							case 27:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 15154);
							}
							case 28:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_sniperrifle", 30665); // Shooting Star
							}
							case 29:
							{
								// Stock
							}
						}
					
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 0);
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 56, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 230, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 526, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 752, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_classic", 1098, 10);
						}	
					}
					}
					int rnd2 = GetRandomUInt(0,5);
					if(rnd2 == 0)
					{	
						int rndskin2 = GetRandomUInt(0,13);
						switch (rndskin2)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_jar", 1083); // festive jarate
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_jar", 1105); // self-aware jar
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 1149); // festive smg
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15153); // Reskins
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15001);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15022);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15032);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15037);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15058);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15076);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15110);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_smg", 15134);
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_smg", 751, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_jar", 58, 10);
						}
						case 3:
						{
							CreateWWeapon(client, "tf_wearable", 57);
						}
						case 4:
						{
							CreateWWeapon(client, "tf_wearable", 231);
						}
						case 5:
						{
							CreateWWeapon(client, "tf_wearable", 642);
						}
					}
					}
					int rnd3 = GetRandomUInt(0,3);
					if(rnd3 != 0)
					{	
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 171, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 232, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_club", 401, 10);
						}
					}
					}
				}
				case TFClass_Soldier:
				{
					int rnd = GetRandomUInt(0,6);
					if(rnd == 0)
					{
						int rndskin = GetRandomUInt(0,24);
						switch (rndskin)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 658); // Festive RL
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 1085); // Festive Black Box
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 800); // Bot Killers
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 809);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 889);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 898);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 907);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 916);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 965);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 974);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15006); // Reskins
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15014);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15028);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15043);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15052);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15057);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15081);
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15104);
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15105);
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15130);
							}
							case 23:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15150);
							}
							case 24:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_rocketlauncher", 15129);
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 0);
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_directhit", 127);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 228);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 414);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_particle_cannon", 441, 30);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 513);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104);
						}	
						//case 7:
						//{
							//CreateWeapon(client, "tf_weapon_rocketlauncher", 730);
						//}											
					}
					}
					int rnd2 = GetRandomUInt(0,9);
					if(rnd2 == 0)
					{
						int rndskin2 = GetRandomUInt(0,12);
						switch (rndskin2)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_buff_item", 1001); // Festive Banner
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 1141); // Festive Shotgun
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15003); // Reskins
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15016);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15044);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15047);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15085);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15109);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15132);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15133);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 15152);
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_raygun", 442, 30);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shotgun_soldier", 415);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 129);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 226);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 354);
						}
						case 7:
						{
							CreateWWeapon(client, "tf_wearable", 133);
						}
						case 8:
						{
							CreateWWeapon(client, "tf_wearable", 444);
						}
						case 9:
						{
							CreateWWeapon(client, "tf_weapon_parachute", 1101);
						}
					}
					}
					int rnd3 = GetRandomUInt(0,5);
					if(rnd3 != 0)
					{	
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 128, 10);
						}
						case 2:
						{
							char currentMap[PLATFORM_MAX_PATH];
							GetCurrentMap(currentMap, sizeof(currentMap));
							if ( StrContains( currentMap, "koth_" , false) != -1 || StrContains( currentMap, "cp_" , false) != -1)
							{
							CreateWeapon(client, "tf_weapon_shovel", 154, 10);
							}
							else
							{
							// Keep Stock Weapons
							}
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shovel", 447, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shovel", 775, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_katana", 357, 10);
						}	
					}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(0,1);
					if(rnd == 0)
					{
						int rndskin = GetRandomUInt(0,10);
						switch (rndskin)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1007); // Festive GL
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15077); // Reskins
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15079);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15091);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15092);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15116);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15117);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15142);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 15158);
							}
						}
					}
					if(rnd == 1)
					{
						int rndchance = GetRandomUInt(0,15);
						switch (rndchance)
						{
							case 1:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWWeapon(client, "tf_wearable", 405);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWWeapon(client, "tf_wearable", 608);
							}
						}
					}
					
					int rnd2 = GetRandomUInt(0,1);
					if(rnd2 == 0)
					{	
						int rndskin2 = GetRandomUInt(0,24);
						switch (rndskin2)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15155); // reskin 
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 661); // Festive Stickybomb
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 797); // BotKillers
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 806);
							}
							
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 886);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 895);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 904);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 913);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 962);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 971);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15009); // Reskins
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15012);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15024);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15038);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15045);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15048);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15082);
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15083);
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15084);
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15113);
							}
							case 22:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15137);
							}
							case 23:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 15138);
							}
						}
					}
					if(rnd2 == 1)
					{	
						int rndchance2 = GetRandomUInt(0,14);
						switch (rndchance2)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 10);
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 10);
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 10);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 10);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 10);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 10);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 10);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 10);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 10);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 10);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWWeapon(client, "tf_wearable_demoshield", 131, 10);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWWeapon(client, "tf_wearable_demoshield", 406, 10);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWWeapon(client, "tf_wearable_demoshield", 1099, 10);
							}
						}
					}	
					
					int rnd3 = GetRandomUInt(0,7);
					if(rnd3 != 0)
					{
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 132, 10);
						}
						case 2:
						{
							char currentMap[PLATFORM_MAX_PATH];
							GetCurrentMap(currentMap, sizeof(currentMap));
							if ( StrContains( currentMap, "koth_" , false) != -1 || StrContains( currentMap, "cp_" , false) != -1)
							{
							CreateWeapon(client, "tf_weapon_shovel", 154, 10);
							}
							else
							{
							// Keep Stock Weapons
							}
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 172, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_stickbomb", 307, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 327, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_katana", 357, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_sword", 482, 10);
						}
					}				
					}
				}
				case TFClass_Medic:
				{
					int rnd = GetRandomUInt(0,4);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_crossbow", 305, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 412, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_crossbow", 1079, 15);
						}
					}
					
					//if(GetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_flChargeLevel") >= 25.00)
					// {
					int rnd2 = GetRandomUInt(0,5);
					if(rnd2 == 0)
					{	
						int rndskin2 = GetRandomUInt(0,21);
						switch (rndskin2)
						{
							case 1:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 663); // Festive Medigun
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 796); // Bot Killers
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 805);
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 885);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 894);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 903);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 912);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 961);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 970);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15010); // reskins
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15025);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15039);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15050);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15078);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15097);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15121);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15122);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15123);
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15145);
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_medigun", 15146);
							}
							case 21:
							{
								// Nothing
							}
						}	
					}					
					else
					{
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_medigun", 29, 8);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_medigun", 29, 8);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_medigun", 35, 8);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_medigun", 411, 8);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_medigun", 998, 8);
						}
					}
					}
					//}
					
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 == 0)
					{
						int rndskin3 = GetRandomUInt(0,3);
						switch (rndskin3)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bonesaw", 1143); // festive bonesaw
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_bonesaw", 1003); // festive ubersaw
							}
						}
					}
					else
					{
						TF2_RemoveWeaponSlot(client, 2);
						switch (rnd3)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 37, 10);
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 173, 5);
							}
							case 3:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 304, 15);
							}
							case 4:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 413, 10);
							}
						}
					}					
				}
				case TFClass_Heavy:
				{
					int rnd = GetRandomUInt(0,8);
					if(rnd == 0 || rnd == 1 || rnd == 2)
					{
						int rndskin = GetRandomUInt(0,23);
						switch (rndskin)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 654); // Festive Minigun 
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 882); // Bot Killers
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 891);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 900);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 909);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 958);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 967);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15004); // Reskins
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15020);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15026);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15031);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15040);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15055);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15086);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15087);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15088);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15098);
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15099);
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15123);
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15124);
							}
							case 22:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15125);
							}
							case 23:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_minigun", 15147);
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 0);
					switch (rnd)
					{
						case 3:
						{
							CreateWeapon(client, "tf_weapon_minigun", 424, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_minigun", 424, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_minigun", 424, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_minigun", 312, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_minigun", 811, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_minigun", 41, 10);
						}
					}
					}
					
					int rnd2 = GetRandomUInt(0,2);
					if(rnd2 == 0)
					{
						int rndskin2 = GetRandomUInt(0,11);
						switch (rndskin2)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 1141); // Festive Shotgun
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15152); // Reskins
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15003);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15016);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15044);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15047);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15085);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15109);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15132);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 15133);
							}
						}
					}
					else
					{
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 425);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153);
						}						
					}
					}
					
					int rnd3 = GetRandomUInt(0,6);
					if(rnd3 == 0)
					{
						int rndskin3 = GetRandomUInt(0,4);
						switch (rndskin3)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_fists", 587); // Apoco Fist
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_fists", 1084); // Festive GRU
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_fists", 1100); // BreadBite
							}
						}
					}					
					else
					{
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 43, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 239, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 310, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fists", 331, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fists", 426, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fists", 656, 10);
						}
					}					
					}
				}
				case TFClass_Pyro:
				{
					int rnd = GetRandomUInt(0,5);
					if(rnd == 0)
					{
						int rndskin = GetRandomUInt(0,25);
						switch (rndskin)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 659); // Festive FlameThrower
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 798); // Bot Killers
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 807);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 887);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 896);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 905);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 914); 
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 963); 
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 972); 
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 1146); // Festive Back Burner
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15005); // Reskins
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15017); 
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15030); 
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15034); 
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15049); 
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15054); 
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15066); 
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15067); 
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15068); 
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15089); 
							}
							case 22:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15090); 
							}
							case 23:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15115); 
							}
							case 24:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 15141); 
							}
							case 25:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_flamethrower", 30474);  // Napalmer
							}
						}	
					}					
					else
					{
					TF2_RemoveWeaponSlot(client, 0);
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 40, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 215, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 594, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 741, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_fireball", 1178, 10);
						}
					}
					}
					
					int rnd2 = GetRandomUInt(0,7);
					if(rnd2 == 0)
					{
						int rndskin2 = GetRandomUInt(0,12);
						switch (rndskin2)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 1141); // Festive Shotgun
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_flaregun", 1081); // Festive Flare Gun
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15003); // Reskins
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15016);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15044);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15047);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15085);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15109);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15132);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15133);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 1);
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 15152);
							}
						}	
					}					
					else
					{
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 39);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 351);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_flaregun_revenge", 595, 30);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 740);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_shotgun_pyro", 415);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_jar_gas", 1180);
						}
					}
					}
					
					int rnd3 = GetRandomUInt(0,10);
					if(rnd3 != 0)
					{
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 38, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 153, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 214, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 326, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 348, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 593, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 813, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 457, 10);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 739, 10);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_slap", 1181, 10);
						}							
					}
					}					
				}
				case TFClass_Spy:
				{
					int rnd = GetRandomUInt(0,4);
					if(rnd == 0)
					{
						int rndskin = GetRandomUInt(0,15);
						switch (rndskin)
						{
							case 1:
							{
								// Do Nothing keep stock.
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15011); // Reskins
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15027);
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15042);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15051);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15062); 
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15063); 
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15064); 
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15103);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15128);
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15129); 
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 15149);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 1006); // Festive Ambassdor
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 161); // Big Kill
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 0);
								CreateWeapon(client, "tf_weapon_revolver", 1142); // Festive Revolver
							}
							
						}						
					}
					TF2_RemoveWeaponSlot(client, 0);
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_revolver", 61, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_revolver", 224, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_revolver", 460, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_revolver", 525, 5);
						}					
					}
					
					int rnd2 = GetRandomUInt(0,1);
					if(rnd2 == 0)
					{
						// Do nothing.
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sapper", 810);
						}
					}
					
					
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 == 0)
					{
						int rndskin3 = GetRandomUInt(0,21);
						switch (rndskin3)
						{
							case 1:
							{
								// Keep Stock
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 794); // Bot Killer
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 803);
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 883);
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 892);
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 901);
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 910);
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 959);
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 968);
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15062); // Reskins
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15094);
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15095);
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15096);
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15118);
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15119);
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15143);
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 15144);
							}
							case 18:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 638); // Sharp Dresser
							}
							case 19:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 665); // Festive knife
							}
							case 20:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 727); // Black Rose
							}
							case 21:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_knife", 574); // Wanga Prick
							}
						}	
					}					
					else
					{
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 356, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 461, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 649, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 225, 10);
						}
					}
					}
					
					int rnd4 = GetRandomUInt(0,3);
					if(rnd4 != 0)
					{
						TF2_RemoveWeaponSlot(client, 4);
					}
					switch (rnd4)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_invis", 947);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_invis", 297);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_invis", 30);
						}
					}
					}
					case TFClass_Engineer:
					{
						int rnd = GetRandomUInt(0,4);
						if(rnd == 0)
						{
							int rndskin = GetRandomUInt(0,12);
							switch (rndskin)
							{
								case 1:
								{
									// Do Nothing keep stock.
								}
								case 2:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 1141); // Festive Shotgun
								}
								case 3:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15003); // Reskins
								}
								case 4:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15016);
								}
								case 5:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15044);
								}
								case 6:
								{
									TF2_RemoveWeaponSlot(client, 1);
									CreateWeapon(client, "tf_weapon_shotgun", 15047);
								}
								case 7:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15085);
								}
								case 8:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15109);
								}
								case 9:
								{
									TF2_RemoveWeaponSlot(client, 1);
									CreateWeapon(client, "tf_weapon_shotgun", 15132);
								}
								case 10:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15133);
								}
								case 11:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_shotgun", 15152);
								}
								case 12:
								{
									TF2_RemoveWeaponSlot(client, 0);
									CreateWeapon(client, "tf_weapon_sentry_revenge", 1004); // Festive Frontier Justice
								}
							}
						}
						else
						{
							TF2_RemoveWeaponSlot(client, 0);
							switch (rnd)
							{
								case 1:
								{
									CreateWeapon(client, "tf_weapon_sentry_revenge", 141, 5);
								}
								case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997);
								}
								case 3:
								{
									CreateWeapon(client, "tf_weapon_drg_pomson", 588, 10);
								}
								case 4:
								{
									CreateWeapon(client, "tf_weapon_shotgun_primary", 1153);
								}						
							}
						}

						int rnd2 = GetRandomUInt(0,15);
						if(rnd2 != 0)
						{
							TF2_RemoveWeaponSlot(client, 1);
						}
						switch (rnd2)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_pistol", 30666); // Capper
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15013); // Case 7 to 19 Reskins
							}
							case 3:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15018);
							}
							case 4:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15035);
							}
							case 5:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15041);
							}
							case 6:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15046);
							}
							case 7:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15056);
							}
							case 8:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15060);
							}
							case 9:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15061);
							}
							case 10:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15100);
							}
							case 11:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15101);
							}
							case 12:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15102);
							}
							case 13:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15126);
							}
							case 14:
							{
								CreateWeapon(client, "tf_weapon_pistol", 15148);
							}
							case 15:
							{
								CreateWeapon(client, "tf_weapon_pistol", 22);
							}
						}	
							
						// Fix engineer shooting sentry bugs. Have a small delay then switch weapons.
						CreateTimer(3.0, EngineerFix,client, TIMER_FLAG_NO_MAPCHANGE);
					}
			}
			
			// Check for tpose issues. (civilian mode)
			CreateTimer(2.0, TposeFix, client, TIMER_FLAG_NO_MAPCHANGE);
			
		}
		else
		{
			switch (class)
			{
				case TFClass_Scout:
				{
					int rnd3 = GetRandomUInt(0,7);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat_wood", 44, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 572, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 317, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bat", 349, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bat", 355, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bat_giftwrap", 648, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bat", 450, 10);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd2 = GetRandomUInt(0,3);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable", 57);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable", 231);
						}
						case 3:
						{
							CreateWWeapon(client, "tf_wearable", 642);
						}
					}
					
					int rnd3 = GetRandomUInt(0,3);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 171, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 232, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_club", 401, 10);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd2 = GetRandomUInt(0,2);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable", 133);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable", 444);
						}
					}
					
					int rnd3 = GetRandomUInt(0,5);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 128, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 154, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shovel", 447, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shovel", 775, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_katana", 357, 10);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(0,2);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable", 405);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable", 608);
						}
					}				

					int rnd2 = GetRandomUInt(0,3);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable_demoshield", 131);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable_demoshield", 406);
						}
						case 3:
						{
							CreateWWeapon(client, "tf_wearable_demoshield", 1099);
						}
					}				
				
					int rnd3 = GetRandomUInt(0,8);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 132, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 154, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 172, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_stickbomb", 307, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 327, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_katana", 357, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_sword", 482, 10);
						}
						case 8:
						{						
							CreateWeapon(client, "tf_weapon_sword", 404, 10);							
						}
					}
				}
				case TFClass_Medic:
				{
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 37, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 173, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 304, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 413, 10);
						}
					}			
				}
				case TFClass_Heavy:
				{
					int rnd3 = GetRandomUInt(0,6);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 43, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 239, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 310, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fists", 331, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fists", 426, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fists", 656, 10);
						}
					}						
				}
				case TFClass_Pyro:
				{
					int rnd3 = GetRandomUInt(0,10);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 38, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 153, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 214, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 326, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 348, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 593, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 813, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 457, 10);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 739, 10);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_slap", 1181, 10);
						}					
					}			
				}
				case TFClass_Spy:
				{
					int rnd3 = GetRandomUInt(0,5);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 356, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 461, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 649, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 638, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_knife", 225, 10);
						}
					}
					int rnd4 = GetRandomUInt(0,1);
					if(rnd4 != 0)
					{
						TF2_RemoveWeaponSlot(client, 4);
					}
					switch (rnd4)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_invis", 947);
						}
					}					
				}
				case TFClass_Engineer:
				{
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 155, 20);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 329, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 589, 20);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_robot_arm", 142, 15);
						}					
					}	
				}
			}
			
			// Check for tpose issues. (civilian mode)
			CreateTimer(2.0, TposeFix, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void EventSuddenDeath(Handle event, const char[] name, bool dontBroadcast)
{
	g_bSuddenDeathMode = true;
}

public void EventRoundReset(Handle event, const char[] name, bool dontBroadcast)
{
	g_bSuddenDeathMode = false;
}

bool CreateWeapon(int client, char[] classname, int itemindex, int level = 0)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);

	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	switch (itemindex)
	{
		case 810:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
		}
		case 998:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomUInt(0,2));
		}
	}
	
	DispatchSpawn(weapon);
	SDKCall(g_hWeaponEquip, client, weapon);
	return true;
} 

bool CreateWWeapon(int client, char[] classname, int itemindex, int level = 0)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);

	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}	
	
	DispatchSpawn(weapon);
	SDKCall(g_hWWeaponEquip, client, weapon);
	CreateTimer(0.1, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	return true;
}

public Action TimerHealth(Handle timer, any client)
{
	int hp = GetPlayerMaxHp(client);
	
	if (hp > 0)
	{
		SetEntityHealth(client, hp);
	}
}

int GetPlayerMaxHp(int client)
{
	if (!IsClientConnected(client))
	{
		return -1;
	}

	int entity = GetPlayerResourceEntity();

	if (entity == -1)
	{
		return -1;
	}

	return GetEntProp(entity, Prop_Send, "m_iMaxHealth", _, client);
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

// Showin added this from bot_ai to fix issues with removing weapons causing tposing and shit
stock void TF2_SwitchtoSlot(int client, int slot)
{
 if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
 {
  char playername[32];
  GetClientName(client, playername, sizeof(playername));
  int wep = GetPlayerWeaponSlot(client, slot);
  if (wep > MaxClients && IsValidEdict(wep))
  {
	// Showin added a new way to force weapon switching!
	// We temporarily unrestrict this command to force a change and use the weapon switch blocker to force it. 
	int flags = GetCommandFlags( "cc_bot_selectweapon" );
	SetCommandFlags( "cc_bot_selectweapon", flags & ~FCVAR_CHEAT ); 
	FakeClientCommand(client, "cc_bot_selectweapon \"%s\" %i", playername, slot);
	SetCommandFlags( "cc_bot_selectweapon", flags|FCVAR_CHEAT);
  }
 }
}  

public Action TposeFix(Handle timer, any client)
{
	// Civilian Fixer (tpose) Sometimes bots fuck out and we gotta do something about it.
	int clientweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(clientweapon) && clientweapon == -1) 
	{
		// Simply try switching to every weapon available until we're good.
		TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
		TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
		TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
			
		// If we're still fucked try brute forcing it.
		if (clientweapon == -1)
		{
			int melee = GetPlayerWeaponSlot(client, 2);
				
			if(IsValidEntity(melee))
			{
				// Force melee!
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
			}
			else
			{
				TFClassType class = TF2_GetPlayerClass(client);
				switch (class)
				{
					case TFClass_Scout:
					{	
						CreateWeapon(client, "tf_weapon_bat", 0);
					}
					case TFClass_Sniper:
					{	
						CreateWeapon(client, "tf_weapon_club", 3);
					}
					case TFClass_Soldier:
					{	
						CreateWeapon(client, "tf_weapon_shovel", 6);
					}
					case TFClass_DemoMan:
					{	
						CreateWeapon(client, "tf_weapon_bottle", 1);
					}
					case TFClass_Medic:
					{	
						CreateWeapon(client, "tf_weapon_bonesaw", 8);
					}
					case TFClass_Heavy:
					{	
						CreateWeapon(client, "tf_weapon_fists", 5);
					}
					case TFClass_Pyro:
					{	
						CreateWeapon(client, "tf_weapon_fireaxe", 2);
					}
					case TFClass_Spy:
					{	
						CreateWeapon(client, "tf_weapon_knife", 4);
					}
					case TFClass_Engineer:
					{	
						CreateWeapon(client, "tf_weapon_wrench", 7);
					}
				}
				
				CreateTimer(2.0, TposeFix2, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action TposeFix2(Handle timer, any client)
{
	// Civilian Fixer (tpose) Sometimes bots fuck out and we gotta do something about it.
	if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == -1) 
	{
		// Now that a melee had a second chance to get added lets try again!
		TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
	}
}

public Action EngineerFix(Handle timer, int client)
{
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 == 0)
					{
						int rndskin3 = GetRandomUInt(0,17);
						switch (rndskin3)
						{
							case 1:
							{
								// He might spawn without a wrench if we don't force one on him.
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 7);
							}
							case 2:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 662); // Festive Wrench
							}
							case 3:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 795); // Bot killer
							}
							case 4:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 804); 
							}
							case 5:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 884); 
							}
							case 6:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 893); 
							}
							case 7:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 902); 
							}
							case 8:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 911); 
							}
							case 9:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 960); 
							}
							case 10:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 969); 
							}
							case 11:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15073); // Reskins
							}
							case 12:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15074); 
							}
							case 13:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15075); 
							}
							case 14:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15139); 
							}
							case 15:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15140); 
							}
							case 16:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15114); 
							}
							case 17:
							{
								TF2_RemoveWeaponSlot(client, 2);
								CreateWeapon(client, "tf_weapon_wrench", 15156); 
							}
						}	
					}					
					else
					{
					TF2_RemoveWeaponSlot(client, 2);
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 155, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 329, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 589, 10);
						}
						case 4:
						{
							char currentMap[PLATFORM_MAX_PATH];
							GetCurrentMap(currentMap, sizeof(currentMap));
							if ( StrContains( currentMap, "koth_" , false) != -1)
							{
								CreateWeapon(client, "tf_weapon_wrench", 142, 10);
							}
							else
							{
								// He might spawn without a wrench if we don't force one on him.
								CreateWeapon(client, "tf_weapon_wrench", 7);
							}
						}								
					}
				}
				//	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
				//	TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
				//	TF2_RemoveCondition(client, TFCond_MeleeOnly);
}