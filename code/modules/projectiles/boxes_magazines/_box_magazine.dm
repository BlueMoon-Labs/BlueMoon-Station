//Boxes of ammo

/// Временный диагностический режим. Закомментируйте строку, чтобы убрать логи.
//#define AMMO_DEBUG_LOGS

#ifdef AMMO_DEBUG_LOGS
/proc/log_ammo_debug(text)
	log_world("AMMODBG: [text]")
	WRITE_LOG(GLOB.world_game_log, "AMMODBG: [text]")

/proc/ammo_dbg_value(value)
	if(islist(value))
		var/list/L = value
		return "list(len=[L.len]):[L.Join(",")]"
	if(isnull(value))
		return "null"
	return "[value] [istext(value) ? "(text)" : "(other)"]"

/// Админский self-test: проверяет пары «контейнер / патрон» и пишет результат в логи.
/client/proc/debug_ammo_selftest()
	set category = "Debug"
	set name = "Debug Ammo Compatibility"
	set desc = "Run ammo caliber compatibility self-test and write results to AMMODBG logs."

	if(!check_rights(R_ADMIN))
		return

	var/list/cases = list(
		list(/obj/item/ammo_box/magazine/m10mm, /obj/item/ammo_casing/c10mm, TRUE),
		list(/obj/item/ammo_box/magazine/acr5m30, /obj/item/ammo_casing/a58mm, TRUE),
		list(/obj/item/ammo_box/magazine/acr5m30/ap, /obj/item/ammo_casing/a58mm/ap, TRUE),
		list(/obj/item/ammo_box/magazine/internal/cylinder, /obj/item/ammo_casing/a357, TRUE),
		list(/obj/item/ammo_box/magazine/internal/cylinder, /obj/item/ammo_casing/c38, TRUE),
		list(/obj/item/ammo_box/magazine/rrcmag, /obj/item/ammo_casing/shotgun/buckshot, TRUE),
		list(/obj/item/ammo_box/magazine/flechette/shredder, /obj/item/ammo_casing/caseless/flechetteshredder, TRUE),
		list(/obj/item/ammo_box/magazine/m50/ctf, /obj/item/ammo_casing/a50/ctf, TRUE),
		list(/obj/item/ammo_box/magazine/m10mm, /obj/item/ammo_casing/a58mm, FALSE),
		list(/obj/item/ammo_box/magazine/internal/cylinder, /obj/item/ammo_casing/a357/requiem, FALSE)
	)

	var/passed = 0
	var/failed = 0
	log_ammo_debug("SELFTEST START by [key_name(src)] cases=[length(cases)]")

	for(var/list/test_case in cases)
		var/box_type = test_case[1]
		var/casing_type = test_case[2]
		var/expected = test_case[3]
		var/obj/item/ammo_box/box = new box_type
		var/obj/item/ammo_casing/casing = new casing_type
		box.stored_ammo.Cut()
		// cylinder/give_round() заменяет только существующие позиции, поэтому
		// барабану нужны пустые слоты, а обычному магазину — пустой список.
		if(istype(box, /obj/item/ammo_box/magazine/internal/cylinder))
			for(var/i in 1 to box.max_ammo)
				box.stored_ammo += null
		var/compat = box.caliber_compatible(casing)
		var/given = box.give_round(casing)
		var/ok = (compat == expected && given == expected)
		if(ok)
			passed++
		else
			failed++
		log_ammo_debug("SELFTEST [ok ? "PASS" : "FAIL"] box=[box_type] casing=[casing_type] expected=[expected] compat=[compat] give=[given] box_cal=[ammo_dbg_value(box.caliber)] casing_cal=[ammo_dbg_value(casing.caliber)] ammo_type=[box.ammo_type]")
		qdel(box)
		qdel(casing)

	log_ammo_debug("SELFTEST END passed=[passed] failed=[failed]")
	to_chat(src, "<span class='notice'>Ammo self-test: [passed] passed, [failed] failed. Смотри AMMODBG в логах.</span>")
#endif

/obj/item/ammo_box
	name = "ammo box (null_reference_exception)"
	desc = "A box of ammo."
	icon = 'icons/obj/ammo.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	item_state = "syringe_kit"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron = 30000)
	throwforce = 2
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 3
	throw_range = 7
	var/list/stored_ammo = list()
	var/ammo_type = /obj/item/ammo_casing
	var/max_ammo = 7
	var/multiple_sprites = 0
	var/caliber
	var/multiload = 1
	var/start_empty = 0
	var/list/bullet_cost
	var/list/base_cost// override this one as well if you override bullet_cost
	var/speedloader = FALSE

	/// When inserted into an ammo workbench, does this ammo box check for parent ammunition to search for subtypes of? Relevant for surplus clips, multi-sprite magazines.
	/// Maybe don't enable this for shotgun ammo boxes.
	var/multitype = TRUE

