// Модуль Доминатрикс для киборгов - порт с WhiteMoon на предметах нашего билда

/mob/living/silicon/robot
	var/has_toys = FALSE
	/// Игрушки, выданные модулем «Доминатрикс», для корректного удаления при деактивации
	var/list/dominatrix_toys = list()

/obj/item/borg/upgrade/dominatrix_module
	name = "модуль «Доминатрикс» для киборга"
	desc = "Модуль, который значительно улучшает способность киборгов проявлять привязанность."
	icon = 'icons/obj/module.dmi'
	icon_state = "cyborg_upgrade5"

/obj/item/borg/upgrade/dominatrix_module/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	if(borg.has_toys)
		to_chat(user, span_warning("На этом юните уже установлен «развлекательный» модуль!"))
		return FALSE
	. = ..()
	if(.)
		borg.has_toys = TRUE
		var/static/list/toy_paths = list(
			/obj/item/bdsm_whip,
			/obj/item/bdsm_whip/ridingcrop,
			/obj/item/electropack/vibrator,
			/obj/item/electropack/shockcollar,
			/obj/item/leash,
			/obj/item/dildo/custom,
			/obj/item/buttplug/small,
			/obj/item/fleshlight,
			/obj/item/magicwand,
		)
		for(var/toy_path as anything in toy_paths)
			var/obj/item/toy = new toy_path(src)
			borg.module.add_module(toy, TRUE, TRUE)
			borg.dominatrix_toys += toy

/obj/item/borg/upgrade/dominatrix_module/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(.)
		borg.has_toys = FALSE
		for(var/obj/item/toy in borg.dominatrix_toys)
			if(!QDELETED(toy))
				borg.module.remove_module(toy, TRUE)
		borg.dominatrix_toys = list()
