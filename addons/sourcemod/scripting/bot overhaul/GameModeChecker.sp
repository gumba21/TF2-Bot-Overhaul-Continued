#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "Gamemode Checker",
	author = "Showin",
	description = "stuff",
	version = "1.0",
	url = "shrek.com"
}

int MISSION;
int intro_blocked = 0;
int intro_video = 0;

Handle cvarListenServer;
Handle cvarMissionTeam;
Handle cvarMissionClass;
Handle cvarMissionBegin;

public void OnPluginStart()
{
	cvarListenServer = CreateConVar("sm_botoverhaul_listenserver", "0", "This is set to 1 if the bot overhaul detects that this is a listen server.");
	cvarMissionTeam = CreateConVar("sm_botoverhaul_mission_team", "0", "This is set automatically to ensure the player is on the correct mission team. 0 - No Team / 1 - Blue Team / 2 - Red Team");
	cvarMissionClass = CreateConVar("sm_botoverhaul_mission_class", "0", "This is set automatically to ensure the player is the correct mission class. 0-9 scout-spy in normal class order");
	cvarMissionBegin = CreateConVar("sm_botoverhaul_mission_begin", "0", "This is set to 1 briefly after the player spawns to ensure they don't die instantly due to tf2 bugginess.");
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", PlayerDied, EventHookMode_Post);
	HookEvent("teamplay_round_win", TEAMWIN, EventHookMode_Post);
	
	HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook, true);
	HookUserMessage(GetUserMessageId("VGUIMenu"), OnVGUIMenu, true);
}

public void OnMapStart()
{
	if (GetConVarInt(FindConVar("sv_bonus_challenge")) == 1)
	{
		if (MISSION != 1)
		{
			MISSION = 1;
		}
	}
	MapCheck();
}

