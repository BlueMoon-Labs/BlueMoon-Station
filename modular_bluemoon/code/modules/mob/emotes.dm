/datum/emote/sound/human/growl
	name = "Рычать"
	key = "growl"
	key_third_person = "growl"
	message = "рычит!"
	message_mime = "безмолвно рычит."
	sound = 'sound/voice/growl.ogg'
	emote_cooldown = 4 SECONDS

/datum/emote/sound/human/trills
	key = "trills"
	key_third_person = "trills"
	message = "издаёт трель!"
	message_mime = "изображает трель."
	sound = 'sound/voice/trills.ogg'
	emote_cooldown = 4 SECONDS

/datum/emote/sound/human/woof
	key = "woof"
	key_third_person = "woofs"
	message = "вуфает."
	message_mime = "изображает вуфанье."
	sound = 'sound/voice/woof.ogg'

/datum/emote/sound/human/cloaker1
	name = "Агрессивное Приближение!"
	key = "cloaker"
	key_third_person = "cloaker"
	message = "агрессивно приближается."
	message_mime = null
	sound = 'sound/voice/cloaker1.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/cloaker2
	name = "Не бей себя!"
	key = "cloaker2"
	key_third_person = "cloaker2"
	message = "даёт прямое требование перестать себя бить."
	message_mime = null
	sound = 'sound/voice/cloaker2.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/cloaker3
	name = "Причина Ареста"
	key = "cloaker3"
	key_third_person = "cloaker3"
	message = "объясняет причину задержания."
	message_mime = null
	sound = 'sound/voice/cloaker3.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/cloaker4
	name = "Безопасное Слово"
	key = "cloaker4"
	key_third_person = "cloaker4"
	message = "одобряет Стоп Слово."
	message_mime = null
	sound = 'sound/voice/cloaker4.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/cluwne
	name = "Мерзко смеяться"
	key = "cluwne"
	key_third_person = "cluwnes"
	message = "клоуничает; ужасно плохо смеётся..."
	message_mime = null
	sound = 'sound/voice/cluwnelaugh1.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/cluwne/run_emote(mob/user, params)
	// Set random emote sound
	sound = pick('sound/voice/cluwnelaugh1.ogg', 'sound/voice/cluwnelaugh2.ogg', 'sound/voice/cluwnelaugh3.ogg')

	// Return normally
	. = ..()

/datum/emote/sound/human/suka1
	name = "Сука!"
	key = "suka"
	key_third_person = "suka"
	message = "выглядит очень злым."
	message_mime = null
	sound = 'sound/voice/human/bear_fight.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/suka2
	name = "Агрессивное Сука!"
	key = "suka2"
	key_third_person = "suka2"
	message = "выглядит <b>очень</b> злым."
	message_mime = null
	sound = 'sound/voice/bear_fight2.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/jacket1
	name = "Какое время?"
	key = "jacket"
	key_third_person = "jacket"
	message = "говорит: <b>'Ты знаешь что сейчас за время?'</b>"
	message_mime = null
	sound = 'sound/voice/jacket1.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/jacket2
	name = "Нужна Помощь?"
	key = "jacket2"
	key_third_person = "jacket2"
	message = "говорит: <b>'Помощь в пути!'</b>"
	message_mime = null
	sound = 'sound/voice/jacket2.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/bulldozer1
	name = "Ты перед Стеной!"
	key = "bulldozer"
	key_third_person = "bulldozer"
	message = "кричит: <b>'Ты напротив стены и Я - эта ёбанная стена!'</b>"
	message_mime = null
	sound = 'sound/voice/bulldozer1.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/bulldozer2
	name = "Оставайся Жив!"
	key = "bulldozer2"
	key_third_person = "bulldozer2"
	message = "кричит: <b>'Пожалуйста, оставайтесь живыми подольше, чтобы я прикончил вас собственноручно!!'</b>"
	message_mime = null
	sound = 'sound/voice/bulldozer2.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/cheekybreeky
	key = "cheekybreeky"
	key_third_person = "cheekybreeky"
	message = "кричит: <b>'А НУ-У, ЧИКИ-БРИКИ И В ДАМКИ!'</b>"
	message_mime = null
	sound = 'sound/voice/human/cheekibreeki.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/sound/human/anyo
	key = "anyo"
	key_third_person = "anyo"
	message = "издаёт <b>аньо!</b>"
	message_mime = null
	sound = 'sound/voice/anyo.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/sound/human/ura1
	name = "Ура!"
	key = "ura"
	key_third_person = "ura"
	message = "кричит '<b>ура!</b>'"
	message_mime = null
	sound = 'sound/voice/ura1.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/sound/human/ura2
	name = "Громкое Ура!"
	key = "ura2"
	key_third_person = "ura2"
	message = "издаёт <b>мега-ура!</b>"
	message_mime = null
	sound = 'sound/voice/ura2.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/sound/human/ura3
	name = "Очень Громкое Ура!"
	key = "ura3"
	key_third_person = "ura3"
	message = "издаёт <b>мега-ультра-УРАААААААА!</b>"
	message_mime = null
	sound = 'sound/voice/ura3.ogg'
	emote_cooldown = 15 SECONDS