/obj/item/ammo_box/Initialize(mapload)
	. = ..()
	if (!bullet_cost)
		for (var/material in custom_materials)
			var/material_amount = custom_materials[material]
			LAZYSET(base_cost, material, (material_amount * 0.10))

			material_amount *= 0.90 // 10% for the container
			material_amount /= max_ammo
			LAZYSET(bullet_cost, material, material_amount)
	if(!start_empty)
		for(var/i = 1, i <= max_ammo, i++)
			stored_ammo += new ammo_type(src)
	update_icon()

/// Casings live inside us, so every remaining round is a hard reference back to
/// the box. Leaving them behind means a qdeleted magazine can never soft-GC and
/// always costs a hard delete - which internal magazines pay on every gun death.
/obj/item/ammo_box/Destroy()
	for(var/obj/item/ammo_casing/casing as anything in stored_ammo)
		if(QDELETED(casing))
			continue
		if(casing.loc == src)
			qdel(casing)
	stored_ammo.Cut()
	return ..()

/obj/item/ammo_box/examine(mob/user)
	. = ..()
	. += span_notice("There [stored_ammo.len == 1 ? "is" : "are"] [stored_ammo.len] shell\s left!")

/obj/item/ammo_box/proc/get_round(keep = 0)
	if (!stored_ammo.len)
		return null
	else
		var/b = stored_ammo[stored_ammo.len]
		stored_ammo -= b
		if (keep)
			stored_ammo.Insert(1,b)
		return b

/// Калибр магазина и гильзы может быть как строкой, так и списком калибров
/// (например, револьверные барабаны). Пустой список трактуется как «калибр не задан»,
/// а не как отдельный калибр: раньше он не совпадал ни с одной строкой.
/obj/item/ammo_box/proc/calibers_match(first, second)
	if(islist(first))
		if(islist(second))
			for(var/check_caliber in first)
				if(check_caliber in second)
					return TRUE
			return FALSE
		return second in first

	if(islist(second))
		return first in second

	return first == second

/obj/item/ammo_box/proc/caliber_compatible(obj/item/ammo_casing/R)
	if(!R)
		#ifdef AMMO_DEBUG_LOGS
		log_ammo_debug("compat 1 !R box=[src] ([src.type])")
		#endif
		return FALSE

	var/box_caliber = caliber
	var/round_caliber = R.caliber
	var/box_has_caliber = !isnull(box_caliber) && (!islist(box_caliber) || length(box_caliber))
	var/round_has_caliber = !isnull(round_caliber) && (!islist(round_caliber) || length(round_caliber))

	// Хотя бы у одной стороны нет калибра — fallback по типу патрона.
	// Если калибр есть только у гильзы, не пускаем подтип с чужим калибром
	// (например, requiem в обычный .357 барабан).
	if(!box_has_caliber || !round_has_caliber)
		var/type_ok = (R.type == ammo_type || istype(R, ammo_type))
		if(type_ok && round_has_caliber && !box_has_caliber)
			var/obj/item/ammo_casing/ammo_box_type = ammo_type
			type_ok = calibers_match(initial(ammo_box_type.caliber), round_caliber)

		#ifdef AMMO_DEBUG_LOGS
		log_ammo_debug("compat 2 fallback box=[src] ([src.type]) ammo_type=[ammo_type] box_cal=[ammo_dbg_value(box_caliber)] casing=[R.type] round_cal=[ammo_dbg_value(round_caliber)] type_ok=[type_ok] => [type_ok]")
		#endif
		return type_ok

	var/result = calibers_match(box_caliber, round_caliber)
	#ifdef AMMO_DEBUG_LOGS
	log_ammo_debug("compat 3 match box=[src] ([src.type]) box_cal=[ammo_dbg_value(box_caliber)] casing=[R.type] round_cal=[ammo_dbg_value(round_caliber)] => [result]")
	#endif
	return result

