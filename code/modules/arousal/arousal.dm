/mob/living
	//var/mb_cd_length = 1 SECONDS						//5 second cooldown for masturbating because fuck spam. // BLUEMOON EDIT commented
	var/last_climax = 0									// BLUEMOON EDIT

/mob/living/carbon/human
	var/arousal_rate = 1
/*
	var/saved_underwear = ""//saves their underwear so it can be toggled later
	var/saved_undershirt = ""
	var/saved_socks = ""
	var/hidden_underwear = FALSE
	var/hidden_undershirt = FALSE
	var/hidden_socks = FALSE


//Mob procs
/mob/living/carbon/human/verb/underwear_toggle()
	set name = "Toggle undergarments"
	set category = "IC"

	var/confirm = input(src, "Select what part of your form to alter", "Undergarment Toggling") as null|anything in list("Top", "Bottom", "Socks", "All")
	if(!confirm)
		return
	if(confirm == "Top")
		hidden_undershirt = !hidden_undershirt
		log_message("[hidden_undershirt ? "removed" : "put on" ] [ru_ego()] undershirt.", LOG_EMOTE)

	if(confirm == "Bottom")
		hidden_underwear = !hidden_underwear
		log_message("[hidden_underwear ? "removed" : "put on"] [ru_ego()] underwear.", LOG_EMOTE)

	if(confirm == "Socks")
		hidden_socks = !hidden_socks
		log_message("[hidden_socks ? "removed" : "put on"] [ru_ego()] socks.", LOG_EMOTE)

	if(confirm == "All")
		var/on_off = (hidden_undershirt || hidden_underwear || hidden_socks) ? FALSE : TRUE
		hidden_undershirt = on_off
		hidden_underwear = on_off
		hidden_socks = on_off
		log_message("[on_off ? "removed" : "put on"] all [ru_ego()] undergarments.", LOG_EMOTE)

	update_body(TRUE)
*/

/mob/living/carbon/human/proc/adjust_arousal(strength, cause = "manual toggle", aphro = FALSE,maso = FALSE, silent = FALSE) // returns all genitals that were adjust
	var/list/obj/item/organ/genital/genit_list = list()
	if(!client?.prefs.arousable || (aphro && (client?.prefs.cit_toggles & NO_APHRO)) || (maso && !HAS_TRAIT(src, TRAIT_MASO)))
		return // no adjusting made here
	var/enabling = strength > 0
	for(var/obj/item/organ/genital/G in internal_organs)
		if(istype(G, /obj/item/organ/genital/penis))
			//SPLURT edit
			if(CHECK_BITFIELD(G.genital_flags, GENITAL_CHASTENED) && enabling)
				to_chat(src, "<span class='userlove'>Твой [pick("член","пенис")] дергается в своей клетке!</span>") // BLUEMOON EDIT
				continue
			if(CHECK_BITFIELD(G.genital_flags, GENITAL_IMPOTENT) && enabling)
				to_chat(src, "<span class='userlove'>Твой [pick("член","пенис")] просто не может возбудиться!</span>") // BLUEMOON EDIT
				continue
		//
		if(G.genital_flags & GENITAL_CAN_AROUSE && !G.aroused_state && prob(abs(strength)*G.sensitivity * arousal_rate))
			G.set_aroused_state(enabling,cause)
			G.update_appearance()
			update_body(TRUE)
			if(G.aroused_state)
				genit_list += G
	if(enabling && !silent)
		for(var/obj/item/organ/genital/g in genit_list)
			to_chat(src, span_userlove("[g.arousal_verb]!"))
	return genit_list

/obj/item/organ/genital/proc/climaxable(mob/living/carbon/human/H, silent = FALSE) //returns the fluid source (ergo reagents holder) if found.
	if((genital_flags & GENITAL_FUID_PRODUCTION))
		. = reagents
	else
		if(linked_organ)
			. = linked_organ.reagents
	if(!. && !silent)
		to_chat(H, "<span class='warning'>Твой [name] не в состоянии производить собственную жидкость, ведь у него отсутствуют органы для этого.</span>")

