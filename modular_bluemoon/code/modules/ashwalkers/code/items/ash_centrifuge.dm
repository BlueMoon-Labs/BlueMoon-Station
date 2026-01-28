/obj/item/reagent_containers/cup/primitive_centrifuge
	name = "primitive centrifuge"
	desc = "Небольшая чашка, которая позволяет человеку медленно выливать жидкости, которые ему не нравятся."
	icon = 'modular_bluemoon/code/modules/ashwalkers/icons/misc_tools.dmi'
	icon_state = "primitive_centrifuge"
	volume = 100
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR

/obj/item/reagent_containers/cup/primitive_centrifuge/examine()
	. = ..()
	. += span_notice("<b>Ctrl + Click</b> для выбора химических веществ, которые необходимо удалить.")
	. += span_notice("<b>Alt + Clickk</b>, чтобы выбрать химическое вещество, которое нужно сохранить, а остальные удалить.")

/obj/item/reagent_containers/cup/primitive_centrifuge/CtrlClick(mob/user)
	if(!length(reagents.reagent_list))
		return

	var/datum/user_input = tgui_input_list(user, "Выберите, какое химическое вещество необходимо удалить.", "Removal Selection", reagents.reagent_list)

	if(!user_input)
		balloon_alert(user, "нет выбора")
		return

	user.balloon_alert_to_viewers("[src] начал вращаться...")
	var/skill_modifier = 1
	if(is_species(user, /datum/species/lizard/ashwalker))
		skill_modifier = 0.75
	if(!do_after(user, 5 SECONDS * skill_modifier, target = src))
		user.balloon_alert_to_viewers("[src] перестал вращаться")
		return

	reagents.del_reagent(user_input.type)
	balloon_alert(user, "удален реагент из [src]")

/obj/item/reagent_containers/cup/primitive_centrifuge/AltClick(mob/user)
	if(!length(reagents.reagent_list))
		return

	var/datum/user_input = tgui_input_list(user, "Выберите, какое химическое вещество оставить, а остальные удалить.", "Keep Selection", reagents.reagent_list)

	if(!user_input)
		balloon_alert(user, "нет выбора")
		return

	user.balloon_alert_to_viewers("[src] начал вращаться...")
	var/skill_modifier = 1
	if(is_species(user, /datum/species/lizard/ashwalker))
		skill_modifier = 0.75
	if(!do_after(user, 5 SECONDS * skill_modifier, target = src))
		user.balloon_alert_to_viewers("[src] перестал вращаться")
		return

	for(var/datum/reagent/remove_reagent in reagents.reagent_list)
		if(!istype(remove_reagent, user_input.type))
			reagents.del_reagent(remove_reagent.type)
	balloon_alert(user, "удалены реагенты из [src]")
