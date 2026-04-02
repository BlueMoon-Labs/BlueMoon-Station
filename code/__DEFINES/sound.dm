//max channel is 1024. Only go lower from here, because byond tends to pick the first availiable channel to play sounds on
#define CHANNEL_LOBBYMUSIC 1024
#define CHANNEL_ADMIN 1023
#define CHANNEL_VOX 1022
// BLUEMOON REMOVAL BEGIN - Increasing amount of jukebox channels
/*
#define CHANNEL_JUKEBOX 1021

#define CHANNEL_JUKEBOX_START 1016 //The gap between this and CHANNEL_JUKEBOX determines the amount of free jukebox channels. This currently allows 6 jukebox channels to exist.
// BLUEMOON REMOVAL END
*/
// BLUEMOON EDIT - Jukebox channels
#define CHANNEL_JUSTICAR_ARK 1021
#define CHANNEL_HEARTBEAT 1020 //sound channel for heartbeats
#define CHANNEL_AMBIENCE 1019
#define CHANNEL_BUZZ 1018
#define CHANNEL_BICYCLE 1017
//CIT CHANNELS - TRY NOT TO REGRESS
#define CHANNEL_PRED 1016
#define CHANNEL_DIGEST 1015
#define CHANNEL_PREYLOOP 1014
//Reactor Channel
#define CHANNEL_REACTOR_ALERT 1013 // Is that radiation I hear? (ported from hyper)
#define CHANNEL_JUKEBOX 1012
#define CHANNEL_JUKEBOX_START 993
// Tetris arcade music для работы лимита канала.
#define CHANNEL_TETRIS_MUSIC 992

//THIS SHOULD ALWAYS BE THE LOWEST ONE!
//KEEP IT UPDATED

#define CHANNEL_HIGHEST_AVAILABLE 991 //CIT CHANGE - COMPENSATES FOR VORESOUND CHANNELS

// BLUEMOON EDIT END

#define MAX_INSTRUMENT_CHANNELS (128 * 6)

///Default range of a sound.
#define SOUND_RANGE 17
#define MEDIUM_RANGE_SOUND_EXTRARANGE -5
///default extra range for sounds considered to be quieter
#define SHORT_RANGE_SOUND_EXTRARANGE -9
///The range deducted from sound range for things that are considered silent / sneaky
#define SILENCED_SOUND_EXTRARANGE -11
///Percentage of sound's range where no falloff is applied
#define SOUND_DEFAULT_FALLOFF_DISTANCE 1 //For a normal sound this would be 1 tile of no falloff
///The default exponent of sound falloff
#define SOUND_FALLOFF_EXPONENT 7.5
/// Default distance multiplier for sounds
#define SOUND_DEFAULT_DISTANCE_MULTIPLIER 2.5
/// Default range at which sound distance multiplier applies
#define SOUND_DEFAULT_MULTIPLIER_EFFECT_RANGE 7


#define SOUND_MINIMUM_PRESSURE 10
/// remove
#define FALLOFF_SOUNDS 1


//Ambience types

#define GENERIC list('sound/ambience/ambigen1.ogg','sound/ambience/ambigen3.ogg',\
								'sound/ambience/ambigen4.ogg','sound/ambience/ambigen5.ogg',\
								'sound/ambience/ambigen6.ogg','sound/ambience/ambigen7.ogg',\
								'sound/ambience/ambigen8.ogg','sound/ambience/ambigen9.ogg',\
								'sound/ambience/ambigen10.ogg','sound/ambience/ambigen11.ogg',\
								'sound/ambience/ambigen12.ogg','sound/ambience/ambigen14.ogg','sound/ambience/ambigen15.ogg')

#define HOLY list('sound/ambience/ambicha1.ogg','sound/ambience/ambicha2.ogg','sound/ambience/ambicha3.ogg',\
										'sound/ambience/ambicha4.ogg', 'sound/ambience/ambiholy.ogg', 'sound/ambience/ambiholy2.ogg',\
										'sound/ambience/ambiholy3.ogg')

#define HIGHSEC list('sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambidanger3.ogg', 'sound/ambience/ambidanger4.ogg', 'sound/ambience/ambidanger5.ogg', 'sound/ambience/ambidanger6.ogg')

#define RUINS list('sound/ambience/ambimine.ogg', 'sound/ambience/ambicave.ogg', 'sound/ambience/ambiruin.ogg',\
									'sound/ambience/ambiruin2.ogg',  'sound/ambience/ambiruin3.ogg',  'sound/ambience/ambiruin4.ogg',\
									'sound/ambience/ambiruin5.ogg',  'sound/ambience/ambiruin6.ogg',  'sound/ambience/ambiruin7.ogg',\
									'sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambitech3.ogg',\
									'sound/ambience/ambimystery.ogg', 'sound/ambience/ambimaint1.ogg')

#define ENGINEERING list('sound/ambience/ambisin1.ogg','sound/ambience/ambisin2.ogg','sound/ambience/ambisin3.ogg','sound/ambience/ambisin4.ogg',\
										'sound/ambience/ambiatmos.ogg', 'sound/ambience/ambiatmos2.ogg', 'sound/ambience/ambitech.ogg',\
										'sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg', 'sound/ambience/ambiviro.ogg')

#define MINING list('sound/ambience/ambimine.ogg', 'sound/ambience/ambicave.ogg', 'sound/ambience/ambiruin.ogg',\
											'sound/ambience/ambiruin2.ogg',  'sound/ambience/ambiruin3.ogg',  'sound/ambience/ambiruin4.ogg',\
											'sound/ambience/ambiruin5.ogg',  'sound/ambience/ambiruin6.ogg',  'sound/ambience/ambiruin7.ogg',\
											'sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambimaint1.ogg',\
											'sound/ambience/ambilava.ogg')

#define MEDICAL list('sound/ambience/ambinice.ogg')

#define SPOOKY list('sound/ambience/ambimo1.ogg','sound/ambience/ambimo2.ogg','sound/ambience/ambiruin7.ogg','sound/ambience/ambiruin6.ogg',\
										'sound/ambience/ambiodd.ogg', 'sound/ambience/ambimystery.ogg')

#define SPACE list('sound/ambience/ambispace1.ogg', 'sound/ambience/ambispace2.ogg', 'sound/ambience/ambispace3.ogg', 'sound/ambience/ambispace4.ogg', 'sound/ambience/ambispace5.ogg', 'sound/ambience/title2.ogg', 'sound/ambience/ambiatmos.ogg')

#define MAINTENANCE list('sound/ambience/ambimaint1.ogg', 'sound/ambience/ambimaint2.ogg', 'sound/ambience/ambimaint3.ogg', 'sound/ambience/ambimaint4.ogg',\
											'sound/ambience/ambimaint5.ogg', 'sound/voice/lowHiss2.ogg', 'sound/voice/lowHiss3.ogg', 'sound/voice/lowHiss4.ogg', 'sound/ambience/ambitech2.ogg',\
											'sound/ambience/ambimaint10.ogg', 'sound/ambience/maintambience.ogg' )

