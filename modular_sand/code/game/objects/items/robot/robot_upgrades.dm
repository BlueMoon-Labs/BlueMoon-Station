
/obj/item/borg/upgrade/xwelding
	name = "engineering cyborg experimental welding tool"
	desc = "An experimental welding tool replacement for the engineering module's standard welding tool."
	icon_state = "cyborg_upgrade3"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING
	/// Старая сварка
	var/obj/item/weldingtool/largetank/cyborg/oldtool
	/// Новая сварка
	var/obj/item/weldingtool/experimental/cyborg/exptool

/obj/item/borg/upgrade/xwelding/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for (exptool in R.module)
		if(exptool)
			to_chat(user, "<span class='warning'>This unit is already equipped with an experimental welder module.</span>")
			return FALSE

	var/oldtool_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Начинаем искать индекс старой сварки
		oldtool = R.module.modules[i]
		if(istype(oldtool, /obj/item/weldingtool/largetank/cyborg))
			oldtool_index = i
			break // Находим - прекращаем, не обрабатываем for'ом весь список.

	exptool = new(R.module)
	R.module.basic_modules += exptool
	R.module.add_module(exptool, FALSE, TRUE)
	var/newtool_index = R.module.modules.Find(exptool)
	for(exptool in R.module) // Можно оформить и для старой сварки, здесь сделано для новой, без разницы.
		R.module.modules.Swap(oldtool_index, newtool_index) // Swap в обоих листах важно настолько же
		R.module.basic_modules.Swap(oldtool_index, newtool_index) // как и `basic_modules +=` и `add.module` выше
	R.module.remove_module(oldtool, TRUE) // Замена произошла - избавляемся от старой сварки

/obj/item/borg/upgrade/xwelding/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/newtool_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Этот алгоритм зеркален тому, что для добавления
		exptool = R.module.modules[i]
		if(istype(exptool, /obj/item/weldingtool/experimental/cyborg))
			newtool_index = i
			break

	oldtool = new(R.module)
	R.module.basic_modules += oldtool
	R.module.add_module(oldtool, FALSE, TRUE)
	var/oldtool_index = R.module.modules.Find(oldtool)
	for(oldtool in R.module)
		R.module.modules.Swap(newtool_index, oldtool_index)
		R.module.basic_modules.Swap(newtool_index, oldtool_index)
		R.module.remove_module(exptool, TRUE)

/* Shit doesnt work, work on it later
/obj/item/borg/upgrade/plasma
	name = "engineering cyborg plasma resource upgrade"
	desc = "An upgrade that allows cyborgs the ability to use plasma and assorted plasma products."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING
*/

/* Shit doesnt work, do it later
/obj/item/borg/upgrade/plasma/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		R.module.basic_modules += /obj/item/stack/sheet/plasmaglass/cyborg
		R.module.add_module(/obj/item/stack/sheet/plasmaglass/cyborg, FALSE, TRUE)
		R.module.basic_modules += /obj/item/stack/sheet/plasmarglass/cyborg
		R.module.add_module(/obj/item/stack/sheet/plasmarglass/cyborg, FALSE, TRUE)
		R.module.basic_modules += /obj/item/stack/sheet/plasteel/cyborg
		R.module.add_module(/obj/item/stack/sheet/plasteel/cyborg, FALSE, TRUE)
		R.module.basic_modules += /obj/item/stack/sheet/mineral/plasma/cyborg
		R.module.add_module(/obj/item/stack/sheet/mineral/plasma/cyborg, FALSE, TRUE)

/obj/item/borg/upgrade/plasma/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		R.module.remove_module(/obj/item/stack/sheet/plasmaglass/cyborg, TRUE)
		R.module.remove_module(/obj/item/stack/sheet/plasmarglass/cyborg, TRUE)
		R.module.remove_module(/obj/item/stack/sheet/plasteel/cyborg, TRUE)
		R.module.remove_module(/obj/item/stack/sheet/mineral/plasma/cyborg, TRUE)
*/

/obj/item/borg/upgrade/bsrpd
	name = "engineering cyborg bluespace RPD"
	desc = "A bluespace RPD replacement for the engineering module's standard RPD."
	icon_state = "cyborg_upgrade3"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING
	/// Старый РПД
	var/obj/item/pipe_dispenser/cyborg/RPD
	/// Новый РПД
	var/obj/item/pipe_dispenser/bluespace/cyborg/BRPD

/obj/item/borg/upgrade/bsrpd/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for(BRPD in R.module.modules)
		if(BRPD)
			to_chat(user, "<span class='warning'>This unit is already equipped with a BSRPD module.</span>")
			return FALSE

	var/RPD_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Начинаем искать индекс старого инструмента
		RPD = R.module.modules[i]
		if(istype(RPD, /obj/item/pipe_dispenser/cyborg))
			RPD_index = i
			break // Находим - прекращаем, не обрабатываем for'ом весь список.

	BRPD = new(R.module)
	R.module.basic_modules += BRPD
	R.module.add_module(BRPD, FALSE, TRUE)
	var/BRPD_index = R.module.modules.Find(BRPD)
	for(BRPD in R.module) // Можно оформить и для старого инструмента, здесь сделано для нового, без разницы.
		R.module.modules.Swap(RPD_index, BRPD_index) // Swap в обоих листах важно настолько же
		R.module.basic_modules.Swap(RPD_index, BRPD_index) // как и `basic_modules +=` и `add.module` выше
	R.module.remove_module(RPD, TRUE) // Замена произошла - избавляемся от старого инструмента

