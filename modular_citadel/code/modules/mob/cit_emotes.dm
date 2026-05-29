#define INSULTS_FILE "insult.json"

/mob
	var/nextsoundemote = 1 SECONDS

/datum/emote/sound/human/insult
	key = "insult"
	key_third_person = "insults"
	message = "изрыгает оскорбления."
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/insult/run_emote(mob/living/user, params)
	if(user.mind?.miming)
		message = "творчески жестикулирует."
	else if(!user.is_muzzled())
		message = pick_list_replacements(INSULTS_FILE, "insult_gen")
	else
		message = "заглушает свои же слова своей кистью."
	. = ..()

/datum/emote/sound/human/scream/run_emote(mob/living/user, params) //I can't not port this shit, come on.
	if(user.stat != CONSCIOUS)
		return
	var/sound
	var/miming = user.mind ? user.mind.miming : 0
	if(iscarbon(user))
		var/mob/living/carbon/c = user
		c.reindex_screams()
	if(!user.is_muzzled() && !miming)
		if(issilicon(user))
			sound = 'modular_citadel/sound/voice/scream_silicon.ogg'
			if(iscyborg(user))
				var/mob/living/silicon/robot/S = user
				if(S.cell?.charge < 20)
					to_chat(S, "<span class='warning'>Модуль крика деактивирован. Пожалуйста, перезарядитесь.</span>")
					return
				S.cell.use(200)
		if(ismonkey(user))
			sound = 'modular_citadel/sound/voice/scream_monkey.ogg'
		if(istype(user, /mob/living/simple_animal/hostile/gorilla))
			sound = 'sound/creatures/gorilla.ogg'
		if(ishuman(user))
			user.adjustOxyLoss(5)
			if(user.gender != FEMALE && !(user.gender == PLURAL && isfeminine(user)))
				sound = pick('modular_citadel/sound/voice/scream_m1.ogg', 'modular_citadel/sound/voice/scream_m2.ogg')
			else
				sound = pick('modular_citadel/sound/voice/scream_f1.ogg', 'modular_citadel/sound/voice/scream_f2.ogg')
			if(is_species(user, /datum/species/jelly))
				if(user.gender == FEMALE || (user.gender == PLURAL && isfeminine(user)))
					sound = pick('modular_citadel/sound/voice/scream_jelly_f1.ogg', 'modular_citadel/sound/voice/scream_jelly_f2.ogg')
				else
					sound = pick('modular_citadel/sound/voice/scream_jelly_m1.ogg', 'modular_citadel/sound/voice/scream_jelly_m2.ogg')
			if(is_species(user, /datum/species/android) || is_species(user, /datum/species/synth) || is_species(user, /datum/species/ipc))
				sound = 'modular_citadel/sound/voice/scream_silicon.ogg'
			if(is_species(user, /datum/species/lizard))
				sound = 'modular_citadel/sound/voice/scream_lizard.ogg'
			if(is_species(user, /datum/species/skeleton))
				sound = 'modular_citadel/sound/voice/scream_skeleton.ogg'
			if (is_species(user, /datum/species/fly) || is_species(user, /datum/species/insect))
				sound = 'modular_citadel/sound/voice/scream_moth.ogg'
			if(is_species(user, /datum/species/mammal/vox))
				sound = 'modular_bluemoon/kovac_shitcode/sound/species/voxscream.ogg'
			// BLUEMOON ADD START - xenohybrids_improvements - вариация крика для ксеногибридов (АДАМ, ПЕРЕПИШИ ГОВНОКОД СВЕРХУ, ПОЖАЛУЙСТА)
			if(is_species(user, /datum/species/xeno))
				sound = pick('sound/alien/Voice/hurt1.ogg', 'sound/alien/Voice/hurt2.ogg')
			// BLUEMOON ADD END
		if(isalien(user))
			sound = 'sound/voice/hiss6.ogg'
		LAZYINITLIST(user.alternate_screams)
		if(LAZYLEN(user.alternate_screams))
			sound = pick(user.alternate_screams)
		playsound(user.loc, sound, 75, 1, 4, 1.2)
		message = "кричит!"
	else if(miming)
		message = "изображает громкий крик."
	else
		message = "издает очень громкий звук."
	. = ..()

/datum/emote/sound/human/snap
	name = "Щелкнуть Пальцами"
	key = "snap"
	key_third_person = "snaps"
	message = "щёлкает пальцами."
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = TRUE
	restraint_check = TRUE
	emote_pitch_variance = FALSE
	sound = 'modular_citadel/sound/voice/snap.ogg'

/datum/emote/sound/human/snap2
	name = "Пару раз Щёлкнуть Пальцами"
	key = "snap2"
	key_third_person = "snaps2"
	name = "snap twice"
	message = "щёлкает пальцами дважды."
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = TRUE
	restraint_check = TRUE
	emote_pitch_variance = FALSE
	sound = 'modular_citadel/sound/voice/snap2.ogg'

