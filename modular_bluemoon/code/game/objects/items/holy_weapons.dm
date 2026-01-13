/obj/item/aspergillum
	name = "Holy Aspergillum"
	desc = "Древний инструмент для окропления святой водой. Да будет смыта ересь с этой станции!"
	icon = 'modular_bluemoon/icons/obj/items_and_weapons.dmi'
	icon_state = "aspergillum"
	force = 0
	throwforce = 0
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("blessed", "sprinkled with holy water", "sanctified")
	hitsound = 'sound/effects/splash.ogg'
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF

	var/radius = 3
	var/busy = FALSE
	var/wet = FALSE
	var/water_per_use = 20
	var/water_per_transfer = 10
	var/sprinkling_delay = 8 SECONDS
	var/list/prayers = list("Exorcizo te, creatura aquæ, in nomine Dei Patris omnipotentis, et in nomine Jesu Christi, Filii ejus Domini nostri, et in virtute Spiritus Sancti",
							"Deus, qui ad salutem humani generis maxima quæque sacramenta in aquarum substantia condidisti",
							"Non illic resideat spiritus pestilens, non aura corrumpens: discedant omnes insidiæ latentis inimici",
							"Ut quidquid in domibus vel in locis fidelium hæc unda resperserit careat omni immunditia, liberetur a noxa")

/obj/item/aspergillum/examine(mob/user)
	. = ..()
	if(!user.mind?.isholy)
		. += span_warning("<hr>Вы не понимаете, как пользоваться этой вещью...")
	else
		. += span_notice("<hr>На кропиле сейчас [wet ? span_greenannounce("есть немного") : span_warning("НЕТ")] святой воды")
		. += span_notice("Чтобы освятить местность в радиусе <b>[radius] тайлов</b> вокруг, используйте кропило в руке на протяжении <b>[sprinkling_delay / 10] секунд</b>")
		. += span_notice("На одно использование уходит <b>[water_per_use] юнитов</b> святой воды. Чтобы восполнить, используйте кропило на любом контейнере, где она есть")


/obj/item/aspergillum/proc/set_wet(new_state)
	if(new_state == wet)
		return
	wet = new_state
	icon_state = wet ? "[initial(icon_state)]_w" : "[initial(icon_state)]"
	update_appearance()

/obj/item/aspergillum/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!ishuman(user))
		to_chat(user, span_warning("Вы не понимаете, как этим пользоваться!"))
		return
	var/mob/living/carbon/human/chaplain = user
	if(!chaplain.mind || !chaplain.mind.isholy)
		to_chat(chaplain, span_warning("Вы не чувствуете себя достаточно [chaplain.gender == FEMALE ? "любимой" : "любимым"] высшими силами, чтобы пользоваться [src]..."))
		return
	// Опрыскиваем людей
	if(isliving(target))
		user.DelayNextAction(CLICK_CD_MELEE)
		if(wet)
			chaplain.visible_message(span_warning("[chaplain] опрыскивает [target] святой водой с помощью [src]!"))
			if(ishuman(target))
				var/mob/living/carbon/human/blessed = target
				chaplain.whisper("[pick(prayers)]")
				playsound(src, 'sound/effects/splash.ogg', 10)
				if(iscatperson(blessed) && prob(40))
					blessed.emote("hiss")
				if(prob(50))
					blessed.reagents.add_reagent(/datum/reagent/water/holywater, water_per_transfer)
					set_wet(FALSE)
				if(prob(50))
					playsound(blessed, 'sound/effects/pray.ogg', 35)
		return ..()

	// Собираем реагенты
	if(wet)
		to_chat(chaplain, span_warning("Нет нужды собирать отсюда святую воду."))
		return
	if(QDELETED(target) || !target.reagents)
		to_chat(chaplain, span_warning("Вы не можете собрать отсюда святой воды!"))
		return
	if(!target.reagents.total_volume || !target.is_drawable())
		to_chat(chaplain, span_warning("Вы не можете собрать святой воды с [target]."))
		return
	if(target.reagents.get_reagent_amount(/datum/reagent/water/holywater) < water_per_use)
		to_chat(chaplain, span_warning("В [target] слишком мало святой воды."))
		return
	target.reagents.remove_reagent(/datum/reagent/water/holywater, water_per_use)
	set_wet(TRUE)
	playsound(src, 'sound/effects/splash.ogg', 20)
	to_chat(chaplain, span_notice("Вы смачиваете [src] в [target]."))


