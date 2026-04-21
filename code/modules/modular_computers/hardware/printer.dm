/obj/item/computer_hardware/printer
	name = "printer"
	desc = "Computer-integrated printer with paper recycling module."
	power_usage = 100
	icon_state = "printer"
	w_class = WEIGHT_CLASS_NORMAL
	device_type = MC_PRINT
	expansion_hw = TRUE
	var/stored_paper = 20
	var/max_paper = 30

/obj/item/computer_hardware/printer/diagnostics(mob/living/user)
	..()
	to_chat(user, span_notice("Paper level: [stored_paper]/[max_paper]."))

/obj/item/computer_hardware/printer/examine(mob/user)
	. = ..()
	. += span_notice("Paper level: [stored_paper]/[max_paper].")


/obj/item/computer_hardware/printer/proc/print_text(text_to_print, paper_title = "")
	if(!stored_paper)
		return FALSE
	if(!check_functionality())
		return FALSE

	var/obj/item/paper/P = new/obj/item/paper(holder.drop_location())

	// Damaged printer causes the resulting paper to be somewhat harder to read.
	if(damage > damage_malfunction)
		text_to_print = stars(text_to_print, 100-malfunction_probability)
	P.add_raw_text(text_to_print)
	if(paper_title)
		P.name = paper_title
	P.update_appearance()
	stored_paper--
	P = null
	return TRUE

/obj/item/computer_hardware/printer/try_insert(obj/item/I, mob/living/user = null)
	// BLUEMOON EDIT START Add papers from bin
	if(istype(I, /obj/item/paper_bin) || istype(I, /obj/item/paper))
		if(stored_paper >= max_paper)
			to_chat(user, span_warning("You try to add [istype(I, /obj/item/paper_bin) ? "some paper" : "\the [I]"] into [src], but its paper bin is full!"))
			return FALSE

		if(istype(I, /obj/item/paper_bin))
			var/obj/item/paper_bin/bin = I
			if(bin.total_paper < 1)
				to_chat(user, span_warning("The \the [bin] is empty!"))
				return FALSE
			to_chat(user, span_notice("You insert some paper into [src]'s paper recycler."))
			playsound(src, 'sound/items/handling/paper_drop.ogg', YEET_SOUND_VOLUME, ignore_walls = FALSE) // paper drop sound
			bin.total_paper--
			if(bin.papers.len > 0) // // If there's any custom paper on the stack dell
				var/obj/item/paper/P = bin.papers[bin.papers.len]
				bin.papers.Remove(P)
				qdel(P)
			bin.update_icon()
		else
			if(user && !user.temporarilyRemoveItemFromInventory(I))
				return FALSE
			to_chat(user, span_notice("You insert \the [I] into [src]'s paper recycler."))
			qdel(I)
	// BLUEMOON EDIT END
		stored_paper++
		return TRUE
	return FALSE

/obj/item/computer_hardware/printer/mini
	name = "miniprinter"
	desc = "A small printer with paper recycling module."
	power_usage = 50
	icon_state = "printer_mini"
	w_class = WEIGHT_CLASS_TINY
	stored_paper = 5
	max_paper = 15
