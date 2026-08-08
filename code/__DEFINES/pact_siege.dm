/// InteQ vs PACT formal siege mode (code-only; map hooks later)
#define TRAIT_PACT_SIEGE_ATTACKER "pact_siege_attacker"
#define TRAIT_PACT_SIEGE_DEFENDER "pact_siege_defender"

#define PACT_SIEGE_SIDE_PACT "pact"
#define PACT_SIEGE_SIDE_INTEQ "inteq"

/// Main defense timer (30 min) after activation
#define PACT_SIEGE_TIMER (30 MINUTES)
/// Score / progression granted to each winning participant (metacurrency-style progression via achievements DB)
#define PACT_SIEGE_REWARD_PACT_WIN 150
#define PACT_SIEGE_REWARD_INTEQ_WIN 200

/// Types of /area considered the InteQ battlefield for gateways & recalls (extend when the outpost moves to CC)
GLOBAL_LIST_INIT(pact_siege_battle_area_types, list(\
	/area/InteQ_ship/shipPACT,\
	/area/InteQ_ship/SOLVED,\
	/area/InteQ_ship/ship6,\
	/area/InteQ_ship/ship5,\
	/area/InteQ_ship/ship4,\
	/area/InteQ_ship/ship3,\
	/area/InteQ_ship/ship2,\
	/area/InteQ_ship/ship1,\
	/area/InteQ_ship,\
))
