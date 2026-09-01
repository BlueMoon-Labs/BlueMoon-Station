/datum/element/tactical
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 2
	var/allowed_slot
	var/original_name // Сохраняем оригинальное имя
	var/static/list/hud_to_hide = list(
		HEALTH_HUD,
		STATUS_HUD,
		ID_HUD,
        WANTED_HUD,
        IMPLOYAL_HUD,
        IMPCHEM_HUD,
        IMPTRACK_HUD,
        RAD_HUD,
    )

/datum/element/tactical/Attach(datum/target, allowed_slot)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE || !isitem(target))
		return ELEMENT_INCOMPATIBLE

	src.allowed_slot = allowed_slot
	RegisterSignal(target, COMSIG_ITEM_EQUIPPED, PROC_REF(modify))
	RegisterSignal(target, COMSIG_ITEM_DROPPED, PROC_REF(unmodify))

/datum/element/tactical/Detach(datum/target)
	UnregisterSignal(target, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED))
	unmodify(target)
	return ..()

/datum/element/tactical/proc/modify(obj/item/source, mob/user, slot)
	if(allowed_slot && slot != allowed_slot)
		unmodify(source, user)
		return

	var/image/I = image(icon = source.icon, icon_state = source.icon_state, loc = user)
	I.copy_overlays(source)
	I.override = TRUE
	source.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, "sneaking_mission", I)
	I.layer = ABOVE_MOB_LAYER

	// Скрывание имени - сохраняем оригинальное имя и заменяем на имя предмета
	if(ishuman(user))
		original_name = user.name
		user.name = source.name

	set_hud_alpha(user, 100)

/datum/element/tactical/proc/unmodify(obj/item/source, mob/user)
	if(!user)
		if(!ismob(source.loc))
			return
		user = source.loc

	user.remove_alt_appearance("sneaking_mission")
	
	// Восстанавливаем оригинальное имя
	if(ishuman(user) && original_name)
		user.name = original_name
		original_name = null

	set_hud_alpha(user, 255)

/datum/element/tactical/proc/set_hud_alpha(mob/user, alpha = 255)
    for(var/hud_id in hud_to_hide)
        var/image/hud_image = user.hud_list[hud_id]
        hud_image?.alpha = alpha
