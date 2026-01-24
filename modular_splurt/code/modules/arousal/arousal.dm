/mob/living/carbon/human/mob_climax_partner(obj/item/organ/genital/G, mob/living/L, spillage = TRUE, mb_time = 30, obj/item/organ/genital/Lgen = null, forced = FALSE, anonymous = FALSE)
	. = ..()
	L.receive_climax(src, Lgen, G, spillage, forced = forced)
	if(iswendigo(L))
		var/mob/living/carbon/wendigo/W = L
		if(W.pulling == src)
			W.slaves |= src
			to_chat(src, "<font color='red'> You are now [W]'s slave! Serve your master properly! </font>")

/mob/living/proc/receive_climax(mob/living/partner, obj/item/organ/genital/receiver, obj/item/organ/genital/source, spill, forced)

	if (istype(receiver, /obj/item/organ/genital/penis) || istype(receiver, /obj/item/organ/genital/vagina))
		partner.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, PLUG13_STRENGTH_LOW, PLUG13_DURATION_MEDIUM)
	else if (istype(receiver, /obj/item/organ/genital/anus))
		partner.client?.plug13.send_emote(PLUG13_EMOTE_ASS, PLUG13_STRENGTH_LOW, PLUG13_DURATION_MEDIUM)
	else if (istype(receiver, /obj/item/organ/stomach))
		partner.client?.plug13.send_emote(PLUG13_EMOTE_MOUTH, PLUG13_STRENGTH_LOW, PLUG13_DURATION_MEDIUM)

	//gregnancy...
	if(!spill && istype(source, /obj/item/organ/genital/penis) && \
		istype(receiver, /obj/item/organ/genital/vagina) && getorganslot(ORGAN_SLOT_WOMB))
		var/obj/item/organ/genital/penis/peenus = source
		if(!(locate(/obj/item/genital_equipment/condom) in peenus.contents))
			impregnate(partner)

	if(!receiver || spill || forced)
		return

	receiver.climax_modify_size(partner, source)

//handles impregnation, also prefs
/mob/living/proc/impregnate(mob/living/partner, obj/item/organ/W, baby_type = /mob/living/carbon/human)
	var/obj/item/organ/container = W
	if(!container)
		container = getorganslot(ORGAN_SLOT_WOMB)
	if(!container)
		return

	var/virility = partner?.client?.prefs?.virility || 0
	var/fertility = client?.prefs?.fertility || 0

	if(!fertility || is_type_in_typecache(src.type, GLOB.pregnancy_blocked_mob_typecache))
		return

	// Базовый шанс с балансом в пользу женщин.. Почему ? Потому что девочки у нас вынашивают. и если у них фертильность 100 то пусть потом не удивляюьтся что залетели от парня.
	var/chance = min(virility * 0.8, fertility * 1.2) * (1 + (rand(-15, 15) / 100))

	// Бонус от эстрального цикла
	var/estrus_total_bonus = 0

	// Проверяем квирк у ПОЛУЧАТЕЛЯ
	if(HAS_TRAIT(src, TRAIT_ESTROUS_ACTIVE))
		var/datum/quirk/estrous_active/Q = get_quirk(/datum/quirk/estrous_active)
		if(Q && !QDELETED(Q))
			// Базовый бонус 5% + накопленный бонус от времени
			var/estrus_bonus = round((0.05 + Q.time_bonus) * 100)
			estrus_total_bonus += estrus_bonus

	// Добавляем итоговый бонус
	if(estrus_total_bonus > 0)
		chance += estrus_total_bonus

	chance = clamp(chance, 0, 100)

	if(prob(chance))
		var/num_eggs = rand(1, 2)
		if(fertility > 80 && prob(30))
			num_eggs += 1

		for(var/i = 1, i <= num_eggs, i++)
			var/obj/item/oviposition_egg/eggo = new()
			eggo.forceMove(container)
			eggo.AddComponent(/datum/component/pregnancy, src, partner, baby_type)

/mob/living/carbon/human/do_climax(datum/reagents/R, atom/target, obj/item/organ/genital/sender, spill, cover = FALSE, obj/item/organ/genital/receiver, anonymous = FALSE)
	if(!sender)
		return
	if(!target || !R)
		return
	if(SEND_SIGNAL(src, COMSIG_MOB_CLIMAX, R, target, sender, receiver, spill, anonymous))
		return

	var/cached_fluid
	if(isliving(target) && !spill)
		var/mob/living/L = target
		var/list/blacklist = L.client?.prefs.gfluid_blacklist
		if((sender.get_fluid_id() in blacklist) || ((/datum/reagent/blood in blacklist) && ispath(sender.get_fluid_id(), /datum/reagent/blood)))
			cached_fluid = sender.get_fluid_id()
			var/default = sender.get_default_fluid()
			sender.set_fluid_id(default)

	if(istype(sender, /obj/item/organ/genital/penis))
		var/obj/item/genital_equipment/sounding/sounding_rod = locate(/obj/item/genital_equipment/sounding) in sender.contents
		if(sounding_rod)
			var/message = ""
			if(locate(/obj/item/genital_equipment/chastity_cage) in sender.contents)
				message = "Ты ощущаешь, как стержень упирается в клетку и не может выйти, поток жидкости обтекает его, раздувая твой член и вызывая болезненную пульсацию!"
				if(HAS_TRAIT(src, TRAIT_MASO))
					message = span_userlove(message)
				else
					message = span_alertwarning(message)
			else
				spill = TRUE
				message = span_userlove("Ты чувствуешь, как стержень выталкивается из твоей уретры вместе со струей оргазменной жидкости!")
				sounding_rod.forceMove(get_turf(src))
			to_chat(src, message)

	if(cover == TRUE)
		if(istype(sender, /obj/item/organ/genital/penis) || HAS_TRAIT(src, TRAIT_MESSY))
			var/overlay_color
			if((istype(sender, /obj/item/organ/genital/penis) || istype(sender, /obj/item/organ/genital/vagina)) && sender.linked_organ)
				overlay_color = sender.linked_organ.fluid_id.color
			target.add_cum_overlay(sender.pick_cum_overlay(), overlay_color)

	. = ..()

	if(cached_fluid)
		sender.set_fluid_id(cached_fluid)

