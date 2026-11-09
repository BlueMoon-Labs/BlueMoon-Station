#define ROLE_SWARMER "swarmer"
#define TRAIT_HEALS_FROM_SWARMER_CORES "swarmer_core_healing"
#define COMSIG_SWARMER_CORE_DAMAGED "swarmer_core_damaged"
#define is_basicswarmer(target) istype(target, /mob/living/simple_animal/hostile/swarmer/basic)
#define is_roverswarmer(target) istype(target, /mob/living/simple_animal/hostile/swarmer/rover)
#define is_builderswarmer(target) istype(target, /mob/living/simple_animal/hostile/swarmer/builder)
#define is_swarmerprojectile(target) istype(target, /obj/item/projectile/beam/disabler/swarmer)
#define is_swarmer_object(target) (istype(target, /obj/structure/swarmer) || istype(target, /obj/machinery/porta_turret/swarmer))
#define SWARMER_STAMINA_SCALE (STAMINA_CRIT / 100)

GLOBAL_LIST_INIT(common_swarmer_actions, list(
	/datum/action/cooldown/swarmer/core_location,
))

GLOBAL_LIST_INIT(swarmer_actions_by_type, list(
	/mob/living/simple_animal/hostile/swarmer/basic = list(
		/datum/action/innate/swarmer_hide,
		),
	/mob/living/simple_animal/hostile/swarmer/generalist = list(
		/datum/action/cooldown/swarmer/build/barricade,
		/datum/action/cooldown/swarmer/build/trap,
		/datum/action/cooldown/swarmer/build/rapid_turret,
		),
	/mob/living/simple_animal/hostile/swarmer/rover = list(
		/datum/action/innate/swarmer_hide,
		/datum/action/cooldown/swarmer/build/trap,
		/datum/action/cooldown/swarmer/build/transport_hub,
		),
	/mob/living/simple_animal/hostile/swarmer/combat = list(
		/datum/action/innate/swarmer_fire_mode,
		/datum/action/cooldown/swarmer/build/barricade,
		),
	/mob/living/simple_animal/hostile/swarmer/builder = list(
		/datum/action/cooldown/swarmer/build/processer,
		/datum/action/cooldown/swarmer/build/analyzer,
		/datum/action/cooldown/swarmer/build/repair_station,
		/datum/action/cooldown/swarmer/build/storage,
		/datum/action/cooldown/swarmer/build/rapid_turret,
		/datum/action/cooldown/swarmer/build/sniper_turret,
		/datum/action/cooldown/swarmer/build/acp_turret,
		/datum/action/cooldown/swarmer/move_core,
		),
	/mob/living/simple_animal/hostile/swarmer/mega = list(
		),
	))

#define SWARMER_SPAWN_VALUE 60
#define MEGA_SWARMER_SPAWN_VALUE 1500

#define SLOW_SWARMER_DISMANTLE_DELAY 8 SECONDS
#define NORMAL_SWARMER_DISMANTLE_DELAY 5 SECONDS
#define FAST_SWARMER_DISMANTLE_DELAY 2 SECONDS
#define SWARMER_FAST_BUILD_DELAY 2 SECONDS
#define SWARMER_NORMAL_BUILD_DELAY 5 SECONDS
#define SWARMER_SLOW_BUILD_DELAY 10 SECONDS
#define SWARMER_TELEPORT_DELAY(swarmer) (is_roverswarmer(swarmer) ? 4 SECONDS : 8 SECONDS)
#define SWARMER_REPAIR_DELAY(swarmer) (is_builderswarmer(swarmer) ? 2 SECONDS : 5 SECONDS)
#define SWARMER_REPAIR_AMOUNT(swarmer) (is_builderswarmer(swarmer) ? 25 : 15)
#define SWARMER_SEND_ORGANIC_DELAY 2 SECONDS
#define SWARMER_SEND_ANALYZER_DELAY 4 SECONDS

#define SWARMER_REPAIR_COST(swarmer) (is_builderswarmer(swarmer) ? 2 : 4)

#define SWARMER_EMP_DAMAGE(severity) ((severity <= 1) ? 30 : 15)
#define SWARMER_STRUCTURE_EMP_DURATION 10 SECONDS
#define SWARMER_FLASH_ATTACK_STUN 4 SECONDS
#define SWARMER_FLASHBANG_STUN 2 SECONDS

#define SWARMER_ACT_POSSIBLE (1<<0)
#define SWARMER_ACT_IMPOSSIBLE (1<<1)
#define SWARMER_ACT_RIGHT_CLICK_DEFAULT (1<<2)

#define SWARMER_ACT_POSSIBLE_ACTION_DAMAGE (1<<3)
#define SWARMER_ACT_POSSIBLE_ACTION_DISMANTLE (1<<4)
#define SWARMER_ACT_POSSIBLE_ACTION_CONSUME (1<<5)
#define SWARMER_ACT_POSSIBLE_ACTION_DESTROY (1<<6)

#define SWARMER_ACT_IMPOSSIBLE_REASON_ENERGY (1<<3)
#define SWARMER_ACT_IMPOSSIBLE_REASON_LIVING (1<<4)
#define SWARMER_ACT_IMPOSSIBLE_REASON_ATMOS (1<<5)
#define SWARMER_ACT_IMPOSSIBLE_REASON_TEAM (1<<6)
#define SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE (1<<7)
#define SWARMER_ACT_IMPOSSIBLE_REASON_DEFAULT (1<<8)

#define SWARMER_ANALYZE_NONE (1<<0)
#define SWARMER_ANALYZE_BUSY (1<<1)
#define SWARMER_ANALYZE_FOUND (1<<2)

#define SWARMER_PROCESS_NONE (1<<0)
#define SWARMER_PROCESS_BUSY (1<<1)
#define SWARMER_PROCESS_FOUND (1<<2)