void MapCheck()
{
	if (MISSION == 1)
	{
		ServerCommand("exec MISSION.cfg");
	}
	else
	{	
		if ( GetConVarInt(FindConVar("tf_gamemode_payload")) == 1 )
		{
			char currentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(currentMap, sizeof(currentMap));
			if ( StrContains( currentMap, "plr_" , false) != -1 )
			{
				ServerCommand("exec PayloadRace.cfg");
			}
			else
			{
				ServerCommand("exec Payload.cfg");
			}
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_cp")) == 1 || GetConVarInt(FindConVar("tf_gamemode_tc")) == 1)
		{
			// tf_attack_defend_map could be used to detect those if needed.
			char currentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(currentMap, sizeof(currentMap));
			if ( StrContains( currentMap, "koth_lakeside_event" , false) != -1 || StrContains( currentMap, "koth_viaduct_event" , false) != -1)
			{
				ServerCommand("exec HalloweenTruce.cfg; wait 66; exec Koth.cfg");
			}
			else if ( StrContains( currentMap, "koth_" , false) != -1 )
			{
				ServerCommand("exec Koth.cfg");
			}
			else
			{
				ServerCommand("exec ControlPoints.cfg");
			}
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_ctf")) == 1 )
		{
			ServerCommand("exec CaptureTheFlag.cfg");
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_mvm")) == 1 )
		{
			ServerCommand("exec MVM.cfg");
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_pd")) == 1 )
		{
			ServerCommand("exec PlayerDestruction.cfg");
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_rd")) == 1 )
		{
			ServerCommand("exec RobotDestruction.cfg");
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_sd")) == 1 )
		{
			ServerCommand("exec SpecialDelivery.cfg");
		}
		else if ( GetConVarInt(FindConVar("tf_gamemode_arena")) == 1 )
		{
			ServerCommand("exec Arena.cfg"); 
		}
	}
}

public Action UserMessageHook(UserMsg msg_hd, BfRead bf, const int[] players, int playersNum, bool reliable, bool init) 
{
	if (MISSION == 1)
	{
		// Thanks JoinedSenses for the example.
		// Hide bot name changes. (for the commander boss for example)
		char sMessage[96];
		bf.ReadString(sMessage, sizeof(sMessage)); // This needs to be here twice for some reason.
		bf.ReadString(sMessage, sizeof(sMessage));
		if (StrContains(sMessage, "Name_Change") != -1) 
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action OnVGUIMenu(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	// Thanks to joao7yt for help with this.
	if (MISSION == 1 && intro_blocked == 0)
	{
		int client = players[0];
		char sMessage[10];
		bf.ReadString(sMessage, sizeof(sMessage));
		
		if(!IsFakeClient(client))
		{
			if (StrEqual(sMessage, "team", true) || StrEqual(sMessage, "class_blue", true) || StrEqual(sMessage, "class_red", true))
			{
				intro_blocked = 1;
				char currentMap[256];
				GetCurrentMap(currentMap, 256);
				ServerCommand("exec missions/%s/start_mission.cfg", currentMap);
				
				// Remove menus a few times to ensure it works.
				// Sometimes this can be buggy otherwise.
				CreateTimer(0.1, STOPVGUI,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, STOPVGUI,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(2.0, STOPVGUI,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, STOPVGUI,client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (intro_video == 0)
			{
				char currentMap[256];
				GetCurrentMap(currentMap, 256);
				ServerCommand("exec missions/%s/intro.cfg", currentMap);
				intro_video = 1;
			}
		}
	}
	return Plugin_Continue;
}  

public Action STOPVGUI(Handle timer, int client)
{
	//ShowVGUIPanel(playerid, "info", _, false); // We'll keep the info screen but remove the class select.
	ShowVGUIPanel(client, "team", _, false);
	//ShowVGUIPanel(client, "class_blue", _, false);
	//ShowVGUIPanel(client, "class_red", _, false);
	ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red", _, false);
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{	
	int playerid = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (MISSION == 1)
	{
		if (!IsFakeClient(playerid))
		{
			char currentMap[256];
			GetCurrentMap(currentMap, 256);
			ServerCommand("exec missions/%s/mission.cfg", currentMap);
			
			//int test = GetConVarInt(cvarMissionTeam);
			//PrintToChatAll("team : %i", test);
			
			//TFClassType class = TF2_GetPlayerClass(playerid);
			//PrintToChatAll("Current Class: %i", class); 
			
			// Check if player is on the correct team. If not kill them and force switch teams.
			if(GetConVarInt(cvarMissionTeam) != GetClientTeam(playerid))
			{
				ChangeClientTeam(playerid, GetConVarInt(cvarMissionTeam));
				//ServerCommand("kill; wait 66; tf_bot_kick all; wait 66; mp_switchteams");
			}		
			//else if(class != GetConVarInt(cvarMissionClass))
			//{
			//	ServerCommand("join_class %i", GetConVarInt(cvarMissionClass));
			//}
			// It doesn't work this way but its ok cuz the cfgs handle this anyways.
			
			// Make sure the save folder exists or else missions won't save!
			char savepath[PLATFORM_MAX_PATH];
			//Format(savepath, sizeof(savepath), "save");
			BuildPath(Path_SM, savepath, sizeof(savepath), "../../save");
			if(!DirExists(savepath, true))
			{
				CreateDirectory(savepath, true);
			}
		}
	}
	else if (GetConVarBool(cvarListenServer) && !IsFakeClient(playerid))
	{
		// Not a mission so let's make sure offline practice settings load!
		// We'll make sure we only do this if we're playing offline.
		// And we also need to make sure we only do this if the bot_quota settings were reset due to a map change.
		if(GetConVarInt(FindConVar("tf_bot_quota")) == 0 && GetConVarInt(FindConVar("tf_bot_difficulty")) == 1)
		{
			char SrcPath[255], DstPath[255];
			Format(SrcPath, sizeof(SrcPath), "offlinepracticeconfig.vdf");
			Format(DstPath, sizeof(DstPath), "cfg/offlinepracticeconfig.vdf");
			CopyFile(SrcPath, DstPath, true);
			ServerCommand("exec offlinepracticeconfig.vdf");
			//PrintToChatAll("Fixed Bot Settings");
		}
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// If Full Moon is on (for halloween cosmetics on enemies) then fix medkits.
	// Thanks to TF2Sanitizer for showing me how I to do this.
	if(MISSION == 1 && GetConVarInt(FindConVar("tf_forced_holiday")) == 8 && IsValidEntity(entity) && strncmp(classname, "item_healthkit_", 15) == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnHealthKitSpawned);		
	}
}

public void OnHealthKitSpawned(int entity)
{
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", 0, _, 2);
}

public Action PlayerDied(Event event, const char[] name, bool dontBroadcast)
{
	if (MISSION == 1)
	{
		int playerid = GetClientOfUserId(GetEventInt(event, "userid", 0));
		TFClassType class = TF2_GetPlayerClass(playerid);
		if (!IsFakeClient(playerid) && GetConVarInt(cvarMissionTeam) == GetClientTeam(playerid) && class == GetConVarInt(cvarMissionClass) && 1 == GetConVarInt(cvarMissionBegin) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)) // Also check for dead ringing!
		{
			if (GetClientTeam(playerid) == 2)
			{
				// Cheats cannot be turned off due to issues with it reloading commands.
				// Doesn't really matter. If people wanted to cheat they could easily do so anyways.
				ServerCommand("wait 66; sv_cheats 1; wait 66; mp_forcewin 3");
			}
			else
			{
				ServerCommand("wait 66; sv_cheats 1; wait 66; mp_forcewin 2");
			}
		}
	}
	return Plugin_Continue;
}

public Action TEAMWIN(Event event, const char[] name, bool dontBroadcast)
{
	if (MISSION == 1)
	{	
		for(int i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (TF2_IsPlayerInCondition(i, TFCond_CritOnWin))
				{
					CreateTimer(14.0, WinTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(10.25, DoorsCloseTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					ServerCommand("echo MISSION_COMPLETE");
				}
				else
				{
					CreateTimer(14.0, LoseTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(7.5, LoseTimerPauling,_, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(13.25, DoorsCloseTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(16.25, DoorsOpenTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					ServerCommand("echo MISSION_FAILED");
				}
			}
		}  
	}
	return Plugin_Continue;
}

public Action WinTimer(Handle timer)
{
	// Load Outro Movies
	char currentMap[256];
	GetCurrentMap(currentMap, 256);
	ServerCommand("exec missions/%s/outro.cfg", currentMap);
	
	ServerCommand("gamemenucommand disconnect; wait 66; gamemenucommand OpenBonusMapsDialog");
	return Plugin_Continue;
}

public Action LoseTimer(Handle timer)
{	
	ServerCommand("wait 66; tf_bot_kick all; wait 66; tf_bot_quota 0; wait 66; mp_restartgame_immediate 1; wait 66; snd_restart");
	return Plugin_Continue;
}

public Action DoorsCloseTimer(Handle timer)
{	
	ServerCommand("wait 66; testhudanim TFMISSIONS_CLOSE_DOORS; wait 66; sm_botoverhaul_mission_begin 0");
	
	// By changing sm_botoverhaul_mission_begin we can inssue the round restarts properly.
	// Basically it won't get fucky and end the round because it had to switch teams at the beginning.
	CreateTimer(5.5, PlayerSwitchTimer,_, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action DoorsOpenTimer(Handle timer)
{	
	ServerCommand("wait 66; testhudanim TFMISSIONS_OPEN_DOORS");
	return Plugin_Continue;
}

public Action PlayerSwitchTimer(Handle timer)
{	
	ServerCommand("wait 66; sm_botoverhaul_mission_begin 1");
	return Plugin_Continue;
}

public Action LoseTimerPauling(Handle timer)
{
	// This randomly plays a Pauling failure line.
	// I might add one to play automatically for class spawns as well.
	// Maybe class win lines too?
	int rndpauling = GetRandomUInt(0,10);
	switch (rndpauling)
	{
		case 0:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_02.mp3;");
		}
		case 1:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_03.mp3;");
		}
		case 3:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_04.mp3;");
		}
		case 4:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_05.mp3;");
		}
		case 5:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_06.mp3;");
		}
		case 6:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_09.mp3;");
		}
		case 7:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_10.mp3;");
		}
		case 8:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_11.mp3;");
		}
		case 9:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_13.mp3;");
		}
		case 10:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_14.mp3;");
		}
	}
	return Plugin_Continue;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

public void OnClientDisconnect(int client) 
{ 
	// ENSURE MISSION MODE IS DISABLED UPON DISCONNECT!
	if (!IsFakeClient(client) && GetConVarInt(FindConVar("sv_bonus_challenge")) == 0)
	{
		if(MISSION == 1)
		{
			ServerCommand("motdfile motd_default.txt; wait 66; sm_botoverhaul_mission_team 0");
		}
		MISSION = 0;
		intro_blocked = 0;
		intro_video = 0;
		ServerCommand("stripper_cfg_path addons/stripper");
	}
}  

// Thanks Potato Uno!
stock bool CopyFile(const char[] Source, const char[] Destination, bool read_valve_fs=false)
{
    Handle f = OpenFile(Source, "rb", read_valve_fs);  
    Handle g = OpenFile(Destination, "w");
    
    int Buffer[1024];
    while (!IsEndOfFile(f))
    {
        int Size = ReadFile(f, Buffer, sizeof(Buffer), 1);
        WriteFile(g, Buffer, Size, 1);
    }
    
    delete f;
    delete g;
}  

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{	
	// If its mission mode then make sure bots don't crit.
    if (IsFakeClient(client) && MISSION == 1)
	{	
		// Make sure they crit if they have forced crits!
		if(!TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || !TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || !TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || !TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || !TF2_IsPlayerInCondition(client, TFCond_CritDemoCharge) || !TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || !TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || !TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || !TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || !TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) || !TF2_IsPlayerInCondition(client, TFCond_CritRuneTemp))
		{
			result = false;
			return Plugin_Handled;	
		}
	}
	
    return Plugin_Continue;
}  