/datum/emote/sound/human/uwu
	name = "Увукнуть"
	key = "uwu"
	key_third_person = "uwu"
	message = "издаёт звук - <b>~UwU~</b>"
	message_mime = null
	sound = 'sound/voice/uwu1.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/sound/human/uwu/run_emote(mob/user, params)
	sound = pick('sound/voice/uwu1.ogg','sound/voice/uwu2.ogg')
	. = ..()

/datum/emote/sound/human/real_agony
	key = "realagony"
	key_third_person = "realagony"
	message = "кричит в агонии!"
	emote_type = EMOTE_AUDIBLE
	emote_cooldown = 5 SECONDS

/datum/emote/sound/human/real_agony/run_emote(mob/living/user, params) //I can't not port this shit, come on.
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
			user.adjustOxyLoss(10)
			if(user.gender != FEMALE && !(user.gender == PLURAL && isfeminine(user)))
				sound = pick('modular_bluemoon/smiley/sounds/emotes/agony_male_1.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_2.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_3.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_4.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_5.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_6.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_7.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_8.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_male_9.ogg')
			else
				sound = pick('modular_bluemoon/smiley/sounds/emotes/agony_female_1.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_female_2.ogg',\
						'modular_bluemoon/smiley/sounds/emotes/agony_female_3.ogg')
			if(is_species(user, /datum/species/android) || is_species(user, /datum/species/synth) || is_species(user, /datum/species/ipc))
				sound = 'modular_citadel/sound/voice/scream_silicon.ogg'
			if(is_species(user, /datum/species/skeleton))
				sound = 'modular_citadel/sound/voice/scream_skeleton.ogg'
			if (is_species(user, /datum/species/fly) || is_species(user, /datum/species/insect))
				sound = 'modular_citadel/sound/voice/scream_moth.ogg'
			if(is_species(user, /datum/species/mammal/vox))
				sound = 'modular_bluemoon/kovac_shitcode/sound/species/voxscream.ogg'
		if(isalien(user))
			sound = 'sound/voice/hiss6.ogg'
		LAZYINITLIST(user.alternate_screams)
		if(LAZYLEN(user.alternate_screams))
			sound = pick(user.alternate_screams)
		playsound(user.loc, sound, 75, 1, 4, 1.2)
		message = "кричит в агонии!"
	else if(miming)
		message = "изображает крик агонии."
	else
		message = "издает крайне громкий звук."
	. = ..()

