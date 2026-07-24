#pragma semicolon 1 // put semicolon to show the end of line;
#pragma newdecls required

//////////////
/* INCLUDES */

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

/////////////
/* DEFINES */

#define nope false
#define yep true

#define PUBLIC_CHAT_TRIGGER '!'
#define SILENT_CHAT_TRIGGER '/'

#define CHAT_MESSAGE_MAX_LENGTH 256
#define EVENT_NAME_MAX_LENGTH 64

#define PLUGIN_VERSION "0.3"

//////////////////////
/* GLOBAL VARIABLES */

Handle tf_bot_chatter_version = INVALID_HANDLE;
Handle tf_bot_chatter_enable = INVALID_HANDLE;
Handle tf_bot_chatter_log = INVALID_HANDLE;

Handle hChatMessages = INVALID_HANDLE;

bool bChatterEnabled = yep;
bool bLoggingEnabled = yep;

float flLastChatTime[MAXPLAYERS+1] = { 0.0, ... };

float curTime = 0.0; // as longer as in Source Engine it's global variable

/////////////////
/* PLUGIN INFO */

public Plugin myinfo = {
	name = "[TF2] Bot Chatter",
	author = "Leonardo",
	description = "Bots will say something eventually.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};

///////////////////
/* PLUGIN EVENTS */

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("tf2botchatter.phrases");
	
	tf_bot_chatter_version = CreateConVar("tf_bot_chatter_version", PLUGIN_VERSION, "Bot Chatter Plugin Version", FCVAR_NOTIFY | 0);
	SetConVarString(tf_bot_chatter_version, PLUGIN_VERSION, yep, yep);
	HookConVarChange(tf_bot_chatter_version, OnConVarChanged_PluginVersion);
	
	tf_bot_chatter_enable = CreateConVar("tf_bot_chatter_enable", ( bChatterEnabled ? "1" : "0" ), "", FCVAR_NONE, yep, 0.0, yep, 1.0);
	HookConVarChange(tf_bot_chatter_enable, OnConVarChanged);
	
	tf_bot_chatter_log = CreateConVar("tf_bot_chatter_log", ( bLoggingEnabled ? "1" : "0" ), "", FCVAR_NONE, yep, 0.0, yep, 1.0);
	HookConVarChange(tf_bot_chatter_log, OnConVarChanged);
	
	char sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "tf", nope) && !StrEqual(sGameDir, "tf_beta", nope))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	HookEvent("player_spawn", OnHookedPlayerEvent, EventHookMode_Post);
	HookEvent("player_changeclass", OnHookedPlayerEvent, EventHookMode_Post);
	HookEvent("teamplay_teambalanced_player", OnHookedPlayerEvent, EventHookMode_Post);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	
	HookEvent("achievement_earned", OnAchievementEarned, EventHookMode_Post);
	HookEvent("item_found", OnItemFound, EventHookMode_Post);
	
	//HookEvent("player_calledformedic", OnHookedPlayerEvent, EventHookMode_Post);
	HookEvent("player_stunned", OnPlayerStunned, EventHookMode_Post);
	HookEvent("player_invulned", OnPlayerInvulned, EventHookMode_Post);
	//HookEvent("player_chargedeployed", OnHookedPlayerEvent, EventHookMode_Post);
	
	HookEvent("player_builtobject", OnObjectBuiltEvent, EventHookMode_Post);
	HookEvent("player_upgradedobject", OnObjectUpgradedEvent, EventHookMode_Post);
	HookEvent("player_sapped_object", OnObjectSappedEvent, EventHookMode_Post);
	HookEvent("object_destroyed", OnObjectDestroyedEvent, EventHookMode_Post);
	
	HookEvent("pumpkin_lord_summoned", OnHookedGameEvent, EventHookMode_Post);
	HookEvent("pumpkin_lord_killed", OnHookedGameEvent, EventHookMode_Post);
	HookEvent("eyeball_boss_summoned", OnHookedGameEvent, EventHookMode_Post);
	HookEvent("eyeball_boss_killed", OnHookedGameEvent, EventHookMode_Post);
	HookEvent("eyeball_boss_escaped", OnHookedGameEvent, EventHookMode_Post);
	
	HookEvent("teamplay_flag_event", OnFlagEvent, EventHookMode_Post);
	HookEvent("teamplay_point_startcapture", OnControlPointEvent, EventHookMode_Post);
	HookEvent("teamplay_point_captured", OnControlPointEvent, EventHookMode_Post);
	HookEvent("teamplay_capture_blocked", OnHookedPlayerEvent, EventHookMode_Post);
	
	HookEvent("teamplay_setup_finished", OnHookedGameEvent, EventHookMode_Post);
	HookEvent("teamplay_round_stalemate", OnHookedGameEvent, EventHookMode_Post);
	HookEvent("teamplay_suddendeath_begin", OnHookedGameEvent, EventHookMode_Post);
	
	HookEvent("teamplay_round_win", OnRoundWin, EventHookMode_Post);
	HookEvent("teamplay_game_over", OnHookedGameEvent, EventHookMode_Post);
	
	HookUserMessage( GetUserMessageId("PlayerJarated"), OnPlayerJarated);
	HookUserMessage( GetUserMessageId("PlayerIgnited"), OnPlayerIgnited);
	HookUserMessage( GetUserMessageId("PlayerExtinguished"), OnPlayerExtinguished);
	
	RegAdminCmd("tf_bot_chatter_refresh", Command_RefreshConfig, ADMFLAG_GENERIC);
}

