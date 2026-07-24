#pragma semicolon 1
#pragma newdecls required
//#include <sourcemod>
//#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define VERSION "0.1"

Handle SpyTimer;
Handle CheckTimer;
float g_flJumpTimer[MAXPLAYERS + 1];
float g_flDuckTimer[MAXPLAYERS + 1];
float BotTimer[MAXPLAYERS + 1];
int SoldierTimerNum = 0; // Define this here cuz we'll use it for sollys rocket jumps.
int Setup = 0;
int Payload = 0;
int RD = 0;
int PD = 0;
int MVM = 0;
int BotBegin = 0;
int realplayercount = 0;
bool ban_primary[MAXPLAYERS+1] = false;
bool ban_secondary[MAXPLAYERS+1] = false;
bool ban_melee[MAXPLAYERS+1] = false;
bool SapTime[MAXPLAYERS+1] = false;
bool MedkitNear[MAXPLAYERS+1] = false;
bool SpyAttack[MAXPLAYERS+1] = false;
bool ImproveAI[MAXPLAYERS+1] = false;

// Human-awareness state. These values sit underneath the class-specific logic so
// every combat class shares the same reaction, target-lock, and memory rules.
int g_awarenessTarget[MAXPLAYERS + 1];
int g_awarenessPendingTarget[MAXPLAYERS + 1];
int g_awarenessCachedCandidate[MAXPLAYERS + 1];
bool g_awarenessTargetVisible[MAXPLAYERS + 1];
bool g_humanAnglesInitialized[MAXPLAYERS + 1];
float g_awarenessReactionUntil[MAXPLAYERS + 1];
float g_awarenessMemoryUntil[MAXPLAYERS + 1];
float g_awarenessTargetLockUntil[MAXPLAYERS + 1];
float g_awarenessNextScanAt[MAXPLAYERS + 1];
float g_awarenessLastKnownPos[MAXPLAYERS + 1][3];
float g_humanViewAngles[MAXPLAYERS + 1][3];
float g_humanAimOffset[MAXPLAYERS + 1][2];
float g_humanAimOffsetUntil[MAXPLAYERS + 1];
float g_humanAimLastUpdate[MAXPLAYERS + 1];
float g_humanAimSnapReactionUntil[MAXPLAYERS + 1];
float g_humanSkillVariance[MAXPLAYERS + 1];

ConVar g_btEnable;
ConVar g_botDifficulty;
ConVar g_humanAwarenessEnable;
ConVar g_humanReactionMin;
ConVar g_humanReactionMax;
ConVar g_humanMemoryMin;
ConVar g_humanMemoryMax;
ConVar g_humanTargetLockMin;
ConVar g_humanTargetLockMax;

public Plugin myinfo = {
	name = "Bot AI",
	author = "Showin / EfeDursun125, Marqueritte, Guren, Oshizu, thecount, etc",
	description = "Bots do shit.",
	version= "1",
};

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", SetupStarted);
	HookEvent("teamplay_setup_finished", RoundStarted);
	HookEvent("player_hurt", PlayerHurt);
	g_btEnable = CreateConVar("tf_bot_ai_tweaks", "1", "Enables many ai tweaks to make bots smarter. This is performance costly. Default = 1.", _, true, 0.0, true, 1.0);
	g_humanAwarenessEnable = CreateConVar("tf_bot_human_awareness", "1", "Adds reaction delay, target memory, target commitment, and humanized turning to improved bots.", _, true, 0.0, true, 1.0);
	g_humanReactionMin = CreateConVar("tf_bot_human_reaction_min", "0.12", "Minimum visual reaction delay before a bot accepts a new enemy target.", _, true, 0.02, true, 1.5);
	g_humanReactionMax = CreateConVar("tf_bot_human_reaction_max", "0.42", "Maximum visual reaction delay before a bot accepts a new enemy target.", _, true, 0.02, true, 2.0);
	g_humanMemoryMin = CreateConVar("tf_bot_human_memory_min", "0.65", "Minimum time a bot remembers the last place it saw an enemy.", _, true, 0.0, true, 5.0);
	g_humanMemoryMax = CreateConVar("tf_bot_human_memory_max", "1.85", "Maximum time a bot remembers the last place it saw an enemy.", _, true, 0.0, true, 8.0);
	g_humanTargetLockMin = CreateConVar("tf_bot_human_target_lock_min", "0.80", "Minimum time a bot prefers its current visible target before switching.", _, true, 0.0, true, 5.0);
	g_humanTargetLockMax = CreateConVar("tf_bot_human_target_lock_max", "2.20", "Maximum time a bot prefers its current visible target before switching.", _, true, 0.0, true, 8.0);
	g_botDifficulty = FindConVar("tf_bot_difficulty");

	for (int client = 1; client <= MaxClients; client++)
	{
		ResetHumanAwareness(client);
	}
}

public Action RoundStarted(Handle event, const char[] name, bool dontBroadcast)
{
	Setup = 0;
}

public Action SetupStarted(Handle event, const char[] name, bool dontBroadcast)
{
	Setup = 1;

	for (int client = 1; client <= MaxClients; client++)
	{
		ResetHumanAwareness(client);
	}
}

public Action PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsValidClient(victim) || !IsFakeClient(victim) || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}

	if (!IsHumanAwarenessEnemy(victim, attacker))
	{
		return Plugin_Continue;
	}

	// Damage is a strong awareness cue, including attacks from outside the bot's
	// current field of view, but it still receives a short human reaction delay.
	g_awarenessTarget[victim] = attacker;
	g_awarenessTargetVisible[victim] = false;
	BeginAwarenessReaction(victim, attacker, 0.35);
	RememberAwarenessTarget(victim, attacker);

	return Plugin_Continue;
}

public void OnMapStart()
{
	MapCheck();
		
	// Load Bot Overhaul Config Files
	ServerCommand("exec TF2_Bot_Overhaul.cfg");
	
	CreateTimer(50.0, LongTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(25.0, MediumTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(12.0, ShortTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	BotBegin = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		ResetHumanAwareness(client);
	}
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
	
	// Robot Destruction Gamemode Logic
	if (GetConVarInt(FindConVar("tf_gamemode_rd")) == 1)
	{
		RD = 1;
	}
	else
	{		
		RD = 0;	
	}
	
	// Player Destruction Gamemode Logic
	if (GetConVarInt(FindConVar("tf_gamemode_pd")) == 1)
	{
		PD = 1;
	}
	else
	{		
		PD = 0;	
	}
	
	// MVM Gamemode Check
	if (GetConVarInt(FindConVar("tf_gamemode_mvm")) == 1)
	{
		MVM = 1;
	}
	else
	{		
		MVM = 0;	
	}
}

void moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
}

void moveBackwards(float vel[3],float MaxSpeed)
{
	vel[0] = -MaxSpeed;
}

void moveSide(float vel[3],float MaxSpeed)
{
	vel[1] = MaxSpeed;
}

void moveSide2(float vel[3],float MaxSpeed)
{
	vel[1] = -MaxSpeed;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
 if (CheckTimer == INVALID_HANDLE && slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
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

// TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);  
// 0 // TFWeaponSlot_Primary
// 1 // TFWeaponSlot_Secondary
// 2 // TFWeaponSlot_Melee
//  // TFWeaponSlot_Grenade
// 5 // TFWeaponSlot_Building 
// 3 // TFWeaponSlot_PDA
//  // TFWeaponSlot_Item1
//  // TFWeaponSlot_Item2

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3]) // Stock By Pelipokia
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    newmove[1] = -newmove[1];
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

stock bool TF2_IsNextToWall(int client) // Stock By Pelipokia
{
	float flPos[3];
	GetClientAbsOrigin(client, flPos);
	
	float flMaxs[3], flMins[3];
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", flMaxs);
	GetEntPropVector(client, Prop_Send, "m_vecMins", flMins);
	
	flMaxs[0] += 2.5;
	flMaxs[1] += 2.5;
	flMins[0] -= 2.5;
	flMins[1] -= 2.5;
	
	flPos[2] += 18.0;
	
	//Perform a wall check to see if we are near any obstacles we should try jump over
	Handle TraceRay = TR_TraceHullFilterEx(flPos, flPos, flMins, flMaxs, MASK_PLAYERSOLID, ExcludeFilter, client);
	
	bool bHit = TR_DidHit(TraceRay);	
	
	delete TraceRay;
	
	return bHit;
}

public bool ExcludeFilter(int entity, int contentsMask, any iExclude)
{
    return !(entity == iExclude);
}

public void OnClientPutInServer(int client) 
{
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	ResetHumanAwareness(client);
	
	if(!IsFakeClient(client))
	{
		realplayercount++;
	}
}

// This will make it so you cannot switch from a certain weapon.
// This way we can lock you away from switching.
public Action OnWeaponSwitch(int client, int weapon) 
{
	if (IsValidClient(client) && IsClientInGame(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{		
		// Make sure we calculate ammo so we can switch if we're out!
		int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		int size = GetEntData(client, ammoOffset + 4, 4);
		
		if (ban_primary[client] && IsWeaponSlotActive(client, 0) && size > 0)
		{
			//PrintToChatAll("ban primary switch");
			return Plugin_Handled;
		}
		else if (ban_secondary[client] && IsWeaponSlotActive(client, 1) && size > 0)
		{
			//PrintToChatAll("ban secondary switch");
			return Plugin_Handled;
		}
		else if (ban_melee[client] && IsWeaponSlotActive(client, 2))
		{
			//PrintToChatAll("ban melee switch");
			return Plugin_Handled;
		}
	}
	else
	{
		// Let's ensure these are reset if these conditions aren't met.
		ban_primary[client] = false;
		ban_secondary[client] = false;
		ban_melee[client] = false;
	}
	return Plugin_Continue;
}

public int GetNearestEntity(int client, char[] classnametarget)
{	
	char ClassName[32];	
	float clientOrigin[3];	
	float entityOrigin[3];	
	float distance = -1.0;	
	int nearestEntity = -1;	
	
	for(int x = 0; x <= GetMaxEntities(); x++)	
	{		
		if(IsValidEdict(x) && IsValidEntity(x))		
		{			
			GetEdictClassname(x, ClassName, 32);								
			if(StrContains(ClassName, classnametarget, false) != -1)			
			{				
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);				
				GetClientEyePosition(client, clientOrigin);								
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);				
				if((edict_distance < distance) || (distance == -1.0))				
				{					
					distance = edict_distance;					
					nearestEntity = x;				
				}			
			}		
		}	
	}	
	
	return nearestEntity;
}

public int FindNearestHealth(int client)
{	
	char ClassName[32];	
	float clientOrigin[3];	
	float entityOrigin[3];	
	float distance = -1.0;	
	int nearestEntity = -1;	
	
	for(int x = 0; x <= GetMaxEntities(); x++)	
	{		
		if(IsValidEdict(x) && IsValidEntity(x))		
		{			
			GetEdictClassname(x, ClassName, 32);						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && !HasEntProp(x, Prop_Send, "m_fEffects"))				
				continue;						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && GetEntProp(x, Prop_Send, "m_fEffects") != 0)				
				continue;						
			if(StrContains(ClassName, "item_health", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1 || StrContains(ClassName, "rd_robot_dispenser", false) != -1 || StrContains(ClassName, "pd_dispenser", false) != -1)			
			{				
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);				
				GetClientEyePosition(client, clientOrigin);								
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);				
				if((edict_distance < distance) || (distance == -1.0))				
				{					
					distance = edict_distance;					
					nearestEntity = x;				
				}			
			}		
		}	
	}	
	
	return nearestEntity;
}

public int FindNearestAmmo(int client)
{	
	char ClassName[32];	
	float clientOrigin[3];	
	float entityOrigin[3];	
	float distance = -1.0;	
	int nearestEntity = -1;	
	
	for(int x = 0; x <= GetMaxEntities(); x++)	
	{		
		if(IsValidEdict(x) && IsValidEntity(x))		
		{			
			GetEdictClassname(x, ClassName, 32);						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && !HasEntProp(x, Prop_Send, "m_fEffects"))				
				continue;						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && GetEntProp(x, Prop_Send, "m_fEffects") != 0)				
				continue;						
			if(StrContains(ClassName, "item_ammopack", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1 || StrContains(ClassName, "rd_robot_dispenser", false) != -1 || StrContains(ClassName, "pd_dispenser", false) != -1)			
			{				
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);				
				GetClientEyePosition(client, clientOrigin);								
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);				
				if((edict_distance < distance) || (distance == -1.0))				
				{					
					distance = edict_distance;					
					nearestEntity = x;				
				}			
			}		
		}	
	}	
	
	return nearestEntity;
}

