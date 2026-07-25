#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

ConVar tf_bot_quota;
int fragcountblue = 0;
int fragcountred = 0;

#define PLUGIN_VERSION			"1.2.1"

public Plugin myinfo = {
	name		= "Bot Teamplay",
	author		= "Showin (Originally by Dr. McKay but I kinda completely changed it at this point.), Goerge",
	description	= "Manages TFBOTS for Bot Overhaul",
	version		= PLUGIN_VERSION,
	url			= "site.com"
};

Handle cvarBotManagerEnable;
Handle cvarAutoQuota;
Handle cvarTeamPlay;
Handle cvarBotRandomDif;

public void OnPluginStart() {
	cvarBotManagerEnable = CreateConVar("sm_bot_manager_enable", "1", "If nonzero, the bot manager will be activated.");
	cvarAutoQuota = CreateConVar("sm_bot_auto_quota", "0", "If nonzero, the best bot count will be chosen automatically to give the most bots with best performance.");
	cvarTeamPlay = CreateConVar("sm_bot_teamplay", "1", "If nonzero, bots will make more aggressive class choices if they're losing.");
	cvarBotRandomDif = CreateConVar("sm_bot_random_difficulty", "0", "Randomizes the difficulty of bots despite the setting");
	HookEvent("player_death", PlayerDied);
	HookEvent("player_connect", PlayerJoined);
}

public void OnConfigsExecuted() {
	char buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "maps/%s.nav", buffer);
	
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if(FileExists(buffer, true) && GetConVarBool(cvarBotManagerEnable) && GetConVarBool(cvarAutoQuota)) {
		// Check for how big the map is.
		int navsize = FileSize(buffer, true, NULL_STRING);
		//PrintToServer("nav size : %i", navsize);
		
		// If we be playing ctf!
		if(StrContains( currentMap, "ctf_" , false) != -1)
		{
			// Lower bot count for better performance! (we're gon be having sollys and heavies spawn through stripper)
			ServerCommand("tf_bot_quota 15");
		}
		// If the file size for nave is basically bigger than badwaters.
		else if(navsize >= 950000)
		{
			// Lower bot count for better performance!
			ServerCommand("tf_bot_quota 17");
		}
		else
		{
			// Increase bot count since performance should be good!
			ServerCommand("tf_bot_quota 19");
		}
	} 
}

public void OnMapEnd() {
	SetConVarInt(tf_bot_quota, 0); // Prevents an issue that happens at mapchange
}

public void OnMapStart() {
	fragcountblue = 0;
	fragcountred = 0;
	
	if(GetConVarBool(cvarBotManagerEnable) && GetConVarBool(cvarTeamPlay) && GetConVarInt(FindConVar("tf_gamemode_mvm")) == 0) 
	{
		CreateTimer(120.0, TeamplayTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("exec bot_teamplay_default.cfg"); // This will fuck with some per map/gamemode settings. So make sure this setting is turned off in those gamemode configs!
	}
}

public Action PlayerDied(Handle event , const char[] name , bool dontBroadcast)
{
	int killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(killer) && GetClientTeam(killer) == 2)
	{
		fragcountred++;
		//PrintToChatAll("Red Kills : %i", fragcountred);
	}
	else
	{
		fragcountblue++;
		//PrintToChatAll("Blue Kills : %i", fragcountblue);
	}
}

public Action TeamplayTimer(Handle timer)
{
if(GetConVarBool(cvarBotManagerEnable) && GetConVarBool(cvarTeamPlay)) 
{
	// SHOWIN! TO DO: TRACK ROUND TIMER! IF WE'RE CLOSE TO LOSING THEN LETS PUSH HARDER!
	if(fragcountred > fragcountblue + 20)
	{
		ServerCommand("exec bot_teamplay_blue.cfg");
		CreateTimer(119.0, RestoreDefault,_, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(fragcountblue > fragcountred + 20)
	{
		ServerCommand("exec bot_teamplay_red.cfg");
		CreateTimer(119.0, RestoreDefault,_, TIMER_FLAG_NO_MAPCHANGE);
	}
}
	//return Plugin_Continue;
}

public Action RestoreDefault(Handle timer)
{
	ServerCommand("exec bot_teamplay_default.cfg");
	return Plugin_Continue;
}

public Action PlayerJoined(Handle event , const char[] name, bool dontBroadcast)
{
	if(GetConVarBool(cvarBotManagerEnable) && GetConVarBool(cvarBotRandomDif) && GetConVarInt(FindConVar("tf_gamemode_mvm")) == 0) 
	{
		// Let's change this every time a bot joins to randomize their difficulty settings.
		CreateTimer(0.1, DifficultyChanger,_, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(GetConVarBool(cvarBotManagerEnable) && GetConVarBool(cvarBotRandomDif) && GetConVarInt(FindConVar("tf_gamemode_mvm")) == 0 && GetConVarInt(FindConVar("tf_bot_difficulty")) == 4) 
	{
		// If Bot difficulty is set to 4 then let's do random difficulty!
		SetConVarInt(FindConVar("sm_bot_random_difficulty"), 1);
	}
}

public Action DifficultyChanger(Handle timer)
{
	SetConVarInt(FindConVar("tf_bot_difficulty"), GetRandomInt(0, 3));
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || client < 0) 
		return false; 
	return true; 
}