#define AWAY_MISSION list('sound/ambience/ambitech.ogg', 'sound/ambience/ambitech2.ogg', 'sound/ambience/ambiruin.ogg',\
									'sound/ambience/ambiruin2.ogg',  'sound/ambience/ambiruin3.ogg',  'sound/ambience/ambiruin4.ogg',\
									'sound/ambience/ambiruin5.ogg',  'sound/ambience/ambiruin6.ogg',  'sound/ambience/ambiruin7.ogg',\
									'sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambimaint.ogg',\
									'sound/ambience/ambiatmos.ogg', 'sound/ambience/ambiatmos2.ogg', 'sound/ambience/ambiodd.ogg')

#define REEBE list('sound/ambience/ambireebe1.ogg', 'sound/ambience/ambireebe2.ogg', 'sound/ambience/ambireebe3.ogg')

#define SHUTTLE list('modular_bluemoon/kovac_shitcode/sound/ambience/enc/alarm_radio.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/alarm_small_09.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/engine_ignit_int.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/enc/env_ship_down.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/gear_loop.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/gear_start.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/enc/gear_stop.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/intercom_loop.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/morse.ogg' )

#define SHUTTLE_MILITARY list('modular_bluemoon/kovac_shitcode/sound/ambience/enc/alarm_radio.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/alarm_small_09.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/engine_ignit_int.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/enc/env_ship_down.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/gear_loop.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/gear_start.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/enc/gear_stop.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/intercom_loop.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/morse.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/mission_danger_01.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/mission_end_02.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/mission_start_03.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/radio_burn_engine_04.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/radio_fuel_20.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/radio_fuel_50.ogg',\
							'modular_bluemoon/kovac_shitcode/sound/ambience/radio_go.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/radio_lost_missile_01.ogg', 'modular_bluemoon/kovac_shitcode/sound/ambience/radio_missile_01.ogg' )

#define CREEPY_SOUNDS list('sound/effects/ghost.ogg', 'sound/effects/ghost2.ogg', 'sound/effects/heart_beat.ogg', 'sound/effects/screech.ogg',\
	'sound/hallucinations/behind_you1.ogg', 'sound/hallucinations/behind_you2.ogg', 'sound/hallucinations/far_noise.ogg', 'sound/hallucinations/growl1.ogg', 'sound/hallucinations/growl2.ogg',\
	'sound/hallucinations/growl3.ogg', 'sound/hallucinations/im_here1.ogg', 'sound/hallucinations/im_here2.ogg', 'sound/hallucinations/i_see_you1.ogg', 'sound/hallucinations/i_see_you2.ogg',\
	'sound/hallucinations/look_up1.ogg', 'sound/hallucinations/look_up2.ogg', 'sound/hallucinations/over_here1.ogg', 'sound/hallucinations/over_here2.ogg', 'sound/hallucinations/over_here3.ogg',\
	'sound/hallucinations/turn_around1.ogg', 'sound/hallucinations/turn_around2.ogg', 'sound/hallucinations/veryfar_noise.ogg', 'sound/hallucinations/wail.ogg')

#define RUSSIAN_SCREAMS list('sound/voice/human/cyka1.ogg', 'sound/voice/human/rus1.ogg', 'sound/voice/human/rus2.ogg', 'sound/voice/human/rus3.ogg',\
	'sound/voice/human/rus4.ogg', 'sound/voice/human/rus5.ogg', 'sound/voice/human/rus6.ogg')

#define ALLIANCE_SCREAMS list('sound/voice/human/combine_hit1.ogg', 'sound/voice/human/combine_hit2.ogg', 'sound/voice/human/combine_hit3.ogg',\
	'sound/voice/human/combine_hit4.ogg', 'sound/voice/human/combine_hit5.ogg', 'sound/voice/human/combine_hit6.ogg',\
	'sound/voice/human/combine_hit7.ogg', 'sound/voice/human/combine_hit8.ogg', 'sound/voice/human/combine_hit9.ogg',\
	'sound/voice/human/combine_hit10.ogg')

#define SPASEMAR_SCREAMS list('modular_bluemoon/Ren/Sound/screams/he_die.ogg', 'modular_bluemoon/Ren/Sound/screams/aah_1.ogg', 'modular_bluemoon/Ren/Sound/screams/nooh.ogg', 'modular_bluemoon/Ren/Sound/screams/nyaahaa.ogg',\
	'modular_bluemoon/Ren/Sound/screams/oh.ogg') // BLUEMOON ADD

#define BLOOD_SCREAMS list('modular_bluemoon/kovac_shitcode/sound/blood/cult_1.ogg', 'modular_bluemoon/kovac_shitcode/sound/blood/cult_2.ogg', 'modular_bluemoon/kovac_shitcode/sound/blood/cult_3.ogg',\
	'modular_bluemoon/kovac_shitcode/sound/blood/cult_4.ogg', 'modular_bluemoon/kovac_shitcode/sound/blood/cult_5.ogg')

#define BLOOD_SCREAMS_PICK pick('modular_bluemoon/kovac_shitcode/sound/blood/cult_1.ogg', 'modular_bluemoon/kovac_shitcode/sound/blood/cult_2.ogg', 'modular_bluemoon/kovac_shitcode/sound/blood/cult_3.ogg',\
	'modular_bluemoon/kovac_shitcode/sound/blood/cult_4.ogg', 'modular_bluemoon/kovac_shitcode/sound/blood/cult_5.ogg')

#define ARENA_MUSIC list('sound/music/arena/hotline1.ogg', 'sound/music/arena/hotline2.ogg', 'sound/music/arena/hotline3.ogg', 'sound/music/arena/hotline4.ogg',\
	'sound/music/arena/hotline5.ogg', 'sound/music/arena/hotline6.ogg', 'sound/music/arena/hotline7.ogg', 'sound/music/arena/hotline8.ogg', 'sound/music/arena/hotline9.ogg',\
	'sound/music/arena/hotline10.ogg', 'sound/music/arena/kat1.ogg', 'sound/music/arena/kat2.ogg', 'sound/music/arena/kat3.ogg', 'sound/music/arena/kat4.ogg',\
	'sound/music/arena/kat5.ogg', 'sound/music/arena/kat6.ogg', 'sound/music/arena/kat7.ogg', 'sound/music/arena/kat8.ogg', 'sound/music/arena/kat9.ogg',\
	'sound/music/arena/kat10.ogg')

#define INTERACTION_SOUND_RANGE_MODIFIER -3
#define EQUIP_SOUND_VOLUME 30
#define PICKUP_SOUND_VOLUME 15
#define DROP_SOUND_VOLUME 20
#define YEET_SOUND_VOLUME 90


