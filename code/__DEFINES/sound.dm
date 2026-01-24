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

//THIS SHOULD ALWAYS BE THE LOWEST ONE!
//KEEP IT UPDATED

#define CHANNEL_HIGHEST_AVAILABLE 992 //CIT CHANGE - COMPENSATES FOR VORESOUND CHANNELS

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
										'sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg', 'sound/ambience/ambiviro.ogg', 'sound/ambience/ambistalker.ogg')

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
	"Свинья" =				'modular_bluemoon/SmiLeY/code/mob/pig/death.ogg',
	"Офицер ГО" =			'modular_bluemoon/SmiLeY/sounds/combine_death.ogg',
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
