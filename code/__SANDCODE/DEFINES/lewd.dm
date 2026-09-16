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
// Emote sounds for custom moan picker
GLOBAL_LIST_INIT(lewd_purr_sounds, list(
	'modular_citadel/sound/voice/purr.ogg',

	'modular_citadel/sound/voice/merowr.ogg',

	'modular_splurt/sound/voice/raptor_purr.ogg',
	'modular_sand/sound/interactions/purr1.ogg',
	'modular_sand/sound/interactions/purr2.ogg',
	'modular_sand/sound/interactions/purr3.ogg',
	'sound/mobs/non-humanoids/cat/cat_purr1.ogg',
	'sound/mobs/non-humanoids/cat/cat_purr2.ogg',
	'sound/mobs/non-humanoids/cat/cat_purr3.ogg',
	'sound/mobs/non-humanoids/cat/cat_purr4.ogg',
	'modular_splurt/sound/voice/mrowl.ogg',


))

GLOBAL_LIST_INIT(lewd_meow_sounds, list(
	'modular_citadel/sound/voice/meow1.ogg',

	'modular_bluemoon/sound/emotes/meow4.ogg',
	'modular_bluemoon/sound/emotes/meow5.ogg',
	'modular_bluemoon/sound/emotes/meow6.ogg',
	'modular_bluemoon/sound/emotes/meow7_1.ogg',
	'modular_bluemoon/sound/emotes/meow7_2.ogg',
	'modular_bluemoon/sound/emotes/meow7_3.ogg',
	'modular_bluemoon/sound/emotes/meow7_4.ogg',
	'modular_bluemoon/sound/emotes/meow7_5.ogg',
	'modular_bluemoon/sound/emotes/catscream1.ogg',
	'modular_bluemoon/sound/emotes/catscream2.ogg',
	'modular_bluemoon/sound/emotes/catscream3.ogg',
	'modular_splurt/sound/voice/meow_meme.ogg',
	'modular_splurt/sound/voice/mewo.ogg',

	'modular_splurt/sound/voice/merowr.ogg',
	'modular_splurt/sound/voice/catpeople/cat_meow1.ogg',
	'modular_splurt/sound/voice/catpeople/cat_meow2.ogg',
	'modular_splurt/sound/voice/catpeople/cat_meow3.ogg',
	'modular_splurt/sound/voice/catpeople/cat_mew1.ogg',
	'modular_splurt/sound/voice/catpeople/cat_mew2.ogg',
	'modular_splurt/sound/voice/catpeople/cat_mrrp1.ogg',
	'modular_splurt/sound/voice/catpeople/cat_mrrp2.ogg',
	'sound/mobs/non-humanoids/cat/cat_meow1.ogg',
	'sound/mobs/non-humanoids/cat/cat_meow2.ogg',
	'sound/mobs/non-humanoids/cat/cat_meow3.ogg',
	'sound/mobs/non-humanoids/cat/oranges_meow1.ogg'
))

GLOBAL_LIST_INIT(lewd_fox_sounds, list(
	'sound/fox/Voice/fox_bark_1.ogg',
	'sound/fox/Voice/fox_scream.ogg',
	'sound/fox/Voice/fox_trill.ogg',
	'sound/fox/Voice/fox_trill_2.ogg',
	'sound/fox/Voice/fox_cacle.ogg',
	'sound/fox/Voice/fox_laugh.ogg',
	'sound/fox/Voice/fox_chatter.ogg',
	'sound/fox/Voice/fox_aaugh.ogg',
	'sound/fox/Voice/fox_growl.ogg',

))

GLOBAL_LIST_INIT(lewd_dog_sounds, list(
	'modular_citadel/sound/voice/bark1.ogg',
	'modular_citadel/sound/voice/bark2.ogg',
	'modular_citadel/sound/voice/awoo.ogg',
	'modular_splurt/sound/voice/bark_alt.ogg',
	'modular_splurt/sound/voice/yap.ogg',
	'modular_splurt/sound/voice/yip.ogg',
	'modular_splurt/sound/voice/woof.ogg',
	'modular_splurt/sound/voice/woof2.ogg',
	'modular_splurt/sound/voice/bork.ogg',
	'modular_splurt/sound/voice/wolfhowl.ogg',


	'sound/voice/woof.ogg',
	'sound/voice/growl.ogg',
	'sound/voice/growl2.ogg',
	'sound/mobs/non-humanoids/dog/growl1.ogg',
	'sound/mobs/non-humanoids/dog/growl2.ogg'
))

