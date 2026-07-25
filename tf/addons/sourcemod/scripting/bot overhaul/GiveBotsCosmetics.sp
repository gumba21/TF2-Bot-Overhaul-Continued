#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.10"

bool g_bTouched[MAXPLAYERS+1];
bool g_bMVM;
bool g_bLateLoad;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
ConVar g_hCVDecreaseChance;
Handle g_hWearableEquip;
Handle g_hGameConfig;
bool face;

public Plugin myinfo =
{
	name = "Give Bots Cosmetics",
	author = "luki1412",
	description = "Gives TF2 bots cosmetics",
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
	ConVar hCVversioncvar = CreateConVar("sm_gbc_version", PLUGIN_VERSION, "Give Bots Cosmetics version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVEnabled = CreateConVar("sm_gbc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbc_delay", "0.1", "Delay for giving cosmetics to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam = CreateConVar("sm_gbc_team", "1", "Team to give cosmetics to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	g_hCVDecreaseChance = CreateConVar("sm_decrease_chance", "0", "Decrease chance of giving bots cosmetics to improve performance and simulate pubs more.", FCVAR_NONE, true, 0.0, true, 1.0);

	HookEvent("post_inventory_application", player_inv);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);

	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Cosmetics");

	if (g_bLateLoad)
	{
		OnMapStart();
	}

	g_hGameConfig = LoadGameConfigFile("give.bots.cosmetics");

	if (!g_hGameConfig)
	{
		SetFailState("Failed to find give.bots.cosmetics.txt gamedata! Can't continue.");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving cosmetics. Try updating gamedata or restarting your server.");
	}
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
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
	if (!GetConVarInt(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	int team = GetClientTeam(client);

	if (!g_bTouched[client] && !g_bMVM && IsPlayerHere(client) || team == 2 && !g_bTouched[client] && g_bMVM == true && IsPlayerHere(client))
	{
		g_bTouched[client] = true;
		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam);
		float timer = GetConVarFloat(g_hCVTimer);

		switch (team2)
		{
			case 1:
			{
				if(GetConVarBool(g_hCVDecreaseChance) && GetRandomUInt(0, 3) != 0 || !GetConVarBool(g_hCVDecreaseChance))
				{
					CreateTimer(timer, Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 2:
			{
				if (team == 2 && GetConVarBool(g_hCVDecreaseChance) && GetRandomUInt(0, 3) != 0 || team == 2 && !GetConVarBool(g_hCVDecreaseChance))
				{
					CreateTimer(timer, Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 3:
			{
				if (team == 3 && GetConVarBool(g_hCVDecreaseChance) && GetRandomUInt(0, 3) != 0 || team == 3 && !GetConVarBool(g_hCVDecreaseChance))
				{
					CreateTimer(timer, Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action Timer_GiveHat(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;

	if (!GetConVarInt(g_hCVEnabled) || !IsPlayerHere(client))
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

	if (!g_bMVM || g_bMVM == true && team == 2)
	{
		face = false;
		TFClassType class = TF2_GetPlayerClass(client);

		switch (class)
		{
			case TFClass_Scout:
			{
				int rnd = GetRandomUInt(0,153);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 30811, 15); // Pestering Jester
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 52, 6); // Batter's Helmet
					}
					case 107:
					{
						CreateHat(client, 106, 6); // Bonk Helm
					}
					case 108:
					{
						CreateHat(client, 107, 6); // Ye Olde Baker Boy
					}
					case 109:
					{
						CreateHat(client, 111, 6); // Baseball Bill's Sports Shine
					}
					case 110:
					{
						CreateHat(client, 150, 6); // Troublemaker's Tossle Cap
					}
					case 111:
					{
						CreateHat(client, 174, 6); // Whoopee Cap
					}
					case 112:
					{
						CreateHat(client, 219, 6); // The Milkman
					}
					case 113:
					{
						CreateHat(client, 249, 6); // Bombing Run
					}
					case 114:
					{
						CreateHat(client, 324, 6); // Flipped Trilby
					}
					case 115:
					{
						CreateHat(client, 346, 6); // The Superfan
					}
					case 116:
					{
						CreateHat(client, 453, 6); // Hero's Tail
					}
					case 117:
					{
						CreateHat(client, 539, 6); // The El Jefe
					}
					case 118:
					{
						CreateHat(client, 617, 6); // The Backwards Ballcap
					}
					case 119:
					{
						CreateHat(client, 633, 6); // The Hermes
					}
					case 120:
					{
						CreateHat(client, 652, 6); // The Big Elfin Deal
					}
					case 121:
					{
					CreateHat(client, 760, 6); // The Front Runner
					}
					case 123:
					{
						CreateHat(client, 765, 6); // The Cross-Comm Express
						face = true;
					}
					case 124:
					{
						CreateHat(client, 780, 6); // The Fed-Fightin' Fedora
					}
					case 125:
					{
						CreateHat(client, 788, 6); // The Void Monk Hair
					}
					case 126:
					{
						CreateHat(client, 846, 6); // The Robot Running Man
					}
					case 127:
					{
						CreateHat(client, 853, 6); // The Crafty Hair
					}
					case 128:
					{
						CreateHat(client, 1012, 6); // The Wilson Weave
					}
					case 129:
					{
						CreateHat(client, 1040, 6); // The Bacteria Blocker
					}
					case 130:
					{
						CreateHat(client, 30019, 6); // Ye Oiled Baker Boy
					}
					case 131:
					{
						CreateHat(client, 30030, 6); // Bonk Leadwear
					}
					case 132:
					{
						CreateHat(client, 30059, 6); // The Beastly Bonnet
					}
					case 133:
					{
						CreateHat(client, 30078, 6); // Greased Lightning
					}
					case 134:
					{
						CreateHat(client, 30326, 6); // The Scout Shako
					}
					case 135:
					{
						CreateHat(client, 30332, 6); // Runner's Warm-up
						face = true;
					}
					case 136:
					{
						CreateHat(client, 30394, 6); // The Frickin' Sweet Ninja Hood
						face = true;
					}
					case 137:
					{
						CreateHat(client, 30428, 6); // The Pomade Prince
					}
					case 138:
					{
						CreateHat(client, 30479, 6); // Thirst Blood
					}
					case 139:
					{
						CreateHat(client, 30573, 6); // Mountebank's Masque
						face = true;
					}
					case 140:
					{
						CreateHat(client, 30636, 15); // Fortunate Son
					}
					case 141:
					{
						CreateHat(client, 30993, 15); // Punk's Pomp
					}
					case 142:
					{
						CreateHat(client, 30977, 15); // Antarctic Eyewear
					}
					case 143:
					{
						CreateHat(client, 30767, 15); // Airdog
						face = true;
					}
					case 144:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 145:
					{
						CreateHat(client, 31023, 15); // Millennial Mercenary
						face = true;
					}
					case 146:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 147:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 148:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 149:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 150:
					{
						CreateHat(client, 30718, 15); // B'aaarrgh-n-Bicorne
					}
					case 151:
					{
						CreateHat(client, 30686, 15); // Death Racer's Helmet
					}
					case 152:
					{
						CreateHat(client, 30809, 6); // Wing Mann
					}
					case 153:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
				}
			}
			case TFClass_Sniper:
			{
				int rnd = GetRandomUInt(0,153);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 30811, 15); // Pestering Jester
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 631, 6); // The Hat With No Name
					}
					case 107:
					{
						CreateHat(client, 30212, 6); // The Snaggletoothed Stetson
					}
					case 108:
					{
						CreateHat(client, 53, 6); // Trophy Belt
					}
					case 109:
					{
						CreateHat(client, 109, 6); // Professional's Panama
					}
					case 110:
					{
						CreateHat(client, 110, 6); // Master's Yellow Belt
					}
					case 111:
					{
						CreateHat(client, 117, 6); // Ritzy Rick's Hair Fixative
					}
					case 112:
					{
						CreateHat(client, 158, 6); // Shooter's Sola Topi
					}
					case 113:
					{
						CreateHat(client, 181, 6); // Bloke's Bucket Hat
					}
					case 114:
					{
						CreateHat(client, 229, 6); // Ol' Snaggletooth
					}
					case 115:
					{
						CreateHat(client, 314, 6); // Larrikin Robin
					}
					case 116:
					{
						CreateHat(client, 344, 6); // Crocleather Slouch
					}
					case 117:
					{
						CreateHat(client, 400, 6); // Desert Maurader
					}
					case 118:
					{
						CreateHat(client, 518, 6); // The Anger
						face = true;
					}
					case 119:
					{
						CreateHat(client, 600, 6); // Your Worst Nightmare
					}
					case 120:
					{
					CreateHat(client, 626, 6); // The Swagman's Swatter
					}
					case 121:
					{
						CreateHat(client, 720, 6); // The Bushman's Boonie
					}
					case 122:
					{
					CreateHat(client, 759, 6); // The Fruit Shoot
					}
					case 123:
					{
						CreateHat(client, 762, 6); // Flamingo Kid
					}
					case 124:
					{
						CreateHat(client, 779, 6); // Liquidator's Lid
						face = true;
					}
					case 125:
					{
						CreateHat(client, 819, 6); // The Lone Star
						face = true;
					}
					case 126:
					{
						CreateHat(client, 819, 6); // The Bolted Bushman
					}
					case 127:
					{
						CreateHat(client, 819, 6); // The Stovepipe Sniper Shako
					}
					case 128:
					{
						CreateHat(client, 981, 6); // The Cold Killer
						face = true;
					}
					case 129:
					{
						CreateHat(client, 1022, 6); // The Sydney Straw Boat
					}
					case 130:
					{
						CreateHat(client, 1029, 6); // The Bloodhound
					}
					case 131:
					{
						CreateHat(client, 1095, 6); // The Dread Riding Hood
						face = true;
					}
					case 132:
					{
						CreateHat(client, 30002, 6); // Letch's LED
						face = true;
					}
					case 133:
					{
						CreateHat(client, 30004, 6); // Soldered Sensei
					}
					case 134:
					{
						CreateHat(client, 30005, 6); // Shooter's Tin Topi
					}
					case 135:
					{
						CreateHat(client, 30135, 6); // Wet Works
					}
					case 136:
					{
						CreateHat(client, 30173, 6); // Brim-Full Of Bullets
					}
					case 137:
					{
						CreateHat(client, 30316, 6); // The Toy Soldier
					}
					case 138:
					{
						CreateHat(client, 30375, 6); // The Deep Cover Operator
					}
					case 139:
					{
						CreateHat(client, 30598, 6); // Professional's Ushanka
						face = true;
					}
					case 140:
					{
						CreateHat(client, 30648, 6); // Corona Australis
						face = true;
					}
					case 141:
					{
						CreateHat(client, 30978, 15); // Head Hedge
					}
					case 142:
					{
						CreateHat(client, 30893, 15); // Classy Capper
					}
					case 143:
					{
						CreateHat(client, 30955, 15); // Handsome Hitman
						face = true;
					}
					case 144:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 145:
					{
						CreateHat(client, 30958, 15); // Puffy Polar Cap
					}
					case 146:
					{
						CreateHat(client, 30977, 15); // Antarctic Eyewear
					}
					case 147:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 148:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 149:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 150:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 151:
					{
						CreateHat(client, 31010, 15); // Highway Star
					}
					case 152:
					{
						CreateHat(client, 30874, 15); // Archer's Sterling
					}
					case 153:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
				}
			}
			case TFClass_Soldier:
			{
				int rnd = GetRandomUInt(0,184);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 853, 6); // The Crafty Hair
					}
					case 107:
					{
						CreateHat(client, 54, 6); // Soldier's Stash
					}
					case 108:
					{
						CreateHat(client, 98, 6); // Stainless Pot
					}
					case 109:
					{
						CreateHat(client, 99, 6); // Tyrant's Helm
					}
					case 120:
					{
						CreateHat(client, 152, 6); // Killer's Kabuto
					}
					case 121:
					{
						CreateHat(client, 183, 6); // Sergeant's Drill Hat
					}
					case 122:
					{
						CreateHat(client, 227, 6); // The Grenadier's Softcap
					}
					case 123:
					{
						CreateHat(client, 240, 6); // Lumbricus Lid
					}
					case 124:
					{
						CreateHat(client, 250, 6); // Chieftain's Challenge
					}
					case 125:
					{
						CreateHat(client, 251, 6); // Stout Shako
					}
					case 126:
					{
						CreateHat(client, 345, 6); // MNC hat
					}
					case 127:
					{
						CreateHat(client, 340, 6); // Defiant Spartan
						face = true;
					}
					case 128:
					{
						CreateHat(client, 378, 6); // The Team Captain
					}
					case 129:
					{
						CreateHat(client, 391, 6); // Honcho's Headgear
						face = true;
					}
					case 130:
					{
						CreateHat(client, 395, 6); // Furious Fukaamigasa
					}
					case 131:
					{
						CreateHat(client, 417, 6); // Jumper's Jeepcap
					}
					case 132:
					{
						CreateHat(client, 434, 6); // Brain Bucket
					}
					case 133:
					{
						CreateHat(client, 439, 6); // Lord Cockswain's Pith Helmet
					}
					case 135:
					{
						CreateHat(client, 445, 6); // Armored Authority
					}
					case 136:
					{
						CreateHat(client, 516, 6); // Stahlhelm
					}
					case 137:
					{
						CreateHat(client, 575, 6); // The Infernal Impaler
						face = true;
					}
					case 138:
					{
						CreateHat(client, 631, 6); // The Hat With No Name
					}
					case 139:
					{
						CreateHat(client, 701, 6); // The Lucky Shot
					}
					case 140:
					{
						CreateHat(client, 30239, 6); // Freedom Feathers
						face = true;
					}
					case 141:
					{
						CreateHat(client, 721, 6); // The Conquistador
					}
					case 142:
					{
						CreateHat(client, 764, 6); // The Cross-Comm Crash Helmet
					}
					case 143:
					{
						CreateHat(client, 732, 6); // The Helmet Without a Name
					}
					case 144:
					{
						CreateHat(client, 829, 6); // The War Pig
					}
					case 145:
					{
						CreateHat(client, 844, 6); // The Tin Pot
					}
					case 146:
					{
						CreateHat(client, 945, 6); // The Chief Constable
					}
					case 147:
					{
					CreateHat(client, 980, 6); // Soldier's Slope Scopers
					}
					case 148:
					{
						CreateHat(client, 1021, 6); // The Doe-Boy
					}
					case 149:
					{
						CreateHat(client, 1021, 1); // The Doe-Boy
					}
					case 150:
					{
						CreateHat(client, 30811, 15); // Pestering Jester
					}
					case 151:
					{
						CreateHat(client, 1090, 6); // Big Daddy
						face = true;
					}
					case 152:
					{
						CreateHat(client, 1091, 6); // The First American
						face = true;
					}
					case 153:
					{
						CreateHat(client, 1093, 6); // The Gilded Guard
					}
					case 154:
					{
						CreateHat(client, 30014, 6); // Tyrantium Helmet
					}
					case 155:
					{
						CreateHat(client, 30017, 6); // Steel Shako
					}
					case 156:
					{
						CreateHat(client, 30026, 6); // Full Metal Drill Hat
					}
					case 157:
					{
						CreateHat(client, 30071, 6); // The Cloud Crasher
					}
					case 158:
					{
						CreateHat(client, 30114, 6); // The Valley Forge
					}
					case 159:
					{
						CreateHat(client, 30116, 6); // The Caribbean Conqueror
					}
					case 160:
					{
						CreateHat(client, 30120, 6); // The Rebel Rouser
					}
					case 161:
					{
						CreateHat(client, 30314, 6); // The Slo-Poke
					}
					case 162:
					{
						CreateHat(client, 30390, 6); // The Spook Specs
						face = true;
					}
					case 163:
					{
						CreateHat(client, 30548, 6); // Screamin' Eagle
					}
					case 164:
					{
						CreateHat(client, 30553, 6); // Condor Cap
					}
					case 165:
					{
						CreateHat(client, 30578, 6); // Skullcap
					}
					case 166:
					{
						CreateHat(client, 30978, 15); // Head Hedge
					}
					case 167:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 168:
					{
						CreateHat(client, 31035, 15); // Dumb Bell
					}
					case 169:
					{
						CreateHat(client, 31024, 15); // Crack Pot
					}
					case 170:
					{
						CreateHat(client, 31025, 15); // Climbing Commander
						face = true;
					}
					case 171:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 172:
					{
						CreateHat(client, 30885, 15); // Nuke
						face = true;
					}
					case 173:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 174:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 175:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 176:
					{
						CreateHat(client, 30708, 15); // Hellmet
					}
					case 178:
					{
						CreateHat(client, 30899, 15); // Crit Cloak
					}
					case 179:
					{
						CreateHat(client, 30897, 15); // Shellmet
					}
					case 180:
					{
						CreateHat(client, 30887, 15); // War Eagle
					}
					case 181:
					{
						CreateHat(client, 30984, 15); // Sky High Fly Guy
					}
					case 182:
					{
						CreateHat(client, 30969, 15); // Brass Bucket
					}
					case 183:
					{
						CreateHat(client, 30338, 6); // Ground Control
					}
					case 184:
					{
						CreateHat(client, 30118, 6); // Whirly Warrior
						face = true;
					}
				}
			}
			case TFClass_DemoMan:
			{
				int rnd = GetRandomUInt(0,168);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 125, 6); // Cheater's Lament
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 1012, 6); // The Wilson Weave
					}
					case 107:
					{
						CreateHat(client, 631, 6); // The Hat With No Name
					}
					case 108:
					{
						CreateHat(client, 47, 6); // Demoman's 'Fro
					}
					case 109:
					{
						CreateHat(client, 100, 6); // Glengarry Bonnet
					}
					case 110:
					{
					CreateHat(client, 120, 6); // Scottsman's Stove Pipe
					}
					case 111:
					{
						CreateHat(client, 146, 6); // Hustler's Hallmark
					}
					case 112:
					{
						CreateHat(client, 179, 6); // Tippler's Tricorne
					}
					case 113:
					{
						CreateHat(client, 216, 6); // Rimmed Raincatcher
					}
					case 114:
					{
						CreateHat(client, 255, 6); // Sober Stuntman
					}
					case 115:
					{
						CreateHat(client, 259, 6); // Carouser's Capotain
					}
					case 116:
					{
						CreateHat(client, 306, 6); // Scotch Bonnet
					}
					case 117:
					{
						CreateHat(client, 342, 6); // Prince Tavish's Crown
					}
					case 118:
					{
						CreateHat(client, 359, 6); // Samur-Eye
					}
					case 119:
					{
						CreateHat(client, 388, 6); // Private Eye
					}
					case 120:
					{
						CreateHat(client, 390, 6); // Reggaelator
					}
					case 121:
					{
						CreateHat(client, 403, 6); // Sultan's Ceremonial
					}
					case 122:
					{
						CreateHat(client, 465, 6); // Conjurer's Cowl
					}
					case 123:
					{
						CreateHat(client, 480, 6); // Tam O'Shanter
					}
					case 124:
					{
						CreateHat(client, 514, 6); // Mask of the Shaman
						face = true;
					}
					case 125:
					{
						CreateHat(client, 604, 6); // The Tavish DeGroot Experience
					}
					case 126:
					{
						CreateHat(client, 607, 6); // The Buccaneer's Bicorne
					}
					case 127:
					{
						CreateHat(client, 703, 6); // The Bolgan
						face = true;
					}
					case 128:
					{
						CreateHat(client, 786, 6); // The Grenadier Helm
					}
					case 129:
					{
						CreateHat(client, 876, 6); // The K-9 Mane
					}
					case 130:
					{
						CreateHat(client, 30016, 6); // The FR-0
					}
					case 131:
					{
						CreateHat(client, 30021, 6); // The Pure Tin Capotain
					}
					case 132:
					{
						CreateHat(client, 30024, 6); // The Cyborg Stunt Helmet
					}
					case 133:
					{
						CreateHat(client, 30029, 6); // The Broadband Bonnet
					}
					case 134:
					{
						CreateHat(client, 30034, 6); // The Bolted Bicorne
					}
					case 135:
					{
						CreateHat(client, 30037, 6); // The Strontium Stovepipe
					}
					case 136:
					{
						CreateHat(client, 30082, 6); // The Glasgow Great Helm
						face = true;
					}
					case 137:
					{
						CreateHat(client, 30105, 6); // The Black Watch
					}
					case 138:
					{
						CreateHat(client, 30106, 6); // The Tartan Spartan
					}
					case 139:
					{
						CreateHat(client, 30112, 6); // The Stormin' Norman
					}
					case 140:
					{
						CreateHat(client, 30180, 6); // Pirate Bandana
					}
					case 141:
					{
						CreateHat(client, 30334, 6); // Tartan Tyrolean
					}
					case 142:
					{
						CreateHat(client, 30340, 6); // Stylish Degroot
					}
					case 143:
					{
						CreateHat(client, 30393, 6); // The Razor Cut
					}
					case 145:
					{
						CreateHat(client, 30421, 6); // The Frontier Djustice
					}
					case 146:
					{
						CreateHat(client, 30429, 6); // The Allbrero
					}
					case 147:
					{
						CreateHat(client, 30547, 6); // Bomber's Bucket Hat
					}
					case 148:
					{
						CreateHat(client, 30586, 6); // Valhalla Helm
						face = true;
					}
					case 149:
					{
						CreateHat(client, 30604, 6); // Scot Bonnet
					}
					case 150:
					{
						CreateHat(client, 30627, 15); // Bruce's Bonnet
					}
					case 151:
					{
						CreateHat(client, 30628, 15); // Outta' Sight
					}
					case 152:
					{
						CreateHat(client, 30519, 6); // Explosive Mind
					}
					case 153:
					{
						CreateHat(client, 30779, 15); // Dayjogger
						face = true;
					}
					case 154:
					{
						CreateHat(client, 30979, 15); // Frag Proof Fragger
						face = true;
					}
					case 155:
					{
						CreateHat(client, 30954, 15); // Hungover Hero
						face = true;
					}
					case 156:
					{
						CreateHat(client, 30064, 6); // The Tartan Shade
					}
					case 157:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 158:
					{
						CreateHat(client, 30977, 15); // Antarctic Eyewear
					}
					case 159:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 160:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 161:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 162:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 163:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
					case 164:
					{
						CreateHat(client, 30823, 15); // Bomb Beanie
					}
					case 165:
					{
						CreateHat(client, 30830, 15); // Bomber Knight
					}
					case 167:
					{
						CreateHat(client, 30836, 15); // Elf Esteem
					}
					case 168:
					{
						CreateHat(client, 30887, 15); // War Eagle
					}
				}
			}
			case TFClass_Medic:
			{
				int rnd = GetRandomUInt(0,156);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 125, 6); // Cheater's Lament
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 853, 6); // The Crafty Hair
					}
					case 107:
					{
						CreateHat(client, 1012, 6); // The Wilson Weave
					}
					case 108:
					{
						CreateHat(client, 378, 6); // The Team Captain
					}
					case 109:
					{
						CreateHat(client, 388, 6); // Private Eye
					}
					case 110:
					{
						CreateHat(client, 50, 6); // Prussian Pickelhaube
					}
					case 111:
					{
						CreateHat(client, 101, 6); // Vintage Tyrolean
					}
					case 112:
					{
						CreateHat(client, 104, 6); // Otolaryngologist's Mirror
					}
					case 113:
					{
						CreateHat(client, 184, 6); // Gentleman's Gatsby
					}
					case 114:
					{
						CreateHat(client, 323, 6); // German Gonzila
					}
					case 115:
					{
						CreateHat(client, 363, 6); // Geisha Boy
					}
					case 116:
					{
						CreateHat(client, 381, 6); // Medic's Mountain Cap
					}
					case 117:
					{
						CreateHat(client, 383, 6); // Grimm Hatte
					}
					case 118:
					{
						CreateHat(client, 398, 6); // Doctor's Sack
					}
					case 119:
					{
						CreateHat(client, 467, 6); // Planeswalker Helm
						face = true;
					}
					case 120:
					{
						CreateHat(client, 616, 6); // The Surgeon's Stahlhelm
					}
					case 121:
					{
						CreateHat(client, 778, 6); // The Gentlemen's Ushanka
					}
					case 122:
					{
						CreateHat(client, 867, 6); // The Combat Medic's Crusher Cap
					}
					case 123:
					{
						CreateHat(client, 1039, 6); // The Weather Master
						face = true;
					}
					case 124:
					{
						CreateHat(client, 30041, 6); // Halogen Head Lamp
					}
					case 125:
					{
						CreateHat(client, 30042, 6); // Platinum Pickelhaube
					}
					case 126:
					{
						CreateHat(client, 30043, 6); // The Virus Doctor
					}
					case 127:
					{
						CreateHat(client, 30045, 6); // Titanium Tyrolean
					}
					case 128:
					{
						CreateHat(client, 30069, 6); // The Powdered Practitioner
					}
					case 129:
					{
						CreateHat(client, 30097, 6); // Das Ubersternmann
					}
					case 130:
					{
						CreateHat(client, 30109, 6); // Das Naggenvatcher
					}
					case 131:
					{
						CreateHat(client, 30121, 6); // Das Maddendoktor
					}
					case 132:
					{
						CreateHat(client, 30127, 6); // Das Gutenkutteharen
					}
					case 133:
					{
						CreateHat(client, 30136, 6); // Baron von Havenaplane
					}
					case 134:
					{
						CreateHat(client, 30187, 6); // The Slick Cut
					}
					case 135:
					{
						CreateHat(client, 30311, 6); // The Nunhood
					}
					case 136:
					{
						CreateHat(client, 30318, 6); // The Mann of Reason
					}
					case 137:
					{
						CreateHat(client, 30318, 6); // The Teutonic Toque
					}
					case 138:
					{
					CreateHat(client, 30378, 6); // Heer's Helm
					}
					case 139:
					{
						CreateHat(client, 30596, 6); // Surgeon's Shako
					}
					case 140:
					{
						CreateHat(client, 30625, 15); // The Physician's Protector
					}
					case 141:
					{
						CreateHat(client, 30862, 15); // Field Practice
					}
					case 142:
					{
						CreateHat(client, 30939, 15); // Coldfront Commander
					}
					case 143:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 144:
					{
						CreateHat(client, 31034, 6); // Mighty Mitre
					}
					case 145:
					{
						CreateHat(client, 31028, 15); // Snowcapped
						face = true;
					}
					case 146:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 147:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 148:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 149:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 150:
					{
						CreateHat(client, 30755, 15); // Berlin Brain Bowl
					}
					case 151:
					{
						CreateHat(client, 30792, 6); // Colossal Cranium
						face = true;
					}
					case 152:
					{
						CreateHat(client, 30907, 15); // Battle Boonie
					}
					case 153:
					{
						CreateHat(client, 30786, 15); // Gauzed Gaze
						face = true;
					}
					case 154:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
					case 155:
					{
						CreateHat(client, 30095, 6); // Das Hazmattenhatten
					}
					case 156:
					{
						CreateHat(client, 30095, 11); // Das Hazmattenhatten
					}
				}
			}
			case TFClass_Heavy:
			{
				int rnd = GetRandomUInt(0,216);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 125, 6); // Cheater's Lament
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 853, 6); // The Crafty Hair
					}
					case 107:
					{
						CreateHat(client, 1012, 6); // The Wilson Weave
					}
					case 108:
					{
						CreateHat(client, 378, 6); // The Team Captain
					}
					case 109:
					{
						CreateHat(client, 876, 6); // The K-9 Mane
					}
					case 110:
					{
						CreateHat(client, 49, 6); // Football Helmet
					}
					case 111:
					{
						CreateHat(client, 96, 6); // Officer's Ushanka
					}
					case 112:
					{
						CreateHat(client, 97, 6); // Tough Guy's Toque
					}
					case 113:
					{
						CreateHat(client, 145, 6); // Hound Dog
						face = true;
					}
					case 114:
					{
						CreateHat(client, 185, 6); // Heavy Duty Rag
					}
					case 115:
					{
						CreateHat(client, 246, 6); // Pugilist's Protector
					}
					case 116:
					{
						CreateHat(client, 254, 6); // Hard Counter
					}
					case 117:
					{
						CreateHat(client, 290, 6); // Cadaver's Cranium
					}
					case 118:
					{
						CreateHat(client, 292, 6); // Poker Visor
					}
					case 119:
					{
						CreateHat(client, 309, 6); // Big Chief
					}
					case 120:
					{
						CreateHat(client, 313, 6); // Magnificent Mongolian
					}
					case 121:
					{
						CreateHat(client, 330, 6); // Coupe D'isaster
					}
					case 122:
					{
						CreateHat(client, 358, 6); // Dread Knot
					}
					case 123:
					{
						CreateHat(client, 380, 6); // Large Luchadore
						face = true;
					}
					case 124:
					{
						CreateHat(client, 427, 6); // Capo's Capper
					}
					case 125:
					{
						CreateHat(client, 478, 6); // Copper's Hard Top
					}
					case 126:
					{
						CreateHat(client, 515, 6); // Pilotka
					}
					case 127:
					{
						CreateHat(client, 517, 6); // Dragonborn Helmet
					}
					case 128:
					{
						CreateHat(client, 535, 6); // Storm Spirit's Jolly Hat
					}
					case 129:
					{
						CreateHat(client, 585, 6); // Cold War Luchador
						face = true;
					}
					case 130:
					{
						CreateHat(client, 601, 6); // The One-Man Army
					}
					case 131:
					{
						CreateHat(client, 603, 6); // The Outdoorsman
					}
					case 132:
					{
						CreateHat(client, 613, 6); // The Gym Rat
					}
					case 133:
					{
						CreateHat(client, 635, 6); // War Head
					}
					case 134:
					{
						CreateHat(client, 840, 6); // The U-clank-a
					}
					case 135:
					{
						CreateHat(client, 866, 6); // The Heavy Artillery Officer's Cap
					}
					case 136:
					{
						CreateHat(client, 952, 6); // Brock's Locks
					}
					case 137:
					{
						CreateHat(client, 985, 6); // Heavy's Hockey Hair
					}
					case 138:
					{
						CreateHat(client, 989, 6); // The Carl
						face = true;
					}
					case 139:
					{
						CreateHat(client, 1018, 6); // The Pounding Father
					}
					case 140:
					{
						CreateHat(client, 30013, 6); // The Gridiron Guardian
					}
					case 141:
					{
						CreateHat(client, 30049, 6); // The Tungsten Toque
					}
					case 142:
					{
						CreateHat(client, 30054, 6); // The Bunsen Brave
					}
					case 143:
					{
						CreateHat(client, 30081, 6); // The Tsarboosh
					}
					case 144:
					{
						CreateHat(client, 30094, 6); // The Katyusha
					}
					case 145:
					{
						CreateHat(client, 30122, 6); // The Bear Necessities
					}
					case 146:
					{
						CreateHat(client, 30315, 6); // Minnesota Slick
					}
					case 147:
					{
						CreateHat(client, 30344, 6); // Bullet Buzz
					}
					case 148:
					{
						CreateHat(client, 30346, 6); // The Trash Man
					}
					case 149:
					{
						CreateHat(client, 30369, 6); // The Eliminators Safeguard
					}
					case 150:
					{
						CreateHat(client, 30374, 6); // The Sammy Cap
					}
					case 151:
					{
						CreateHat(client, 30545, 6); // Fur-lined Fighter
					}
					case 152:
					{
						CreateHat(client, 30589, 6); // Siberian Facehugger
						face = true;
					}
					case 153:
					{
						CreateHat(client, 30589, 6); // Old Man Frost
						face = true;
					}
					case 154:
					{
						CreateHat(client, 30644, 15); // White Russian
					}
					case 155:
					{
						CreateHat(client, 30653, 15); // Sucker Slug
					}
					case 156:
					{
					CreateHat(client, 30914, 15); // Aztec Aggressor
					}
					case 157:
					{
						CreateHat(client, 30912, 15); // Commando Elite
					}
					case 158:
					{
						CreateHat(client, 30911, 15); // Fat Man's Field Cap
					}
					case 159:
					{
						CreateHat(client, 1187, 6); // Kathman-Hairdo
						face = true;
					}
					case 200:
					{
						CreateHat(client, 30887, 15); // War Eagle
					}
					case 201:
					{
						CreateHat(client, 30885, 15); // Nuke
						face = true;
					}
					case 202:
					{
						CreateHat(client, 1087, 6); // Der Maschinensoldaten-Helm
					}
					case 203:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 204:
					{
						CreateHat(client, 31029, 6); // Cool Capuchon
					}
					case 205:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 206:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 207:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 208:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 209:
					{
						CreateHat(client, 821, 6); // Soviet Gentleman
						face = true;
					}
					case 210:
					{
						CreateHat(client, 30959, 15); // Sinner's Shade
					}
					case 211:
					{
						CreateHat(client, 30960, 15); // Wild West Whiskers
					}
					case 212:
					{
						CreateHat(client, 30981, 15); // Starboard Crusader
					}
					case 213:
					{
						CreateHat(client, 30866, 15); // Warhood
						face = true;
					}
					case 214:
					{
						CreateHat(client, 31008, 15); // Mann-O-War
					}
					case 215:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
					case 216:
					{
						CreateHat(client, 30811, 15); // Pestering Jester
					}
				}
			}
			case TFClass_Pyro:
			{
				int rnd = GetRandomUInt(0,166);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 125, 6); // Cheater's Lament
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 51, 6); // Pyro's Beanie
					}
					case 107:
					{
						CreateHat(client, 102, 6); // Respectless Rubber Glove
					}
					case 108:
					{
						CreateHat(client, 105, 6); // Brigade Helm
					}
					case 109:
					{
						CreateHat(client, 151, 6); // Triboniophorus Tyrannus
					}
					case 110:
					{
						CreateHat(client, 182, 6); // Vintage Merryweather
					}
					case 111:
					{
						CreateHat(client, 213, 6); // The Attendant
					}
					case 112:
					{
						CreateHat(client, 247, 6); // Old Guadalajara
					}
					case 113:
					{
						CreateHat(client, 248, 6); // Napper's Respite
					}
					case 114:
					{
						CreateHat(client, 253, 6); // Handyman's Handle
					}
					case 115:
					{
						CreateHat(client, 316, 6); // Pyromancer's Mask
						face = true;
					}
					case 116:
					{
						CreateHat(client, 318, 6); // Prancer's Pride
					}
					case 117:
					{
						CreateHat(client, 321, 6); // Madame Dixie
					}
					case 118:
					{
						CreateHat(client, 377, 6); // Hottie's Hoodie
					}
					case 119:
					{
						CreateHat(client, 394, 6); // Connoisseur's Cap
					}
					case 120:
					{
						CreateHat(client, 435, 6); // Dead Cone
					}
					case 121:
					{
						CreateHat(client, 481, 6); // Stately Steel Toe
					}
					case 122:
					{
						CreateHat(client, 597, 6); // The Bubble Pipe
					}
					case 123:
					{
					CreateHat(client, 612, 6); // The Little Buddy
					}
					case 124:
					{
					CreateHat(client, 615, 6); // The Birdcage
					}
					case 125:
					{
						CreateHat(client, 627, 6); // The Flamboyant Flamenco
					}
					case 126:
					{
						CreateHat(client, 644, 6); // The Head Warmer
						face = true;
					}
					case 127:
					{
						CreateHat(client, 753, 6); // The Waxy Wayfinder
					}
					case 128:
					{
						CreateHat(client, 854, 6); // Area 451
						face = true;
					}
					case 129:
					{
						CreateHat(client, 937, 6); // The Wraith Wrap
					}
					case 130:
					{
						CreateHat(client, 949, 6); // The DethKapp
					}
					case 131:
					{
						CreateHat(client, 1031, 6); // The Necronomicrown
					}
					case 132:
					{
						CreateHat(client, 30022, 6); // Plumber's Pipe
					}
					case 133:
					{
						CreateHat(client, 30025, 6); // The Electric Escorter
					}
					case 134:
					{
						CreateHat(client, 30028, 6); // The Metal Slug
					}
					case 135:
					{
						CreateHat(client, 30038, 6); // Firewall Helmet
					}
					case 136:
					{
						CreateHat(client, 30039, 6); // Respectless Robo-Glove
					}
					case 137:
					{
						CreateHat(client, 30040, 6); // Pyro's Boron Beanie
					}
					case 138:
					{
						CreateHat(client, 30057, 6); // Bolted Birdcage
					}
					case 139:
					{
						CreateHat(client, 30063, 6); // The Centurion
					}
					case 140:
					{
						CreateHat(client, 30091, 6); // The Burning Bandana
					}
					case 141:
					{
						CreateHat(client, 30093, 6); // The Hive Minder
					}
					case 142:
					{
						CreateHat(client, 30139, 6); // The Pampered Pyro
					}
					case 143:
					{
						CreateHat(client, 30162, 6); // The Bone Dome
					}
					case 144:
					{
						CreateHat(client, 30327, 6); // The Toy Tailor
					}
					case 145:
					{
						CreateHat(client, 30355, 6); // Sole Mate
					}
					case 146:
					{
						CreateHat(client, 30399, 6); // The Smoking Skid Lid
					}
					case 147:
					{
						CreateHat(client, 30416, 6); // Employee of the Mmmph
					}
					case 148:
					{
						CreateHat(client, 30418, 6); // The Combustable Kabuto
					}
					case 149:
					{
					CreateHat(client, 30580, 6); // Pyromancer's Hood
					}
					case 150:
					{
						CreateHat(client, 30662, 15); // A Head Full of Hot Air
					}
					case 151:
					{
						CreateHat(client, 30684, 15); // Neptune's Nightmare
						face = true;
					}
					case 152:
					{
						CreateHat(client, 30936, 15); // Burning Beanie
					}
					case 153:
					{
						CreateHat(client, 30937, 15); // Cat's Pajamas
					}
					case 154:
					{
						CreateHat(client, 30987, 15); // Burning Question
					}
					case 155:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 156:
					{
						CreateHat(client, 30739, 6); // Fear Monger
						face = true;
					}
					case 157:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 158:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 159:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 160:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 161:
					{
					CreateHat(client, 1177, 1); // Audio File
					}
					case 162:
					{
						CreateHat(client, 31006, 15); // Mr. Quackers
					}
					case 163:
					{
					CreateHat(client, 30903, 15); // Feathered Fiend
					}
					case 164:
					{
						CreateHat(client, 30799, 15); // Combustible Cutie
					}
					case 165:
					{
						CreateHat(client, 30800, 15); // Cranial Carcharodon
					}
					case 166:
					{
						CreateHat(client, 30811, 15); // Pestering Jester
					}
				}
			}
			case TFClass_Spy:
			{
				int rnd = GetRandomUInt(0,144);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 125, 6); // Cheater's Lament
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 388, 6); // Private Eye
					}
					case 107:
					{
					CreateHat(client, 30195, 6); // Ethereal Hood
					}
					case 108:
					{
						CreateHat(client, 1029, 6); // The Bloodhound
					}
					case 109:
					{
						CreateHat(client, 30375, 6); // The Deep Cover Operator
					}
					case 110:
					{
						CreateHat(client, 55, 6); // Fancy Fedora
					}
					case 111:
					{
						CreateHat(client, 108, 6); // Backbiter's Billycock
					}
					case 112:
					{
						CreateHat(client, 147, 6); // Magistrate's Mullet
					}
					case 113:
					{
						CreateHat(client, 180, 6); // Frenchman's Beret
					}
					case 114:
					{
						CreateHat(client, 223, 6); // The Familiar Fez
						face = true;
					}
					case 115:
					{
						CreateHat(client, 319, 6); // Detective Noir
					}
					case 116:
					{
						CreateHat(client, 397, 6); // Charmer's Chapeau
					}
					case 117:
					{
						CreateHat(client, 437, 6); // Janissary Ketche
					}
					case 118:
					{
						CreateHat(client, 459, 6); // Cosa Nostra Cap
					}
					case 119:
					{
						CreateHat(client, 521, 6); // Nanobalaclava
						face = true;
					}
					case 120:
					{
						CreateHat(client, 602, 6); // The Counterfeit Billycock
					}
					case 121:
					{
						CreateHat(client, 622, 6); // L'Inspecteur
					}
					case 122:
					{
						CreateHat(client, 637, 6); // The Dashin' Hashshashin
					}
					case 123:
					{
						CreateHat(client, 789, 6); // The Ninja Cowl
					}
					case 124:
					{
						CreateHat(client, 841, 6); // The Stealth Steeler
					}
					case 125:
					{
						CreateHat(client, 872, 6); // The Lacking Moral Fiber Mask
						face = true;
					}
					case 126:
					{
						CreateHat(client, 30007, 6); // Base Metal Billycock
					}
					case 127:
					{
						CreateHat(client, 30047, 6); // Bootleg Base Metal Billycock
					}
					case 128:
					{
						CreateHat(client, 30072, 6); // The Pom-Pommed Provocateur
						face = true;
					}
					case 129:
					{
						CreateHat(client, 30123, 6); // The Harmburg
					}
					case 130:
					{
						CreateHat(client, 30128, 6); // The Belgian Detective
						face = true;
					}
					case 131:
					{
						CreateHat(client, 30182, 6); // L'homme Burglerre
						face = true;
					}
					case 132:
					{
						CreateHat(client, 30360, 6); // The Napolean Complex
					}
					case 133:
					{
						CreateHat(client, 30404, 6); // The Aviator Assassin
					}
					case 134:
					{
						CreateHat(client, 825, 6); // Hat of Cards
					}
					case 135:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 136:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 137:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 138:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 139:
					{
						CreateHat(client, 30469, 1); // Horace
					}
					case 140:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
					case 141:
					{
						CreateHat(client, 31016, 15); // Murderer's Motif
					}
					case 142:
					{
						CreateHat(client, 30827, 15); // Brain-Warming Wear
					}
					case 143:
					{
						CreateHat(client, 30798, 15); // Big Topper
						face = true;
					}
					case 144:
					{
						CreateHat(client, 30753, 15); // A Hat to Kill For
					}
				}
			}
			case TFClass_Engineer:
			{
				int rnd = GetRandomUInt(0,151);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); // Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); // The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); // The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); // The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); // Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); // Killer Exclusive
					}
					case 7:
					{
						CreateHat(client, 139, 6); // Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); // Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); // Towering Pillar of Hats
					}
					case 10:
					{
						CreateHat(client, 30119, 6); // The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); // Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); // A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); // The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); // The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); // The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); // The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); // The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 19:
					{
						CreateHat(client, 984, 6); // Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); // The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); // The Brotherhood of Arms
					}
					case 22:
					{
						CreateHat(client, 30067, 6); // The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); // The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); // Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); // The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); // Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); // The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); // The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); // The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); // Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); // The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); // Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); // The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); // The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); // Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); // Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 261, 6); //  Mann Co. Cap
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); // Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); // Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); // Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); // Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); // That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); // Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 471, 6); //  Proof Of Purchase
					}
					case 45:
					{
						CreateHat(client, 30473, 6); // MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); // Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 756, 6); //  Bolt Action Blitzer
					}
					case 48:
					{
						CreateHat(client, 994, 6); // Mann Co. Online Cap
					}
					case 49:
					{
						CreateHat(client, 1169, 6); // Military Grade JACK Hat
					}
					case 50:
					{
						CreateHat(client, 584, 6); // Ghastlierest Gibus
					}
					case 51:
					{
						CreateHat(client, 1191, 6); //  Mercenary Park Cap
					}
					case 52:
					{
						CreateHat(client, 1186, 6); //  The Monstrous Memento
					}
					case 53:
					{
						CreateHat(client, 1185, 6); //  Saxton
					}
					case 54:
					{
						CreateHat(client, 30704, 15); // Prehistoric Pullover
					}
					case 55:
					{
						CreateHat(client, 30700, 15); // Duck Billed Hatypus
					}
					case 56:
					{
						CreateHat(client, 30746, 15); // A Well Wrapped Hat
					}
					case 57:
					{
						CreateHat(client, 30748, 15); // Chill Chullo
					}
					case 58:
					{
						CreateHat(client, 30743, 15); // Patriot Peaks
					}
					case 59:
					{
						CreateHat(client, 30814, 15); // Lil' Bitey
					}
					case 60:
					{
						CreateHat(client, 30882, 15); // Jungle Wreath
					}
					case 61:
					{
						CreateHat(client, 30833, 15); // Woolen Warmer
					}
					case 62:
					{
						CreateHat(client, 30576, 6); // Co-Pilot
					}
					case 63:
					{
						CreateHat(client, 30829, 15); // Snowmann
					}
					case 64:
					{
						CreateHat(client, 30868, 15); // Legendary Lid
					}
					case 65:
					{
						CreateHat(client, 30549, 6); // Winter Woodsman
					}
					case 66:
					{
						CreateHat(client, 30546, 6); // Boxcar Bomber
					}
					case 67:
					{
						CreateHat(client, 30542, 6); // Coldsnap Cap
					}
					case 68:
					{
						CreateHat(client, 30623, 15); // The Rotation Sensation
					}
					case 69:
					{
						CreateHat(client, 30643, 15); // Potassium Bonnett
						face = true;
					}
					case 70:
					{
						CreateHat(client, 30640, 15); // Captain Cardbeard Cutthroat
						face = true;
					}
					case 71:
					{
						CreateHat(client, 30810, 15); // Nasty Norsemann
					}
					case 72:
					{
						CreateHat(client, 30838, 15); // Head Prize
					}
					case 73:
					{
						CreateHat(client, 30796, 15); // Toadstool Topper
					}
					case 74:
					{
						CreateHat(client, 30808, 15); // Class Crown
					}
					case 75:
					{
						CreateHat(client, 30759, 6); // Prinny Hat
					}
					case 76:
					{
						CreateHat(client, 30976, 15); // Tundra Top
					}
					case 77:
					{
						CreateHat(client, 537, 6); // Birthday Hat
					}
					case 78:
					{
						CreateHat(client, 30998, 15); // Lucky Cat Hat
					}
					case 79:
					{
						CreateHat(client, 30877, 15); // Hunter in Darkness
					}
					case 80:
					{
						CreateHat(client, 30879, 15); // Aztec Warrior
						face = true;
					}
					case 81:
					{
						CreateHat(client, 30682, 15); // Smokey Sombrero
					}
					case 82:
					{
						CreateHat(client, 189, 6); // Alien Swarm Parasite
					}
					case 83:
					{
						CreateHat(client, 162, 6); // Max's Severed Head
					}
					case 84:
					{
						CreateHat(client, 302, 6); // Frontline Field Recorder
					}
					case 85:
					{
						CreateHat(client, 473, 6); // Spiral Sallet
						face = true;
					}
					case 86:
					{
						CreateHat(client, 420, 1); // Aperture Labs Hard Hat
					}
					case 87:
					{
						CreateHat(client, 470, 6); // Lo-Fi Longwave
					}
					case 88:
					{
						CreateHat(client, 598, 6); // Manniversary Paper Hat
					}
					case 89:
					{
						CreateHat(client, 492, 6); // Summer Hat
					}
					case 90:
					{
						CreateHat(client, 666, 6); // The B.M.O.C.
					}
					case 91:
					{
						CreateHat(client, 30018, 6); // The Bot Dogger
					}
					case 92:
					{
						CreateHat(client, 30003, 6); // The Galvanized Gibus
					}
					case 93:
					{
						CreateHat(client, 30001, 6); // Modest Metal Pile of Scrap
					}
					case 94:
					{
						CreateHat(client, 30006, 6); // Noble Nickel Amassment of Hats
					}
					case 95:
					{
						CreateHat(client, 30008, 6); // Towering Titanium Pillar of Hats
					}
					case 96:
					{
						CreateHat(client, 30058, 6); // The Crosslinker's Coil
					}
					case 97:
					{
						CreateHat(client, 30646, 15); // Captain Space Mann
					}
					case 98:
					{
						CreateHat(client, 30647, 15); // Phononaut
					}
					case 99:
					{
						CreateHat(client, 30768, 15); // Bedouin Bandana
						face = true;
					}
					case 100:
					{
						CreateHat(client, 30928, 15); // Balloonihoodie
					}
					case 101:
					{
						CreateHat(client, 30974, 15); // Caribou Companion
					}
					case 102:
					{
						CreateHat(client, 30733, 6); // Teufort Knight
						face = true;
					}
					case 103:
					{
						CreateHat(client, 30658, 15); // Universal Translator
					}
					case 104:
					{
						CreateHat(client, 332, 6); // Bounty Hat
					}
					case 105:
					{
						CreateHat(client, 30915, 15); // Pithy Professional
					}
					case 106:
					{
						CreateHat(client, 853, 6); // The Crafty Hair
					}
					case 107:
					{
						CreateHat(client, 1012, 6); // The Wilson Weave
					}
					case 108:
					{
						CreateHat(client, 631, 6); // The Hat With No Name
					}
					case 109:
					{
						CreateHat(client, 30681, 15); // El Patron
					}
					case 110:
					{
						CreateHat(client, 48, 6); // Mining Light
					}
					case 111:
					{
						CreateHat(client, 94, 6); // Texas Ten Gallon
					}
					case 112:
					{
						CreateHat(client, 95, 6); // Engineer's Cap
					}
					case 113:
					{
						CreateHat(client, 118, 6); // Texas Slim's Dome Shine
					}
					case 114:
					{
						CreateHat(client, 148, 6); // Hotrod
					}
					case 115:
					{
						CreateHat(client, 178, 6); // Safe'n'Sound
					}
					case 116:
					{
						CreateHat(client, 322, 6); // Buckaroo's Hat
					}
					case 117:
					{
						CreateHat(client, 338, 6); // Industrial Festivizer
					}
					case 118:
					{
						CreateHat(client, 379, 6); // Western Wear
					}
					case 119:
					{
						CreateHat(client, 382, 6); // Big Country
					}
					case 120:
					{
						CreateHat(client, 384, 6); // Professor's Peculiarity
						face = true;
					}
					case 121:
					{
						CreateHat(client, 399, 6); // Ol' Geezer
					}
					case 122:
					{
						CreateHat(client, 436, 6); // Hetman's Headpiece
					}
					case 123:
					{
						CreateHat(client, 30930, 15); // Trucker's Topper
					}
					case 124:
					{
						CreateHat(client, 30707, 15); // Dead'er Alive
					}
					case 125:
					{
						CreateHat(client, 628, 6); // The Virtual Reality Headset
						face = true;
					}
					case 126:
					{
						CreateHat(client, 848, 6); // The Tin-1000
						face = true;
					}
					case 127:
					{
						CreateHat(client, 988, 6); // The Barnstormer
						face = true;
					}
					case 128:
					{
						CreateHat(client, 988, 6); // The Last Straw
					}
					case 129:
					{
						CreateHat(client, 1017, 6); // Vox Diabolus
						face = true;
					}
					case 130:
					{
						CreateHat(client, 30031, 6); // The Plug-in Prospector
					}
					case 131:
					{
						CreateHat(client, 30035, 6); // The Timeless Topper
					}
					case 132:
					{
						CreateHat(client, 30035, 6); // Texas Tin-Gallon
					}
					case 133:
					{
						CreateHat(client, 30051, 6); // The Data Mining Light
					}
					case 134:
					{
						CreateHat(client, 30099, 6); // The Pardner's Pompadour
						face = true;
					}
					case 135:
					{
						CreateHat(client, 30336, 6); // The Trencher's Topper
					}
					case 136:
					{
						CreateHat(client, 1177, 1); // Audio File
					}
					case 137:
					{
						CreateHat(client, 30420, 6); // The Danger
						face = true;
					}
					case 138:
					{
						CreateHat(client, 30592, 6); // Conagher's Combover
						face = true;
					}
					case 139:
					{
						CreateHat(client, 30634, 15); // Sheriff's Stetson
						face = true;
					}
					case 140:
					{
						CreateHat(client, 30806, 15); // Corpus Christi Cranium
						face = true;
					}
					case 141:
					{
						CreateHat(client, 30805, 15); // Wide-Brimmed Bandito
					}
					case 142:
					{
						CreateHat(client, 31011, 15); // Defragmenting Hard Hat 17%
					}
					case 143:
					{
						CreateHat(client, 30995, 6); // Dell in the Shell
					}
					case 144:
					{
						CreateHat(client, 30846, 15); // Plumber's Cap
						face = true;
					}
					case 145:
					{
						CreateHat(client, 30871, 15); // Flash of Inspiration
					}
					case 146:
					{
						CreateHat(client, 30977, 15); // Antarctic Eyewear
					}
					case 147:
					{
						CreateHat(client, 31020, 15); // Bread Heads
						face = true;
					}
					case 148:
					{
						CreateHat(client, 30740, 6); // Arkham Cowl
						face = true;
					}
					case 149:
					{
						CreateHat(client, 332, 6); // Treasure Hat
					}
					case 150:
					{
						CreateHat(client, 675, 6); // The Ebenezer
					}
					case 151:
					{
						CreateHat(client, 30469, 1); // Horace
					}
				}
			}
		}
	}

	if ( !face )
	{
		TFClassType class = TF2_GetPlayerClass(client);

		switch (class)
		{
			case TFClass_Scout:
			{
				int rnd2 = GetRandomUInt(0,46);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 451, 6); // Bonk Boy
					}
					case 27:
					{
						CreateHat(client, 451, 11); // Bonk Boy
					}
					case 28:
					{
						CreateHat(client, 468, 1); // Planeswalker Goggles
					}
					case 29:
					{
						CreateHat(client, 468, 6); // Planeswalker Goggles
					}
					case 30:
					{
						CreateHat(client, 630, 6); // The Stereoscopic Shades
					}
					case 31:
					{
						CreateHat(client, 630, 11); // The Stereoscopic Shades
					}
					case 32:
					{
						CreateHat(client, 30027, 6); // Bolt Boy
					}
					case 33:
					{
						CreateHat(client, 30027, 11); // Bolt Boy
					}
					case 34:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 36:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 37:
					{
						CreateHat(client, 30661, 11); // Cadet Visor
					}
					case 38:
					{
						CreateHat(client, 30661, 15); // Cadet Visor
					}
					case 39:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 40:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 41:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 42:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 43:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 44:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 45:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 46:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
				}
			}
			case TFClass_Sniper:
			{
				int rnd2 = GetRandomUInt(0,52);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 27:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 393, 6); // Villain's Veil
					}
					case 29:
					{
						CreateHat(client, 393, 11); // Villain's Veil
					}
					case 30:
					{
						CreateHat(client, 766, 6); // The Doublecross-Comm
					}
					case 31:
					{
						CreateHat(client, 986, 6); // The Mutton Mann
					}
					case 32:
					{
						CreateHat(client, 986, 11); // The Mutton Mann
					}
					case 33:
					{
						CreateHat(client, 30317, 6); // The Five-Month Shadow
					}
					case 34:
					{
						CreateHat(client, 30317, 11); // The Five-Month Shadow
					}
					case 35:
					{
						CreateHat(client, 30423, 6); // The Scoper's Smoke
					}
					case 36:
					{
						CreateHat(client, 30423, 11); // The Scoper's Smoke
					}
					case 37:
					{
						CreateHat(client, 30597, 6); // Bushman's Bristles
					}
					case 38:
					{
						CreateHat(client, 30597, 11); // Bushman's Bristles
					}
					case 39:
					{
						CreateHat(client, 647, 6); // The All-Father
					}
					case 40:
					{
						CreateHat(client, 647, 11); // The All-Father
					}
					case 41:
					{
						CreateHat(client, 783, 6); // The HazMat Headcase
					}
					case 42:
					{
						CreateHat(client, 783, 11); // The HazMat Headcase
					}
					case 43:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 44:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 45:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 46:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 47:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 48:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 49:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 50:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 51:
					{
						CreateHat(client, 30894, 15); // Most Dangerous Mane
					}
					case 52:
					{
						CreateHat(client, 30858, 15); // Hawk-Eyed Hunter
					}
				}
			}
			case TFClass_Soldier:
			{
				int rnd2 = GetRandomUInt(0,60);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); // The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); // The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 440, 6); // Lord Cockswain's Novelty Mutton Chops and Pipe
					}
					case 32:
					{
						CreateHat(client, 440, 11); // Lord Cockswain's Novelty Mutton Chops and Pipe
					}
					case 33:
					{
						CreateHat(client, 647, 6); // The All-Father
					}
					case 34:
					{
						CreateHat(client, 647, 11); // The All-Father
					}
					case 35:
					{
						CreateHat(client, 852, 6); // The Soldier's Stogie
					}
					case 36:
					{
						CreateHat(client, 852, 11); // The Soldier's Stogie
					}
					case 37:
					{
						CreateHat(client, 875, 1); // The Menpo
					}
					case 38:
					{
						CreateHat(client, 875, 6); // The Menpo
					}
					case 39:
					{
						CreateHat(client, 30033, 6); //  Soldier's Sparkplug
					}
					case 40:
					{
						CreateHat(client, 30033, 11); //  Soldier's Sparkplug
					}
					case 41:
					{
						CreateHat(client, 30164, 6); //  The Viking Braider
					}
					case 42:
					{
						CreateHat(client, 30164, 11); //  The Viking Braider
					}
					case 43:
					{
						CreateHat(client, 30335, 6); //  Marshall's Mutton Chops
					}
					case 44:
					{
						CreateHat(client, 30335, 11); //  Marshall's Mutton Chops
					}
					case 45:
					{
						CreateHat(client, 30477, 6); //  The Lone Survivor
					}
					case 46:
					{
						CreateHat(client, 30477, 11); //  The Lone Survivor
					}
					case 47:
					{
						CreateHat(client, 30554, 6); //  Mistaken Movember
					}
					case 48:
					{
						CreateHat(client, 30554, 11); // Mistaken Movember
					}
					case 49:
					{
						CreateHat(client, 30165, 6); // The Cuban Bristle Crisis
					}
					case 50:
					{
						CreateHat(client, 30165, 11); // The Cuban Bristle Crisis
					}
					case 51:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 52:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 53:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 54:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 55:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 56:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 57:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 58:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 59:
					{
						CreateHat(client, 339, 6); // Exquisite Rack
					}
					case 60:
					{
						CreateHat(client, 360, 6); // Hero's Hachimaki
					}
				}
			}
			case TFClass_DemoMan:
			{
				int rnd2 = GetRandomUInt(0,56);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); // The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); // The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); // The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); // The All-Father
					}
					case 33:
					{
						CreateHat(client, 875, 1); // The Menpo
					}
					case 34:
					{
						CreateHat(client, 875, 6); // The Menpo
					}
					case 35:
					{
						CreateHat(client, 295, 6); // Dangeresque, Too?!
					}
					case 36:
					{
						CreateHat(client, 709, 6); // The Snapped Pupil
					}
					case 37:
					{
						CreateHat(client, 709, 11); // The Snapped Pupil
					}
					case 38:
					{
						CreateHat(client, 830, 6); // The Bearded Bombardier
					}
					case 39:
					{
						CreateHat(client, 830, 11); // The Bearded Bombardier
					}
					case 40:
					{
						CreateHat(client, 30010, 6); // The HDMI Patch
					}
					case 41:
					{
						CreateHat(client, 30010, 11); // The HDMI Patch
					}
					case 42:
					{
						CreateHat(client, 30011, 6); // Bolted Bombardier
					}
					case 43:
					{
						CreateHat(client, 30011, 11); // Bolted Bombardier
					}
					case 44:
					{
						CreateHat(client, 30430, 6); // Seeing Double
					}
					case 45:
					{
						CreateHat(client, 30430, 11); // Seeing Double
					}
					case 46:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 47:
					{
						CreateHat(client, 1019, 6); // Blind Justice
					}
					case 48:
					{
						CreateHat(client, 1019, 1); // Blind Justice
					}
					case 49:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 50:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 51:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 52:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 53:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 54:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 55:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 56:
					{
						CreateHat(client, 31017, 15); // Gaelic Glutton
					}
				}
			}
			case TFClass_Medic:
			{
				int rnd2 = GetRandomUInt(0,59);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); // The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); // The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); // The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); // The All-Father
					}
					case 33:
					{
						CreateHat(client, 144, 3); // Physician's Procedure Mask
					}
					case 34:
					{
						CreateHat(client, 144, 6); // Physician's Procedure Mask
					}
					case 35:
					{
						CreateHat(client, 315, 6); // Blighted Beak
					}
					case 36:
					{
						CreateHat(client, 30046, 6); // Practitioner's Processing Mask
					}
					case 37:
					{
						CreateHat(client, 30046, 11); // Practitioner's Processing Mask
					}
					case 38:
					{
						CreateHat(client, 30052, 6); // The Byte'd Beak
					}
					case 39:
					{
						CreateHat(client, 30052, 11); // The Byte'd Beak
					}
					case 40:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 41:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 42:
					{
						CreateHat(client, 30186, 6); // A Brush with Death
					}
					case 43:
					{
						CreateHat(client, 30186, 11); // A Brush with Death
					}
					case 44:
					{
						CreateHat(client, 30323, 6); // The Ruffled Ruprecht
					}
					case 45:
					{
						CreateHat(client, 30323, 11); // The Ruffled Ruprecht
					}
					case 46:
					{
						CreateHat(client, 30349, 6); // The Fashionable Megalomaniac
					}
					case 47:
					{
						CreateHat(client, 30349, 11); // The Fashionable Megalomaniac
					}
					case 48:
					{
						CreateHat(client, 30410, 6); // Ze Ubermensch
					}
					case 49:
					{
						CreateHat(client, 30410, 11); // Ze Ubermensch
					}
					case 50:
					{
						CreateHat(client, 30595, 6); // Unknown Mann
					}
					case 51:
					{
						CreateHat(client, 30595, 11); // Unknown Mann
					}
					case 52:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 53:
					{
						CreateHat(client, 657, 6); // The Nine-Pipe Problem
					}
					case 54:
					{
						CreateHat(client, 657, 11); // The Nine-Pipe Problem
					}
					case 55:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 56:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 57:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 58:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 59:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
				}
			}
			case TFClass_Heavy:
			{
				int rnd2 = GetRandomUInt(0,59);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); // The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); // The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); // The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); // The All-Father
					}
					case 33:
					{
						CreateHat(client, 30164, 6); // The Viking Braider
					}
					case 34:
					{
						CreateHat(client, 30164, 11); // The Viking Braider
					}
					case 35:
					{
						CreateHat(client, 479, 6); // Security Shades
					}
					case 36:
					{
						CreateHat(client, 485, 6); // Big Steel Jaw of Summer Fun
					}
					case 37:
					{
						CreateHat(client, 30141, 6); // The Gabe Glasses
					}
					case 38:
					{
						CreateHat(client, 30141, 11); // The Gabe Glasses
					}
					case 39:
					{
						CreateHat(client, 30165, 6); // The Cuban Bristle Crisis
					}
					case 40:
					{
						CreateHat(client, 30165, 11); // The Cuban Bristle Crisis
					}
					case 41:
					{
						CreateHat(client, 30345, 6); // The Leftover Trap
					}
					case 42:
					{
						CreateHat(client, 30345, 11); // The Leftover Trap
					}
					case 43:
					{
						CreateHat(client, 30368, 6); // The War Goggles
					}
					case 44:
					{
						CreateHat(client, 30368, 11); // The War Goggles
					}
					case 45:
					{
						CreateHat(client, 30401, 6); // Yuri's Revenge
					}
					case 46:
					{
						CreateHat(client, 30401, 11); // Yuri's Revenge
					}
					case 47:
					{
						CreateHat(client, 30482, 6); // Yuri's Revenge
					}
					case 48:
					{
						CreateHat(client, 30482, 11); // Yuri's Revenge
					}
					case 49:
					{
						CreateHat(client, 30645, 15); // El Duderino
					}
					case 50:
					{
						CreateHat(client, 30645, 11); // El Duderino
					}
					case 51:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 52:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 53:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 54:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 55:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 56:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 57:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 58:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 59:
					{
						CreateHat(client, 30815, 15); // Mad Mask
					}
				}
			}
			case TFClass_Pyro:
			{
				int rnd2 = GetRandomUInt(0,87);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 175, 3); // Whiskered Gentleman
					}
					case 28:
					{
						CreateHat(client, 175, 6); // Whiskered Gentleman
					}
					case 29:
					{
						CreateHat(client, 30664, 3); //  Space Diver
					}
					case 30:
					{
						CreateHat(client, 335, 6); //  Foster's Facade
					}
					case 31:
					{
						CreateHat(client, 335, 11); // Foster's Facade
					}
					case 32:
					{
						CreateHat(client, 570, 6); // The Last Breath
					}
					case 33:
					{
						CreateHat(client, 570, 11); // The Last Breath
					}
					case 34:
					{
						CreateHat(client, 571, 6); // Apparition's Aspect
					}
					case 35:
					{
						CreateHat(client, 571, 11); // Apparition's Aspect
					}
					case 36:
					{
						CreateHat(client, 783, 6); // The HazMat Headcase
					}
					case 37:
					{
						CreateHat(client, 783, 11); // The HazMat Headcase
					}
					case 38:
					{
						CreateHat(client, 950, 6); // Nose Candy
					}
					case 41:
					{
						CreateHat(client, 976, 6); // Winter Wonderland Wrap
					}
					case 42:
					{
						CreateHat(client, 976, 11); // Winter Wonderland Wrap
					}
					case 43:
					{
						CreateHat(client, 1020, 6); // The Person in the Iron Mask
					}
					case 44:
					{
						CreateHat(client, 1038, 6); // The Breather Bag
					}
					case 45:
					{
						CreateHat(client, 30032, 6); // The Rusty Reaper
					}
					case 46:
					{
						CreateHat(client, 30032, 11); // The Rusty Reaper
					}
					case 47:
					{
						CreateHat(client, 30036, 6); // The Filamental
					}
					case 48:
					{
						CreateHat(client, 30036, 11); // The Filamental
					}
					case 49:
					{
						CreateHat(client, 30053, 6); // The Googol Glass Eyes
					}
					case 50:
					{
						CreateHat(client, 30053, 11); // The Googol Glass Eyes
					}
					case 51:
					{
						CreateHat(client, 30075, 6); // The Mair Mask
					}
					case 52:
					{
						CreateHat(client, 30075, 11); // The Mair Mask
					}
					case 53:
					{
						CreateHat(client, 30163, 6); // The Air Raider
					}
					case 54:
					{
						CreateHat(client, 30163, 11); // The Air Raider
					}
					case 55:
					{
						CreateHat(client, 30176, 6); // Pop-eyes
					}
					case 56:
					{
						CreateHat(client, 30176, 11); // Pop-eyes
					}
					case 57:
					{
						CreateHat(client, 30304, 6); // The Blizzard Breather
					}
					case 58:
					{
						CreateHat(client, 30304, 11); // The Blizzard Breather
					}
					case 59:
					{
						CreateHat(client, 30367, 6); // The Blizzard Breather
					}
					case 60:
					{
						CreateHat(client, 30367, 11); // The Blizzard Breather
					}
					case 61:
					{
						CreateHat(client, 30475, 6); // The Mishap Mercenary
					}
					case 62:
					{
						CreateHat(client, 30475, 11); // The Mishap Mercenary
					}
					case 63:
					{
						CreateHat(client, 30538, 6); // Wartime Warmth
					}
					case 64:
					{
						CreateHat(client, 30538, 11); // Wartime Warmth
					}
					case 65:
					{
						CreateHat(client, 30582, 6); // Black Knight's Bascinet
					}
					case 66:
					{
						CreateHat(client, 30582, 11); // Black Knight's Bascinet
					}
					case 67:
					{
						CreateHat(client, 30652, 15); // Phobos Filter
					}
					case 68:
					{
						CreateHat(client, 30652, 11); // Phobos Filter
					}
					case 69:
					{
						CreateHat(client, 30168, 6); // The Special Eyes
					}
					case 70:
					{
						CreateHat(client, 30168, 11); // The Special Eyes
					}
					case 71:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 72:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 73:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 74:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 75:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 76:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 77:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 78:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 79:
					{
						CreateHat(client, 30717, 15); // Arthropod's Aspect
					}
					case 80:
					{
						CreateHat(client, 30676, 15); // Face of Mercy
					}
					case 81:
					{
						CreateHat(client, 30835, 15); // Pyro the Flamedeer
					}
					case 82:
					{
						CreateHat(client, 30901, 15); // D-eye-monds
					}
					case 83:
					{
						CreateHat(client, 31007, 15); // Arachno-Arsonist
					}
					case 84:
					{
						CreateHat(client, 31004, 15); // Pyro in Chinatown
					}
					case 85:
					{
						CreateHat(client, 30859, 15); // Airtight Arsonist
					}
					case 86:
					{
						CreateHat(client, 30298, 6); // Raven's Visage
					}
					case 87:
					{
						CreateHat(client, 30741, 6); // Firefly
					}
				}
			}
			case TFClass_Spy:
			{
				int rnd2 = GetRandomUInt(0,51);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 103, 1); // Camera Beard
					}
					case 30:
					{
						CreateHat(client, 103, 3); // Camera Beard
					}
					case 31:
					{
						CreateHat(client, 103, 6); // Camera Beard
					}
					case 32:
					{
						CreateHat(client, 103, 11); // Camera Beard
					}
					case 33:
					{
						CreateHat(client, 337, 6); // Le Party Phantom
					}
					case 34:
					{
						CreateHat(client, 629, 6); // The Spectre's Spectacles
					}
					case 35:
					{
						CreateHat(client, 629, 11); // The Spectre's Spectacles
					}
					case 36:
					{
						CreateHat(client, 919, 6); // The Scarecrow
					}
					case 37:
					{
						CreateHat(client, 919, 11); // The Scarecrow
					}
					case 38:
					{
						CreateHat(client, 919, 13); // The Scarecrow
					}
					case 39:
					{
						CreateHat(client, 1030, 6); // The Dapper Disguise
					}
					case 40:
					{
						CreateHat(client, 30009, 6); // The Megapixel Beard
					}
					case 41:
					{
						CreateHat(client, 30009, 11); // The Megapixel Beard
					}
					case 42:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 43:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 44:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 45:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 46:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 47:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 48:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 49:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 50:
					{
						CreateHat(client, 30775, 15); // Dead Head
					}
					case 51:
					{
						CreateHat(client, 30848, 15); // Upgrade
					}
				}
			}
			case TFClass_Engineer:
			{
				int rnd2 = GetRandomUInt(0,61);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); // The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); // Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); // The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); // The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); // Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); // The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); // The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); // The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); // The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); // The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); // The Tomb Readers
					}
					case 12:
					{
						CreateHat(client, 744, 3); // Pyrovision Goggles
					}
					case 13:
					{
						CreateHat(client, 522, 1); // The Deus Specs
					}
					case 14:
					{
						CreateHat(client, 816, 1); // The Marxman
					}
					case 15:
					{
						CreateHat(client, 816, 11); // The Marxman
					}
					case 16:
					{
						CreateHat(client, 30104, 11); // Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); // The Dictator
					}
					case 18:
					{
						CreateHat(client, 30352, 11); // The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); // The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); // The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); // Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); // Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); // Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); // Summer Shades
					}
					case 26:
					{
						CreateHat(client, 343,11); //  Strange Professor Speks
					}
					case 27:
					{
						CreateHat(client, 30085, 6); // The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); // The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); // The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); // The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); // The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); // The All-Father
					}
					case 33:
					{
						CreateHat(client, 30164, 6); // The Viking Braider
					}
					case 34:
					{
						CreateHat(client, 30164, 11); // The Viking Braider
					}
					case 35:
					{
						CreateHat(client, 30165, 6); // The Cuban Bristle Crisis
					}
					case 36:
					{
						CreateHat(client, 30165, 11); // The Cuban Bristle Crisis
					}
					case 37:
					{
						CreateHat(client, 30367, 6); // The Blizzard Breather
					}
					case 38:
					{
						CreateHat(client, 30367, 11); // The Blizzard Breather
					}
					case 39:
					{
						CreateHat(client, 389, 6); // Googly Gazer
					}
					case 40:
					{
						CreateHat(client, 591, 6); // The Brainiac Goggles
					}
					case 41:
					{
						CreateHat(client, 1009, 6); // The Grizzled Growth
					}
					case 42:
					{
						CreateHat(client, 1009, 1); // The Grizzled Growth
					}
					case 43:
					{
						CreateHat(client, 30168, 6); // The Special Eyes
					}
					case 44:
					{
						CreateHat(client, 30168, 11); // The Special Eyes
					}
					case 45:
					{
						CreateHat(client, 30172, 6); // The Gold Digger
					}
					case 46:
					{
						CreateHat(client, 30172, 11); // The Gold Digger
					}
					case 47:
					{
						CreateHat(client, 30322, 6); // Face Full of Festive
					}
					case 48:
					{
						CreateHat(client, 30322, 11); // Face Full of Festive
					}
					case 49:
					{
						CreateHat(client, 30347, 6); // The Scotch Saver
					}
					case 50:
					{
						CreateHat(client, 30347, 11); // The Scotch Saver
					}
					case 51:
					{
						CreateHat(client, 30407, 6); // The Level Three Chin
					}
					case 52:
					{
						CreateHat(client, 30407, 11); // The Level Three Chin
					}
					case 53:
					{
						CreateHat(client, 30414, 11); // The Eye-Catcher
					}
					case 54:
					{
						CreateHat(client, 993, 6); // Antlers
					}
					case 55:
					{
						CreateHat(client, 30571, 6); // Brimstone
					}
					case 56:
					{
						CreateHat(client, 30997, 15); // Deadbeats
					}
					case 57:
					{
						CreateHat(client, 30831, 15); // Reader's Choice
					}
					case 58:
					{
						CreateHat(client, 30801, 15); // Spooktacles
					}
					case 59:
					{
						CreateHat(client, 1122, 6); // Towering Pillar of Summer Shades
					}
					case 60:
					{
						CreateHat(client, 1033, 1); // The TF2VRH
					}
					case 61:
					{
						CreateHat(client, 30872, 15); // Head Mounted Double Observatory
					}
				}
			}
		}
	}

	TFClassType class = TF2_GetPlayerClass(client);

	switch (class)
	{
		case TFClass_Scout:
		{
			int rnd3 = GetRandomUInt(0,229);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 347, 6); // The Essential Accessories
				}
				case 91:
				{
					CreateHat(client, 454, 6); // Sign of the Wolf's School
				}
				case 92:
				{
					CreateHat(client, 454, 1); // Sign of the Wolf's School
				}
				case 93:
				{
					CreateHat(client, 490, 6); // Flip-Flops
				}
				case 94:
				{
					CreateHat(client, 827, 6); // Track Terrorizer
				}
				case 95:
				{
					CreateHat(client, 540, 6); // Ball-Kicking Boots
				}
				case 96:
				{
					CreateHat(client, 540, 1); // Ball-Kicking Boots
				}
				case 97:
				{
					CreateHat(client, 653, 6); // The Bootie Time
				}
				case 98:
				{
					CreateHat(client, 653, 11); // The Bootie Time
				}
				case 99:
				{
					CreateHat(client, 707, 6); // The Boston Boom-Bringer
				}
				case 100:
				{
					CreateHat(client, 707, 11); // The Boston Boom-Bringer
				}
				case 101:
				{
					CreateHat(client, 722, 6); // The Fast Learner
				}
				case 102:
				{
					CreateHat(client, 722, 11); // The Fast Learner
				}
				case 103:
				{
					CreateHat(client, 734, 6); // The Teufort Tooth Kicker
				}
				case 104:
				{
					CreateHat(client, 734, 11); // The Teufort Tooth Kicker
				}
				case 105:
				{
					CreateHat(client, 781, 6); // Dillinger's Duffel
				}
				case 106:
				{
					CreateHat(client, 781, 11); // Dillinger's Duffel
				}
				case 107:
				{
					CreateHat(client, 814, 1); // The Triad Trinket
				}
				case 108:
				{
					CreateHat(client, 814, 6); // The Triad Trinket
				}
				case 109:
				{
					CreateHat(client, 814, 11); // The Triad Trinket
				}
				case 110:
				{
					CreateHat(client, 815, 1); // The Champ Stamp
				}
				case 111:
				{
					CreateHat(client, 815, 6); // The Champ Stamp
				}
				case 112:
				{
					CreateHat(client, 815, 11); // The Champ Stamp
				}
				case 113:
				{
					CreateHat(client, 924, 6); // The Spooky Shoes
				}
				case 114:
				{
					CreateHat(client, 924, 11); // The Spooky Shoes
				}
				case 115:
				{
					CreateHat(client, 924, 13); // The Spooky Shoes
				}
				case 116:
				{
					CreateHat(client, 925, 6); // The Spooky Sleeves
				}
				case 117:
				{
					CreateHat(client, 925, 11); // The Spooky Sleeves
				}
				case 118:
				{
					CreateHat(client, 925, 13); // The Spooky Sleeves
				}
				case 119:
				{
					CreateHat(client, 983, 6); // The Digit Divulger
				}
				case 120:
				{
					CreateHat(client, 983, 11); // The Digit Divulger
				}
				case 121:
				{
					CreateHat(client, 1016, 11); // Buck Turner All-Stars
				}
				case 122:
				{
					CreateHat(client, 1026, 1); // The Tomb Wrapper
				}
				case 123:
				{
					CreateHat(client, 1026, 6); // The Tomb Wrapper
				}
				case 125:
				{
					CreateHat(client, 1032, 6); // The Long Fall Loafers
				}
				case 126:
				{
					CreateHat(client, 1075, 6); // The Sack Fulla Smissmas
				}
				case 127:
				{
					CreateHat(client, 30060, 6); // The Cheet Sheet
				}
				case 128:
				{
					CreateHat(client, 30060, 1); // The Cheet Sheet
				}
				case 129:
				{
					CreateHat(client, 30076, 6); // The Bigg Mann on Campus
				}
				case 130:
				{
					CreateHat(client, 30076, 11); // The Bigg Mann on Campus
				}
				case 131:
				{
					CreateHat(client, 30077, 6); // The Cool Cat Cardigan
				}
				case 132:
				{
					CreateHat(client, 30077, 11); // The Cool Cat Cardigan
				}
				case 133:
				{
					CreateHat(client, 30083, 11); // The Caffeine Cooler
				}
				case 134:
				{
					CreateHat(client, 30084, 6); // The Half-Pipe Hurdler
				}
				case 135:
				{
					CreateHat(client, 30084, 11); // The Half-Pipe Hurdler
				}
				case 136:
				{
					CreateHat(client, 30134, 6); // The Delinquent's Down Vest
				}
				case 137:
				{
					CreateHat(client, 30134, 11); // The Delinquent's Down Vest
				}
				case 138:
				{
					CreateHat(client, 30185, 6); // The Flapjack
				}
				case 139:
				{
					CreateHat(client, 30185, 11); // The Flapjack
				}
				case 140:
				{
					CreateHat(client, 30320, 6); // Chucklenuts
				}
				case 141:
				{
					CreateHat(client, 30320, 11); // Chucklenuts
				}
				case 142:
				{
					CreateHat(client, 30325, 6); // The Little Drummer Mann
				}
				case 143:
				{
					CreateHat(client, 30325, 11); // The Little Drummer Mann
				}
				case 144:
				{
					CreateHat(client, 30376, 6); // The Ticket Boy
				}
				case 145:
				{
					CreateHat(client, 30376, 11); // The Ticket Boy
				}
				case 146:
				{
					CreateHat(client, 30395, 6); // The Southie Shinobi
				}
				case 147:
				{
					CreateHat(client, 30395, 11); // The Southie Shinobi
				}
				case 148:
				{
					CreateHat(client, 30396, 6); // The Red Socks
				}
				case 149:
				{
					CreateHat(client, 30396, 11); // The Red Socks
				}
				case 150:
				{
					CreateHat(client, 30426, 6); // The Paisley Pro
				}
				case 151:
				{
					CreateHat(client, 30426, 11); // The Paisley Pro
				}
				case 152:
				{
					CreateHat(client, 30427, 6); // The Argyle Ace
				}
				case 153:
				{
					CreateHat(client, 30427, 11); // The Argyle Ace
				}
				case 154:
				{
					CreateHat(client, 30540, 6); // Brooklyn Booties
				}
				case 155:
				{
					CreateHat(client, 30540, 11); // Brooklyn Booties
				}
				case 156:
				{
					CreateHat(client, 30552, 6); // Thermal Tracker
				}
				case 157:
				{
					CreateHat(client, 30552, 11); // Thermal Tracker
				}
				case 158:
				{
					CreateHat(client, 30561, 6); // The Bootenkhamuns
				}
				case 159:
				{
					CreateHat(client, 30564, 6); // Orion's Belt
				}
				case 160:
				{
					CreateHat(client, 30574, 6); // Courtier's Collar
				}
				case 161:
				{
					CreateHat(client, 30574, 11); // Courtier's Collar
				}
				case 162:
				{
					CreateHat(client, 30575, 6); // Harlequin's Hooves
				}
				case 163:
				{
					CreateHat(client, 30575, 11); // Harlequin's Hooves
				}
				case 164:
				{
					CreateHat(client, 30637, 15); // Flak Jack
				}
				case 165:
				{
					CreateHat(client, 30637, 11); // Flak Jack
				}
				case 166:
				{
					CreateHat(client, 30178, 6); // Weight Room Warmer
				}
				case 167:
				{
					CreateHat(client, 30178, 11); // Weight Room Warmer
				}
				case 168:
				{
					CreateHat(client, 30167, 6); // The Beep Boy
				}
				case 169:
				{
					CreateHat(client, 30167, 11); // The Beep Boy
				}
				case 170:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 171:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 172:
				{
					CreateHat(client, 30719, 15); // B'aaarrgh-n-Britches
				}
				case 173:
				{
					CreateHat(client, 30685, 15); // Thrilling Tracksuit
				}
				case 174:
				{
					CreateHat(client, 30751, 15); // Bonk Batter's Backup
				}
				case 175:
				{
					CreateHat(client, 30751, 15); // Bonk Batter's Backup
				}
				case 176:
				{
					CreateHat(client, 30754, 15); // Hot Heels
				}
				case 177:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 178:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 179:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 180:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 181:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 182:
				{
					CreateHat(client, 30824, 15); // Electric Twanger
				}
				case 183:
				{
					CreateHat(client, 30820, 15); // Snowwing
				}
				case 184:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 185:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 186:
				{
					CreateHat(client, 30890, 15); // Forest Footwear
				}
				case 187:
				{
					CreateHat(client, 30888, 15); // Jungle Jersey
				}
				case 188:
				{
					CreateHat(client, 30889, 15); // Transparent Trousers
				}
				case 189:
				{
					CreateHat(client, 30884, 15); // Aloha Apparel
				}
				case 190:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 191:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 192:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 193:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 194:
				{
					CreateHat(client, 31001, 15); // Athenian Attire
				}
				case 195:
				{
					CreateHat(client, 30999, 15); // Olympic Leapers
				}
				case 196:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 197:
				{
					CreateHat(client, 30770, 15); // Courtly Cuirass
				}
				case 198:
				{
					CreateHat(client, 30771, 15); // Squire's Sabatons
				}
				case 199:
				{
					CreateHat(client, 30869, 15); // Messenger's Mail Bag
				}
				case 200:
				{
					CreateHat(client, 30849, 15); // Pocket Pauling
				}
				case 201:
				{
					CreateHat(client, 30875, 15); // Speedster's Spandex
				}
				case 202:
				{
					CreateHat(client, 30873, 15); // Airborne Attire
				}
				case 203:
				{
					CreateHat(client, 30991, 15); // Blizzard Britches
				}
				case 204:
				{
					CreateHat(client, 30990, 15); // Wipe Out Wraps
				}
				case 205:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 206:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 207:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 208:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 209:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 210:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 211:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 212:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 213:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 214:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 215:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 216:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 217:
				{
					CreateHat(client, 859, 6); // Flight of the Monarch
				}
				case 218:
				{
					CreateHat(client, 858, 6); // Hanger-On Hood
				}
				case 219:
				{
					CreateHat(client, 30736, 6); // Bat Backup
				}
				case 220:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 221:
				{
					CreateHat(client, 30737, 6); // Crook Combatant
				}
				case 223:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 224:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 225:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 226:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
				case 227:
				{
					CreateHat(client, 31021, 15); // Catcher's Companion
				}
				case 228:
				{
					CreateHat(client, 31022, 6); // Juvenile's Jumper
				}
				case 229:
				{
					CreateHat(client, 491, 6); // Lucky No. 42
				}
			}
		}
		case TFClass_Sniper:
		{
			int rnd3 = GetRandomUInt(0,196);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 814, 1); // The Triad Trinket
				}
				case 91:
				{
					CreateHat(client, 814, 6); // The Triad Trinket
				}
				case 93:
				{
					CreateHat(client, 814, 11); // The Triad Trinket
				}
				case 94:
				{
					CreateHat(client, 815, 1); // The Champ Stamp
				}
				case 95:
				{
					CreateHat(client, 815, 6); // The Champ Stamp
				}
				case 96:
				{
					CreateHat(client, 815, 11); // The Champ Stamp
				}
				case 97:
				{
					CreateHat(client, 618, 6); // The Crocodile Smile
				}
				case 98:
				{
					CreateHat(client, 618, 11); // The Crocodile Smile
				}
				case 99:
				{
					CreateHat(client, 645, 6); // The Outback Intellectual
				}
				case 100:
				{
					CreateHat(client, 645, 11); // The Outback Intellectual
				}
				case 101:
				{
					CreateHat(client, 646, 6); // The Itsy Bitsy Spyer
				}
				case 102:
				{
					CreateHat(client, 646, 11); // The Itsy Bitsy Spyer
				}
				case 103:
				{
					CreateHat(client, 734, 6); // The Teufort Tooth Kicker
				}
				case 104:
				{
					CreateHat(client, 734, 11); // The Teufort Tooth Kicker
				}
				case 105:
				{
					CreateHat(client, 734, 6); // Sir Hootsalot
				}
				case 106:
				{
					CreateHat(client, 734, 11); // Sir Hootsalot
				}
				case 107:
				{
					CreateHat(client, 734, 13); // Sir Hootsalot
				}
				case 108:
				{
					CreateHat(client, 948, 1); // The Deadliest Duckling
				}
				case 109:
				{
					CreateHat(client, 948, 6); // The Deadliest Duckling
				}
				case 110:
				{
					CreateHat(client, 1023, 1); // The Steel Songbird
				}
				case 111:
				{
					CreateHat(client, 1023, 6); // The Steel Songbird
				}
				case 112:
				{
					CreateHat(client, 1094, 1); // The Criminal Cloak
				}
				case 113:
				{
					CreateHat(client, 1094, 6); // The Criminal Cloak
				}
				case 114:
				{
					CreateHat(client, 30056, 6); // The Dual-Core Devil Doll
				}
				case 115:
				{
					CreateHat(client, 30056, 11); // The Dual-Core Devil Doll
				}
				case 116:
				{
					CreateHat(client, 30056, 6); // The Birdman of Australiacatraz
				}
				case 117:
				{
					CreateHat(client, 30056, 11); // The Birdman of Australiacatraz
				}
				case 118:
				{
					CreateHat(client, 30101, 6); // The Cobber Chameleon
				}
				case 119:
				{
					CreateHat(client, 30101, 11); // The Cobber Chameleon
				}
				case 120:
				{
					CreateHat(client, 30103, 6); // The Falconer
				}
				case 121:
				{
					CreateHat(client, 30103, 11); // The Falconer
				}
				case 122:
				{
					CreateHat(client, 30170, 6); // The Chronomancer
				}
				case 123:
				{
					CreateHat(client, 30170, 11); // The Chronomancer
				}
				case 124:
				{
					CreateHat(client, 30181, 6); // Li'l Snaggletooth
				}
				case 125:
				{
					CreateHat(client, 30181, 11); // Li'l Snaggletooth
				}
				case 126:
				{
					CreateHat(client, 30310, 6); // The Snow Scoper
				}
				case 127:
				{
					CreateHat(client, 30310, 11); // The Snow Scoper
				}
				case 128:
				{
					CreateHat(client, 30324, 6); // The Golden Garment
				}
				case 129:
				{
					CreateHat(client, 30324, 11); // The Golden Garment
				}
				case 130:
				{
					CreateHat(client, 30328, 6); // The Extra Layer
				}
				case 131:
				{
					CreateHat(client, 30328, 11); // The Extra Layer
				}
				case 132:
				{
					CreateHat(client, 30359, 6); // The Huntman's Essentials
				}
				case 133:
				{
					CreateHat(client, 30359, 11); // The Huntman's Essentials
				}
				case 134:
				{
					CreateHat(client, 30371, 6); // The Archers Groundings
				}
				case 135:
				{
					CreateHat(client, 30371, 11); // The Archers Groundings
				}
				case 136:
				{
					CreateHat(client, 30373, 6); // The Toowoomba Tunic
				}
				case 137:
				{
					CreateHat(client, 30373, 11); // The Toowoomba Tunic
				}
				case 138:
				{
					CreateHat(client, 30424, 6); // The Triggerman's Tacticals
				}
				case 139:
				{
					CreateHat(client, 30424, 11); // The Triggerman's Tacticals
				}
				case 140:
				{
					CreateHat(client, 30478, 6); // Poacher's Safari Jacket
				}
				case 141:
				{
					CreateHat(client, 30478, 11); // Poacher's Safari Jacket
				}
				case 142:
				{
					CreateHat(client, 30481, 6); // Hillbilly Speed Bump
				}
				case 143:
				{
					CreateHat(client, 30481, 11); // Hillbilly Speed Bump
				}
				case 144:
				{
					CreateHat(client, 30599, 6); // Marksman's Mohair
				}
				case 145:
				{
					CreateHat(client, 30599, 11); // Marksman's Mohair
				}
				case 146:
				{
					CreateHat(client, 30600, 6); // Wally Pocket
				}
				case 147:
				{
					CreateHat(client, 30600, 11); // Wally Pocket
				}
				case 148:
				{
					CreateHat(client, 30629, 15); // Support Spurs
				}
				case 149:
				{
					CreateHat(client, 30629, 11); // Support Spurs
				}
				case 150:
				{
					CreateHat(client, 30649, 15); // Final Fontiersman
				}
				case 151:
				{
					CreateHat(client, 30649, 11); // Final Fontiersman
				}
				case 152:
				{
					CreateHat(client, 30650, 15); // Starduster
				}
				case 153:
				{
					CreateHat(client, 30650, 11); // Starduster
				}
				case 154:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 155:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 156:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 157:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 158:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 159:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 160:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 161:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 162:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 163:
				{
					CreateHat(client, 30916, 15); // Bait and Bite
				}
				case 164:
				{
					CreateHat(client, 30891, 15); // Cammy Jammies
				}
				case 165:
				{
					CreateHat(client, 30892, 15); // Conspicuous Camouflage
				}
				case 166:
				{
					CreateHat(client, 30895, 15); // Rifleman's Regalia
				}
				case 167:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 168:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 169:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 170:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 171:
				{
					CreateHat(client, 30789, 15); // Scoped Spartan
				}
				case 172:
				{
					CreateHat(client, 30856, 15); // Down Under Duster
				}
				case 173:
				{
					CreateHat(client, 30857, 15); // Guilden Guardian
				}
				case 174:
				{
					CreateHat(client, 30873, 15); // Airborne Attire
				}
				case 175:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 176:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 177:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 178:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 179:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 180:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 181:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 182:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 183:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 184:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 185:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 186:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 187:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 188:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 189:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 190:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 191:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 192:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 193:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 194:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 195:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 196:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
			}
		}
		case TFClass_Soldier:
		{
			int rnd3 = GetRandomUInt(0,190);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 734, 6); // The Teufort Tooth Kicker
				}
				case 91:
				{
					CreateHat(client, 734, 11); // The Teufort Tooth Kicker
				}
				case 92:
				{
					CreateHat(client, 121, 6); // Service Medal
				}
				case 93:
				{
					CreateHat(client, 392, 6); // Pocket Medic
				}
				case 94:
				{
					CreateHat(client, 446, 6); // Fancy Dress Uniform
				}
				case 95:
				{
					CreateHat(client, 446, 11); // Fancy Dress Uniform
				}
				case 96:
				{
					CreateHat(client, 641, 6); // The Ornament Armament
				}
				case 97:
				{
					CreateHat(client, 641, 11); // The Ornament Armament
				}
				case 98:
				{
					CreateHat(client, 650, 6); // The Kringle Collection
				}
				case 100:
				{
					CreateHat(client, 650, 11); // The Kringle Collection
				}
				case 101:
				{
					CreateHat(client, 731, 6); // The Captain's Cocktails
				}
				case 102:
				{
					CreateHat(client, 731, 11); // The Captain's Cocktails
				}
				case 103:
				{
					CreateHat(client, 768, 6); // The Professor's Pineapple
				}
				case 104:
				{
					CreateHat(client, 768, 11); // The Professor's Pineapple
				}
				case 105:
				{
					CreateHat(client, 922, 6); // The Bonedolier
				}
				case 106:
				{
					CreateHat(client, 922, 11); // The Bonedolier
				}
				case 107:
				{
					CreateHat(client, 922, 13); // The Bonedolier
				}
				case 108:
				{
					CreateHat(client, 948, 1); // The Deadliest Duckling
				}
				case 109:
				{
					CreateHat(client, 948, 6); // The Deadliest Duckling
				}
				case 110:
				{
					CreateHat(client, 1074, 6); // The War on Smissmas Battle Socks
				}
				case 111:
				{
					CreateHat(client, 30115, 6); // The Compatriot
				}
				case 112:
				{
					CreateHat(client, 30115, 11); // The Compatriot
				}
				case 113:
				{
					CreateHat(client, 30117, 6); // The Colonial Clogs
				}
				case 114:
				{
					CreateHat(client, 30117, 11); // The Colonial Clogs
				}
				case 115:
				{
					CreateHat(client, 30126, 6); // The Shotgun's Shoulder Guard
				}
				case 116:
				{
					CreateHat(client, 30126, 11); // The Shotgun's Shoulder Guard
				}
				case 117:
				{
					CreateHat(client, 30129, 6); // The Hornblower
				}
				case 118:
				{
					CreateHat(client, 30129, 11); // The Hornblower
				}
				case 119:
				{
					CreateHat(client, 30130, 6); // Lieutenant Bites
				}
				case 120:
				{
					CreateHat(client, 30130, 11); // Lieutenant Bites
				}
				case 121:
				{
					CreateHat(client, 30131, 6); // The Brawling Buccaneer
				}
				case 122:
				{
					CreateHat(client, 30131, 11); // The Brawling Buccaneer
				}
				case 123:
				{
					CreateHat(client, 30142, 6); // The Founding Father
				}
				case 124:
				{
					CreateHat(client, 30142, 11); // The Founding Father
				}
				case 125:
				{
					CreateHat(client, 30331, 6); // Anarctic Parka
				}
				case 126:
				{
					CreateHat(client, 30331, 11); // Anarctic Parka
				}
				case 127:
				{
					CreateHat(client, 30339, 6); // The Killer's Kit
				}
				case 128:
				{
					CreateHat(client, 30339, 11); // The Killer's Kit
				}
				case 129:
				{
					CreateHat(client, 30388, 6); // The Classified Coif
				}
				case 130:
				{
					CreateHat(client, 30388, 11); // The Classified Coif
				}
				case 131:
				{
					CreateHat(client, 30392, 6); // The Man in Slacks
				}
				case 132:
				{
					CreateHat(client, 30392, 11); // The Man in Slacks
				}
				case 133:
				{
					CreateHat(client, 30558, 6); // Coldfront Curbstompers
				}
				case 134:
				{
					CreateHat(client, 30558, 11); // Coldfront Curbstompers
				}
				case 136:
				{
					CreateHat(client, 30601, 6); // Cold Snap Coat
				}
				case 137:
				{
					CreateHat(client, 30601, 11); // Cold Snap Coat
				}
				case 138:
				{
					CreateHat(client, 936, 6); // The Exorcizor
				}
				case 139:
				{
					CreateHat(client, 936, 11); // The Exorcizor
				}
				case 140:
				{
					CreateHat(client, 936, 13); // The Exorcizor
				}
				case 141:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 142:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 143:
				{
					CreateHat(client, 30744, 15); // Diplomat
				}
				case 144:
				{
					CreateHat(client, 30747, 15); // Gift Bringer
				}
				case 145:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 146:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 147:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 148:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 149:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 150:
				{
					CreateHat(client, 30818, 15); // Socked and Loaded
				}
				case 151:
				{
					CreateHat(client, 30822, 15); // Handy Canes
				}
				case 152:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 153:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 154:
				{
					CreateHat(client, 30896, 15); // Attack Packs
				}
				case 155:
				{
					CreateHat(client, 30898, 15); // Sharp Chest Pain
				}
				case 156:
				{
					CreateHat(client, 30886, 15); // Bananades
				}
				case 157:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 158:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 159:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 160:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 161:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 162:
				{
					CreateHat(client, 30780, 15); // Patriot's Pouches
				}
				case 163:
				{
					CreateHat(client, 30853, 15); // Flakcatcher
				}
				case 164:
				{
					CreateHat(client, 30985, 15); // Private Maggot Muncher
				}
				case 165:
				{
					CreateHat(client, 30983, 15); // Veterans Attire
				}
				case 166:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 168:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 169:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 170:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 171:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 172:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 173:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 174:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 175:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 176:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 177:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 178:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 179:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 180:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 181:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 182:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 183:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 184:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 185:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 186:
				{
					CreateHat(client, 30727, 6); // Caped Crusader
				}
				case 187:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 188:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 189:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 190:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
			}
		}
		case TFClass_DemoMan:
		{
			int rnd3 = GetRandomUInt(0,194);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 1016, 11); // Buck Turner All-Stars
				}
				case 91:
				{
					CreateHat(client, 734, 6); // The Teufort Tooth Kicker
				}
				case 92:
				{
					CreateHat(client, 734, 11); // The Teufort Tooth Kicker
				}
				case 93:
				{
					CreateHat(client, 641, 6); // The Ornament Armament
				}
				case 94:
				{
					CreateHat(client, 641, 11); // The Ornament Armament
				}
				case 95:
				{
					CreateHat(client, 768, 6); // The Professor's Pineapple
				}
				case 96:
				{
					CreateHat(client, 768, 11); // The Professor's Pineapple
				}
				case 97:
				{
					CreateHat(client, 922, 6); // The Bonedolier
				}
				case 98:
				{
					CreateHat(client, 922, 11); // The Bonedolier
				}
				case 99:
				{
					CreateHat(client, 922, 13); // The Bonedolier
				}
				case 100:
				{
					CreateHat(client, 948, 1); // The Deadliest Duckling
				}
				case 101:
				{
					CreateHat(client, 948, 6); // The Deadliest Duckling
				}
				case 102:
				{
					CreateHat(client, 610, 6); // A Whiff of the Old Brimstone
				}
				case 103:
				{
					CreateHat(client, 610, 11); // A Whiff of the Old Brimstone
				}
				case 104:
				{
					CreateHat(client, 708, 6); // Aladdin's Private Reserve
				}
				case 105:
				{
					CreateHat(client, 708, 11); // Aladdin's Private Reserve
				}
				case 106:
				{
					CreateHat(client, 771, 6); // The Liquor Locker
				}
				case 107:
				{
					CreateHat(client, 771, 11); // The Liquor Locker
				}
				case 108:
				{
					CreateHat(client, 776, 6); // The Bird-Man of Aberdeen
				}
				case 109:
				{
					CreateHat(client, 776, 11); // The Bird-Man of Aberdeen
				}
				case 110:
				{
					CreateHat(client, 845, 6); // The Battery Bandolier
				}
				case 111:
				{
					CreateHat(client, 874, 6); // King of Scotland Cape
				}
				case 112:
				{
					CreateHat(client, 874, 1); // King of Scotland Cape
				}
				case 113:
				{
					CreateHat(client, 979, 6); // The Cool Breeze
				}
				case 114:
				{
					CreateHat(client, 979, 11); // The Cool Breeze
				}
				case 115:
				{
					CreateHat(client, 30055, 6); // The Scrumpy Strongbox
				}
				case 116:
				{
					CreateHat(client, 30055, 11); // The Scrumpy Strongbox
				}
				case 117:
				{
					CreateHat(client, 30061, 1); // The Tartantaloons
				}
				case 118:
				{
					CreateHat(client, 30061, 6); // The Tartantaloons
				}
				case 119:
				{
					CreateHat(client, 30073, 6); // The Dark Age Defender
				}
				case 120:
				{
					CreateHat(client, 30073, 11); // The Dark Age Defender
				}
				case 121:
				{
					CreateHat(client, 30107, 6); // The Gaelic Golf Bag
				}
				case 122:
				{
					CreateHat(client, 30107, 11); // The Gaelic Golf Bag
				}
				case 123:
				{
					CreateHat(client, 30110, 6); // The Whiskey Bib
				}
				case 124:
				{
					CreateHat(client, 30110, 11); // The Whiskey Bib
				}
				case 125:
				{
					CreateHat(client, 30124, 6); // The Gaelic Garb
				}
				case 126:
				{
					CreateHat(client, 30124, 11); // The Gaelic Garb
				}
				case 127:
				{
					CreateHat(client, 30179, 6); // The Hurt Locher
				}
				case 128:
				{
					CreateHat(client, 30179, 11); // The Hurt Locher
				}
				case 129:
				{
					CreateHat(client, 30333, 6); // Highland High Heels
				}
				case 130:
				{
					CreateHat(client, 30333, 11); // Highland High Heels
				}
				case 131:
				{
					CreateHat(client, 30348, 6); // Bushi-Dou
				}
				case 132:
				{
					CreateHat(client, 30348, 11); // Bushi-Dou
				}
				case 133:
				{
					CreateHat(client, 30358, 6); // The Sole Saviors
				}
				case 134:
				{
					CreateHat(client, 30358, 11); // The Sole Saviors
				}
				case 135:
				{
					CreateHat(client, 30363, 6); // The Juggernaut Jacket
				}
				case 136:
				{
					CreateHat(client, 30363, 11); // The Juggernaut Jacket
				}
				case 137:
				{
					CreateHat(client, 30366, 6); // The Sangu Sleeves
				}
				case 138:
				{
					CreateHat(client, 30366, 11); // The Sangu Sleeves
				}
				case 139:
				{
					CreateHat(client, 30431, 6); // Six Pack Abs
				}
				case 140:
				{
					CreateHat(client, 30431, 11); // Six Pack Abs
				}
				case 141:
				{
					CreateHat(client, 30541, 6); // Double Dynamite
				}
				case 142:
				{
					CreateHat(client, 30541, 11); // Double Dynamite
				}
				case 143:
				{
					CreateHat(client, 30555, 6); // Double Dog Dare Demo Pants
				}
				case 144:
				{
					CreateHat(client, 30555, 11); // Double Dog Dare Demo Pants
				}
				case 145:
				{
					CreateHat(client, 30587, 6); // Storm Stompers
				}
				case 146:
				{
					CreateHat(client, 30587, 11); // Storm Stompers
				}
				case 147:
				{
					CreateHat(client, 30178, 6); // Weight Room Warmer
				}
				case 148:
				{
					CreateHat(client, 30178, 11); // Weight Room Warmer
				}
				case 149:
				{
					CreateHat(client, 30305, 6); // The Sub Zero Suit
				}
				case 150:
				{
					CreateHat(client, 30305, 11); // The Sub Zero Suit
				}
				case 151:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 152:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 153:
				{
					CreateHat(client, 30742, 15); // Shin Shredders
				}
				case 154:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 155:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 156:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 157:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 158:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 159:
				{
					CreateHat(client, 30793, 6); // Aerobatics Demonstrator
				}
				case 160:
				{
					CreateHat(client, 30818, 15); // Socked and Loaded
				}
				case 161:
				{
					CreateHat(client, 30822, 15); // Handy Canes
				}
				case 162:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 163:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 164:
				{
					CreateHat(client, 30886, 15); // Bananades
				}
				case 165:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 166:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 167:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 168:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 169:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 170:
				{
					CreateHat(client, 30788, 15); // Demo's Dustcatcher
				}
				case 171:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 172:
				{
					CreateHat(client, 30945, 15); // Blast Blocker
				}
				case 173:
				{
					CreateHat(client, 30973, 15); // Melody Of Misery
				}
				case 174:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 175:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 176:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 177:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 178:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 179:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 180:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 181:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 182:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 183:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 184:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 185:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 186:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 187:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 188:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 189:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 190:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 191:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 192:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 193:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 194:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
			}
		}
		case TFClass_Medic:
		{
			int rnd3 = GetRandomUInt(0,194);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 620, 6); // Couvre Corner
				}
				case 91:
				{
					CreateHat(client, 620, 11); // Couvre Corner
				}
				case 92:
				{
					CreateHat(client, 621, 6); // The Surgeon's Stethoscope
				}
				case 93:
				{
					CreateHat(client, 621, 11); // The Surgeon's Stethoscope
				}
				case 94:
				{
					CreateHat(client, 639, 6); // Dr. Whoa
				}
				case 95:
				{
					CreateHat(client, 639, 11); // Dr. Whoa
				}
				case 96:
				{
					CreateHat(client, 754, 1); // The Scrap Pack
				}
				case 97:
				{
					CreateHat(client, 754, 6); // The Scrap Pack
				}
				case 98:
				{
					CreateHat(client, 769, 1); // The Quadwranlger
				}
				case 99:
				{
					CreateHat(client, 769, 6); // The Quadwranlger
				}
				case 100:
				{
					CreateHat(client, 770, 6); // The Surgeon's Side Satchel
				}
				case 101:
				{
					CreateHat(client, 770, 11); // The Surgeon's Side Satchel
				}
				case 102:
				{
					CreateHat(client, 828, 6); // Archimedes
				}
				case 103:
				{
					CreateHat(client, 828, 11); // Archimedes
				}
				case 104:
				{
					CreateHat(client, 828, 1); // Archimedes
				}
				case 105:
				{
					CreateHat(client, 843, 6); // The Medic Mech-bag
				}
				case 106:
				{
					CreateHat(client, 878, 6); // The Foppish Physician
				}
				case 107:
				{
					CreateHat(client, 878, 11); // The Foppish Physician
				}
				case 108:
				{
					CreateHat(client, 878, 1); // The Foppish Physician
				}
				case 109:
				{
					CreateHat(client, 978, 6); // Der Wintermantel
				}
				case 110:
				{
					CreateHat(client, 978, 11); // Der Wintermantel
				}
				case 111:
				{
					CreateHat(client, 982, 6); // Doc's Holiday
				}
				case 112:
				{
					CreateHat(client, 982, 11); // Doc's Holiday
				}
				case 113:
				{
					CreateHat(client, 30048, 6); // Mecha-Medes
				}
				case 114:
				{
					CreateHat(client, 30048, 11); // Mecha-Medes
				}
				case 115:
				{
					CreateHat(client, 30096, 6); // Das Feelinbeterbager
				}
				case 116:
				{
					CreateHat(client, 30096, 11); // Das Feelinbeterbager
				}
				case 117:
				{
					CreateHat(client, 30098, 6); // Das Metalmeatencasen
				}
				case 118:
				{
					CreateHat(client, 30098, 11); // Das Metalmeatencasen
				}
				case 119:
				{
					CreateHat(client, 30137, 6); // Das Fantzipantzen
				}
				case 120:
				{
					CreateHat(client, 30137, 11); // Das Fantzipantzen
				}
				case 121:
				{
					CreateHat(client, 30171, 6); // The Medical Mystery
				}
				case 122:
				{
					CreateHat(client, 30171, 11); // The Medical Mystery
				}
				case 123:
				{
					CreateHat(client, 30190, 6); // The Ward
				}
				case 124:
				{
					CreateHat(client, 30190, 11); // The Ward
				}
				case 125:
				{
					CreateHat(client, 30350, 6); // The Dough Puncher
				}
				case 126:
				{
					CreateHat(client, 30350, 11); // The Dough Puncher
				}
				case 127:
				{
					CreateHat(client, 30356, 6); // The Heat of Winter
				}
				case 128:
				{
					CreateHat(client, 30356, 11); // The Heat of Winter
				}
				case 129:
				{
					CreateHat(client, 30361, 6); // The Colonel's Coat
				}
				case 130:
				{
					CreateHat(client, 30361, 11); // The Colonel's Coat
				}
				case 131:
				{
					CreateHat(client, 30365, 6); // The Smock Surgeon
				}
				case 132:
				{
					CreateHat(client, 30365, 11); // The Smock Surgeon
				}
				case 133:
				{
					CreateHat(client, 30379, 6); // The Gaiter Guards
				}
				case 134:
				{
					CreateHat(client, 30379, 11); // The Gaiter Guards
				}
				case 135:
				{
					CreateHat(client, 30415, 6); // The Medicine Manpurse
				}
				case 136:
				{
					CreateHat(client, 30415, 11); // The Medicine Manpurse
				}
				case 137:
				{
					CreateHat(client, 30419, 6); // The Chronoscarf
				}
				case 138:
				{
					CreateHat(client, 30419, 11); // The Chronoscarf
				}
				case 139:
				{
					CreateHat(client, 30483, 6); // Pocket Heavy
				}
				case 140:
				{
					CreateHat(client, 30483, 11); // Pocket Heavy
				}
				case 141:
				{
					CreateHat(client, 30626, 15); // The Vascular Vestment
				}
				case 142:
				{
					CreateHat(client, 30626, 11); // The Vascular Vestment
				}
				case 143:
				{
					CreateHat(client, 936, 6); // The Exorcizor
				}
				case 144:
				{
					CreateHat(client, 936, 11); // The Exorcizor
				}
				case 145:
				{
					CreateHat(client, 936, 13); // The Exorcizor
				}
				case 146:
				{
					CreateHat(client, 30312, 6); // The Angel of Death
				}
				case 147:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 148:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 149:
				{
					CreateHat(client, 30756, 15); // Bunnyhopper's Ballistics Vest
				}
				case 150:
				{
					CreateHat(client, 30750, 15); // Medical Monarch
				}
				case 151:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 152:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 153:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 154:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 155:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 156:
				{
					CreateHat(client, 30817, 15); // Burly Beast
				}
				case 157:
				{
					CreateHat(client, 30813, 15); // Surgeon's Sidearms
				}
				case 158:
				{
					CreateHat(client, 30825, 15); // Santarchimedes
				}
				case 159:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 160:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 161:
				{
					CreateHat(client, 30906, 15); // Vitals Vest
				}
				case 162:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 163:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 164:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 165:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 166:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 167:
				{
					CreateHat(client, 30773, 15); // Surgical Survivalist
				}
				case 168:
				{
					CreateHat(client, 30982, 15); // Scourge of the Sky
				}
				case 169:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 170:
				{
					CreateHat(client, 30940, 15); // Coldfront Carapace
				}
				case 171:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 172:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 173:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 174:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 175:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 176:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 177:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 178:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 179:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 180:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 181:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 182:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 183:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 184:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 185:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 186:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 187:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 188:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 189:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 190:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 191:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 192:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
				case 193:
				{
					CreateHat(client, 31027, 15); // Miser's Muttonchops
				}
				case 194:
				{
					CreateHat(client, 31033, 15); // Harry
				}
			}
		}
		case TFClass_Heavy:
		{
			int rnd3 = GetRandomUInt(0,206);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); // The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); // The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 815, 6); // The Champ Stamp
				}
				case 93:
				{
					CreateHat(client, 815, 11); // The Champ Stamp
				}
				case 94:
				{
					CreateHat(client, 814, 1); // The Triad Trinket
				}
				case 95:
				{
					CreateHat(client, 814, 6); // The Triad Trinket
				}
				case 96:
				{
					CreateHat(client, 814, 11); // The Triad Trinket
				}
				case 97:
				{
					CreateHat(client, 392, 6); // Pocket Medic
				}
				case 98:
				{
					CreateHat(client, 524, 6); // The Purity Fist
				}
				case 99:
				{
					CreateHat(client, 524, 1); // The Purity Fist
				}
				case 100:
				{
					CreateHat(client, 643, 6); // The Sandvich Safe
				}
				case 101:
				{
					CreateHat(client, 643, 11); // The Sandvich Safe
				}
				case 102:
				{
					CreateHat(client, 757, 6); // The Toss-Proof Towel
				}
				case 103:
				{
					CreateHat(client, 757, 11); // The Toss-Proof Towel
				}
				case 104:
				{
					CreateHat(client, 777, 6); // The Apparatchik's Apparel
				}
				case 105:
				{
					CreateHat(client, 777, 11); // The Apparatchik's Apparel
				}
				case 106:
				{
					CreateHat(client, 946, 6); // The Siberian Sophisticate
				}
				case 107:
				{
					CreateHat(client, 946, 1); // The Siberian Sophisticate
				}
				case 108:
				{
					CreateHat(client, 985, 6); // Heavy's Hockey Hair
				}
				case 109:
				{
					CreateHat(client, 985, 11); // Heavy's Hockey Hair
				}
				case 110:
				{
					CreateHat(client, 990, 6); // Aqua Flops
				}
				case 113:
				{
					CreateHat(client, 991, 6); // The Hunger Force
				}
				case 114:
				{
					CreateHat(client, 1028, 6); // The Samson Skewer
				}
				case 115:
				{
					CreateHat(client, 1097, 6); // The Little Bear
				}
				case 116:
				{
					CreateHat(client, 1097, 1); // The Little Bear
				}
				case 117:
				{
					CreateHat(client, 1097, 11); // The Little Bear
				}
				case 118:
				{
					CreateHat(client, 30012, 6); // The Titanium Towel
				}
				case 119:
				{
					CreateHat(client, 30012, 11); // The Titanium Towel
				}
				case 120:
				{
					CreateHat(client, 30074, 6); // The Tyrutleneck
				}
				case 121:
				{
					CreateHat(client, 30074, 11); // The Tyrutleneck
				}
				case 122:
				{
					CreateHat(client, 30079, 6); // The Red Army Robin
				}
				case 123:
				{
					CreateHat(client, 30079, 11); // The Red Army Robin
				}
				case 124:
				{
					CreateHat(client, 30080, 6); // The Heavy-Weight Champ
				}
				case 125:
				{
					CreateHat(client, 30080, 11); // The Heavy-Weight Champ
				}
				case 126:
				{
					CreateHat(client, 30108, 6); // The Borscht Belt
				}
				case 127:
				{
					CreateHat(client, 30108, 11); // The Borscht Belt
				}
				case 128:
				{
					CreateHat(client, 30138, 6); // The Bolshevik Biker
				}
				case 129:
				{
					CreateHat(client, 30138, 11); // The Bolshevik Biker
				}
				case 130:
				{
					CreateHat(client, 30178, 6); // Weight Room Warmer
				}
				case 131:
				{
					CreateHat(client, 30178, 11); // Weight Room Warmer
				}
				case 132:
				{
					CreateHat(client, 30319, 6); // The Mann of the House
				}
				case 133:
				{
					CreateHat(client, 30319, 11); // The Mann of the House
				}
				case 134:
				{
					CreateHat(client, 30342, 6); // The Heavy Lifter
				}
				case 135:
				{
					CreateHat(client, 30342, 11); // The Heavy Lifter
				}
				case 136:
				{
					CreateHat(client, 30343, 6); // Gone Commando
				}
				case 137:
				{
					CreateHat(client, 30343, 11); // Gone Commando
				}
				case 138:
				{
					CreateHat(client, 30354, 6); // The Rat Stompers
				}
				case 139:
				{
					CreateHat(client, 30354, 11); // The Rat Stompers
				}
				case 140:
				{
					CreateHat(client, 30364, 6); // The Warmth Preserver
				}
				case 141:
				{
					CreateHat(client, 30364, 11); // The Warmth Preserver
				}
				case 142:
				{
					CreateHat(client, 30372, 6); // Combat Slacks
				}
				case 143:
				{
					CreateHat(client, 30372, 11); // Combat Slacks
				}
				case 144:
				{
					CreateHat(client, 30556, 6); // Sleeveless in Siberia
				}
				case 145:
				{
					CreateHat(client, 30556, 11); // Sleeveless in Siberia
				}
				case 146:
				{
					CreateHat(client, 30557, 6); // Hunter Heavy
				}
				case 147:
				{
					CreateHat(client, 30557, 11); // Hunter Heavy
				}
				case 148:
				{
					CreateHat(client, 30563, 6); // Jungle Booty
				}
				case 149:
				{
					CreateHat(client, 30563, 11); // Jungle Booty
				}
				case 150:
				{
					CreateHat(client, 30633, 15); // Comissar's Coat
				}
				case 151:
				{
					CreateHat(client, 30633, 11); // Comissar's Coat
				}
				case 152:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 153:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 154:
				{
					CreateHat(client, 30745, 15); // Siberian Sweater
				}
				case 155:
				{
					CreateHat(client, 30747, 15); // Gift Bringer
				}
				case 156:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 157:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 158:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 159:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 160:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 161:
				{
					CreateHat(client, 30803, 15); // Heavy Tourism
				}
				case 162:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 163:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 164:
				{
					CreateHat(client, 1188, 6); // Abominable Snow Pants
				}
				case 165:
				{
					CreateHat(client, 30910, 15); // Heavy Harness
				}
				case 166:
				{
					CreateHat(client, 1189, 6); // Himalayan Hair Shirt
				}
				case 167:
				{
					CreateHat(client, 30913, 15); // Siberian Tigerstripe
				}
				case 168:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 169:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 170:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 171:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 172:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 173:
				{
					CreateHat(client, 30873, 15); // Airborne Attire
				}
				case 174:
				{
					CreateHat(client, 30980, 15); // Tsar Platinum
				}
				case 175:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 176:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 177:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 178:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 179:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 180:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 181:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 182:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 183:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 190:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 191:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 192:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 193:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 194:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 195:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 196:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 197:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 198:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 199:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 200:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 201:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 202:
				{
					CreateHat(client, 1088, 6); // Die Regime-Panzerung
				}
				case 203:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 204:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
				case 205:
				{
					CreateHat(client, 31030, 6); // Paka Parka
				}
			}
		}
		case TFClass_Pyro:
		{
			int rnd3 = GetRandomUInt(0,221);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 641, 6); // The Ornament Armament
				}
				case 91:
				{
					CreateHat(client, 641, 11); // The Ornament Armament
				}
				case 92:
				{
					CreateHat(client, 768, 6); // The Professor's Pineapple
				}
				case 93:
				{
					CreateHat(client, 768, 11); // The Professor's Pineapple
				}
				case 94:
				{
					CreateHat(client, 922, 6); // The Bonedolier
				}
				case 95:
				{
					CreateHat(client, 922, 11); // The Bonedolier
				}
				case 96:
				{
					CreateHat(client, 922, 13); // The Bonedolier
				}
				case 97:
				{
					CreateHat(client, 948, 1); // The Deadliest Duckling
				}
				case 98:
				{
					CreateHat(client, 948, 6); // The Deadliest Duckling
				}
				case 99:
				{
					CreateHat(client, 30236, 6); // Pin Pals
				}
				case 100:
				{
					CreateHat(client, 30236, 13); // Pin Pals
				}
				case 101:
				{
					CreateHat(client, 754, 1); // The Scrap Pack
				}
				case 102:
				{
					CreateHat(client, 754, 6); // The Scrap Pack
				}
				case 103:
				{
					CreateHat(client, 336, 6); // Stockbroker's Scarf
				}
				case 104:
				{
					CreateHat(client, 336, 3); // Stockbroker's Scarf
				}
				case 105:
				{
					CreateHat(client, 336, 11); // Stockbroker's Scarf
				}
				case 106:
				{
					CreateHat(client, 596, 6); // The Moonman Backpack
				}
				case 107:
				{
					CreateHat(client, 632, 6); // The Cremator's Conscience
				}
				case 108:
				{
					CreateHat(client, 632, 11); // The Cremator's Conscience
				}
				case 109:
				{
					CreateHat(client, 651, 6); // The Jingle Belt
				}
				case 110:
				{
					CreateHat(client, 651, 11); // The Jingle Belt
				}
				case 111:
				{
					CreateHat(client, 745, 6); // The Infernal Orchestrina
				}
				case 112:
				{
					CreateHat(client, 745, 11); // The Infernal Orchestrina
				}
				case 113:
				{
					CreateHat(client, 746, 6); // The Burning Bongoes
				}
				case 114:
				{
					CreateHat(client, 746, 11); // The Burning Bongoes
				}
				case 115:
				{
					CreateHat(client, 787, 6); // The Tribal Bones
				}
				case 116:
				{
					CreateHat(client, 820, 6); // The Russian Rocketeer
				}
				case 117:
				{
					CreateHat(client, 820, 1); // The Russian Rocketeer
				}
				case 118:
				{
					CreateHat(client, 842, 6); // The Pyrobotics Pack
				}
				case 119:
				{
					CreateHat(client, 856, 6); // The Pyrotechnic Tote
				}
				case 120:
				{
					CreateHat(client, 856, 11); // The Pyrotechnic Tote
				}
				case 121:
				{
					CreateHat(client, 938, 6); // The Coffin Kit
				}
				case 122:
				{
					CreateHat(client, 938, 11); // The Coffin Kit
				}
				case 123:
				{
					CreateHat(client, 938, 13); // The Coffin Kit
				}
				case 124:
				{
					CreateHat(client, 951, 6); // Rail Spikes
				}
				case 125:
				{
					CreateHat(client, 1072, 6); // The Portable Smissmas Spirit Dispenser
				}
				case 126:
				{
					CreateHat(client, 30020, 6); // The Scrap Sack
				}
				case 127:
				{
					CreateHat(client, 30020, 11); // The Scrap Sack
				}
				case 128:
				{
					CreateHat(client, 30062, 6); // The Steel Sixpack
				}
				case 129:
				{
					CreateHat(client, 30062, 1); // The Steel Sixpack
				}
				case 130:
				{
					CreateHat(client, 30089, 6); // El Muchacho
				}
				case 131:
				{
					CreateHat(client, 30089, 11); // El Muchacho
				}
				case 132:
				{
					CreateHat(client, 30090, 6); // The Backpack Broiler
				}
				case 133:
				{
					CreateHat(client, 30090, 11); // The Backpack Broiler
				}
				case 134:
				{
					CreateHat(client, 30092, 6); // The Soot Suit
				}
				case 135:
				{
					CreateHat(client, 30092, 11); // The Soot Suit
				}
				case 136:
				{
					CreateHat(client, 30169, 6); // Trickster's Turnout Gear
				}
				case 137:
				{
					CreateHat(client, 30169, 11); // Trickster's Turnout Gear
				}
				case 138:
				{
					CreateHat(client, 30305, 6); // The Sub Zero Suit
				}
				case 139:
				{
					CreateHat(client, 30305, 11); // The Sub Zero Suit
				}
				case 140:
				{
					CreateHat(client, 30308, 6); // The Trail-Blazer
				}
				case 141:
				{
					CreateHat(client, 30308, 11); // The Trail-Blazer
				}
				case 142:
				{
					CreateHat(client, 30321, 6); // Tiny Timber
				}
				case 143:
				{
					CreateHat(client, 30321, 11); // Tiny Timber
				}
				case 144:
				{
					CreateHat(client, 30391, 6); // The Sengoku Scorcher
				}
				case 145:
				{
					CreateHat(client, 30391, 11); // The Sengoku Scorcher
				}
				case 146:
				{
					CreateHat(client, 30398, 6); // The Gas Guzzler
				}
				case 147:
				{
					CreateHat(client, 30398, 11); // The Gas Guzzler
				}
				case 148:
				{
					CreateHat(client, 30400, 6); // The Lunatic's Leathers
				}
				case 149:
				{
					CreateHat(client, 30400, 11); // The Lunatic's Leathers
				}
				case 150:
				{
					CreateHat(client, 30417, 6); // The Frymaster
				}
				case 151:
				{
					CreateHat(client, 30417, 11); // The Frymaster
				}
				case 152:
				{
					CreateHat(client, 30544, 6); // North Polar Fleece
				}
				case 153:
				{
					CreateHat(client, 30544, 11); // North Polar Fleece
				}
				case 154:
				{
					CreateHat(client, 30581, 6); // Pyromancer's Raiments
				}
				case 155:
				{
					CreateHat(client, 30581, 11); // Pyromancer's Raiments
				}
				case 156:
				{
					CreateHat(client, 30583, 6); // Torcher's Tabard
				}
				case 157:
				{
					CreateHat(client, 30583, 11); // Torcher's Tabard
				}
				case 158:
				{
					CreateHat(client, 30584, 6); // Charred Chainmail
				}
				case 159:
				{
					CreateHat(client, 30584, 11); // Charred Chainmail
				}
				case 160:
				{
					CreateHat(client, 30663, 6); // Jupiter Jetpack
				}
				case 161:
				{
					CreateHat(client, 30663, 11); // Jupiter Jetpack
				}
				case 162:
				{
					CreateHat(client, 30664, 15); // The Space Diver
				}
				case 163:
				{
					CreateHat(client, 30664, 11); // The Space Diver
				}
				case 164:
				{
					CreateHat(client, 936, 6); // The Exorcizor
				}
				case 165:
				{
					CreateHat(client, 936, 11); // The Exorcizor
				}
				case 166:
				{
					CreateHat(client, 936, 13); // The Exorcizor
				}
				case 167:
				{
					CreateHat(client, 30167, 6); // The Beep Boy
				}
				case 168:
				{
					CreateHat(client, 30167, 11); // The Beep Boy
				}
				case 169:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 170:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 171:
				{
					CreateHat(client, 30716, 15); // Crusader's Getup
				}
				case 172:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 173:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 174:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 175:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 176:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 177:
				{
					CreateHat(client, 30795, 6); // Hovering Hotshot
				}
				case 178:
				{
					CreateHat(client, 30819, 15); // Flammable Favor
				}
				case 179:
				{
					CreateHat(client, 30826, 15); // Sweet Smissmas Sweater
				}
				case 180:
				{
					CreateHat(client, 30818, 15); // Socked and Loaded
				}
				case 181:
				{
					CreateHat(client, 30822, 15); // Handy Canes
				}
				case 182:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 183:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 184:
				{
					CreateHat(client, 30902, 15); // Deity's Dress
				}
				case 185:
				{
					CreateHat(client, 30900, 15); // Fireman's Essentials
				}
				case 186:
				{
					CreateHat(client, 30905, 15); // Hot Huaraches
				}
				case 187:
				{
					CreateHat(client, 30904, 15); // Sacrificial Stone
				}
				case 188:
				{
					CreateHat(client, 30886, 15); // Bananades
				}
				case 189:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 190:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 191:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 192:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 193:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 194:
				{
					CreateHat(client, 30986, 15); // Hot Case
				}
				case 195:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 196:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 197:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 198:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 199:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 200:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 201:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 202:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 203:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 204:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 205:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 206:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 207:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 208:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 209:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 210:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 211:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 212:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 213:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 214:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 215:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 216:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 217:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 218:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 219:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 220:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
				case 221:
				{
					CreateHat(client, 31026, 15); // Pocket Pardner
				}
			}
		}
		case TFClass_Spy:
		{
			int rnd3 = GetRandomUInt(0,182);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 814, 1); // The Triad Trinket
				}
				case 91:
				{
					CreateHat(client, 814, 6); // The Triad Trinket
				}
				case 92:
				{
					CreateHat(client, 814, 11); // The Triad Trinket
				}
				case 93:
				{
					CreateHat(client, 639, 6); // Dr. Whoa
				}
				case 94:
				{
					CreateHat(client, 639, 11); // Dr. Whoa
				}
				case 95:
				{
					CreateHat(client, 462, 6); // The Made Man
				}
				case 96:
				{
					CreateHat(client, 483, 6); // Rogue's Col Roule
				}
				case 97:
				{
					CreateHat(client, 763, 6); // The Sneaky Spats of Sneaking
				}
				case 98:
				{
					CreateHat(client, 763, 11); // The Sneaky Spats of Sneaking
				}
				case 99:
				{
					CreateHat(client, 782, 6); // The Business Casual
				}
				case 100:
				{
					CreateHat(client, 782, 11); // The Business Casual
				}
				case 101:
				{
					CreateHat(client, 879, 6); // The Distinguished Rogue
				}
				case 102:
				{
					CreateHat(client, 879, 1); // The Distinguished Rogue
				}
				case 103:
				{
					CreateHat(client, 936, 6); // The Exorcizor
				}
				case 104:
				{
					CreateHat(client, 936, 11); // The Exorcizor
				}
				case 105:
				{
					CreateHat(client, 936, 13); // The Exorcizor
				}
				case 106:
				{
					CreateHat(client, 977, 6); // The Cut-Throat Concierge
				}
				case 107:
				{
					CreateHat(client, 977, 11); // The Cut-Throat Concierge
				}
				case 108:
				{
					CreateHat(client, 30125, 6); // The Rogue's Brogues
				}
				case 109:
				{
					CreateHat(client, 30125, 11); // The Rogue's Brogues
				}
				case 110:
				{
					CreateHat(client, 30132, 6); // The Blood Banker
				}
				case 111:
				{
					CreateHat(client, 30132, 11); // The Blood Banker
				}
				case 112:
				{
					CreateHat(client, 30132, 6); // The After Dark
				}
				case 113:
				{
					CreateHat(client, 30132, 11); // The After Dark
				}
				case 114:
				{
					CreateHat(client, 30183, 6); // Escapist
				}
				case 115:
				{
					CreateHat(client, 30183, 11); // Escapist
				}
				case 116:
				{
					CreateHat(client, 30189, 6); // The Frenchman's Formals
				}
				case 117:
				{
					CreateHat(client, 30189, 11); // The Frenchman's Formals
				}
				case 118:
				{
					CreateHat(client, 30353, 6); // The Backstabber's Boomslang
				}
				case 119:
				{
					CreateHat(client, 30353, 11); // The Backstabber's Boomslang
				}
				case 120:
				{
					CreateHat(client, 30389, 6); // The Rogue's Robe
				}
				case 121:
				{
					CreateHat(client, 30389, 11); // The Rogue's Robe
				}
				case 122:
				{
					CreateHat(client, 30405, 6); // The Sky Captain
				}
				case 123:
				{
					CreateHat(client, 30405, 11); // The Sky Captain
				}
				case 124:
				{
					CreateHat(client, 30411, 6); // The Au Courant Assassin
				}
				case 125:
				{
					CreateHat(client, 30411, 11); // The Au Courant Assassin
				}
				case 126:
				{
					CreateHat(client, 30467, 1); // The Spycrab
				}
				case 127:
				{
					CreateHat(client, 30476, 6); // The Lady Killer
				}
				case 128:
				{
					CreateHat(client, 30476, 11); // The Lady Killer
				}
				case 129:
				{
					CreateHat(client, 30602, 6); // Puffy Provocateur
				}
				case 130:
				{
					CreateHat(client, 30602, 11); // Puffy Provocateur
				}
				case 131:
				{
					CreateHat(client, 30603, 6); // Stealthy Scarf
				}
				case 132:
				{
					CreateHat(client, 30603, 11); // Stealthy Scarf
				}
				case 133:
				{
					CreateHat(client, 30606, 6); // Pocket Momma
				}
				case 134:
				{
					CreateHat(client, 30606, 11); // Pocket Momma
				}
				case 135:
				{
					CreateHat(client, 30631, 15); // Lurker's Leathers
				}
				case 136:
				{
					CreateHat(client, 30631, 11); // Lurker's Leathers
				}
				case 137:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 138:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 139:
				{
					CreateHat(client, 30752, 15); // Chicago Overcoat
				}
				case 140:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 141:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 142:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 143:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 144:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 145:
				{
					CreateHat(client, 30797, 15); // Showstopper
				}
				case 146:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 147:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 148:
				{
					CreateHat(client, 30884, 15); // Aloha Apparel
				}
				case 149:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 150:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 151:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 152:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 153:
				{
					CreateHat(client, 31014, 15); // Dressperado
				}
				case 154:
				{
					CreateHat(client, 31015, 15); // Bandit's Boots
				}
				case 155:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 156:
				{
					CreateHat(client, 30777, 15); // Lurking Legionnaire
				}
				case 157:
				{
					CreateHat(client, 30988, 15); // Aristotle
				}
				case 158:
				{
					CreateHat(client, 30989, 15); // Assassin's Attire
				}
				case 159:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 160:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 161:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 162:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 163:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 164:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 165:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 166:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 167:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 168:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 169:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 170:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 171:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 172:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 173:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 174:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 175:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 176:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 177:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 178:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 179:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 180:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 181:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
				case 182:
				{
					CreateHat(client, 31033, 15); // Harry
				}
			}
		}
		case TFClass_Engineer:
		{
			int rnd3 = GetRandomUInt(0,229);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); // Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); // Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); // Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); // Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); // Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); // The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); // Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); // Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); // The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); // Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); // The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); // The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); // The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); // The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); // The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); // Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); // Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); // Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); // Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); // Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); // Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); // Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); // Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); // Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); // Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); // Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); // Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); // Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); // Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); // The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); // Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); // Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); // Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); // The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); // The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); // The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); // The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); // The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); // Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); // Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); // Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); // Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); // Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); // Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); // Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); // Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); // Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); // Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); // Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); // Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); // Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); // Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); // Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); // Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); // Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); // Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); // License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); // Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); // Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); // Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); // SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); // Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); // Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); // Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); // Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); // Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); // Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); // The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); // The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); // The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); // Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); // Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); // Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); // The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); // The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); // The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); // Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); // Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); // Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); // Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); // The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); // Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); // Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); // Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); // Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); // End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); // Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); // Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); // Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 814, 1); // The Triad Trinket
				}
				case 91:
				{
					CreateHat(client, 814, 6); // The Triad Trinket
				}
				case 92:
				{
					CreateHat(client, 814, 11); // The Triad Trinket
				}
				case 93:
				{
					CreateHat(client, 815, 1); // The Champ Stamp
				}
				case 94:
				{
					CreateHat(client, 815, 6); // The Champ Stamp
				}
				case 95:
				{
					CreateHat(client, 815, 11); // The Champ Stamp
				}
				case 96:
				{
					CreateHat(client, 646, 6); // The Itsy Bitsy Spyer
				}
				case 97:
				{
					CreateHat(client, 646, 11); // The Itsy Bitsy Spyer
				}
				case 98:
				{
					CreateHat(client, 734, 6); // The Teufort Tooth Kicker
				}
				case 99:
				{
					CreateHat(client, 734, 11); // The Teufort Tooth Kicker
				}
				case 100:
				{
					CreateHat(client, 30056, 6); // The Dual-Core Devil Doll
				}
				case 101:
				{
					CreateHat(client, 30056, 11); // The Dual-Core Devil Doll
				}
				case 102:
				{
					CreateHat(client, 30481, 6); // Hillbilly Speed Bump
				}
				case 103:
				{
					CreateHat(client, 30481, 11); // Hillbilly Speed Bump
				}
				case 104:
				{
					CreateHat(client, 948, 1); // The Deadliest Duckling
				}
				case 105:
				{
					CreateHat(client, 948, 6); // The Deadliest Duckling
				}
				case 106:
				{
					CreateHat(client, 386, 6); // Teddy Roosebelt
				}
				case 107:
				{
					CreateHat(client, 386, 11); // Teddy Roosebelt
				}
				case 108:
				{
					CreateHat(client, 484, 6); // Prarie Heel Biters
				}
				case 109:
				{
					CreateHat(client, 519, 6); // Pip-Boy
				}
				case 110:
				{
					CreateHat(client, 519, 1); // Pip-Boy
				}
				case 111:
				{
					CreateHat(client, 520, 6); // Wingstick
				}
				case 112:
				{
					CreateHat(client, 520, 1); // Wingstick
				}
				case 113:
				{
					CreateHat(client, 606, 6); // The Builder's Blueprints
				}
				case 114:
				{
					CreateHat(client, 606, 11); // The Builder's Blueprints
				}
				case 115:
				{
					CreateHat(client, 670, 6); // The Stocking Stuffer
				}
				case 116:
				{
					CreateHat(client, 670, 11); // The Stocking Stuffer
				}
				case 117:
				{
					CreateHat(client, 755, 6); // The Texas Half-Pants
				}
				case 118:
				{
					CreateHat(client, 755, 11); // The Texas Half-Pants
				}
				case 119:
				{
					CreateHat(client, 784, 6); // The Idea Tube
				}
				case 120:
				{
					CreateHat(client, 784, 11); // The Idea Tube
				}
				case 121:
				{
					CreateHat(client, 1008, 6); // The Prize Plushy
				}
				case 122:
				{
					CreateHat(client, 1008, 1); // The Prize Plushy
				}
				case 123:
				{
					CreateHat(client, 1089, 6); // Mister Bubbles
				}
				case 124:
				{
					CreateHat(client, 1089, 1); // Mister Bubbles
				}
				case 125:
				{
					CreateHat(client, 30023, 6); // Teddy Robobelt
				}
				case 126:
				{
					CreateHat(client, 30023, 11); // Teddy Robobelt
				}
				case 127:
				{
					CreateHat(client, 30070, 6); // The Pocket Pyro
				}
				case 128:
				{
					CreateHat(client, 30070, 11); // The Pocket Pyro
				}
				case 129:
				{
					CreateHat(client, 30086, 6); // The Trash Toter
				}
				case 130:
				{
					CreateHat(client, 30086, 11); // The Trash Toter
				}
				case 131:
				{
					CreateHat(client, 30087, 6); // The Dry Gulch Gulp
				}
				case 132:
				{
					CreateHat(client, 30087, 11); // The Dry Gulch Gulp
				}
				case 133:
				{
					CreateHat(client, 30113, 6); // The Flared Frontiersman
				}
				case 134:
				{
					CreateHat(client, 30113, 11); // The Flared Frontiersman
				}
				case 135:
				{
					CreateHat(client, 30167, 6); // The Beep Boy
				}
				case 136:
				{
					CreateHat(client, 30167, 11); // The Beep Boy
				}
				case 137:
				{
					CreateHat(client, 30330, 6); // The Dogfighter
				}
				case 138:
				{
					CreateHat(client, 30330, 11); // The Dogfighter
				}
				case 139:
				{
					CreateHat(client, 30337, 6); // The Trencher's Tunic
				}
				case 140:
				{
					CreateHat(client, 30337, 11); // The Trencher's Tunic
				}
				case 141:
				{
					CreateHat(client, 30341, 6); // Ein
				}
				case 142:
				{
					CreateHat(client, 30341, 11); // Ein
				}
				case 143:
				{
					CreateHat(client, 30377, 6); // The Antarctic Researcher
				}
				case 144:
				{
					CreateHat(client, 30377, 11); // The Antarctic Researcher
				}
				case 145:
				{
					CreateHat(client, 30402, 6); // The Tools of the Trade
				}
				case 146:
				{
					CreateHat(client, 30402, 11); // The Tools of the Trade
				}
				case 147:
				{
					CreateHat(client, 30403, 6); // The Joe-on-the-Go
				}
				case 148:
				{
					CreateHat(client, 30403, 11); // The Joe-on-the-Go
				}
				case 149:
				{
					CreateHat(client, 30408, 6); // The Egghead's Overalls
				}
				case 150:
				{
					CreateHat(client, 30408, 11); // The Egghead's Overalls
				}
				case 151:
				{
					CreateHat(client, 30409, 6); // The Lonesome Loafers
				}
				case 152:
				{
					CreateHat(client, 30409, 11); // The Lonesome Loafers
				}
				case 153:
				{
					CreateHat(client, 30412, 6); // The Endothermic Exowear
				}
				case 154:
				{
					CreateHat(client, 30412, 11); // The Endothermic Exowear
				}
				case 155:
				{
					CreateHat(client, 30539, 6); // Insulated Inventor
				}
				case 156:
				{
					CreateHat(client, 30539, 11); // Insulated Inventor
				}
				case 157:
				{
					CreateHat(client, 30590, 6); // Holstered Heaters
				}
				case 158:
				{
					CreateHat(client, 30590, 11); // Holstered Heaters
				}
				case 159:
				{
					CreateHat(client, 30591, 6); // Cop Caller
				}
				case 160:
				{
					CreateHat(client, 30591, 11); // Cop Caller
				}
				case 161:
				{
					CreateHat(client, 30593, 6); // Clubsy the Seal
				}
				case 162:
				{
					CreateHat(client, 30593, 11); // Clubsy the Seal
				}
				case 163:
				{
					CreateHat(client, 30605, 6); // Thermal Insulation Layer
				}
				case 164:
				{
					CreateHat(client, 30605, 11); // Thermal Insulation Layer
				}
				case 165:
				{
					CreateHat(client, 30629, 15); // Support Spurs
				}
				case 166:
				{
					CreateHat(client, 30629, 11); // Support Spurs
				}
				case 167:
				{
					CreateHat(client, 30635, 15); // Wild West Waistcoat
				}
				case 168:
				{
					CreateHat(client, 30635, 11); // Wild West Waistcoat
				}
				case 169:
				{
					CreateHat(client, 30654, 15); // Life Support System
				}
				case 170:
				{
					CreateHat(client, 30654, 11); // Life Support System
				}
				case 171:
				{
					CreateHat(client, 30655, 15); // Rocket Operator
				}
				case 172:
				{
					CreateHat(client, 30655, 11); // Rocket Operator
				}
				case 173:
				{
					CreateHat(client, 30543, 6); // Snow Stompers
				}
				case 174:
				{
					CreateHat(client, 30543, 11); // Snow Stompers
				}
				case 175:
				{
					CreateHat(client, 30706, 15); // Catastrophic Companions
				}
				case 176:
				{
					CreateHat(client, 30693, 15); // Grim Tweeter
				}
				case 178:
				{
					CreateHat(client, 30680, 15); // El Caballero
				}
				case 179:
				{
					CreateHat(client, 30698, 15); // Iron Lung
				}
				case 180:
				{
					CreateHat(client, 30675, 15); // Roboot
				}
				case 181:
				{
					CreateHat(client, 30749, 15); // Winter Backup
				}
				case 182:
				{
					CreateHat(client, 9229, 1); // Altruist's Adornment
				}
				case 183:
				{
					CreateHat(client, 1171, 6); // PASS Time Early Participation Pin
				}
				case 184:
				{
					CreateHat(client, 1170, 6); // PASS Time Miniature Half JACK
				}
				case 185:
				{
					CreateHat(client, 9228, 1); // TF2Maps 72hr TF2Jam Participant
				}
				case 186:
				{
					CreateHat(client, 30757, 6); // Prinny Pouch
				}
				case 187:
				{
					CreateHat(client, 30804, 15); // El Paso Poncho
				}
				case 188:
				{
					CreateHat(client, 30794, 6); // Final Frontier Freighter
				}
				case 189:
				{
					CreateHat(client, 30821, 15); // Packable Provisions
				}
				case 190:
				{
					CreateHat(client, 9307, 1); // Special Snowflake 2016
				}
				case 191:
				{
					CreateHat(client, 9308, 1); // Gift of Giving 2016
				}
				case 192:
				{
					CreateHat(client, 30908, 15); // Conaghers' Utility Idol
				}
				case 193:
				{
					CreateHat(client, 30909, 15); // Tropical Toad
				}
				case 194:
				{
					CreateHat(client, 30884, 15); // Aloha Apparel
				}
				case 195:
				{
					CreateHat(client, 30881, 15); // Croaking Hazard
				}
				case 196:
				{
					CreateHat(client, 30880, 15); // Pocket Saxton
				}
				case 197:
				{
					CreateHat(client, 30878, 15); // Quizzical Quetzal
				}
				case 198:
				{
					CreateHat(client, 30883, 15); // Slithering Scarf
				}
				case 199:
				{
					CreateHat(client, 30994, 6); // A Shell of a Mann
				}
				case 200:
				{
					CreateHat(client, 31012, 15); // Aim Assistant
				}
				case 201:
				{
					CreateHat(client, 31013, 15); // Mini-Engy
				}
				case 202:
				{
					CreateHat(client, 30996, 15); // Terror-antula
				}
				case 203:
				{
					CreateHat(client, 30785, 15); // Dad Duds
				}
				case 204:
				{
					CreateHat(client, 30992, 15); // Cold Case
				}
				case 205:
				{
					CreateHat(client, 30975, 15); // Robin Walkers
				}
				case 206:
				{
					CreateHat(client, 30972, 15); // Pocket Santa
				}
				case 207:
				{
					CreateHat(client, 30929, 15); // Pocket Yeti
				}
				case 208:
				{
					CreateHat(client, 30923, 15); // Sledder's Sidekick
				}
				case 209:
				{
					CreateHat(client, 30738, 6); // Batbelt
				}
				case 210:
				{
					CreateHat(client, 30722, 6); // Batter's Bracers
				}
				case 211:
				{
					CreateHat(client, 9048, 1); // Gift of Giving
				}
				case 212:
				{
					CreateHat(client, 8367, 1); // Heart of Gold
				}
				case 213:
				{
					CreateHat(client, 9941, 1); // Heartfelt Hero
				}
				case 214:
				{
					CreateHat(client, 9515, 1); // Heartfelt Hug
				}
				case 215:
				{
					CreateHat(client, 9510, 1); // Mappers vs. Machines Participant Medal 2017
				}
				case 216:
				{
					CreateHat(client, 9731, 1); // Philanthropist's Indulgence
				}
				case 217:
				{
					CreateHat(client, 9047, 1); // Special Snowflake
				}
				case 218:
				{
					CreateHat(client, 9732, 1); // Spectral Snowflake
				}
				case 219:
				{
					CreateHat(client, 8584, 1); // Thought that Counts
				}
				case 220:
				{
					CreateHat(client, 9720, 1); // Titanium Tank Participant Medal 2017
				}
				case 221:
				{
					CreateHat(client, 8477, 1); // Tournament Medal - Tumblr Vs Reddit (Season 2)
				}
				case 222:
				{
					CreateHat(client, 8395, 1); // Tumblr Vs Reddit Participant
				}
				case 223:
				{
					CreateHat(client, 30728, 6); // Buttler
				}
				case 224:
				{
					CreateHat(client, 823, 6); // Pocket Purrer
				}
				case 225:
				{
					CreateHat(client, 8633, 1); // Asymmetric Accolade
				}
				case 226:
				{
					CreateHat(client, 30726, 6); // Pocket Villains
				}
				case 227:
				{
					CreateHat(client, 31019, 6); // Pocket Admin
				}
				case 228:
				{
					CreateHat(client, 31018, 15); // Polar Pal
				}
				case 229:
				{
					CreateHat(client, 31032, 15); // Puggyback
				}
			}
		}
	}
}

bool CreateHat(int client, int itemindex, int quality, int level = 0)
{
	int hat = CreateEntityByName("tf_wearable");

	if (!IsValidEntity(hat))
	{
		return false;
	}

	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);

	if (level)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,100));
	}

	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}