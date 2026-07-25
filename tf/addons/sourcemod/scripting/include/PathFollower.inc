#if defined _pathfollower_included
 #endinput
#endif
#define _pathfollower_included

/** Compatibility declarations for the optional PathFollower extension. */
#define PFCB_Approach 0

native bool PF_Exists(int client);
native void PF_Create(
    int client,
    float hullWidth,
    float hullHeight,
    float maxPathLength,
    float stepHeight,
    int traceMask,
    float goalTolerance,
    float repathInterval,
    float stuckTimeout
);
native void PF_SetGoalVector(int client, const float goal[3]);
native void PF_StartPathing(int client);
native void PF_EnableCallback(int client, int callbackType, Function callback);
