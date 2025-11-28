/mob/living/simple_animal/hostile/netherworld
	name = "creature"
	desc = "Существо из потустороннего мира, разрушающее рассудок. Хотя кто-то найдет его милым..."
	icon_state = "otherthing"
	icon_living = "otherthing"
	icon_dead = "otherthing-dead"
	mob_biotypes = NONE
	health = 80
	maxHealth = 80
	obj_damage = 100
	melee_damage_lower = 25
	melee_damage_upper = 50
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	faction = list("creature")
	speak_emote = list("screams")
	gold_core_spawnable = HOSTILE_SPAWN
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	faction = list("nether")

/mob/living/simple_animal/hostile/netherworld/migo
	name = "mi-go"
	desc = "Розоватое, грибоподобное существо, напоминающее ракообразное, с множеством пар клешнеобразных конечностей и головой, покрытой извивающимися антеннами."
	speak_emote = list("screams", "clicks", "chitters", "barks", "moans", "growls", "meows", "reverberates", "roars", "squeaks", "rattles", "exclaims", "yells", "remarks", "mumbles", "jabbers", "stutters", "seethes")
	icon_state = "mi-go"
	icon_living = "mi-go"
	icon_dead = "mi-go-dead"
	attack_verb_continuous = "lacerates"
	attack_verb_simple = "lacerate"
	speed = -0.5
	var/static/list/migo_sounds
	deathmessage = "издает завывания, пока его тело превращается в кашеобразную массу."
	death_sound = 'sound/voice/hiss6.ogg'