/datum/emote/sound/human/rawr2
	name = "Равр!"
	key = "rawr2"
	key_third_person = "rawr2"
	message = "издаёт звук - <b>RAWR!</b>"
	message_mime = "строит грозную мину!"
	sound = 'sound/voice/rawr2.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/rocking
	key = "rocking"
	key_third_person = "rocking"
	message = "издаёт звук - <b>LIGHT WEIGHT BABY!</b>"
	message_mime = "строит грозную мину!"
	sound = 'sound/voice/light_weight_baby.ogg'
	emote_cooldown = 15 SECONDS

/datum/emote/sound/human/affirmative
	name = "Утвердительный сигнал"
	key = "affirmative"
	key_third_person = "affirmative"
	message = "испускает <b>утвердительный</b> сигнал"
	message_mime = "быстро кивает"
	sound = 'sound/machines/synth_yes.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/negative
	name = "Отрицательный сигнал"
	key = "negative"
	key_third_person = "negative"
	message = "испускает <b>отрицательный</b> сигнал"
	message_mime = "быстро мотает головой"
	sound = 'sound/machines/synth_no.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/cat_snores
	key = "catsnore"
	key_third_person = "catsnores"
	message = "глупенько храпит."
	message_mime = "храпит с необычным звуком."
	sound = 'sound/voice/snore_mimimimimimi.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/catgaph
	key = "catgaph"
	key_third_person = "catgaph"
	message = "хватает воздух ртом."
	message_mime = null
	sound = 'modular_bluemoon/sound/emotes/catgaph.ogg'
	emote_cooldown = 4 SECONDS

/datum/emote/sound/human/cp_laugh
	key = "cplaugh"
	key_third_person = "cplaught"
	message = "издаёт вокодерский смех."
	message_mime = "издаёт вокодерский смех."
	sound = 'sound/voice/cp_laugh.ogg'
	emote_cooldown = 0.25 SECONDS

/datum/emote/sound/human/oink1
	key = "oink1"
	key_third_person = "oink1"
	message = "хрюкает."
	message_mime = "кажется, хрюкает."
	sound = 'modular_bluemoon/sound/emotes/oink1.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/oink2
	key = "oink2"
	key_third_person = "oink2"
	message = "хрюкает."
	message_mime = "кажется, хрюкает."
	sound = 'modular_bluemoon/sound/emotes/oink2.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/oink3
	key = "oink3"
	key_third_person = "oink3"
	message = "хрюкает."
	message_mime = "кажется, хрюкает."
	sound = 'modular_bluemoon/sound/emotes/oink3.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/mrrp3
	key = "mrrp3"
	key_third_person = "mrrp3"
	message = "муркает."
	message_mime = "безмолвно муркает."
	sound = 'modular_bluemoon/sound/emotes/mrrps3.ogg'
	emote_cooldown = 0.5 SECONDS

/datum/emote/sound/human/girlymoan
	key = "girlymoan"
	key_third_person = "girlymoan"
	message = "мягко стонет."
	message_mime = "безмолвно стонет."
	sound = 'modular_bluemoon/sound/emotes/softmoan6.ogg'
	emote_type = EMOTE_AUDIBLE
	emote_cooldown = 0.8 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/girlymoan/run_emote(mob/user, params)
	sound = pick(GLOB.lewd_softmoans_female)
	. = ..()

/datum/emote/sound/human/squeal
	key = "squeal"
	key_third_person = "squeal"
	message = "пищит."
	message_mime = "безмолвно попискивает."
	sound = 'modular_bluemoon/sound/emotes/squeal.ogg'
	emote_cooldown = 0.75 SECONDS

/datum/emote/sound/human/purr
	stat_allowed = UNCONSCIOUS
	emote_volume = 10
	emote_falloff_exponent = 4

/datum/emote/sound/human/meow4
	key = "meow4"
	key_third_person = "meow4"
	message = "кротко мяукает."
	message_mime = "безмолвно мяукает."
	sound = 'modular_bluemoon/sound/emotes/meow4.ogg'
	emote_cooldown = 0.5 SECONDS