GLOBAL_LIST_INIT(lewd_bird_sounds, list(
	'modular_citadel/sound/voice/peep.ogg',
	'modular_bluemoon/sound/emotes/kweh1.ogg',
	'modular_bluemoon/sound/emotes/kweh2.ogg',
	'modular_bluemoon/sound/emotes/kweh3.ogg',
	'modular_bluemoon/sound/emotes/skweh1.ogg',
	'modular_bluemoon/sound/emotes/skweh2.ogg',
	'modular_bluemoon/sound/emotes/owl.ogg',
	'modular_bluemoon/sound/emotes/mar.ogg',
	'modular_splurt/sound/voice/chirp.ogg',
	'modular_splurt/sound/voice/caw.ogg',
	'modular_splurt/sound/voice/bawk.ogg',
	'modular_splurt/sound/voice/coo.ogg',
	'modular_splurt/sound/voice/hoot.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_goose_honk_b_01.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_goose_honk_b_02.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_goose_honk_b_03.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_goose_honk_b_06.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_02.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_03.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_04.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_06.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_07.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_08.ogg',
	'modular_splurt/sound/voice/goosehonk/sfx_gooseB_honk_09.ogg',
	'modular_sand/sound/voice/peep_once.ogg',
	'sound/voice/scream/bird1.ogg',
	'sound/voice/scream/bird2.ogg'
))

GLOBAL_LIST_INIT(lewd_robot_sounds, list(
	'sound/machines/synth_yes.ogg',
	'sound/machines/synth_no.ogg',
	'modular_bluemoon/sound/emotes/malf.ogg',
	'sound/effects/ping.ogg',
	'sound/machines/ping.ogg',
	'modular_bluemoon/sound/effects/soft_ping.ogg'
))

GLOBAL_LIST_INIT(lewd_insect_sounds, list(
	'modular_citadel/sound/voice/mothsqueak.ogg',
	'modular_citadel/sound/voice/scream_moth.ogg',
	'modular_splurt/sound/voice/moth/mothchitter2.ogg',
	'modular_splurt/sound/voice/barks/mothsqueak.ogg',
	'sound/voice/moth/mothchitter.ogg',
	'sound/voice/moth/mothlaugh.ogg',
	'sound/mobs/non-humanoids/insect/chitter.ogg',
	'sound/voice/barks/chitter.ogg',
	'sound/creatures/bee.ogg',
	'sound/mobs/non-humanoids/bee/bee.ogg',
	'sound/mobs/humanoids/moth/moth_flutter.ogg',
	'sound/mobs/humanoids/moth/moth_laugh1.ogg',
	'sound/voice/scream/moth1.ogg',
	'modular_splurt/sound/voice/teshsqueak.ogg',
	'modular_splurt/sound/voice/teshtrill.ogg',
	'modular_splurt/sound/voice/teshchirp.ogg',

))

GLOBAL_LIST_INIT(lewd_other_animal_sounds, list(
	"Hiss" = 'modular_citadel/sound/voice/hiss.ogg',
	"Felinid Hiss" = 'modular_bluemoon/sound/emotes/felinid_hiss.ogg',
	"Snake Dies" = 'modular_bluemoon/sound/emotes/snakedies.ogg',
	"Rattlesnake" = 'modular_splurt/sound/voice/rattle.ogg',
	"Oink 1" = 'modular_bluemoon/sound/emotes/oink1.ogg',
	"Oink 2" = 'modular_bluemoon/sound/emotes/oink2.ogg',
	"Oink 3" = 'modular_bluemoon/sound/emotes/oink3.ogg',
	"Weh" = 'modular_citadel/sound/voice/weh.ogg',
	"Weh 2" = 'modular_splurt/sound/voice/weh2.ogg',
	"Weh 3" = 'modular_splurt/sound/voice/weh3.ogg',
	"Weh Surprised" = 'modular_splurt/sound/voice/weh_s.ogg',
	"Moo" = 'modular_splurt/sound/voice/moo.ogg',
	"Bleat" = 'modular_splurt/sound/voice/bleat.ogg',
	"Horse Snort" = 'modular_bluemoon/sound/emotes/snort.ogg',
	"Horse Neigh" = 'modular_bluemoon/sound/emotes/neigh.ogg',
	"Trills" = 'sound/voice/trills.ogg',
	"Trill" = 'modular_splurt/sound/voice/trill.ogg',
	"Warble" = 'modular_splurt/sound/voice/warble.ogg',
	"Wurble" = 'modular_splurt/sound/voice/wurble.ogg',
	"Hyena Cackle" = 'modular_splurt/sound/voice/cackle_yeen.ogg'
))

GLOBAL_LIST_INIT(lewd_scream_female, list(
	'sound/voice/scream/scream_f1.ogg',
	'sound/voice/scream/scream_f2.ogg',
	'sound/voice/scream/scream_f3.ogg',
	'modular_citadel/sound/voice/scream_f1.ogg',
	'modular_citadel/sound/voice/scream_f2.ogg',
	'modular_citadel/sound/voice/scream_f3.ogg',
	'modular_citadel/sound/voice/scream_jelly_f1.ogg',
	'modular_citadel/sound/voice/scream_jelly_f2.ogg',
	'modular_citadel/sound/voice/human_female_scream_2.ogg',
	'modular_citadel/sound/voice/human_female_scream_3.ogg',
	'modular_citadel/sound/voice/human_female_scream_4.ogg',
	'modular_bluemoon/sound/emotes/scream_female_1.ogg',
	'modular_bluemoon/sound/emotes/scream_female_2.ogg',
	'modular_bluemoon/sound/emotes/scream_female_3.ogg',
	'modular_bluemoon/sound/emotes/scream_female_4.ogg',
	'sound/voice/scream/scream_r.ogg',
	'sound/voice/scream/android_scream.ogg',
	'modular_citadel/sound/voice/scream_silicon.ogg',
	'modular_citadel/sound/voice/scream_skeleton.ogg',
	'modular_bluemoon/sound/emotes/squeal.ogg'
))

