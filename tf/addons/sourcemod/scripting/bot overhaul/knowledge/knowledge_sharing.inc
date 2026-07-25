#if defined _knowledge_sharing_inc
 #endinput
#endif
#define _knowledge_sharing_inc

void ShareObservation(int reporter, int subject, float now)
{
    if (!g_CvarTeamSharing.BoolValue) return;

    int team = g_WorldTeam[reporter];
    int teammates = g_AliveTeamMask[team];
    for (int recipient = 1; recipient <= MaxClients; recipient++)
    {
        if (recipient == reporter || !MaskHasClient(teammates, recipient) || !g_WorldIsBot[recipient]) continue;

        float distance = GetVectorDistance(g_WorldPosition[reporter], g_WorldPosition[recipient]);
        if (distance > 1350.0) continue;

        float reportConfidence = distance <= 750.0 ? 0.78 : 0.66;
        if (g_KnownPlayer[recipient][subject] && g_KnownConfidence[recipient][subject] >= reportConfidence) continue;

        if (!g_KnownPlayer[recipient][subject]) g_KnownFirstAt[recipient][subject] = now;
        g_KnownPlayer[recipient][subject] = true;
        CopyVector(g_WorldPosition[subject], g_KnownPosition[recipient][subject]);
        CopyVector(g_WorldVelocity[subject], g_KnownVelocity[recipient][subject]);
        g_KnownConfidence[recipient][subject] = reportConfidence;
        g_KnownUncertainty[recipient][subject] = 110.0;
        g_KnownConfirmedAt[recipient][subject] = now;
        g_KnownUpdatedAt[recipient][subject] = now;
        g_KnownExpiresAt[recipient][subject] = now + g_CvarMemoryDuration.FloatValue * 0.75;
        g_KnownSource[recipient][subject] = distance <= 750.0 ? BKSource_NearbyAllyObservation : BKSource_TeamReport;
        g_KnownScope[recipient][subject] = distance <= 750.0 ? BKScope_SquadShared : BKScope_TeamShared;
        g_KnownLabels[recipient][subject] = g_WorldLabels[subject];
    }
}

void AddAudibleKnowledge(int sourceClient, float confidence, float uncertainty, float now)
{
    if (!g_WorldConnected[sourceClient] || !g_WorldAlive[sourceClient]) return;

    int sourceTeam = g_WorldTeam[sourceClient];
    float hearingDistance = g_CvarHearingDistance.FloatValue;
    for (int observer = 1; observer <= MaxClients; observer++)
    {
        if (!g_WorldIsBot[observer] || !g_WorldAlive[observer] || g_WorldTeam[observer] == sourceTeam) continue;

        float distance = GetVectorDistance(g_WorldPosition[observer], g_WorldPosition[sourceClient]);
        if (distance > hearingDistance) continue;

        float finalConfidence = confidence * (1.0 - (distance / hearingDistance) * 0.35);
        if (g_KnownPlayer[observer][sourceClient] && g_KnownConfidence[observer][sourceClient] >= finalConfidence) continue;

        if (!g_KnownPlayer[observer][sourceClient]) g_KnownFirstAt[observer][sourceClient] = now;
        g_KnownPlayer[observer][sourceClient] = true;
        CopyVector(g_WorldPosition[sourceClient], g_KnownPosition[observer][sourceClient]);
        CopyVector(g_WorldVelocity[sourceClient], g_KnownVelocity[observer][sourceClient]);
        g_KnownConfidence[observer][sourceClient] = finalConfidence;
        g_KnownUncertainty[observer][sourceClient] = uncertainty + distance * 0.08;
        g_KnownConfirmedAt[observer][sourceClient] = now;
        g_KnownUpdatedAt[observer][sourceClient] = now;
        g_KnownExpiresAt[observer][sourceClient] = now + g_CvarMemoryDuration.FloatValue * 0.65;
        g_KnownSource[observer][sourceClient] = BKSource_DirectHearing;
        g_KnownScope[observer][sourceClient] = BKScope_BotLocal;
        g_KnownLabels[observer][sourceClient] = g_WorldLabels[sourceClient] & ~(BKLabel_Cloaked | BKLabel_Disguised);
    }
}