/obj/item/aspergillum/attack_self(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Вы не понимаете, как этим пользоваться!"))
		return
	var/mob/living/carbon/human/chaplain = user
	if(!chaplain.mind || !chaplain.mind.isholy)
		to_chat(chaplain, span_warning("Вы не чувствуете себя достаточно [chaplain.gender == FEMALE ? "любимой" : "любимым"] высшими силами, чтобы пользоваться [src]..."))
		return
	if(!wet)
		to_chat(chaplain, span_warning("Нужно сначала смочить [src] в святой воде!"))
		return
	if(busy)
		to_chat(chaplain, span_warning("Вы уже используете [src]."))
		return
	chaplain.visible_message(span_his_grace("[chaplain] начинает окроплять всё вокруг святой водой при помощи [src]..."), span_his_grace("Вы начинаете окроплять всё вокруг святой водой при помощи [src]..."))
	busy = TRUE
	if(!do_after(chaplain, sprinkling_delay, get_turf(chaplain.loc)))
		busy = FALSE
		return

	for(var/obj/effect/rune/R in oview(radius, chaplain))
		R.invisibility = 0
	for(var/turf/T in oview(radius, chaplain))
		T.Bless()
	set_wet(FALSE)
	playsound(src, 'sound/effects/pray.ogg', 30)
	chaplain.whisper("[pick(prayers)]")
	sleep(0.5 SECONDS)
	var/list/end_prayers = list("In nomine Domini Patris", "et Filii", "et Spiritus Sancti", "Amen.")
	for(var/i = 1, i <= GLOB.cardinals.len, i++)
		chaplain.whisper("[end_prayers[i]]")
		var/blessed_turf = get_turf(get_step(chaplain.loc, GLOB.cardinals[i]))
		if(isturf(blessed_turf))
			sleep(0.5 SECONDS)
			chaplain.dir = GLOB.cardinals[i]
			chaplain.do_attack_animation(blessed_turf, ATTACK_EFFECT_BOOP, src)
			playsound(src, 'sound/effects/splash.ogg', 10)
	busy = FALSE
	. = ..()

/obj/item/aspergillum/ert
	name = "Inquisitor's Aspergillum"
	desc = "Древний инструмент для окропления святой водой, улучшенный для лучших инквизиторов ПАКТа, мокрый не столько от святой воды, сколько от крови еретиков. Бегите, грешники!"
	icon_state = "aspergillum_ert"
	attack_verb = list("exorcised", "sprinkled with holy water... violently", "purged of heresy")
	resistance_flags = INDESTRUCTIBLE
	water_per_transfer = 33 // Магия блюспейса
	water_per_use = 3 // Магия блюспейса
	sprinkling_delay = 3 SECONDS
	wet = TRUE
	radius = 7
	prayers = list("LET ALL HERESY BE PURGED!",
					"WITNESS HOLY LIGHT, HERETICS!",
					"BE EXPELLED, UNHOLY!",
					"IN THE NAME OF GOD!")

/obj/item/aspergillum/ert/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_ATTACK_HAND, PROC_REF(check_hand_attack))

/obj/item/aspergillum/ert/Destroy()
	UnregisterSignal(src, COMSIG_ATOM_ATTACK_HAND)
	. = ..()

/obj/item/aspergillum/ert/proc/check_hand_attack(datum/source, mob/user)
	if(istype(user, /mob/living/simple_animal/drone/cogscarab))
		to_chat(user, span_cultlarge("[src] защищается от вашей попытки его подобрать!"))
		return COMPONENT_NO_ATTACK_HAND

