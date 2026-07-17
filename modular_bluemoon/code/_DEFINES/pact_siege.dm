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
	/area/ruin/space/has_grav/bluemoon/inteq,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_ship,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_outpost,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_cargopod,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_vault,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_bar,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_bridge,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_medbay,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_atmos,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_rnd,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_permabrig,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_inspection,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_outpost_shower,\
	/area/ruin/space/has_grav/bluemoon/inteq_forgotten_permabrig_shower,\
))