/mob/living/carbon/human/proc/do_climax(datum/reagents/R, atom/target, obj/item/organ/genital/sender, spill = TRUE, cover = FALSE, obj/item/organ/genital/receiver, anonymous = FALSE)
	if(!sender)
		return
	if(!target || !R)
		return
	var/turfing = isturf(target)
	var/condomning
	if(istype(sender, /obj/item/organ/genital/penis))
		var/obj/item/organ/genital/penis/P = sender
		condomning = locate(/obj/item/genital_equipment/condom) in P.contents
	sender.generate_fluid(R)
	last_climax = world.time // BLUEMOON ADD
	log_message("Кончает [sender] благодаря [target]", LOG_EMOTE)

	client?.plug13.send_emote(PLUG13_EMOTE_GROIN, PLUG13_STRENGTH_MAX, PLUG13_DURATION_ORGASM)

	if(condomning)
		to_chat(src, "<span class='userlove'>Ты чувствуешь, как презерватив наполняется изнутри твоей спермой!</span>")
		R.trans_to(condomning, R.total_volume)
	else
		if(spill && R.total_volume > 0)
			var/turf/location = get_turf(target)
			var/obj/effect/decal/cleanable/semen/S = locate(/obj/effect/decal/cleanable/semen) in location
			var/obj/effect/decal/cleanable/semen/femcum/F = locate(/obj/effect/decal/cleanable/semen/femcum) in location
			if(istype(sender, /obj/item/organ/genital/penis))
				if(S && !istype(S, /obj/effect/decal/cleanable/semen/femcum))
					if(R.trans_to(S, R.total_volume))
						LAZYINITLIST(S.blood_DNA)
						S.blood_DNA |= get_blood_dna_list()
						S.update_icon()
						return
				else
					var/obj/effect/decal/cleanable/semendrip/drip = (locate(/obj/effect/decal/cleanable/semendrip) in location) || new(location)
					if(R.trans_to(drip, R.total_volume))
						LAZYINITLIST(drip.blood_DNA)
						drip.blood_DNA |= get_blood_dna_list()
						drip.update_icon()
						if(drip.reagents.total_volume >= 10)
							S = new(location)
							drip.reagents.trans_to(S, drip.reagents.total_volume)
							LAZYINITLIST(S.blood_DNA)
							S.blood_DNA |= drip.blood_DNA
							S.update_icon()
							qdel(drip)
						return
			if(istype(sender, /obj/item/organ/genital/vagina))
				if(F)
					if(R.trans_to(F, R.total_volume))
						LAZYINITLIST(F.blood_DNA)
						F.blood_DNA |= get_blood_dna_list()
						F.update_icon()
						return
				else
					F = new(location)
					if(R.trans_to(F, R.total_volume))
						LAZYINITLIST(F.blood_DNA)
						F.blood_DNA |= get_blood_dna_list()
						F.update_icon()
						return

		if(!turfing)
			// sandstorm edit - advanced cum drip
			var/amount_to_transfer = R.total_volume * (spill ? sender.fluid_transfer_factor : 1)
			var/mob/living/carbon/human/cummed_on = target
			if(!istype(cummed_on)) // not human
				R.trans_to(target, amount_to_transfer, log = TRUE)
			else // if human
				var/datum/reagents/copy = new()
				R.copy_to(copy, R.total_volume)

				// BLUEMOON EDIT START
				var/it_a_portal = FALSE

				if(anonymous) //most likely a portal fleshlight
					// Universal list of liquid transfer cases via portalpanties
					var/list/portal_cases = list(
						list( // receiver is wearing portal panties as a mask
							"panties" = cummed_on.wear_mask,
							"plight" = get_active_held_item()
						),
						list( // sender is wearing portal panties
							"panties" = w_underwear,
							"plight" = cummed_on.get_active_held_item()
						),
						list( // receiver is wearing portal panties
							"panties" = cummed_on.w_underwear,
							"plight" = get_active_held_item()
						)
					)

					for(var/case in portal_cases)
						var/obj/item/clothing/underwear/briefs/panties/portalpanties/p_panties = case["panties"]
						if(!istype(p_panties))
							continue

						var/obj/item/portallight/plight = case["plight"]
						if(!istype(plight))
							continue

						// checking that this is exactly the right fleshlight and portal
						if(plight.portalunderwear != p_panties)
							continue

						it_a_portal = TRUE // We are absolutely sure that this is a portal (i guess) -> anonymous + checks

						// checking that sender is either the target of the fleshlight or the target of the portal
						if(sender.name != plight.targetting && sender.name != p_panties.targetting)
							continue

						// checking if last_genital is sender P.S. because this process is called in all scenarios, and I won't/don't to fix it.
						if(last_genital != sender)
							continue

						// if the sender is the vagina, but the receiver is not the mouth, it is unacceptable
						if(istype(sender, /obj/item/organ/genital/vagina) && !istype(receiver, /obj/item/organ/stomach))
							continue

						R.trans_to(target, amount_to_transfer, log = TRUE)

						// sender = penis, in vagina or anus
						if(istype(sender, /obj/item/organ/genital/penis) && (istype(receiver, /obj/item/organ/genital/vagina) || istype(receiver, /obj/item/organ/genital/anus)))
							if(copy.total_volume > 0)
								cummed_on.apply_status_effect(STATUS_EFFECT_DRIPPING_CUM, copy, get_blood_dna_list(), receiver)
						break

				if(!it_a_portal && (!last_genital || last_genital.type == sender.type)) // some lewd interactions are broken, so we checking type
					if(istype(receiver, /obj/item/organ/stomach))	//in mouth
						switch(sender.type)
							if(/obj/item/organ/genital/penis)
								if(src.last_lewd_datum?.required_from_user_exposed == INTERACTION_REQUIRE_PENIS && src.last_lewd_datum?.required_from_target == INTERACTION_REQUIRE_MOUTH)	//panel user is sender
									R.trans_to(target, amount_to_transfer, log = TRUE)
								else if(cummed_on.last_lewd_datum?.required_from_user == INTERACTION_REQUIRE_MOUTH && cummed_on.last_lewd_datum?.required_from_target_exposed == INTERACTION_REQUIRE_PENIS)	//panel user is receiver
									R.trans_to(target, amount_to_transfer, log = TRUE)
							if(/obj/item/organ/genital/vagina)
								if(src.last_lewd_datum?.required_from_user_exposed == INTERACTION_REQUIRE_VAGINA && src.last_lewd_datum?.required_from_target == INTERACTION_REQUIRE_MOUTH)
									R.trans_to(target, amount_to_transfer, log = TRUE)
								else if(cummed_on.last_lewd_datum?.required_from_user == INTERACTION_REQUIRE_MOUTH && cummed_on.last_lewd_datum?.required_from_target_exposed == INTERACTION_REQUIRE_VAGINA)
									R.trans_to(target, amount_to_transfer, log = TRUE)
							//most likely not needed here
							// if(/obj/item/organ/genital/breasts)
							// 	if(src.last_lewd_datum?.required_from_user_exposed == INTERACTION_REQUIRE_BREASTS && src.last_lewd_datum?.required_from_target == INTERACTION_REQUIRE_MOUTH)
							// 		R.trans_to(target, amount_to_transfer, log = TRUE)
							// 	else if(cummed_on.last_lewd_datum?.required_from_user == INTERACTION_REQUIRE_MOUTH && cummed_on.last_lewd_datum?.required_from_target_exposed == INTERACTION_REQUIRE_BREASTS)
							// 		R.trans_to(target, amount_to_transfer, log = TRUE)
					else if(istype(sender, /obj/item/organ/genital/penis))	//not in mouth and penis orgasm
					// BLUEMOON EDIT END
						R.trans_to(target, amount_to_transfer, log = TRUE)
						if(istype(receiver, /obj/item/organ/genital/vagina) || istype(receiver, /obj/item/organ/genital/anus))
							if(copy.total_volume > 0)
								cummed_on.apply_status_effect(STATUS_EFFECT_DRIPPING_CUM, copy, get_blood_dna_list(), receiver)

	sender.last_orgasmed = world.time
	R.clear_reagents()
	//sandstorm edit - gain momentum from dirty deeds.
	if(!Process_Spacemove(turn(dir, 180)))
		newtonian_move(turn(dir, 180))
	//

