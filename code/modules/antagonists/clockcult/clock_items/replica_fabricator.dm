//Replica Fabricator: Converts applicable objects to Ratvarian variants.
/obj/item/clockwork/replica_fabricator
	name = "replica fabricator"
	desc = "Странное устройство в форме буквы L, наполненное энергией."
	clockwork_desc = "Устройство, позволяющее заменять обычные предметы на их ратварские аналоги. Для работы ему требуется энергия."
	icon_state = "replica_fabricator"
	lefthand_file = 'icons/mob/inhands/antag/clockwork_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/clockwork_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	force = 5
	item_flags = NOBLUDGEON
	var/speed_multiplier = 1 //The speed ratio the fabricator operates at
	var/uses_power = TRUE
	var/repairing = null //what we're currently repairing, if anything

/obj/item/clockwork/replica_fabricator/scarab
	name = "scarab fabricator"
	clockwork_desc = "Внутренний фабрикатор жука-шестерни. Им может успешно пользоваться только жук-шестерня, и для его работы требуется энергия."
	item_state = "nothing"
	w_class = WEIGHT_CLASS_TINY
	speed_multiplier = 0.5
	var/debug = FALSE

/obj/item/clockwork/replica_fabricator/scarab/fabricate(atom/target, mob/living/user)
	if(!debug && !isdrone(user))
		return FALSE
	return ..()

/obj/item/clockwork/replica_fabricator/scarab/debug
	clockwork_desc = "Внутренний фабрикатор жука-шестерни. Он способен преобразовывать практически любой объект в ратварскую версию."
	uses_power = FALSE
	debug = TRUE

/obj/item/clockwork/replica_fabricator/cyborg
	name = "cyborg fabricator"
	clockwork_desc = "Внутренний фабрикатор киборга."

/obj/item/clockwork/replica_fabricator/ratvar_act()
	if(GLOB.ratvar_awakens)
		uses_power = FALSE
		speed_multiplier = initial(speed_multiplier) * 0.25
	else
		uses_power = initial(uses_power)
		speed_multiplier = initial(speed_multiplier)

