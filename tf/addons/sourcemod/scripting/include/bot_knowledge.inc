#if defined _bot_knowledge_included
 #endinput
#endif
#define _bot_knowledge_included

/**
 * Shared Battlefield Knowledge API.
 *
 * Normal consumers receive observer-scoped knowledge. Authoritative world truth
 * remains private to the bot_knowledge plugin unless unfair access is explicitly enabled.
 */

enum BKKnowledgeSource
{
    BKSource_None = 0,
    BKSource_DirectVision,
    BKSource_PeripheralVision,
    BKSource_DirectHearing,
    BKSource_DamageReceived,
    BKSource_ObjectiveEvent,
    BKSource_TeamReport,
    BKSource_NearbyAllyObservation,
    BKSource_Memory,
    BKSource_MovementInference,
    BKSource_GroupInference,
    BKSource_MapKnowledge,
    BKSource_ScriptedKnowledge,
    BKSource_OmnipresentKnowledge
};

enum BKKnowledgeScope
{
    BKScope_WorldOnly = 0,
    BKScope_BotLocal,
    BKScope_SquadShared,
    BKScope_TeamShared,
    BKScope_DirectorShared,
    BKScope_GlobalScripted
};

enum BKMovementState
{
    BKMove_Unknown = 0,
    BKMove_Stationary,
    BKMove_Advancing,
    BKMove_Retreating,
    BKMove_Flanking,
    BKMove_Chasing,
    BKMove_Escaping,
    BKMove_Holding
};

enum BKCombatState
{
    BKCombat_None = 0,
    BKCombat_Entering,
    BKCombat_Active,
    BKCombat_UnderFire,
    BKCombat_Winning,
    BKCombat_Losing,
    BKCombat_Outnumbered
};

enum BKTeamState
{
    BKTeam_Unknown = 0,
    BKTeam_Grouped,
    BKTeam_Split,
    BKTeam_Scattered,
    BKTeam_Regrouping,
    BKTeam_Pushing,
    BKTeam_Holding,
    BKTeam_Retreating,
    BKTeam_Collapsing
};

enum BKEntityKind
{
    BKEntity_None = 0,
    BKEntity_Player,
    BKEntity_Sentry,
    BKEntity_Dispenser,
    BKEntity_Teleporter,
    BKEntity_Objective,
    BKEntity_Projectile,
    BKEntity_Hazard,
    BKEntity_Resource
};

enum BKTacticalLabel
{
    BKLabel_None               = 0,
    BKLabel_Alive              = (1 << 0),
    BKLabel_Dead               = (1 << 1),
    BKLabel_Burning            = (1 << 2),
    BKLabel_Bleeding           = (1 << 3),
    BKLabel_Jarated            = (1 << 4),
    BKLabel_Milked             = (1 << 5),
    BKLabel_Cloaked            = (1 << 6),
    BKLabel_Disguised          = (1 << 7),
    BKLabel_Invulnerable       = (1 << 8),
    BKLabel_Overhealed         = (1 << 9),
    BKLabel_CriticalHealth     = (1 << 10),
    BKLabel_LowHealth          = (1 << 11),
    BKLabel_Healthy            = (1 << 12),
    BKLabel_Airborne           = (1 << 13),
    BKLabel_Scoped             = (1 << 14),
    BKLabel_SpunUp             = (1 << 15),
    BKLabel_UnderFire          = (1 << 16),
    BKLabel_InCombat           = (1 << 17),
    BKLabel_Advancing          = (1 << 18),
    BKLabel_Retreating         = (1 << 19),
    BKLabel_Holding            = (1 << 20),
    BKLabel_Isolated           = (1 << 21),
    BKLabel_HighValueTarget    = (1 << 22),
    BKLabel_SentryThreat       = (1 << 23),
    BKLabel_ObjectiveThreat    = (1 << 24),
    BKLabel_Grouped            = (1 << 25),
    BKLabel_Overextended       = (1 << 26),
    BKLabel_Protected          = (1 << 27),
    BKLabel_Exposed            = (1 << 28)
};

native bool BK_IsEnabled();

native int BK_GetKnownEnemies(
    int observer,
    int[] clients,
    int maxClients,
    float minimumConfidence = 0.20
);

native int BK_GetBurningTeammates(
    int observer,
    int[] clients,
    int maxClients,
    float maximumDistance = 900.0,
    float minimumConfidence = 0.35
);

native bool BK_GetLastKnownPosition(
    int observer,
    int subject,
    float position[3],
    float &confidence,
    float &uncertainty
);

native bool BK_GetLargestEnemyCluster(
    int observer,
    float centroid[3],
    int &memberCount,
    float &cohesion,
    float &confidence
);

native BKTeamState BK_GetTeamState(int team);

native bool BK_GetFrontLine(
    int team,
    float position[3],
    float &confidence
);

native float BK_GetThreatAtPosition(
    int observer,
    const float position[3]
);

native bool BK_FindBestMadMilkTarget(
    int observer,
    float target[3],
    int &enemyCount,
    int &burningAllies,
    float &utility
);
