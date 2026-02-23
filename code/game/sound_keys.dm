/**
# sound_effect datum
* use for when you need multiple sound files to play at random in a playsound
* see var documentation below
* initialized and added to sfx_datum_by_key in /datum/controller/subsystem/sounds/init_sound_keys()
*/
/datum/sound_effect
	/// sfx key define with which we are associated with, see code\__DEFINES\sound.dm
	var/key
	/// list of paths to our files, use the /assoc subtype if your paths are weighted
	var/list/file_paths

/datum/sound_effect/proc/return_sfx()
	return pick(file_paths)

/datum/sound_effect/shatter
	key = SFX_SHATTER
	file_paths = list(
		'sound/effects/glassbr1.ogg',
		'sound/effects/glassbr2.ogg',
		'sound/effects/glassbr3.ogg'
	)

/datum/sound_effect/explosion
	key = SFX_EXPLOSION
	file_paths = list(
		'sound/effects/explosion1.ogg',
		'sound/effects/explosion2.ogg'
	)

/datum/sound_effect/explosion_creaking
	key = SFX_EXPLOSION_CREAKING
	file_paths = list(
		'sound/effects/explosioncreak1.ogg',
		'sound/effects/explosioncreak2.ogg'
	)

/datum/sound_effect/hull_creaking
	key = SFX_HULL_CREAKING
	file_paths = list(
		'sound/effects/creak1.ogg',
		'sound/effects/creak2.ogg',
		'sound/effects/creak3.ogg'
	)

/datum/sound_effect/sparks
	key = SFX_SPARKS
	file_paths = list(
		'sound/effects/sparks1.ogg',
		'sound/effects/sparks2.ogg',
		'sound/effects/sparks3.ogg',
		'sound/effects/sparks4.ogg'
	)

/datum/sound_effect/rustle
	key = SFX_RUSTLE
	file_paths = list(
		'sound/effects/rustle1.ogg',
		'sound/effects/rustle2.ogg',
		'sound/effects/rustle3.ogg',
		'sound/effects/rustle4.ogg',
		'sound/effects/rustle5.ogg'
	)

/datum/sound_effect/bodyfall
	key = SFX_BODYFALL
	file_paths = list(
		'sound/effects/bodyfall1.ogg',
		'sound/effects/bodyfall2.ogg',
		'sound/effects/bodyfall3.ogg',
		'sound/effects/bodyfall4.ogg'
	)

/datum/sound_effect/punch
	key = SFX_PUNCH
	file_paths = list(
		'sound/weapons/punch1.ogg',
		'sound/weapons/punch2.ogg',
		'sound/weapons/punch3.ogg',
		'sound/weapons/punch4.ogg'
	)

/datum/sound_effect/clown_step
	key = SFX_CLOWN_STEP
	file_paths = list(
		'sound/effects/clownstep1.ogg',
		'sound/effects/clownstep2.ogg'
	)

/datum/sound_effect/suit_step
	key = SFX_SUIT_STEP
	file_paths = list(
		'sound/effects/suitstep1.ogg',
		'sound/effects/suitstep2.ogg'
	)

/datum/sound_effect/swing_hit
	key = SFX_SWING_HIT
	file_paths = list(
		'sound/weapons/genhit1.ogg',
		'sound/weapons/genhit2.ogg',
		'sound/weapons/genhit3.ogg'
	)

/datum/sound_effect/hiss
	key = SFX_HISS
	file_paths = list(
		'sound/voice/hiss1.ogg',
		'sound/voice/hiss2.ogg',
		'sound/voice/hiss3.ogg',
		'sound/voice/hiss4.ogg'
	)

/datum/sound_effect/page_turn
	key = SFX_PAGE_TURN
	file_paths = list(
		'sound/effects/pageturn1.ogg',
		'sound/effects/pageturn2.ogg',
		'sound/effects/pageturn3.ogg'
	)

/datum/sound_effect/gunshot
	key = SFX_GUNSHOT
	file_paths = list(
		'sound/weapons/gunshot.ogg',
		'sound/weapons/gunshot2.ogg',
		'sound/weapons/gunshot3.ogg',
		'sound/weapons/gunshot4.ogg'
	)