GLOBAL_LIST_INIT(lewd_scream_male, list(
	'sound/voice/scream/scream_m1.ogg',
	'sound/voice/scream/scream_m2.ogg',
	'modular_citadel/sound/voice/scream_m.ogg',
	'modular_citadel/sound/voice/scream_m1.ogg',
	'modular_citadel/sound/voice/scream_m2.ogg',
	'modular_citadel/sound/voice/scream_jelly_m1.ogg',
	'modular_citadel/sound/voice/scream_jelly_m2.ogg',
	'modular_citadel/sound/voice/human_male_scream_1.ogg',
	'modular_citadel/sound/voice/human_male_scream_2.ogg',
	'modular_citadel/sound/voice/human_male_scream_3.ogg',
	'modular_citadel/sound/voice/human_male_scream_4.ogg',
	'modular_bluemoon/sound/emotes/scream_male_1.ogg',
	'modular_bluemoon/sound/emotes/scream_male_2.ogg',
	'sound/voice/scream/scream_r.ogg',
	'sound/voice/scream/android_scream.ogg',
	'modular_citadel/sound/voice/scream_silicon.ogg',
	'modular_citadel/sound/voice/scream_skeleton.ogg',
	'modular_bluemoon/sound/emotes/squeal.ogg'
))

GLOBAL_LIST_INIT(lewd_scream_gachi, list(
	'modular_splurt/sound/voice/cscream1.ogg',
	'modular_splurt/sound/voice/cscream2.ogg',
	'modular_splurt/sound/voice/cscream3.ogg',
	'modular_splurt/sound/voice/cscream4.ogg',
	'modular_splurt/sound/voice/cscream5.ogg',
	'modular_splurt/sound/voice/cscream6.ogg',
	'modular_splurt/sound/voice/cscream7.ogg',
	'modular_splurt/sound/voice/cscream8.ogg',
	'modular_splurt/sound/voice/cscream9.ogg',
	'modular_splurt/sound/voice/cscream10.ogg',
	'modular_splurt/sound/voice/cscream11.ogg',
	'modular_splurt/sound/voice/cscream12.ogg',
	'modular_splurt/sound/voice/gachi/scream1.ogg',
	'modular_splurt/sound/voice/gachi/scream2.ogg',
	'modular_splurt/sound/voice/gachi/scream3.ogg',
	'modular_splurt/sound/voice/gachi/scream4.ogg'
))

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
#define INTERACTION_UNHOLY_HARD 4


#define INTERACTION_EFFECT_HEART "heart"

GLOBAL_LIST_INIT(interaction_effects_list, list(
	INTERACTION_EFFECT_HEART = "Сердечко",
))

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
#define NUTS_MASSAGE "nuts_massage"

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

#define INTERACTION_REQUIRE_ANUS (1<<4)
#define INTERACTION_REQUIRE_BALLS (1<<5)
#define INTERACTION_REQUIRE_BREASTS (1<<6)
#define INTERACTION_REQUIRE_BELLY (1<<7)
// Terrible stuff start here
#define INTERACTION_REQUIRE_EARS (1<<8)
#define INTERACTION_REQUIRE_EARSOCKETS (1<<9)
#define INTERACTION_REQUIRE_EYES (1<<10)
#define INTERACTION_REQUIRE_EYESOCKETS (1<<11)
// End here
#define INTERACTION_REQUIRE_FEET (1<<12)
#define INTERACTION_REQUIRE_PENIS (1<<13)
#define INTERACTION_REQUIRE_VAGINA (1<<14)
// BLUEMOON ADD хвостики!
#define INTERACTION_REQUIRE_TAIL (1<<15)
#define INTERACTION_REQUIRE_KNOT (1<<16) // not replace INTERACTION_REQUIRE_PENIS, use both
#define INTERACTION_REQUIRE_DOUBLE_PENIS (1<<17) // not replace INTERACTION_REQUIRE_PENIS, use both
#define INTERACTION_REQUIRE_TK (1<<18)
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
#define INTERACTION_FLAG_HIDE_IN_PANEL (1<<9) // not show for users
#define INTERACTION_FLAG_UNHOLY_HARD (1<<10) // C богом

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

#define DEFAULT_INTERACTION_SOUND_EXTRARANGE(_is_hidden) (_is_hidden ? (-SOUND_RANGE+2) : -1)