// Bot Shit
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	if(IsValidClient(client))
	{
	
	if(BotBegin == 0)
	{
		BotTimer[client] = GetGameTime() + 1.0;
		BotBegin = 1;
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	if (g_btEnable.IntValue > 0 && BotTimer[client] < GetGameTime())
	{
		// Start disabled and enable once any qualifying human is found.
		// Previously, every later human could overwrite an earlier positive match.
		ImproveAI[client] = false;

		if (IsFakeClient(client))
		{
			// In MvM, all RED bots receive the tweaks as intended.
			if (MVM == 1)
			{
				ImproveAI[client] = GetClientTeam(client) == 2;
			}
			else
			{
				float clientOrigin[3];
				GetClientAbsOrigin(client, clientOrigin);

				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i) || i == client || IsFakeClient(i))
					{
						continue;
					}

					float searchOrigin[3];
					GetClientAbsOrigin(i, searchOrigin);
					float chainDistance = GetVectorDistance(clientOrigin, searchOrigin);

					bool nearbyHuman = chainDistance < 650.0;
					bool visibleEnemy = chainDistance < 1200.0
						&& GetClientTeam(i) != GetClientTeam(client)
						&& IsPointVisible(searchOrigin, clientOrigin);
					bool supportClassNearHuman = chainDistance < 1200.0
						&& (class == TFClass_Medic || class == TFClass_Spy || class == TFClass_Engineer);

					if (nearbyHuman || visibleEnemy || supportClassNearHuman)
					{
						ImproveAI[client] = true;
						break;
					}
				}
			}
		}

		BotTimer[client] = GetGameTime() + 1.0;
	}
			
	if (IsFakeClient(client) && (!IsPlayerAlive(client) || !ImproveAI[client])
		&& (g_humanAnglesInitialized[client] || g_awarenessTarget[client] != -1 || g_awarenessPendingTarget[client] != -1))
	{
		ResetHumanAwareness(client);
	}

	if(g_btEnable.IntValue > 0 && IsFakeClient(client) && IsPlayerAlive(client) && ImproveAI[client] && !TF2_IsPlayerInCondition(client, TFCond_CritOnWin) && GetEntProp(client, Prop_Send, "m_iStunFlags") != TF_STUNFLAGS_LOSERSTATE)
	{
		//PrintToChatAll("BOT IS IMPROVED!");
		
		// GENERAL STUFF!	
		
		// Force Bots to auto ready in MVM!
		if(CheckTimer == INVALID_HANDLE && MVM == 1 && GetClientTeam(client) == 2)
		{
			FakeClientCommand(client, "tournament_player_readystate 1");
		}
	
		// Make bots work better in water.
		int WaterDepth = GetEntProp(client, Prop_Data, "m_nWaterLevel");
		if(WaterDepth >= 2)
		{
			buttons |= IN_JUMP;
		}
		
		// Make bots crouch jump.
		if(GetClientButtons(client) & IN_JUMP)
		{
			if(!(GetEntityFlags(client) & FL_ONGROUND))
			{
				//PrintToChatAll("DUCK!");
				buttons |= IN_DUCK;
			}
		}
		
		//int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		if(GetHealth(client) < (MaxHealth / 1.25))
		{
			//int healthkit = GetNearestEntity(client, "item_healthkit_*"); 
			int healthkit = FindNearestHealth(client);
			
			if(healthkit != -1)
			{
				if(IsValidEntity(healthkit))
				{
					if (GetEntProp(healthkit, Prop_Send, "m_fEffects") != 0)
					{
						return Plugin_Continue;
					}
					
					float clientOrigin[3];
					float healthkitorigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(healthkit, Prop_Send, "m_vecOrigin", healthkitorigin);
					
					clientOrigin[2] += 5.0;
					healthkitorigin[2] += 5.0;
					
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, healthkitorigin);
					
					if(chainDistance < 350 && IsPointVisible(clientOrigin, healthkitorigin) && healthkitorigin[2] < clientOrigin[2] + 50)
					{
						MedkitNear[client] = true;
						TF2_MoveTo(client, healthkitorigin, vel, angles);
					}
					else
					{
						MedkitNear[client] = false;
					}
				}
			}
		}
		else
		{
			MedkitNear[client] = false;
		}
		
		int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		int size = GetEntData(client, ammoOffset + 4, 4);
		if(size < 13)
		{
			//int ammokit = GetNearestEntity(client, "item_ammopack_*"); 		
			int ammokit = FindNearestAmmo(client);
				
			if(ammokit != -1)
			{
				if(IsValidEntity(ammokit))
				{
					if (GetEntProp(ammokit, Prop_Send, "m_fEffects") != 0)
					{
						return Plugin_Continue;
					}
		
					float clientOrigin[3];
					float ammokitorigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(ammokit, Prop_Send, "m_vecOrigin", ammokitorigin);
					
					clientOrigin[2] += 5.0;
					ammokitorigin[2] += 5.0;
					
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, ammokitorigin);
					
					if(chainDistance < 350 && IsPointVisible(clientOrigin, ammokitorigin) && ammokitorigin[2] < clientOrigin[2] + 50)
					{
						TF2_MoveTo(client, ammokitorigin, vel, angles);
					}
				}
			}
		}

		float clientEyes[3];
		GetClientEyePosition(client, clientEyes);
		int Ent = UpdateHumanAwareness(client);

		if(IsValidEntity(Ent))
		{
			TFClassType otherclass = TF2_GetPlayerClass(Ent);
			if (class != TFClass_Medic && class != TFClass_Engineer && otherclass != TFClass_Spy)
			{
				float clientOrigin[3];
				float searchOrigin[3];
				GetClientAbsOrigin(Ent, searchOrigin);
				GetClientAbsOrigin(client, clientOrigin);
				float chainDistance;
				chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
				if (chainDistance < 1000.0 && IsTargetInSightRange(client, Ent) && searchOrigin[2] < clientOrigin[2] + 115)
				{	
					// Melee overrides all! If we're doing melee to begin with we're basically on a suicide mission.
					// Let's also check for uber while we're at it. We shouldn't be scared while we're ubered. We should get agressive!
					if(IsWeaponSlotActive(client, 2) || TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
					{
						//PrintToChatAll("MELEE ATTACK!");
						
						TF2_MoveTo(client, searchOrigin, vel, angles);
						
						// Make sure bot doesn't get stuck when trying to attack.
						if(chainDistance > 150.0 && TF2_IsNextToWall(client))
						{
							//PrintToChatAll("JUMP!");
							buttons |= IN_JUMP;
						}
						
						// Make bots only attack with melee up close! Works better with demoknights!
						if(IsWeaponSlotActive(client, 2) && chainDistance > 125.0)
						{
							if(buttons & IN_ATTACK)
							{
								buttons &= ~IN_ATTACK;
							}
						}
					}
					// Things that scare us and make us retreat! These tend to be more important than the buffs we get so it takes priority.
					else if (TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Jarated) || TF2_IsPlayerInCondition(client, TFCond_Bleeding) || TF2_IsPlayerInCondition(client, TFCond_Milked) || TF2_IsPlayerInCondition(client, TFCond_HalloweenBombHead) || TF2_IsPlayerInCondition(client, TFCond_Gas) || TF2_IsPlayerInCondition(Ent, TFCond_Ubercharged) && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || TF2_IsPlayerInCondition(Ent, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(Ent, TFCond_Buffed) || TF2_IsPlayerInCondition(Ent, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(Ent, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(Ent, TFCond_CritOnKill) || TF2_IsPlayerInCondition(Ent, TFCond_CritMmmph) || TF2_IsPlayerInCondition(Ent, TFCond_CritOnDamage) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || GetEntProp(client, Prop_Send, "m_iStunFlags") == TF_STUNFLAGS_LOSERSTATE || GetEntProp(client, Prop_Send, "m_iStunFlags") == TF_STUNFLAGS_GHOSTSCARE)
					{
						if (class == TFClass_Pyro && TF2_IsPlayerInCondition(Ent, TFCond_Ubercharged))
						{
							TF2_MoveTo(client, searchOrigin, vel, angles);
							if (chainDistance < 250.0)
							{
									buttons = buttons | IN_ATTACK2;
							}
							
							// Make sure bot doesn't get stuck when trying to attack.
							if(TF2_IsNextToWall(client))
							{
								//PrintToChatAll("JUMP!");
								buttons |= IN_JUMP;
							}
						}
						else if(!IsWeaponSlotActive(Ent, 2))
						{
							if (class == TFClass_Spy && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons = buttons | IN_ATTACK2;
							}
							moveBackwards(vel, 300.0);
							//PrintToChatAll("backup");
						}
					}
					// Things that make us push forward!
					else if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_Buffed) || TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed) || TF2_IsPlayerInCondition(client, TFCond_RegenBuffed) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) || TF2_IsPlayerInCondition(client, TFCond_KnockedIntoAir) || TF2_IsPlayerInCondition(Ent, TFCond_Bonked) || TF2_IsPlayerInCondition(Ent, TFCond_OnFire) || TF2_IsPlayerInCondition(Ent, TFCond_Jarated) || TF2_IsPlayerInCondition(Ent, TFCond_Bleeding) || TF2_IsPlayerInCondition(Ent, TFCond_Milked) || TF2_IsPlayerInCondition(Ent, TFCond_MarkedForDeath) || TF2_IsPlayerInCondition(Ent, TFCond_MarkedForDeathSilent) || TF2_IsPlayerInCondition(Ent, TFCond_Gas) || (class == TFClass_Scout && otherclass != TFClass_Pyro && chainDistance < 800.0 && GetHealth(client) > 65.0 && IsWeaponSlotActive(client, 0)) || (class == TFClass_Heavy && chainDistance < 550.0 && TF2_IsPlayerInCondition(client, TFCond_Overhealed)))
					{
						if (GetHealth(client) > (MaxHealth / 1.5) && class != TFClass_Spy && class != TFClass_Medic && class != TFClass_Engineer && class != TFClass_Sniper) // Let's let spies not run into battle and stay stealthy.
						{
							TF2_MoveTo(client, searchOrigin, vel, angles);
							
							// Make sure bot doesn't get stuck when trying to attack.
							if(TF2_IsNextToWall(client))
							{
								//PrintToChatAll("JUMP!");
								buttons |= IN_JUMP;
							}
						}
					}
				}
			}
	
			// Make bots work better with throwable weapons.
			// Let's check for classes that actually use them first.
			// Soldier's backpacks are handled elsewhere.
			if (CheckTimer == INVALID_HANDLE && class == TFClass_Scout || class == TFClass_Sniper || class == TFClass_Pyro)
			{
				char BotWeapon[32];
				GetClientWeapon(client, BotWeapon, 32);
			
				if (StrEqual(BotWeapon, "tf_weapon_jar_milk", true) || StrEqual(BotWeapon, "tf_weapon_cleaver", true) || StrEqual(BotWeapon, "tf_weapon_jar_gas", true) || StrEqual(BotWeapon, "tf_weapon_jar", true))
				{
					int secondary = GetPlayerWeaponSlot(client, 1); 
					float regen = GetEntPropFloat(secondary, Prop_Send, "m_flEffectBarRegenTime");
				
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
				
					if (regen != 0)
					{
						//TF2_RemoveWeaponSlot(client, 1); // Might not have to resort to this.
						ban_primary[client] = true; // Ensure they switch back to primary.
						TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); // Ensure they switch back to primary.
						ban_primary[client] = false; // Ensure they switch back to primary.
						//PrintToChatAll("thrown weapon : %f", regen);
					}
					// Force bots to throw it if they should.
					else if(TF2_IsPlayerInCondition(client, TFCond_OnFire) && !StrEqual(BotWeapon, "tf_weapon_cleaver", true))
					{
						TF2_LookAtPos(client, clientOrigin, 0.75);
						buttons |= IN_ATTACK;
					}
					else
					{
						int Ent_Team = Client_GetClosest_Team(clientEyes, client);
						if(IsValidEntity(Ent_Team))
						{
							float clientOrigin2[3];
							float searchOrigin2[3];
							GetClientAbsOrigin(Ent_Team, searchOrigin2);
							GetClientAbsOrigin(client, clientOrigin2);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin2, searchOrigin2);
					
							// Put out teammates that are on fire.
							if(chainDistance < 850.0 && IsTargetInSightRange(client, Ent) || chainDistance2 < 850.0 && TF2_IsPlayerInCondition(Ent_Team, TFCond_OnFire) && IsTargetInSightRange(client, Ent_Team) && !StrEqual(BotWeapon, "tf_weapon_cleaver", true))
							{
								buttons |= IN_ATTACK;
							}
						}
					}
				}
			}
		}
		
		// Make bots randomly spy check nearby spies. 
		// This is sorta cheating but will feel more realistic.
		// This will only come into effect on expert difficulty.
		if (g_botDifficulty != null
			&& g_botDifficulty.IntValue == 3
			&& (Payload == 0 || Setup == 0))
		{
			if(SpyTimer == INVALID_HANDLE && class != TFClass_Heavy && class != TFClass_Engineer && class != TFClass_Spy && class != TFClass_Sniper && class != TFClass_Medic)
			{	
				int EntSpy = Client_GetClosest_SPY(clientEyes, client);
				//PrintToChatAll("Spy"); 
				if(IsValidEntity(EntSpy) && !IsFakeClient(EntSpy) && TF2_GetPlayerClass(EntSpy) == TFClass_Spy && !TF2_IsPlayerInCondition(EntSpy, TFCond_Cloaked) && GetClientTeam(EntSpy) != GetClientTeam(client) && TF2_IsPlayerInCondition(EntSpy, TFCond_Disguised))
				{
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(EntSpy, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
						
					if(chainDistance < 150 && searchOrigin[2] < clientOrigin[2] + 115)
					{
						int disguiseclass = GetEntProp(EntSpy, Prop_Send, "m_nDisguiseClass");
						int disguisetarget = GetEntProp(EntSpy, Prop_Send, "m_iDisguiseTargetIndex");
						
						//PrintToChatAll("Spy Disguised As: %i", disguiseclass); 
						//PrintToChatAll("Spy Disguised As: %i", disguisetarget); 
					
						// If its a medic or scout then bots will be more likely to attack. (and pretty much guaranteed if you disguise as the bot itself)
						if(IsTargetInSightRange(client, EntSpy) && class == TFClass_Pyro || IsTargetInSightRange(client, EntSpy) && disguisetarget == client && disguiseclass == class || IsTargetInSightRange(client, EntSpy) && disguiseclass == 1 && IsClientMoving(EntSpy) || IsTargetInSightRange(client, EntSpy) && disguiseclass == 5)
						{
							SpyAttack[client] = true;
							float SpyValue = GetRandomFloat(6.0, 12.0);
							CreateTimer(SpyValue, ResetSpyTimer2);
						}
					
						// If spy is sus then attack.
						if (SpyAttack[client])
						{
							//PrintToChatAll("Attack Spy");
							TF2_LookAtPos(client, searchOrigin, 0.65);
							
							buttons |= IN_ATTACK;
							//FakeClientCommand(client, "voicemenu 1 1");
								
							// Only advance if spy is on equal ground.
							if(searchOrigin[2] < clientOrigin[2] + 115)
							{
								TF2_MoveTo(client, searchOrigin, vel, angles);
								
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToChatAll("JUMP!");
									buttons |= IN_JUMP;
								}
							}
						}
					}
				}  
			}
			else
			{
				SpyAttack[client] = false;
			}
		}
		
		// Showin added a few more classes that likely won't see much benefit from this.
		// Also added a check to make sure the enemy is actually attacking so they don't just randomly jump.
		// From Marqueritte's Bot Combat Improvements
		if(class != TFClass_Spy && class != TFClass_Engineer && class != TFClass_Sniper && class != TFClass_Medic && GetClientButtons(client) & 1)
		{	
			// Modification of old script where bots jump in combat.
			if(!IsWeaponSlotActive(client, 2) && g_flJumpTimer[client] < GetGameTime())
			{
				buttons |= IN_JUMP;
				buttons &= ~IN_DUCK;
				g_flJumpTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
			}
				
			if(g_flDuckTimer[client] < GetGameTime())
			{
				buttons |= IN_DUCK;
				g_flDuckTimer[client] = GetGameTime() + 25.0;		
			}
		}
		
		// GAMEMODE STUFF
		if(RD != 0)
		{
			// ROBOT DESTRUCTION LOGIC
			// TO DO! MAKE BOTS SHOOT AT ROBOTS USING CODE SO THEY DO IT MORE OFTEN!
			
			int item_bonuspack = GetNearestEntity(client, "item_bonuspack"); 
			
			if(item_bonuspack != -1)
			{
				if(IsValidEntity(item_bonuspack))
				{	
					if (GetEntProp(item_bonuspack, Prop_Send, "m_nSkin") != GetClientTeam(client))
					{
						return Plugin_Continue;
					}
					
					float clientOrigin[3];
					float item_bonuspackorigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(item_bonuspack, Prop_Send, "m_vecOrigin", item_bonuspackorigin);
					
					clientOrigin[2] += 5.0;
					item_bonuspackorigin[2] += 5.0;
					
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, item_bonuspackorigin);
					
					if(chainDistance < 750 && IsPointVisible(clientOrigin, item_bonuspackorigin) && item_bonuspackorigin[2] < clientOrigin[2] + 50)
					{
						TF2_MoveTo(client, item_bonuspackorigin, vel, angles);
						
						// Make sure bot doesn't get stuck when trying to attack.
						if(TF2_IsNextToWall(client))
						{
							//PrintToChatAll("JUMP!");
							buttons |= IN_JUMP;
						}
					}
				}
			}
		}
		else if(PD != 0)
		{
			// PLAYER DESTRUCTION LOGIC
			// GET CODE FROM PD PLUGIN TO MAKE THEM CAP AND SHIT!
			// ADD PRINT TO CHAT TO MAKE SURE ITS WORKING!
			
			int item_teamflag = GetNearestEntity(client, "item_teamflag"); 
			int func_capturezone = GetNearestEntity(client, "func_capturezone"); 
			
			if(item_teamflag != -1 && func_capturezone != -1)
			{
				if(IsValidEntity(item_teamflag) && IsValidEntity(func_capturezone))
				{	
					float clientOrigin[3];
					float item_teamflagorigin[3];
					float func_capturezoneorigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(item_teamflag, Prop_Send, "m_vecOrigin", item_teamflagorigin);
					GetEntPropVector(func_capturezone, Prop_Send, "m_vecOrigin", func_capturezoneorigin);
					
					clientOrigin[2] += 5.0;
					item_teamflagorigin[2] += 5.0;
					func_capturezoneorigin[2] += 5.0;
					
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, item_teamflagorigin);
					float chainDistance2;
					chainDistance2 = GetVectorDistance(clientOrigin, func_capturezoneorigin);
					
					if(chainDistance < 750 && IsPointVisible(clientOrigin, item_teamflagorigin) && item_teamflagorigin[2] < clientOrigin[2] + 50)
					{
						TF2_MoveTo(client, item_teamflagorigin, vel, angles);
						
						// Make sure bot doesn't get stuck when trying to attack.
						if(TF2_IsNextToWall(client))
						{
							//PrintToChatAll("JUMP!");
							buttons |= IN_JUMP;
						}
					}
					else if(chainDistance2 < 750 && IsPointVisible(clientOrigin, func_capturezoneorigin) && func_capturezoneorigin[2] < clientOrigin[2] + 50)
					{
						TF2_MoveTo(client, func_capturezoneorigin, vel, angles);
						
						// Make sure bot doesn't get stuck when trying to attack.
						if(TF2_IsNextToWall(client))
						{
							//PrintToChatAll("JUMP!");
							buttons |= IN_JUMP;
						}
					}
				}
			}
		}

		// CLASS SPECIFIC STUFF
		switch (class)
		{
			// HEAVY STUFF!
			case TFClass_Heavy:
			{	
				if (IsWeaponSlotActive(client, 0) && TF2_IsPlayerInCondition(client, TFCond_Slowed))
				{
					//int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
					//int size = GetEntData(client, ammoOffset + 4, 4);
					//PrintToChatAll("clip size : %i", size);
					if(size > 0)
					{
						// If heavy is low on health retreat.
						if(GetHealth(client) < 150)
						{
							moveBackwards(vel, 230.0);
						}
					}
					else
					{
						// Make Heavy bots not bug out and keep shooting when they have no ammo.
						buttons &= ~IN_ATTACK;
						buttons &= ~IN_ATTACK2;
						//TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
						//TF2_RemoveCondition(client, TFCond_MeleeOnly);
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
					}
				}
			
				// This will make heavy bots use the their opportunistic melees.
				// First lets make sure we're not in ctf where heavys defend a lot and we're not currently in combat.
				if(CheckTimer == INVALID_HANDLE && GetConVarInt(FindConVar("tf_gamemode_ctf")) == 0 && !TF2_IsPlayerInCondition(client, TFCond_Slowed))
				{
					if(IsValidClient(Ent))
					{
						float clientOrigin[3];
						float searchOrigin[3];
						GetClientAbsOrigin(Ent, searchOrigin);
						GetClientAbsOrigin(client, clientOrigin);
					
						float chainDistance;
						chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
						int index = GetPlayerWeaponSlot(client, 2);
				
						if(IsValidEntity(index))
						{		
							// Make Heavy bots use GRU / Fists Of Steel / Eviction Notice buffs
							if (239 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 426 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 331 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 1084 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 1100 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex"))
							{ 	 
								if(chainDistance > 3500.0 && IsWeaponSlotActive(client, 0) && IsClientMoving(client))
								{
									//PrintToChatAll("GRU!");
									//TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
									ban_melee[client] = true;
									//TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
									//TF2_RemoveCondition(client, TFCond_MeleeOnly);
									TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
								}
								else if(IsWeaponSlotActive(client, 2) && chainDistance < 3500.0)
								{
								//TF2_RemoveCondition(client, TFCond_RestrictToMelee);
									ban_melee[client] = false;
									TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
								}
							}
						}
					}
				}
			}
				
			// MEDIC STUFF!			
			case TFClass_Medic:
			{
				int Ent_Both = Client_GetClosest_Both(clientEyes, client);
				
				// I guess we have to make absolutely sure this is a medigun to avoid issues.
				// Some people crashed when we didn't make 100% sure it was a medigun!
				char medigun_check[20];
				GetClientWeapon(client, medigun_check, 20);
				
				//PrintToChatAll("weapon : %s", medigun_check);
				
				if (IsValidClient(Ent_Both))
				{	
					TFClassType otherclass = TF2_GetPlayerClass(Ent_Both);
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent_Both, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
						
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
					
					int medigun = GetPlayerWeaponSlot(client, 1); // For some reason people crashed cuz of this. So we gotta be more specific.

					
					if(GetClientTeam(Ent_Both) == GetClientTeam(client) && IsWeaponSlotActive(client, 1))
					{ 
						
						// Force medic bots to help humans over everyone else!
						if(!IsFakeClient(Ent_Both) && chainDistance < 750.0 && otherclass != TFClass_Spy && GetHealth(Ent_Both) < (GetEntProp(Ent_Both, Prop_Data, "m_iMaxHealth") / 1.65))
						{
							// Make Medic bots heal hurt teammates if they're close!
							TF2_LookAtPos(client, searchOrigin, 2.0); // Make it slow so its less snappy.
							//TF2_MoveTo(client, searchOrigin, vel, angles);
							//PrintToChatAll("Heal Hurt Players!"); 
						}
						// If a player nearby is hurt lets do a quick check up on em.
						else if(chainDistance < 750.0 && otherclass != TFClass_Spy && GetHealth(Ent_Both) < (GetEntProp(Ent_Both, Prop_Data, "m_iMaxHealth") / 1.65))
						{
							// Make Medic bots heal hurt teammates if they're close!
							TF2_LookAtPos(client, searchOrigin, 2.0);
							//TF2_MoveTo(client, searchOrigin, vel, angles);
							//PrintToChatAll("Heal Hurt Players!"); 
						}
						// Stop medic from getting stuck. (a bug that makes them freeze up) Make him move forward if he's getting far away.
						else if(StrEqual(medigun_check, "tf_weapon_medigun") && GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == Ent_Both && !MedkitNear[client])
						{
							//PrintToChatAll("realplayercount: %i", realplayercount);
							// If player isn't looking then teleport medic. (singleplayer only)
							if(realplayercount == 1 && !IsFakeClient(Ent_Both) && TF2_GetPlayerClass(Ent_Both) != TFClass_Scout && GetEntityFlags(Ent_Both) & FL_ONGROUND && chainDistance > 300.0 && !IsTargetInSightRange(Ent_Both, client))
							{	
								TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 15.0);

								if(chainDistance > 425.0 && IsTargetInSightRange(client, Ent_Both) && searchOrigin[2] < clientOrigin[2] + 115)
								{
									TF2_MoveTo(client, searchOrigin, vel, angles);
								}
								else if(chainDistance > 425.0)
								{
									//PrintToChatAll("TELEPORT");
									float TeleportOrigin[3];
									TeleportOrigin[0] = searchOrigin[0];
									TeleportOrigin[1] = searchOrigin[1];
									TeleportOrigin[2] = (searchOrigin[2] + 75);
									TeleportEntity(client, searchOrigin, NULL_VECTOR, NULL_VECTOR);
								}
							}
							else if(realplayercount >= 1 && !IsFakeClient(Ent_Both) && TF2_IsPlayerInCondition(client, TFCond_HalloweenSpeedBoost))
							{
								TF2_RemoveCondition(client, TFCond_HalloweenSpeedBoost);
							}
							else if(chainDistance > 425.0 && IsTargetInSightRange(client, Ent_Both) && searchOrigin[2] < clientOrigin[2] + 115)
							{
								TF2_MoveTo(client, searchOrigin, vel, angles);
								
								//PrintToChatAll("Follow Players!");
								//PrintToChatAll("Patient: %i", GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget"));
							}
						}

						if(StrEqual(medigun_check, "tf_weapon_medigun") && GetEntProp(medigun, Prop_Send, "m_bHealing") != 1)
						{
							//PrintToChatAll("Heal!");
							buttons |= IN_ATTACK;
						}
						else
						{
							if(chainDistance < 250.0)
							{
								if(g_flJumpTimer[client] < GetGameTime())
								{
									buttons |= IN_JUMP;
									g_flJumpTimer[client] = GetGameTime() + GetRandomFloat(1.0, 6.0);
									//PrintToChatAll("Jump!");
								}

								if(StrEqual(medigun_check, "tf_weapon_medigun") && GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == Ent_Both)
								{
									if(GetClientButtons(Ent_Both) & IN_JUMP)
									{
										buttons |= IN_JUMP;
									}
									// Will not Duck if Enemy is target(3.4)
									if(GetClientButtons(Ent_Both) & IN_DUCK)
									{
										buttons |= IN_DUCK;
									}
								}
							}
						}
					}
					// Make medic attack close players with his melee!
					else if (StrEqual(medigun_check, "tf_weapon_medigun") && GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") >= 9.0 && IsTargetInSightRange(client, Ent_Both) && chainDistance < 150.0 && otherclass != TFClass_Pyro && !MedkitNear[client] || !IsWeaponSlotActive(client, 1) && IsTargetInSightRange(client, Ent_Both) && chainDistance < 150.0 && otherclass != TFClass_Pyro && !MedkitNear[client])
					{
						moveSide(vel,300.0);
						moveForward(vel,300.0);
						ban_secondary[client] = false;
						ban_melee[client] = true;
						//TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
						//TF2_RemoveCondition(client, TFCond_MeleeOnly);
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
						buttons |= IN_ATTACK;
					}
					// Make Medic switch to heal if he's near a friendly player and isn't doing so already.
					else if (GetClientTeam(Ent_Both) == GetClientTeam(client) && IsTargetInSightRange(client, Ent_Both) && chainDistance < 400.0 && otherclass != TFClass_Spy)
					{	
						ban_melee[client] = false;
						ban_secondary[client] = true;
						TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary);
					}
					else
					{
						ban_melee[client] = false;
						ban_secondary[client] = false;
					}
				}
			}
			
			// SPY STUFF!
			case TFClass_Spy:
			{
				// Get watch type.
				int watch = GetPlayerWeaponSlot(client, 4); 
				
				// If a spy bot is dead ringing then make sure he stays cloaked.
				if(IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					if(buttons & IN_ATTACK2)
					{
						buttons &= ~IN_ATTACK2;
					}
				}
				
				// Make spys always backstab if they can!
				if(CheckTimer == INVALID_HANDLE && IsWeaponSlotActive(client, 2) && GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab"))
				{
					buttons |= IN_ATTACK;
				}

				// Make spy bots always sap enemy buildings!
				int EnemyBuilding = GetNearestEntity(client, "obj_sentrygun");
				if(EnemyBuilding != -1 && !MedkitNear[client])
				{
					if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
					{
						float clientOrigin[3];
						float enemysentryOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
				
						clientOrigin[2] += 50.0;

						float camangle[3];
						float fEntityLocation[3];
						float vec[3];
						float angle[3];
						GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
						GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
						fEntityLocation[2] += 35.0;
						MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;
						ClampAngle(camangle);
					
						int iBuildingIsSapped = GetEntProp(EnemyBuilding, Prop_Send, "m_bHasSapper");
						//int iBuildingHealth = GetEntProp(EnemyBuilding, Prop_Send, "m_iHealth");
						int IBuildingBuilded = GetEntProp(EnemyBuilding, Prop_Send, "m_iState");
						//PrintToChatAll("Building Mode : %i", IBuildingBuilded);
						if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 250.0 && IBuildingBuilded != 0 && iBuildingIsSapped == 0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && enemysentryOrigin[2] < clientOrigin[2] + 50)
						{
							SapTime[client] = true;
							ban_secondary[client] = true;
							TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
							if(CheckTimer == INVALID_HANDLE)
							{
								FakeClientCommand(client, "build 3 0");
							}
							
							TF2_LookAtPos(client, enemysentryOrigin, 0.08);
							TF2_MoveTo(client, enemysentryOrigin, vel, angles);
							//	PrintToChatAll("SAP TIME!");
							if(IsWeaponSlotActive(client, 1))
							{
								buttons |= IN_ATTACK;
							//	PrintToChatAll("SAP SPAM!");
							}
							// If the spy is near it but still has yet to sap (due to bugs) then sap it automatically.
							//if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 250.0 && iBuildingIsSapped == 0)
							//{
							//	iBuildingIsSapped = 1;
							//	PrintToChatAll("FORCE SAP!");
							//}
							
							// Make dead ringer spies put it away for the sap!
							if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
							{
								buttons |= IN_ATTACK2;
							}
							
							// Make sure bot doesn't get stuck when trying to attack.
							if(TF2_IsNextToWall(client))
							{
								//PrintToChatAll("JUMP!");
								buttons |= IN_JUMP;
							}
						}
						else if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 1000.0 && IBuildingBuilded != 0 && iBuildingIsSapped == 0)
						{
							SapTime[client] = true;
							ban_secondary[client] = false;
						}
						else
						{
							SapTime[client] = false;
							ban_secondary[client] = false;
						}
					}
					else
					{
						SapTime[client] = false;
						ban_secondary[client] = false;
					}
				}
				else
				{
					SapTime[client] = false;
					ban_secondary[client] = false;
				}

				// Make spys always go for the stab!
				if(IsValidClient(Ent) && !SapTime[client] && GetHealth(client) > (MaxHealth / 1.75) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !MedkitNear[client])
				{		
					TFClassType otherclass = TF2_GetPlayerClass(Ent);
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
				
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
					
					// float camangle[3], float clientEyes[3], float fEntityLocation[3];
					GetClientEyePosition(Ent, clientEyes);
					
					// Make them fire their weapon if this is a panic situation!
					// Otherwise keep it on the down low.
					if (IsTargetInSightRange(client, Ent) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsWeaponSlotActive(client, 0))
					{
						TF2_LookAtPos(client, searchOrigin, 0.08);
						buttons |= IN_ATTACK;
					}
					else if (IsTargetInSightRange(Ent, client) && IsTargetInSightRange(client, Ent) && TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetHealth(client) < (MaxHealth / 1.25) && IsWeaponSlotActive(client, 0))
					{
						TF2_LookAtPos(client, searchOrigin, 0.08);
						buttons |= IN_ATTACK;
					}
					else if (IsWeaponSlotActive(client, 0))
					{
						buttons &= ~IN_ATTACK;
					}

					if(otherclass != TFClass_Pyro && chainDistance < 1000.0)
					{
						//PrintToChatAll("FOLLOW!");
						if(!IsTargetInSightRange(Ent, client) && IsTargetInSightRange(client, Ent) && searchOrigin[2] < clientOrigin[2] + 115)
						{
							TF2_LookAtPos(client, searchOrigin, 0.08);
							ban_melee[client] = true;
							ban_primary[client] = false;
							TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
							
							if(chainDistance < 150.0)
							{
								// Thanks to Pelipoika for this part.
								float flBotAng[3], flTargetAng[3];
								GetClientEyeAngles(client, flBotAng);
								GetClientEyeAngles(Ent, flTargetAng);
								int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);

								if(iAngleDiff > 70)
								{
									//Move right
									moveSide(vel,300.0);
								}
								else if(iAngleDiff < -70)
								{
									//Move left
									moveSide2(vel,300.0);
								}
							}
							else
							{
								TF2_MoveTo(client, searchOrigin, vel, angles);
								
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToChatAll("JUMP!");
									buttons |= IN_JUMP;
								}
							}
						}
						else if(IsTargetInSightRange(Ent, client) && IsTargetInSightRange(client, Ent))
						{						
							if(chainDistance < 300.0 && searchOrigin[2] < clientOrigin[2] + 115)
							{
								if(chainDistance > 50.0)
								{
									moveForward(vel,300.0);
								}
								else
								{
									moveBackwards(vel,300.0);
								}
									
								// Thanks to Pelipoika for this part.
								float flBotAng[3], flTargetAng[3];
								GetClientEyeAngles(client, flBotAng);
								GetClientEyeAngles(Ent, flTargetAng);
								int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);

								if(iAngleDiff > 90)
								{
									//Move right
									moveSide(vel,300.0);
								}
								else if(iAngleDiff < -90)
								{
									//Move left
									moveSide2(vel,300.0);
								}
									
								ban_melee[client] = false;
								ban_primary[client] = true;
								TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
								TF2_LookAtPos(client, searchOrigin, 0.08);
								//buttons |= IN_ATTACK;
								
									
								//PrintToChatAll("DEADRING: %i", GetEntProp(client, Prop_Send, "m_bFeignDeathReady"));
									
								// Make dead ringer spies put it away for the stab!
								if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
								{
									buttons |= IN_ATTACK2;
								}
								else
								{
									// Spy bots should stay dedicated to the fight at this point.
									// Normally they would shoot once and instantly cloak.
									if(buttons & IN_ATTACK2)
									{
										buttons &= ~IN_ATTACK2;
									}
								}
							}		
							else
							{
								TF2_MoveTo(client, searchOrigin, vel, angles);	
								ban_melee[client] = false;
								ban_primary[client] = true;
								TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
									
								//PrintToChatAll("DEADRING: %i", GetEntProp(client, Prop_Send, "m_bFeignDeathReady"));
									
								// Make dead ringer spies take their dead ringer out.
								if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 0)
								{
									buttons |= IN_ATTACK2;
								}		
								
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToChatAll("JUMP!");
									buttons |= IN_JUMP;
								}
							}
						}
					}
					else
					{
						ban_melee[client] = false;
						ban_primary[client] = false;
					}
				}
				else
				{
					ban_melee[client] = false;
					ban_primary[client] = false;
				}
			}

			// DEMOMAN STUFF!
			case TFClass_DemoMan:
			{
				// If Demo has a shield then continue!
				int index = GetPlayerWeaponSlot(client, 1);
				if(IsValidEntity(index))
				{
					if (131 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 406 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 1099 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") || 1144 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex"))
					{ 	 
						if(IsValidClient(Ent))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(Ent, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
	
							float chainDistance;
							chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
								
							if(!IsTargetInSightRange(client, Ent) || TF2_IsPlayerInCondition(Ent, TFCond_Ubercharged))
							{
								if(buttons & IN_ATTACK2)
								{
									buttons &= ~IN_ATTACK2;
								}
							}
							else if(chainDistance < 800.0 && searchOrigin[2] < clientOrigin[2] + 115)
							{
								// Demo can attack with shield!
								// Force them to do it because they might bug out and do nothing.
								buttons = buttons | IN_ATTACK2;
							}
						}
					}
					// Demoman Sticky Bomb Behavior!
					else if(CheckTimer == INVALID_HANDLE)
					{
						// Make Demomen automatically detonate sticky bombs. (by EfeDursun125)
						int iSticky = -1; 	
						while((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != INVALID_ENT_REFERENCE)
						{
							if(IsValidEntity(iSticky) && IsValidEntity(Ent) && IsClientInGame(Ent) && IsPlayerAlive(Ent) && Ent != client && IsTargetInSightRange(client, Ent))
							{
								float clientOrigin[3];
								float stickyOrigin[3];
								float searchOrigin[3];
								GetClientAbsOrigin(client, clientOrigin);
								GetClientAbsOrigin(Ent, searchOrigin);
								GetEntPropVector(iSticky, Prop_Send, "m_vecOrigin", stickyOrigin);
								
								// Enemy is close to my stickies!
								if(GetVectorDistance(stickyOrigin, searchOrigin) < 160.0)
								{
									//PrintToChatAll("KABOOM!");
									// If Demo is close to his stickies too then try to get away first. 
									if(GetVectorDistance(stickyOrigin, clientOrigin) < 120.0)
									{
										moveBackwards(vel,300.0);
										if(GetEntPropEnt(iSticky, Prop_Send, "m_hThrower") == client)
										{
											buttons |= IN_ATTACK2;
										}
									}
									else if(GetEntPropEnt(iSticky, Prop_Send, "m_hThrower") == client)
									{
										buttons |= IN_ATTACK2;
									}
								}
							}
						}
						
						// Make Demoman Sticky Spam!
						// Modified from Marqueritte's Bot Combat Improvements.
						if(IsValidEntity(Ent) && IsWeaponSlotActive(client, 1))
						{
							float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(Ent, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);
							float StickyDistance;
							StickyDistance = GetVectorDistance(clientOrigin, searchOrigin);
							
							float targetEyes3[3];
							GetClientAbsOrigin(Ent, targetEyes3);
						
							//PrintToChatAll("SPAM TIME!");
							
							if(IsTargetInSightRange(client, Ent))
							{
								if(StickyDistance < 500)
								{
									targetEyes3[2] += 25.0;
									buttons |= IN_ATTACK;
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
								else if(StickyDistance > 500 && StickyDistance < 750)
								{
									targetEyes3[2] += 50.0;
									buttons |= IN_ATTACK;
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
								else if(StickyDistance > 750 && StickyDistance < 1000)
								{
									targetEyes3[2] += 100.0;
									buttons |= IN_ATTACK;
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
								else if(StickyDistance > 1000 && StickyDistance < 1250)
								{
									targetEyes3[2] += 150.0;
									buttons |= IN_ATTACK;
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
								else if(StickyDistance > 1250 && StickyDistance < 1500)
								{
									targetEyes3[2] += 200.0;
									buttons |= IN_ATTACK;
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
								else if(StickyDistance > 1500)
								{
									targetEyes3[2] += 250.0;
									buttons |= IN_ATTACK;
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
							}
							else
							{
								// Allow demo to switch back.
								ban_secondary[client] = false;
								// Messes when he intentionally uses sticky traps.
								// He should technically switch back after he does those anyways probably.
								// So demo should still eventually go back to primary.
								//TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
							}
						}
					}
					
					// If Demo runs out of primary clip then switch to stickies!
					if(CheckTimer == INVALID_HANDLE && IsWeaponSlotActive(client, 0) && IsValidEntity(Ent) && IsTargetInSightRange(client, Ent))
					{
						int clipsize = -1;
						weapon = GetPlayerWeaponSlot(client, 0); 
						int AmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
						if(IsValidEntity(weapon))
						{
							clipsize = GetEntData(weapon, AmmoTable, 4);
						}
						
						if(clipsize <= 0)
						{
							ban_secondary[client] = true;
							TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
						}
					}
				}
			}
		
			// PYRO STUFF!
			case TFClass_Pyro:
			{	
				// If Pyro sees a teammate on fire then airblast them to help them out.
				int Ent_Team = Client_GetClosest_Team(clientEyes, client);
				if(IsValidClient(Ent_Team))
				{			
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent_Team, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
				
					int index = GetPlayerWeaponSlot(client, 0);
					int index2 = GetPlayerWeaponSlot(client, 1);
					
					// If Pyro is using phlog then taunt when he has full rage.
					// Also check to see if he's around any enemies.
					if (CheckTimer == INVALID_HANDLE && 594 == GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") && 100.0 == GetEntPropFloat(client, Prop_Send, "m_flRageMeter") && chainDistance < 1500 && chainDistance > 750)
					{
						FakeClientCommand(client, "taunt");
					}
					
					if(IsValidEntity(index) && IsValidEntity(index2))
					{
						if (594 != GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") && TF2_IsPlayerInCondition(Ent_Team, TFCond_OnFire) || 595 == GetEntProp(index2, Prop_Send, "m_iItemDefinitionIndex") && TF2_IsPlayerInCondition(Ent_Team, TFCond_OnFire))
						{	
							if(chainDistance < 375.0 && IsTargetInSightRange(client, Ent_Team) && searchOrigin[2] < clientOrigin[2] + 115)
							{
								TF2_LookAtPos(client, searchOrigin, 0.08);
								buttons |= IN_ATTACK2;
								TF2_MoveTo(client, searchOrigin, vel, angles);
							
								if(CheckTimer == INVALID_HANDLE)
								{
									FakeClientCommand(client, "voicemenu 2 3");
								}
							
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToChatAll("JUMP!");
									buttons |= IN_JUMP;
								}
							}
						}
						else if(IsWeaponSlotActive(client, 0) && Setup == 0 && Payload == 1 || IsWeaponSlotActive(client, 0) && Payload == 0)
						{
							// SPY CHECK!
							int random = GetRandomInt(1, 475);
							if (chainDistance < 250.0 && IsWeaponSlotActive(client, 0) && random == 1)
							{
								buttons |= IN_ATTACK;
							}
							else if(CheckTimer == INVALID_HANDLE)
							{
								// Make Pyro bots always spy check if they're near dispensers.
								int EnemyBuilding = GetNearestEntity(client, "obj_dispenser");
								if(EnemyBuilding != -1 && IsWeaponSlotActive(client, 0))
								{
									if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) == GetTeamNumber(EnemyBuilding))
									{
										float enemysentryOrigin[3];
										GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
								
										if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 100 || GetVectorDistance(clientOrigin, enemysentryOrigin) < 500 && random == 1)
										{
											buttons |= IN_ATTACK;
										}
									}
								}
							}
						}
					}
				}
				
				if(IsValidEntity(Ent))
				{
					// Make Pyro use flamethrower up close and use secondary from far away.	
					TFClassType otherclass = TF2_GetPlayerClass(Ent);
					
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
					
					// Force them to use flamethrower up close but if really the enemy is far force them to use secondary.
					if(chainDistance < 425.0 && IsTargetInSightRange(client, Ent))
					{
						ban_secondary[client] = false;
						ban_primary[client] = true;
						TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
					}
					else if(chainDistance > 700.0 && IsTargetInSightRange(client, Ent) && otherclass != TFClass_DemoMan && otherclass != TFClass_Soldier)						
					{
						ban_primary[client] = false;
						ban_secondary[client] = true;
						TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary);
					}
					else
					{
						ban_primary[client] = false;
						ban_secondary[client] = false;
					}
				}
			}
		
			// SOLDIER STUFF!
			case TFClass_Soldier:
			{
				if(IsValidClient(Ent))
				{	
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
				
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
					
					// Make Soldier bots rocket jump in combat situations. (Ask if the enemy is looking cuz it won't work the other way around.)
					if(IsWeaponSlotActive(client, 0) && IsTargetInSightRange(Ent, client) && GetEntityFlags(client) & FL_ONGROUND && chainDistance < 750.0 && GetHealth(client) >= 130 && SoldierTimerNum == 1)
					{
						int clipsize = -1;
						weapon = GetPlayerWeaponSlot(client, 0); 
						int AmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
						if(IsValidEntity(weapon))
						{
							clipsize = GetEntData(weapon, AmmoTable, 4);
						}
					
						//PrintToChatAll("clip size : %i", clipsize);
						if(clipsize >= 1)
						{
							// Rocket Jump
							float newDirection[3];
							GetClientEyeAngles(client, newDirection);
							newDirection[0] = 89.0;
							//newDirection[1] = -90.0;
							newDirection[1] = 90.0;
							newDirection[2] = 0.0;
							//TF2_LookAtPos(client, newDirection, 0.08);
							TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
							buttons |= IN_JUMP;
							buttons |= IN_DUCK;
							buttons |= IN_ATTACK;
							moveForward(vel,9000.0);
							//PrintToChatAll("ROCKET JUMPING!");
							SoldierTimerNum = 0;
						}
					}
					
					// Make Soldier's aim for the feet!
					// From Marqueritte's Bot Combat Improvements
					if(IsWeaponSlotActive(client, 0))
					{
						float targetEyes[3];
						float targetEyes2[3];
						
						float EntVel[3];
						GetEntPropVector(Ent, Prop_Data, "m_vecVelocity", EntVel);
						
						if(GetEntityFlags(Ent) & FL_ONGROUND)
						{
							targetEyes[2] += 5.0;
						}
						else
						{
							targetEyes[2] += 0.0;
						}
					
						if(IsPointVisible(clientEyes, EntVel))
						{
							targetEyes[1] += (EntVel[1] / 2);
						}
						else
						{
							targetEyes[1] = targetEyes2[1];
						}
					}

					// Check if Soldier has a backpack equipped.
					int sollysecondary = GetPlayerWeaponSlot(client, 1);
					if(IsValidEntity(sollysecondary))
					{
						if(129 == GetEntProp(sollysecondary, Prop_Send, "m_iItemDefinitionIndex") || 226 == GetEntProp(sollysecondary, Prop_Send, "m_iItemDefinitionIndex") || 354 == GetEntProp(sollysecondary, Prop_Send, "m_iItemDefinitionIndex") || 1001 == GetEntProp(sollysecondary, Prop_Send, "m_iItemDefinitionIndex"))
						{
							// If Soldier ain't ready to use it then make sure he uses his rocket launcher instead.
							if(IsWeaponSlotActive(client, 1) && 100.0 != GetEntPropFloat(client, Prop_Send, "m_flRageMeter"))
							{
								TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
							}
							// Otherwise we should make him at least try to use it if he's not currently in a fight.
							else if (100.0 == GetEntPropFloat(client, Prop_Send, "m_flRageMeter") && chainDistance > 750 && chainDistance < 1500)
							{
								TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
								buttons |= IN_ATTACK;
							}
						}
					}

					// Support for Beggar's Bazooka and Cow Mangler.
					// SHOWIN! BEGGARS GETS BUGGED DUE TO SOLDIERS RETREATING TO RELOAD AND GETTING CONFUSED!
					int sollyprim = GetPlayerWeaponSlot(client, 0);
					if(IsValidEntity(sollyprim))
					{
						//if(129 == GetEntProp(sollyprim, Prop_Send, "m_iItemDefinitionIndex"))
						//{
						//	// If Soldier has 3 rockets loaded then fire them.
						//	if(IsWeaponSlotActive(client, 0))
						//	{
						//		int clipsize = -1;
						//		int AmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
						//		clipsize = GetEntData(sollyprim, AmmoTable, 3);
						//
						//		if(clipsize < 3)
						//		{
						//			// Do Nothing if we don't have a full clip.
						//		}
						//		else if(buttons & IN_ATTACK)
						//		{
						//			buttons &= ~IN_ATTACK;
						//		}
						//	}
						//}
						//else if(441 == GetEntProp(sollyprim, Prop_Send, "m_iItemDefinitionIndex"))
						if(441 == GetEntProp(sollyprim, Prop_Send, "m_iItemDefinitionIndex"))
						{
							// If Soldier has 4 rockets let's roll to see if he'll charge.
							if(IsWeaponSlotActive(client, 0) && IsTargetInSightRange(Ent, client) && SoldierTimerNum == 0 && chainDistance > 500.0)
							{
								int clipsize = -1;
								int AmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
								clipsize = GetEntData(sollyprim, AmmoTable, 4);
								
								if(clipsize > 3)
								{
									buttons &= ~IN_ATTACK;
									buttons |= IN_ATTACK2;
								}					
							}
						}
					}
				}
			}
		
			// SNIPER STUFF!
			case TFClass_Sniper:
			{
				if(CheckTimer == INVALID_HANDLE && IsValidEntity(Ent) && IsWeaponSlotActive(client, 0))
				{		
					// Make Sniper actually attack with his rifle if up close.
					// He might be using backpacks so we need to account for this.
					float clientOrigin[3];
					float searchOrigin[3];
					GetClientAbsOrigin(Ent, searchOrigin);
					GetClientAbsOrigin(client, clientOrigin);
					float sniperDistance;
					sniperDistance = GetVectorDistance(clientOrigin, searchOrigin);
					
					if(IsTargetInSightRange(client, Ent))
					{	
						// Make Sniper use focus with hitmans heatmaker
						int CurrentSniperWeapon = GetPlayerWeaponSlot(client, 0);
						if (752 == GetEntProp(CurrentSniperWeapon, Prop_Send, "m_iItemDefinitionIndex") && 100.0 == GetEntPropFloat(client, Prop_Send, "m_flRageMeter"))
						{
							buttons |= IN_RELOAD;
							if(sniperDistance < 750)
							{
								buttons |= IN_ATTACK2;
								buttons |= IN_ATTACK;
							}
						}
						// If Sniper is using huntsman / classic then just melee.
						else if(56 == GetEntProp(CurrentSniperWeapon, Prop_Send, "m_iItemDefinitionIndex") || 1005 == GetEntProp(CurrentSniperWeapon, Prop_Send, "m_iItemDefinitionIndex") || 1092 == GetEntProp(CurrentSniperWeapon, Prop_Send, "m_iItemDefinitionIndex") || 1098 == GetEntProp(CurrentSniperWeapon, Prop_Send, "m_iItemDefinitionIndex"))
						{
							if(sniperDistance < 701)
							{
								ban_melee[client] = true;
								TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
							}
							else
							{
								ban_melee[client] = false;
								// We have to force snipers to switching instead of letting them do it on their own.
								// Because snipers are mega-dumb like engineers and won't try otherwise.
								if (IsWeaponSlotActive(client, 2))
								{
									TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
								}
							}
						}
						// Use rifle if up close.
						else if(sniperDistance < 750)
						{
							buttons |= IN_ATTACK2;
							buttons |= IN_ATTACK;
						}
					}
				}
			}	
		
			// SCOUT STUFF!	
			case TFClass_Scout:
			{
				if(CheckTimer == INVALID_HANDLE)
				{
					// Make scouts double jump.
					if (buttons & IN_JUMP)
					{
						buttons |= IN_JUMP;
					}
					// Make scouts occasionally jump in combat.
					//if (IsWeaponSlotActive(client, 0) && GetClientButtons(client) & 1)
					if (GetClientButtons(client) & 1)
					{
						int random = GetRandomInt(1, 250);
						if (random == 1)
						{
							buttons |= IN_JUMP;
						}
					}
				}
			}	
		
			// Engineer STUFF! - Engineer Gaming
			case TFClass_Engineer:
			{		
				int iSentry = TF2_GetObject(client, TFObject_Sentry, TFObjectMode_None);
				int iTeleporter = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Exit);
				if(IsWeaponSlotActive(client, 2))
				{
					if(iTeleporter != INVALID_ENT_REFERENCE && IsValidEntity(iTeleporter) && iSentry != INVALID_ENT_REFERENCE && IsValidEntity(iSentry))
					{
						float clientOrigin[3];
						float teleporterOrigin[3];
						//float sentryOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						GetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", teleporterOrigin);
						//GetEntPropVector(iSentry, Prop_Send, "m_vecOrigin", sentryOrigin);

						float chainDistance;
						chainDistance = GetVectorDistance(clientOrigin, teleporterOrigin);
							
						int iTeleporterLevel = GetEntProp(iTeleporter, Prop_Send, "m_iUpgradeLevel");
						int iTeleporterSapped = GetEntProp(iTeleporter, Prop_Send, "m_bHasSapper");
						int iTeleporterHealth = GetEntProp(iTeleporter, Prop_Send, "m_iHealth");
						int iTeleporterMaxHealth = GetEntProp(iTeleporter, Prop_Send, "m_iMaxHealth");
							
						int iSentrySapped = GetEntProp(iSentry, Prop_Send, "m_bHasSapper");
						int iSentryHealth = GetEntProp(iSentry, Prop_Send, "m_iHealth");
						int iSentryMaxHealth = GetEntProp(iSentry, Prop_Send, "m_iMaxHealth");
							
						// Make engineer repair / level up teleporters
						if(iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth && iTeleporterLevel < 3 && GetHealth(client) >= 125.0 && GetMetal(client) > 130 || iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth && iTeleporterHealth <= (iTeleporterMaxHealth / 1.5) || iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth && iTeleporterSapped == 1)
						{			
							//PrintToChatAll("WE SHOULD REPAIR / UPGRADE TELE!");
							
							if(chainDistance < 600.0 && teleporterOrigin[2] < clientOrigin[2] + 50)
							{		
								//PrintToChatAll("WHACKING TELE!");
								TF2_LookAtPos(client, teleporterOrigin, 0.05);
								TF2_MoveTo(client, teleporterOrigin, vel, angles);
								
								buttons |= IN_DUCK;
								buttons |= IN_ATTACK;
								
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToChatAll("JUMP!");
									buttons |= IN_JUMP;
								}
							}
						}
					}
				}
				else if(iSentry != INVALID_ENT_REFERENCE && IsValidEntity(iSentry))
				{
					float clientOrigin[3];
					float sentryOrigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(iSentry, Prop_Send, "m_vecOrigin", sentryOrigin);

					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, sentryOrigin);
					
					int iSentryLevel = GetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel");
					int iSentrySapped = GetEntProp(iSentry, Prop_Send, "m_bHasSapper");
					int iSentryHealth = GetEntProp(iSentry, Prop_Send, "m_iHealth");
					int iSentryMaxHealth = GetEntProp(iSentry, Prop_Send, "m_iMaxHealth");
					
					// This will force engineers to use their melee near their sentryguns and fix an issue that makes them fuck out.
					// Lets check if engie is close to his own sentrygun.
					// If its in bad condition lets let him decide to abandon it and fight back.
					if(chainDistance < 250.0 && iSentryLevel < 3 && iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth - 90)
					{	
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
					}
				}
				
				// Always build entrance teleporters and refill metal
				int iResupply = GetNearestEntity(client, "func_regenerate"); 
				if(iResupply != INVALID_ENT_REFERENCE && IsValidEntity(iResupply))
				{		
					int iTeleporterEntrance = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Entrance);
					
					float clientOrigin[3];
					float iResupplyorigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(iResupply, Prop_Send, "m_vecOrigin", iResupplyorigin);
								
					float chainDistance;
					chainDistance = GetVectorDistance(clientOrigin, iResupplyorigin);
					
					// Force engies to put down teles if they're close to the resupply and have full metal.
					if(iTeleporterEntrance == INVALID_ENT_REFERENCE && GetMetal(client) >= 200 && chainDistance < 750.0 || !IsValidEntity(iTeleporterEntrance) && GetMetal(client) >= 200 && chainDistance < 750.0)
					{
						if(CheckTimer == INVALID_HANDLE)
						{
							FakeClientCommand(client, "build 1 0" );
						}
						
						if(!IsWeaponSlotActive(client, 0) && !IsWeaponSlotActive(client, 1))
						{
							buttons |= IN_ATTACK;
						}
					}
					// When engies do not have full metal we instead tell them to go the resupply to make sure they're full and don't go hungry.
					//else if(chainDistance < 1000.0 && iResupplyorigin[2] < clientOrigin[2] + 50 && iResupplyorigin[2] < clientOrigin[2] - 50)
					//{
					//	TF2_MoveTo(client, iResupplyorigin, vel, angles);
					//	
					//	// Make sure bot doesn't get stuck when trying to attack.
					//	if(TF2_IsNextToWall(client))
					//	{
					//		//PrintToChatAll("JUMP!");
					//		buttons |= IN_JUMP;
					//	}
					//}
				}
			}
		}
		
		// Apply the shared view/reaction layer after class logic has selected its
		// movement and buttons. This catches snap turns from the stock bot brain too.
		HumanizeAwarenessCommand(client, buttons, angles);

		// This is used for certain parts to reduce the amount of time the code is ran.
		// But it only works in specific areas.
		CheckTimer = CreateTimer(1.0, ResetCheckTimer);
		
	}
	
	}
	
	return Plugin_Continue;
}