/datum/sound_effect/ricochet
	key = SFX_RICOCHET
	file_paths = list(
		'sound/weapons/effects/ric1.ogg',
		'sound/weapons/effects/ric2.ogg',
		'sound/weapons/effects/ric3.ogg',
		'sound/weapons/effects/ric4.ogg',
		'sound/weapons/effects/ric5.ogg'
	)

/datum/sound_effect/terminal_type
	key = SFX_TERMINAL_TYPE
	file_paths = list(
		'sound/machines/terminal_button01.ogg',
		'sound/machines/terminal_button02.ogg',
		'sound/machines/terminal_button03.ogg',
		'sound/machines/terminal_button04.ogg',
		'sound/machines/terminal_button05.ogg',
		'sound/machines/terminal_button06.ogg',
		'sound/machines/terminal_button07.ogg',
		'sound/machines/terminal_button08.ogg'
	)

/datum/sound_effect/desecration
	key = SFX_DESECRATION
	file_paths = list(
		'sound/misc/desceration-01.ogg',
		'sound/misc/desceration-02.ogg',
		'sound/misc/desceration-03.ogg'
	)

/datum/sound_effect/im_here
	key = SFX_IM_HERE
	file_paths = list(
		'sound/hallucinations/im_here1.ogg',
		'sound/hallucinations/im_here2.ogg'
	)

/datum/sound_effect/can_open
	key = SFX_CAN_OPEN
	file_paths = list(
		'sound/effects/can_open1.ogg',
		'sound/effects/can_open2.ogg',
		'sound/effects/can_open3.ogg'
	)

/datum/sound_effect/bullet_miss
	key = SFX_BULLET_MISS
	file_paths = list(
		'sound/weapons/bulletflyby.ogg',
		'sound/weapons/bulletflyby2.ogg',
		'sound/weapons/bulletflyby3.ogg'
	)

/datum/sound_effect/gun_dry_fire
	key = SFX_GUN_DRY_FIRE
	file_paths = list(
		'sound/weapons/gun_dry_fire_1.ogg',
		'sound/weapons/gun_dry_fire_2.ogg',
		'sound/weapons/gun_dry_fire_3.ogg',
		'sound/weapons/gun_dry_fire_4.ogg'
	)
/datum/sound_effect/gun_insert_empty_magazine
	key = SFX_GUN_INSERT_EMPTY_MAGAZINE
	file_paths = list(
		'sound/weapons/gun_magazine_insert_empty_1.ogg',
		'sound/weapons/gun_magazine_insert_empty_2.ogg',
		'sound/weapons/gun_magazine_insert_empty_3.ogg',
		'sound/weapons/gun_magazine_insert_empty_4.ogg'
	)
/datum/sound_effect/gun_insert_full_magazine
	key = SFX_GUN_INSERT_FULL_MAGAZINE
	file_paths = list(
	'sound/weapons/gun_magazine_insert_full_1.ogg',
	'sound/weapons/gun_magazine_insert_full_2.ogg',
	'sound/weapons/gun_magazine_insert_full_3.ogg',
	'sound/weapons/gun_magazine_insert_full_4.ogg',
	'sound/weapons/gun_magazine_insert_full_5.ogg'
	)
/datum/sound_effect/gun_remove_empty_magazine
	key = SFX_GUN_REMOVE_EMPTY_MAGAZINE
	file_paths = list(
		'sound/weapons/gun_magazine_remove_empty_1.ogg',
		'sound/weapons/gun_magazine_remove_empty_2.ogg',
		'sound/weapons/gun_magazine_remove_empty_3.ogg',
		'sound/weapons/gun_magazine_remove_empty_4.ogg'
	)
/datum/sound_effect/gun_slide_lock
	key = SFX_GUN_SLIDE_LOCK
	file_paths = list(
		'sound/weapons/gun_slide_lock_1.ogg',
		'sound/weapons/gun_slide_lock_2.ogg',
		'sound/weapons/gun_slide_lock_3.ogg',
		'sound/weapons/gun_slide_lock_4.ogg',
		'sound/weapons/gun_slide_lock_5.ogg'
	)