//default byond sound environments
#define SOUND_ENVIRONMENT_NONE -1
#define SOUND_ENVIRONMENT_GENERIC 0
#define SOUND_ENVIRONMENT_PADDED_CELL 1
#define SOUND_ENVIRONMENT_ROOM 2
#define SOUND_ENVIRONMENT_BATHROOM 3
#define SOUND_ENVIRONMENT_LIVINGROOM 4
#define SOUND_ENVIRONMENT_STONEROOM 5
#define SOUND_ENVIRONMENT_AUDITORIUM 6
#define SOUND_ENVIRONMENT_CONCERT_HALL 7
#define SOUND_ENVIRONMENT_CAVE 8
#define SOUND_ENVIRONMENT_ARENA 9
#define SOUND_ENVIRONMENT_HANGAR 10
#define SOUND_ENVIRONMENT_CARPETED_HALLWAY 11
#define SOUND_ENVIRONMENT_HALLWAY 12
#define SOUND_ENVIRONMENT_STONE_CORRIDOR 13
#define SOUND_ENVIRONMENT_ALLEY 14
#define SOUND_ENVIRONMENT_FOREST 15
#define SOUND_ENVIRONMENT_CITY 16
#define SOUND_ENVIRONMENT_MOUNTAINS 17
#define SOUND_ENVIRONMENT_QUARRY 18
#define SOUND_ENVIRONMENT_PLAIN 19
#define SOUND_ENVIRONMENT_PARKING_LOT 20
#define SOUND_ENVIRONMENT_SEWER_PIPE 21
#define SOUND_ENVIRONMENT_UNDERWATER 22
#define SOUND_ENVIRONMENT_DRUGGED 23
#define SOUND_ENVIRONMENT_DIZZY 24
#define SOUND_ENVIRONMENT_PSYCHOTIC 25
//If we ever make custom ones add them here

//"sound areas": easy way of keeping different types of areas consistent.
#define SOUND_AREA_STANDARD_STATION SOUND_ENVIRONMENT_PARKING_LOT
#define SOUND_AREA_LARGE_ENCLOSED SOUND_ENVIRONMENT_QUARRY
#define SOUND_AREA_SMALL_ENCLOSED SOUND_ENVIRONMENT_BATHROOM
#define SOUND_AREA_TUNNEL_ENCLOSED SOUND_ENVIRONMENT_STONEROOM
#define SOUND_AREA_LARGE_SOFTFLOOR SOUND_ENVIRONMENT_CARPETED_HALLWAY
#define SOUND_AREA_MEDIUM_SOFTFLOOR SOUND_ENVIRONMENT_LIVINGROOM
#define SOUND_AREA_SMALL_SOFTFLOOR SOUND_ENVIRONMENT_ROOM
#define SOUND_AREA_ASTEROID SOUND_ENVIRONMENT_CAVE
#define SOUND_AREA_SPACE SOUND_ENVIRONMENT_UNDERWATER
#define SOUND_AREA_LAVALAND SOUND_ENVIRONMENT_MOUNTAINS
#define SOUND_AREA_ICEMOON SOUND_ENVIRONMENT_CAVE
#define SOUND_AREA_WOODFLOOR SOUND_ENVIRONMENT_CITY

///Announcer audio keys
#define ANNOUNCER_AIMALF "aimalf"
#define ANNOUNCER_ALIENS "aliens"
#define ANNOUNCER_ANIMES "animes"
#define ANNOUNCER_GRANOMALIES "granomalies"
#define ANNOUNCER_INTERCEPT "intercept"
#define ANNOUNCER_IONSTORM "ionstorm"
#define ANNOUNCER_METEORS "meteors"
#define ANNOUNCER_NEWAI "newAI"
#define ANNOUNCER_OUTBREAK5 "outbreak5"
#define ANNOUNCER_OUTBREAK7 "outbreak7"
#define ANNOUNCER_POWEROFF "poweroff"
#define ANNOUNCER_POWERON "poweron"
#define ANNOUNCER_RADIATION "radiation"
#define ANNOUNCER_SHUTTLECALLED "shuttlecalled"
#define ANNOUNCER_SHUTTLEDOCK "shuttledock"
#define ANNOUNCER_SHUTTLERECALLED "shuttlerecalled"
#define ANNOUNCER_SPANOMALIES "spanomalies"
#define ANNOUNCER_ADMIN_1 "_admin_cap_gone"
#define ANNOUNCER_ADMIN_2 "_admin_capitain"
#define ANNOUNCER_ADMIN_3 "_admin_horror_music"
#define ANNOUNCER_ADMIN_4 "_admin_hos_gone"
#define ANNOUNCER_ADMIN_5 "_admin_war_pipisky"
#define ANNOUNCER_ADMIN_6 "_admin_war_pizdec"
#define ANNOUNCER_ADMIN_7 "_admin_war_tishina"
#define ANNOUNCER_BSA "artillery"
#define ANNOUNCER_XENO "xeno"
#define ANNOUNCER_IROD "irod"
#define ANNOUNCER_LAMBDA "lambda"


/// Global list of all of our announcer keys.
GLOBAL_LIST_INIT(announcer_keys, list(
	ANNOUNCER_AIMALF,
	ANNOUNCER_ALIENS,
	ANNOUNCER_ANIMES,
	ANNOUNCER_GRANOMALIES,
	ANNOUNCER_INTERCEPT,
	ANNOUNCER_IONSTORM,
	ANNOUNCER_METEORS,
	ANNOUNCER_NEWAI,
	ANNOUNCER_OUTBREAK5,
	ANNOUNCER_OUTBREAK7,
	ANNOUNCER_POWEROFF,
	ANNOUNCER_POWERON,
	ANNOUNCER_RADIATION,
	ANNOUNCER_SHUTTLECALLED,
	ANNOUNCER_SHUTTLEDOCK,
	ANNOUNCER_SHUTTLERECALLED,
	ANNOUNCER_SPANOMALIES,
	ANNOUNCER_ADMIN_1,
	ANNOUNCER_ADMIN_2,
	ANNOUNCER_ADMIN_3,
	ANNOUNCER_ADMIN_4,
	ANNOUNCER_ADMIN_5,
	ANNOUNCER_ADMIN_6,
	ANNOUNCER_ADMIN_7,
	ANNOUNCER_BSA,
	ANNOUNCER_XENO,
	ANNOUNCER_IROD,
	ANNOUNCER_LAMBDA
))

