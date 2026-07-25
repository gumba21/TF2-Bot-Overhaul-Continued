#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.10"

bool g_bTouched[MAXPLAYERS+1];
bool g_bSuddenDeathMode;
bool g_bMVM;
bool g_bLateLoad;
ConVar g_hCVTimer2;
ConVar g_hCVTeam2;
Handle g_hWeaponEquip;
Handle g_hWWeaponEquip;
Handle g_hGameConfig;
int boss_health = 1000;
int boss_ammo = 1000;
int boss_pinch_mode = 0;

// Thanks to nosoop for boss health code!
int g_iBossTarget = -1;

#include <sdktools>

enum TFBossHealthState {
	HealthState_Default = 0,
	HealthState_Healing
};

void moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
}

methodmap TFMonsterResource {
	property int Index {
		public get() {
			return EntRefToEntIndex(view_as<int>(this));
		}
	}
	
	property int BossHealthPercentageByte {
		public get() {
			return GetEntProp(this.Index, Prop_Send, "m_iBossHealthPercentageByte");
		}
		public set(int value) {
			value = value > 0xFF? 0xFF : value;
			value = value < 0? 0 : value;
			SetEntProp(this.Index, Prop_Send, "m_iBossHealthPercentageByte", value);
		}
	}
	
	property TFBossHealthState BossHealthState {
		public get() {
			int index = this.Index;
			return view_as<TFBossHealthState>(GetEntProp(index, Prop_Send, "m_iBossState"));
		}
		public set(TFBossHealthState value) {
			SetEntProp(this.Index, Prop_Send, "m_iBossState", value);
		}
	}
	
	/**
	 * Updates the monster resource health display to display the current health of the
	 * specified entity.
	 */
	public void LinkHealth(int entity) {
		int hEntity = EntRefToEntIndex(entity);
		
		if (IsValidEntity(hEntity)) {
			int iMaxHealth = GetEntProp(hEntity, Prop_Data, "m_iMaxHealth");
			
			// account for max unbuffed health on clients
			if (entity > 0 && entity <= MaxClients) {
				int resource = GetPlayerResourceEntity();
				if (IsValidEntity(resource)) {
					iMaxHealth = GetEntProp(resource, Prop_Send, "m_iMaxHealth", _, entity);
				}
			}
			
			int iHealth = GetEntProp(hEntity, Prop_Data, "m_iHealth");
			
			this.BossHealthPercentageByte = RoundToCeil(float(iHealth) / iMaxHealth * 255);
		}
	}
	
	/**
	 * Returns the first monster_resource entity, creating it if it doesn't exist.
	 */
	public static TFMonsterResource GetEntity(bool create = false) {
		int hMonsterResource = FindEntityByClassname(-1, "monster_resource");
		
		if (hMonsterResource == -1) {
			hMonsterResource = CreateEntityByName("monster_resource");
			
			if (hMonsterResource == -1) {
				DispatchSpawn(hMonsterResource);
			}
		}
		
		return view_as<TFMonsterResource>(EntIndexToEntRef(hMonsterResource));
	}
}

public Action SetBossHealthTarget(int client) {
	
	g_iBossTarget = client;
	
	SDKHook(client, SDKHook_PostThink, OnBossPostThink);
	
	return Plugin_Handled;
}

public Action RemoveBossHealthTarget(int client) {
	
	if (client == g_iBossTarget) 
	{
		SDKUnhook(client, SDKHook_PostThink, OnBossPostThink);
		g_iBossTarget = -1;
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", false);
	}
	
	return Plugin_Handled;
}

public void OnBossPostThink(int client) {
	if (client != g_iBossTarget) {
		SDKUnhook(client, SDKHook_PostThink, OnBossPostThink);
		g_iBossTarget = -1;
		
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", false);
	}
	
	if (!TF2_IsGameModeMvM()) {
		// non-MvM, use monster resource health bar
		TFMonsterResource.GetEntity(true).LinkHealth(client);
	} else if (!GetEntProp(client, Prop_Send, "m_bUseBossHealthBar")) {
		// MvM, display boss health bar if it isn't already
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", true);
	}
}

