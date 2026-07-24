#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.7.5"

float g_flMiscTimer[MAXPLAYERS + 1];
float g_flNeedHealTimer[MAXPLAYERS + 1];
float g_flThanksTimer[MAXPLAYERS + 1];
float g_flBuildhereTimer[MAXPLAYERS + 1];
float g_flRTDTimer[MAXPLAYERS + 1];
ConVar g_cvBVCEnable;
ConVar g_cvRTDEnable;

public Plugin myinfo = 
{
	name = "[TF2] Bot Voice Commands",
	author = "EfeDursun125, enderandrew, Marqueritte, Showin', and Crasher_3637",
	description = "Bots use voice commands.",
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
 	g_cvBVCEnable = CreateConVar("tf_bot_voice_commands", "1", "controls whenever TFbots use voice commands. Default = 1.", _, true, 0.0, true, 1.0);
	g_cvRTDEnable = CreateConVar("tf_bot_rtd_support", "0", "Enables or Disables RTD(Roll The Dice) support for TFbots. Default = 0.", _, true, 0.0, true, 1.0);
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
	HookEvent("player_hurt", BotHurt, EventHookMode_Post);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		// Voice Commands
		
		if (g_cvRTDEnable.IntValue > 0)
		{	
			// For Unfinished RTD Support.
			if(g_flRTDTimer[client] < GetGameTime()) // Bots types RTD.
			{
				FakeClientCommandThrottled(client, "say /rtd"); // Instead of exclamation use a slash so it won't spam chat.
				g_flRTDTimer[client] = GetGameTime() + GetRandomFloat(90.0, 125.0);
			}
		}
		
		if (g_cvBVCEnable.IntValue > 0)
		{
			if(g_flMiscTimer[client] < GetGameTime()) // Bots use Misc Voice Commands (i.e "Battle Cry" and "Cheers")
			{
				int randomvoice = GetRandomInt(1,5);
				switch (randomvoice)
				{
					case 1: 
					{
						FakeClientCommandThrottled(client, "voicemenu 2 1"); // Battle Cry
					}
					case 2:
					{
						FakeClientCommandThrottled(client, "voicemenu 2 2"); // Cheers
					}
					case 3: 
					{
						FakeClientCommandThrottled(client, "voicemenu 2 3"); // Jeers
					}
					case 4:
					{
						FakeClientCommandThrottled(client, "voicemenu 2 4"); // Positive
					}
					case 5:
					{
						FakeClientCommandThrottled(client, "voicemenu 2 5"); // Negative
					}
				}
				g_flMiscTimer[client] = GetGameTime() + GetRandomFloat(40.0, 85.0);
			}
			
			if(g_flNeedHealTimer[client] < GetGameTime()) // Bot calls "Medic" when low in health (checks if there is a medic)
			{
				int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				if(CurrentHealth < (MaxHealth / 2))
				{
					if(GetAliveMedicsCount(client) > 0)
					{
						FakeClientCommandThrottled(client, "voicemenu 0 0");
					}
				}
				g_flNeedHealTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
			}
			
			if(g_flThanksTimer[client] < GetGameTime()) // Bots thank medics after being healed.
			{
				if(TF2_GetNumHealers(client) > 0)
				{
					FakeClientCommandThrottled(client, "voicemenu 0 1");
				}
				g_flThanksTimer[client] = GetGameTime() + GetRandomFloat(15.0, 25.0);
			}
			
			if(g_flBuildhereTimer[client] < GetGameTime()) // Bots use Build Voice Commands (i.e "SentryHere" and "DispenserHere")
			{
				TFClassType class = TF2_GetPlayerClass(client);
				if(class != TFClass_Engineer)
				{	
					if(GetAliveEngineerCount(client) > 0)
					{
						int buildvoice = GetRandomInt(1,4);
						switch (buildvoice)
						{
							case 1:
							{
								FakeClientCommandThrottled(client, "voicemenu 1 5"); // SentryHere
							}
							case 2:							
							{
								FakeClientCommandThrottled(client, "voicemenu 1 4"); // DispenserHere
							}
							case 3: 
							{
								FakeClientCommandThrottled(client, "voicemenu 1 3"); // TeleporterHere
							}
							case 4: 
							{
								FakeClientCommandThrottled(client, "voicemenu 0 3"); // MoveUp
							}
						}
						g_flBuildhereTimer[client] = GetGameTime() + 150.0;
					}
				}
			}
		}	
	}
	return Plugin_Continue;
}

public Action BotSpawn(Handle event, const char[] name, bool dontBroadcast) // Bot uses voice commands when they spawn. (This code and below are taken from efedursun)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(botid) && IsFakeClient(botid) && IsPlayerAlive(botid)) 
	{
		int spawnchance = GetRandomInt(1,24);
		switch(spawnchance)
		{
			case 1:
			{
				FakeClientCommandThrottled(botid, "voicemenu 0 2"); // Go Go Go
			}
			case 2:
			{
				FakeClientCommandThrottled(botid, "voicemenu 1 0"); // Incoming
			}
			case 3:
			{
				FakeClientCommandThrottled(botid, "voicemenu 0 0"); // Medic!
			}
			case 4:
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 0"); // Help!
			}
			case 5: 
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 3"); // Jeers
			}
			case 6:
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 5"); // Negative
			}
			case 7: 
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 1"); // Battle Cry
			}
		}
	}
}

public Action BotHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(botid) && IsFakeClient(botid) && IsPlayerAlive(botid))
	{
		int hurtchance = GetRandomInt(1,18);
		switch(hurtchance)
		{
			case 1:
			{
				FakeClientCommandThrottled(botid, "voicemenu 2 0"); // Help!
			}
		}
	}
}

public Action hookPlayerDie(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetEventInt(event, "attacker");
	int botid = GetClientOfUserId(attacker);
	
	if(IsValidClient(botid) && IsFakeClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			int random = GetRandomInt(1,12);
			switch(random)
			{
				case 1:
			  	{
					FakeClientCommandThrottled(botid, "voicemenu 2 6"); // Nice Shot
				}
				case 2: 
				{
					FakeClientCommandThrottled(botid, "voicemenu 2 7"); // Good Job
				}
			}
		}
	}
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

stock int TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock int GetAliveEngineerCount(int client)
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client) && TF2_GetPlayerClass(i) == TFClass_Engineer) 
            number++;
    }
    return number;
}

stock int GetAliveMedicsCount(int client)
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client) && TF2_GetPlayerClass(i) == TFClass_Medic) 
            number++;
    }
    return number;
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}