//Sandstorm edits

/datum/interaction/lewd/display_interaction(mob/living/user, mob/living/target, var/is_hidden)
	. = ..()
	//переменные ниже используются в последующих проках после вызова родителя

	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB) && !is_hidden)
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB) && !is_hidden)
		new /obj/effect/temp_visual/heart(target.loc)

	if(is_hidden)
		return TRUE

/datum/interaction/lewd/titgrope/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	var/list/honks = list(
		"Сиськи <b>[target]</b> забавно пищат!",
		"\<b>[user]</b> крепко сжимает \<b>[target]</b> за её [pick(GLOB.breast_nouns)] и они громко пищат!"
	)
	if(prob(50))
		target.visible_message("<span class='lewd'>[pick(honks)]</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/oral/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		target.visible_message("<span class='lewd'>\<b>[target]</b> неуклюже хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/oral/blowjob/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		// var/genital_name = target.get_penetrating_genital_name(TRUE)
		target.visible_message("<span class='lewd'>\[genital_name] <b>[target]</b> громко хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/fuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\<b>[target]</b> неуклюже хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/fuck/anal/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>Задница <b>[target]</b> громко хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/finger/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		target.visible_message("<span class='lewd'>\<b>[target]</b> неуклюже хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/fingerass/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		target.visible_message("<span class='lewd'>Задница <b>[target]</b> громко хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/facefuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = target.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'><b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/throatfuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(istype(target, /mob/living) && user.is_fucking(target, CUM_TARGET_THROAT))
		var/stat_before = target.stat
		target.adjustOxyLoss(6)
		if(target.stat == UNCONSCIOUS && stat_before != UNCONSCIOUS)
			target.visible_message(message = "<font color=red><b>[target]</b> теряет сознание из-за члена <b>[user]</b>.</span>", ignored_mobs = user.get_unconsenting())
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'><b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/handjob/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'><b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/breastfuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\ [pick(GLOB.breast_nouns)] <b>[target]</b> забавно хонкают!</span>")

	playlewdinteractionsound(target, pick('sound/items/bikehorn.ogg',
						'modular_bluemoon/sound/interactions/fuckClown.ogg',
						'modular_bluemoon/sound/interactions/fuckClown1.ogg'), 70, 1, -1)

/datum/interaction/lewd/mount/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(user))
		user.visible_message("<span class='lewd'>\ Киска <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/mountass/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(user))
		target.visible_message("<span class='lewd'>\ Задница <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/mountface/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ Задница <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/footfuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/footfuck/double/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/footjob/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		//var/genital_name = target.get_penetrating_genital_name(TRUE)
		target.visible_message("<span class='lewd'>\ <b>[target]</b> забавно хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/footjob/double/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(target))
		return

	if(prob(50))
		//var/genital_name = target.get_penetrating_genital_name(TRUE)
		target.visible_message("<span class='lewd'>\ <b>[target]</b> забавно хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/nuts/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ Яички <b>[user]</b> забавно хонкают!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/nut_smack/display_interaction(mob/living/user, mob/living/target)
	. = ..()
	if(!(isclownjob(target) && type == /datum/interaction/lewd/nut_smack))
		return

	if(prob(50))
		target.visible_message("<span class='lewd'>\ Яички <b>[user]</b> забавно хонкают!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/earfuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/bite/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if (istype(user.wear_mask, /obj/item/clothing/mask/muzzle/mouthring))
		to_chat(user, "<span class='warning'> Вы безуспешно пытаетесь сомкнуть свои челюсти. </span>")
		return
	. = ..()


	if(!isclownjob(user))
		return
	//
	//
	if(prob(50))
			//var/genital_name = user.get_penetrating_genital_name(TRUE)
			//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/eyefuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/frotting/display_interaction(mob/living/user, mob/living/target)
	. = ..()
	if(!(isclownjob(target) || isclownjob(user)))
		return

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/do_breastfeed/display_interaction(mob/living/user, mob/living/target)
	var/obj/item/organ/genital/breasts/milkers = user.getorganslot(ORGAN_SLOT_BREASTS)
	var/blacklist = target.client?.prefs.gfluid_blacklist
	var/cached_fluid
	if((milkers?.get_fluid_id() in blacklist) || ((/datum/reagent/blood in blacklist) && ispath(milkers?.get_fluid_id(), /datum/reagent/blood)))
		cached_fluid = milkers?.get_fluid_id()
		milkers?.set_fluid_id(milkers?.default_fluid_id)

	. = ..()

	if(cached_fluid)
		milkers.set_fluid_id(cached_fluid)

	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ [pick(GLOB.breast_nouns)] <b>[target]</b> забавно хонкают!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/jack/display_interaction(mob/living/carbon/human/user)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/fingerass_self/display_interaction(mob/living/carbon/human/user)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ Задница <b>[user]</b> громко хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/finger_self/display_interaction(mob/living/carbon/human/user)
	. = ..()
	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ Киска <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/titgrope_self/display_interaction(mob/living/carbon/human/user)
	. = ..()
	if(!isclownjob(user))
		return

	//var/u_His = user.ru_ego()
	var/list/honks = list(
		"<span class='lewd'>\ Сиськи <b>[user]</b> громко пищат!</span>",
		"<span class='lewd'>\ <b>[user]</b> издаёт громкое пищание своими [pick(GLOB.breast_nouns)]!</span>"
	)
	if(prob(50))
		user.visible_message("<span class='lewd'>[pick(honks)]</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/self_nipsuck/display_interaction(mob/living/user, mob/living/target)
	var/obj/item/organ/genital/breasts/milkers = user.getorganslot(ORGAN_SLOT_BREASTS)
	var/blacklist = target.client?.prefs.gfluid_blacklist
	var/cached_fluid
	if((milkers?.get_fluid_id() in blacklist) || ((/datum/reagent/blood in blacklist) && ispath(milkers?.get_fluid_id(), /datum/reagent/blood)))
		cached_fluid = milkers?.get_fluid_id()
		milkers?.set_fluid_id(milkers?.default_fluid_id)

	. = ..()

	if(cached_fluid)
		milkers.set_fluid_id(cached_fluid)

	if(!isclownjob(user))
		return

	//var/u_His = user.ru_ego()
	var/list/honks = list(
		"<span class='lewd'>\ Сиськи <b>[target]</b> громко пищат!</span>",
		"<span class='lewd'>\ <b>[target]</b> издаёт громкое пищание своими [pick(GLOB.breast_nouns)]!</span>"
	)
	if(prob(50))
		user.visible_message("<span class='lewd'>[pick(honks)]</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/nipsuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/organ/genital/breasts/milkers = target.getorganslot(ORGAN_SLOT_BREASTS)
	var/blacklist = user.client?.prefs.gfluid_blacklist
	var/cached_fluid
	if((milkers?.get_fluid_id() in blacklist) || ((/datum/reagent/blood in blacklist) && ispath(milkers?.get_fluid_id(), /datum/reagent/blood)))
		cached_fluid = milkers?.get_fluid_id()
		milkers?.set_fluid_id(milkers?.default_fluid_id)

	. = ..()

	if(cached_fluid)
		milkers.set_fluid_id(cached_fluid)

	if(!isclownjob(target) || !milkers)
		return

	var/list/honks = list(
		"<span class='lewd'>\ Сиськи <b>[target]</b> громко пищат!</span>",
		"<span class='lewd'>\ <b>[target]</b> издаёт громкое пищание своими [pick(GLOB.breast_nouns)]!</span>"
	)
	if(prob(50))
		user.visible_message("<span class='lewd'>[pick(honks)]</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/kiss/post_interaction(mob/living/user, mob/living/partner)
	. = ..()

	SEND_SIGNAL(user, COMSIG_INTERACTION_KISS, partner)
	SEND_SIGNAL(partner, COMSIG_INTERACTION_KISS, user)

	//SPLURT EDIT START:
	// Check if user has TRAIT_KISS_SLUT and increase their lust
	if(HAS_TRAIT(user, TRAIT_KISS_SLUT))
		user.handle_post_sex(LOW_LUST, null, partner)

	// Check if partner has TRAIT_KISS_SLUT and increase their lust
	if(HAS_TRAIT(partner, TRAIT_KISS_SLUT))
		partner.handle_post_sex(LOW_LUST, null, user)
	//SPLURT EDIT END

/datum/interaction/lewd/kiss/display_interaction(mob/living/user, mob/living/partner)
	var/is_hidden = ..()
	var/volume = 50
	if(is_hidden)
		volume = sound_quiet_volume
	if(!HAS_TRAIT(user, TRAIT_KISS_MIME))
		if(HAS_TRAIT(user, TRAIT_KISS_HONK))
			playlewdinteractionsound(user.loc, 'modular_sand/sound/interactions/kiss5.ogg', volume, 1, -1)
		else
			playlewdinteractionsound(user.loc, pick(GLOB.lewd_kiss_sounds), volume, 1, -1)

	if(user.a_intent == INTENT_HARM)
		if(HAS_TRAIT(user, TRAIT_KISS_OF_DEATH))
			partner.reagents.add_reagent(/datum/reagent/toxin/amanitin , 4)
			user.reagents.add_reagent(/datum/reagent/toxin/amanitin , 0.5)
		else if(HAS_TRAIT(user, TRAIT_KISS_CROCIN))
			partner.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, rand(5, 10))
		else if(HAS_TRAIT(user, TRAIT_KISS_SPACE_DRUGS))
			partner.reagents.add_reagent(/datum/reagent/drug/space_drugs, rand(1, 3))
		else if(HAS_TRAIT(user, TRAIT_KISS_HONK))
			partner.emote("flip")
			playsound(partner, 'sound/items/bikehorn.ogg', 50, TRUE)
		else if(HAS_TRAIT(user, TRAIT_KISS_BLOODSUCKER))
			if(iscarbon(partner))
				var/mob/living/carbon/C = partner
				if(C.blood_volume > 0)
					C.blood_volume = max(C.blood_volume - 15, 0)
		else if(HAS_TRAIT(user, TRAIT_KISS_MIME))
			partner.reagents.add_reagent(/datum/reagent/toxin/mutetoxin, rand(1, 2))
		else if(HAS_TRAIT(user, TRAIT_KISS_DRAGQUEEN))
			var/list/drugs = list(
				/datum/reagent/drug/space_drugs,
				/datum/reagent/toxin/mindbreaker,
				/datum/reagent/drug/mdma,
				/datum/reagent/drug/zvezdochka,
				/datum/reagent/drug/pendosovka
			)
			partner.reagents.add_reagent(pick(drugs), 1)
		else if(HAS_TRAIT(user, TRAIT_KISS_HEARTBOOM))
			partner.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, rand(1, 5))
			new /obj/effect/temp_visual/heart(get_turf(partner))
			var/obj/effect/particle_effect/smoke/cigsmoke/puff = new(get_turf(partner))
			puff.color = "#9400D3"
			puff.alpha = 64
			puff.lifetime = 1
			var/static/list/heartboom_emotes = list(
				list("gasp", "Ты чувствуешь как леденеют твои вены и сердце на секунду замирает..."),
				list("sneeze", "Ты чихаешь от попавших тебе в нос блёсток..."),
				list("dance", "Жизнь прекрасна! Твои ноги пускаются в пляс!"),
				list("blush", "Внутри так... тепло..."),
				list("moan", "Мне так... хорошо..."),
				list("collapse", "В груди так пусто... что-то исчезло..."),
				list("realagony", "БОЖЕ! ВНУТРИ ВСЁ ПЫЛАЕТ! ОСТАНОВИТЕ ЭТО!"),
				list("laugh", "Что-то щекочет тебя"),
				list("laugh", "Ты не можешь перестать смеяться")
			)
			var/list/chosen = pick(heartboom_emotes)
			to_chat(partner, span_love("[chosen[2]]"))
			partner.emote(chosen[1])

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.use_kiss()

//Own stuff
/datum/interaction/lewd/oral/selfsuck
	description = "Член. Отсосать самому себе."
	interaction_sound = null
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	max_distance = 0
	write_log_user = "Отсосал(а) сам(а) себе"
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_MOUTH
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/oral/selfsuck/display_interaction(mob/living/carbon/human/user)
	var/is_hidden = ..()
	user.do_oral_self(user, "penis", is_hidden)
	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/oral/suckvagself
	description = "Вагина. Отлизать свою киску."
	interaction_sound = null
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	required_from_user_unexposed = NONE
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	max_distance = 0
	write_log_user = "отлизал(а) свою собственную киску"
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_MOUTH
	p13target_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/oral/suckvagself/display_interaction(mob/living/carbon/human/user)
	var/is_hidden = ..()
	user.do_oral_self(user, "vagina", is_hidden)

/datum/interaction/lewd/breastfuckself
	description = "Грудь. Трахнуть свои сиськи."
	interaction_sound = null
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS | INTERACTION_REQUIRE_BREASTS
	required_from_user_unexposed = NONE
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	max_distance = 0
	write_log_user = "Трахнул(а) свои сиськи."
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/breastfuckself/display_interaction(mob/living/carbon/human/user)
	var/is_hidden = ..()
	user.do_breastfuck_self(user, is_hidden)
	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ [pick(GLOB.breast_nouns)] <b>[user]</b> забавно хонкают!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/fuck/belly
	description = "Живот. Трахнуть в пупок."
	required_from_target_exposed = INTERACTION_REQUIRE_BELLY
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	write_log_user = "belly fucked"
	write_log_target = "was belly fucked by"
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_CHEST

/datum/interaction/lewd/fuck/belly/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/is_hidden = ..()
	user.do_bellyfuck(target, is_hidden)

	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\ Живот <b>[target]</b> громко хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/deflate_belly
	description = "Живот. Уменьшить свой живот."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_BELLY
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 0
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "deflated their belly"
	write_log_target = null

/datum/interaction/lewd/deflate_belly/display_interaction(mob/living/carbon/user)
	var/obj/item/organ/genital/belly/gut = user.getorganslot(ORGAN_SLOT_BELLY)
	if(gut)
		gut.modify_size(-1)

/datum/interaction/lewd/inflate_belly
	description = "Живот. Надуть свой живот."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_BELLY
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 0
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "inflated their belly"
	write_log_target = null

/datum/interaction/lewd/inflate_belly/display_interaction(mob/living/carbon/user)
	var/obj/item/organ/genital/belly/gut = user.getorganslot(ORGAN_SLOT_BELLY)
	if(gut)
		gut.modify_size(1)

/datum/interaction/lewd/deflate_breasts
	description = "Грудь. Уменьшить свою грудь."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 0
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "deflated their breasts"
	write_log_target = null

/datum/interaction/lewd/deflate_breasts/display_interaction(mob/living/carbon/user)
	var/obj/item/organ/genital/breasts/breasts = user.getorganslot(ORGAN_SLOT_BREASTS)
	if(breasts)
		breasts.modify_size(-1)

/datum/interaction/lewd/inflate_breasts
	description = "Грудь. Надуть свою грудь."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 0
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "inflated their breasts"
	write_log_target = null

/datum/interaction/lewd/inflate_breasts/display_interaction(mob/living/carbon/user)
	var/obj/item/organ/genital/breasts/breasts = user.getorganslot(ORGAN_SLOT_BREASTS)
	if(breasts)
		breasts.modify_size(1)

/datum/interaction/lewd/nuzzle_belly
	description = "Живот. Тыкнуться носом."
	required_from_target_exposed = INTERACTION_REQUIRE_BELLY
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 1
	write_log_target = "К её/его животу прижался носом"
	write_log_user = "прижался носом к животу"

/datum/interaction/lewd/nuzzle_belly/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.nuzzle_belly(target, is_hidden)

/datum/interaction/lewd/do_breastsmother
	description = "Грудь. Придушить партнёра."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "был(а) придушен(а) грудью"
	write_log_user = "придушил(а) грудью"

/datum/interaction/lewd/do_breastsmother/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_breastsmother(target, is_hidden)

	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\ [pick(GLOB.breast_nouns)] <b>[target]</b> забавно хонкают!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/lick_sweat
	description = "Подмышки. Слизывать пот."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "Её/его пот был слизан"
	write_log_user = "слизывал(а) пот"

/datum/interaction/lewd/lick_sweat/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.lick_sweat(target, is_hidden)

/datum/interaction/lewd/smother_armpit
	description = "Подмышки. Зажать лицо партнёра."
	max_distance = 1
	interaction_sound = null
	write_log_target = "Был(а) зажат(а) лицом в подмышку"
	write_log_user = "Зажал(а) своей подмышкой лицо"

/datum/interaction/lewd/smother_armpit/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.smother_armpit(target, is_hidden)

/datum/interaction/lewd/lick_armpit
	description = "Подмышки. Вылизать подмышку."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "Её/его подмышка была вылизана"
	write_log_user = "вылизал(а) подмышку"

/datum/interaction/lewd/lick_armpit/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.lick_armpit(target, is_hidden)

/datum/interaction/lewd/fuck_armpit
	description = "Подмышки. Трахнуть в подмышку."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	interaction_sound = null
	write_log_target = "был(-а) трахнут(-а) в подмышку"
	write_log_user = "трахнул(-а) подмышку"
	p13user_emote = PLUG13_EMOTE_PENIS
	p13user_strength = PLUG13_STRENGTH_NORMAL
	p13target_emote = PLUG13_EMOTE_BASIC
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/fuck_armpit/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.fuck_armpit(target, is_hidden)

	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/do_pitjob
	description = "Подмышки. Вздрочнуть пенис партнёра."
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	interaction_sound = null
	write_log_target = "получил(-а) мастурбацию подмышкой от"
	write_log_user = "вздрочнул(-а) своей подмышкой пенис"
	p13user_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_emote = PLUG13_EMOTE_PENIS
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/do_pitjob/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_pitjob(target, is_hidden)

	if(!isclownjob(target))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[user]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/do_boobjob
	description = "Грудь. Вздрочнуть пенис партнёра."
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 1
	write_log_target = "получил(-а) мастурбацию сиськами от"
	write_log_user = "вздрочнул(-а) своими сиськами пенис"
	p13user_emote = PLUG13_EMOTE_BREASTS
	p13user_strength = PLUG13_STRENGTH_NORMAL
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/do_boobjob/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_boobjob(target, is_hidden)

	if(!isclownjob(user))
		return

	if(prob(50))
		user.visible_message("<span class='lewd'>\[pick(GLOB.breast_nouns)] <b>[target]</b> забавно хонкают!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/lick_nuts
	description = "Яйца. Полизать яички партнёра."
	required_from_target_exposed = INTERACTION_REQUIRE_BALLS
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 1
	write_log_target = "Её/его яйца были вылизаны"
	write_log_user = "Отлизал(а) яйца"
	p13user_emote = PLUG13_EMOTE_MOUTH
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_emote = PLUG13_EMOTE_GROIN
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/lick_nuts/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.lick_nuts(target, is_hidden)

/datum/interaction/lewd/fuck_cock
	description = "Член. Трахнуть в уретру."
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	interaction_sound = null
	max_distance = 1
	write_log_target = "Был трахнут(-а) в уретру"
	write_log_user = "Трахнул(-а) уретру"
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/fuck_cock/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_cockfuck(target, is_hidden)

	if(!(isclownjob(target) || isclownjob(user)))
		return

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/nipple_fuck
	description = "Грудь. Трахнуть в сосок."
	required_from_target = INTERACTION_REQUIRE_TOPLESS
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	write_log_user = "fucked nipples"
	write_log_target = "got their nipples fucked by"
	interaction_sound = null
	max_distance = 1
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_CHEST

/datum/interaction/lewd/nipple_fuck/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_nipfuck(target, is_hidden)

	if(!isclownjob(target) || isclownjob(user))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\[pick(GLOB.breast_nouns)] <b>[target]</b> [pick(GLOB.breast_nouns)] забавно хонкают!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/fuck_thighs
	description = "Член. Проникнуть между бёдрами."
	require_target_legs = REQUIRE_ANY
	require_target_num_legs = 2
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	write_log_user = "fucked thighs"
	write_log_target = "got their thighs fucked by"
	interaction_sound = null
	max_distance = 1
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_GROIN
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/fuck_thighs/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_thighfuck(target, spillage = TRUE, is_hidden = is_hidden)

	if(!isclownjob(user))
		return

	if(prob(50))
		//var/genital_name = user.get_penetrating_genital_name(TRUE)
		user.visible_message("<span class='lewd'>\ <b>[target]</b> забавно хонкает!</span>")

	playlewdinteractionsound(user, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/do_thighjob
	description = "Бёдра. Подрочить член бёдрами."
	require_user_legs = REQUIRE_ANY
	require_user_num_legs = 2
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	write_log_user = "Gave a thighjob"
	write_log_target = "Got a thighjob from"
	interaction_sound = null
	max_distance = 1
	p13user_emote = PLUG13_EMOTE_GROIN
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/do_thighjob/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_thighjob(target, is_hidden)

	if(!isclownjob(target))
		return

	if(prob(50))
		//var/genital_name = target.get_penetrating_genital_name(TRUE)
		target.visible_message("<span class='lewd'>\ <b>[target]</b> забавно хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/clothesplosion
	description = "Резко снять всю свою одежду!"
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	interaction_sound = null
	max_distance = 0
	write_log_user = "Exploded out of their clothes"

/datum/interaction/lewd/clothesplosion/display_interaction(mob/living/carbon/user, mob/living/carbon/target)
	if(!istype(user))
		return

	user.clothing_burst(FALSE)

////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// 									U N H O L Y										   /////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/interaction/lewd/unholy
	description = null

/datum/interaction/lewd/unholy/New()
	. = ..()
	interaction_flags |= INTERACTION_FLAG_UNHOLY_CONTENT

/datum/interaction/lewd/unholy/do_facefart
	description = "Напердеть на лицо."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "на его промежность напердел"
	write_log_user = "перданул на лицо"

/datum/interaction/lewd/unholy/do_facefart/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_facefart(target, is_hidden)

/datum/interaction/lewd/unholy/do_crotchfart
	description = "Напердеть на промежность."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "на его промежность напердел"
	write_log_user = "перданул на промежность"

/datum/interaction/lewd/unholy/do_crotchfart/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_crotchfart(target, is_hidden)

/datum/interaction/lewd/unholy/do_fartfuck
	description = "Трахнуть в задницу с пердежом."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "был(а) трахнут(а) в задницу с пердежом"
	write_log_user = "трахнул(а) в задницу с пердежом"

/datum/interaction/lewd/unholy/do_fartfuck/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_fartfuck(target, is_hidden)

	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\ Задница <b>[target]</b> смешно хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/unholy/suck_fart
	description = "Высосать газы из задницы ртом."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его газы высосал из задницы"
	write_log_user = "высосал газы из задницы"

/datum/interaction/lewd/unholy/suck_fart/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.suck_fart(target, is_hidden)

/datum/interaction/lewd/unholy/do_faceshit
	description = "Насрать на лицо."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его лицо было обосрано"
	write_log_user = "насрал на лицо"

/datum/interaction/lewd/unholy/do_faceshit/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_faceshit(target, is_hidden)

/datum/interaction/lewd/unholy/do_crotchshit/
	description = "Насрать на промежность."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его промежность была обосрана"
	write_log_user = "насрал на промежность"

/datum/interaction/lewd/unholy/do_crotchshit/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_crotchshit(target, is_hidden)

/datum/interaction/lewd/unholy/do_shitfuck
	description = "Трахнуть в задницу с говнецом."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "трахнут в задницу с говнецом"
	write_log_user = "трахнул в задницу с говнецом"

/datum/interaction/lewd/unholy/do_shitfuck/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.do_shitfuck(target, is_hidden)

	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\ Жопа <b>[target]</b>забавно хонкает!</span>")

	playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/unholy/suck_shit
	description = "Высосать говно из задницы."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его говно высосал из задницы"
	write_log_user = "высосал говно из задницы"

/datum/interaction/lewd/unholy/suck_shit/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.suck_shit(target, is_hidden)

/datum/interaction/lewd/unholy/piss_over
	description = "Обоссать с ног до головы."
	required_from_user = INTERACTION_REQUIRE_BOTTOMLESS
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "получает золотой дождь от"
	write_log_user = "нассал на"

/datum/interaction/lewd/unholy/piss_over/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.piss_over(target, is_hidden)

/datum/interaction/lewd/unholy/piss_mouth
	description = "Нассать в рот."
	max_distance = 1
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_BOTTOMLESS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	write_log_user = "pissed in someone's mouth"
	write_log_target = "got their mouth filled with piss by"

/datum/interaction/lewd/unholy/piss_mouth/display_interaction(mob/living/carbon/user, mob/living/target)
	if(!istype(user))
		to_chat(user, span_warning("You're not a carbon entity."))
		return
	var/is_hidden = ..()
	user.piss_mouth(target, is_hidden)