void ResetHumanAwareness(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	g_awarenessTarget[client] = -1;
	g_awarenessPendingTarget[client] = -1;
	g_awarenessCachedCandidate[client] = -1;
	g_awarenessTargetVisible[client] = false;
	g_humanAnglesInitialized[client] = false;
	g_awarenessReactionUntil[client] = 0.0;
	g_awarenessMemoryUntil[client] = 0.0;
	g_awarenessTargetLockUntil[client] = 0.0;
	g_awarenessNextScanAt[client] = 0.0;
	g_humanAimOffsetUntil[client] = 0.0;
	g_humanAimLastUpdate[client] = 0.0;
	g_humanAimSnapReactionUntil[client] = 0.0;
	g_humanSkillVariance[client] = GetRandomFloat(0.88, 1.12);

	for (int axis = 0; axis < 3; axis++)
	{
		g_awarenessLastKnownPos[client][axis] = 0.0;
		g_humanViewAngles[client][axis] = 0.0;
	}

	g_humanAimOffset[client][0] = 0.0;
	g_humanAimOffset[client][1] = 0.0;
}

bool IsHumanAwarenessEnemy(int client, int target)
{
	if (client < 1 || client > MaxClients || target < 1 || target > MaxClients)
	{
		return false;
	}

	if (!IsValidClient(client) || !IsValidClient(target) || client == target)
	{
		return false;
	}

	if (!IsPlayerAlive(target) || GetClientTeam(client) == GetClientTeam(target))
	{
		return false;
	}

	if (TF2_IsPlayerInCondition(target, TFCond_Cloaked) || TF2_IsPlayerInCondition(target, TFCond_Disguised))
	{
		return false;
	}

	return true;
}

