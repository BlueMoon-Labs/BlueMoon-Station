#define TRAITOR_HUMAN /datum/traitor_class/human/freeform
#define TRAITOR_AI /datum/traitor_class/ai

#define NUKE_RESULT_FLUKE 0
#define NUKE_RESULT_NUKE_WIN 1
#define NUKE_RESULT_CREW_WIN 2
#define NUKE_RESULT_CREW_WIN_SYNDIES_DEAD 3
#define NUKE_RESULT_DISK_LOST 4
#define NUKE_RESULT_DISK_STOLEN 5
#define NUKE_RESULT_NOSURVIVORS 6
#define NUKE_RESULT_WRONG_STATION 7
#define NUKE_RESULT_WRONG_STATION_DEAD 8

//fugitive end results
#define FUGITIVE_RESULT_BADASS_HUNTER 0
#define FUGITIVE_RESULT_POSTMORTEM_HUNTER 1
#define FUGITIVE_RESULT_MAJOR_HUNTER 2
#define FUGITIVE_RESULT_HUNTER_VICTORY 3
#define FUGITIVE_RESULT_MINOR_HUNTER 4
#define FUGITIVE_RESULT_STALEMATE 5
#define FUGITIVE_RESULT_MINOR_FUGITIVE 6
#define FUGITIVE_RESULT_FUGITIVE_VICTORY 7
#define FUGITIVE_RESULT_MAJOR_FUGITIVE 8

#define APPRENTICE_DESTRUCTION "destruction"
#define APPRENTICE_BLUESPACE "bluespace"
#define APPRENTICE_ROBELESS "robeless"
#define APPRENTICE_HEALING "healing"
#define APPRENTICE_MARTIAL "martial"


//ERT Types
#define ERT_BLUE "Blue"
#define ERT_RED  "Red"
#define ERT_AMBER "Amber"
#define ERT_DEATHSQUAD "Deathsquad"

//ERT subroles
#define ERT_SEC "sec"
#define ERT_MED "med"
#define ERT_ENG "eng"
#define ERT_LEADER "leader"
#define DEATHSQUAD "ds"
#define DEATHSQUAD_LEADER "ds_leader"

//Shuttle hijacking
#define HIJACK_NEUTRAL 0 //Does not stop hijacking but itself won't hijack
#define HIJACK_HIJACKER 1 //Needs to be present for shuttle to be hijacked
#define HIJACK_PREVENT 2 //Prevents hijacking same way as non-antags

//Syndicate Contracts
#define CONTRACT_STATUS_INACTIVE 1
#define CONTRACT_STATUS_ACTIVE 2
#define CONTRACT_STATUS_BOUNTY_CONSOLE_ACTIVE 3
#define CONTRACT_STATUS_EXTRACTING 4
#define CONTRACT_STATUS_COMPLETE 5
#define CONTRACT_STATUS_ABORTED 6

#define CONTRACT_PAYOUT_LARGE 1
#define CONTRACT_PAYOUT_MEDIUM 2
#define CONTRACT_PAYOUT_SMALL 3

#define CONTRACT_UPLINK_PAGE_CONTRACTS "CONTRACTS"
#define CONTRACT_UPLINK_PAGE_HUB "HUB"

//Lingblood stuff
#define LINGBLOOD_DETECTION_THRESHOLD 1
#define LINGBLOOD_EXPLOSION_MULT 2
#define LINGBLOOD_EXPLOSION_THRESHOLD (LINGBLOOD_DETECTION_THRESHOLD * LINGBLOOD_EXPLOSION_MULT) //Hey, important to note here: the explosion threshold is explicitly more than, rather than more than or equal to. This stops a single loud ability from triggering the explosion threshold.

///Heretics --
GLOBAL_LIST_EMPTY(living_heart_cache)	//A list of all living hearts in existance, for us to iterate through.

#define IS_INTEQ(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/traitor) || mob.mind?.has_antag_datum(/datum/antagonist/raiders) || mob.mind?.has_antag_datum(/datum/antagonist/nukeop) || (ROLE_INTEQ in mob.faction))

/// Checks if the given mob is a changeling
#define IS_CHANGELING(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/changeling))

#define IS_HERETIC(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/heretic))
#define IS_HERETIC_MONSTER(mob) (mob.mind?.has_antag_datum(/datum/antagonist/heretic_monster))