/datum/sound_effect/law
	key = SFX_LAW
	file_paths = list(
		'sound/voice/beepsky/god.ogg',
		'sound/voice/beepsky/iamthelaw.ogg',
		'sound/voice/beepsky/secureday.ogg',
		'sound/voice/beepsky/radio.ogg',
		'sound/voice/beepsky/insult.ogg',
		'sound/voice/beepsky/creep.ogg'
	)
/datum/sound_effect/honkbot_e
	key = SFX_HONKBOT_E
	file_paths = list(
		'sound/items/bikehorn.ogg',
		'sound/items/AirHorn2.ogg',
		'sound/misc/sadtrombone.ogg',
		'sound/items/AirHorn.ogg',
		'sound/effects/reee.ogg',
		'sound/items/WEEOO1.ogg',
		'sound/voice/beepsky/iamthelaw.ogg',
		'sound/voice/beepsky/creep.ogg',
		'sound/magic/Fireball.ogg',
		'sound/effects/pray.ogg',
		'sound/voice/hiss1.ogg',
		'sound/machines/buzz-sigh.ogg',
		'sound/machines/ping.ogg',
		'sound/weapons/flashbang.ogg',
		'sound/weapons/bladeslice.ogg'
	)
/datum/sound_effect/goose
	key = SFX_GOOSE
	file_paths = list(
		'sound/creatures/goose1.ogg',
		'sound/creatures/goose2.ogg',
		'sound/creatures/goose3.ogg',
		'sound/creatures/goose4.ogg'
	)
/datum/sound_effect/water_wade
	key = SFX_WATER_WADE
	file_paths = list(
		'sound/effects/water_wade1.ogg',
		'sound/effects/water_wade2.ogg',
		'sound/effects/water_wade3.ogg',
		'sound/effects/water_wade4.ogg'
	)

/datum/sound_effect/struggle_sound
	key = SFX_VORE_STRUGGLE
	file_paths = list(
		'sound/vore/pred/struggle_01.ogg',
		'sound/vore/pred/struggle_02.ogg',
		'sound/vore/pred/struggle_03.ogg',
		'sound/vore/pred/struggle_04.ogg',
		'sound/vore/pred/struggle_05.ogg'
	)
/datum/sound_effect/prey_struggle
	key = SFX_VORE_PREY_STRUGGLE
	file_paths = list(
		'sound/vore/prey/struggle_01.ogg',
		'sound/vore/prey/struggle_02.ogg',
		'sound/vore/prey/struggle_03.ogg',
		'sound/vore/prey/struggle_04.ogg',
		'sound/vore/prey/struggle_05.ogg'
	)
/datum/sound_effect/digest_pred
	key = SFX_VORE_DIGEST_PRED
	file_paths = list(
		'sound/vore/pred/digest_01.ogg',
		'sound/vore/pred/digest_02.ogg',
		'sound/vore/pred/digest_03.ogg',
		'sound/vore/pred/digest_04.ogg',
		'sound/vore/pred/digest_05.ogg',
		'sound/vore/pred/digest_06.ogg',
		'sound/vore/pred/digest_07.ogg',
		'sound/vore/pred/digest_08.ogg',
		'sound/vore/pred/digest_09.ogg',
		'sound/vore/pred/digest_10.ogg',
		'sound/vore/pred/digest_11.ogg',
		'sound/vore/pred/digest_12.ogg',
		'sound/vore/pred/digest_13.ogg',
		'sound/vore/pred/digest_14.ogg',
		'sound/vore/pred/digest_15.ogg',
		'sound/vore/pred/digest_16.ogg',
		'sound/vore/pred/digest_17.ogg',
		'sound/vore/pred/digest_18.ogg'
	)
/datum/sound_effect/death_pred
	key = SFX_VORE_DEATH_PRED
	file_paths = list(
		'sound/vore/pred/death_01.ogg',
		'sound/vore/pred/death_02.ogg',
		'sound/vore/pred/death_03.ogg',
		'sound/vore/pred/death_04.ogg',
		'sound/vore/pred/death_05.ogg',
		'sound/vore/pred/death_06.ogg',
		'sound/vore/pred/death_07.ogg',
		'sound/vore/pred/death_08.ogg',
		'sound/vore/pred/death_09.ogg',
		'sound/vore/pred/death_10.ogg'
	)