/obj/item/borg/upgrade/bsrpd/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	var/BRPD_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Этот алгоритм зеркален тому, что для добавления.
		BRPD = R.module.modules[i]
		if(istype(BRPD, /obj/item/pipe_dispenser/bluespace/cyborg))
			BRPD_index = i
			break

	RPD = new(R.module)
	R.module.basic_modules += RPD
	R.module.add_module(RPD, FALSE, TRUE)
	var/RPD_index = R.module.modules.Find(RPD)
	for(RPD in R.module)
		R.module.modules.Swap(BRPD_index, RPD_index)
		R.module.basic_modules.Swap(BRPD_index, RPD_index)
		R.module.remove_module(BRPD, TRUE)

/obj/item/borg/upgrade/expand/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)

		if(R.hasExpanded)
			to_chat(usr, "<span class='notice'>This unit already has an expand module installed!</span>")
			return FALSE

		if(R.hasShrunk)
			to_chat(usr, "<span class='notice'>This unit already has an shrink module installed!</span>")
			return FALSE

		if(ExpandSize <= 0)
			ExpandSize = 200

		R.mob_transforming = TRUE
		var/prev_locked_down = R.locked_down
		R.SetLockdown(1)
		R.anchored = TRUE
		var/datum/effect_system/smoke_spread/smoke = new
		smoke.set_up(1, R.loc)
		smoke.start()
		sleep(2)
		for(var/i in 1 to 4)
			playsound(R, pick('sound/items/drill_use.ogg', 'sound/items/jaws_cut.ogg', 'sound/items/jaws_pry.ogg', 'sound/items/welder.ogg', 'sound/items/ratchet.ogg'), 80, 1, -1)
			sleep(12)
		if(!prev_locked_down)
			R.SetLockdown(0)
		R.anchored = FALSE
		R.mob_transforming = FALSE
		R.resize = ExpandSize/100
		R.update_transform()
		//R.update_size(ExpandSize/100)
		R.hasExpanded = TRUE
		R.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/changed_robot_size) // BLUEMOON ADD

/obj/item/borg/upgrade/expand/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (. && R.hasExpanded)
		R.transform = null
		R.hasExpanded = FALSE
		R.remove_movespeed_modifier(/datum/movespeed_modifier/changed_robot_size) // BLUEMOON ADD

/obj/item/borg/upgrade/shrink
	name = "borg shrinker"
	desc = "A cyborg resizer, it makes a cyborg small."
	icon_state = "cyborg_upgrade3"

/obj/item/borg/upgrade/shrink/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)

		if(R.hasShrunk)
			to_chat(usr, "<span class='notice'>This unit already has an shrink module installed!</span>")
			return FALSE

		if(R.hasExpanded)
			to_chat(usr, "<span class='notice'>This unit already has an expand module installed!</span>")
			return FALSE

		if(ShrinkSize == 0)
			ShrinkSize = 50

		R.mob_transforming = TRUE
		var/prev_locked_down = R.locked_down
		R.SetLockdown(1)
		R.anchored = TRUE
		var/datum/effect_system/smoke_spread/smoke = new
		smoke.set_up(1, R.loc)
		smoke.start()
		sleep(2)
		for(var/i in 1 to 4)
			playsound(R, pick('sound/items/drill_use.ogg', 'sound/items/jaws_cut.ogg', 'sound/items/jaws_pry.ogg', 'sound/items/welder.ogg', 'sound/items/ratchet.ogg'), 80, 1, -1)
			sleep(12)
		if(!prev_locked_down)
			R.SetLockdown(0)
		R.anchored = FALSE
		R.mob_transforming = FALSE
		R.resize = ShrinkSize/100
		R.update_transform()
/*		R.add_movespeed_modifier(/datum/movespeed_modifier/reagent/freon) / BLUEMOON REMOVAL - увеличиваем степень замедления роботов, уменьшенных или увеличенных в размере */
		R.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/changed_robot_size/shrink) // BLUEMOON ADD
		//R.update_size(ShrinkSize/100)
		R.hasShrunk = TRUE

/obj/item/borg/upgrade/shrink/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (. && R.hasShrunk)
		R.transform = null
		R.hasShrunk = FALSE
/*		R.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/freon) / BLUEMOON REMOVAL - увеличиваем степень замедления роботов, уменьшенных или увеличенных в размере */
		R.remove_movespeed_modifier(/datum/movespeed_modifier/changed_robot_size/shrink) // BLUEMOON ADD


/obj/item/borg/upgrade/transform/syndicatejack
    name = "borg module picker (Syndicate)"
    desc = "Allows you to to turn a cyborg into a experimental syndicate cyborg."
    icon_state = "cyborg_upgrade3"
    new_module = /obj/item/robot_module/syndicatejack

/obj/item/borg/upgrade/transform/syndicatejack/action(mob/living/silicon/robot/R, user = usr)
    if(R.emagged)
        return ..()

/obj/item/borg/upgrade/shuttlemaking
	name = "engineering cyborg rapid shuttle designator"
	desc = "A device used to define the area required for custom ships. Uses bluespace crystals to create bluespace-capable ships.\n\
			It appears to be a rough adaptation for cyborgs."
	icon_state = "cyborg_upgrade5"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING

/obj/item/borg/upgrade/shuttlemaking/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		var/obj/item/shuttle_creator/shuttle_maker = locate() in R
		if(!shuttle_maker)
			shuttle_maker = locate() in R.module
		if(shuttle_maker)
			to_chat(user, "<span class='warning'>This unit is already equipped with a rapid shuttle designator module.</span>")
			return FALSE
		shuttle_maker = new(R.module)
		R.module.basic_modules += shuttle_maker
		R.module.add_module(shuttle_maker, FALSE, TRUE)

/obj/item/borg/upgrade/shuttlemaking/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		for(var/obj/item/shuttle_creator/shuttle_maker in R.module)
			R.module.remove_module(shuttle_maker, TRUE)
