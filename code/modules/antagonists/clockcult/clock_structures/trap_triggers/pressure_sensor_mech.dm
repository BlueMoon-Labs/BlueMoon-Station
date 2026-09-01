//Mech sensor: Activates when stepped on by a mech
/obj/structure/destructible/clockwork/trap/trigger/pressure_sensor/mech
	name = "mech sensor"
	desc = "Тонкая пластина из латуни, едва заметная, но отчетливо различимая."
	clockwork_desc = "Триггер, который активируется, когда по нему пробегает мех, управляемый человеком, не являющимся слугой."
	max_integrity = 5
	icon_state = "pressure_sensor"
	alpha = 75

/obj/structure/destructible/clockwork/trap/trigger/pressure_sensor/mech/Crossed(atom/movable/AM)
	. = ..()
	if(!istype(AM,/obj/vehicle/sealed/mecha/))
		return

	var/obj/vehicle/sealed/mecha/M = AM
	if(LAZYLEN(M.occupants))
		for(var/mob/living/MB in M.occupants)
			if(is_servant_of_ratvar(MB))
				return
	audible_message("<i>*клик*</i>")
	playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)
	activate()