/// Checks if the given mob is a malf ai.
#define IS_MALF_AI(mob) (isAI(mob) && mob?.mind?.has_antag_datum(/datum/antagonist/traitor))

#define PATH_SIDE "Side"

#define PATH_ASH "Ash"
#define PATH_RUST "Rust"
#define PATH_FLESH "Flesh"
#define PATH_VOID "Void"
#define PATH_BLADE "Blade"
#define PATH_MOON "Moon"
#define PATH_COSMIC "Cosmic"
#define PATH_LOCK "Lock"
#define PATH_TIDE "Tide"
#define PATH_GLASS "Glass"
#define PATH_BLOOD "Blood"
#define PATH_ECHO "Echo"
#define PATH_SAND "Sand"
#define PATH_WAX "Wax"
#define PATH_SPIRIT "Spirit"

#define HERETIC_ASCENSION_SACRIFICES 3
#define HERETIC_ASCENSION_BODIES 3
#define HERETIC_ASCENDED_DAMAGE_MOD 0.6
#define HERETIC_ASCENDED_MAX_HEALTH 150
#define HERETIC_ASCENDED_STAMINA_MOD 0.3
#define HERETIC_ASCENDED_STUN_MOD 0.25
#define HERETIC_ASCENDED_REGEN 2
#define HERETIC_ASCENDED_REGEN_DELAY (5 SECONDS)
#define HERETIC_VFX_MAX_PARTICLES 30
#define HERETIC_VFX_MAX_SPAWNING 10
#define HERETIC_VFX_BURST_TIME (0.3 SECONDS)
#define HERETIC_VFX_PULSE_FILTER "heretic_vfx_pulse"
#define HERETIC_VFX_RAYS_FILTER "heretic_vfx_rays"
#define HERETIC_VFX_ATTACH_FADE (0.3 SECONDS)
#define HERETIC_BLADE_ORBIT_MAX 4
#define HERETIC_BLADE_ORBIT_REGEN (6 SECONDS)
#define HERETIC_BLADE_LIFESTEAL 0.25
#define HERETIC_BLADE_STORM_TARGETS 4
#define HERETIC_BLADE_STORM_RANGE 7
#define HERETIC_BLADE_STORM_BRUTE 20
#define HERETIC_BLADE_STORM_STAMINA 20
#define HERETIC_BLADE_STORM_COOLDOWN (30 SECONDS)
#define HERETIC_BLADE_STREAK_GHOSTS 4
#define HERETIC_ASH_TRAIL_DURATION (4 SECONDS)
#define HERETIC_ASH_LORD_HEAL 3
#define HERETIC_ASH_WET_DURATION (7 SECONDS)
#define HERETIC_ASH_CASCADE_RANGE 10
#define HERETIC_ASH_FIRE_SWORN_COOLDOWN (2 MINUTES)
#define HERETIC_ASH_RING_MOTES 6
#define HERETIC_VOID_DEFLECT_CHANCE 30
#define HERETIC_VOID_HEAT_MARGIN 20
#define HERETIC_MOON_ASCENDED_INTERCEPT_RANGE 2
#define HERETIC_MOON_LUNATIC_DURATION (12 SECONDS)
#define HERETIC_MOON_LUNATIC_SPREAD 30
#define HERETIC_MOON_FLASH_RANGE 3
/// В тиках жизни (около 2 секунд).
#define HERETIC_MOON_FLASH_BLIND 1
#define HERETIC_MOON_FLASH_BLUR 4
#define HERETIC_MOON_LUNATIC_HALO "heretic_lunatic_halo"
#define HERETIC_GLASS_REFRACT_CHANCE 35
#define HERETIC_GLASS_MELEE_FRAGILITY 0.25
#define HERETIC_ECHO_REPRISE_RADIUS 3
#define HERETIC_ECHO_REPRISE_DAMAGE 15
#define HERETIC_ECHO_REPRISE_STAMINA 15
#define HERETIC_ECHO_REPRISE_MIN_DAMAGE 5
#define HERETIC_ECHO_REPRISE_COOLDOWN (2 SECONDS)
#define HERETIC_SAND_SLOW_RADIUS 4
#define HERETIC_SAND_FIELD_REACH (HERETIC_SAND_SLOW_RADIUS + 0.5)
#define HERETIC_SAND_SLOW_FACTOR 3
#define HERETIC_LOCK_KEEPER_RANGE 15
#define HERETIC_LOCK_KEEPER_CHANNEL (1 SECONDS)
#define HERETIC_LOCK_KEEPER_COOLDOWN (10 SECONDS)
#define HERETIC_LOCK_KEEPER_BOLT_TIME (8 SECONDS)
#define HERETIC_LOCK_KEEPER_MIN_DISTANCE 2
#define HERETIC_SPIRIT_FERRY_RANGE 7
#define HERETIC_SPIRIT_FERRY_OBOLS 2
#define HERETIC_SPIRIT_FERRY_HEAL 20
#define HERETIC_VOID_BLINK_COOLDOWN (8 SECONDS)
#define HERETIC_VOID_DOMAIN_BLINK_COOLDOWN (2 SECONDS)
#define HERETIC_TIDE_FLOOD_RADIUS 2
#define HERETIC_TIDE_FLOOD_INTERVAL (2 SECONDS)
#define HERETIC_TIDE_FLOOD_LIFETIME (4 SECONDS)
#define HERETIC_TIDE_FLOOD_HASTE 0.2
#define HERETIC_BLOOD_TIDE_RADIUS 3
#define HERETIC_BLOOD_TIDE_POOL_HEAL 3
#define HERETIC_BLOOD_TIDE_POOL_COOLDOWN (1 SECONDS)
#define HERETIC_RUST_HEART_INTEGRITY 300
#define HERETIC_RUST_ASCENDED_STAMINA_MOD 0.5
#define HERETIC_RUST_WAVE_RANGE 5
#define HERETIC_RUST_WAVE_CORROSION 20
#define HERETIC_RUST_WAVE_COOLDOWN (40 SECONDS)
#define HERETIC_WAX_PHYLACTERY_ANCHORS 3
#define HERETIC_WAX_PHYLACTERY_COOLDOWN (5 MINUTES)
#define HERETIC_WAX_PHYLACTERY_HEALTH 0.5
#define HERETIC_WAX_PHYLACTERY_DOLL_TIME (10 SECONDS)
#define HERETIC_STARGAZER_HEALTH 400
#define HERETIC_STARGAZER_RANGE 7
#define HERETIC_STARGAZER_BEAM_DAMAGE 20
#define HERETIC_STARGAZER_BEAM_COOLDOWN (3 SECONDS)
#define HERETIC_STARGAZER_COOLDOWN (3 MINUTES)
#define HERETIC_COSMIC_WAKE_INTERVAL (4 SECONDS)
#define HERETIC_COSMIC_WAKE_STEP_GAP (1 SECONDS)
#define HERETIC_FLESH_WORM_FEED_TIME (3 SECONDS)
#define HERETIC_FLESH_WORM_FEED_HEAL 100
#define HERETIC_FLESH_WORM_MAX_LENGTH 16
#define HERETIC_FLESH_WORM_DEATH_COOLDOWN (2 MINUTES)
#define HERETIC_FLESH_WORM_REVIVE_HEALTH_RATIO 0.5
#define HERETIC_LIVE_SACRIFICE_KNOWLEDGE 2
#define HERETIC_LIVE_SACRIFICE_SIDE_KNOWLEDGE 1
#define HERETIC_DEAD_SACRIFICE_KNOWLEDGE 1
#define HERETIC_THREAT_SACRIFICES 2
#define HERETIC_THREAT_WARNING_TIME (3 MINUTES)
#define HERETIC_HUNT_REFRESH_COOLDOWN (3 MINUTES)
#define HERETIC_HUNT_DOWNED_ALERT_RANGE 9
#define HERETIC_HUNT_DOWNED_ALERT_COOLDOWN (20 SECONDS)
#define HERETIC_HUNT_CLAIM_HINT_COOLDOWN (45 SECONDS)
/// Сколько живого экипажа приходится на одного еретика, прежде чем динамик добавит следующего.
#define HERETIC_CREW_PER_HERETIC 20
/// Во сколько раз спрайт руны 96x96 больше тайла; картовая руна ужимается на этот множитель.
#define HERETIC_RUNE_SCALE 3
#define HERETIC_RUNE_VISUAL_TRACE "rune_write"
#define HERETIC_RUNE_VISUAL_RITUAL "rune_ritual"
#define HERETIC_RUNE_VISUAL_ERASE "rune_erase"
#define HERETIC_RUNE_VISUAL_SCATTER "rune_scatter"
#define HERETIC_RUNE_VISUAL_RELEASE "rune_release"
/// Через сколько после начала начертания на смоле проступает знак пути.
#define HERETIC_RUNE_INSCRIBE_DELAY (5.5 SECONDS)
#define HERETIC_RUNE_ERASE_TIME (2 SECONDS)
#define HERETIC_RUNE_RELEASE_TIME (1.6 SECONDS)
#define HERETIC_RUNE_SCATTER_TIME (1.4 SECONDS)
#define HERETIC_RUNE_CAST_TIME (1.8 SECONDS)
#define HERETIC_INFLUENCE_LIMIT 6
#define HERETIC_INFLUENCE_INITIAL_COUNT 3
#define HERETIC_INFLUENCE_INTERVAL (8 MINUTES)
#define HERETIC_VEIL_CRYSTAL_POINTS 2500
#define HERETIC_STARTING_KNOWLEDGE 3
#define HERETIC_STARTING_SIDE_KNOWLEDGE 2
/// Сколько держится открытым список выбора обряда на руне.
#define HERETIC_RITUAL_CHOICE_TIMEOUT (1 MINUTES)
#define HERETIC_DEED_TIERS 3
#define HERETIC_DEED_KNOWLEDGE 1
#define HERETIC_DEED_SIDE_KNOWLEDGE 1
#define HERETIC_DEED_SIDE_TIER 2
#define HERETIC_PENULTIMATE_SACRIFICES 2
#define HERETIC_SERVANT_POLL_DURATION (10 SECONDS)