/mob/living/simple_animal/hostile/netherworld/migo/Initialize(mapload)
	. = ..()
	migo_sounds = list('sound/items/bubblewrap.ogg', 'sound/items/change_jaws.ogg', 'sound/items/crowbar.ogg', 'sound/items/drink.ogg', 'sound/items/deconstruct.ogg', 'sound/items/carhorn.ogg', 'sound/items/change_drill.ogg', 'sound/items/dodgeball.ogg', 'sound/items/eatfood.ogg', 'sound/items/megaphone.ogg', 'sound/items/screwdriver.ogg', 'sound/items/weeoo1.ogg', 'sound/items/wirecutter.ogg', 'sound/items/welder.ogg', 'sound/items/zip.ogg', 'sound/items/rped.ogg', 'sound/items/ratchet.ogg', 'sound/items/polaroid1.ogg', 'sound/items/pshoom.ogg', 'sound/items/airhorn.ogg', 'sound/items/geiger/high1.ogg', 'sound/items/geiger/high2.ogg', 'sound/voice/beepsky/creep.ogg', 'sound/voice/beepsky/iamthelaw.ogg', 'sound/voice/ed209_20sec.ogg', 'sound/voice/hiss3.ogg', 'sound/voice/hiss6.ogg', 'sound/voice/medbot/patchedup.ogg', 'sound/voice/medbot/feelbetter.ogg', 'sound/voice/human/manlaugh1.ogg', 'sound/voice/human/womanlaugh.ogg', 'sound/weapons/sear.ogg', 'sound/ambience/antag/clockcultalr.ogg', 'sound/ambience/antag/ling_aler.ogg', 'sound/ambience/antag/tatoralert.ogg', 'sound/ambience/antag/monkey.ogg', 'sound/mecha/nominal.ogg', 'sound/mecha/weapdestr.ogg', 'sound/mecha/critdestr.ogg', 'sound/mecha/imag_enh.ogg', 'sound/effects/adminhelp.ogg', 'sound/misc/alerts/alert.ogg', 'sound/effects/attackblob.ogg', 'sound/effects/bamf.ogg', 'sound/effects/blobattack.ogg', 'sound/effects/break_stone.ogg', 'sound/effects/bubbles.ogg', 'sound/effects/bubbles2.ogg', 'sound/effects/clang.ogg', 'sound/effects/clockcult_gateway_disrupted.ogg', 'sound/effects/clownstep2.ogg', 'sound/effects/curse1.ogg', 'sound/effects/dimensional_rend.ogg', 'sound/effects/doorcreaky.ogg', 'sound/effects/empulse.ogg', 'sound/effects/explosion_distant.ogg', 'sound/effects/explosionfar.ogg', 'sound/effects/explosion1.ogg', 'sound/effects/grillehit.ogg', 'sound/effects/genetics.ogg', 'sound/effects/heart_beat.ogg', 'sound/effects/hyperspace_begin.ogg', 'sound/effects/hyperspace_end.ogg', 'sound/effects/his_grace_awaken.ogg', 'sound/effects/pai_boot.ogg', 'sound/effects/phasein.ogg', 'sound/effects/picaxe1.ogg', 'sound/effects/ratvar_reveal.ogg', 'sound/effects/sparks1.ogg', 'sound/effects/smoke.ogg', 'sound/effects/splat.ogg', 'sound/effects/snap.ogg', 'sound/effects/tendril_destroyed.ogg', 'sound/effects/supermatter.ogg', 'sound/misc/desceration-01.ogg', 'sound/misc/desceration-02.ogg', 'sound/misc/desceration-03.ogg', 'sound/misc/bloblarm.ogg', 'sound/misc/airraid.ogg', 'sound/misc/bang.ogg','sound/misc/highlander.ogg', 'sound/misc/interference.ogg', 'sound/misc/notice1.ogg', 'sound/misc/notice2.ogg', 'sound/misc/sadtrombone.ogg', 'sound/misc/slip.ogg', 'sound/misc/splort.ogg', 'sound/weapons/armbomb.ogg', 'sound/weapons/beam_sniper.ogg', 'sound/weapons/chainsawhit.ogg', 'sound/weapons/emitter.ogg', 'sound/weapons/emitter2.ogg', 'sound/weapons/blade1.ogg', 'sound/weapons/bladeslice.ogg', 'sound/weapons/blastcannon.ogg', 'sound/weapons/blaster.ogg', 'sound/weapons/bulletflyby3.ogg', 'sound/weapons/circsawhit.ogg', 'sound/weapons/cqchit2.ogg', 'sound/weapons/drill.ogg', 'sound/weapons/genhit1.ogg', 'sound/weapons/gunshot_silenced.ogg', 'sound/weapons/gunshot2.ogg', 'sound/weapons/handcuffs.ogg', 'sound/weapons/homerun.ogg', 'sound/weapons/kenetic_accel.ogg', 'sound/machines/clockcult/steam_whoosh.ogg', 'sound/machines/fryer/deep_fryer_emerge.ogg', 'sound/machines/airlock.ogg', 'sound/machines/airlock_alien_prying.ogg', 'sound/machines/airlockclose.ogg', 'sound/machines/airlockforced.ogg', 'sound/machines/airlockopen.ogg', 'sound/machines/alarm.ogg', 'sound/machines/blender.ogg', 'sound/machines/boltsdown.ogg', 'sound/machines/boltsup.ogg', 'sound/machines/buzz-sigh.ogg', 'sound/machines/buzz-two.ogg', 'sound/machines/chime.ogg', 'sound/machines/cryo_warning.ogg', 'sound/machines/defib_charge.ogg', 'sound/machines/defib_failed.ogg', 'sound/machines/defib_ready.ogg', 'sound/machines/defib_zap.ogg', 'sound/machines/deniedbeep.ogg', 'sound/machines/ding.ogg', 'sound/machines/disposalflush.ogg', 'sound/machines/door_close.ogg', 'sound/machines/door_open.ogg', 'sound/machines/engine_alert1.ogg', 'sound/machines/engine_alert2.ogg', 'sound/machines/hiss.ogg', 'sound/machines/honkbot_evil_laugh.ogg', 'sound/machines/juicer.ogg', 'sound/machines/ping.ogg', 'sound/machines/signal.ogg', 'sound/machines/synth_no.ogg', 'sound/machines/synth_yes.ogg', 'sound/machines/terminal_alert.ogg', 'sound/machines/triple_beep.ogg', 'sound/machines/twobeep.ogg', 'sound/machines/ventcrawl.ogg', 'sound/machines/warning-buzzer.ogg', SSstation.announcer.event_sounds[ANNOUNCER_OUTBREAK5], SSstation.announcer.event_sounds[ANNOUNCER_OUTBREAK7], SSstation.announcer.event_sounds[ANNOUNCER_POWEROFF], SSstation.announcer.event_sounds[ANNOUNCER_RADIATION], SSstation.announcer.event_sounds[ANNOUNCER_SHUTTLERECALLED], SSstation.announcer.event_sounds[ANNOUNCER_SHUTTLEDOCK], SSstation.announcer.event_sounds[ANNOUNCER_SHUTTLECALLED], SSstation.announcer.event_sounds[ANNOUNCER_AIMALF]) //hahahaha fuck you code divers

/mob/living/simple_animal/hostile/netherworld/migo/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	..()
	if(stat)
		return
	var/chosen_sound = pick(migo_sounds)
	playsound(src, chosen_sound, 100, TRUE)

/mob/living/simple_animal/hostile/netherworld/migo/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	if(stat)
		return
	if(prob(10))
		var/chosen_sound = pick(migo_sounds)
		playsound(src, chosen_sound, 100, TRUE)