float GetAwarenessDifficultyScale()
{
	if (g_botDifficulty == null)
	{
		return 1.0;
	}

	switch (g_botDifficulty.IntValue)
	{
		case 0: return 1.45;
		case 1: return 1.18;
		case 2: return 0.95;
		case 3: return 0.78;
	}

	return 1.0;
}

float GetAwarenessReactionDelay(int client, int target)
{
	float minimum = g_humanReactionMin.FloatValue;
	float maximum = g_humanReactionMax.FloatValue;
	if (maximum < minimum)
	{
		maximum = minimum;
	}

	float delay = GetRandomFloat(minimum, maximum);
	delay *= GetAwarenessDifficultyScale();
	delay *= g_humanSkillVariance[client];

	float clientPos[3];
	float targetPos[3];
	GetClientAbsOrigin(client, clientPos);
	GetClientAbsOrigin(target, targetPos);
	float distance = GetVectorDistance(clientPos, targetPos);

	// Distant targets take slightly longer to visually parse.
	float distanceDelay = distance / 8000.0;
	if (distanceDelay > 0.16)
	{
		distanceDelay = 0.16;
	}
	delay += distanceDelay;

	return delay < 0.02 ? 0.02 : delay;
}

float GetAwarenessMemoryDuration(int client)
{
	float minimum = g_humanMemoryMin.FloatValue;
	float maximum = g_humanMemoryMax.FloatValue;
	if (maximum < minimum)
	{
		maximum = minimum;
	}

	float duration = GetRandomFloat(minimum, maximum);
	float difficulty = GetAwarenessDifficultyScale();
	if (difficulty > 1.5)
	{
		difficulty = 1.5;
	}

	return duration * (2.0 - difficulty) * g_humanSkillVariance[client];
}

