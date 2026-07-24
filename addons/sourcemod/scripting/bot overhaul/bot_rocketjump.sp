#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.0"

public Plugin myinfo = 
{
	name = "TFBot Rocket Jump",
	author = "EfeDursun125",
	description = "TFBots now making rocket jump.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action RoundStarted(Handle  event , const char[]  name , bool  dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "ctf_2fort" , false) != -1)
	{
		int snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "2");
		int snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "2");
		int snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "2");

		float origin[3] = {233.0, 1020.0, 294.0};
		float origin2[3] = {-234.0, 1028.0, 294.0};
		float origin3[3] = {23.0, 881.0, 0.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);
		
		int snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "3");
		int snipepos5 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos5, "team", "3");
		int snipepos6 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos6, "team", "3");

		float origin4[3] = {-224.0, -1042.0, 306.0};
		float origin5[3] = {229.0, -1029.0, 305.0};
		float origin6[3] = {-27.0, -876.0, 298.0};

		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos5, origin5, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos6, origin6, NULL_VECTOR, NULL_VECTOR);
	}
	if(StrContains(currentMap, "tc_hydro" , false) != -1)
	{
		int snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "0");
		int snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "0");
		int snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "0");
		int snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "0");
		int snipepos5 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos5, "team", "0");
		int snipepos6 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos6, "team", "0");

		float origin[3] = {1605.0, 2383.0, 523.0};
		float origin2[3] = {2368.0, 1363.0, 523.0};
		float origin3[3] = {2375.0, 2633.0, 523.0};
		float origin4[3] = {2267.0, -1278.0, 363.0};
		float origin5[3] = {-2136.0, 858.0, 476.0};
		float origin6[3] = {-2133.0, 1427.0, 468.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos5, origin5, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos6, origin6, NULL_VECTOR, NULL_VECTOR);
	}
	if(StrContains(currentMap, "koth_harvest_final" , false) != -1)
	{
		int snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "2");
		int snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "2");
		int snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "2");
		int snipepos10 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos10, "team", "2");
		int snipepos11 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos11, "team", "2");
		int snipepos12 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos12, "team", "2");

		float origin[3] = {922.0, -1043.0, 366.0};
		float origin2[3] = {-1424.0, -395.0, 331.0};
		float origin3[3] = {-930.0, -414.0, 331.0};
		float origin10[3] = {-743.0, -1093.0, 448.0};
		float origin11[3] = {-242.0, -1090.0, 45.0};
		float origin12[3] = {1262.0, 387.0, 300.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos10, origin10, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos11, origin11, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos12, origin12, NULL_VECTOR, NULL_VECTOR);
		
		int snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "3");
		int snipepos5 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos5, "team", "3");
		int snipepos6 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos6, "team", "3");
		int snipepos7 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos7, "team", "3");
		int snipepos8 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos8, "team", "3");
		int snipepos9 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos9, "team", "3");

		float origin4[3] = {-892.0, 1032.0, 367.0};
		float origin5[3] = {1344.0, 296.0, 331.0};
		float origin6[3] = {198.0, 1085.0, 454.0};
		float origin7[3] = {744.0, 1093.0, 449.0};
		float origin8[3] = {892.0, 397.0, 331.0};
		float origin9[3] = {-1295.0, -392.0, 300.0};

		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos5, origin5, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos6, origin6, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos7, origin7, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos8, origin8, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos9, origin9, NULL_VECTOR, NULL_VECTOR);
	}
	if(StrContains(currentMap, "pl_badwater" , false) != -1)
	{
		int snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "3");
		int snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "3");
		int sentrypos = CreateEntityByName("bot_hint_sentrygun");
		DispatchKeyValue(sentrypos, "team", "3");
		int engipos = CreateEntityByName("bot_hint_engineer_nest");
		DispatchKeyValue(engipos, "team", "3");
	
		float origin[3] = {-183.0, 1921.0, 452.0};
		float origin2[3] = {522.0, 2025.0, 193.0};
		float origin3[3] = {-650.0, 992.0, 232.0};
	
		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(sentrypos, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(engipos, origin2, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				TFClassType class = TF2_GetPlayerClass(client);
				int team = GetClientTeam(client);
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));
				
				if(class == TFClass_Soldier)
				{
					//int itemflag; // TODO : How to make detect flag?
					//int Flag;
					//if((Flag = FindEntityByClassname(Flag, "iteam_teamflag")) != INVALID_ENT_REFERENCE)
					//{
					//	if(IsValidEntity(Flag))
					//	{
					//		float fEntityLocation[3];
					//		float clientOrigin[3];
					//		GetClientAbsOrigin(client, clientOrigin);
					//		GetEntPropVector(Flag, Prop_Send, "m_vecOrigin", fEntityLocation);
					//
					//		float chainDistance2;
					//		chainDistance2 = GetVectorDistance(clientOrigin,fEntityLocation);
					//		
					//		if(chainDistance2 < 1000.0)
					//		{
					//			itemflag = 1;
					//		}
					//		else
					//		{
					//			itemflag = 0;
					//		}
					//	}
					//}
					if(StrContains(currentMap, "ctf_2fort" , false) != -1)
					{
						float clientOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						if(team == 2)
						{
							float rocketjump1[3] = {-257.0, -761.0, 68.0};
							float rocketjump2[3] = {255.0, -788.0, 87.0};
							float rocketjumpfix1[3] = {-220.0, -882.0, 332.0};
							float rocketjumpfix2[3] = {229.0, -888.0, 332.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
						if(team == 3)
						{
							float rocketjump1[3] = {255.0, 741.0, 60.0};
							float rocketjump2[3] = {-252.0, 795.0, 90.0};
							float rocketjump3[3] = {-992.0, -1918.0, 144.0};
							float rocketjumpfix1[3] = {-226.0, 879.0, 300.0};
							float rocketjumpfix2[3] = {231.0, 897.0, 482.0};
							float rocketjumpfix3[3] = {-832.0, -1911.0, 324.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							float chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							float chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
					}
					if(StrContains(currentMap, "pl_badwater" , false) != -1)
					{
						float clientOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						if(team == 3)
						{
							float rocketjump1[3] = {2137.0, -1494.0, 196.0};
							float rocketjump2[3] = {621.0, -771.0, 389.0};
							float rocketjump3[3] = {-459.0, 994.0, -60.0};
							float rocketjumpfix1[3] = {1943.0, -1473.0, 453.0};
							float rocketjumpfix2[3] = {450.0, -707.0, 597.0};
							float rocketjumpfix3[3] = {-650.0, 992.0, 232.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							float chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							float chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 166.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 166.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
						if(team == 2)
						{
							float rocketjump1[3] = {536.0, 1895.0, 196.0};
							float rocketjump2[3] = {-172.0, 1133.0, -59.0};
							float rocketjump3[3] = {-1699.0, 1283.0, 120.0};
							float rocketjump4[3] = {348.0, -1913.0, 196.0};
							float rocketjump5[3] = {-459.0, 994.0, -60.0};
							float rocketjumpfix1[3] = {529.0, 1763.0, 324.0};
							float rocketjumpfix2[3] = {-19.0, 1287.0, 196.0};
							float rocketjumpfix3[3] = {-1697.0, 1059.0, 324.0};
							float rocketjumpfix4[3] = {471.0, -1904.0, 388.0};
							float rocketjumpfix5[3] = {-650.0, 992.0, 232.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							float chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							float chainDistance7;
							chainDistance7 = GetVectorDistance(clientOrigin,rocketjump4);
							float chainDistance9;
							chainDistance9 = GetVectorDistance(clientOrigin,rocketjump5);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							float chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							float chainDistance8;
							chainDistance8 = GetVectorDistance(clientOrigin,rocketjumpfix4);
							float chainDistance10;
							chainDistance10 = GetVectorDistance(clientOrigin,rocketjumpfix5);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 37.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance7 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 0.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance9 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 37.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance8 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 0.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance10 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
					}
					if(StrContains(currentMap, "koth_harvest_final" , false) != -1)
					{
						float clientOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						if(team == 2)
						{
							float rocketjump1[3] = {-586.0, -1566.0, 68.0};
							float rocketjump2[3] = {6.0, -318.0, 84.0};
							float rocketjump3[3] = {438.0, 495.0, 69.0};
							float rocketjump4[3] = {0.0, -1651.0, 68.0};
							float rocketjumpfix1[3] = {-571.0, -1427.0, 281.0};
							float rocketjumpfix2[3] = {-2.0, -222.0, 292.0};
							float rocketjumpfix3[3] = {425.0, 617.0, 280.0};
							float rocketjumpfix4[3] = {216.0, -1531.0, 68.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							float chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							float chainDistance7;
							chainDistance7 = GetVectorDistance(clientOrigin,rocketjump4);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							float chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							float chainDistance8;
							chainDistance8 = GetVectorDistance(clientOrigin,rocketjumpfix4);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance7 < 75.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 40.0;
									newDirection[1] = -135.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
										vel = moveForward(vel,300.0);
									}
								}
								if(chainDistance8 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 35.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
						if(team == 3)
						{
							float rocketjump1[3] = {578.0, 1561.0, 68.0};
							float rocketjump2[3] = {73.0, 345.0, 79.0};
							float rocketjump3[3] = {-495.0, -537.0, 75.0};
							float rocketjump4[3] = {1382.0, -159.0, 62.0};
							float rocketjump5[3] = {661.0, -96.0, 70.0};
							float rocketjumpfix1[3] = {597.0, 1429.0, 280.0};
							float rocketjumpfix2[3] = {54.0, 225.0, 291.0};
							float rocketjumpfix3[3] = {-461.0, -623.0, 282.0};
							float rocketjumpfix4[3] = {1049.0, -183.0, 67.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							float chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							float chainDistance7;
							chainDistance7 = GetVectorDistance(clientOrigin,rocketjump4);
							float chainDistance8;
							chainDistance8 = GetVectorDistance(clientOrigin,rocketjump5);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							float chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							float chainDistance9;
							chainDistance9 = GetVectorDistance(clientOrigin,rocketjumpfix4);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance7 < 60.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 50.0;
									newDirection[1] = 0.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance8 < 75.0)
								{
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										GetClientEyeAngles(client, newDirection);
										newDirection[0] = 89.0;
										newDirection[1] = 160.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
										buttons |= IN_JUMP;
										buttons |= IN_DUCK;
										buttons |= IN_ATTACK;
										vel = moveForward(vel,300.0);
									}
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 89.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance9 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 177.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
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

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

bool IsValidClient( int client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  