/obj/item/clockwork/replica_fabricator/examine(mob/living/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='brass'>Можно использовать для замены стен, полов, столов, окон, дверей и шлюзов на их механические аналоги.</span>"
		. += "<span class='brass'>Можно создавать часовые стены из часовых полов и разбирать часовые стены на часовые полы.</span>"
		if(uses_power)
			. += "<span class='alloy'>Он может перерабатывать полы, прутья, металл и пласталь в энергию по курсу <b>2:[DisplayPower(POWER_ROD)]</b>, <b>1:[DisplayPower(POWER_ROD)]</b>, <b>1:[DisplayPower(POWER_METAL)]</b>, \
			и <b>1:[DisplayPower(POWER_PLASTEEL)]</b>, соответственно.</span>"
			. += "<span class='alloy'>Он также может перерабатывать листы латуни в энергию по курсу <b>1:[DisplayPower(POWER_FLOOR)]</b>.</span>"
			. += "<span class='alloy'>Используйте его в руке, чтобы создать <b>5</b> листов латуни ценой в <b>[DisplayPower(POWER_WALL_TOTAL)]</b> энергии.</span>"
			. += "<span class='alloy'>Он имеет доступ к <b>[DisplayPower(get_clockwork_power())]</b> энергии.</span>"

/obj/item/clockwork/replica_fabricator/attack_self(mob/living/user)
	if(is_servant_of_ratvar(user))
		if(uses_power)
			if(!get_clockwork_power(POWER_WALL_TOTAL))
				to_chat(user, "<span class='warning'>[src] требует <b>[DisplayPower(POWER_WALL_TOTAL)]</b> энергии, чтобы создать листы латуни!</span>")
				return
			adjust_clockwork_power(-POWER_WALL_TOTAL)
		playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
		new/obj/item/stack/tile/brass(user.loc, 5)
		to_chat(user, "<span class='brass'>Вы используете [get_clockwork_power() ? "часть":"всю"] энергию [src], чтобы создать <b>5</b> листов латуни. Теперь он имеет доступ к <b>[DisplayPower(get_clockwork_power())]</b> энергии.</span>")

/obj/item/clockwork/replica_fabricator/pre_attack(atom/target, mob/living/user, params)
	if(!target || !user || !is_servant_of_ratvar(user) || istype(target, /obj/item/storage))
		return ..()
	return !fabricate(target, user)

//A note here; return values are for if we CAN BE PUT ON A TABLE, not IF WE ARE SUCCESSFUL, unless no_table_check is TRUE
/obj/item/clockwork/replica_fabricator/proc/fabricate(atom/target, mob/living/user, silent, no_table_check)
	if(!target || !user)
		return FALSE
	if(repairing)
		if(!silent)
			to_chat(user, "<span class='warning'>В данный момент вы ремонтируете [repairing] с помощью [src]!</span>")
		return FALSE
	var/list/fabrication_values = target.fabrication_vals(user, src, silent) //relevant values for fabricating stuff, given as an associated list
	if(!islist(fabrication_values))
		if(fabrication_values != TRUE) //if we get true, fail, but don't send a message for whatever reason
			if(!isturf(target)) //otherwise, if we didn't get TRUE and the original target wasn't a turf, try to fabricate the turf
				return fabricate(get_turf(target), user, no_table_check)
			if(!silent)
				to_chat(user, "<span class='warning'>[target] не может быть создан!</span>")
			if(!no_table_check)
				return TRUE
		return FALSE
	if(GLOB.ratvar_awakens)
		fabrication_values["power_cost"] = 0

	var/turf/Y = get_turf(user)
	if(!Y || (!is_centcom_level(Y.z) && !is_station_level(Y.z) && !is_mining_level(Y.z)))
		fabrication_values["operation_time"] *= 2
		if(fabrication_values["power_cost"] > 0)
			fabrication_values["power_cost"] *= 2

	var/target_type = target.type

	if(!fabricate_checks(fabrication_values, target, target_type, user, silent))
		return FALSE

	fabrication_values["operation_time"] *= speed_multiplier

	playsound(target, 'sound/machines/click.ogg', 50, 1)
	if(fabrication_values["operation_time"])
		if(!silent)
			var/atom/A = fabrication_values["new_obj_type"]
			if(A)
				user.visible_message("<span class='warning'>[name] в руках [user] начинает разбирать [target] на части!</span>", \
				"<span class='brass'>Вы начинаете изготавливать [initial(A.name)] из [target]...</span>")
			else
				user.visible_message("<span class='warning'>[name] в руках [user] начинает поглощать [target]!</span>", \
				"<span class='brass'>Ваш [name] начинает поглощать [target]...</span>")
		if(!do_after(user, fabrication_values["operation_time"], target = target, extra_checks = CALLBACK(src, PROC_REF(fabricate_checks), fabrication_values, target, target_type, user, TRUE)))
			return FALSE
		if(!silent)
			var/atom/A = fabrication_values["new_obj_type"]
			if(A)
				user.visible_message("<span class='warning'>[name] в руках [user] заменяет [target] на [initial(A.name)]!</span>", \
				"<span class='brass'>Вы создали [initial(A.name)] из [target].</span>")
			else
				user.visible_message("<span class='warning'>[name] в руках [user] поглощает [target]!</span>", \
				"<span class='brass'>Ваш [name] поглощает [target].</span>")
	else
		if(!silent)
			var/atom/A = fabrication_values["new_obj_type"]
			if(A)
				user.visible_message("<span class='warning'>[name] в руках [user] разбирает [target] на части, заменяя его на [initial(A.name)]!</span>", \
				"<span class='brass'>Вы создаёте [initial(A.name)] из [target].</span>")
			else
				user.visible_message("<span class='warning'>[name] в руках [user] быстро поглощает [target]!</span>", \
				"<span class='brass'>Ваш [name] поглощает [target].</span>")

	playsound(target, 'sound/items/deconstruct.ogg', 50, 1)
	var/new_thing_type = fabrication_values["new_obj_type"]
	if(isturf(target)) //if our target is a turf, we're just going to ChangeTurf it and assume it'll work out.
		var/turf/T = target
		T.ChangeTurf(new_thing_type, flags = CHANGETURF_INHERIT_AIR)
	else
		if(new_thing_type)
			if(fabrication_values["dir_in_new"])
				var/atom/A =  new new_thing_type(get_turf(target), fabrication_values["spawn_dir"]) //please verify that your new object actually wants to get a dir in New()
				if(fabrication_values["transfer_name"])
					A.name = target.name
			else
				var/atom/A = new new_thing_type(get_turf(target))
				A.setDir(fabrication_values["spawn_dir"])
				if(fabrication_values["transfer_name"])
					A.name = target.name
		if(!fabrication_values["no_target_deletion"]) //for some cases where fabrication_vals() modifies the object but doesn't want it deleted
			qdel(target)
	adjust_clockwork_power(-fabrication_values["power_cost"])
	if(no_table_check)
		return TRUE
	return FALSE

//The following three procs are heavy wizardry.
//What these procs do is they take an existing list of values, which they then modify.
//This(modifying an existing object, in this case the list) is the only way to get information OUT of a do_after callback, which this is used as.

//The fabricate check proc.
/obj/item/clockwork/replica_fabricator/proc/fabricate_checks(list/fabrication_values, atom/target, expected_type, mob/user, silent) //checked constantly while fabricating
	if(!islist(fabrication_values) || QDELETED(target) || QDELETED(user))
		return FALSE
	if(repairing)
		return FALSE
	if(target.type != expected_type)
		return FALSE
	if(GLOB.ratvar_awakens)
		fabrication_values["power_cost"] = 0
	if(!get_clockwork_power(fabrication_values["power_cost"]))
		if(get_clockwork_power() - fabrication_values["power_cost"] < 0)
			if(!silent)
				var/atom/A = fabrication_values["new_obj_type"]
				if(A)
					to_chat(user, "<span class='warning'>You need <b>[DisplayPower(fabrication_values["power_cost"])]</b> power to fabricate \a [initial(A.name)] from [target]!</span>")
		return FALSE
	return TRUE

//The repair check proc.
/obj/item/clockwork/replica_fabricator/proc/fabricator_repair_checks(list/repair_values, atom/target, mob/user, silent) //Exists entirely to avoid an otherwise unreadable series of checks.
	if(!islist(repair_values) || QDELETED(target) || QDELETED(user))
		return FALSE
	if(isliving(target)) //standard checks for if we can affect the target
		var/mob/living/L = target
		if(!is_servant_of_ratvar(L))
			if(!silent)
				to_chat(user, "<span class='warning'>[L] не служит Ратвару!</span>")
			return FALSE
		if(L.health >= L.maxHealth || (L.flags_1 & GODMODE))
			if(!silent)
				to_chat(user, "<span class='warning'>[L == user ? "Вы уже имеете максимальное здоровье" : "[L] уже имеет максимальное здоровье"]!</span>")
			return FALSE
		repair_values["amount_to_heal"] = L.maxHealth - L.health
	else if(isobj(target))
		if(istype(target, /obj/structure/destructible/clockwork))
			var/obj/structure/destructible/clockwork/C = target
			if(!C.can_be_repaired)
				if(!silent)
					to_chat(user, "<span class='warning'>[C] не может быть починен!</span>")
				return FALSE
		var/obj/O = target
		if(O.obj_integrity >= O.max_integrity)
			if(!silent)
				to_chat(user, "<span class='warning'>[O] имеет максимальную целостность!</span>")
			return FALSE
		repair_values["amount_to_heal"] = O.max_integrity - O.obj_integrity
	else
		return FALSE
	if(repair_values["amount_to_heal"] <= 0) //nothing to heal!
		return FALSE
	repair_values["healing_for_cycle"] = min(repair_values["amount_to_heal"], FABRICATOR_REPAIR_PER_TICK) //modify the healing for this cycle
	repair_values["power_required"] = round(repair_values["healing_for_cycle"]*MIN_CLOCKCULT_POWER, MIN_CLOCKCULT_POWER) //and get the power cost from that
	if(!GLOB.ratvar_awakens && !get_clockwork_power(repair_values["power_required"]))
		if(!silent)
			to_chat(user, "<span class='warning'>Вам нужно как минимум <b>[DisplayPower(repair_values["power_required"])]</b> энергии, чтобы начать чинить [target == user ? "себя" : "[target]"], и как минимум \
			<b>[DisplayPower(repair_values["amount_to_heal"]*MIN_CLOCKCULT_POWER, MIN_CLOCKCULT_POWER)]</b>, чтобы починить [target == user ? "себя" : "[target.ru_ego()]"] полностью!</span>")
		return FALSE
	return TRUE