/datum/sound_effect/digest_prey
	key = SFX_VORE_DIGEST_PREY
	file_paths = list(
		'sound/vore/prey/digest_01.ogg',
		'sound/vore/prey/digest_02.ogg',
		'sound/vore/prey/digest_03.ogg',
		'sound/vore/prey/digest_04.ogg',
		'sound/vore/prey/digest_05.ogg',
		'sound/vore/prey/digest_06.ogg',
		'sound/vore/prey/digest_07.ogg',
		'sound/vore/prey/digest_08.ogg',
		'sound/vore/prey/digest_09.ogg',
		'sound/vore/prey/digest_10.ogg',
		'sound/vore/prey/digest_11.ogg',
		'sound/vore/prey/digest_12.ogg',
		'sound/vore/prey/digest_13.ogg',
		'sound/vore/prey/digest_14.ogg',
		'sound/vore/prey/digest_15.ogg',
		'sound/vore/prey/digest_16.ogg',
		'sound/vore/prey/digest_17.ogg',
		'sound/vore/prey/digest_18.ogg')
/datum/sound_effect/death_prey
	key = SFX_VORE_DEATH_PREY
	file_paths = list(
		'sound/vore/prey/death_01.ogg',
		'sound/vore/prey/death_02.ogg',
		'sound/vore/prey/death_03.ogg',
		'sound/vore/prey/death_04.ogg',
		'sound/vore/prey/death_05.ogg',
		'sound/vore/prey/death_06.ogg',
		'sound/vore/prey/death_07.ogg',
		'sound/vore/prey/death_08.ogg',
		'sound/vore/prey/death_09.ogg',
		'sound/vore/prey/death_10.ogg'
	)
/datum/sound_effect/hunger_sounds
	key = SFX_VORE_HUNGER
	file_paths = list(
		'sound/vore/growl1.ogg',
		'sound/vore/growl2.ogg',
		'sound/vore/growl3.ogg',
		'sound/vore/growl4.ogg',
		'sound/vore/growl5.ogg'
	)
/datum/sound_effect/clang
	key = SFX_CLANG
	file_paths = list(
		'sound/effects/clang1.ogg',
		'sound/effects/clang2.ogg'
	)
/datum/sound_effect/clangsmall
	key = SFX_CLANGSMALL
	file_paths = list(
		'sound/effects/clangsmall1.ogg',
		'sound/effects/clangsmall2.ogg'
	)
/datum/sound_effect/slosh
	key = SFX_SLOSH
	file_paths = list(
		'sound/effects/slosh1.ogg',
		'sound/effects/slosh2.ogg'
	)
/datum/sound_effect/smcalm
	key = SFX_SMCALM
	file_paths = list(
		'sound/machines/sm/accent/normal/1.ogg',
		'sound/machines/sm/accent/normal/2.ogg',
		'sound/machines/sm/accent/normal/3.ogg',
		'sound/machines/sm/accent/normal/4.ogg',
		'sound/machines/sm/accent/normal/5.ogg',
		'sound/machines/sm/accent/normal/6.ogg',
		'sound/machines/sm/accent/normal/7.ogg',
		'sound/machines/sm/accent/normal/8.ogg',
		'sound/machines/sm/accent/normal/9.ogg',
		'sound/machines/sm/accent/normal/10.ogg',
		'sound/machines/sm/accent/normal/11.ogg',
		'sound/machines/sm/accent/normal/12.ogg',
		'sound/machines/sm/accent/normal/13.ogg',
		'sound/machines/sm/accent/normal/14.ogg',
		'sound/machines/sm/accent/normal/15.ogg',
		'sound/machines/sm/accent/normal/16.ogg',
		'sound/machines/sm/accent/normal/17.ogg',
		'sound/machines/sm/accent/normal/18.ogg',
		'sound/machines/sm/accent/normal/19.ogg',
		'sound/machines/sm/accent/normal/20.ogg',
		'sound/machines/sm/accent/normal/21.ogg',
		'sound/machines/sm/accent/normal/22.ogg',
		'sound/machines/sm/accent/normal/23.ogg',
		'sound/machines/sm/accent/normal/24.ogg',
		'sound/machines/sm/accent/normal/25.ogg',
		'sound/machines/sm/accent/normal/26.ogg',
		'sound/machines/sm/accent/normal/27.ogg',
		'sound/machines/sm/accent/normal/28.ogg',
		'sound/machines/sm/accent/normal/29.ogg',
		'sound/machines/sm/accent/normal/30.ogg',
		'sound/machines/sm/accent/normal/31.ogg',
		'sound/machines/sm/accent/normal/32.ogg',
		'sound/machines/sm/accent/normal/33.ogg')

