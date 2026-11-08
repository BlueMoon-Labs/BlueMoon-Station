/mob/living/carbon/human/do_climax(datum/reagents/R, atom/target, obj/item/organ/genital/sender, spill, cover = FALSE, obj/item/organ/genital/receiver, anonymous = FALSE, is_hidden = FALSE)
	. = ..()
	set_lust(0)
	SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
	var/message_to_display
	// We got pleased, let's get rid of some of it
	var/crocin_amount = reagents.get_reagent_amount(/datum/reagent/drug/aphrodisiac)
	if(crocin_amount)
		reagents.remove_reagent(/datum/reagent/drug/aphrodisiac, rand(10, max(30, crocin_amount / 5)))
		message_to_display = span_userlove("Мммм.. Да...~")
	// More potent, harder to get rid of
	var/hexacrocin_amount = reagents.get_reagent_amount(/datum/reagent/drug/aphrodisiacplus)
	if(hexacrocin_amount)
		reagents.remove_reagent(/datum/reagent/drug/aphrodisiacplus, rand(2, max(15, hexacrocin_amount / 6)))
		message_to_display = span_userlove("АХХХ... ДА...~!")
	if(message_to_display)
		to_chat(src, message_to_display)

/mob/living/proc/pick_receiving_organ(mob/living/carbon/L, flag = CAN_CUM_INTO, title = "Climax", desc = "in what hole?")
	if (!istype(L))
		return
	var/list/receivers_list
	//BLUEMOON EDIT START
	for(var/obj/item/organ/genital/G in L.internal_organs)
		if((!flag || (G.genital_flags & flag)) && (G.is_exposed() || G.always_accessible)) //filter out what you can't cum into
			LAZYADD(receivers_list, G)
	if(LAZYLEN(receivers_list))
		for(var/obj/item/organ/genital/G in receivers_list)
			receivers_list[G] = new /mutable_appearance(G)
		var/obj/item/organ/genital/ret_organ = show_radial_menu(src, L, receivers_list, require_near = TRUE, tooltips = TRUE)
	//BLUEMOON EDIT END
		return ret_organ
