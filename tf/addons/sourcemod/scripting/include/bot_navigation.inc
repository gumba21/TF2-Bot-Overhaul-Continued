#if defined _bot_navigation_included
 #endinput
#endif
#define _bot_navigation_included

enum BNRouteProfile
{
    BNProfile_Fastest = 0,
    BNProfile_Safest,
    BNProfile_Retreat,
    BNProfile_Flank,
    BNProfile_Push,
    BNProfile_Support,
    BNProfile_Defensive,
    BNProfile_Stealth
};

enum BNMovementPurpose
{
    BNPurpose_None = 0,
    BNPurpose_Attack,
    BNPurpose_Retreat,
    BNPurpose_Regroup,
    BNPurpose_Flank,
    BNPurpose_Follow,
    BNPurpose_Protect,
    BNPurpose_Capture,
    BNPurpose_Defend,
    BNPurpose_SeekHealth,
    BNPurpose_SeekAmmo,
    BNPurpose_Investigate,
    BNPurpose_SearchLastKnown,
    BNPurpose_EscapeSentry,
    BNPurpose_CrossSightline
};

enum BNRouteStatus
{
    BNRoute_None = 0,
    BNRoute_Pending,
    BNRoute_Active,
    BNRoute_Complete,
    BNRoute_Failed,
    BNRoute_Cancelled
};

enum BNAreaLabel
{
    BNArea_None             = 0,
    BNArea_Open             = (1 << 0),
    BNArea_Enclosed         = (1 << 1),
    BNArea_Narrow           = (1 << 2),
    BNArea_Wide             = (1 << 3),
    BNArea_Corridor         = (1 << 4),
    BNArea_Choke            = (1 << 5),
    BNArea_Intersection     = (1 << 6),
    BNArea_DeadEnd          = (1 << 7),
    BNArea_HighGround       = (1 << 8),
    BNArea_LowGround        = (1 << 9),
    BNArea_OneWayDrop       = (1 << 10),
    BNArea_Cover            = (1 << 11),
    BNArea_Peek             = (1 << 12),
    BNArea_ExposedCrossing  = (1 << 13),
    BNArea_LongSightline    = (1 << 14),
    BNArea_Defensive        = (1 << 15),
    BNArea_Ambush           = (1 << 16),
    BNArea_ObjectiveApproach= (1 << 17),
    BNArea_MainRoute        = (1 << 18),
    BNArea_FlankConnection  = (1 << 19),
    BNArea_SpawnApproach    = (1 << 20)
};

native bool BN_IsAvailable();
native int BN_GetAreaFromPosition(const float position[3]);
native int BN_GetCurrentAreaForClient(int client);
native bool BN_GetAreaCenter(int areaId, float center[3]);
native bool BN_GetAreaBounds(int areaId, float minimum[3], float maximum[3]);
native int BN_GetAreaLabels(int areaId);
native float BN_GetAreaDanger(int observer, int areaId);
native float BN_GetAreaControl(int team, int areaId);
native float BN_GetAreaTraffic(int team, int areaId);

native bool BN_RequestRoute(
    int client,
    const float goal[3],
    BNRouteProfile profile,
    BNMovementPurpose purpose,
    int priority = 25,
    float minimumDuration = 0.50,
    float lifetime = 8.0,
    bool interruptible = true
);

native void BN_CancelRoute(int client);
native BNRouteStatus BN_GetRouteStatus(int client);
native bool BN_GetNextTraversalPoint(int client, float point[3]);
native bool BN_GetRouteMetrics(
    int client,
    float &distance,
    float &danger,
    float &tacticalCost,
    float &confidence
);
native bool BN_GetSafestNearbyArea(int observer, float radius, float destination[3]);
native bool BN_GetRetreatDestination(int observer, float destination[3]);
native bool BN_GetBestFlankApproach(int observer, const float goal[3], float destination[3]);