/mob/living/carbon/human/mob_fill_container(obj/item/organ/genital/G, obj/item/reagent_containers/container, mb_time, obj/item/sucking_machine/M)
	if(!M)
		return ..()

	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	var/main_fluid = lowertext(G.get_fluid_name())
	if(mb_time)
		visible_message("<span class='love'>You hear a strong suction sound coming from the [M.name] on [src]'s [G.name].</span>", \
							"<span class='userlove'>The [M.name] pumps faster, trying to get you over the edge.</span>", \
							"<span class='userlove'>Something vacuums your [G.name] with a quiet but powerfull vrrrr.</span>")
		if(!do_after(src, mb_time, target = src, timed_action_flags = (IGNORE_HELD_ITEM|IGNORE_INCAPACITATED)) || !in_range(src, container) || !G.climaxable(src, TRUE))
			return
	visible_message("<span class='love'>[src] twitches as [ru_ego()] [main_fluid] trickles into <b>[container]</b>.</span>", \
								"<span class='userlove'>[M] sucks out all the [main_fluid] you had been saving up into <b>[container]</b>.</span>", \
								"<span class='userlove'>You feel a vacuum sucking on your [G.name] as you climax!</span>")
	do_climax(fluid_source, container, G, FALSE, cover = TRUE)
	emote("moan")

/mob/living/carbon/human/proc/mob_climax_over(obj/item/organ/genital/G, mob/living/L, spillage = TRUE, mb_time = 30)
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	if(mb_time) //Skip warning if this is an instant climax.
		to_chat(src,"<span class='userlove'>You're about to climax over [L]!</span>")
		to_chat(L,"<span class='userlove'>[src] is about to climax over you!</span>")
		if(!do_after(src, mb_time, target = src) || !in_range(src, L) || !G.climaxable(src, TRUE))
			return
	to_chat(src,"<span class='userlove'>You climax all over [L] using your [G.name]!</span>")
	to_chat(L, "<span class='userlove'>[src] climaxes all over you using [ru_ego()] [G.name]!</span>")
	do_climax(fluid_source, L, G, spillage, cover = TRUE)

/mob/living/carbon/human
	var/covered_in_cum = FALSE

/atom/proc/add_cum_overlay(state = "cum_normal", cum_color = "#FFFFFF") //This can go in a better spot, for now its here.
	var/const/overlays_limit = 10
	if(!istype(src, /mob/living/carbon/human))
		return

	if(initial(icon) && initial(icon_state))
		var/list/active_overlays = get_cum_overlays() //BLUEMOON ADD
		if(active_overlays.len < overlays_limit) // BLUEMOON EDIT || Ограничение на оверлеи, иначе будет срабатывать VALIDATE_OVERLAY_LIMIT
			add_overlay(mutable_appearance(CUM_DMI, state, color = cum_color), ICON_MULTIPLY)
		var/mob/living/carbon/human/H = src
		H.covered_in_cum = TRUE
		to_chat(H, span_love("Кажется тебя немножко забрызгали~"))

//BLUEMOON ADD START
/atom/proc/get_cum_overlays()
	var/list/active_overlays = list()
	for(var/over in src.overlays)
		var/image/MA = over
		if(MA && MA.icon == CUM_DMI && (MA.icon_state in CUM_STATES))
			active_overlays += MA
	return active_overlays
//BLUEMOON ADD END

/mob/living/carbon/human/proc/getPercentAroused()
    var/percentage = ((get_lust() / (get_climax_threshold())) * 100) // BLUEMOON EDIT
    return percentage

/atom/proc/wash_cum()
	overlays -= get_cum_overlays()
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		H.covered_in_cum = FALSE
	return TRUE

//arousal hud display

/atom/movable/screen/arousal
	name = "arousal"
	icon_state = "arousal0"
	icon = 'icons/obj/genitals/hud.dmi'
	screen_loc = ui_arousal

/atom/movable/screen/arousal/Initialize(mapload, mob/living/carbon/human/owner)
	. = ..()
	if(!istype(owner))
		return INITIALIZE_HINT_QDEL
	RegisterSignal(owner, COMSIG_MOB_LUST_UPDATED, PROC_REF(update_lust))

/atom/movable/screen/arousal/Click()
	if(!ishuman(usr))
		return FALSE
	if(!usr.client?.prefs.arousable)
		return
	var/mob/living/M = usr
	M.interact_with()

/atom/movable/screen/arousal/proc/update_lust(mob/living/carbon/human/source)
	SIGNAL_HANDLER

	if(!istype(source))
		return
	if(!source.client || !source.hud_used)
		return

	var/arousal_level = 0
	if(source.stat != DEAD)
		arousal_level = min(FLOOR(source.getPercentAroused(), 10),100)
	icon_state = "arousal[arousal_level]"
