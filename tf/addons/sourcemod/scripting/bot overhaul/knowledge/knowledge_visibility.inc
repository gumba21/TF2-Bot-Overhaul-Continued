#if defined _knowledge_visibility_inc
 #endinput
#endif
#define _knowledge_visibility_inc

bool CanObserverSeePlayer(int observer, int subject)
{
    if (!g_WorldAlive[observer] || !g_WorldAlive[subject]) return false;

    float eye[3];
    float target[3];
    GetClientEyePosition(observer, eye);
    GetClientEyePosition(subject, target);
    if (GetVectorDistance(eye, target) > g_CvarVisionDistance.FloatValue) return false;
    if (!IsWithinObserverFov(observer, eye, target)) return false;

    Handle trace = TR_TraceRayFilterEx(eye, target, MASK_SHOT | CONTENTS_HITBOX, RayType_EndPoint, TraceFilter_IgnoreObserver, observer);
    bool visible = !TR_DidHit(trace) || TR_GetEntityIndex(trace) == subject;
    delete trace;
    return visible;
}

bool IsWithinObserverFov(int observer, const float eye[3], const float target[3])
{
    float fov = g_CvarVisionFov.FloatValue;
    if (fov >= 359.0) return true;

    float angles[3];
    float forward[3];
    float direction[3];
    GetClientEyeAngles(observer, angles);
    GetAngleVectors(angles, forward, NULL_VECTOR, NULL_VECTOR);
    MakeVectorFromPoints(eye, target, direction);
    NormalizeVector(direction, direction);
    return GetVectorDotProduct(forward, direction) >= Cosine(DegToRad(fov * 0.5));
}

public bool TraceFilter_IgnoreObserver(int entity, int contentsMask, any data)
{
    return entity != data;
}
