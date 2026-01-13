/*
 * # lewd_prefs_choices
 * Used for determining the possible choices for lewd prefs,
 * downstreams can modify this and i don't know,
 * remove "Ask"? or make a very confusing list of options which will make players hate you for it.
*/
GLOBAL_LIST_INIT(lewd_prefs_choices, list(
	"Yes",
	"Ask",
	"No"
	))

// Moaning Sounds
GLOBAL_LIST_INIT(lewd_moans_male, list(
	'modular_sand/sound/interactions/moan_m1.ogg',
	'modular_sand/sound/interactions/moan_m2.ogg',
	'modular_sand/sound/interactions/moan_m3.ogg'
))

GLOBAL_LIST_INIT(lewd_moans_female, list(
	'modular_sand/sound/interactions/moan_f1.ogg',
	'modular_sand/sound/interactions/moan_f2.ogg',
	'modular_sand/sound/interactions/moan_f3.ogg',
	'modular_sand/sound/interactions/moan_f4.ogg',
	'modular_sand/sound/interactions/moan_f5.ogg',
	'modular_sand/sound/interactions/moan_f6.ogg',
	'modular_sand/sound/interactions/moan_f7.ogg'
))
// BLUEMOON ADD START
GLOBAL_LIST_INIT(lewd_softmoans_female, list(
	'modular_bluemoon/sound/emotes/softmoan1.ogg',
	'modular_bluemoon/sound/emotes/softmoan2.ogg',
	'modular_bluemoon/sound/emotes/softmoan3.ogg',
	'modular_bluemoon/sound/emotes/softmoan4.ogg',
	'modular_bluemoon/sound/emotes/softmoan5.ogg',
	'modular_bluemoon/sound/emotes/softmoan6.ogg'
))
// BLUEMOON ADD END
// Kissing sounds
GLOBAL_LIST_INIT(lewd_kiss_sounds, list(
	'modular_sand/sound/interactions/kiss1.ogg',
	'modular_sand/sound/interactions/kiss2.ogg',
	'modular_sand/sound/interactions/kiss3.ogg',
	'modular_sand/sound/interactions/kiss4.ogg',
	'modular_sand/sound/interactions/kiss5.ogg'
))
GLOBAL_LIST_INIT(interaction_speeds, list(
	4 SECONDS,
	2 SECONDS,
	1 SECONDS,
	0.8 SECONDS,
	0.5 SECONDS, // lowest value must always be over or equal to the subsystem wait/cooldown for interaction
))

#define INTERACTION_NORMAL 0
#define INTERACTION_LEWD 1
#define INTERACTION_EXTREME 2

#define CUM_TARGET_MOUTH "mouth"
#define CUM_TARGET_THROAT "throat"
#define CUM_TARGET_VAGINA "vagina"
#define CUM_TARGET_ANUS "anus"
#define CUM_TARGET_HAND "hand"
#define CUM_TARGET_BREASTS "breasts"
#define CUM_TARGET_FEET "feet"
#define CUM_TARGET_PENIS "penis"
//Weird defines go here
#define CUM_TARGET_EARS "ears"
#define CUM_TARGET_EYES "eyes"
//
// BLUEMOON ADD хвостики!
#define CUM_TARGET_TAIL "tail"
//
#define GRINDING_FACE_WITH_ANUS "faceanus"
#define GRINDING_FACE_WITH_FEET "facefeet"
#define GRINDING_MOUTH_WITH_FEET "mouthfeet"
#define THIGH_SMOTHERING "thigh_smother"
#define NUTS_TO_FACE "nut_face"

#define HIGH_LUST 20
#define NORMAL_LUST 12
#define LOW_LUST 6

/// Exposed states, your friendly non-carbon returns
// TRUE
#define HAS_EXPOSED_GENITAL 2
#define HAS_UNEXPOSED_GENITAL 3

/// Interaction requirements
#define INTERACTION_REQUIRE_BOTTOMLESS (1<<0)
#define INTERACTION_REQUIRE_HANDS (1<<1)
#define INTERACTION_REQUIRE_MOUTH (1<<2)
#define INTERACTION_REQUIRE_TOPLESS (1<<3)

/// Interaction requirements -- Has require states
#define INTERACTION_REQUIRE_ANUS (1<<0)
#define INTERACTION_REQUIRE_BALLS (1<<1)
#define INTERACTION_REQUIRE_BREASTS (1<<2)
// Terrible stuff start here
#define INTERACTION_REQUIRE_EARS (1<<3)
#define INTERACTION_REQUIRE_EARSOCKETS (1<<4)
#define INTERACTION_REQUIRE_EYES (1<<5)
#define INTERACTION_REQUIRE_EYESOCKETS (1<<6)
// End here
#define INTERACTION_REQUIRE_FEET (1<<7)
#define INTERACTION_REQUIRE_PENIS (1<<8)
#define INTERACTION_REQUIRE_VAGINA (1<<9)
// BLUEMOON ADD хвостики!
#define INTERACTION_REQUIRE_TAIL (1<<9)
#define INTERACTION_REQUIRE_KNOT (1<<10) // not replace INTERACTION_REQUIRE_PENIS, use both
#define INTERACTION_REQUIRE_DOUBLE_PENIS (1<<11) // not replace INTERACTION_REQUIRE_PENIS, use both
#define INTERACTION_REQUIRE_TK (1<<12)
// BLUEMOON ADD END

/// Interaction flags
#define INTERACTION_FLAG_ADJACENT (1<<0)
#define INTERACTION_FLAG_EXTREME_CONTENT (1<<1)
#define INTERACTION_FLAG_OOC_CONSENT (1<<2)
#define INTERACTION_FLAG_TARGET_NOT_TIRED (1<<3)
#define INTERACTION_FLAG_USER_IS_TARGET (1<<4)
#define INTERACTION_FLAG_USER_NOT_TIRED (1<<5)
#define INTERACTION_FLAG_UNHOLY_CONTENT (1<<6)
#define INTERACTION_FLAG_REQUIRE_BONDAGE (1<<7) //TODO: move the bondage interactions out of the interaction menu
#define INTERACTION_FLAG_RANGED_CONSENT (1<<8)

/// Copy-paste prevention for additional details
/// Fills containers
#define INTERACTION_FILLS_CONTAINERS list( \
	"info" = "Вы можете наполнить контейнер, если держите его в активной руке или тянете за собой", \
	"icon" = "flask", \
	"color" = "white" \
	)
/// Can drink from
#define INTERACTION_MAY_CONTAIN_DRINK list( \
	"info" = "Может содержать реагенты", \
	"icon" = "cow", \
	"color" = "white" \
)
/// Causes pregnancies
#define INTERACTION_MAY_CAUSE_PREGNANCY list( \
	"info" = "Может вызвать беременность", \
	"icon" = "person-pregnant", \
	"color" = "white" \
)
