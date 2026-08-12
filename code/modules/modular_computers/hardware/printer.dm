/obj/item/computer_hardware/printer
	name = "printer"
	desc = "Computer-integrated printer with paper recycling module."
	power_usage = 100
	icon_state = "printer"
	w_class = WEIGHT_CLASS_SMALL
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

/obj/item/computer_hardware/printer/proc/do_after_bin_checks(mob/user, obj/item/paper_bin/bin)
	return !QDELETED(bin) && bin.total_paper >= 1 && Adjacent(user) && stored_paper < max_paper

/obj/item/computer_hardware/printer/proc/do_after_package_checks(mob/user, obj/item/stack/packageWrap/package)
	return !QDELETED(package) && Adjacent(user) && stored_paper < max_paper

/obj/item/computer_hardware/printer/try_insert(obj/item/I, mob/living/user = null)
	. = FALSE
	if(istype(I, /obj/item/paper_bin) || istype(I, /obj/item/stack/packageWrap) || istype(I, /obj/item/paper))
		if(stored_paper >= max_paper)
			to_chat(user, span_warning("You try to add [istype(I, /obj/item/paper_bin) ? "some paper" : "\the [I]"] into [src], but its paper bin is full!"))
			return

		if(istype(I, /obj/item/paper_bin))
			var/obj/item/paper_bin/bin = I
			if(bin.total_paper < 1)
				to_chat(user, span_warning("The \the [bin] is empty!"))
				return
			var/do_after_target = holder.physical || src
			if(INTERACTING_WITH(user, do_after_target))
				return
			while(do_after(user, 0.2 SECONDS, do_after_target, extra_checks = CALLBACK(src, PROC_REF(do_after_bin_checks), user, bin)))
				playsound(src, 'sound/items/handling/paper_drop.ogg', 30, ignore_walls = FALSE) // paper drop sound
				bin.total_paper--
				if(bin.papers.len > 0) // // If there's any custom paper on the stack dell
					var/obj/item/paper/P = bin.papers[bin.papers.len]
					bin.papers.Remove(P)
					qdel(P)
				stored_paper++
			bin.update_icon()
			to_chat(user, span_notice("You insert some papers into [src]'s paper recycler."))
			return TRUE
		else if(istype(I, /obj/item/stack/packageWrap))
			var/obj/item/stack/packageWrap/package = I
			var/do_after_target = holder.physical || src
			if(INTERACTING_WITH(user, do_after_target))
				return
			while(do_after(user, 0.2 SECONDS, do_after_target, extra_checks = CALLBACK(src, PROC_REF(do_after_package_checks), user, package)))
				playsound(src, 'sound/items/handling/paper_drop.ogg', 30, ignore_walls = FALSE) // paper drop sound
				package.use(1)
				stored_paper++
			to_chat(user, span_notice("You insert some packing into [src]'s paper recycler."))
			return TRUE
		else
			if(user && !user.temporarilyRemoveItemFromInventory(I))
				return
			to_chat(user, span_notice("You insert \the [I] into [src]'s paper recycler."))
			qdel(I)
			stored_paper++
			return TRUE

/obj/item/computer_hardware/printer/mini
	name = "miniprinter"
	desc = "A small printer with paper recycling module."
	power_usage = 50
	icon_state = "printer_mini"
	stored_paper = 5
	max_paper = 15