/mob/living/carbon/human/proc/mob_climax_outside(obj/item/organ/genital/G, mb_time = 30) //This is used for forced orgasms and other hands-free climaxes
	var/datum/reagents/fluid_source = G.climaxable(src, TRUE)
	if(!fluid_source)
		to_chat(src,"<span class='userdanger'>Твой [G.name] предательски сжимается, не имея возможности кончить...</span>")
		return
	if(mb_time) //as long as it's not instant, give a warning
		to_chat(src,"<span class='userlove'>Вы чувствуете, что вот-вот достигнете оргазма!</span>")
		if(!do_after(src, mb_time, target = src) || !G.climaxable(src, TRUE))
			return
	to_chat(src,"<span class='userlove'>Вы оргазмируете[isturf(loc) ? ", обливая пространство под собой" : ""]!</span>")
	do_climax(fluid_source, loc, G)

/mob/living/carbon/human/proc/mob_climax_partner(obj/item/organ/genital/G, mob/living/L, spillage = TRUE, mb_time = 30, obj/item/organ/genital/Lgen = null, forced = FALSE, anonymous = FALSE)
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	if(mb_time) //Skip warning if this is an instant climax.
		if(!do_after(src, mb_time, target = src) || !in_range(src, L) || !G.climaxable(src, TRUE))
			return
	SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
	do_climax(fluid_source, spillage ? loc : L, G, spillage, FALSE, Lgen, anonymous)