/datum/emote/sound/human/meow5
	key = "meow5"
	key_third_person = "meow5"
	message = "мяукает."
	message_mime = "безмолвно мяукает."
	sound = 'modular_bluemoon/sound/emotes/meow5.ogg'
	emote_cooldown = 0.5 SECONDS

/datum/emote/sound/human/meow6
	key = "meow6"
	key_third_person = "meow6"
	message = "натужно мяукает."
	message_mime = "безмолвно мяукает."
	sound = 'modular_bluemoon/sound/emotes/meow6.ogg'
	emote_cooldown = 0.5 SECONDS

/datum/emote/sound/human/catscream1
	key = "catscream1"
	key_third_person = "catscreams1"
	message = "кричит как кошка!"
	sound = 'modular_bluemoon/sound/emotes/catscream1.ogg'
	emote_cooldown = 1 SECONDS // I love felinid
	emote_pitch_variance = FALSE

/datum/emote/sound/human/catscream2
	key = "catscream2"
	key_third_person = "catscreams2"
	message = "кричит как раздражённая кошка!"
	sound = 'modular_bluemoon/sound/emotes/catscream2.ogg'
	emote_cooldown = 1 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/catscream3
	key = "catscream3"
	key_third_person = "catscreams3"
	message = "кричит как обиженная кошка!"
	sound = 'modular_bluemoon/sound/emotes/catscream3.ogg'
	emote_cooldown = 1 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/catscream
	key = "catscream"
	key_third_person = "catscreams"
	message = "кричит будто раненая кошка!"
	sound = 'modular_bluemoon/sound/emotes/catscream1.ogg'
	emote_cooldown = 1 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/catscream/run_emote(mob/user, params)
	sound = pick('modular_bluemoon/sound/emotes/catscream1.ogg', 'modular_bluemoon/sound/emotes/catscream2.ogg')
	. = ..()

/datum/emote/sound/human/horse_snort
	key = "horsesnort"
	key_third_person = "horsesnort"
	message = "фыркает как лошадь!"
	sound = 'modular_bluemoon/sound/emotes/snort.ogg'
	emote_cooldown = 1 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/horse_neigh
	key = "horseneigh"
	key_third_person = "horseneigh"
	message = "ржёт как лошадь!"
	sound = 'modular_bluemoon/sound/emotes/neigh.ogg'
	emote_cooldown = 1 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/vomit
	key = "vomit"
	key_third_person = "vomits"
	message = "суёт пальцы в рот и блюёт."
	message_mime = "суёт пальцы в рот и блюёт."
	sound = 'sound/effects/splat.ogg'
	emote_cooldown = 30 SECONDS

/datum/emote/sound/human/bruv
	key = "bruv"
	key_third_person = "bruv"
	message = "испытывает неловкость."
	message_mime = "испытывает неловкость."
	sound = 'modular_bluemoon/sound/emotes/bruv.ogg'
	emote_cooldown = 30 SECONDS

/datum/emote/sound/human/bonecrack
	key = "bonecrack"
	key_third_person = "bonecracks"
	message = "разминает суставы."
	message_mime = "делает вид, что разминает суставы."
	sound = 'modular_bluemoon/sound/emotes/bonecrack.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/sound/human/ohyes
	key = "ohyes"
	key_third_person = "ohyes"
	message = "испытывает приятное удивление."
	message_mime = "испытывает приятное удивление."
	sound = 'modular_bluemoon/sound/emotes/ohyes.ogg'
	emote_cooldown = 11.6 SECONDS

/datum/emote/sound/human/mudak
	key = "mudak"
	key_third_person = "mudak"
	message = "высказывает крайнюю степень недовольства."
	message_mime = "испытывает крайнюю степень недовольства."
	sound = 'modular_bluemoon/sound/emotes/mudak.ogg'
	emote_cooldown = 11.6 SECONDS

