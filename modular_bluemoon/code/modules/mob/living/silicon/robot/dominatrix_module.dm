// Модуль Доминатрикс для киборгов - порт с WhiteMoon на предметах нашего билда

/mob/living/silicon/robot
	var/hasToys = FALSE

/obj/item/borg/upgrade/dominatrixmodule
	name = "модуль «Доминатрикс» для киборга"
	desc = "Модуль, который значительно улучшает способность киборгов проявлять привязанность."
	icon = 'icons/obj/module.dmi'
	icon_state = "cyborg_upgrade5"

/obj/item/borg/upgrade/dominatrixmodule/action(mob/living/silicon/robot/borg, mob/living/user)
	if(borg.hasToys)
		to_chat(user, span_warning("This unit already has a 'recreational' module installed!"))
		return FALSE
	. = ..()
	if(.)
		borg.hasToys = TRUE
		borg.module.add_module(new /obj/item/bdsm_whip(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/bdsm_whip/ridingcrop(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/electropack/vibrator(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/electropack/shockcollar(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/leash(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/dildo/custom(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/buttplug/small(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/fleshlight(src), TRUE, TRUE)
		borg.module.add_module(new /obj/item/magicwand(src), TRUE, TRUE)

/obj/item/borg/upgrade/dominatrixmodule/deactivate(mob/living/silicon/robot/borg, mob/living/user)
	. = ..()
	if(.)
		if(borg.hasToys)
			borg.hasToys = FALSE
		var/static/list/toys = list(
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
		for(var/toy_path in toys)
			var/obj/item/toy = locate(toy_path) in borg.module.get_usable_modules()
			if(toy)
				borg.module.remove_module(toy, TRUE)