/obj/item/ammo_box/proc/give_round(obj/item/ammo_casing/R, replace_spent = 0)
	// Boxes don't have a caliber type, magazines do. If we fail to find a caliber, then we fall back to ammo_type.
	if(!caliber_compatible(R))
		#ifdef AMMO_DEBUG_LOGS
		log_ammo_debug("give_round REJECT box=[src] ([src.type]) casing=[R?.type] stored=[stored_ammo.len]/[max_ammo] replace_spent=[replace_spent]")
		#endif
		return FALSE

	if (stored_ammo.len < max_ammo)
		stored_ammo += R
		R.forceMove(src)
		#ifdef AMMO_DEBUG_LOGS
		log_ammo_debug("give_round OK box=[src] ([src.type]) casing=[R.type] stored=[stored_ammo.len]/[max_ammo]")
		#endif
		return TRUE

	//for accessibles magazines (e.g internal ones) when full, start replacing spent ammo
	else if(replace_spent)
		for(var/obj/item/ammo_casing/AC in stored_ammo)
			if(!AC.BB)//found a spent ammo
				stored_ammo -= AC
				AC.forceMove(get_turf(src.loc))

				stored_ammo += R
				R.forceMove(src)
				#ifdef AMMO_DEBUG_LOGS
				log_ammo_debug("give_round OK (replace_spent) box=[src] ([src.type]) casing=[R.type] stored=[stored_ammo.len]/[max_ammo]")
				#endif
				return TRUE

	#ifdef AMMO_DEBUG_LOGS
	log_ammo_debug("give_round FULL box=[src] ([src.type]) casing=[R.type] stored=[stored_ammo.len]/[max_ammo] replace_spent=[replace_spent]")
	#endif
	return FALSE

/obj/item/ammo_box/proc/can_load(mob/user)
	return TRUE

/obj/item/ammo_box/attackby(obj/item/A, mob/user, params, silent = FALSE, replace_spent = 0)
	#ifdef AMMO_DEBUG_LOGS
	log_ammo_debug("attackby IN target=[src] ([src.type]) item=[A] ([A?.type]) user=[key_name(user)] replace_spent=[replace_spent]")
	#endif
	var/num_loaded = 0
	if(!can_load(user))
		#ifdef AMMO_DEBUG_LOGS
		log_ammo_debug("attackby BLOCKED can_load target=[src] ([src.type]) user=[key_name(user)]")
		#endif
		return
	if(istype(A, /obj/item/ammo_box))
		var/obj/item/ammo_box/AM = A
		for(var/obj/item/ammo_casing/AC in AM.stored_ammo)
			var/did_load = give_round(AC, replace_spent)
			if(did_load)
				AM.stored_ammo -= AC
				num_loaded++
			if(!did_load || !multiload)
				break
	if(istype(A, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/AC = A
		if(give_round(AC, replace_spent))
			user.transferItemToLoc(AC, src, TRUE)
			num_loaded++

	#ifdef AMMO_DEBUG_LOGS
	log_ammo_debug("attackby OUT target=[src] ([src.type]) item=[A?.type] loaded=[num_loaded] stored=[stored_ammo.len]/[max_ammo]")
	#endif
	if(num_loaded)
		if(!silent)
			to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src]!</span>")
			playsound(src, 'sound/weapons/bulletinsert.ogg', 60, 1)
		A.update_icon()
		update_icon()

	return num_loaded

/obj/item/ammo_box/attack_self(mob/user)
	var/obj/item/ammo_casing/A = get_round()
	if(A)
		if(!user.put_in_hands(A))
			A.bounce_away(FALSE, NONE)
		playsound(src, 'sound/weapons/bulletinsert.ogg', 60, 1)
		to_chat(user, "<span class='notice'>You remove a round from \the [src]!</span>")
		update_icon()

/obj/item/ammo_box/update_icon()
	. = ..()
	if(length(bullet_cost))
		var/temp_materials = custom_materials.Copy()
		for (var/material in bullet_cost)
			var/material_amount = bullet_cost[material]
			material_amount = (material_amount*stored_ammo.len) + base_cost[material]
			temp_materials[material] = material_amount
		set_custom_materials(temp_materials)

/obj/item/ammo_box/update_icon_state()
	switch(multiple_sprites)
		if(1)
			icon_state = "[initial(icon_state)]-[stored_ammo.len]"
		if(2)
			icon_state = "[initial(icon_state)]-[stored_ammo.len ? "[max_ammo]" : "0"]"

//Behavior for magazines
/obj/item/ammo_box/magazine
	w_class = WEIGHT_CLASS_SMALL

/obj/item/ammo_box/magazine/proc/ammo_count()
	return stored_ammo.len

/obj/item/ammo_box/magazine/proc/empty_magazine()
	var/turf_mag = get_turf(src)
	for(var/obj/item/ammo_casing/ammo as anything in stored_ammo)
		ammo.forceMove(turf_mag)
		stored_ammo -= ammo
		if(istype(ammo))
			ammo.bounce_away(isnull(ammo.BB))

/obj/item/ammo_box/magazine/handle_atom_del(atom/A)
	stored_ammo -= A
	update_icon()