// Возможные звуки эмоции *deathgasp
GLOBAL_LIST_INIT(deathgasp_sounds, list(
	"По умолчанию" =		null,
	"Беззвучный" =			-1,
	"Классический (1)" =	'sound/voice/deathgasp1.ogg',
	"Классический (2)" =	'sound/voice/deathgasp2.ogg',
	"Киборг" =				'sound/voice/borg_deathsound.ogg',
	"Демон" =				'sound/magic/demon_dies.ogg',
	"Имп" =					'modular_sand/sound/misc/impdies.wav',
	"Гладиатор" =			'modular_sand/sound/effects/gladiatordeathsound.ogg',
	"Посох Смерти" =		'sound/magic/WandODeath.ogg',
	"Проклятие" =			'sound/magic/curse.ogg',
	"Конструкт Ратвара" =	'sound/magic/clockwork/anima_fragment_death.ogg',
	"Ксеноморф" =			'sound/voice/hiss6.ogg',
	"Свинья" =				'modular_bluemoon/sound/creatures/pig/death.ogg',
	"Офицер ГО" =			'modular_bluemoon/sound/ert/combine_death.ogg',
	"Свинья" =				'modular_bluemoon/sound/voice/death_gasps/pig.ogg',
	"Свинья 2" =				'modular_bluemoon/sound/voice/death_gasps/pig2.ogg',
	"Фрэнк" =				'modular_bluemoon/sound/voice/death_gasps/frank.ogg',
	"Сьюзи" =				'modular_bluemoon/sound/voice/death_gasps/susie.ogg',
	"Наёмник" =				'modular_bluemoon/sound/voice/death_gasps/mercenary.ogg',
	"Бандит 1" =			'modular_bluemoon/sound/voice/death_gasps/bandit1.ogg',
	"Бандит 2" =			'modular_bluemoon/sound/voice/death_gasps/bandit2.ogg',
	"Смерть в богатстве" =	'modular_bluemoon/sound/voice/death_gasps/richstalker.ogg',
	"Зомбированный сталкер" =	'modular_bluemoon/sound/voice/death_gasps/stalkerzombie.ogg'
	))