/mob/living/carbon/human/proc/mob_fill_container(obj/item/organ/genital/G, obj/item/reagent_containers/container, mb_time = 30) //For beaker-filling, beware the bartender
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	if(mb_time)
		to_chat(src,"<span class='userlove'>Вы начали [G.masturbation_verb] прямо над <b>[container]</b>. [G.ru_name_capital] в готовности к этому...</span>")
		if(!do_after(src, mb_time, target = src, timed_action_flags = (IGNORE_HELD_ITEM|IGNORE_INCAPACITATED)) || !in_range(src, container) || !G.climaxable(src, TRUE))
			return
	to_chat(src,"<span class='userlove'>[G.ru_name_capital] стимулируется вашими же усилиями, вы пытаетесь наполнить <b>[container]</b>.</span>")
	message_admins("[ADMIN_LOOKUPFLW(src)] использует [ru_ego()] [G.name], чтобы наполнить <b>[container]</b> [G.get_fluid_name()].")
	log_consent("[key_name(src)] использует [ru_ego()] [G.name], чтобы наполнить <b>[container]</b> [G.get_fluid_name()].")
	do_climax(fluid_source, container, G, FALSE, cover = TRUE)

/mob/living/carbon/human/proc/pick_climax_genitals(silent = FALSE)
	var/list/genitals_list
	// BLUEMOON EDIT START

	for(var/obj/item/organ/genital/G in internal_organs)
		if((G.genital_flags & CAN_CLIMAX_WITH) && (G.is_exposed() || G.always_accessible)) //filter out what you can't masturbate with
			LAZYADD(genitals_list, G)
	if(LAZYLEN(genitals_list))
		for(var/obj/item/organ/genital/listed in genitals_list)
			genitals_list[listed] = new /mutable_appearance(listed)
		var/obj/item/organ/genital/ret_organ = genitals_list.len == 1 ? genitals_list[1] : show_radial_menu(src, src, genitals_list)
		// BLUEMOON EDIT END
		//SPLURT edit
		if(CHECK_BITFIELD(ret_organ.genital_flags, GENITAL_CHASTENED))
			visible_message("<span class='userlove'><b>\The [src]</b> fumbles with their cage with a whine!</span>",
							"<span class='userlove'>You can't climax with a cage on it!</span>",
							ignored_mobs = get_unconsenting())
			return
		//
		return ret_organ
	else if(!silent)
		to_chat(src, "<span class='warning'>Вы не можете достичь кульминации без наличия гениталий.</span>")

// BLUEMOON EDIT START
/mob/living/carbon/human/proc/pick_partner(silent = FALSE, covering = FALSE)
	var/list/partners = list()
	for(var/mob/living/L in view(1))
		if(L != src && L.ckey && L.mind && Adjacent(L))
			if(!iscarbon(L))
				LAZYADD(partners, L)
			else
				var/mob/living/carbon/C = L
				if(covering || C.exposed_genitals.len || C.is_groin_exposed() || C.is_chest_exposed() || !C.is_mouth_covered()) //Anything through_clothing or covering
					LAZYADD(partners, L)

	for(var/mob/living/L in partners)
		partners[L] = new /mutable_appearance(L)
	//NOW the list should only contain correct partners
	if(!partners.len)
		if(!silent)
			to_chat(src, "<span class='warning'>Вы не можете сделать это в одиночку.</span>")
		return //No one left.

	var/mob/living/target = partners.len == 1 ? partners[1] : show_radial_menu(src, src, partners, radius = 40, require_near = TRUE) // BLUEMOON EDIT

	if(target && in_range(src, target))
		if(covering && target.client?.prefs.cit_toggles & CUM_ONTO)
			return target
		else
		// BLUEMOON EDIT END
			to_chat(src,"<span class='notice'>Ожидание согласия...</span>")
			var/consenting = alert(target, "Вы хотите, чтобы [src] кончил[src.ru_a()] [covering ? "на вас" : "совместно с вами"]?","Механика Кульминации","Да","Нет")
			if(consenting == "Да")
				return target
			else
				message_admins("[ADMIN_LOOKUPFLW(src)] tried to climax with [target], but [target] did not consent.")
				log_consent("[key_name(src)] tried to climax with [target], but [target] did not consent.")

