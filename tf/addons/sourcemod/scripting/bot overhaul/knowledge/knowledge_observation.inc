#if defined _knowledge_observation_inc
 #endinput
#endif
#define _knowledge_observation_inc

void UpdateObserverKnowledge(int observer, float now)
{
    int observerTeam = g_WorldTeam[observer];
    if (observerTeam < 2) return;

    bool unfair = g_CvarUnfairAccess.BoolValue;
    int enemyTeam = observerTeam == 2 ? 3 : 2;
    int candidates = g_AliveTeamMask[enemyTeam];

    for (int subject = 1; subject <= MaxClients; subject++)
    {
        if (!MaskHasClient(candidates, subject))
        {
            DecayPlayerKnowledge(observer, subject, now);
            continue;
        }

        bool visible = unfair || CanObserverSeePlayer(observer, subject);
        if (visible)
        {
            ConfirmPlayerKnowledge(
                observer,
                subject,
                unfair ? BKSource_OmnipresentKnowledge : BKSource_DirectVision,
                unfair ? BKScope_GlobalScripted : BKScope_BotLocal,
                1.0,
                0.0,
                now
            );
            if (!unfair) ShareObservation(observer, subject, now);
        }
        else
        {
            g_PlayerVisible[observer][subject] = false;
            DecayPlayerKnowledge(observer, subject, now);
        }
    }
}

void ConfirmPlayerKnowledge(
    int observer,
    int subject,
    BKKnowledgeSource source,
    BKKnowledgeScope scope,
    float confidence,
    float uncertainty,
    float now
)
{
    if (!g_KnownPlayer[observer][subject]) g_KnownFirstAt[observer][subject] = now;

    g_KnownPlayer[observer][subject] = true;
    g_PlayerVisible[observer][subject] = source == BKSource_DirectVision || source == BKSource_OmnipresentKnowledge;
    CopyVector(g_WorldPosition[subject], g_KnownPosition[observer][subject]);
    CopyVector(g_WorldVelocity[subject], g_KnownVelocity[observer][subject]);
    g_KnownConfidence[observer][subject] = confidence;
    g_KnownUncertainty[observer][subject] = uncertainty;
    g_KnownConfirmedAt[observer][subject] = now;
    g_KnownUpdatedAt[observer][subject] = now;
    g_KnownExpiresAt[observer][subject] = now + g_CvarMemoryDuration.FloatValue;
    g_KnownSource[observer][subject] = source;
    g_KnownScope[observer][subject] = scope;
    g_KnownLabels[observer][subject] = g_WorldLabels[subject];
}

void DecayPlayerKnowledge(int observer, int subject, float now)
{
    if (!g_KnownPlayer[observer][subject]) return;
    if (!g_WorldConnected[subject])
    {
        ClearPlayerKnowledge(observer, subject);
        return;
    }

    float age = now - g_KnownConfirmedAt[observer][subject];
    float confidence = 1.0 - age * g_CvarConfidenceDecay.FloatValue;
    if (g_KnownSource[observer][subject] == BKSource_TeamReport) confidence *= 0.82;
    else if (g_KnownSource[observer][subject] == BKSource_DirectHearing) confidence *= 0.72;

    if (now >= g_KnownExpiresAt[observer][subject]
        || age >= g_CvarMemoryDuration.FloatValue
        || confidence <= 0.05)
    {
        ClearPlayerKnowledge(observer, subject);
        return;
    }

    g_KnownConfidence[observer][subject] = ClampFloat(confidence, 0.0, 1.0);
    float estimatedSpeed = GetVectorLength(g_KnownVelocity[observer][subject]);
    g_KnownUncertainty[observer][subject] = 64.0 + age * FloatMax(estimatedSpeed, 120.0);
    g_KnownUpdatedAt[observer][subject] = now;
    g_KnownSource[observer][subject] = BKSource_Memory;
    g_KnownScope[observer][subject] = BKScope_BotLocal;
}