/datum/sound_effect/smdelam
	key = SFX_SMDELAM
	file_paths = list(
		'sound/machines/sm/accent/delam/1.ogg',
		'sound/machines/sm/accent/delam/2.ogg',
		'sound/machines/sm/accent/delam/3.ogg',
		'sound/machines/sm/accent/delam/4.ogg',
		'sound/machines/sm/accent/delam/5.ogg',
		'sound/machines/sm/accent/delam/6.ogg',
		'sound/machines/sm/accent/delam/7.ogg',
		'sound/machines/sm/accent/delam/8.ogg',
		'sound/machines/sm/accent/delam/9.ogg',
		'sound/machines/sm/accent/delam/10.ogg',
		'sound/machines/sm/accent/delam/11.ogg',
		'sound/machines/sm/accent/delam/12.ogg',
		'sound/machines/sm/accent/delam/13.ogg',
		'sound/machines/sm/accent/delam/14.ogg',
		'sound/machines/sm/accent/delam/15.ogg',
		'sound/machines/sm/accent/delam/16.ogg',
		'sound/machines/sm/accent/delam/17.ogg',
		'sound/machines/sm/accent/delam/18.ogg',
		'sound/machines/sm/accent/delam/19.ogg',
		'sound/machines/sm/accent/delam/20.ogg',
		'sound/machines/sm/accent/delam/21.ogg',
		'sound/machines/sm/accent/delam/22.ogg',
		'sound/machines/sm/accent/delam/23.ogg',
		'sound/machines/sm/accent/delam/24.ogg',
		'sound/machines/sm/accent/delam/25.ogg',
		'sound/machines/sm/accent/delam/26.ogg',
		'sound/machines/sm/accent/delam/27.ogg',
		'sound/machines/sm/accent/delam/28.ogg',
		'sound/machines/sm/accent/delam/29.ogg',
		'sound/machines/sm/accent/delam/30.ogg',
		'sound/machines/sm/accent/delam/31.ogg',
		'sound/machines/sm/accent/delam/32.ogg',
		'sound/machines/sm/accent/delam/33.ogg')

/datum/sound_effect/drawer_open
	key = SFX_DRAWER_OPEN
	file_paths = list(
		'modular_sand/sound/misc/drawer_open1.ogg',
		'modular_sand/sound/misc/drawer_open2.ogg'
	)
/datum/sound_effect/drawer_close
	key = SFX_DRAWER_CLOSE
	file_paths = list(
		'modular_sand/sound/misc/drawer_close.ogg'
	)

/datum/sound_effect/rolling_pin_rolling
	key = SFX_ROLLING_PIN_ROLLING
	file_paths = list(
		'sound/items/rolling_pin/rolling_pin_rolling1.ogg',
		'sound/items/rolling_pin/rolling_pin_rolling2.ogg',
		'sound/items/rolling_pin/rolling_pin_rolling3.ogg',
		'sound/items/rolling_pin/rolling_pin_rolling4.ogg',
		'sound/items/rolling_pin/rolling_pin_rolling5.ogg',
		'sound/items/rolling_pin/rolling_pin_rolling6.ogg',
	)

/datum/sound_effect/knife_slice
	key = SFX_KNIFE_SLICE
	file_paths = list(
		'sound/items/knife/knife_slice1.ogg',
		'sound/items/knife/knife_slice2.ogg',
		'sound/items/knife/knife_slice3.ogg',
		'sound/items/knife/knife_slice4.ogg',
		'sound/items/knife/knife_slice5.ogg',
		'sound/items/knife/knife_slice6.ogg'
	)