//Overthrow time to update heads obj
#define OBJECTIVE_UPDATING_TIME 300

//Gangshit
#define NOT_DOMINATING			-1
#define MAX_LEADERS_GANG		4
#define INITIAL_DOM_ATTEMPTS	3

//Bloodsucker defines
// Bloodsucker related antag datums
#define ANTAG_DATUM_BLOODSUCKER			/datum/antagonist/bloodsucker
#define ANTAG_DATUM_VASSAL				/datum/antagonist/vassal
//#define ANTAG_DATUM_HUNTER				/datum/antagonist/vamphunter   Disabled for now

// BLOODSUCKER
#define BLOODSUCKER_LEVEL_TO_EMBRACE	3
#define BLOODSUCKER_FRENZY_TIME	25		// How long the vamp stays in frenzy.
#define BLOODSUCKER_FRENZY_OUT_TIME	300	// How long the vamp goes back into frenzy.
#define BLOODSUCKER_STARVE_VOLUME	5	// Amount of blood, below which a Vamp is at risk of frenzy.

#define CAT_STRUCTURE	"Structures"

#define MARTIALART_HUNTER "hunter-fu"

//Blob
#define BLOB_REROLL_TIME 2400 // blob gets a free reroll every X time
#define BLOB_SPREAD_COST 4
#define BLOB_ATTACK_REFUND 2 //blob refunds this much if it attacks and doesn't spread
#define BLOB_REFLECTOR_COST 15