/mob/living/carbon/human/proc/pick_climax_container(silent = FALSE)
	var/list/containers_list = list()

	for(var/obj/item/reagent_containers/C in held_items)
		if(C.is_open_container() || istype(C, /obj/item/reagent_containers/food/snacks))
			containers_list += C
	for(var/obj/item/reagent_containers/C in range(1, src))
		if((C.is_open_container() || istype(C, /obj/item/reagent_containers/food/snacks)) && CanReach(C))
			containers_list += C

	if(containers_list.len)
		//BLUEMOON EDIT START
		for(var/obj/item/reagent_containers/C in containers_list)
			containers_list[C] = new /mutable_appearance(C)
		var/obj/item/reagent_containers/SC = containers_list.len == 1 ? containers_list[1] : show_radial_menu(src, src, containers_list, require_near = TRUE)
		//BLUEMOON EDIT END
		if(SC && CanReach(SC))
			return SC
	else if(!silent)
		to_chat(src, "<span class='warning'>Вы не сможете сделать это без соответствующего контейнера.</span>")

/mob/living/carbon/human/proc/available_rosie_palms(silent = FALSE, list/whitelist_typepaths = list(/obj/item/dildo))
	if(restrained(TRUE)) //TRUE ignores grabs
		if(!silent)
			to_chat(src, "<span class='warning'>Вы не можете сделать это, будучи связанным!</span>")
		return FALSE
	if(!get_num_arms() || !get_empty_held_indexes())
		if(whitelist_typepaths)
			if(!islist(whitelist_typepaths))
				whitelist_typepaths = list(whitelist_typepaths)
			for(var/path in whitelist_typepaths)
				if(is_holding_item_of_type(path))
					return TRUE
		if(!silent)
			to_chat(src, "<span class='warning'>Вам нужна как минимум одна свободная рука.</span>")
		return FALSE
	return TRUE