GLOBAL_LIST_INIT(otherworld_sounds, list(
		'sound/items/bubblewrap.ogg',
		'sound/items/change_jaws.ogg',
		'sound/items/crowbar.ogg',
		'sound/items/drink.ogg',
		'sound/items/deconstruct.ogg',
		'sound/items/carhorn.ogg',
		'sound/items/change_drill.ogg',
		'sound/items/dodgeball.ogg',
		'sound/items/eatfood.ogg',
		'sound/items/megaphone.ogg',
		'sound/items/screwdriver.ogg',
		'sound/items/weeoo1.ogg',
		'sound/items/wirecutter.ogg',
		'sound/items/welder.ogg',
		'sound/items/zip.ogg',
		'sound/items/rped.ogg',
		'sound/items/ratchet.ogg',
		'sound/items/polaroid1.ogg',
		'sound/items/pshoom.ogg',
		'sound/items/airhorn.ogg',
		'sound/items/geiger/high1.ogg',
		'sound/items/geiger/high2.ogg',
		'sound/voice/beepsky/creep.ogg',
		'sound/voice/beepsky/iamthelaw.ogg',
		'sound/voice/ed209_20sec.ogg',
		'sound/voice/hiss3.ogg',
		'sound/voice/hiss6.ogg',
		'sound/voice/medbot/patchedup.ogg',
		'sound/voice/medbot/feelbetter.ogg',
		'sound/voice/human/manlaugh1.ogg',
		'sound/voice/human/womanlaugh.ogg',
		'sound/weapons/sear.ogg',
		'sound/ambience/antag/clockcultalr.ogg',
		'sound/ambience/antag/ling_aler.ogg',
		'sound/ambience/antag/tatoralert.ogg',
		'sound/ambience/antag/monkey.ogg',
		'sound/mecha/nominal.ogg',
		'sound/mecha/weapdestr.ogg',
		'sound/mecha/critdestr.ogg',
		'sound/mecha/imag_enh.ogg',
		'sound/effects/adminhelp.ogg',
		'sound/misc/alerts/alert.ogg',
		'sound/effects/attackblob.ogg',
		'sound/effects/bamf.ogg',
		'sound/effects/blobattack.ogg',
		'sound/effects/break_stone.ogg',
		'sound/effects/bubbles.ogg',
		'sound/effects/bubbles2.ogg',
		'sound/effects/clang.ogg',
		'sound/effects/clockcult_gateway_disrupted.ogg',
		'sound/effects/clownstep2.ogg',
		'sound/effects/curse1.ogg',
		'sound/effects/dimensional_rend.ogg',
		'sound/effects/doorcreaky.ogg',
		'sound/effects/empulse.ogg',
		'sound/effects/explosion_distant.ogg',
		'sound/effects/explosionfar.ogg',
		'sound/effects/explosion1.ogg',
		'sound/effects/grillehit.ogg',
		'sound/effects/genetics.ogg',
		'sound/effects/heart_beat.ogg',
		'sound/effects/hyperspace_begin.ogg',
		'sound/effects/hyperspace_end.ogg',
		'sound/effects/his_grace_awaken.ogg',
		'sound/effects/pai_boot.ogg',
		'sound/effects/phasein.ogg',
		'sound/effects/picaxe1.ogg',
		'sound/effects/ratvar_reveal.ogg',
		'sound/effects/sparks1.ogg',
		'sound/effects/smoke.ogg',
		'sound/effects/splat.ogg',
		'sound/effects/snap.ogg',
		'sound/effects/tendril_destroyed.ogg',
		'sound/effects/supermatter.ogg',
		'sound/misc/desceration-01.ogg',
		'sound/misc/desceration-02.ogg',
		'sound/misc/desceration-03.ogg',
		'sound/misc/bloblarm.ogg',
		'sound/misc/airraid.ogg',
		'sound/misc/bang.ogg',
		'sound/misc/highlander.ogg',
		'sound/misc/interference.ogg',
		'sound/misc/notice1.ogg',
		'sound/misc/notice2.ogg',
		'sound/misc/sadtrombone.ogg',
		'sound/misc/slip.ogg',
		'sound/misc/splort.ogg',
		'sound/weapons/armbomb.ogg',
		'sound/weapons/beam_sniper.ogg',
		'sound/weapons/chainsawhit.ogg',
		'sound/weapons/emitter.ogg',
		'sound/weapons/emitter2.ogg',
		'sound/weapons/blade1.ogg',
		'sound/weapons/bladeslice.ogg',
		'sound/weapons/blastcannon.ogg',
		'sound/weapons/blaster.ogg',
		'sound/weapons/bulletflyby3.ogg',
		'sound/weapons/circsawhit.ogg',
		'sound/weapons/cqchit2.ogg',
		'sound/weapons/drill.ogg',
		'sound/weapons/genhit1.ogg',
		'sound/weapons/gunshot_silenced.ogg',
		'sound/weapons/gunshot2.ogg',
		'sound/weapons/handcuffs.ogg',
		'sound/weapons/homerun.ogg',
		'sound/weapons/kenetic_accel.ogg',
		'sound/machines/clockcult/steam_whoosh.ogg',
		'sound/machines/fryer/deep_fryer_emerge.ogg',
		'sound/machines/airlock.ogg',
		'sound/machines/airlock_alien_prying.ogg',
		'sound/machines/airlockclose.ogg',
		'sound/machines/airlockforced.ogg',
		'sound/machines/airlockopen.ogg',
		'sound/machines/alarm.ogg',
		'sound/machines/blender.ogg',
		'sound/machines/boltsdown.ogg',
		'sound/machines/boltsup.ogg',
		'sound/machines/buzz-sigh.ogg',
		'sound/machines/buzz-two.ogg',
		'sound/machines/chime.ogg',
		'sound/machines/cryo_warning.ogg',
		'sound/machines/defib_charge.ogg',
		'sound/machines/defib_failed.ogg',
		'sound/machines/defib_ready.ogg',
		'sound/machines/defib_zap.ogg',
		'sound/machines/deniedbeep.ogg',
		'sound/machines/ding.ogg',
		'sound/machines/disposalflush.ogg',
		'sound/machines/door_close.ogg',
		'sound/machines/door_open.ogg',
		'sound/machines/engine_alert1.ogg',
		'sound/machines/engine_alert2.ogg',
		'sound/machines/hiss.ogg',
		'sound/machines/honkbot_evil_laugh.ogg',
		'sound/machines/juicer.ogg',
		'sound/machines/ping.ogg',
		'sound/machines/signal.ogg',
		'sound/machines/synth_no.ogg',
		'sound/machines/synth_yes.ogg',
		'sound/machines/terminal_alert.ogg',
		'sound/machines/triple_beep.ogg',
		'sound/machines/twobeep.ogg',
		'sound/machines/ventcrawl.ogg',
		'sound/machines/warning-buzzer.ogg',
		'sound/announcer/classic/outbreak5.ogg',
		'sound/announcer/classic/outbreak7.ogg',
		'sound/announcer/intern/poweroff_boomer.ogg',
		'sound/announcer/classic/poweroff.ogg',
		'sound/announcer/classic/poweroff.ogg',
		'sound/announcer/classic/poweroff.ogg',
		'sound/announcer/classic/poweroff.ogg',
		'sound/announcer/classic/poweroff.ogg',
		'sound/announcer/classic/poweroff2.ogg',
		'sound/announcer/classic/radiation.ogg',
		'sound/announcer/classic/shuttlerecalled.ogg',
		'sound/announcer/classic/shuttledock.ogg',
		'sound/announcer/classic/shuttlecalled.ogg',
		'sound/announcer/classic/aimalf.ogg',
		'modular_bluemoon/sound/effects/bonfire_lit.ogg',
		'modular_bluemoon/sound/effects/chair_break.ogg',
		'modular_bluemoon/sound/effects/critical_hit.ogg',
		'modular_bluemoon/sound/effects/hahun_dontmove.ogg',
		'modular_bluemoon/sound/effects/hahun_halt.ogg',
		'modular_bluemoon/sound/effects/hahun_hold.ogg',
		'modular_bluemoon/sound/effects/hahun_verdict.ogg',
		'modular_bluemoon/sound/effects/metal_pipe.ogg',
		'modular_bluemoon/sound/effects/nanosuitengage.ogg',
		'modular_bluemoon/sound/effects/noose_idle.ogg',
		'modular_bluemoon/sound/effects/noosed.ogg',
		'modular_bluemoon/sound/effects/opening-gears.ogg',
		'modular_bluemoon/sound/effects/pshsh.ogg',
		'modular_bluemoon/sound/effects/restart-shutdown.ogg',
		'modular_bluemoon/sound/effects/restart-wakeup.ogg',
		'modular_bluemoon/sound/effects/re-zero.ogg',
		'modular_bluemoon/sound/effects/robot_bump.ogg',
		'modular_bluemoon/sound/effects/robot_sit.ogg',
		'modular_bluemoon/sound/effects/snap.ogg',
		'modular_bluemoon/sound/effects/soft_ping.ogg',
		'modular_bluemoon/sound/effects/spook.ogg',
		'modular_bluemoon/sound/effects/squishy.ogg',
		'modular_bluemoon/sound/effects/startup.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_female1.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_female2.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_female3.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_male1.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_male2.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_male3.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_male4.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_male5.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall_male6.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall1.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall2.ogg',
		'modular_bluemoon/sound/effects/titanfall/titanfall3.ogg',
		'modular_bluemoon/sound/effects/transform.ogg',
		'modular_bluemoon/sound/effects/whir1.ogg',
		'modular_bluemoon/sound/emotes/afton_death_laugh.ogg',
		'modular_bluemoon/sound/emotes/afton_laugh.ogg',
		'modular_bluemoon/sound/emotes/agony_female_1.ogg',
		'modular_bluemoon/sound/emotes/agony_female_2.ogg',
		'modular_bluemoon/sound/emotes/agony_female_3.ogg',
		'modular_bluemoon/sound/emotes/agony_male_1.ogg',
		'modular_bluemoon/sound/emotes/agony_male_2.ogg',
		'modular_bluemoon/sound/emotes/agony_male_3.ogg',
		'modular_bluemoon/sound/emotes/agony_male_4.ogg',
		'modular_bluemoon/sound/emotes/agony_male_5.ogg',
		'modular_bluemoon/sound/emotes/agony_male_6.ogg',
		'modular_bluemoon/sound/emotes/agony_male_7.ogg',
		'modular_bluemoon/sound/emotes/agony_male_8.ogg',
		'modular_bluemoon/sound/emotes/agony_male_9.ogg',
		'modular_bluemoon/sound/emotes/always_come_back.ogg',
		'modular_bluemoon/sound/emotes/animewow.ogg',
		'modular_bluemoon/sound/emotes/boalert.ogg',
		'modular_bluemoon/sound/emotes/bonecrack.ogg',
		'modular_bluemoon/sound/emotes/bruv.ogg',
		'modular_bluemoon/sound/emotes/burp_female.ogg',
		'modular_bluemoon/sound/emotes/burp_male.ogg',
		'modular_bluemoon/sound/emotes/catgaph.ogg',
		'modular_bluemoon/sound/emotes/catscream1.ogg',
		'modular_bluemoon/sound/emotes/catscream2.ogg',
		'modular_bluemoon/sound/emotes/catscream3.ogg',
		'modular_bluemoon/sound/emotes/choke_female_1.ogg',
		'modular_bluemoon/sound/emotes/choke_female_2.ogg',
		'modular_bluemoon/sound/emotes/choke_female_3.ogg',
		'modular_bluemoon/sound/emotes/choke_female_4.ogg',
		'modular_bluemoon/sound/emotes/choke_male_1.ogg',
		'modular_bluemoon/sound/emotes/choke_male_2.ogg',
		'modular_bluemoon/sound/emotes/choke_male_3.ogg',
		'modular_bluemoon/sound/emotes/choke_male_4.ogg',
		'modular_bluemoon/sound/emotes/cough_female_1.ogg',
		'modular_bluemoon/sound/emotes/cough_female_2.ogg',
		'modular_bluemoon/sound/emotes/cough_female_3.ogg',
		'modular_bluemoon/sound/emotes/cough_female_4.ogg',
		'modular_bluemoon/sound/emotes/cough_female_5.ogg',
		'modular_bluemoon/sound/emotes/cough_male_1.ogg',
		'modular_bluemoon/sound/emotes/cough_male_2.ogg',
		'modular_bluemoon/sound/emotes/cough_male_3.ogg',
		'modular_bluemoon/sound/emotes/cough_male_4.ogg',
		'modular_bluemoon/sound/emotes/cough_male_5.ogg',
		'modular_bluemoon/sound/emotes/dexter-song.ogg',
		'modular_bluemoon/sound/emotes/fart_1.ogg',
		'modular_bluemoon/sound/emotes/fart_2.ogg',
		'modular_bluemoon/sound/emotes/fart_3.ogg',
		'modular_bluemoon/sound/emotes/fart_4.ogg',
		'modular_bluemoon/sound/emotes/fart_5.ogg',
		'modular_bluemoon/sound/emotes/fart_6.ogg',
		'modular_bluemoon/sound/emotes/fart_7.ogg',
		'modular_bluemoon/sound/emotes/fart_8.ogg',
		'modular_bluemoon/sound/emotes/fart_9.ogg',
		'modular_bluemoon/sound/emotes/fart_uraj.ogg',
		'modular_bluemoon/sound/emotes/felinid_hiss.ogg',
		'modular_bluemoon/sound/emotes/gasp_female_1.ogg',
		'modular_bluemoon/sound/emotes/gasp_female_2.ogg',
		'modular_bluemoon/sound/emotes/gasp_female_3.ogg',
		'modular_bluemoon/sound/emotes/gasp_female_4.ogg',
		'modular_bluemoon/sound/emotes/gasp_female_5.ogg',
		'modular_bluemoon/sound/emotes/gasp_female_6.ogg',
		'modular_bluemoon/sound/emotes/gasp_male_1.ogg',
		'modular_bluemoon/sound/emotes/gasp_male_2.ogg',
		'modular_bluemoon/sound/emotes/gasp_male_3.ogg',
		'modular_bluemoon/sound/emotes/gasp_male_4.ogg',
		'modular_bluemoon/sound/emotes/gasp_male_5.ogg',
		'modular_bluemoon/sound/emotes/gasp_male_6.ogg',
		'modular_bluemoon/sound/emotes/giggle_female_1.ogg',
		'modular_bluemoon/sound/emotes/giggle_female_2.ogg',
		'modular_bluemoon/sound/emotes/hellogordon.ogg',
		'modular_bluemoon/sound/emotes/hey_female_1.ogg',
		'modular_bluemoon/sound/emotes/hey_female_2.ogg',
		'modular_bluemoon/sound/emotes/hey_male_1.ogg',
		'modular_bluemoon/sound/emotes/hey_male_2.ogg',
		'modular_bluemoon/sound/emotes/hi.ogg',
		'modular_bluemoon/sound/emotes/kweh1.ogg',
		'modular_bluemoon/sound/emotes/kweh2.ogg',
		'modular_bluemoon/sound/emotes/kweh3.ogg',
		'modular_bluemoon/sound/emotes/laugh_africanamericanmemberoflgbtq_1.ogg',
		'modular_bluemoon/sound/emotes/laugh_africanamericanmemberoflgbtq_2.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_1.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_2.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_3.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_4.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_5.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_6.ogg',
		'modular_bluemoon/sound/emotes/laugh_female_7.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_1.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_2.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_3.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_4.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_5.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_6.ogg',
		'modular_bluemoon/sound/emotes/laugh_male_7.ogg',
		'modular_bluemoon/sound/emotes/malf.ogg',
		'modular_bluemoon/sound/emotes/mar.ogg',
		'modular_bluemoon/sound/emotes/meow4.ogg',
		'modular_bluemoon/sound/emotes/meow5.ogg',
		'modular_bluemoon/sound/emotes/meow6.ogg',
		'modular_bluemoon/sound/emotes/meow7_1.ogg',
		'modular_bluemoon/sound/emotes/meow7_2.ogg',
		'modular_bluemoon/sound/emotes/meow7_3.ogg',
		'modular_bluemoon/sound/emotes/meow7_4.ogg',
		'modular_bluemoon/sound/emotes/meow7_5.ogg',
		'modular_bluemoon/sound/emotes/mrrps3.ogg',
		'modular_bluemoon/sound/emotes/mudak.ogg',
		'modular_bluemoon/sound/emotes/myassisheavy.ogg',
		'modular_bluemoon/sound/emotes/neigh.ogg',
		'modular_bluemoon/sound/emotes/ohyes.ogg',
		'modular_bluemoon/sound/emotes/oink1.ogg',
		'modular_bluemoon/sound/emotes/oink2.ogg',
		'modular_bluemoon/sound/emotes/oink3.ogg',
		'modular_bluemoon/sound/emotes/owl.ogg',
		'modular_bluemoon/sound/emotes/scream_female_1.ogg',
		'modular_bluemoon/sound/emotes/scream_female_2.ogg',
		'modular_bluemoon/sound/emotes/scream_female_3.ogg',
		'modular_bluemoon/sound/emotes/scream_female_4.ogg',
		'modular_bluemoon/sound/emotes/scream_male_1.ogg',
		'modular_bluemoon/sound/emotes/scream_male_2.ogg',
		'modular_bluemoon/sound/emotes/sigh_female.ogg',
		'modular_bluemoon/sound/emotes/sigh_male_1.ogg',
		'modular_bluemoon/sound/emotes/sigh_male_2.ogg',
		'modular_bluemoon/sound/emotes/sigh_male_3.ogg',
		'modular_bluemoon/sound/emotes/sigh_male_4.ogg',
		'modular_bluemoon/sound/emotes/skweh1.ogg',
		'modular_bluemoon/sound/emotes/skweh2.ogg',
		'modular_bluemoon/sound/emotes/snakedies.ogg',
		'modular_bluemoon/sound/emotes/sneeze_female_1.ogg',
		'modular_bluemoon/sound/emotes/sneeze_female_2.ogg',
		'modular_bluemoon/sound/emotes/sneeze_female_3.ogg',
		'modular_bluemoon/sound/emotes/sneeze_male_1.ogg',
		'modular_bluemoon/sound/emotes/sneeze_male_2.ogg',
		'modular_bluemoon/sound/emotes/sneeze_male_3.ogg',
		'modular_bluemoon/sound/emotes/snore_1.ogg',
		'modular_bluemoon/sound/emotes/snore_10.ogg',
		'modular_bluemoon/sound/emotes/snore_11.ogg',
		'modular_bluemoon/sound/emotes/snore_12.ogg',
		'modular_bluemoon/sound/emotes/snore_13.ogg',
		'modular_bluemoon/sound/emotes/snore_14.ogg',
		'modular_bluemoon/sound/emotes/snore_15.ogg',
		'modular_bluemoon/sound/emotes/snore_16.ogg',
		'modular_bluemoon/sound/emotes/snore_17.ogg',
		'modular_bluemoon/sound/emotes/snore_18.ogg',
		'modular_bluemoon/sound/emotes/snore_19.ogg',
		'modular_bluemoon/sound/emotes/snore_2.ogg',
		'modular_bluemoon/sound/emotes/snore_3.ogg',
		'modular_bluemoon/sound/emotes/snore_4.ogg',
		'modular_bluemoon/sound/emotes/snore_5.ogg',
		'modular_bluemoon/sound/emotes/snore_6.ogg',
		'modular_bluemoon/sound/emotes/snore_7.ogg',
		'modular_bluemoon/sound/emotes/snore_8.ogg',
		'modular_bluemoon/sound/emotes/snore_9.ogg',
		'modular_bluemoon/sound/emotes/snort.ogg',
		'modular_bluemoon/sound/emotes/softmoan1.ogg',
		'modular_bluemoon/sound/emotes/softmoan2.ogg',
		'modular_bluemoon/sound/emotes/softmoan3.ogg',
		'modular_bluemoon/sound/emotes/softmoan4.ogg',
		'modular_bluemoon/sound/emotes/softmoan5.ogg',
		'modular_bluemoon/sound/emotes/softmoan6.ogg',
		'modular_bluemoon/sound/emotes/squeal.ogg',
		'modular_bluemoon/sound/emotes/svist.ogg',
		'modular_bluemoon/sound/emotes/tsss.ogg',
		'modular_bluemoon/sound/emotes/worm.ogg',
		'modular_bluemoon/sound/ert/asset_protection_send.ogg',
		'modular_bluemoon/sound/ert/chechnya.ogg',
		'modular_bluemoon/sound/ert/combine_death.ogg',
		'modular_bluemoon/sound/ert/deathsquad_send_in.ogg',
		'modular_bluemoon/sound/ert/ert_firesquad_send.ogg',
		'modular_bluemoon/sound/ert/ert_heavysquad_send.ogg',
		'modular_bluemoon/sound/ert/ert_inq_send.ogg',
		'modular_bluemoon/sound/ert/ert_no.ogg',
		'modular_bluemoon/sound/ert/ert_rofl.ogg',
		'modular_bluemoon/sound/ert/ert_send.ogg',
		'modular_bluemoon/sound/ert/ert_tribunal.ogg',
		'modular_bluemoon/sound/ert/ert_yes.ogg',
		'modular_bluemoon/sound/ert/get_out.ogg',
		'modular_bluemoon/sound/ert/nri_send.ogg',
		'modular_bluemoon/sound/ert/Nuclear_Operations.ogg',
		'modular_bluemoon/sound/ert/rabbit_protocol.ogg',
		'modular_bluemoon/sound/ert/sergeant_dornan.ogg',
		'modular_bluemoon/sound/ert/sol_send.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing2.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing3.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinPrihodRing4.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinRing1.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinRing2.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/HeroinRing3.ogg',
		'modular_bluemoon/sound/hallucinations/heroin/PhotoFlash.ogg',
		'modular_bluemoon/sound/hallucinations/mdma/slowslippy.ogg',
		'modular_bluemoon/sound/hallucinations/shizoshroom/Gazeblya1.ogg',
		'modular_bluemoon/sound/hallucinations/shizoshroom/Gazeblya2.ogg',
		'modular_bluemoon/sound/hallucinations/shizoshroom/Gazeblya3.ogg',
		'modular_bluemoon/sound/hallucinations/shizoshroom/mechsound.ogg',
		'modular_bluemoon/sound/plush/allta_mew1.ogg',
		'modular_bluemoon/sound/plush/allta_mew2.ogg',
		'modular_bluemoon/sound/plush/allta_mew3.ogg',
		'modular_bluemoon/sound/plush/baka-cirno.ogg',
		'modular_bluemoon/sound/plush/bao_sex.ogg',
		'modular_bluemoon/sound/plush/bel1.ogg',
		'modular_bluemoon/sound/plush/bel2.ogg',
		'modular_bluemoon/sound/plush/Bloody Miner Plushie.ogg',
		'modular_bluemoon/sound/plush/Blue Ninja Plushie.ogg',
		'modular_bluemoon/sound/plush/catshark1.ogg',
		'modular_bluemoon/sound/plush/catshark2.ogg',
		'modular_bluemoon/sound/plush/Green Ninja Plushie.ogg',
		'modular_bluemoon/sound/plush/grunt-kill.ogg',
		'modular_bluemoon/sound/plush/jump.ogg',
		'modular_bluemoon/sound/plush/Koteyko_bad_smell.ogg',
		'modular_bluemoon/sound/plush/Koteyko_dicks_and_butts.ogg',
		'modular_bluemoon/sound/plush/Koteyko_rotting.ogg',
		'modular_bluemoon/sound/plush/leia_giggle.ogg',
		'modular_bluemoon/sound/plush/leia_nyah.ogg',
		'modular_bluemoon/sound/plush/leia_plan.ogg',
		'modular_bluemoon/sound/plush/manul1.ogg',
		'modular_bluemoon/sound/plush/manul2.ogg',
		'modular_bluemoon/sound/plush/milp1.ogg',
		'modular_bluemoon/sound/plush/milp2.ogg',
		'modular_bluemoon/sound/plush/milp3.ogg',
		'modular_bluemoon/sound/plush/milp4.ogg',
		'modular_bluemoon/sound/plush/milp5.ogg',
		'modular_bluemoon/sound/plush/milp6.ogg',
		'modular_bluemoon/sound/plush/milp7.ogg',
		'modular_bluemoon/sound/plush/Miner Plushie.ogg',
		'modular_bluemoon/sound/plush/miss.ogg',
		'modular_bluemoon/sound/plush/nekoark/burunya.ogg',
		'modular_bluemoon/sound/plush/nekoark/necoarc-1.ogg',
		'modular_bluemoon/sound/plush/nekoark/necoarc-2.ogg',
		'modular_bluemoon/sound/plush/nekoark/necoarc-3.ogg',
		'modular_bluemoon/sound/plush/nekoark/necoarc-4.ogg',
		'modular_bluemoon/sound/plush/nekoark/necoarc-5.ogg',
		'modular_bluemoon/sound/plush/nekoark/neco-arc-dori.ogg',
		'modular_bluemoon/sound/plush/nekoark/necoarc-nyeh.ogg',
		'modular_bluemoon/sound/plush/nova_lisa.ogg',
		'modular_bluemoon/sound/plush/nova_secret.ogg',
		'modular_bluemoon/sound/plush/nova_wi.ogg',
		'modular_bluemoon/sound/plush/ooh.ogg',
		'modular_bluemoon/sound/plush/Red Ninja Plushie.ogg',
		'modular_bluemoon/sound/plush/savepoint.ogg',
		'modular_bluemoon/sound/plush/security_1.ogg',
		'modular_bluemoon/sound/plush/security_2.ogg',
		'modular_bluemoon/sound/plush/tiamat_meow1.ogg',
		'modular_bluemoon/sound/plush/tiamat_meow2.ogg',
		'modular_bluemoon/sound/plush/tiamat_meow3.ogg',
		'modular_bluemoon/sound/plush/tiamat_mrrp1.ogg',
		'modular_bluemoon/sound/plush/tiamat_mrrp2.ogg',
		'modular_bluemoon/sound/plush/vinc_bleh.ogg',
		'modular_bluemoon/sound/plush/vinc_fahhh.ogg',
		'modular_bluemoon/sound/plush/vinc_fuck.ogg',
		'modular_bluemoon/sound/plush/zetta_hahaha.ogg',
		'modular_bluemoon/sound/plush/zetta_nya.ogg',
		'modular_bluemoon/sound/plush/zetta_redo.ogg',
		'modular_bluemoon/sound/plush/zlatchek.ogg',
		'modular_bluemoon/sound/voice/death_gasps/bandit1.ogg',
		'modular_bluemoon/sound/voice/death_gasps/bandit2.ogg',
		'modular_bluemoon/sound/voice/death_gasps/frank.ogg',
		'modular_bluemoon/sound/voice/death_gasps/mercenary.ogg',
		'modular_bluemoon/sound/voice/death_gasps/pig.ogg',
		'modular_bluemoon/sound/voice/death_gasps/pig2.ogg',
		'modular_bluemoon/sound/voice/death_gasps/richstalker.ogg',
		'modular_bluemoon/sound/voice/death_gasps/stalkerzombie.ogg',
		'modular_bluemoon/sound/voice/death_gasps/susie.ogg',
		// modular_bluemoon: voice/vox_sounds_alliance (*.wav)
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_anticitizenreport_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_anticivil1_5_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_anticivilevidence_3_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_capitalmalcompliance_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_ceaseevasionlevelfive_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_citizenshiprevoked_6_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_confirmcivilstatus_1_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_evasionbehavior_2_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_innactionisconspiracy_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_localunrest_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_protectionresponse_1_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_protectionresponse_4_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_protectionresponse_5_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_rationunitsdeduct_3_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_sociolevel1_4_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_trainstation_assemble_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_trainstation_assumepositions_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_trainstation_cooperation_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_trainstation_inform_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_trainstation_offworldrelocation_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/f_unrestprocedure1_spkr.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_10sectosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_15sectosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_1minutetosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_2minutestosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_30sectosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_3minutestosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_45sectosingularity.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_confiscating.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_confiscationfailure.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_deploy.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fcitadel_transportsequence.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_airwatchdispatched.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_contactlostlandsea.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_containexogens.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_deployinb4.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_deservicepoliticalconscripts.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_detectionsystemsout.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_dropforcesixandeight.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_exogenbreach.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_freemanlocated.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_interfacebypass.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_missionfailurereminder.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_nonstandardexogen.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_perimeterrestrictors.wav',
		'modular_bluemoon/sound/voice/vox_sounds_alliance/fprison_restrictorsdisengaged.wav',
	))