/obj/item/aspergillum/ert/proc/check_unholy(atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/livingmob = target
	if(livingmob.mind && (livingmob.mind.has_antag_datum(/datum/antagonist/heretic) || livingmob.mind?.has_antag_datum(/datum/antagonist/bloodsucker) || livingmob.mind?.has_antag_datum(/datum/antagonist/devil)))
		return TRUE
	if(is_servant_of_ratvar(livingmob) || iscultist(livingmob) || isconstruct(livingmob) || isclockmob(livingmob))
		return TRUE
	if(istype(livingmob, /mob/living/simple_animal/hostile/clockwork) || istype(livingmob, /mob/living/simple_animal/drone/cogscarab))
		return TRUE
	if(istype(livingmob, /mob/living/simple_animal/hostile/clockcultistmelee) || istype(livingmob, /mob/living/simple_animal/hostile/clockcultistranged))
		return TRUE
	return FALSE

/obj/item/aspergillum/ert/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(check_unholy(target))
		var/mob/living/heretic = target
		heretic.adjustStaminaLoss(25, TRUE)
		if(istype(heretic, /mob/living/simple_animal))
			heretic.apply_damage(20, BRUTE)
		else if(wet && ishuman(heretic) && prob(33))
			heretic.reagents.add_reagent(/datum/reagent/water/holywater, water_per_transfer)
			set_wet(FALSE)
		user.say("[pick(prayers)]")
		to_chat(heretic, span_cultbold("Святая энергия жжёт вас!"))
		user.DelayNextAction(CLICK_CD_MELEE)
		return
	. = ..()

/obj/item/aspergillum/ert/examine(mob/user)
	. = ..()
	var/can_read_unholy = isobserver(user) || check_unholy(user)
	if(can_read_unholy)
		. += span_cultbold("<hr>Эта вещь наполнена святой энергией! Подбирать такую кому-то из грешников было бы очень неблагоразумно!")

/obj/item/aspergillum/ert/can_be_pulled(user, grab_state, force)
	. = ..()
	if(!.)
		return FALSE
	if(check_unholy(user))
		if(ishuman(user))
			var/mob/living/carbon/human/pickuper = user
			pickuper.Dizzy(5 SECONDS)
			pickuper.Confused(10 SECONDS)
			pickuper.Stun(3 SECONDS)
			pickuper.blur_eyes(7)
			pickuper.adjustStaminaLoss(25, TRUE)
			pickuper.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10, 100)
			pickuper.drop_all_held_items()
			to_chat(pickuper, span_userdanger("Священная энергия пробегает по вашим венам!"))
			pickuper.emote("shiver")
			playsound(pickuper,'sound/hallucinations/veryfar_noise.ogg', 40)
			return FALSE
		else
			var/mob/living/sufferer = user
			sufferer.apply_damage(15, BRUTE)
			playsound(sufferer,'sound/hallucinations/veryfar_noise.ogg', 10)
			to_chat(sufferer, span_cultlarge("[src] защищается от вашей попытки его утащить!"))
			return FALSE

/obj/item/aspergillum/ert/pickup(mob/living/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Вы не можете поднять эту вещь!"))
		return
	var/mob/living/carbon/human/pickuper = user
	if(check_unholy(user))
		pickuper.Confused(10 SECONDS)
		pickuper.Stun(5 SECONDS)
		pickuper.blur_eyes(7)
		pickuper.adjustStaminaLoss(30)
		pickuper.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10, 100)
		pickuper.drop_all_held_items()
		to_chat(pickuper, span_userdanger("Священная энергия пробегает по вашим венам!"))
		pickuper.emote("shiver")
		playsound(pickuper,'sound/hallucinations/veryfar_noise.ogg', 40)
		return
	. = ..()

/obj/item/nullrod/holydildo
	name = "Holy dildo"
	desc = "Golden dildo with holy features."
	icon_state = "holy_dildo"
	item_state = "holy_dildo"
	icon = 'modular_bluemoon/icons/obj/items_and_weapons.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	attack_verb = list("banished", "struck", "smacked", "exorcised")
	force = 12
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY
	var/hole = CUM_TARGET_VAGINA

/obj/item/nullrod/holydildo/CtrlShiftClick(mob/living/carbon/human/user as mob)
	hole = hole == CUM_TARGET_VAGINA ? CUM_TARGET_ANUS : CUM_TARGET_VAGINA
	to_chat(user, span_notice("Я целюсь в... [hole]."))

/obj/item/nullrod/holydildo/attack(mob/living/target, mob/living/user)
	user.DelayNextAction(CLICK_CD_MELEE)
	if (user.a_intent == INTENT_HELP)
		do_eblya(target, user)
	else
		if (user.a_intent == INTENT_HARM)
			. = ..()
		else
			return