float GetAwarenessTargetLockDuration(int client)
{
	float minimum = g_humanTargetLockMin.FloatValue;
	float maximum = g_humanTargetLockMax.FloatValue;
	if (maximum < minimum)
	{
		maximum = minimum;
	}

	return GetRandomFloat(minimum, maximum) * g_humanSkillVariance[client];
}

void RememberAwarenessTarget(int client, int target)
{
	if (!IsHumanAwarenessEnemy(client, target))
	{
		return;
	}

	GetClientEyePosition(target, g_awarenessLastKnownPos[client]);
	g_awarenessMemoryUntil[client] = GetGameTime() + GetAwarenessMemoryDuration(client);
}

void BeginAwarenessReaction(int client, int target, float delayScale = 1.0)
{
	if (!IsHumanAwarenessEnemy(client, target))
	{
		return;
	}

	if (g_awarenessPendingTarget[client] != target)
	{
		g_awarenessPendingTarget[client] = target;
		g_awarenessReactionUntil[client] = GetGameTime() + (GetAwarenessReactionDelay(client, target) * delayScale);
	}
}

bool IsTargetInsideHumanFov(int client, int target, float fieldOfView)
{
	float clientPos[3];
	float targetPos[3];
	float aimForward[3];
	float direction[3];
	float viewAngles[3];

	GetClientEyePosition(client, clientPos);
	GetClientEyePosition(target, targetPos);
	MakeVectorFromPoints(clientPos, targetPos, direction);
	NormalizeVector(direction, direction);

	if (g_humanAnglesInitialized[client])
	{
		viewAngles[0] = g_humanViewAngles[client][0];
		viewAngles[1] = g_humanViewAngles[client][1];
		viewAngles[2] = 0.0;
	}
	else
	{
		GetClientEyeAngles(client, viewAngles);
	}

	GetAngleVectors(viewAngles, aimForward, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(aimForward, aimForward);

	float dot = GetVectorDotProduct(direction, aimForward);
	if (dot > 1.0)
	{
		dot = 1.0;
	}
	else if (dot < -1.0)
	{
		dot = -1.0;
	}
	float angle = RadToDeg(ArcCosine(dot));
	return angle <= fieldOfView * 0.5;
}

bool CanHumanAwarenessSee(int client, int target, bool currentTarget = false)
{
	if (!IsHumanAwarenessEnemy(client, target))
	{
		return false;
	}

	float clientPos[3];
	float targetPos[3];
	GetClientEyePosition(client, clientPos);
	GetClientEyePosition(target, targetPos);

	if (!IsPointVisible(clientPos, targetPos))
	{
		return false;
	}

	float distance = GetVectorDistance(clientPos, targetPos);
	float fieldOfView = currentTarget ? 205.0 : 155.0;
	if (distance < 275.0)
	{
		fieldOfView = currentTarget ? 320.0 : 250.0;
	}

	return IsTargetInsideHumanFov(client, target, fieldOfView);
}

int FindBestHumanAwarenessEnemy(int client)
{
	float clientPos[3];
	GetClientEyePosition(client, clientPos);

	float bestScore = -1.0;
	int bestTarget = -1;

	for (int target = 1; target <= MaxClients; target++)
	{
		if (!IsHumanAwarenessEnemy(client, target) || !CanHumanAwarenessSee(client, target, target == g_awarenessTarget[client]))
		{
			continue;
		}

		float targetPos[3];
		GetClientEyePosition(target, targetPos);
		float score = GetVectorDistance(clientPos, targetPos);

		// Prefer sticking with the current threat instead of switching every tick.
		if (target == g_awarenessTarget[client])
		{
			score -= 325.0;
		}

		// Attackers are visually salient and should win close comparisons.
		if ((GetClientButtons(target) & IN_ATTACK) != 0)
		{
			score -= 125.0;
		}

		if (bestTarget == -1 || score < bestScore)
		{
			bestScore = score;
			bestTarget = target;
		}
	}

	return bestTarget;
}

int UpdateHumanAwareness(int client)
{
	if (g_humanAwarenessEnable == null || g_humanAwarenessEnable.IntValue == 0)
	{
		float clientEyes[3];
		GetClientEyePosition(client, clientEyes);
		return Client_GetClosest(clientEyes, client);
	}

	float now = GetGameTime();
	int currentTarget = g_awarenessTarget[client];
	bool currentVisible = CanHumanAwarenessSee(client, currentTarget, true);
	g_awarenessTargetVisible[client] = currentVisible;

	if (currentVisible)
	{
		RememberAwarenessTarget(client, currentTarget);
	}
	else if (currentTarget != -1 && (!IsHumanAwarenessEnemy(client, currentTarget) || now >= g_awarenessMemoryUntil[client]))
	{
		g_awarenessTarget[client] = -1;
		g_awarenessTargetLockUntil[client] = 0.0;
		currentTarget = -1;
	}

	if (now >= g_awarenessNextScanAt[client])
	{
		g_awarenessCachedCandidate[client] = FindBestHumanAwarenessEnemy(client);
		g_awarenessNextScanAt[client] = now + GetRandomFloat(0.08, 0.14);
	}

	int candidate = g_awarenessCachedCandidate[client];

	// Once a reaction has started, keep processing that same visual stimulus
	// instead of restarting the delay whenever another enemy crosses the screen.
	int pendingTarget = g_awarenessPendingTarget[client];
	if (pendingTarget != -1 && now < g_awarenessReactionUntil[client] && CanHumanAwarenessSee(client, pendingTarget, pendingTarget == currentTarget))
	{
		candidate = pendingTarget;
	}

	if (candidate != -1 && candidate != currentTarget)
	{
		bool canSwitch = currentTarget == -1 || !currentVisible || now >= g_awarenessTargetLockUntil[client];
		if (canSwitch)
		{
			BeginAwarenessReaction(client, candidate);
			if (now >= g_awarenessReactionUntil[client])
			{
				g_awarenessTarget[client] = candidate;
				g_awarenessPendingTarget[client] = -1;
				g_awarenessTargetVisible[client] = true;
				g_awarenessTargetLockUntil[client] = now + GetAwarenessTargetLockDuration(client);
				RememberAwarenessTarget(client, candidate);
				currentTarget = candidate;
				currentVisible = true;
			}
		}
	}
	else if (candidate == currentTarget && currentTarget != -1 && now >= g_awarenessReactionUntil[client])
	{
		g_awarenessPendingTarget[client] = -1;
	}
	else if (candidate == -1 && g_awarenessPendingTarget[client] != -1
		&& (now >= g_awarenessReactionUntil[client] || !IsHumanAwarenessEnemy(client, g_awarenessPendingTarget[client])))
	{
		g_awarenessPendingTarget[client] = -1;
		g_awarenessReactionUntil[client] = 0.0;
	}

	// Class logic only receives a target once it has been reacted to and is still
	// visibly confirmed. Memory is used for looking/searching, not wall tracking.
	bool reactionComplete = g_awarenessPendingTarget[client] != currentTarget || now >= g_awarenessReactionUntil[client];
	if (currentTarget != -1 && currentVisible && reactionComplete)
	{
		return currentTarget;
	}

	return -1;
}

float GetHumanTurnSpeed(int client, bool reacting, bool fighting, bool remembering)
{
	float speed;
	int difficulty = g_botDifficulty == null ? 1 : g_botDifficulty.IntValue;

	switch (difficulty)
	{
		case 0: speed = 250.0;
		case 1: speed = 360.0;
		case 2: speed = 500.0;
		case 3: speed = 680.0;
		default: speed = 360.0;
	}

	if (reacting)
	{
		speed *= 0.42;
	}
	else if (remembering)
	{
		speed *= 0.58;
	}
	else if (!fighting)
	{
		speed *= 1.35;
	}

	return speed / g_humanSkillVariance[client];
}

float ApproachHumanAngle(float current, float target, float maximumStep)
{
	float difference = AngleNormalize(target - current);
	if (difference > maximumStep)
	{
		difference = maximumStep;
	}
	else if (difference < -maximumStep)
	{
		difference = -maximumStep;
	}

	return AngleNormalize(current + difference);
}

void GetAnglesToAwarenessPosition(int client, const float position[3], float output[3])
{
	float eyePos[3];
	float direction[3];
	GetClientEyePosition(client, eyePos);
	MakeVectorFromPoints(eyePos, position, direction);
	GetVectorAngles(direction, output);
	output[2] = 0.0;
}

void HumanizeAwarenessCommand(int client, int &buttons, float angles[3])
{
	if (g_humanAwarenessEnable == null || g_humanAwarenessEnable.IntValue == 0)
	{
		g_humanAnglesInitialized[client] = false;
		return;
	}

	float now = GetGameTime();
	if (!g_humanAnglesInitialized[client])
	{
		g_humanViewAngles[client][0] = angles[0];
		g_humanViewAngles[client][1] = angles[1];
		g_humanViewAngles[client][2] = 0.0;
		g_humanAimLastUpdate[client] = now;
		g_humanAnglesInitialized[client] = true;
	}

	float deltaTime = now - g_humanAimLastUpdate[client];
	if (deltaTime <= 0.0 || deltaTime > 0.10)
	{
		deltaTime = 0.015;
	}
	g_humanAimLastUpdate[client] = now;

	bool fighting = g_awarenessTarget[client] != -1 && g_awarenessTargetVisible[client];
	bool remembering = !fighting && g_awarenessTarget[client] != -1 && now < g_awarenessMemoryUntil[client];

	float desiredAngles[3];
	desiredAngles[0] = angles[0];
	desiredAngles[1] = angles[1];
	desiredAngles[2] = 0.0;

	// The stock bot brain can decide to shoot and rotate toward something outside
	// this layer's field of view in the same command. Treat a large attacking snap
	// as an unconfirmed stimulus so it still has to turn and react before firing.
	TFClassType class = TF2_GetPlayerClass(client);
	float rawYawChange = FloatAbs(AngleNormalize(desiredAngles[1] - g_humanViewAngles[client][1]));
	float rawPitchChange = FloatAbs(AngleNormalize(desiredAngles[0] - g_humanViewAngles[client][0]));
	if (!fighting && g_awarenessPendingTarget[client] == -1
		&& class != TFClass_Medic && class != TFClass_Engineer
		&& (buttons & IN_ATTACK) != 0 && (rawYawChange > 24.0 || rawPitchChange > 18.0)
		&& now >= g_humanAimSnapReactionUntil[client])
	{
		float snapDelay = GetRandomFloat(g_humanReactionMin.FloatValue, g_humanReactionMax.FloatValue);
		g_humanAimSnapReactionUntil[client] = now + (snapDelay * GetAwarenessDifficultyScale() * g_humanSkillVariance[client]);
	}

	bool reacting = (g_awarenessPendingTarget[client] != -1 && now < g_awarenessReactionUntil[client])
		|| now < g_humanAimSnapReactionUntil[client];

	if (remembering)
	{
		GetAnglesToAwarenessPosition(client, g_awarenessLastKnownPos[client], desiredAngles);
	}

	if (fighting)
	{
		// Keep the stock class-specific aim when it is plausibly aimed at the
		// committed target (including projectile leading). Reject large retarget
		// snaps until the awareness layer has accepted a switch.
		float targetPos[3];
		float directTargetAngles[3];
		GetClientEyePosition(g_awarenessTarget[client], targetPos);
		GetAnglesToAwarenessPosition(client, targetPos, directTargetAngles);

		float targetYawDifference = FloatAbs(AngleNormalize(desiredAngles[1] - directTargetAngles[1]));
		float targetPitchDifference = FloatAbs(AngleNormalize(desiredAngles[0] - directTargetAngles[0]));
		if (targetYawDifference > 36.0 || targetPitchDifference > 28.0)
		{
			desiredAngles[0] = directTargetAngles[0];
			desiredAngles[1] = directTargetAngles[1];
		}
		if (now >= g_humanAimOffsetUntil[client])
		{
			float errorScale = GetAwarenessDifficultyScale();
			g_humanAimOffset[client][0] = GetRandomFloat(-0.65, 0.65) * errorScale;
			g_humanAimOffset[client][1] = GetRandomFloat(-0.90, 0.90) * errorScale;
			g_humanAimOffsetUntil[client] = now + GetRandomFloat(0.22, 0.48);
		}

		desiredAngles[0] += g_humanAimOffset[client][0];
		desiredAngles[1] += g_humanAimOffset[client][1];
	}

	ClampAngle(desiredAngles);

	float maximumStep = GetHumanTurnSpeed(client, reacting, fighting, remembering) * deltaTime;
	g_humanViewAngles[client][0] = ApproachHumanAngle(g_humanViewAngles[client][0], desiredAngles[0], maximumStep);
	g_humanViewAngles[client][1] = ApproachHumanAngle(g_humanViewAngles[client][1], desiredAngles[1], maximumStep);
	g_humanViewAngles[client][2] = 0.0;

	angles[0] = g_humanViewAngles[client][0];
	angles[1] = g_humanViewAngles[client][1];
	angles[2] = 0.0;

	// Keep reaction delay from becoming harmless prefire. Support tools are exempt
	// so Medics and Engineers do not drop heals or repairs when an enemy appears.
	if (reacting && class != TFClass_Medic && class != TFClass_Engineer)
	{
		buttons &= ~IN_ATTACK;
	}
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

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}  

public Action ResetSpyTimer(Handle timer)
{
	SpyTimer = INVALID_HANDLE;
	return Plugin_Continue;
}

public Action ResetSpyTimer2(Handle timer)
{
	float SpyValue = GetRandomFloat(5.0, 25.0);
	SpyTimer = CreateTimer(SpyValue, ResetSpyTimer);
	return Plugin_Continue;
}

public Action ResetCheckTimer(Handle timer)
{
	CheckTimer = INVALID_HANDLE;
	return Plugin_Continue;
}

public bool Filter(int entity, int mask)
{
	return !(IsValidClient(entity));
}

public bool TraceRayDontHitPlayers(int entity, int mask)
{
	if(entity <= MaxClients)
	{
		return false;
	}
	return true;
}

bool IsClientMoving(int client)
{
     float buffer[3];
     GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
     return (GetVectorLength(buffer) > 0.0);
}  

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock void ClampAngle(float fAngles[3])
{
	if (fAngles[0] > 89.0)
	{
		fAngles[0] = 89.0;
	}
	else if (fAngles[0] < -89.0)
	{
		fAngles[0] = -89.0;
	}

	while (fAngles[1] > 180.0)
	{
		fAngles[1] -= 360.0;
	}
	while (fAngles[1] < -180.0)
	{
		fAngles[1] += 360.0;
	}

	fAngles[2] = 0.0;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{	
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

stock int TF_IsUberCharge(int client)
{
	int index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntProp(index, Prop_Send, "m_bChargeRelease", 1);
	else
		return 0;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
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
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			// We always check this anyways later on.
			// Getitng rid of this makes stuff like gru heavy tweaks work.
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock int Client_GetClosest_Team(float vecOrigin_center[3], const int client)
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
		if(GetClientTeam(i) == GetClientTeam(client))
		{
			TFClassType class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock int Client_GetClosest_Both(float vecOrigin_center[3], const int client)
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
		if(GetClientTeam(i) == GetClientTeam(client))
		{
			TFClassType class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
		else if(GetClientTeam(i) != GetClientTeam(client))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock int Client_GetClosest_SPY(float vecOrigin_center[3], const int client)
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
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client))
				continue;
			// We always check this anyways later on.
			// Getitng rid of this makes stuff like gru heavy tweaks work.
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

public Action LongTimer(Handle timer)
{
	int AmmoArray[10] = {1000,2000,3000,4000,5000,6000,7000,8000,9000,10000};
	int AmmoNum = GetRandomInt(0, 9);
	int AmmoResult = AmmoArray[AmmoNum];
	SetConVarInt(FindConVar("tf_bot_ammo_search_range"), AmmoResult);
	
	float DefendOwnedPointArray[9] = {0.10,0.20,0.30,0.40,0.50,0.60,0.70,0.80,0.90};
	int DefendOwnedPointNum = GetRandomInt(0, 8);
	float DefendOwnedPointResult = DefendOwnedPointArray[DefendOwnedPointNum];
	SetConVarFloat(FindConVar("tf_bot_defend_owned_point_percent"), DefendOwnedPointResult);
	
	int MustDefendArray[6] = {60,100,200,300,400,600};
	int MustDefendNum = GetRandomInt(0, 5);
	int MustDefendResult = MustDefendArray[MustDefendNum];
	SetConVarInt(FindConVar("tf_bot_defense_must_defend_time"), MustDefendResult);
	
	int HealthSearchFarArray[3] = {2000,3000,4000};
	int HealthSearchFarNum = GetRandomInt(0, 2);
	int HealthSearchFarResult = HealthSearchFarArray[HealthSearchFarNum];
	SetConVarInt(FindConVar("tf_bot_health_search_far_range"), HealthSearchFarResult);
	
	int HealthSearchNearArray[3] = {500,1000,1999};
	int HealthSearchNearNum = GetRandomInt(0, 2);
	int HealthSearchNearResult = HealthSearchNearArray[HealthSearchNearNum];
	SetConVarInt(FindConVar("tf_bot_health_search_near_range"), HealthSearchNearResult);
	
	int NearPointArray[5] = {250,500,750,1000,1250};
	int NearPointNum = GetRandomInt(0, 4);
	int NearPointResult = NearPointArray[NearPointNum];
	SetConVarInt(FindConVar("tf_bot_near_point_travel_distance"), NearPointResult);
	
	int RetreatArray[9] = {600,700,800,900,1000,1500,2000,2500,3000};
	int RetreatNum = GetRandomInt(0, 8);
	int RetreatResult = RetreatArray[RetreatNum];
	SetConVarInt(FindConVar("tf_bot_retreat_to_cover_range"), RetreatResult);
	
	int SeekAndDestroyMinArray[7] = {2,4,6,8,10,12,15};
	int SeekAndDestroyMinNum = GetRandomInt(0, 6);
	int SeekAndDestroyMinResult = SeekAndDestroyMinArray[SeekAndDestroyMinNum];
	SetConVarInt(FindConVar("tf_bot_capture_seek_and_destroy_min_duration"), SeekAndDestroyMinResult);
	
	int SeekAndDestroyMaxArray[21] = {18,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60};
	int SeekAndDestroyMaxNum = GetRandomInt(0, 20);
	int SeekAndDestroyMaxResult = SeekAndDestroyMaxArray[SeekAndDestroyMaxNum];
	SetConVarInt(FindConVar("tf_bot_capture_seek_and_destroy_max_duration"), SeekAndDestroyMaxResult);
	
	int PayloadDefendRangeArray[7] = {500,1000,1000,1500,2000,2000,2500};
	int PayloadDefendRangeNum = GetRandomInt(0, 6);
	int PayloadDefendRangeResult = PayloadDefendRangeArray[PayloadDefendRangeNum];
	SetConVarInt(FindConVar("tf_bot_payload_guard_range"), PayloadDefendRangeResult);
	return Plugin_Continue;
}

public Action MediumTimer(Handle timer)
{
	int SpyForgetArray[24] = {5,5,5,10,10,10,15,15,15,20,20,20,25,25,25,30,30,30,40,40,40,50,50,50};
	int SpyForgetNum = GetRandomInt(0, 23);
	int SpyForgetResult = SpyForgetArray[SpyForgetNum];
	SetConVarInt(FindConVar("tf_bot_suspect_spy_forget_cooldown"), SpyForgetResult);
	
	int PyroShoveArray[2] = {0,250};
	int PyroShoveNum = GetRandomInt(0, 1);
	int PyroShoveResult = PyroShoveArray[PyroShoveNum];
	SetConVarInt(FindConVar("tf_bot_pyro_shove_away_range"), PyroShoveResult);
	
	float SniperAimArray[8] = {0.0005,0.0025,0.005,0.0075,0.01,0.012,0.013,0.014};
	int SniperAimNum = GetRandomInt(0, 7);
	float SniperAimResult = SniperAimArray[SniperAimNum];
	SetConVarFloat(FindConVar("tf_bot_sniper_aim_error"), SniperAimResult);
	
	int SniperAimSteadyArray[10] = {5,6,8,9,10,20,30,40,50,999};
	int SniperAimSteadyNum = GetRandomInt(0, 9);
	int SniperAimSteadyResult = SniperAimSteadyArray[SniperAimSteadyNum];
	SetConVarInt(FindConVar("tf_bot_sniper_aim_steady_rate"), SniperAimSteadyResult);
	
	int SniperLingerArray[9] = {1,2,3,4,5,6,7,8,9};
	int SniperLingerNum = GetRandomInt(0, 8);
	int SniperLingerResult = SniperLingerArray[SniperLingerNum];
	SetConVarInt(FindConVar("tf_bot_sniper_linger_time"), SniperLingerResult);
	
	int SniperPatienceArray[10] = {2,4,6,8,10,12,14,16,18,20};
	int SniperPatienceNum = GetRandomInt(0, 9);
	int SniperPatienceResult = SniperPatienceArray[SniperPatienceNum];
	SetConVarInt(FindConVar("tf_bot_sniper_patience_duration"), SniperPatienceResult);
	
	float SniperTargetArray[9] = {1.0, 1.25, 1.50, 1.75, 2.0, 3.0, 4.0, 5.0, 6.0};
	int SniperTargetNum = GetRandomInt(0, 8);
	float SniperTargetResult = SniperTargetArray[SniperTargetNum];
	SetConVarFloat(FindConVar("tf_bot_sniper_target_linger_duration"), SniperTargetResult);
	
	float SniperReselectArray[7] = {0.25, 0.5, 1.0, 2.0, 3.0, 4.0, 4.5}; 
	int SniperReselectNum = GetRandomInt(0, 6);
	float SniperReselectResult = SniperReselectArray[SniperReselectNum];
	SetConVarFloat(FindConVar("tf_bot_sniper_choose_target_interval"), SniperReselectResult);
	
	int EngineerFightArray[9] = {250,350,450,550,650,700,800,900,1000};
	int EngineerFightNum = GetRandomInt(0, 8);
	int EngineerFightResult = EngineerFightArray[EngineerFightNum];
	SetConVarInt(FindConVar("tf_bot_engineer_retaliate_range"), EngineerFightResult);
	
	int MedicCallResponseArray[6] = {750,1000,1500,1500,2000,2500};
	int MedicCallResponseNum = GetRandomInt(0, 5);
	int MedicCallResponseResult = MedicCallResponseArray[MedicCallResponseNum];
	SetConVarInt(FindConVar("tf_bot_medic_max_call_response_range"), MedicCallResponseResult);
	
	int SpyTargetArray[9] = {100,150,200,250,300,400,500,600,700};
	int SpyTargetNum = GetRandomInt(0, 8);
	int SpyTargetResult = SpyTargetArray[SpyTargetNum];
	SetConVarInt(FindConVar("tf_bot_spy_change_target_range_threshold"), SpyTargetResult);
	
	int NoticeGunFireRangeArray[11] = {3000,3500,3500,3500,4000,4500,5000,5500,6000,6500,7000};
	int NoticeGunFireRangeNum = GetRandomInt(0, 10);
	int NoticeGunFireRangeResult = NoticeGunFireRangeArray[NoticeGunFireRangeNum];
	SetConVarInt(FindConVar("tf_bot_notice_gunfire_range"), NoticeGunFireRangeResult);
	
	int NoticeQuietGunFireRangeArray[10] = {250,250,500,500,500,1000,1500,2000,2500,3000};
	int NoticeQuietGunFireRangeNum = GetRandomInt(0, 9);
	int NoticeQuietGunFireRangeResult = NoticeQuietGunFireRangeArray[NoticeQuietGunFireRangeNum];
	SetConVarInt(FindConVar("tf_bot_notice_quiet_gunfire_range"), NoticeQuietGunFireRangeResult);
	
	// Engineer Teleport Upgrade Cheat!
	// Yeah we cheating so what? Engie bots are too dumb to fuck with.
	
	//float clientOrigin_human[3];
	//float searchOrigin_engie_bot[3];
	//float chainDistance_human_vs_engie_bot;
	//int ent_tele = -1;
	
	//for(int i = 1; i <= MaxClients; i++)
	//{
	//	TFClassType class = TF2_GetPlayerClass(i);
	//	PrintToChatAll("CHECK ENGINEER VS HUMAN SPACE!");
	//	
	//	if(IsValidClient(i) && IsClientInGame(i) && !IsFakeClient(i))
	//	{
	//		GetClientAbsOrigin(i, clientOrigin_human);
	//	}
	//	else if(IsValidClient(i) && IsClientInGame(i) && IsFakeClient(i) && class == TFClass_Engineer)
	//	{
	//		GetClientAbsOrigin(i, searchOrigin_engie_bot);
	//	}
	//}
	
	//chainDistance_human_vs_engie_bot = GetVectorDistance(clientOrigin_human, searchOrigin_engie_bot);
		
	//if(chainDistance_human_vs_engie_bot > 1 && IsPointVisible(clientOrigin_human, searchOrigin_engie_bot))
	//{
	//	PrintToChatAll("CHECK TELEPORTERS!");
	//	while((ent_tele = FindEntityByClassname(ent_tele, "obj_teleporter")) != -1) 
	//	{
	//		if(ent_tele != INVALID_ENT_REFERENCE && IsValidEntity(ent_tele)) 
	//		{
	//			if(GetEntProp(ent_tele, Prop_Send, "m_iUpgradeLevel") != 3 && IsFakeClient(GetEntProp(ent_tele, Prop_Send, "m_hBuilder")))
	//			{
	//				PrintToChatAll("ENGINEER BOT HAS CHEATED LIKE A LIL WEASEL!");
	//				SetEntPropEnt(ent_tele, Prop_Send, "m_iUpgradeLevel", 3); 
	//			}
	//		}
	//	}
	//}
	
	return Plugin_Continue;
}

public Action ShortTimer(Handle timer)
{	
	int SpyLookArray[24] = {5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10};
	int SpyLookNum = GetRandomInt(0, 23);
	int SpyLookResult = SpyLookArray[SpyLookNum];
	SetConVarInt(FindConVar("tf_bot_suspect_spy_touch_interval"), SpyLookResult);
	
	int PyroReflectArray[2] = {0,1};
	int PyroReflectNum = GetRandomInt(0, 1);
	int PyroReflectResult = PyroReflectArray[PyroReflectNum];
	SetConVarInt(FindConVar("tf_bot_pyro_always_reflect"), PyroReflectResult);
	
	int SpyFindArray[22] = {25,25,25,25,25,25,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100};
	int SpyFindNum = GetRandomInt(0, 21);
	int SpyFindResult = SpyFindArray[SpyFindNum];
	SetConVarInt(FindConVar("tf_bot_notice_backstab_chance"), SpyFindResult);
	
	int BackstabNoticeMaxRangeArray[14] = {450,500,550,600,650,700,750,800,850,900,950,1000,1050,1100};
	int BackstabNoticeMaxRangeNum = GetRandomInt(0, 13);
	int BackstabNoticeMaxRangeResult = BackstabNoticeMaxRangeArray[BackstabNoticeMaxRangeNum];
	SetConVarInt(FindConVar("tf_bot_notice_backstab_max_range"), BackstabNoticeMaxRangeResult);
	
	int BackstabNoticeMinRangeTimerArray[11] = {0,40,80,85,90,95,100,200,300,400,450};
	int BackstabNoticeMinRangeTimerNum = GetRandomInt(0, 10);
	int BackstabNoticeMinRangeTimerResult = BackstabNoticeMinRangeTimerArray[BackstabNoticeMinRangeTimerNum];
	SetConVarInt(FindConVar("tf_bot_notice_backstab_min_range"), BackstabNoticeMinRangeTimerResult);
	
	SoldierTimerNum = GetRandomInt(0, 3);
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false; 
	return true; 
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

public bool TraceEntityFilterStuffTank(int entity, int mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

stock int GetMetal(int client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}

stock int GetTeamNumber(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock bool IsTargetInSightRange(int client, int target, float angle=90.0, float distance=0.0, bool heightcheck=true, bool negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
		
	float clientpos[3];
	float targetpos[3];
	float anglevector[3];
	float targetvector[3];
	float resultangle;
	float resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	// Showin added wall detection here
	// Might be useless cuz it doesn't really prevent them from getting stuck.
	//Handle Wall;
	//Wall = TR_TraceRayFilterEx(clientpos,targetpos,MASK_SOLID,RayType_EndPoint,Filter);
	//if(TR_DidHit(Wall))
	//{
	//	TR_GetEndPosition(targetpos, Wall);
	//	if(GetVectorDistance(clientpos, targetpos) < 50.0)
	//	{
	//		//PrintToChatAll("WALL!");
	//		return false;
	//	}
	//}					
	//CloseHandle(Wall);
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

stock int TF2_GetObject(int client, TFObjectType type, TFObjectMode mode)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		TFObjectMode iObjMode = TF2_GetObjectMode(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type && iObjMode == mode 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
}

stock int AngleDifference(float angle1, float angle2)
{
	int diff = RoundToNearest((angle2 - angle1 + 180)) % 360 - 180;
	return diff < -180 ? diff + 360 : diff;
}