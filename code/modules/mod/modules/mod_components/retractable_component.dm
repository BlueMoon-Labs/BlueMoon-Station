

/datum/component/mod_retractable
	var/obj/item/mod/module/storage_module
	var/obj/item/using_device
	var/obj/item/mod/control/my_modsuit
	var/already_holding = FALSE
	var/need_to_protect_item = TRUE
	var/sound

/datum/component/mod_retractable/Initialize(mapload, device, modsuit, retract_sound, need_to_protect_item)
	. = ..()
	storage_module = parent //где храним
	using_device = device //что храним
	my_modsuit = modsuit
	sound = retract_sound

	if(!my_modsuit)
		stack_trace("Компонент выдвигаемости МОДа создан без ссылки на сам МОД и сломался!")
		return
	RegisterSignal(using_device, COMSIG_MOVABLE_MOVED, PROC_REF(check_range)) //чтобы знать когда проверять расстояние до айтема
	RegisterSignal(src, COMSIG_MODULE_ON_USE, PROC_REF(retract_in_hands))

/datum/component/mod_retractable/proc/retract_in_hands(datum/source, mob/living/carbon/user)
	if(!using_device)
		return
	if(already_holding)
		snap_back()
	if(!already_holding && my_modsuit.wearer)
		my_modsuit.wearer.put_in_hands(using_device)
		playsound(get_turf(my_modsuit), sound, 30, 1)

	already_holding = !already_holding //инвертация булевой переменной по итогам любого из if

/datum/component/mod_retractable/Destroy()
	if(storage_module)
		UnregisterSignal(src, COMSIG_MODULE_ON_USE, PROC_REF(retract_in_hands))
	if(using_device)
		UnregisterSignal(using_device, COMSIG_MOVABLE_MOVED, PROC_REF(check_range))
		qdel(using_device)
		using_device = null
		my_modsuit = null
	return ..()

/datum/component/mod_retractable/proc/check_range()
	if(!need_to_protect_item)
		return //разрешаем объекту быть выкинутым

	if(!using_device || !storage_module || !my_modsuit)
		return //если что-то пошло не так

	var/mob/living/carbon/human/wearer = my_modsuit.wearer
	if(!wearer)
		return

	if(using_device.loc == storage_module)
		return

	if(using_device.loc == wearer)
		return

	snap_back()

/datum/component/mod_retractable/proc/snap_back()
	if(!using_device || !storage_module)
		return
	already_holding = FALSE
	using_device.forceMove(storage_module)
	playsound(get_turf(my_modsuit), sound, 30, 1)