/datum/emote/sound/human/worm
	key = "worm"
	key_third_person = "worm"
	message = "высказывает неприятное удивление."
	message_mime = "испытывает неприятное удивление."
	sound = 'modular_bluemoon/sound/emotes/worm.ogg'
	emote_cooldown = 11.6 SECONDS

/datum/emote/sound/human/malf
	key = "malf"
	key_third_person = "malf"
	message = "втыкает."
	message_mime = "молча втыкает."
	sound = 'modular_bluemoon/sound/emotes/malf.ogg'
	emote_cooldown = 15 SECONDS

/datum/emote/sound/human/tsss
	key = "tsss"
	key_third_person = "tsss"
	message = "прижимает палец к своему рту, издавая 'ТССС'."
	message_mime = "прижимает палец к своему рту, издавая 'ТССС'."
	sound = 'modular_bluemoon/sound/emotes/tsss.ogg'
	emote_cooldown = 11.6 SECONDS

/datum/emote/sound/human/hellothere
	key = "hellothere"
	key_third_person = "hellothere"
	message = "приветствует вас."
	message_mime = "молча приветствует вас."
	sound = 'modular_bluemoon/sound/emotes/hi.ogg'
	emote_cooldown = 11.6 SECONDS

/datum/emote/sound/human/hecu
	key = "heavyass"
	key_third_person = "heavyasses"
	message = "БУКВАЛЬНО ГОВОРИТ, <b>\"MY ASS IS HEAVY\"</b>"
	emote_type = EMOTE_BOTH
	sound = 'modular_bluemoon/sound/emotes/myassisheavy.ogg'
	emote_cooldown = 3.2 SECONDS

/datum/emote/sound/human/blackops
	key = "blackopsalert"
	key_third_person = "blackopsalerted"
	message = "говорит <b>\"I have a target\"</b>"
	emote_type = EMOTE_BOTH
	sound = 'modular_bluemoon/sound/emotes/boalert.ogg'
	emote_cooldown = 5 SECONDS


/datum/emote/sound/human/higordon
	key = "higordon"
	key_third_person = "higordons"
	message = "говорит, <b>\"Hello Gordon\"</b>"
	emote_type = EMOTE_BOTH
	sound = 'modular_bluemoon/sound/emotes/hellogordon.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/sound/human/owl
	name = "Ухухать как сова"
	key = "owl"
	key_third_person = "owl"
	message = "OvO"
	sound = 'modular_bluemoon/sound/emotes/owl.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/sound/human/snakedies
	key = "snakedies"
	key_third_person = "Dying like a Snake"
	message = "dying like a Snake."
	sound = 'modular_bluemoon/sound/emotes/snakedies.ogg'
	emote_cooldown = 4 SECONDS
	emote_pitch_variance = FALSE

/datum/emote/sound/human/felinidhiss
	key = "felinidhiss"
	key_third_person = "hisses"
	message = "шипит!"
	sound = 'modular_bluemoon/sound/emotes/felinid_hiss.ogg'
	emote_cooldown = 1 SECONDS

/datum/emote/sound/human/dexter
	key = "dexter"
	key_third_person = "dextered"
	message = "неистово подозревает в чем-то"
	message_mime = "пронзает взглядом, неистово подозревая в чем-то"
	emote_type = EMOTE_AUDIBLE
	sound = 'modular_bluemoon/sound/emotes/dexter-song.ogg'
	emote_cooldown = 5 SECONDS


/*
 * XENO EMOTES START
 */