/obj/item/nullrod/holydildo/proc/do_eblya(mob/living/target, mob/living/user)
	var/message = ""
	var/lust_amt = 0
	if(!user.canUseTopic(target, BE_CLOSE))
		return
	if(ishuman(target) && (target?.client?.prefs?.toggles & VERB_CONSENT))
		if(user.zone_selected == BODY_ZONE_PRECISE_GROIN)
			switch(hole)
				if(CUM_TARGET_VAGINA)
					if(target.has_vagina() == HAS_EXPOSED_GENITAL)
						message = (user == target) ? pick("Мысленно устремив взгляд в бесконечность, она крепко обхватывает '\the [src]' и начинает погружать это в свою глубину.", "С величественным постоянством она наполняет свою киску '\the [src]' во имя своей веры.", "Смиренно постанывая, она садится на '\the [src]' в акте предания и самоотдачи.") : pick("Свершая акт святой любви, она проникает внутрь <b>[target]</b> с использованием '\the [src]' в своем стремлении к блаженству.", "В торжественном ритуале она внедряет '\the [src]' прямо в киску <b>[target]</b>.")
						lust_amt = NORMAL_LUST
				if(CUM_TARGET_ANUS)
					if(target.has_anus() == HAS_EXPOSED_GENITAL)
						message = (user == target) ? pick("С верой в душе, она крепко обхватывает '\the [src]' и начинает внедрять это в свою попку.", "С величественным постоянством она наполняет свою попку '\the [src]' во имя своей веры.", "Смиренно постанывая, она садится на '\the [src]' в акте ритуала святой любви.") : pick("С величием души, она трахает <b>[target]</b> прямо в попку с помощью '\the [src]'.", "В сакральном обряде она активно суёт '\the [src]' прямо в попку <b>[target]</b>, совершая акт любви.")
						lust_amt = NORMAL_LUST
	if(message)
		user.visible_message(span_lewd("<b>[user]</b> [message]"))
		target.handle_post_sex(lust_amt, null, user)
		playsound(loc, pick('modular_sand/sound/interactions/bang4.ogg',
							'modular_sand/sound/interactions/bang5.ogg',
							'modular_sand/sound/interactions/bang6.ogg'), 70, 1, -1)
		////
		// пошло благословление
		new /obj/effect/temp_visual/yellowsparkles(target.loc)
		// чисто внутряк хилим
		target.adjustOrganLoss(ORGAN_SLOT_HEART, -1.5)
		target.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1.5)
		target.adjustToxLoss(-1.5)
		target.adjustCloneLoss(-1.5)
		// вкусное печенько
		//if(target.get_lust() >= (target.get_lust_tolerance() * 3))  // проверка на кончание (пока сломано)
		if(prob(3))
			new /obj/item/reagent_containers/food/snacks/cookie(target.loc)
			to_chat(user, "<span class='adminnoticevin'>Your prayers have been answered!! You received the <b>best cookie</b>!</span>")
			SEND_SOUND(target, sound('sound/effects/pray_chaplain.ogg'))

///////////////

/obj/item/reagent_containers/censer
	name = "Orthodox Censer"
	desc = "The golden holy smoking ball."
	icon = 'modular_bluemoon/icons/obj/chemical.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	icon_state = "censer"
	item_state = "censer"
	w_class = WEIGHT_CLASS_TINY
	var/chem_volume = 100
	var/vapetime = FALSE //this so it won't puff out clouds every tick
	var/lit = FALSE
	reagent_flags = OPENCONTAINER

//obj/item/reagent_containers/censer/attackby(obj/item/O, mob/user, params)
//obj/item/clothing/glasses/AltClick(mob/user)

/obj/item/reagent_containers/censer/equipped(mob/user, slot, initial)
	. = ..()
	if (slot != ITEM_SLOT_HANDS)
		lit = FALSE
		icon_state = "censer"
		STOP_PROCESSING(SSobj, src)
		return

/obj/item/reagent_containers/censer/attack_self(mob/user)
	lit = !lit
	if (lit)
		icon_state = "censer_anim"
		START_PROCESSING(SSobj, src)

	else
		icon_state = "censer"
		STOP_PROCESSING(SSobj, src)

/obj/item/reagent_containers/censer/process()
	vapetime++
	if (item_flags & IN_STORAGE)
		lit = FALSE
		icon_state = "censer"
		STOP_PROCESSING(SSobj, src)
		return

	if(!reagents.total_volume)
		if(ismob(loc))
			to_chat(usr, "<span class='notice'>[src] is empty!</span>")
			STOP_PROCESSING(SSobj, src)
			//it's reusable so it won't unequip when empty
		return

	if( vapetime > 3)//Time to start puffing those fat vapes, yo.
		var/datum/effect_system/smoke_spread/chem/smoke_machine/s = new
		s.set_up(reagents, 1, 24, loc)
		s.start()
		vapetime = 0



///////////////

/obj/item/reagent_containers/censer/incense
	icon_state = "incense"
	item_state = "incense"

/obj/item/reagent_containers/censer/incense/attack_self(mob/user)
	lit = !lit
	if (lit)
		icon_state = "incense_anim"
		START_PROCESSING(SSobj, src)

	else
		icon_state = "incense"
		STOP_PROCESSING(SSobj, src)