/datum/emote/sound/human/snap3
	name = "Трижды Щёлкнуть Пальцами"
	key = "snap3"
	key_third_person = "snaps thrice"
	name = "snap thrice"
	message = "щёлкает пальцами трижды."
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = TRUE
	restraint_check = TRUE
	emote_pitch_variance = FALSE
	sound = 'modular_citadel/sound/voice/snap3.ogg'

/datum/emote/sound/human/awoo
	name = "Выть"
	key = "awoo"
	key_third_person = "lets out an awoo"
	message = "воет!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/awoo.ogg'

/datum/emote/sound/human/hiss
	name = "Шипеть"
	key = "hiss"
	key_third_person = "hisses"
	message = "шипит!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/hiss.ogg'

/datum/emote/sound/human/hiss/run_emote(mob/user, params)
	if(isalienadult(user))
		sound = sound(get_sfx("hiss"))
	else if(iscatperson(user))
		sound = 'modular_bluemoon/sound/emotes/felinid_hiss.ogg'
	else
		sound = initial(sound)
	. = ..()

/datum/emote/sound/human/purr
	name = "Мурчать"
	key = "purr"
	key_third_person = "purrs softly"
	message = "мягко мурлычет."
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/purr.ogg'

/datum/emote/sound/human/nya
	key = "nya"
	key_third_person = "lets out a nya"
	message = "мяучит!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/nya.ogg'

/datum/emote/sound/human/weh
	name = "Вех"
	key = "weh"
	key_third_person = "lets out a weh"
	message = "издаёт ВЕХ!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/weh.ogg'

/datum/emote/sound/human/peep
	name = "Пискнуть по-птичьи 1"
	key = "peep"
	key_third_person = "peeps like a bird"
	message = "чирикает!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/peep.ogg'

/datum/emote/sound/human/dab
	key = "dab"
	key_third_person = "suddenly hits a dab"
	message = "делает жесточайший ДЕБ!"
	emote_type = EMOTE_AUDIBLE
	restraint_check = TRUE

/datum/emote/sound/human/mothsqueak
	name = "Пищать словно Крыска"
	key = "msqueak"
	key_third_person = "lets out a tiny squeak"
	message = "пищит!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'modular_citadel/sound/voice/mothsqueak.ogg'

/datum/emote/sound/human/merp
	key = "merp"
	key_third_person = "merps"
	message = "мёрпает!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	emote_cooldown = 0.6 SECONDS
	sound = 'modular_citadel/sound/voice/merp.ogg'

/datum/emote/sound/human/bark
	key = "bark"
	key_third_person = "barks"
	message = "гафкает!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	emote_cooldown = 0.6 SECONDS

/datum/emote/sound/human/bark/run_emote(mob/user, params)
	sound = pick('modular_citadel/sound/voice/bark1.ogg', 'modular_citadel/sound/voice/bark2.ogg')
	. = ..()

/datum/emote/sound/human/squish
	name = "Хлюпать"
	key = "squish"
	key_third_person = "squishes"
	message = "сквишает!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	sound = 'sound/voice/slime_squish.ogg'

/datum/emote/sound/human/squish/run_emote(mob/user, params)
	sound = pick('sound/voice/slime_squish.ogg', 'sound/voice/squish.ogg')
	. = ..()

/datum/emote/sound/human/pain
	key = "pain"
	key_third_person = "cries out in pain!"
	message = "кричит от боли!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	emote_pitch_variance = FALSE

/datum/emote/sound/human/pain/run_emote(mob/user, params)
	if(user.gender != FEMALE && !(user.gender == PLURAL && isfeminine(user)))
		sound = pick('modular_citadel/sound/voice/human_male_pain_1.ogg', 'modular_citadel/sound/voice/human_male_pain_2.ogg', 'modular_citadel/sound/voice/human_male_pain_3.ogg', 'modular_citadel/sound/voice/human_male_pain_rare.ogg', 'modular_citadel/sound/voice/human_male_scream_1.ogg', 'modular_citadel/sound/voice/human_male_scream_2.ogg', 'modular_citadel/sound/voice/human_male_scream_3.ogg', 'modular_citadel/sound/voice/human_male_scream_4.ogg')
	else
		sound = pick('modular_citadel/sound/voice/human_female_pain_1.ogg', 'modular_citadel/sound/voice/human_female_pain_2.ogg', 'modular_citadel/sound/voice/human_female_pain_3.ogg', 'modular_citadel/sound/voice/human_female_scream_2.ogg', 'modular_citadel/sound/voice/human_female_scream_3.ogg', 'modular_citadel/sound/voice/human_female_scream_4.ogg')
	. = ..()

/datum/emote/sound/human/clap1
	name = "Единично хлопнуть"
	key = "clap1"
	key_third_person = "clap1s"
	name = "clap once"
	message = "хлопает."
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = TRUE
	restraint_check = TRUE
	sound = 'modular_citadel/sound/voice/clap.ogg'