/mob/living/simple_animal/hostile/netherworld/blankbody
	name = "blank body"
	desc = "Выглядит достаточно по-человечески, но его плоть выглядит вывернутой наизнанку, а лицо лишено всего, за исключением зловещей улыбки."
	icon_state = "blank-body"
	icon_living = "blank-body"
	icon_dead = "blank-dead"
	gold_core_spawnable = NO_SPAWN
	health = 100
	maxHealth = 100
	melee_damage_lower = 5
	melee_damage_upper = 10
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	deathmessage = "рассыпается в мелкую пыль."

/mob/living/simple_animal/hostile/netherworld/blankbody/examine(mob/user)
	. = ..()
	var/obj/item/organ/brain/brain = locate(/obj/item/organ/brain) in contents
	if(brain)
		. += span_boldwarning("\nВнутри кровоточащей плоти, ты замечаешь [icon2html(brain, user)] [brain.name]!")

/mob/living/simple_animal/hostile/netherworld/blankbody/death(gibbed)
	var/turf/T = get_turf(src)
	for(var/atom/movable/A in contents)
		A.forceMove(T)
		if(isliving(A))
			var/mob/living/L = A
			L.update_mobility()
	. = ..()

/obj/structure/spawner/nether
	name = "netherworld link"
	desc = "Прямая связь с другим измерением, полным существ, которые явно не рады тебе. \
	<span class='boldwarning'>Входить туда - очень плохая идея.</span>\
	\n<span class='nicegreen'>Но может быть там есть что-то ценное...</span>"
	icon_state = "nether"
	max_integrity = 50
	spawn_time = 1 MINUTES //1 minute
	max_mobs = 15
	icon = 'icons/mob/nest.dmi'
	spawn_text = "crawls through"
	mob_types = list(/mob/living/simple_animal/hostile/netherworld/migo, /mob/living/simple_animal/hostile/netherworld, /mob/living/simple_animal/hostile/netherworld/blankbody)
	faction = list("nether")
	var/processing_time = 15 SECONDS

/obj/structure/spawner/nether/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(user.loc == src)
		return
	user.visible_message(span_warning("[user] с силой затягивает в портал!"), \
						span_userdanger("Когда ты прикасаешься к порталу, он стремительно затягивает тебя в мир невообразимого ужаса!"))
	if(!do_after(user, 2 SECONDS, src))
		return
	contents.Add(user)
	processing_time = 0
	START_PROCESSING(SSobj, src)

/obj/structure/spawner/nether/process(delta_time)
	if(!locate(/mob/living) in contents)
		return PROCESS_KILL

	for(var/mob/living/M in contents)
		if(M.stat == DEAD)
			var/mob/living/simple_animal/hostile/netherworld/blankbody/blank
			blank = new(loc)
			blank.name = "[M]"
			blank.desc = "Это [M], но [M.ru_ego()] его плоть выглядит вывернутой наизнанку, а [M.ru_ego()] лицо лишено всего, за исключением зловещей улыбки."
			balloon_alert_to_viewers(span_balloon_warning("[M] выходит!"))
			if(iscarbon(M))
				var/mob/living/carbon/C = M
				for(var/obj/item/organ/organ in C.internal_organs)
					if(istype(organ, /obj/item/organ/genital))
						continue
					organ.Remove()
					organ.forceMove(blank)
			qdel(M)

	if(processing_time > 0)
		processing_time -= delta_time SECONDS
		return
	processing_time = initial(processing_time)

	for(var/mob/living/M in contents)
		if(prob(10))
			playsound(get_turf(src), 'sound/effects/pray.ogg', 50)
			to_chat(M, span_nicegreen("Вы не знаете боги ли спасли вас или демоны, но вам чудом удается выбраться из проклятого мира и закрыть портал!"))
			new /obj/structure/closet/crate/necropolis/tendril/random(drop_location())
			qdel(src)
			return
		playsound(src, 'sound/magic/demon_consume.ogg', 50, 1)
		M.emote("realagony")
		M.say(pick("AAA!!", "АААХ!!", "ААГХ!!"), forced = "nether")
		M.Stun(100)
		M.Jitter(50)
		M.blur_eyes(15)
		M.dizziness += 50
		M.confused += 30
		M.stuttering += 30
		M.adjustBruteLoss(60)
		M.spawn_gibs()

/obj/structure/spawner/nether/Destroy()
	var/turf/T = get_turf(src)
	for(var/atom/movable/A in contents)
		A.forceMove(T)
		if(isliving(A))
			var/mob/living/L = A
			L.update_mobility()
	. = ..()
