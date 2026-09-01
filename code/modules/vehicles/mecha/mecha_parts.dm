/////////////////////////
////// Mecha Parts //////
/////////////////////////

/obj/item/mecha_parts
	name = "mecha part"
	icon = 'icons/mecha/mech_construct.dmi'
	icon_state = "blank"
	w_class = WEIGHT_CLASS_GIGANTIC
	flags_1 = CONDUCT_1

/obj/item/mecha_parts/proc/try_attach_part(mob/user, obj/vehicle/sealed/mecha/M) //For attaching parts to a finished mech
	if(!user.transferItemToLoc(src, M))
		to_chat(user, "<span class='warning'>\The [src] is stuck to your hand, you cannot put it in \the [M]!</span>")
		return FALSE
	user.visible_message("<span class='notice'>[user] attaches [src] to [M].</span>", "<span class='notice'>You attach [src] to [M].</span>")
	return TRUE

/obj/item/mecha_parts/part/try_attach_part(mob/user, obj/vehicle/sealed/mecha/M)
	return

/obj/item/mecha_parts/chassis
	name = "Mecha Chassis"
	icon_state = "backbone"
	interaction_flags_item = NONE			//Don't pick us up!!
	var/construct_type

/obj/item/mecha_parts/chassis/Initialize(mapload)
	. = ..()
	if(construct_type)
		AddComponent(construct_type)

/////////// Ripley

/obj/item/mecha_parts/chassis/ripley
	name = "\improper Ripley chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/ripley

/obj/item/mecha_parts/part/ripley_torso
	name = "\improper Ripley torso"
	desc = "Корпус Ripley APLU. Содержит силовой агрегат, процессор и системы жизнеобеспечения."
	icon_state = "ripley_harness"

/obj/item/mecha_parts/part/ripley_left_arm
	name = "\improper Ripley left arm"
	desc = "Левая рука Ripley APLU. Разъёмы данных и питания совместимы с большинством инструментов экзокостюма."
	icon_state = "ripley_l_arm"

/obj/item/mecha_parts/part/ripley_right_arm
	name = "\improper Ripley right arm"
	desc = "Правая рука Ripley APLU. Разъёмы данных и питания совместимы с большинством инструментов экзокостюма."
	icon_state = "ripley_r_arm"

/obj/item/mecha_parts/part/ripley_left_leg
	name = "\improper Ripley left leg"
	desc = "Левая нога Ripley APLU. Содержит довольно сложные сервоприводы и системы поддержания баланса."
	icon_state = "ripley_l_leg"

/obj/item/mecha_parts/part/ripley_right_leg
	name = "\improper Ripley right leg"
	desc = "Правая нога Ripley APLU. Содержит довольно сложные сервоприводы и системы поддержания баланса."
	icon_state = "ripley_r_leg"


//Firefighter
/obj/item/mecha_parts/chassis/firefighter
	name = "\improper Firefighter chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/firefighter

///////// Odysseus

/obj/item/mecha_parts/chassis/odysseus
	name = "\improper Odysseus chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/odysseus

/obj/item/mecha_parts/part/odysseus_head
	name = "\improper Odysseus head"
	desc = "Голова Odysseus. Содержит встроенный медицинский HUD-сканер."
	icon_state = "odysseus_head"

/obj/item/mecha_parts/part/odysseus_torso
	name = "\improper Odysseus torso"
	desc="Корпус Odysseus. Содержит силовой агрегат, процессор и системы жизнеобеспечения, а также разъём для установки медицинской капсулы."
	icon_state = "odysseus_torso"

/obj/item/mecha_parts/part/odysseus_left_arm
	name = "\improper Odysseus left arm"
	desc = "Левая рука Odysseus. Разъёмы данных и питания совместимы с медицинским оборудованием."
	icon_state = "odysseus_l_arm"

/obj/item/mecha_parts/part/odysseus_right_arm
	name = "\improper Odysseus right arm"
	desc = "Правая рука Odysseus. Разъёмы данных и питания совместимы с медицинским оборудованием."
	icon_state = "odysseus_r_arm"

