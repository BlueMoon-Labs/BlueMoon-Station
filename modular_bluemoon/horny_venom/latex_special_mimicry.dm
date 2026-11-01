/datum/action/cooldown/latexmob/mimicry
	name = "Мимикрия"
	button_icon_state = "Saturate"
	desc = "Ctrl+клик копирует облик предмета рядом. Способность создаёт оболочку или снимает её."
	stage_required = 2
	var/mutable_appearance/copied_appearance
	var/copied_name
	var/copied_desc
	var/copied_size
	var/copied_slots = NONE
	var/copied_item_state
	var/copied_worn_icon
	var/is_item = FALSE
	var/is_clothing = FALSE

/datum/action/cooldown/latexmob/mimicry/proc/can_copy(obj/target)
	if(!istype(target) || QDELETED(target) || !owner.Adjacent(target) || !isturf(target.loc))
		return FALSE
	if(target.GetComponent(/datum/component/latex_mimicry) || target.invisibility || target.alpha != LIGHTING_PLANE_ALPHA_VISIBLE)
		return FALSE
	var/list/allowed = my_living_latex.base_mimicry_types.Copy()
	if(stage >= 1)
		allowed |= my_living_latex.advanced_mimicry_types
	if(stage >= 2)
		allowed |= my_living_latex.superior_special_mimicry_types
	for(var/type in allowed)
		if(istype(target, type))
			return TRUE
	return FALSE

/datum/action/cooldown/latexmob/mimicry/proc/copy_target(obj/target)
	if(!my_living_latex || !can_copy(target))
		return FALSE
	var/icon/base_icon = icon(target.icon, target.icon_state)
	if(base_icon.Width() > LATEX_MIMIC_MAX_SIZE || base_icon.Height() > LATEX_MIMIC_MAX_SIZE)
		return FALSE
	copied_appearance = new /mutable_appearance(target.appearance)
	copied_name = target.name
	copied_desc = target.desc
	is_item = isitem(target)
	is_clothing = isclothing(target)
	copied_slots = NONE
	if(is_item)
		var/obj/item/item = target
		copied_size = item.w_class
		copied_slots = is_clothing ? item.slot_flags : NONE
		copied_item_state = item.item_state
		copied_worn_icon = item.mob_overlay_icon
	owner.balloon_alert(owner, "облик скопирован")
	return TRUE

/datum/action/cooldown/latexmob/mimicry/Activate()
	if(!..() || !islatexmob(owner) || isbackseatmob(owner) || my_living_latex.capture || my_living_latex.host_organ)
		return FALSE
	var/mob/living/simple_animal/latexmob/user = owner
	if(user.mimicry_in_use)
		return user.go_back()
	if(!copied_appearance || !isturf(user.loc) || user.stat != CONSCIOUS)
		user.balloon_alert(user, "сначала Ctrl+клик по предмету")
		return FALSE
	return user.do_mimicry(src)

/datum/action/cooldown/latexmob/mimicry/Destroy()
	copied_appearance = null
	return ..()

/mob/living/simple_animal/latexmob/CtrlClickOn(atom/movable/target)
	var/datum/antagonist/living_latex/latex = mind?.has_antag_datum(/datum/antagonist/living_latex)
	var/datum/action/cooldown/latexmob/mimicry/ability = latex?.get_ability_by_path(/datum/action/cooldown/latexmob/mimicry)
	if(!ability || mimicry_in_use || latex.capture || latex.host_organ)
		return ..()
	if(!ability.copy_target(target))
		balloon_alert(src, "нельзя скопировать этот облик")

/mob/living/simple_animal/latexmob/proc/do_mimicry(datum/action/cooldown/latexmob/mimicry/ability)
	if(mimic_shell || !isturf(loc))
		return FALSE
	var/shell_type = /obj/structure/latex_disguise
	if(ability.is_item)
		shell_type = ability.is_clothing ? /obj/item/clothing/latex_disguise : /obj/item/latex_disguise
	var/obj/shell = new shell_type(get_turf(src))
	shell.appearance = ability.copied_appearance
	shell.name = ability.copied_name
	shell.desc = "[ability.copied_desc] На поверхности заметен влажный чёрный блеск."
	shell.layer = initial(shell.layer)
	shell.plane = initial(shell.plane)
	shell.mouse_opacity = MOUSE_OPACITY_ICON
	shell.density = FALSE
	shell.opacity = FALSE
	if(isitem(shell))
		var/obj/item/item = shell
		item.w_class = ability.copied_size
		item.slot_flags = ability.copied_slots
		item.item_state = ability.copied_item_state
		item.mob_overlay_icon = ability.copied_worn_icon
	mimic_shell = shell
	mimicry_in_use = TRUE
	shell.AddComponent(/datum/component/latex_mimicry, src)
	shell.AddComponent(/datum/component/latex_contact)
	forceMove(shell)
	if(loc != shell)
		go_back()
		return FALSE
	return TRUE

/mob/living/simple_animal/latexmob/proc/go_back()
	var/obj/shell = mimic_shell
	mimic_shell = null
	mimicry_in_use = FALSE
	if(!shell)
		return FALSE
	if(loc == shell)
		var/datum/component/latex_mimicry/component = shell.GetComponent(/datum/component/latex_mimicry)
		forceMove(component?.exit_turf() || get_turf(shell))
	if(!QDELETED(shell))
		qdel(shell)
	return TRUE

/obj/item/latex_disguise
	name = "латексная оболочка"

/obj/item/clothing/latex_disguise
	name = "живая одежда"

/obj/structure/latex_disguise
	name = "латексная оболочка"
	anchored = TRUE
	density = FALSE