/datum/emote/sound/human/alien_hiss_1
	key = "ahiss1"
	key_third_person = "ahiss1"
	message = "шипит!"
	message_mime = null
	sound = 'sound/mobs/non-humanoids/hiss/hiss1.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_hiss_2
	key = "ahiss2"
	key_third_person = "ahiss2"
	message = "гортанно шипит..."
	message_mime = null
	sound = 'sound/mobs/non-humanoids/hiss/hiss2.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_hiss_2/run_emote(mob/user, params)
	sound = pick(
	'sound/mobs/non-humanoids/hiss/hiss2.ogg',
	'sound/mobs/non-humanoids/hiss/hiss3.ogg',
	'sound/mobs/non-humanoids/hiss/hiss4.ogg')
	. = ..()

/datum/emote/sound/human/alien_hiss_3
	key = "ahiss3"
	key_third_person = "ahiss3"
	message = "агрессивно шипит!"
	message_mime = null
	sound = 'sound/mobs/non-humanoids/hiss/hiss5.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_hiss_4
	key = "ahiss4"
	key_third_person = "ahiss4"
	message = "шипит на выдохе..."
	message_mime = null
	sound = 'sound/mobs/non-humanoids/hiss/lowHiss1.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_hiss_4/run_emote(mob/user, params)
	sound = pick(
	'sound/mobs/non-humanoids/hiss/lowHiss1.ogg',
	'sound/mobs/non-humanoids/hiss/lowHiss2.ogg',
	'sound/mobs/non-humanoids/hiss/lowHiss3.ogg',
	'sound/mobs/non-humanoids/hiss/lowHiss4.ogg')
	. = ..()

/datum/emote/sound/human/alien_scream
	key = "ascream"
	key_third_person = "ascream"
	message = "агрессивно кричит!"
	sound = 'sound/alien/Voice/screech1.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_scream/run_emote(mob/user, params)
	sound = pick(
	'sound/alien/Voice/screech1.ogg',
	'sound/alien/Voice/screech2.ogg',
	'sound/alien/Voice/screech3.ogg',
	'sound/alien/Voice/screech4.ogg')
	. = ..()

/datum/emote/sound/human/alien_scream_pain
	key = "apscream"
	key_third_person = "apscream"
	message = "кричит!"
	sound = 'sound/alien/Voice/hurt1.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_scream_pain/run_emote(mob/user, params)
	sound = pick(
	'sound/alien/Voice/hurt1.ogg',
	'sound/alien/Voice/hurt2.ogg')
	. = ..()

/datum/emote/sound/human/alien_sigh
	key = "asigh"
	key_third_person = "asigh"
	message = "раздражённо выдыхает!"
	message_mime = null
	sound = 'sound/alien/Voice/gnarl1.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_growl_1
	key = "agrowl1"
	key_third_person = "agrowl1"
	message = "агрессивно шипит, клацнув зубами!"
	message_mime = null
	sound = 'sound/alien/Voice/growl1.ogg'
	emote_cooldown = 6 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_growl_2
	key = "agrowl2"
	key_third_person = "agrowl2"
	message = "недовольно рычит."
	message_mime = null
	sound = 'sound/alien/Voice/growl2.ogg'
	emote_cooldown = 3 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_growl_2/run_emote(mob/user, params)
	sound = pick(
	'sound/alien/Voice/growl2.ogg',
	'sound/alien/Voice/growl9.ogg',
	'sound/alien/Voice/growl10.ogg',)
	. = ..()

/datum/emote/sound/human/alien_growl_3
	key = "agrowl3"
	key_third_person = "agrowl3"
	message = "агрессивно рычит!"
	message_mime = null
	sound = 'sound/alien/Voice/growl3.ogg'
	emote_cooldown = 6 SECONDS
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/alien_growl_3/run_emote(mob/user, params)
	sound = pick(
	'sound/alien/Voice/growl3.ogg',
	'sound/alien/Voice/growl4.ogg',
	'sound/alien/Voice/growl5.ogg',
	'sound/alien/Voice/growl6.ogg',
	'sound/alien/Voice/growl7.ogg',
	'sound/alien/Voice/growl8.ogg')
	. = ..()

/*
 * XENO EMOTES END
 */
