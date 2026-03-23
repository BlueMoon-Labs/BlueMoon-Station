/* Types of tanks!
 * Contains:
 *		Oxygen
 *		Anesthetic
 *		Air
 *		Plasma
 *		Emergency Oxygen
 */

/*
 * Oxygen
 */
/obj/item/tank/internals/oxygen
	name = "oxygen tank"
	desc = "Баллон кислорода синего цвета."
	icon_state = "oxygen"
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
	force = 10
	dog_fashion = /datum/dog_fashion/back


/obj/item/tank/internals/oxygen/populate_gas()
	air_contents.set_moles(GAS_O2, (6*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return


/obj/item/tank/internals/oxygen/yellow
	desc = "Баллон кислорода жёлтого цвета."
	icon_state = "oxygen_f"
	dog_fashion = null

/obj/item/tank/internals/oxygen/red
	desc = "Баллон кислорода красного цвета."
	icon_state = "oxygen_fr"
	dog_fashion = null

/obj/item/tank/internals/oxygen/empty/populate_gas()
	return

/*
 * Anesthetic
 */
/obj/item/tank/internals/anesthetic
	name = "anesthetic tank"
	desc = "Баллон с газовой смесью N2O/O2."
	icon_state = "anesthetic"
	item_state = "an_tank"
	force = 10
	// BLUEMOON ADD START - снижаем время надевания и снимания анестезии
	equip_delay_other = 10
	strip_delay = 20
	// BLUEMOON ADD END

/obj/item/tank/internals/anesthetic/populate_gas()
	air_contents.set_moles(GAS_O2, (3*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C) * O2STANDARD)
	air_contents.set_moles(GAS_NITROUS, (3*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C) * N2STANDARD)
	return

/*
 * Air
 */
/obj/item/tank/internals/air
	name = "air tank"
	desc = "Mixed anyone?"
	item_state = "air"
	force = 10
	dog_fashion = /datum/dog_fashion/back

/obj/item/tank/internals/air/populate_gas()
	air_contents.set_moles(GAS_O2, (6*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C) * O2STANDARD)
	air_contents.set_moles(GAS_N2, (6*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C) * N2STANDARD)
	return


/*
 * Plasma
 */
/obj/item/tank/internals/plasma
	name = "plasma tank"
	desc = "Содержит опасную плазму. Не вдыхать. Внимание: экстремально горючее."
	icon_state = "plasma"
	flags_1 = CONDUCT_1
	slot_flags = null	//they have no straps!
	force = 8


/obj/item/tank/internals/plasma/populate_gas()
	air_contents.set_moles(GAS_PLASMA, (3*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

/obj/item/tank/internals/plasma/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/flamethrower))
		var/obj/item/flamethrower/F = W
		if ((!F.status)||(F.ptank))
			return
		if(!user.transferItemToLoc(src, F))
			return
		src.master = F
		F.ptank = src
		F.update_icon()
	else
		return ..()

/obj/item/tank/internals/plasma/full/populate_gas()
	air_contents.set_moles(GAS_PLASMA, (10*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))

//Makes empty oxygen tanks spawn without gas
/obj/item/tank/internals/plasma/empty/populate_gas()
	return

/obj/item/tank/internals/plasma/full/populate_gas()
	air_contents.set_moles(GAS_PLASMA, (10*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))

/*
 * Plasmaman Plasma Tank
 */

/obj/item/tank/internals/plasmaman
	name = "plasma internals tank"
	desc = "Баллон плазмы, спроектированный для дыхания, в частности, плазменными формами жизни. Если вы не плазмачеловек, вам не следует его использовать."
	icon_state = "plasmaman_tank"
	item_state = "plasmaman_tank"
	force = 10
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE

/obj/item/tank/internals/plasmaman/populate_gas()
	air_contents.set_moles(GAS_PLASMA, (3*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

/obj/item/tank/internals/plasmaman/full/populate_gas()
	air_contents.set_moles(GAS_PLASMA, (10*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return


/obj/item/tank/internals/plasmaman/belt
	icon_state = "plasmaman_tank_belt"
	item_state = "plasmaman_tank_belt"
	slot_flags = ITEM_SLOT_BELT
	force = 5
	volume = 6
	w_class = WEIGHT_CLASS_SMALL //thanks i forgot this

/obj/item/tank/internals/plasmaman/belt/full/populate_gas()
	air_contents.set_moles(GAS_PLASMA, (10*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

//makes empty plasma tanks spawn without gas.
/obj/item/tank/internals/plasmaman/belt/empty/populate_gas()
	return

/*
 * Emergency Oxygen
 */
/obj/item/tank/internals/emergency_oxygen
	name = "emergency oxygen tank"
	desc = "Для чрезвычайных ситуаций. Содержит малый объём кислорода, постарайтесь сохранить его на случай крайней необходимости."
	icon_state = "emergency"
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	force = 4
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
	volume = 3 //Tiny. Real life equivalents only have 21 breaths of oxygen in them. They're EMERGENCY tanks anyway -errorage (dangercon 2011)


/obj/item/tank/internals/emergency_oxygen/populate_gas()
	air_contents.set_moles(GAS_O2, (10*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

/obj/item/tank/internals/emergency_oxygen/empty/populate_gas()
	return

/obj/item/tank/internals/emergency_oxygen/engi
	name = "extended-capacity emergency oxygen tank"
	desc = "Для чрезвычайных ситуаций и инженерных нужд. Этот баллон вмещает немного больший объем кислорода, судя по бирке на обратной стороне."
	icon_state = "emergency_engi"
	volume = 6

/obj/item/tank/internals/emergency_oxygen/engi/sec
	name = "security extended-capacity emergency oxygen tank"
	icon_state = "emergency_sec"
	desc = "Тёмно-красный баллон кислорода для чрезвычайных ситуаций. Обычно используется службами безопасности."

/obj/item/tank/internals/emergency_oxygen/engi/syndi
	name = "Suspicious Emergency Oxygen Tank"
	icon_state = "emergency_syndi"
	desc = "Тёмный баллон кислорода. На наклейке сзади написано: \"Оригинальный Дизайн Кислородного Баллона, Все Права Защищены.\""
	volume = 12

/obj/item/tank/internals/emergency_oxygen/engi/empty/populate_gas()
	return

/obj/item/tank/internals/emergency_oxygen/double
	name = "double emergency oxygen tank"
	desc = "Сдвоенный жёлтый баллон кислорода знакомого дизайна. Вмещает почти в два раза больше объёма газа, нежели малый собрат."
	icon_state = "emergency_double"
	volume = 10

/obj/item/tank/internals/emergency_oxygen/double/empty/populate_gas()
	return

/*
 * Methyl Bromide
 */
/obj/item/tank/internals/methyl_bromide
	name = "mantid gas reactor"
	desc = "A mantid gas processing plant that continuously synthesises 'breathable' atmosphere."
	icon_state = "methyl_bromide"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	force = 6
	distribute_pressure = 14
	volume = 10

/obj/item/tank/internals/methyl_bromide/populate_gas()
	air_contents.set_moles(GAS_METHYL_BROMIDE, (6*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return