/**
# assoc list of datum by key
* k = SFX_KEY (see below)
* v = singleton sound_effect datum ref
* initialized in SSsounds init
*/
GLOBAL_LIST_EMPTY(sfx_datum_by_key)

/* List of all of our sound keys.
	used with /datum/sound_effect as the key
	see code\game\sound_keys.dm
*/

#define SFX_SHATTER "shatter"
#define SFX_EXPLOSION "explosion"
#define SFX_EXPLOSION_CREAKING "explosion_creaking"
#define SFX_HULL_CREAKING "hull_creaking"
#define SFX_SPARKS "sparks"
#define SFX_RUSTLE "rustle"
#define SFX_BODYFALL "bodyfall"
#define SFX_PUNCH "punch"
#define SFX_CLOWN_STEP "clownstep"
#define SFX_SUIT_STEP "suitstep"
#define SFX_SWING_HIT "swing_hit"
#define SFX_HISS "hiss"
#define SFX_PAGE_TURN "pageturn"
#define SFX_GUNSHOT "gunshot"
#define SFX_RICOCHET "ricochet"
#define SFX_TERMINAL_TYPE "terminal_type"
#define SFX_DESECRATION "desceration"
#define SFX_IM_HERE "im_here"
#define SFX_CAN_OPEN "can_open"
#define SFX_BULLET_MISS "bullet_miss"
#define SFX_GUN_DRY_FIRE "gun_dry_fire"
#define SFX_GUN_INSERT_EMPTY_MAGAZINE "gun_insert_empty_magazine"
#define SFX_GUN_INSERT_FULL_MAGAZINE "gun_insert_full_magazine"
#define SFX_GUN_REMOVE_EMPTY_MAGAZINE "gun_remove_empty_magazine"
#define SFX_GUN_SLIDE_LOCK "gun_slide_lock"
#define SFX_LAW "law"
#define SFX_HONKBOT_E "honkbot_e"
#define SFX_GOOSE "goose"
#define SFX_WATER_WADE "water_wade"
#define SFX_VORE_STRUGGLE "struggle_sound"
#define SFX_VORE_PREY_STRUGGLE "prey_struggle"
#define SFX_VORE_DIGEST_PRED "digest_pred"
#define SFX_VORE_DEATH_PRED "death_pred"
#define SFX_VORE_DIGEST_PREY "digest_prey"
#define SFX_VORE_DEATH_PREY "death_prey"
#define SFX_VORE_HUNGER "hunger_sounds"
#define SFX_CLANG "clang"
#define SFX_CLANGSMALL "clangsmall"
#define SFX_SLOSH "slosh"
#define SFX_SMCALM "smcalm"
#define SFX_SMDELAM "smdelam"
#define SFX_DRAWER_OPEN "drawer_open"
#define SFX_DRAWER_CLOSE "drawer_close"
#define SFX_ROLLING_PIN_ROLLING "rolling_pin_rolling"
#define SFX_KNIFE_SLICE "knife_slice"