public Plugin myinfo = 
{
	name = "Give Bots Weapons MISSION MODE",
	author = "luki1412 / Edited By Showin, Marqueritte",
	description = "Alternate Version of luki's plugin that gives specific loadouts for mission mode!",
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
	// Change this so it overrides givebotsweapons plugins!
	g_hCVTimer2 = CreateConVar("sm_gbw_delay_missions", "0.1", "Delay for giving weapons to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam2 = CreateConVar("sm_gbw_team_missions", "1", "Team to give weapons to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	
	HookEvent("post_inventory_application", player_inv);
	HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	
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

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int playerid = GetClientOfUserId(GetEventInt(event, "userid", 0));
	// Make sure pinch mode resets upon player respawn.
	// Dying makes u lose in mission mode so this will ensure pinch mode always gets activated after losing.
	if (!IsFakeClient(playerid))
	{
		boss_pinch_mode = 0;
	}
	return Plugin_Continue;
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
	
	if (client == g_iBossTarget) 
	{
		g_iBossTarget = -1;
	}
}

// Powerlord's MvM stock
stock bool TF2_IsGameModeMvM() {
	return GameRules_GetProp("m_bPlayingMannVsMachine")? true : false;
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	int team = GetClientTeam(client);
	
	if (!g_bSuddenDeathMode && !g_bTouched[client] && !g_bMVM && IsPlayerHere(client) || team == 2 && !g_bSuddenDeathMode && !g_bTouched[client] && g_bMVM == true && IsPlayerHere(client))
	{
		g_bTouched[client] = true;
//		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam2);
		float timer = GetConVarFloat(g_hCVTimer2);
		
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
	}
}

public Action OnGetMaxHealth(int entity, int &maxhealth)
{
	maxhealth = boss_health;
	return Plugin_Changed;
}

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;

	int team = GetClientTeam(client);
	int team2 = GetConVarInt(g_hCVTeam2);
	
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
		char currentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(currentMap, sizeof(currentMap));
		switch (class)
		{
			case TFClass_Scout:
			{				
				// Check Maps
				if (StrContains( currentMap, "itemtest" , false) != -1)
				{
					// EXAMPLE BOSS
					// We're looking for any scouts that are on expert difficulty that are also on the BLU team.
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   
						// Name
						char name[5] = "Test";
						SetClientInfo(client, "name", name);
						
						// Weapons
						// First we remove all of the existing weapons.
						// Comment on of these out to keep stock / random.
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
						
						// Then we force a new set of weapons.
						// If you don't add a primary for example you can force them to use melee.
						CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220);
						CreateWeapon(client, "tf_weapon_jar_milk", 222, 10);
						CreateWeapon(client, "tf_weapon_bat_fish", 221, 10);
							
						// Cosmetics
						// The cosmetic randomizer must be disabled for this to work properly.
						CreateWWeapon(client, "tf_wearable", 106);
						CreateWWeapon(client, "tf_wearable", 347);
						CreateWWeapon(client, "tf_wearable", 468);
					
						// Health
						// Simple just set it to whatever and the bot will spawn with this set amount of HP!
						boss_health = 3000;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
										
						// Addconds
						// These are specific conditions you can add to the bot to buff/nerf them.
						// Use the link below to see them all.
						// https://sm.alliedmods.net/new-api/tf2/TFCond
						TF2_AddCondition(client, TFCond_BalloonHead, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						
						// Weapon Switching
						// Lastly its very important to use this if your removing a weapon slot.
						// It will force the bots to switch to the selected weapon and prevent tposing.
						TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
						TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
					}
				}
				else if (StrContains( currentMap, "ctf_2fort_invasion" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 2 && team == 3)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30253); // The Sprinting Cephalopod
						CreateWWeapon(client, "tf_wearable", 1040); // Bacteria Blocker
						CreateWWeapon(client, "tf_wearable", 31163); // Particulate Protector
						CreateWWeapon(client, "tf_wearable", 189); // Alien Swarm Parasite
						
						// Addconds
						//TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite); // Crits
						TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
					// Xenomorph (Later Form)
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30471); // The Alien Cranium
						CreateWWeapon(client, "tf_wearable", 30470); // The Biomech Backpack
						CreateWWeapon(client, "tf_wearable", 30472); // The Xeno Suit
						
						// Addconds
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_DodgeChance, TFCondDuration_Infinite);
					}
				}
				else if (StrContains( currentMap, "pl_snowycoast" , false) != -1 || StrContains( currentMap, "pd_watergate" , false) != -1)
				{
					// Pack #2 Infected Bot: Xenomorph Assassin
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3)
					{ 
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
							
						CreateWeapon(client, "tf_weapon_bat", 30667, 100);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30471); // The Alien Cranium
						CreateWWeapon(client, "tf_wearable", 30470); // The Biomech Backpack
						CreateWWeapon(client, "tf_wearable", 30472); // The Xeno Suit
						
						// Addconds
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite); //crits
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						
						// Weapon Switching
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
					}
					// Xenomorph Gunner
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 1) // no need to check team we use this on red and blu
					{   	
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
							
						CreateWeapon(client, "tf_weapon_pistol", 30666, 10);
						
						// This was originally another xeno but it messes with sniper's headshots!
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 31081); // Fuel Injector
						CreateWWeapon(client, "tf_wearable", 30472); // The Xeno Suit
						CreateWWeapon(client, "tf_wearable", 858); // The Hanger-On Hood
						
						// Addconds
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						
						// Weapon Switching
						TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
					}
				}
			}
			case TFClass_Sniper:
			{
				if (StrContains( currentMap, "pl_snowycoast" , false) != -1 || StrContains( currentMap, "pd_watergate" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 2)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30499); // Conspiratorial Cut // Cranial Conspiracy
						CreateWWeapon(client, "tf_wearable", 30500); // Skinless Slashers // Scaly Scrapers
						
						// Addconds
						TF2_AddCondition(client, TFCond_FocusBuff, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
					
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 31009); // Crocodile Mun-Dee
						CreateWWeapon(client, "tf_wearable", 31005); // Scopers Scales
						
						// Addconds
						TF2_AddCondition(client, TFCond_FocusBuff, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_RegenBuffed, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
				}
			}
			case TFClass_Soldier:
			{		
				// Check Maps
				if (StrContains( currentMap, "cp_well" , false) != -1)
				{
					// Pack #1 Special Bot
					// The Patroller
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 1 && team == 2)
					{   
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
							
						CreateWeapon(client, "tf_weapon_shovel", 775, 10);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 30362); // The Law
						CreateWWeapon(client, "tf_wearable", 296); // License to Maim
						CreateWWeapon(client, "tf_wearable", 30104); // Greybanns
					
						// Health
						boss_health = 150;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
						
						// Addconds
						TF2_AddCondition(client, TFCond_CritOnDamage, TFCondDuration_Infinite); // Give him crits!
						TF2_AddCondition(client, TFCond_MarkedForDeathSilent, TFCondDuration_Infinite); // Will take minicrit damage!
						TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite); // Force Melee
						//TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
						
						// Weapon Switching
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
					}
					// Pack #1 Special Bot
					// Friendly Solly
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 378); // Team Captain
						CreateWWeapon(client, "tf_wearable", 30165); // Cuban Bristle Crisis
						CreateWWeapon(client, "tf_wearable", 1096); // The Baronial Badge
											
						// Addconds
						//TF2_AddCondition(client, TFCond_DodgeChance, TFCondDuration_Infinite); // Keep him alive.
						TF2_AddCondition(client, TFCond_UberchargedHidden, 75.0); // Hidden Uber for sentry destruction
					}
				}
				else if (StrContains( currentMap, "ctf_2fort_invasion" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 189); // Alien Swarm Parasite
						CreateWWeapon(client, "tf_wearable", 30294); // The Larval Lid
						CreateWWeapon(client, "tf_wearable", 31134); // Eye-See-You
						CreateWWeapon(client, "tf_wearable", 30221); // Grub Grenades
						//CreateWWeapon(client, "tf_wearable", 5618); // Voodoo-Cursed Soldier Soul // Doesn't work right.
						
						// Addconds
						//TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
				}
				else if (StrContains( currentMap, "pl_snowycoast" , false) != -1)
				{
					// Pack #2 Ally Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						char name[13] = "Step";
						SetClientInfo(client, "name", name);
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
							
						CreateWeapon(client, "tf_weapon_rocketlauncher", 127, 10);
						CreateWeapon(client, "tf_weapon_buff_item", 354, 10); // The Concheror
						CreateWeapon(client, "tf_weapon_shovel", 775, 10);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 30331); // Antarctic Parka
						CreateWWeapon(client, "tf_wearable", 980); // Soldier's Slope Scopers
						CreateWWeapon(client, "tf_wearable", 30558); // Coldfront Curbstompers
						CreateWWeapon(client, "tf_wearable", 31163); // Particulate Protector
						
						//TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
					}
					// Pack #2 Infected Bot (Cow Mangler)
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 2 && team == 2)
					{   	
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
							
						CreateWeapon(client, "tf_weapon_rocketlauncher", 441, 10);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 443); // Dr.Grodbort's Crest
						CreateWWeapon(client, "tf_wearable", 189); // Alien Swarm Parasite
						CreateWWeapon(client, "tf_wearable", 30294); // The Larval Lid
						CreateWWeapon(client, "tf_wearable", 31134); // Eye-See-You
						CreateWWeapon(client, "tf_wearable", 30221); // Grub Grenades
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						
						TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
					// Pack #2 Infected Bot: Raccoon Soldier
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 2)
					{   	
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
							
						CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 10);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 31071); // Racc Mann
						CreateWWeapon(client, "tf_wearable", 30276); // Lieutenant Bites the Dust
						CreateWWeapon(client, "tf_wearable", 30447); // Lone Survivor
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						
						TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
						
						// Addconds
						TF2_AddCondition(client, TFCond_Jarated, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_CritCola, TFCondDuration_Infinite);						
					}
				}
			}
			case TFClass_DemoMan:
			{
				if (StrContains( currentMap, "pl_snowycoast" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 2)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
												
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 545); // Pickled Paws
						CreateWWeapon(client, "tf_wearable", 30292); // The Parasight
						CreateWWeapon(client, "tf_wearable", 5620); // Voodoo-Cursed Demoman Soul
						
						// Addconds
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_CritCola, TFCondDuration_Infinite);
					}
					// Pack #2 Ally bot
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						char name[15] = "Sub Zero Hero";
						SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 30823); // Bomb Beanie
						CreateWWeapon(client, "tf_wearable", 30305); // The Sub Zero Suit
						CreateWWeapon(client, "tf_wearable", 30061); // The Tartantaloons
						CreateWWeapon(client, "tf_wearable", 31163); // Particulate Protector
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1); // Don't let him have stickies.
						
						CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 10); // Iron Bomber
						//CreateWWeapon(client, "tf_wearable_demoshield", 131, 10);
						
						//TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
					}
				}
				else if (StrContains( currentMap, "cp_degrootkeep" , false) != -1)
				{
					// Pack #2 MISSION BOSS
					// The KING OF YE DEMOMEN
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 2)
					{   
						// Name
						char name[20] = "King of Ye Demomen";
						SetClientInfo(client, "name", name);
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						//TF2_RemoveWeaponSlot(client, 2);
						
						//CreateWWeapon(client, "tf_wearable_demoshield", 131, 10);
						//CreateWeapon(client, "tf_weapon_sword", 172, 10);
						CreateWeapon(client, "tf_weapon_sword", 132, 10);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 342); // Prince Tavish's Crown
						CreateWWeapon(client, "tf_wearable", 31040); // Unforgiven Glory
						CreateWWeapon(client, "tf_wearable", 874); // King of Scotland Cape
						CreateWWeapon(client, "tf_wearable", 31037); // Dynamite Abs
						
						// Health
						//boss_health = 8000;
						//boss_health = 7500;
						//boss_health = 6000;
						boss_health = 5300;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
						SetEntityHealth(client, boss_health); // Do this to fix health bar.
						RemoveBossHealthTarget(client); // Remove health bar to reset max health.
						SetBossHealthTarget(client); // Add health bar for boss!
						
						// Ammo
						//boss_ammo = 9999;
						//int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
						//SetEntData(client, ammoOffset + 4, boss_ammo, 4, true);
						
						// Addconds
						TF2_AddCondition(client, TFCond_KingRune, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
					}
					// Pack #2 Boss Assist Bot #1
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 2 && team == 2)
					{   						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 473); // Spiral Sallet
						CreateWWeapon(client, "tf_wearable", 30722); // Batter's Bracers
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
						
						CreateWWeapon(client, "tf_wearable", 405);
						CreateWWeapon(client, "tf_wearable_demoshield", 406, 10);
						//CreateWeapon(client, "tf_weapon_sword", 132, 10);
						CreateWeapon(client, "tf_weapon_sword", 172, 10);
					}
					// Pack #2 Boss Assist Bot #2
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 1 && team == 2)
					{   						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 30082); // The Glasgow Great Helm
						CreateWWeapon(client, "tf_wearable", 30073); // The Dark Age Defender
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
												
						CreateWWeapon(client, "tf_wearable_demoshield", 131, 10);
						CreateWeapon(client, "tf_weapon_sword", 404, 10);
						
						TF2_AddCondition(client, TFCond_AfterburnImmune, TFCondDuration_Infinite);
					}
					// Pack #2 Boss Assist Bot #3
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 0 && team == 2)
					{   						
						// Cosmetics			
						CreateWWeapon(client, "tf_wearable", 702); // The Warsworn Helmet
						CreateWWeapon(client, "tf_wearable", 30431); // Six Pack Abs
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
						TF2_RemoveWeaponSlot(client, 2);
						
						CreateWeapon(client, "tf_weapon_stickbomb", 307, 10); // Ullapool Caber
					}
				}
			}
			case TFClass_Medic:
			{
				if (StrContains( currentMap, "cp_gravelpit" , false) != -1)
				{
					// Pack #1 Special Bot
					// Kritz Medic Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 2)
					{   
						// Name
						char name[14] = "School Nurse";
						SetClientInfo(client, "name", name);
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 1);
						
						CreateWeapon(client, "tf_weapon_medigun", 35, 10);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 144);
						CreateWWeapon(client, "tf_wearable", 621);
						CreateWWeapon(client, "tf_wearable", 30096);
															
						// Addconds
						TF2_AddCondition(client, TFCond_DodgeChance, TFCondDuration_Infinite);
					}
				}
				else if (StrContains( currentMap, "pl_snowycoast" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 1 && team == 2)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 31163); // Particulate Protector
						CreateWWeapon(client, "tf_wearable", 30197); // The Second Opinion
						CreateWWeapon(client, "tf_wearable", 554); // Emerald Jarate
						CreateWWeapon(client, "tf_wearable", 5622); // Voodoo-Cursed Medic Soul
						
						// Addconds
						//TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
				}
			}
			case TFClass_Heavy:
			{					
				// Check Maps
				if (StrContains( currentMap, "cp_badlands" , false) != -1)
				{
					// Pack #1 MISSION BOSS
					// The Commander
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   
						// Name
						char name[14] = "The Commander";
						SetClientInfo(client, "name", name);
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						//TF2_RemoveWeaponSlot(client, 1);
						//TF2_RemoveWeaponSlot(client, 2);
							
						CreateWeapon(client, "tf_weapon_minigun", 41);
						//CreateWeapon(client, "tf_weapon_shotgun", 11, 10);
						//CreateWeapon(client, "tf_weapon_fists", 43, 10);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 185);
						CreateWWeapon(client, "tf_wearable", 30368);
						CreateWWeapon(client, "tf_wearable", 30342);
						CreateWWeapon(client, "tf_wearable", 30372);
					
						// Health
						boss_health = 4500;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
						SetBossHealthTarget(client); // Add health bar for boss!
						
						// Ammo
						boss_ammo = 9999;
						int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
						SetEntData(client, ammoOffset + 4, boss_ammo, 4, true);
						
						// Addconds
						//TF2_AddCondition(client, TFCond_Slowed, TFCondDuration_Infinite); // He will be really slow!
						//TF2_AddCondition(client, TFCond_DodgeChance, TFCondDuration_Infinite); // Dodges most damage!
						//TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite); // Survives until 1 health then its removed for the final blow.
					}
				}
				else if (StrContains( currentMap, "cp_gravelpit" , false) != -1)
				{
					// Pack #1 Special Bot
					// Heavy Tank
					// Tanky slow enemies that are a constant threat in Triangular Attack. (cp_gravelpit mission)
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   		
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
							
						CreateWeapon(client, "tf_weapon_minigun", 312);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 1088);
						CreateWWeapon(client, "tf_wearable", 30357);
						CreateWWeapon(client, "tf_wearable", 30815);
					
						// Health
						boss_health = 600;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));	
					}
				}
				else if (StrContains( currentMap, "cp_well" , false) != -1)
				{
					// Pack #1 Special Bot
					// Heavy Escort
					// This is the bot that needs to be escorted in cp_well's mission.
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						char name[13] = "Grumch";
						SetClientInfo(client, "name", name);
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
							
						// Cosmetics
						// Trying to make this heavy look beat up since he was captured.
						CreateWWeapon(client, "tf_wearable", 31133); // Boom Boxers
						CreateWWeapon(client, "tf_wearable", 985); // Hockey Hair
						CreateWWeapon(client, "tf_wearable", 30074); // The Tyrutleneck
						CreateWWeapon(client, "tf_wearable", 30345); // The Leftover Trap
						CreateWWeapon(client, "tf_wearable", 30354); // Rat Stompers
					
						// Health
						boss_health = 500;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
						
						// Addconds
						TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite); // Force Melee
						TF2_AddCondition(client, TFCond_UberchargedHidden, 9.0); // Hidden Uber
						
						// Weapon Switching
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
					}
				}
				else if (StrContains( currentMap, "pl_snowycoast" , false) != -1 || StrContains( currentMap, "pd_watergate" , false) != -1)
				{
					// Pack #2 Ally Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						char name[30] = "Soviet Cool Down";
						SetClientInfo(client, "name", name);
						
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						TF2_RemoveWeaponSlot(client, 1);
							
						CreateWeapon(client, "tf_weapon_minigun", 424);
						CreateWeapon(client, "tf_weapon_shotgun", 425, 10);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 31029); // Cool Capuchon
						CreateWWeapon(client, "tf_wearable", 31030); // Paka Parka
						CreateWWeapon(client, "tf_wearable", 30563); // Jungle Booty
						//CreateWWeapon(client, "tf_wearable", 990); // Aqua Flops // Would be funni but doesn't work with jungle booty.
						CreateWWeapon(client, "tf_wearable", 31163); // Particulate Protector
						
						//TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
					}
					// Pack #2 Infected Bot (Brass Beast)
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 1)
					{   
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						
						CreateWeapon(client, "tf_weapon_minigun", 312);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30280); // The Monstrous Mandible
						CreateWWeapon(client, "tf_wearable", 30571); // Brimstone
						CreateWWeapon(client, "tf_wearable", 30653); // Sucker Slug
						CreateWWeapon(client, "tf_wearable", 31103); // Hypno-eyes
						CreateWWeapon(client, "tf_wearable", 562); // Soviet Stitch-Up
											
						// Addconds
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
					}
					// Pack #2 Infected Bot (Shotgun)
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 2)
					{   
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
						
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 30533); // Minsk Beef
						CreateWWeapon(client, "tf_wearable", 30280); // The Monstrous Mandible
						CreateWWeapon(client, "tf_wearable", 30653); // Sucker Slug
						CreateWWeapon(client, "tf_wearable", 31103); // Hypno-eyes
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 562); // Soviet Stitch-Up
											
						// Addconds
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
					}
				}
			}
			case TFClass_Pyro:
			{
				if (StrContains( currentMap, "ctf_2fort_invasion" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 151); // Triboniophorus Tyrannus
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30196); // The Maniac's Manacles
						//CreateWWeapon(client, "tf_wearable", 30530); // Vampyro
						CreateWWeapon(client, "tf_wearable", 30525); // Creature's Grin
						CreateWWeapon(client, "tf_wearable", 30303); // The Abhorrent Appendages
						
						// Addconds
						TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite); // Crits
						TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
				}
			}
			case TFClass_Spy:
			{
				if (StrContains( currentMap, "cp_well" , false) != -1)
				{
					// Pack #1 Special Bot
					// Spy Disguised As Engineer
					// This bot just needs to be forced disguised as an engineer.
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 2)
					{   
						// Class Disguise Numbers!
						//	"TF_CLASS_UNDEFINED", 0
						//	"TF_CLASS_SCOUT", 1
						//	"TF_CLASS_SNIPER", 2
						//	"TF_CLASS_SOLDIER", 3
						//	"TF_CLASS_DEMOMAN", 4
						//	"TF_CLASS_MEDIC", 5
						//	"TF_CLASS_HEAVYWEAPONS", 6
						//	"TF_CLASS_PYRO", 7
						//	"TF_CLASS_SPY", 8
						//	"TF_CLASS_ENGINEER", 9
						//	"TF_CLASS_CIVILIAN", 10
						
						// Health
						boss_health = 300;
						SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
						SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
							
						SetEntProp(client, Prop_Send, "m_nDisguiseTeam", 3);
						SetEntProp(client, Prop_Send, "m_nMaskClass", 9);
						SetEntProp(client, Prop_Send, "m_nDisguiseClass", 9);
						SetEntProp(client, Prop_Send, "m_nDesiredDisguiseClass", 9);
						SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", 1);
						
						TF2_AddCondition(client, TFCond_Disguised);
					}
				}
				else if (StrContains( currentMap, "pl_snowycoast" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 2)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30512); // Facepeeler
						CreateWWeapon(client, "tf_wearable", 30768); // Bedouin Bandana
						CreateWWeapon(client, "tf_wearable", 5623); // Voodoo-Cursed Spy Soul
						
						// Addconds
						//	TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
						TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite); // Crits
					}					
					// Pack #2 Infected Bot
					else if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 2 && team == 2)
					{   	
						// Name
						//char name[13] = "Infected";
						//SetClientInfo(client, "name", name);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 30651); // The Graylien
						CreateWWeapon(client, "tf_wearable", 30128); // The Belgian Detective
						CreateWWeapon(client, "tf_wearable", 5623); // Voodoo-Cursed Spy Soul
						
						// Addconds
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite); // Crits
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
				}
			}
			case TFClass_Engineer:
			{
				if (StrContains( currentMap, "pl_snowycoast" , false) != -1 || StrContains( currentMap, "pd_watergate" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3)
					{   	
						// Weapons
						TF2_RemoveWeaponSlot(client, 0);
							
						CreateWeapon(client, "tf_weapon_shotgun_primary", 527);
							
						// Cosmetics
						CreateWWeapon(client, "tf_wearable", 30654); // Life Support System
						CreateWWeapon(client, "tf_wearable", 655); // The Spirit of Giving 
						CreateWWeapon(client, "tf_wearable", 31151); // The Ghoul Box
						CreateWWeapon(client, "tf_wearable", 30995); // Dell in a shell
						CreateWWeapon(client, "tf_wearable", 30168); // Special Eyes
						CreateWWeapon(client, "tf_wearable", 30254); // Unidentified Following Object
						
						// Addconds
						//TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
						//TF2_AddCondition(client, TFCond_Gas, TFCondDuration_Infinite);
					}
				}
			}
		}	
		
		// Check for tpose issues. (civilian mode)
		CreateTimer(2.0, TposeFix, client, TIMER_FLAG_NO_MAPCHANGE);
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