/obj/item/mecha_parts/part/odysseus_left_leg
	name = "\improper Odysseus left leg"
	desc = "Левая нога Odysseus. Содержит сложные сервоприводы и системы поддержания баланса для стабильности при транспортировке критических пациентов."
	icon_state = "odysseus_l_leg"

/obj/item/mecha_parts/part/odysseus_right_leg
	name = "\improper Odysseus right leg"
	desc = "Правая нога Odysseus. Содержит сложные сервоприводы и системы поддержания баланса для стабильности при транспортировке критических пациентов."
	icon_state = "odysseus_r_leg"

///////// Gygax

/obj/item/mecha_parts/chassis/gygax
	name = "\improper Gygax chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/gygax

/obj/item/mecha_parts/part/gygax_torso
	name = "\improper Gygax torso"
	desc = "Корпус Gygax. Содержит силовой агрегат, процессор и системы жизнеобеспечения."
	icon_state = "gygax_harness"

/obj/item/mecha_parts/part/gygax_head
	name = "\improper Gygax head"
	desc = "Голова Gygax. Вмещает продвинутые датчики наблюдения и наведения."
	icon_state = "gygax_head"

/obj/item/mecha_parts/part/gygax_left_arm
	name = "\improper Gygax left arm"
	desc = "Левая рука Gygax. Разъёмы данных и питания совместимы с большинством инструментов и оружия экзокостюма."
	icon_state = "gygax_l_arm"

/obj/item/mecha_parts/part/gygax_right_arm
	name = "\improper Gygax right arm"
	desc = "Правая рука Gygax. Разъёмы данных и питания совместимы с большинством инструментов и оружия экзокостюма."
	icon_state = "gygax_r_arm"

/obj/item/mecha_parts/part/gygax_left_leg
	name = "\improper Gygax left leg"
	desc = "Левая нога Gygax. Построена с использованием продвинутых сервомеханизмов и актуаторов для повышения скорости."
	icon_state = "gygax_l_leg"

/obj/item/mecha_parts/part/gygax_right_leg
	name = "\improper Gygax right leg"
	desc = "Правая нога Gygax. Построена с использованием продвинутых сервомеханизмов и актуаторов для повышения скорости."
	icon_state = "gygax_r_leg"

/obj/item/mecha_parts/part/gygax_armor
	gender = PLURAL
	name = "\improper Gygax armor plates"
	desc = "Набор броневых пластин для Gygax. Разработаны для эффективного отклонения повреждений при минимальном весе."
	icon_state = "gygax_armor"

///////// Medical Gygax

/obj/item/mecha_parts/chassis/medigax
	name = "\improper Medical Gygax chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/medigax

/obj/item/mecha_parts/part/medigax_torso
	name = "\improper Medical Gygax torso"
	desc = "Корпус Medical Gygax. Содержит силовой агрегат, процессор и системы жизнеобеспечения."
	icon_state = "medigax_harness"

/obj/item/mecha_parts/part/medigax_head
	name = "\improper Medical Gygax head"
	desc = "Голова Medical Gygax. Вмещает продвинутые датчики наблюдения и наведения."
	icon_state = "medigax_head"

/obj/item/mecha_parts/part/medigax_left_arm
	name = "\improper Medical Gygax left arm"
	desc = "Левая рука Medical Gygax. Разъёмы данных и питания совместимы с большинством инструментов и оружия экзокостюма."
	icon_state = "medigax_l_arm"

/obj/item/mecha_parts/part/medigax_right_arm
	name = "\improper Medical Gygax right arm"
	desc = "Правая рука Medical Gygax. Разъёмы данных и питания совместимы с большинством инструментов и оружия экзокостюма."
	icon_state = "medigax_r_arm"

/obj/item/mecha_parts/part/medigax_left_leg
	name = "\improper Medical Gygax left leg"
	desc = "Левая нога Medical Gygax. Построена с использованием продвинутых сервомеханизмов и актуаторов для повышения скорости."
	icon_state = "medigax_l_leg"

/obj/item/mecha_parts/part/medigax_right_leg
	name = "\improper Medical Gygax right leg"
	desc = "Правая нога Medical Gygax. Построена с использованием продвинутых сервомеханизмов и актуаторов для повышения скорости."
	icon_state = "medigax_r_leg"