public void OnMapStart()
{
	// update 
	if( GetEngineVersion() == Engine_TF2 )
		SetConVarString(tf_bot_chatter_version, PLUGIN_VERSION, yep, yep);
	
	// update on each map load
	LoadChatMessages();
	
	for(int i=0; i<=MAXPLAYERS; i++)
		flLastChatTime[i] = 0.0;
}

public void OnConfigsExecuted()
{
	bChatterEnabled = GetConVarBool(tf_bot_chatter_enable);
	bLoggingEnabled = GetConVarBool(tf_bot_chatter_log);
}

/////////////////
/* GAME EVENTS */

public void OnGameFrame()
{
	//static float flLastEventCallTime[2] = { 0.0, ... };
	static float flLastCheckingTime = 0.0;
	curTime = GetGameTime();
	if( (flLastCheckingTime - 0.1) < curTime )
		return; // do not work too fast
	flLastCheckingTime = curTime;
	
	if( !bChatterEnabled )
		return;
	
	//TODO: something. like a spy detection event
}

public void OnClientPostAdminCheck(int iClient)
{
	if( !bChatterEnabled )
		return;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strClientName[MAX_NAME_LENGTH] = "unconnected";
	char strBotName[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iClient, strClientName, sizeof(strClientName));
	
	if( IsValidBot(iClient) )
	{
		if( FindNiceWordsToSay( "player_connected", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iClient ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strClientName );
			BotSay( iClient, "player_connected", strMessage, flTypeTime, bTeamOnly );
		}
	}
	else if( strlen(strClientName) > 0 )
	{
		for( int iBot = 0; iBot <= MaxClients; iBot++ )
			if( IsValidBot(iBot) && IsItMyChanceToSay() )
				if( FindNiceWordsToSay( "other_player_connected", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
				{
					if( strMessage[0] == '#' )
					{
						GetClientName(iBot, strBotName, sizeof(strBotName));
						Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName, strClientName );
					}
					BotSay( iBot, "other_player_connected", strMessage, flTypeTime, bTeamOnly );
				}
	}
}

public Action OnHookedPlayerEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	char strCaller[16] = "userid";
	if( strcmp( strEventName, "teamplay_teambalanced_player", nope ) == 0 )
		strCaller = "player";
	if( strcmp( strEventName, "teamplay_capture_blocked", nope ) == 0 )
		strCaller = "blocker";
	
	int iCaller = GetClientOfUserId( GetEventInt( hEvent, strCaller ) );
	if( !IsValidClient(iCaller) )
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strCallerName[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iCaller, strCallerName, sizeof(strCallerName));
	
	if( IsValidBot(iCaller) )
		if( FindNiceWordsToSay( strEventName, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iCaller ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strCallerName );
			BotSay( iCaller, strEventName, strMessage, flTypeTime,  bTeamOnly );
		}
	
	return Plugin_Continue;
}
public Action OnAchievementEarned(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iCaller = GetClientOfUserId( GetEventInt( hEvent, "player" ) );
	if( !IsValidClient(iCaller) ) // wait, what? why event triggered?
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[EVENT_NAME_MAX_LENGTH];
	char strCallerName[MAX_NAME_LENGTH] = "unconnected";
	char strBotName[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iCaller, strCallerName, sizeof(strCallerName));
	
	Format(strEventNameEx, sizeof(strEventNameEx), "achievement_earned_%d", GetEventInt( hEvent, "achievement" ) );
	
	for( int iBot = 0; iBot <= MaxClients; iBot++ )
		if( IsValidBot(iBot) && IsItMyChanceToSay() )
			if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
			{
				if( strMessage[0] == '#' )
				{
					GetClientName(iBot, strBotName, sizeof(strBotName));
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName, strCallerName );
				}
				BotSay( iBot, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
			}
			else if( FindNiceWordsToSay( "achievement_earned", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
			{
				if( strMessage[0] == '#' )
				{
					GetClientName(iBot, strBotName, sizeof(strBotName));
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName, strCallerName );
				}
				BotSay( iBot, "achievement_earned", strMessage, flTypeTime,  bTeamOnly );
			}
	
	return Plugin_Continue;
}
public Action OnItemFound(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iCaller = GetClientOfUserId( GetEventInt( hEvent, "player" ) );
	if( !IsValidClient(iCaller) ) // wait, what? why event triggered?
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[EVENT_NAME_MAX_LENGTH];
	char strCallerName[MAX_NAME_LENGTH] = "unconnected";
	char strBotName[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iCaller, strCallerName, sizeof(strCallerName));
	
	Format(strEventNameEx, sizeof(strEventNameEx), "item_found_%d_%d", GetEventInt( hEvent, "itemdef" ), GetEventInt( hEvent, "quality" ) );
	
	for( int iBot = 0; iBot <= MaxClients; iBot++ )
		if( IsValidBot(iBot) && IsItMyChanceToSay() )
			if( FindNiceWordsToSay( "item_found", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
			{
				if( strMessage[0] == '#' )
				{
					GetClientName(iBot, strBotName, sizeof(strBotName));
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName, strCallerName );
				}
				BotSay( iBot, "item_found", strMessage, flTypeTime,  bTeamOnly );
			}
	
	return Plugin_Continue;
}
public Action OnPlayerHurt(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	int iVictim = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iVictim) ) // no victim = no deal
		return Plugin_Continue;
	
	if( iVictim == iAttacker )
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strAttackerName[MAX_NAME_LENGTH] = "unconnected";
	char strVictimName[MAX_NAME_LENGTH] = "unconnected";
	
	if( IsValidClient(iAttacker) )
		GetClientName(iAttacker, strAttackerName, sizeof(strAttackerName));
	GetClientName(iVictim, strVictimName, sizeof(strVictimName));
	
	if( IsValidBot(iVictim) && GetEventInt( hEvent, "health" ) > 0 )
		if( FindNiceWordsToSay( "player_hurt_victim", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strAttackerName, strVictimName );
			BotSay( iVictim, "player_hurt_victim", strMessage, flTypeTime,  bTeamOnly );
		}
	
	if( IsValidBot(iAttacker) )
		if( FindNiceWordsToSay( "player_hurt_attacker", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iAttacker ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strAttackerName, strVictimName );
			BotSay( iAttacker, "player_hurt_attacker", strMessage, flTypeTime,  bTeamOnly );
		}
	
	return Plugin_Continue;
}
public Action OnPlayerDeath(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iKiller = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	int iAssister = GetClientOfUserId( GetEventInt( hEvent, "assister" ) );
	int iVictim = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iVictim) ) // no victim = no deal
		return Plugin_Continue;
	
	if( iVictim == iKiller )
		return Plugin_Continue;
	
	char strWeaponName[32];
	GetEventString( hEvent, "weapon_logclassname", strWeaponName, sizeof(strWeaponName) );
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[EVENT_NAME_MAX_LENGTH];
	char strKillerName[MAX_NAME_LENGTH] = "unconnected";
	char strAssisterName[MAX_NAME_LENGTH] = "unconnected";
	char strVictimName[MAX_NAME_LENGTH] = "unconnected";
	
	if( IsValidClient(iKiller) )
		GetClientName(iKiller, strKillerName, sizeof(strKillerName));
	if( IsValidClient(iAssister) )
		GetClientName(iAssister, strAssisterName, sizeof(strAssisterName));
	GetClientName(iVictim, strVictimName, sizeof(strVictimName));
	
	if( IsValidBot(iVictim) )
	{
		Format(strEventNameEx, sizeof(strEventNameEx), "player_death_%s_%d", strWeaponName, GetEventInt( hEvent, "customkill" ) );
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
			BotSay( iVictim, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
		else
		{
			Format(strEventNameEx, sizeof(strEventNameEx), "player_death_%s", strWeaponName);
			if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
			{
				if( strMessage[0] == '#' )
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
				BotSay( iVictim, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
			}
			else
			{
				if( FindNiceWordsToSay( "player_death", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
				{
					if( strMessage[0] == '#' )
						Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
					BotSay( iVictim, "player_death", strMessage, flTypeTime,  bTeamOnly );
				}
			}
		}
	}
	
	if( IsValidBot(iKiller) )
	{
		Format(strEventNameEx, sizeof(strEventNameEx), "player_kill_%s_%d", strWeaponName, GetEventInt( hEvent, "customkill" ) );
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
			BotSay( iVictim, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
		else
		{
			Format(strEventNameEx, sizeof(strEventNameEx), "player_kill_%s", strWeaponName);
			if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iKiller ) )
			{
				if( strMessage[0] == '#' )
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
				BotSay( iKiller, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
			}
			else
			{
				if( FindNiceWordsToSay( "player_kill", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iKiller ) )
				{
					if( strMessage[0] == '#' )
						Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
					BotSay( iKiller, "player_kill", strMessage, flTypeTime,  bTeamOnly );
				}
			}
		}
	}
	
	if( IsValidBot(iAssister) )
	{
		Format(strEventNameEx, sizeof(strEventNameEx), "player_kill_assist_%s_%d", strWeaponName, GetEventInt( hEvent, "customkill" ) );
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
			BotSay( iVictim, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
		else
		{
			Format(strEventNameEx, sizeof(strEventNameEx), "player_kill_assist_%s", strWeaponName);
			if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iAssister ) )
			{
				if( strMessage[0] == '#' )
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
				BotSay( iAssister, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
			}
			else
			{
				if( FindNiceWordsToSay( "player_kill_assist", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iAssister ) )
				{
					if( strMessage[0] == '#' )
						Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strKillerName, strAssisterName, strVictimName );
					BotSay( iAssister, "player_kill_assist", strMessage, flTypeTime,  bTeamOnly );
				}
			}
		}
	}
	
	return Plugin_Continue;
}
public Action OnPlayerStunned(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iStunner = GetClientOfUserId( GetEventInt( hEvent, "stunner" ) );
	int iVictim = GetClientOfUserId( GetEventInt( hEvent, "victim" ) );
	if( !IsValidClient(iVictim) ) // no victim = no deal
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strStunnerName[MAX_NAME_LENGTH] = "unconnected";
	char strVictimName[MAX_NAME_LENGTH] = "unconnected";
	
	if( IsValidClient(iStunner) )
		GetClientName(iStunner, strStunnerName, sizeof(strStunnerName));
	GetClientName(iVictim, strVictimName, sizeof(strVictimName));
	
	if( IsValidBot(iStunner) )
		if( FindNiceWordsToSay( "player_stunned_stunner", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iStunner ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strStunnerName, strVictimName );
			BotSay( iStunner, "player_stunned_stunner", strMessage, flTypeTime,  bTeamOnly );
		}
	
	if( IsValidBot(iVictim) )
		if( FindNiceWordsToSay( "player_stunned_victim", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iVictim ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strStunnerName, strVictimName );
			BotSay( iVictim, "player_stunned_victim", strMessage, flTypeTime,  bTeamOnly );
		}
	
	return Plugin_Continue;
}
public Action OnPlayerInvulned(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iMedic = GetClientOfUserId( GetEventInt( hEvent, "medic_userid" ) );
	int iPatient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iPatient) ) // no patient = no deal
		return Plugin_Continue;
	if( IsValidClient(iMedic) && iMedic == iPatient ) // do not care about self
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strMedicName[MAX_NAME_LENGTH] = "unconnected";
	char strPatientName[MAX_NAME_LENGTH] = "unconnected";
	
	if( IsValidClient(iMedic) )
		GetClientName(iMedic, strMedicName, sizeof(strMedicName));
	GetClientName(iPatient, strPatientName, sizeof(strPatientName));
	
	if( IsValidBot(iMedic) )
		if( FindNiceWordsToSay( "player_invulned_medic", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iMedic ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strMedicName, strPatientName );
			BotSay( iMedic, "player_invulned_medic", strMessage, flTypeTime,  bTeamOnly );
		}
	
	if( IsValidBot(iPatient) )
		if( FindNiceWordsToSay( "player_invulned_patient", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iPatient ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strMedicName, strPatientName );
			BotSay( iPatient, "player_invulned_patient", strMessage, flTypeTime,  bTeamOnly );
		}
	
	return Plugin_Continue;
}
public Action OnObjectBuiltEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iBuilder = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iBuilder) )
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[EVENT_NAME_MAX_LENGTH];
	char strBuilderName[MAX_NAME_LENGTH] = "unconnected";
	char strOwnerName[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iBuilder, strBuilderName, sizeof(strBuilderName));
	
	switch( GetEventInt(hEvent, "object") )
	{
		case 0: Format(strEventNameEx, sizeof(strEventNameEx), "%s_dispenser", strEventName);
		case 1: Format(strEventNameEx, sizeof(strEventNameEx), "%s_teleport_entr", strEventName);
		case 2: Format(strEventNameEx, sizeof(strEventNameEx), "%s_teleport_exit", strEventName);
		case 3: Format(strEventNameEx, sizeof(strEventNameEx), "%s_sentry", strEventName);
		case 4: Format(strEventNameEx, sizeof(strEventNameEx), "%s_sapper", strEventName);
	}
	
	if( IsValidBot(iBuilder) )
	{
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBuilder ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBuilderName, strOwnerName );
			BotSay( iBuilder, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	return Plugin_Continue;
}
public Action OnObjectUpgradedEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iBuilder = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iBuilder) )
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[EVENT_NAME_MAX_LENGTH];
	char strBuilderName[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iBuilder, strBuilderName, sizeof(strBuilderName));
	
	switch( GetEventInt(hEvent, "object") )
	{
		case 0: Format(strEventNameEx, sizeof(strEventNameEx), "%s_dispenser", strEventName);
		case 1: Format(strEventNameEx, sizeof(strEventNameEx), "%s_teleport", strEventName);
		case 2: Format(strEventNameEx, sizeof(strEventNameEx), "%s_sentry", strEventName);
	}
	
	if( IsValidBot(iBuilder) )
	{
		if( GetEventInt(hEvent, "isbuilder") )
			Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_builder", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBuilder ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBuilderName );
			BotSay( iBuilder, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	return Plugin_Continue;
}
public Action OnObjectSappedEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iSpy = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	int iOwner = GetClientOfUserId( GetEventInt( hEvent, "ownerid" ) );
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[2][EVENT_NAME_MAX_LENGTH];
	char strSpyName[MAX_NAME_LENGTH] = "unconnected";
	char strOwnerName[MAX_NAME_LENGTH] = "unconnected";
	
	if( IsValidClient(iSpy) )
		GetClientName(iSpy, strSpyName, sizeof(strSpyName));
	if( IsValidClient(iOwner) )
		GetClientName(iOwner, strOwnerName, sizeof(strOwnerName));
	
	switch( GetEventInt(hEvent, "object") )
	{
		case 0: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_dispenser", strEventName);
		case 1: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_teleport", strEventName);
		case 2: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_sentry", strEventName);
	}
	
	if( IsValidBot(iSpy) )
	{
		Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_spy", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx[1], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iSpy ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strSpyName, strOwnerName );
			BotSay( iSpy, strEventNameEx[1], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	if( IsValidBot(iOwner) )
	{
		if( FindNiceWordsToSay( strEventNameEx[0], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iOwner ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strSpyName, strOwnerName );
			BotSay( iOwner, strEventNameEx[0], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	return Plugin_Continue;
}
public Action OnObjectDestroyedEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iBuilder = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	int iDestroyer = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	int iAssister = GetClientOfUserId( GetEventInt( hEvent, "assister" ) );
	if( !IsValidClient(iBuilder) ) // no owner = no deal
		return Plugin_Continue;
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[2][EVENT_NAME_MAX_LENGTH];
	char strBuilderName[MAX_NAME_LENGTH] = "unconnected";
	char strDestroyerName[MAX_NAME_LENGTH] = "unconnected";
	char strAssisterName[MAX_NAME_LENGTH] = "unconnected";
	
	if( IsValidClient(iDestroyer) )
		GetClientName(iDestroyer, strDestroyerName, sizeof(strDestroyerName));
	if( IsValidClient(iAssister) )
		GetClientName(iAssister, strAssisterName, sizeof(strAssisterName));
	GetClientName(iBuilder, strBuilderName, sizeof(strBuilderName));
	
	switch( GetEventInt(hEvent, "objecttype") )
	{
		case 0: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_dispenser", strEventName);
		case 1: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_teleport", strEventName);
		case 2: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_sentry", strEventName);
		case 3: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_sapper", strEventName);
	}
	
	if( IsValidBot(iBuilder) )
	{
		Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_builder", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx[1], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBuilder ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBuilderName, strDestroyerName, strAssisterName );
			BotSay( iBuilder, strEventNameEx[1], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	if( IsValidBot(iDestroyer) )
	{
		Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_destroyer", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx[1], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iDestroyer ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBuilderName, strDestroyerName, strAssisterName );
			BotSay( iDestroyer, strEventNameEx[1], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	if( IsValidBot(iAssister) )
	{
		Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_assister", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx[1], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iAssister ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBuilderName, strDestroyerName, strAssisterName );
			BotSay( iAssister, strEventNameEx[1], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	return Plugin_Continue;
}
public Action OnPlayerJarated(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int iAttacker = BfReadByte(bf);
	int iVictim = BfReadByte(bf);
	
	On2PlayerEvent( "player_jarated", iAttacker, iVictim );
	
	return Plugin_Continue;
}

public Action OnPlayerIgnited(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int iVictim = BfReadByte(bf);
	int iIgniter = BfReadByte(bf);
	
	On2PlayerEvent( "player_ignited", iIgniter, iVictim );
	
	return Plugin_Continue;
}

public Action OnPlayerExtinguished(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int iVictim = BfReadByte(bf);
	int iExtinguisher = BfReadByte(bf);
	
	On2PlayerEvent( "player_extinguished", iExtinguisher, iVictim );
	
	return Plugin_Continue;
}

public void On2PlayerEvent(const char[] strEventName, int iPlayer1, int iPlayer2)
{
	if( !IsValidClient(iPlayer1) || !IsValidClient(iPlayer2) )
		return;
	
	if( !bChatterEnabled )
		return;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[EVENT_NAME_MAX_LENGTH];
	char strPlayer1Name[MAX_NAME_LENGTH] = "unconnected";
	char strPlayer2Name[MAX_NAME_LENGTH] = "unconnected";
	
	GetClientName(iPlayer1, strPlayer1Name, sizeof(strPlayer1Name));
	GetClientName(iPlayer2, strPlayer2Name, sizeof(strPlayer2Name));
	
	if( IsValidBot(iPlayer1) )
	{
		Format(strEventNameEx, sizeof(strEventNameEx), "%s_player1", strEventName);
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iPlayer1 ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strPlayer1Name, strPlayer2Name );
			BotSay( iPlayer1, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	if( IsValidBot(iPlayer2) )
	{
		Format(strEventNameEx, sizeof(strEventNameEx), "%s_player2", strEventName);
		if( FindNiceWordsToSay( strEventNameEx, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iPlayer2 ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strPlayer1Name, strPlayer2Name );
			BotSay( iPlayer2, strEventNameEx, strMessage, flTypeTime,  bTeamOnly );
		}
	}
}

public Action OnHookedGameEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strBotName[MAX_NAME_LENGTH];
	
	for( int iBot = 0; iBot <= MaxClients; iBot++ )
		if( IsValidBot(iBot) && IsItMyChanceToSay() )
			if( FindNiceWordsToSay( strEventName, strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
			{
				if( strMessage[0] == '#' )
				{
					GetClientName(iBot, strBotName, sizeof(strBotName));
					Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
				}
				BotSay( iBot, strEventName, strMessage, flTypeTime,  bTeamOnly );
			}
	
	return Plugin_Continue;
}
public Action OnRoundWin(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iWinTeam = GetEventInt( hEvent, "team" );
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strBotName[MAX_NAME_LENGTH];
	
	if( iWinTeam < 2 || iWinTeam > 3 )
	{
		for( int iBot = 0; iBot <= MaxClients; iBot++ )
			if( IsValidBot(iBot) && IsItMyChanceToSay() )
				if( FindNiceWordsToSay( "teamplay_round_win_nobody", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
				{
					if( strMessage[0] == '#' )
					{
						GetClientName(iBot, strBotName, sizeof(strBotName));
						Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
					}
					BotSay( iBot, "teamplay_round_win_nobody", strMessage, flTypeTime,  bTeamOnly );
				}
	}
	else
	{
		for( int iBot = 0; iBot <= MaxClients; iBot++ )
			if( IsValidBot(iBot) && IsItMyChanceToSay() )
				if( GetClientTeam(iBot) == iWinTeam )
				{
					if( FindNiceWordsToSay( "teamplay_round_win_friend", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
					{
						if( strMessage[0] == '#' )
						{
							GetClientName(iBot, strBotName, sizeof(strBotName));
							Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
						}
						BotSay( iBot, "teamplay_round_win_friend", strMessage, flTypeTime,  bTeamOnly );
					}
				}
				else
				{
					if( FindNiceWordsToSay( "teamplay_round_win_enemy", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
					{
						if( strMessage[0] == '#' )
						{
							GetClientName(iBot, strBotName, sizeof(strBotName));
							Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
						}
						BotSay( iBot, "teamplay_round_win_enemy", strMessage, flTypeTime,  bTeamOnly );
					}
				}
	}
	
	return Plugin_Continue;
}
public Action OnFlagEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iCarrier = GetClientOfUserId( GetEventInt( hEvent, "carrier" ) );
	int iPlayer = GetClientOfUserId( GetEventInt( hEvent, "player" ) );
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strEventNameEx[2][EVENT_NAME_MAX_LENGTH];
	char strCarrierName[MAX_NAME_LENGTH] = "unconnected";
	char strPlayerName[MAX_NAME_LENGTH] = "unconnected";
	char strBotName[MAX_NAME_LENGTH];
	
	switch( GetEventInt(hEvent, "eventtype") )
	{
		case 1: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_pickedup", strEventName);
		case 2: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_captured", strEventName);
		case 3: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_defended", strEventName);
		case 4: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_dropped", strEventName);
		case 5: Format(strEventNameEx[0], EVENT_NAME_MAX_LENGTH-1, "%s_returned", strEventName);
	}
	
	if( IsValidClient(iCarrier) )
		GetClientName(iCarrier, strCarrierName, sizeof(strCarrierName));
	if( IsValidClient(iPlayer) )
		GetClientName(iPlayer, strPlayerName, sizeof(strPlayerName));
	
	if( IsValidBot(iCarrier) )
	{
		Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_carrier", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx[1], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iCarrier ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strPlayerName, strCarrierName );
			BotSay( iCarrier, strEventNameEx[1], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	if( IsValidBot(iPlayer) )
	{
		Format(strEventNameEx[1], EVENT_NAME_MAX_LENGTH-1, "%s_player", strEventNameEx[0]);
		if( FindNiceWordsToSay( strEventNameEx[1], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iPlayer ) )
		{
			if( strMessage[0] == '#' )
				Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strPlayerName, strCarrierName );
			BotSay( iPlayer, strEventNameEx[1], strMessage, flTypeTime,  bTeamOnly );
		}
	}
	
	if( !IsValidClient(iPlayer) && !IsValidClient(iCarrier) )
	{
		for( int iBot = 0; iBot <= MaxClients; iBot++ )
			if( IsValidBot(iBot) && IsItMyChanceToSay() )
				if( FindNiceWordsToSay( strEventNameEx[0], strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
				{
					if( strMessage[0] == '#' )
					{
						GetClientName(iBot, strBotName, sizeof(strBotName));
						Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER );
					}
					BotSay( iPlayer, strEventNameEx[0], strMessage, flTypeTime,  bTeamOnly );
				}
	}
	
	return Plugin_Continue;
}
public Action OnControlPointEvent(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iOwnerTeam = GetEventInt( hEvent, "team" );
	int iCapTeam = GetEventInt( hEvent, "capteam" );
	
	if( !bChatterEnabled )
		return Plugin_Continue;
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	bool bTeamOnly;
	float flTypeTime;
	char strBotName[MAX_NAME_LENGTH];
	
	if( strcmp( strEventName, "teamplay_point_startcapture", false) == 0 )
	{
		for( int iBot = 0; iBot <= MaxClients; iBot++ )
			if( IsValidBot(iBot) && IsItMyChanceToSay() )
				if( iCapTeam >= 2 && iCapTeam <= 3 )
				{
					if( GetClientTeam(iBot) == iCapTeam )
					{
						if( FindNiceWordsToSay( "teamplay_point_startcapture_friend", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
						{
							if( strMessage[0] == '#' )
							{
								GetClientName(iBot, strBotName, sizeof(strBotName));
								Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
							}
							BotSay( iBot, "teamplay_point_startcapture_friend", strMessage, flTypeTime,  bTeamOnly );
						}
					}
					else
					{
						if( FindNiceWordsToSay( "teamplay_point_startcapture_enemy", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
						{
							if( strMessage[0] == '#' )
							{
								GetClientName(iBot, strBotName, sizeof(strBotName));
								Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
							}
							BotSay( iBot, "teamplay_point_startcapture_enemy", strMessage, flTypeTime,  bTeamOnly );
						}
					}
				}
				else
				{
					
					if( GetClientTeam(iBot) == iOwnerTeam )
					{
						if( FindNiceWordsToSay( "teamplay_point_captured_friend", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
						{
							if( strMessage[0] == '#' )
							{
								GetClientName(iBot, strBotName, sizeof(strBotName));
								Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
							}
							BotSay( iBot, "teamplay_point_captured_friend", strMessage, flTypeTime,  bTeamOnly );
						}
					}
					else
					{
						if( FindNiceWordsToSay( "teamplay_point_captured_enemy", strMessage, sizeof(strMessage), flTypeTime, bTeamOnly, iBot ) )
						{
							if( strMessage[0] == '#' )
							{
								GetClientName(iBot, strBotName, sizeof(strBotName));
								Format( strMessage, sizeof(strMessage), "%T", strMessage[1], LANG_SERVER, strBotName );
							}
							BotSay( iBot, "teamplay_point_captured_enemy", strMessage, flTypeTime,  bTeamOnly );
						}
					}
				}
	}
	
	return Plugin_Continue;
}

////////////
/* TIMERS */

public Action Timer_BotSay(Handle hTimer, Handle hData)
{
	ResetPack( hData );
	
	int iBot = ReadPackCell(hData);
	if( !IsValidBot(iBot) )
		return Plugin_Handled;
	
	char strEventName[EVENT_NAME_MAX_LENGTH];
	ReadPackString( hData, strEventName, sizeof(strEventName) );
	
	char strMessage[CHAT_MESSAGE_MAX_LENGTH];
	ReadPackString( hData, strMessage, sizeof(strMessage) );
	
	bool bTeamOnly = ( ReadPackCell(hData) != 0 );
	
	if( bTeamOnly )
		FakeClientCommand( iBot, "say_team \"%s\"", strMessage );
	else
		FakeClientCommand( iBot, "say \"%s\"", strMessage );
	
	if( bLoggingEnabled )
	{
		char strPath[PLATFORM_MAX_PATH];
		FormatTime(strPath, sizeof(strPath), "%Y%m%d-tf2botchatter.log");
		BuildPath(Path_SM, strPath, sizeof(strPath), "logs/%s", strPath);
		LogToFileEx( strPath, "<%s> %s%N :  %s", strEventName, ( bTeamOnly == true ? "(TEAM) " : "" ), iBot, strMessage );
	}
	
	return Plugin_Handled;
}

////////////////////
/* CMDS AND CVARS */

public Action Command_RefreshConfig(int iClient, int iArgs)
{
	LoadChatMessages();
	return Plugin_Handled;
}

public void OnConVarChanged_PluginVersion(Handle hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if(!StrEqual(sNewValue, PLUGIN_VERSION, nope))
		SetConVarString(hConVar, PLUGIN_VERSION, yep, yep);
}

public void OnConVarChanged(Handle hConVar, const char[] sOldValue, const char[] sNewValue)
{
	OnConfigsExecuted();
}

//////////////////////
/* PLUGIN FUNCTIONS */

void LoadChatMessages()
{
	char strFilePath[PLATFORM_MAX_PATH] = "";
	BuildPath( Path_SM, strFilePath, sizeof(strFilePath), "configs/tf2botchatter.txt" );
	if( !FileExists( strFilePath ) )
		SetFailState( "Couldn't found file: %s", strFilePath );
	
	hChatMessages = CreateKeyValues("botchatter");
	FileToKeyValues( hChatMessages, strFilePath );
}

bool FindNiceWordsToSay(const char[] strEventName, char[] strMessage, int iMessageLength, float &flTypeTime, bool &bTeamOnly, int &iBot)
{
	bool bGotString = nope;
	
	char strCurrentMap[32];
	GetCurrentMap( strCurrentMap, sizeof(strCurrentMap) );
	
	SetRandomSeed( RoundFloat( GetEngineTime() ) );
	char flStringChance[4];
	float flSayChance = GetRandomFloat( 0.0, 100.0 );
	
	KvRewind( hChatMessages );
	if( KvJumpToKey( hChatMessages, strEventName, nope )  && KvGotoFirstSubKey( hChatMessages ) )
	{
		int iStrictClass;
		int iStrictTeam;
		char strStrictMap[32];
		do
		{
			KvGetSectionName( hChatMessages, flStringChance, sizeof(flStringChance) );
			if( StringToFloat( flStringChance ) >= flSayChance )
			{
				KvGetString( hChatMessages, "message", strMessage, iMessageLength, "LOOKUP FAILED!" );
				flTypeTime = KvGetFloat( hChatMessages, "typetime", 0.1 );
				bTeamOnly = view_as<bool>(( KvGetNum( hChatMessages, "teamonly", 0 ) != 0 ? 1 : 0 ));
				
				iStrictClass = KvGetNum( hChatMessages, "class", 0 );
				if( iStrictClass >= 1 && iStrictClass <= 10 )
					if( view_as<int>(TF2_GetPlayerClass(iBot)) != iStrictClass )
						continue;
				
				iStrictTeam = KvGetNum( hChatMessages, "team", 0 );
				if( iStrictTeam >= 2 && iStrictTeam <= 3 )
					if( GetClientTeam(iBot) != iStrictTeam )
						continue;
				
				KvGetString( hChatMessages, "mapstrict", strStrictMap, sizeof(strStrictMap), "" );
				if( strlen(strStrictMap) > 0 && strcmp( strCurrentMap, strStrictMap, false ) != 0 )
					continue;
				
				bGotString = yep;
				
				if( GetRandomInt(0,1) )
					break;
			}
		}
		while( KvGotoNextKey( hChatMessages ) );
	}
	
	return bGotString;
}

void BotSay(const int iBot, const char[] strEventName, const char[] strMessage, float flTypeTime = 0.1, const bool bTeamOnly = nope )
{
	if( flTypeTime < 0.1 ) flTypeTime = 0.1; // prevent buggy timers
	
	flTypeTime += ( (flLastChatTime[iBot] - curTime) > 0.0 ? (flLastChatTime[iBot] - curTime) : 0.0 );
	flLastChatTime[iBot] = curTime + flTypeTime;
	
	Handle hWData = CreateDataPack();
	CreateDataTimer( flTypeTime, Timer_BotSay, hWData, TIMER_DATA_HNDL_CLOSE );
	WritePackCell( hWData, iBot);
	WritePackString(hWData, strEventName);
	WritePackString(hWData, strMessage);
	WritePackCell(hWData, bTeamOnly);
}

/////////////////////
/* STOCK FUNCTIONS */

stock bool IsItMyChanceToSay()
{
	//SetRandomSeed( RoundFloat( GetEngineTime() ) );
	return ( GetRandomInt(0, 3) == 1 );
}

stock bool IsValidClient(int iClient)
{
	if( iClient <= 0 ) return nope;
	if( iClient > MaxClients ) return nope;
	if( !IsClientConnected(iClient) ) return nope;
	return IsClientInGame(iClient);
}

stock bool IsValidBot(int iBot)
{
	if(GetRandomInt(0, 3) != 1) return nope;
	if( !IsValidClient(iBot) ) return nope;
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 4
	if( IsClientSourceTV(iBot) ) return nope;
	if( IsClientReplay(iBot) ) return nope;
#endif
	if( GetClientTeam(iBot) <= 1 ) return nope; // unassigned and spectators, STFU
	return IsFakeClient(iBot);
}