//Here's the main proc itself
//skyrat edit - forced partner and spillage
/mob/living/carbon/human/proc/mob_climax(forced_climax = FALSE, cause = "", var/mob/living/forced_partner = null, var/forced_spillage = TRUE, var/obj/item/organ/genital/forced_receiving_genital = null, anonymous = FALSE)
	set waitfor = FALSE

	if(!(client?.prefs.arousable || !ckey) || !has_dna())
		return

	if(HAS_TRAIT(src, TRAIT_NEVERBONER))
		to_chat(src, span_warning("You don't feel like it at all."))
		return

	if(stat == DEAD)
		if(!forced_climax)
			to_chat(src, "<span class='warning'>Ты не можешь сделать это, будучи мертвым!</span>")
		return
	if(forced_climax) //Something forced us to cum, this is not a masturbation thing and does not progress to the other checks
		log_message("was forced to climax by [cause]",LOG_EMOTE)
		for(var/obj/item/organ/genital/G in internal_organs)
			if(!(G.genital_flags & CAN_CLIMAX_WITH)) //Skip things like wombs and testicles
				continue
			var/mob/living/partner
			var/check_target

			if(forced_receiving_genital || G.is_exposed() || G.always_accessible) // BLUEMOON EDIT
				if(pulling) //Are we pulling someone? Priority target, we can't be making option menus for this, has to be quick
					if(isliving(pulling)) //Don't fuck objects
						check_target = pulling
				if(pulledby && !check_target) //prioritise pulled over pulledby
					if(isliving(pulledby))
						check_target = pulledby
				//Now we should have a partner, or else we have to come alone
				if(check_target)
					if(iscarbon(check_target)) //carbons can have clothes
						var/mob/living/carbon/C = check_target
						if(C.exposed_genitals.len || C.is_groin_exposed() || C.is_chest_exposed()) //Are they naked enough?
							partner = C
						// BLUEMMON ADD START
						else
							for(var/obj/item/organ/genital/partner_G in C.internal_organs)
								if(partner_G.always_accessible)
									partner = C
									break
						// BLUEMMON ADD END
					else //A cat is fine too
						partner = check_target
				//skyrat edit
				if(forced_partner)
					if((forced_partner == "none") || (!istype(forced_partner)))
						partner = null
					else
						partner = forced_partner
				//
				if(partner) //Did they pass the clothing checks?
					//skyrat edit
					mob_climax_partner(G, partner, forced_spillage, 0, forced_receiving_genital, forced_climax, anonymous) //Instant climax due to forced
					//
					continue //You've climaxed once with this organ, continue on
			//not exposed OR if no partner was found while exposed, climax alone
			mob_climax_outside(G, mb_time = 0) //removed climax timer for sudden, forced orgasms
		//Now all genitals that could climax, have.
		//Since this was a forced climax, we do not need to continue with the other stuff
		return
	//If we get here, then this is not a forced climax and we gotta check a few things.

	if(stat == UNCONSCIOUS) //No sleep-masturbation, you're unconscious.
		to_chat(src, "<span class='warning'>Вы должны быть в сознании, чтобы сделать это!</span>")
		return

	//Ok, now we check what they want to do.
	// BLUEMOON EDIT START
	var/static/list/options = list(
		"Оргазмировать в одиночестве" = list("icon" = 'icons/obj/genitals/hud.dmi', "state" = "arousal"),
		"Оргазмировать совместно с кем-то" = list("icon" = 'modular_sand/icons/mob/dogborg.dmi', "state" = "pleasuremaw"),
		"Оргазмировать на кого-то" = list("icon" = 'modular_splurt/icons/effects/cumoverlay.dmi', "state" = "cum_large"),
		"Наполнить контейнер половыми жидкостями" = list("icon" = 'modular_splurt/icons/obj/drinks.dmi', "state" = "cumchalice")
	)

	var/list/choices = list()
	for(var/text in options)
		var/info = options[text]
		var/mutable_appearance/app = new /mutable_appearance()
		app.icon = info["icon"]
		app.icon_state = info["state"]
		app.name = text
		choices[text] = app

	var/choice = show_radial_menu(src, src, choices, require_near = FALSE)

	if(!choice)
		return

	switch(choice)
		if("Оргазмировать в одиночестве")
			if(!available_rosie_palms())
				return
			var/obj/item/organ/genital/picked_organ = pick_climax_genitals()
			if(picked_organ && available_rosie_palms(TRUE))
				mob_climax_outside(picked_organ)
		if("Оргазмировать совместно с кем-то")
			//We need no hands, we can be restrained and so on, so let's pick an organ
			var/obj/item/organ/genital/picked_organ = pick_climax_genitals()
			if(picked_organ)
				var/mob/living/partner = pick_partner() //Get someone
				if(partner && in_range(src, partner))
					var/spillage = alert(src, "Кончить внутрь?", "При возможности", "Да", "Нет")
					if(in_range(src, partner))
						mob_climax_partner(picked_organ, partner, spillage == "Нет" ? TRUE : FALSE, Lgen = pick_receiving_organ(partner))
		if("Наполнить контейнер половыми жидкостями")
			//We'll need hands and no restraints.
			if(!available_rosie_palms(FALSE, /obj/item/reagent_containers))
				return
			//We got hands, let's pick an organ
			var/obj/item/organ/genital/picked_organ
			picked_organ = pick_climax_genitals() //Gotta be climaxable, not just masturbation, to fill with fluids.
			if(picked_organ)
				//Good, got an organ, time to pick a container
				var/obj/item/reagent_containers/fluid_container = pick_climax_container()
				if(fluid_container && available_rosie_palms(TRUE, /obj/item/reagent_containers))
					mob_fill_container(picked_organ, fluid_container)
		if("Оргазмировать на кого-то")
			//We need no hands, we can be restrained and so on, so let's pick an organ
			var/obj/item/organ/genital/picked_organ = pick_climax_genitals()
			if(picked_organ)
				var/mob/living/partner = pick_partner(covering = TRUE) //Get someone
				if(partner && in_range(src, partner))
					mob_climax_over(picked_organ, partner, TRUE)

	// BLUEMOON EDIT END

/mob/living/carbon/human/verb/climax_verb()
	set category = "IC"
	set name = "Climax"
	set desc = "Lets you choose a couple ways to ejaculate."
	mob_climax()