/obj/item/mecha_parts/part/medigax_armor
	gender = PLURAL
	name = "\improper Medical Gygax armor plates"
	desc = "Набор броневых пластин для Medical Gygax. Разработаны для эффективного отклонения повреждений при минимальном весе."
	icon_state = "medigax_armor"

//////////// Durand

/obj/item/mecha_parts/chassis/durand
	name = "\improper Durand chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/durand

/obj/item/mecha_parts/part/durand_torso
	name = "\improper Durand torso"
	desc = "Корпус Durand. Содержит силовой агрегат, процессор и системы жизнеобеспечения в прочном защитном каркасе."
	icon_state = "durand_harness"

/obj/item/mecha_parts/part/durand_head
	name = "\improper Durand head"
	desc = "Голова Durand. Вмещает продвинутые датчики наблюдения и наведения."
	icon_state = "durand_head"

/obj/item/mecha_parts/part/durand_left_arm
	name = "\improper Durand left arm"
	desc = "Левая рука Durand. Разъёмы данных и питания совместимы с большинством инструментов и оружия экзокостюма. Обладает крайне мощным ударом."
	icon_state = "durand_l_arm"

/obj/item/mecha_parts/part/durand_right_arm
	name = "\improper Durand right arm"
	desc = "Правая рука Durand. Разъёмы данных и питания совместимы с большинством инструментов и оружия экзокостюма. Обладает крайне мощным ударом."
	icon_state = "durand_r_arm"

/obj/item/mecha_parts/part/durand_left_leg
	name = "\improper Durand left leg"
	desc = "Левая нога Durand. Построена особенно прочно, чтобы выдерживать большой вес и обеспечивать защиту."
	icon_state = "durand_l_leg"

/obj/item/mecha_parts/part/durand_right_leg
	name = "\improper Durand right leg"
	desc = "Правая нога Durand. Построена особенно прочно, чтобы выдерживать большой вес и обеспечивать защиту."
	icon_state = "durand_r_leg"

/obj/item/mecha_parts/part/durand_armor
	gender = PLURAL
	name = "\improper Durand armor plates"
	desc = "Набор броневых пластин для Durand. Тяжёлые, рассчитаны на сопротивление огромному количеству грубой силы."
	icon_state = "durand_armor"


////////// HONK

/obj/item/mecha_parts/chassis/honker
	name = "\improper H.O.N.K chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/honker

/obj/item/mecha_parts/part/honker_torso
	name = "\improper H.O.N.K torso"
	desc = "Корпус H.O.N.K. Содержит смеховой блок, ядро из банания и системы поддержания хонка."
	icon_state = "honker_harness"

/obj/item/mecha_parts/part/honker_head
	name = "\improper H.O.N.K head"
	desc = "Голова H.O.N.K. Кажется, ей не хватает лицевой пластины."
	icon_state = "honker_head"

/obj/item/mecha_parts/part/honker_left_arm
	name = "\improper H.O.N.K left arm"
	desc = "Левая рука H.O.N.K. Имеет уникальные разъёмы, совместимые с необычным оружием, разработанным клоунскими учёными."
	icon_state = "honker_l_arm"

/obj/item/mecha_parts/part/honker_right_arm
	name = "\improper H.O.N.K right arm"
	desc = "Правая рука H.O.N.K. Имеет уникальные разъёмы, совместимые с необычным оружием, разработанным клоунскими учёными."
	icon_state = "honker_r_arm"

/obj/item/mecha_parts/part/honker_left_leg
	name = "\improper H.O.N.K left leg"
	desc = "Левая нога H.O.N.K. Стопа кажется достаточно большой, чтобы полностью вместить клоунский башмак."
	icon_state = "honker_l_leg"

/obj/item/mecha_parts/part/honker_right_leg
	name = "\improper H.O.N.K right leg"
	desc = "Правая нога H.O.N.K. Стопа кажется достаточно большой, чтобы полностью вместить клоунский башмак."
	icon_state = "honker_r_leg"


////////// Phazon

/obj/item/mecha_parts/chassis/phazon
	name = "\improper Phazon chassis"
	construct_type = /datum/component/construction/unordered/mecha_chassis/phazon

