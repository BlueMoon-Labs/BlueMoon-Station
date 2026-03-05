// Ported from the Goonstation

#define FINGERPRINT_PLANT 0
#define FINGERPRINT_READ 1

/obj/item/device/fingerprinter
	name = "sales tagger"
	desc = "Замаскированный под ценник серорыночный инструмент для сканирования отпечатков пальцев с предметов и нанесения их на другие вещи."
	icon = 'icons/obj/device.dmi'
	icon_state = "salestagger"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY

	var/list/current_prints = list() // список отсканированных отпечатков
	var/mode = FINGERPRINT_READ // режим работы девайса
	var/chosen_prints = null // выбранные для нанесения отпечатки

/obj/item/device/fingerprinter/examine()
	. = ..()
	. += span_notice("A small side display says:")
	switch(mode) // отображение текущего режима при экзейме
		if(FINGERPRINT_PLANT)
			. += span_robot("Mode: <b>PLANTING</b>")
		if(FINGERPRINT_READ)
			. += span_robot("Mode: <b>READING</b>")
	if(chosen_prints)
		. += span_robot("Prints: [chosen_prints]")

/obj/item/device/fingerprinter/examine_more()
	. = ..()
	. += span_boldnotice("Use alt-click to switch between prints.")
	. += span_info("Toggle modes by using the fingerprinter in hand.<br>\
		While on <b>\"Read\"</b> mode, use the tool on someone or something that has prints on it to add all the prints to the tool's print database.<br>\
		While on <b>\"Plant\"</b> mode, use the tool on anything to add any prints from the database on it.")
	. += span_warning("The device is forbidden and illegal to use in almost all nations and private organizations, including the Pact.")

/obj/item/device/fingerprinter/attack_self(mob/user)
	. = ..()
	toggle_mode(user) // изменение режима при нажатии на девайс

/obj/item/device/fingerprinter/pre_attack(atom/A, mob/living/user, params, attackchain_flags, damage_multiplier)
	. = ..()
	try_action(A, user, params)
	return TRUE // не производится анимация атаки, действие перенесено в try_action

/obj/item/device/fingerprinter/proc/try_action(atom/movable/target, mob/user, flag)
	if(!flag)
		to_chat(user, span_warning("You cannot use the device from so far."))
		return
	if(mode == FINGERPRINT_READ)
		read_prints(user, target)
	else
		plant_print(user, target)
	return

/obj/item/device/fingerprinter/AltClick(mob/user)
	// List mapping readable options to literal prints
	var/optionslist = list()
	for(var/print in current_prints)
		var/txt = print
		if(current_prints[print])
			txt += " ([current_prints[print]])"
		optionslist[txt] = print // map to the print so we can get the actual print to plant

	var/selected = tgui_input_list(user, "Select a print to plant:", "Fingerprinter", optionslist)
	if(!selected)
		to_chat(user, span_warning("You reset the chosen prints."))
		chosen_prints = null
		return
	to_chat(user, span_notice("You selected the prints."))
	chosen_prints = selected

/obj/item/device/fingerprinter/proc/toggle_mode(mob/user)
	mode = !mode
	to_chat(user, span_notice("Current mode set to <b>[mode == FINGERPRINT_READ ? "READ" : "PLANT"]</b>."))

/obj/item/device/fingerprinter/proc/plant_print(mob/user, atom/target)
	if(!chosen_prints)
		to_chat(user, span_warning("You have to set the chosen prints firstly. Use alt-click."))
		return

	to_chat(user, span_notice("You plant fingerprints onto [target]. Let's blackmail or frame someone."))

	target.add_fingerprint_direct(chosen_prints)

	// TODO maybe handle dupe glove prints more gracefully? if we see the same glove ID on 2 different people, list both names? idk
/obj/item/device/fingerprinter/proc/read_prints(mob/user, atom/target)
	if(!target.fingerprints && !ishuman(target))
		to_chat(user, span_danger("There's no fingerprints to read off of that."))
		return

	// This is gross and theoretically slow but we index full-prints by time, and the fingerprints list will only have 6 entries at max so
	// the time complexity doesn't really matter.
	var/found_new_print = FALSE
	for(var/print in target.fingerprints)
		if(!(print in current_prints))
			found_new_print = TRUE
			current_prints += print

	if (found_new_print)
		to_chat(user, span_notice("You read the prints on [target] into [src]."))
	else
		to_chat(user, span_danger("You've already scanned all the prints on [target]."))

	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!(current_prints[md5(H.dna.uni_identity)]))
			current_prints[md5(H.dna.uni_identity)] += md5(H.dna.uni_identity)
			to_chat(user, span_notice("You read [H.gloves ? "the prints of [H]'s gloves" : "[H]'s prints"] into [src]."))
		else
			to_chat(user, span_danger("You've already scanned the fingerprints of [target]."))

#undef FINGERPRINT_PLANT
#undef FINGERPRINT_READ

/// Add a fingerprint to an atom directly. Doesn't interact with hidden prints at all
/atom/proc/add_fingerprint_direct(print)
	LAZYINITLIST(fingerprints)
	fingerprints -= print
	if(length(fingerprints) >= 6) // limit fingerprints in the list to 6
		fingerprints -= fingerprints[1]
	fingerprints += print

/*
 * ПРЕДМЕТ ДЛЯ АПЛИНКА
 */

/datum/uplink_item/stealthy_tools/fingerprinter
	name = "Finger printer"
	desc = "Устройство, позволяющее сканировать и подбрасывать отпечатки пальцев."
	item = /obj/item/device/fingerprinter
	cost = 5