/// How many telecrystals a normal traitor starts with
#define TELECRYSTALS_DEFAULT 30
/// How many telecrystals mapper/admin only "precharged" uplink implant
#define TELECRYSTALS_PRELOADED_IMPLANT 10
/// The normal cost of an uplink implant; used for calcuating how many
/// TC to charge someone if they get a free implant through choice or
/// because they have nothing else that supports an implant.
#define UPLINK_IMPLANT_TELECRYSTAL_COST 4

/// The dimensions of the antagonist preview icon. Will be scaled to this size.
#define ANTAGONIST_PREVIEW_ICON_SIZE 96

//Objectives-Ambitions Panel
#define REQUEST_NEW_OBJECTIVE "new_objective"
#define REQUEST_DEL_OBJECTIVE "del_objective"
#define REQUEST_WIN_OBJECTIVE "win_objective"
#define REQUEST_LOSE_OBJECTIVE "lose_objective"

#define ANTAG_GROUP_ABOMINATIONS "Extradimensional Abominations"

// Slavers
#define SLAVER_RANSOM_STANDARD 5000 // credits
#define SLAVER_RANSOM_VALUABLE SLAVER_RANSOM_STANDARD*4
#define SLAVER_RANSOM_HEAD SLAVER_RANSOM_STANDARD*5
#define SLAVER_RANSOM_HEAD_VALUABLE SLAVER_RANSOM_STANDARD*20

#define SLAVER_RANSOM_STANDARD_PERCENT 0.05 // 5%

#define SLAVER_RANSOM_MULTIPLIER 2