/obj/item/mecha_parts/chassis/phazon/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(istype(I, /obj/item/assembly/signaler/anomaly) && !istype(I, /obj/item/assembly/signaler/anomaly/bluespace))
		to_chat(user, "The anomaly core socket only accepts bluespace anomaly cores!")

/obj/item/mecha_parts/part/phazon_torso
	name="\improper Phazon torso"
	desc="Корпус Phazon. Разъём для блюспейс-ядра, питающего уникальные фазовые приводы экзокостюма, находится посередине."
	icon_state = "phazon_harness"

/obj/item/mecha_parts/part/phazon_head
	name="\improper Phazon head"
	desc="Голова Phazon. Датчики тщательно откалиброваны для обеспечения зрения и данных даже при фазовом сдвиге."
	icon_state = "phazon_head"

/obj/item/mecha_parts/part/phazon_left_arm
	name="\improper Phazon left arm"
	desc="Левая рука Phazon. Под броневыми пластинами расположены несколько микроинструментальных массивов, которые можно подстроить под ситуацию."
	icon_state = "phazon_l_arm"

/obj/item/mecha_parts/part/phazon_right_arm
	name="\improper Phazon right arm"
	desc="Правая рука Phazon. Под броневыми пластинами расположены несколько микроинструментальных массивов, которые можно подстроить под ситуацию."
	icon_state = "phazon_r_arm"

/obj/item/mecha_parts/part/phazon_left_leg
	name="\improper Phazon left leg"
	desc="Левая нога Phazon. Содержит уникальные фазовые приводы, позволяющие экзокостюму проходить сквозь твёрдую материю при активации."
	icon_state = "phazon_l_leg"

/obj/item/mecha_parts/part/phazon_right_leg
	name="\improper Phazon right leg"
	desc="Правая нога Phazon. Содержит уникальные фазовые приводы, позволяющие экзокостюму проходить сквозь твёрдую материю при активации."
	icon_state = "phazon_r_leg"

/obj/item/mecha_parts/part/phazon_armor
	name="Phazon armor"
	desc="Броневые пластины Phazon. Слоистая плазменная защита оберегает пилота от стресса фазовых переходов и обладает необычными свойствами."
	icon_state = "phazon_armor"

///////// Circuitboards

/obj/item/circuitboard/mecha
	name = "exosuit circuit board"
	icon = 'icons/obj/module.dmi'
	icon_state = "std_mod"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1
	force = 5
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	throw_speed = 3
	throw_range = 7

/obj/item/circuitboard/mecha/ripley/peripherals
	name = "Ripley Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/ripley/main
	name = "Ripley Central Control module (Exosuit Board)"
	icon_state = "mainboard"


/obj/item/circuitboard/mecha/gygax/peripherals
	name = "Gygax Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/gygax/targeting
	name = "Gygax Weapon Control and Targeting module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/gygax/main
	name = "Gygax Central Control module (Exosuit Board)"
	icon_state = "mainboard"

/obj/item/circuitboard/mecha/durand/peripherals
	name = "Durand Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/durand/targeting
	name = "Durand Weapon Control and Targeting module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/durand/main
	name = "Durand Central Control module (Exosuit Board)"
	icon_state = "mainboard"

/obj/item/circuitboard/mecha/honker/peripherals
	name = "H.O.N.K Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/honker/targeting
	name = "H.O.N.K Weapon Control and Targeting module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/honker/main
	name = "H.O.N.K Central Control module (Exosuit Board)"
	icon_state = "mainboard"

/obj/item/circuitboard/mecha/odysseus/peripherals
	name = "Odysseus Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/odysseus/main
	name = "Odysseus Central Control module (Exosuit Board)"
	icon_state = "mainboard"

/obj/item/circuitboard/mecha/phazon/peripherals
	name = "Phazon Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/phazon/targeting
	name = "Phazon Weapon Control and Targeting module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/phazon/main
	name = "Phazon Central Control module (Exosuit Board)"

/obj/item/circuitboard/mecha/clarke/peripherals
	name = "Clarke Peripherals Control module (Exosuit Board)"
	icon_state = "mcontroller"

/obj/item/circuitboard/mecha/clarke/main
	name = "Clarke Central Control module (Exosuit Board)"
	icon_state = "mainboard"