public Action TposeFix(Handle timer, any client)
{
	// Civilian Fixer (tpose) Sometimes bots fuck out and we gotta do something about it.
	if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == -1) 
	{
		// Simply try switching to every weapon available until we're good.
		TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
		TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
		TF2_SwitchtoSlot(client, TFWeaponSlot_Primary); 
			
		// If we're still fucked try brute forcing it.
		if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == -1) 
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

// Bot Bosses Desperation Code
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsPlayerHere(client))
	{	
		TFClassType class = TF2_GetPlayerClass(client);
		int team = GetClientTeam(client);
		int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		int MaxBossHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		char currentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(currentMap, sizeof(currentMap));
		switch (class)
		{
			case TFClass_Scout:
			{
				if (StrContains( currentMap, "ctf_2fort_invasion" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						if(buttons & IN_ATTACK)
						{
							moveForward(vel, 300.0);
						}
					}
				}
			}
			case TFClass_Sniper:
			{

			}
			case TFClass_Soldier:
			{
				if (StrContains( currentMap, "ctf_2fort_invasion" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						if(buttons & IN_ATTACK)
						{
							moveForward(vel, 300.0);
						}
					}
				}
			}
			case TFClass_DemoMan:
			{

			}
			case TFClass_Medic:
			{

			}
			case TFClass_Heavy:
			{			
				// Check Maps
				if (StrContains( currentMap, "cp_badlands" , false) != -1)
				{
					// Pack #1 MISSION BOSS
					// The Commander
					// If the boss is getting low let's add a final buff.
					// THIS IS DESPERATION MODE
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3 && CurrentHealth < (MaxBossHealth / 1.5)) 	
					{   	
						if(boss_pinch_mode == 0)
						{
							// Weapons
							// Remove Primary And Secondary!
							// Forcing The Commander to use melee!
							TF2_RemoveWeaponSlot(client, 0);
							TF2_RemoveWeaponSlot(client, 1);
							//TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
							//TF2_RemoveCondition(client, TFCond_MeleeOnly);
							TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
						
							// Weapon Switching
							TF2_SwitchtoSlot(client, TFWeaponSlot_Melee); 
						
							// Addconds
							TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite); // Give him crits!
							TF2_AddCondition(client, TFCond_RuneHaste, TFCondDuration_Infinite); // Goes mega fast.
							TF2_AddCondition(client, TFCond_HalloweenQuickHeal, TFCondDuration_Infinite); // Heals.
							//TF2_AddCondition(client, TFCond_DodgeChance, TFCondDuration_Infinite); // Not every hit counts.
							TF2_AddCondition(client, TFCond_UberBulletResist, TFCondDuration_Infinite); // Resists bullets.
							
							// Health
							boss_health = 2550;
							SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
							SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
							SetEntityHealth(client, boss_health); // Do this to fix health bar.
							//RemoveBossHealthTarget(client); // Remove health bar to reset max health.
							//SetBossHealthTarget(client); // Add health bar for boss!

							ServerCommand("wait 66; playgamesound vo/cp_badlands/boss_pinch.mp3");
							ServerCommand("wait 66; sm_cvar tf_damage_multiplier_blue 0.75");
							ServerCommand("wait 66; exec missions/cp_badlands/pinch_mode.cfg"); // Do this for client commands like shake!
							boss_pinch_mode = 1;
						}
					}
				}
			}
			case TFClass_Pyro:
			{		
				if (StrContains( currentMap, "ctf_2fort_invasion" , false) != -1)
				{
					// Pack #2 Infected Bot
					if(GetEntProp(client, Prop_Send, "m_nBotSkill") == 3 && team == 3)
					{   	
						if(buttons & IN_ATTACK)
						{
							moveForward(vel, 300.0);
						}
					}
				}
			}
			case TFClass_Spy:
			{

			}
			case TFClass_Engineer:
			{

			}
		}
	}
}