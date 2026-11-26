// robot_upgrades.dm
// Contains various borg upgrades.

/obj/item/borg/upgrade
	name = "borg upgrade module."
	desc = "Защищено FRM."
	icon = 'icons/obj/module.dmi'
	icon_state = "cyborg_upgrade"
	w_class = WEIGHT_CLASS_SMALL
	var/locked = FALSE
	var/installed = FALSE
	var/require_module = FALSE
	var/list/module_type = null
	///	Bitflags listing module compatibility. Used in the exosuit fabricator for creating sub-categories.
	var/module_flags = NONE
	// if true, is not stored in the robot to be ejected
	// if module is reset
	var/one_use = FALSE
	/// Means this is a basetype and should not be used
	var/abstract_type = /obj/item/borg/upgrade
	/// Show the amount of this module that is installed
	var/show_amount = FALSE

/obj/item/borg/upgrade/proc/action(mob/living/silicon/robot/R, user = usr)
	if(R.stat == DEAD)
		to_chat(user, span_warning("[src] will not function on a deceased cyborg!"))
		return FALSE
	if(module_type && !is_type_in_list(R.module, module_type))
		to_chat(R, span_alert("Upgrade mounting error! No suitable hardpoint detected."))
		to_chat(user, span_warning("There's no mounting point for the module!"))
		return FALSE
	return TRUE

/obj/item/borg/upgrade/proc/deactivate(mob/living/silicon/robot/R, user = usr)
	if (!(src in R.upgrades))
		return FALSE
	return TRUE

/// Ищет индекс первого предмета нужного типа в списке модулей киборга. 0 - не нашли.
/obj/item/borg/upgrade/proc/find_module_index(mob/living/silicon/robot/robot, wanted_type)
	if(!robot?.module)
		return 0
	var/list/modules = robot.module.modules
	for(var/index in 1 to length(modules))
		if(istype(modules[index], wanted_type))
			return index
	return 0

/// Меняет местами два предмета в обоих списках модуля киборга.
/// Нулевой индекс - штатная ситуация, а не ошибка: ResetModule() сначала обнуляет
/// модуль (transform_to), и только потом зовёт deactivate() у апгрейдов, так что
/// заменяемого инструмента в списках уже нет. Раньше это уходило в Swap(0, x) и
/// валило "list index out of bounds" (прод-раунд 10150).
/obj/item/borg/upgrade/proc/swap_module_entries(mob/living/silicon/robot/robot, first_index, second_index)
	if(!robot?.module || first_index < 1 || second_index < 1)
		return FALSE
	var/list/modules = robot.module.modules
	if(first_index > length(modules) || second_index > length(modules))
		return FALSE
	modules.Swap(first_index, second_index)
	var/list/basic_modules = robot.module.basic_modules
	if(first_index <= length(basic_modules) && second_index <= length(basic_modules))
		basic_modules.Swap(first_index, second_index)
	return TRUE

// BLUEMOON CYBORG ION SHIELD v10
// Passive hardware upgrade: protects the bearer against the ion storm event.
// It is not a law-upload board, does not alter ordinary AI commands, and has
// no effect on manual admin / AI-module uploads to the cyborg.
/obj/item/borg/upgrade/ion_shield
	name = "Модуль экранирования"
	desc = "Защищает матрицу законов киборга от ионных штормов. При подключении к ИИ отфильтровывает ионные директивы из входящей синхронизации."
	icon_state = "cyborg_upgrade3"
	var/mob/living/silicon/ai/observed_ai
	var/list/observed_ion_laws = list()
	// Ion storms can also insert their law into inherent/supplied.
	var/list/blocked_storm_laws = list()
	var/last_warning_tick = -1
	var/last_warning_law
	// Prevent two storm paths (AI snapshot + direct borg pass) from double-stunning.
	var/last_storm_disruption_tick = -1
	// BLUEMOON CYBORG ION SHIELD v10.1: keep a clean, per-cyborg
	// snapshot. Filtering the ion text alone loses displaced core laws.
	var/mob/living/silicon/ai/protected_ai
	var/remote_storm_active = FALSE
	var/list/safe_inherent
	var/list/safe_supplied
	var/list/last_master_inherent
	var/list/last_master_supplied

/obj/item/borg/upgrade/ion_shield/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return FALSE
	if(R.shell)
		to_chat(user, span_warning("Модуль нельзя установить в оболочку дистанционного управления ИИ."))
		return FALSE
	for(var/obj/item/borg/upgrade/ion_shield/existing in R.upgrades)
		if(!QDELETED(existing))
			to_chat(user, span_warning("У киборга уже установлен модуль экранирования."))
			return FALSE
	observed_ai = R.connected_ai
	observed_ion_laws = observed_ai?.laws?.ion ? observed_ai.laws.ion.Copy() : list()
	to_chat(R, span_notice("Модуль экранирования активирован. Ионные штормы не смогут напрямую переписывать ваши законы."))
	return TRUE

/obj/item/borg/upgrade/ion_shield/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return FALSE
	observed_ai = null
	observed_ion_laws = list()
	blocked_storm_laws = list()
	reset_remote_storm_snapshot()
	to_chat(R, span_warning("Модуль экранирования отключён. Защита от ионных штормов недоступна."))
	return TRUE

/obj/item/borg/upgrade/ion_shield/proc/report_blocked_law(mob/living/silicon/robot/R, law)
	if(QDELETED(R) || !length(law))
		return
	blocked_storm_laws |= "[law]"
	// AI synchronization and the event itself may report the same law in one tick.
	if(last_warning_tick == world.time && last_warning_law == law)
		return
	last_warning_tick = world.time
	last_warning_law = law
	var/safe_law = html_encode_readable("[law]")
	to_chat(R, span_notice("<b>Модуль экранирования сработал.</b> Ионный закон отклонён: <b>«[safe_law]»</b>"))
	R.logevent("Ion shield blocked a proposed ion law.")

// Notice only newly transmitted ion laws; ordinary remote laws still synchronize.
/obj/item/borg/upgrade/ion_shield/proc/reject_remote_ion_laws(mob/living/silicon/robot/R, mob/living/silicon/ai/source_ai, list/incoming)
	if(observed_ai != source_ai)
		observed_ai = source_ai
		observed_ion_laws = incoming ? incoming.Copy() : list()
		return
	if(!incoming)
		observed_ion_laws = list()
		return
	for(var/law in incoming)
		if(!(law in observed_ion_laws))
			report_blocked_law(R, law)
	observed_ion_laws = incoming.Copy()

// A snapshot is owned by the installed module, never by the AI. This is
// important: the AI is allowed to keep its ion-corrupted laws, while this borg
// must retain the version it had immediately before the event.
/obj/item/borg/upgrade/ion_shield/proc/reset_remote_storm_snapshot()
	protected_ai = null
	remote_storm_active = FALSE
	safe_inherent = null
	safe_supplied = null
	last_master_inherent = null
	last_master_supplied = null

/obj/item/borg/upgrade/ion_shield/proc/begin_remote_ion_storm(mob/living/silicon/robot/R, mob/living/silicon/ai/source_ai)
	if(QDELETED(R) || QDELETED(source_ai) || R.connected_ai != source_ai || !R.lawupdate)
		return
	if(remote_storm_active)
		return
	// Bring through any genuine AI edits which happened BEFORE this storm.
	R.lawsync(FALSE)
	R.laws_sanity_check()
	protected_ai = source_ai
	safe_inherent = R.laws.inherent.Copy()
	safe_supplied = R.laws.supplied.Copy()
	last_master_inherent = source_ai.laws.inherent.Copy()
	last_master_supplied = source_ai.laws.supplied.Copy()
	remote_storm_active = TRUE

/obj/item/borg/upgrade/ion_shield/proc/end_remote_ion_storm(mob/living/silicon/robot/R, mob/living/silicon/ai/source_ai)
	if(protected_ai != source_ai || !remote_storm_active)
		return
	// Advance the observation baseline past the storm without accepting any
	// changes to the clean lists. Every later sync compares against THIS baseline.
	if(!QDELETED(source_ai) && source_ai.laws)
		last_master_inherent = source_ai.laws.inherent.Copy()
		last_master_supplied = source_ai.laws.supplied.Copy()
		observed_ai = source_ai
		observed_ion_laws = source_ai.laws.ion.Copy()
	remote_storm_active = FALSE

// Merge only changes the AI made AFTER the storm. Do not rebuild the local
// list from master.inherent/master.supplied: those lists still contain the
// storm's removed/replaced/shuffled laws. A genuine new directive is included;
// a genuine removal of an unaffected law removes that law locally.
/obj/item/borg/upgrade/ion_shield/proc/merge_nonstorm_laws(list/safe, list/old_raw, list/new_raw)
	if(!islist(safe) || !islist(old_raw) || !islist(new_raw))
		return islist(new_raw) ? new_raw.Copy() : list()
	// A deliberate non-storm full reset must still work normally.
	if(!length(new_raw) && length(old_raw))
		return list()
	if(length(new_raw) > 1 && length(old_raw) > 1)
		var/has_common_law = FALSE
		for(var/law in new_raw)
			if(law in old_raw)
				has_common_law = TRUE
				break
		if(!has_common_law)
			return new_raw.Copy()
	// An ordinary edit of a slot of unchanged length replaces that same slot,
	// e.g. updating a supplied law in-place through the normal law UI.
	var/aligned = length(old_raw) == length(new_raw) && length(safe) == length(old_raw)
	if(aligned)
		for(var/i = 1, i <= length(old_raw), i++)
			if(safe[i] != old_raw[i])
				aligned = FALSE
				break
	if(aligned)
		for(var/i = 1, i <= length(new_raw), i++)
			if(old_raw[i] != new_raw[i])
				safe[i] = new_raw[i]
		return safe
	// Structural edits: account for membership rather than raw indices, as
	// a storm can have deleted an original core law from the AI outright.
	var/list/unmatched_old = old_raw.Copy()
	var/list/unmatched_new = new_raw.Copy()
	for(var/law in old_raw)
		if(law in unmatched_new)
			unmatched_new.Remove(law)
			unmatched_old.Remove(law)
	var/list/replacement_slots = list()
	for(var/deleted_law in unmatched_old)
		var/removed_pos = safe.Find(deleted_law)
		if(removed_pos)
			replacement_slots += removed_pos
			safe.Remove(deleted_law)
	for(var/added_law in unmatched_new)
		if(added_law in safe)
			continue
		var/insert_at = length(safe) + 1
		if(length(replacement_slots))
			// Ordinary replacement of a surviving law keeps its old priority.
			insert_at = replacement_slots[1]
			replacement_slots.Cut(1, 2)
		else
			// Ordinary addition: place it ahead of the next surviving source
			// law without disturbing the archived pre-storm directives.
			var/new_pos = new_raw.Find(added_law)
			for(var/j = new_pos + 1, j <= length(new_raw), j++)
				var/next_law = new_raw[j]
				var/next_pos = safe.Find(next_law)
				if(next_pos)
					insert_at = next_pos
					break
		safe.Insert(insert_at, added_law)
	return safe

/obj/item/borg/upgrade/ion_shield/proc/sync_protected_ai_laws(mob/living/silicon/robot/R, datum/ai_laws/master)
	if(QDELETED(R) || !master || !islist(safe_inherent) || !islist(safe_supplied))
		return
	safe_inherent = merge_nonstorm_laws(safe_inherent, last_master_inherent, master.inherent)
	safe_supplied = merge_nonstorm_laws(safe_supplied, last_master_supplied, master.supplied)
	last_master_inherent = master.inherent.Copy()
	last_master_supplied = master.supplied.Copy()
	R.laws.inherent = safe_inherent.Copy()
	R.laws.supplied = safe_supplied.Copy()

// BLUEMOON CYBORG ION SHIELD v10.2
// Shielding an ion storm temporarily overloads the borg's control circuits.
// This is a normal timed paralysis, not death, brain removal or law reset.
/obj/item/borg/upgrade/ion_shield/proc/ion_storm_disruption(mob/living/silicon/robot/R)
	if(QDELETED(src) || QDELETED(R) || R.stat == DEAD || loc != R || !(src in R.upgrades))
		return
	if(last_storm_disruption_tick == world.time)
		return
	last_storm_disruption_tick = world.time
	R.Paralyze(5 SECONDS)
	R.spark_system?.start()
	to_chat(R, span_boldwarning("ИОННЫЙ ШТОРМ: модуль экранирования сохранил ваши законы, но перегрузка временно отключила двигательные системы (5 секунд)."))
	R.logevent("Ion shield interrupted controls for 5 seconds during an ion storm.")

// Any real EMP which reaches the robot destroys only this installed module.
// qdel signals the normal upgrade cleanup; other upgrades are untouched.
/obj/item/borg/upgrade/ion_shield/proc/burn_out_from_emp(mob/living/silicon/robot/R)
	if(QDELETED(src) || QDELETED(R) || loc != R || !(src in R.upgrades))
		return
	to_chat(R, span_userdanger("ЭМИ ПЕРЕГРУЗКА: модуль экранирования необратимо повреждён и уничтожен! Для восстановления защиты установите новый модуль."))
	R.logevent("Ion shielding module destroyed by EMP; replacement hardware required.")
	qdel(src)

/mob/living/silicon/robot/proc/get_ion_shield()
	if(shell)
		return null
	for(var/obj/item/borg/upgrade/ion_shield/shield in upgrades)
		if(!QDELETED(shield) && shield.loc == src)
			return shield
	return null

/obj/item/borg/upgrade/rename
	name = "cyborg reclassification board"
	desc = "Используется для переименования киборга."
	icon_state = "cyborg_upgrade1"
	var/heldname = ""
	one_use = TRUE

/obj/item/borg/upgrade/rename/attack_self(mob/user)
	heldname = sanitize_name(stripped_input(user, "Enter new robot name", "Cyborg Reclassification", heldname, MAX_NAME_LEN))

/obj/item/borg/upgrade/rename/action(mob/living/silicon/robot/R)
	. = ..()
	if(.)
		var/oldname = R.real_name
		R.custom_name = heldname
		R.updatename()
		if(oldname == R.real_name)
			R.notify_ai(RENAME, oldname, R.real_name)

/obj/item/borg/upgrade/restart
	name = "cyborg emergency reboot module"
	desc = "Используется для принудительной перезагрузки отключённого, но отремонтированного киборга, возвращая его в онлайн."
	icon_state = "cyborg_upgrade1"
	one_use = TRUE

/obj/item/borg/upgrade/restart/action(mob/living/silicon/robot/R, user = usr)
	if(R.stat == DEAD && !R.can_be_medically_revived())
		to_chat(user, span_warning("Сознание киборга недоступно для перезапуска."))
		return FALSE
	if(R.health < 0)
		to_chat(user, "<span class='warning'>You have to repair the cyborg before using this module!</span>")
		return FALSE

	if(R.mind)
		R.mind.grab_ghost()
		playsound(loc, 'sound/voice/liveagain.ogg', 75, 1)

	R.revive(medical_revive = TRUE)

/obj/item/borg/upgrade/vtec
	name = "cyborg VTEC module"
	desc = "Используется для активации систем VTEC киборга, увеличивая его скорость."
	icon_state = "cyborg_upgrade2"
	require_module = 1
	var/obj/effect/proc_holder/silicon/cyborg/vtecControl/VC

/obj/item/borg/upgrade/vtec/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return
	return activate(R, user)

/obj/item/borg/upgrade/vtec/proc/activate(mob/living/silicon/robot/R, user = usr)
	if(!R.cansprint)
		to_chat(R, "<span class='notice'>A VTEC unit is already installed!</span>")
		to_chat(user, "<span class='notice'>There's no room for another VTEC unit!</span>")
		return FALSE

	//R.vtec = -2 // Gotta go fast.
	//Citadel change - makes vtecs give an ability rather than reducing the borg's speed instantly
	VC = new /obj/effect/proc_holder/silicon/cyborg/vtecControl
	R.AddAbility(VC)
	R.cansprint = 0
	R.disable_intentional_sprint_mode()
	var/datum/hud/robot/robohud = R.hud_used
	if(istype(robohud))
		robohud.assert_move_intent_ui()
	return TRUE

/obj/item/borg/upgrade/vtec/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		R.RemoveAbility(VC)
		R.disable_vtec()
		R.cansprint = 1
		var/datum/hud/robot/robohud = R.hud_used
		if(istype(robohud))
			robohud.assert_move_intent_ui()

/obj/item/borg/upgrade/disablercooler
	name = "cyborg rapid energy blaster cooling module"
	desc = "Используется для охлаждения установленного энергетического оружия, увеличивая потенциальный ток и, следовательно, скорость перезарядки."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_flags = BORG_MODULE_SECURITY

/obj/item/borg/upgrade/disablercooler/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		var/successflag
		for(var/obj/item/gun/energy/T in R.module.modules)
			if(T.charge_delay <= 2)
				successflag = successflag || 2
				continue
			T.charge_delay = max(2, T.charge_delay - 4)
			successflag = 1
		if(!successflag)
			to_chat(user, "<span class='notice'>There's no energy-based firearm in this unit!</span>")
			return FALSE
		if(successflag == 2)
			to_chat(R, "<span class='notice'>A cooling unit is already installed!</span>")
			to_chat(user, "<span class='notice'>There's no room for another cooling unit!</span>")
			return FALSE

/obj/item/borg/upgrade/disablercooler/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		var/restored_any = FALSE
		for(var/obj/item/gun/energy/T in R.module.modules)
			T.charge_delay = initial(T.charge_delay)
			restored_any = TRUE
		if(!restored_any)
			return FALSE

/obj/item/borg/upgrade/thrusters
	name = "ion thruster upgrade"
	desc = "Энергетическая система двигателей для киборгов."
	icon_state = "cyborg_upgrade3"

/obj/item/borg/upgrade/thrusters/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		if(R.ionpulse)
			to_chat(user, "<span class='notice'>This unit already has ion thrusters installed!</span>")
			return FALSE

		R.ionpulse = TRUE

/obj/item/borg/upgrade/thrusters/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		R.ionpulse = FALSE

/obj/item/borg/upgrade/ddrill
	name = "mining cyborg diamond drill"
	desc = "Алмазная дрель для замены стандартной дрели шахтёрского модуля."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/miner)
	module_flags = BORG_MODULE_MINER
	// Старая дрель
	var/obj/item/pickaxe/drill/cyborg/D
	// Старая лопата
	// Новая дрель
	var/obj/item/pickaxe/drill/cyborg/diamond/DD


/obj/item/borg/upgrade/ddrill/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for(DD in R.module.modules)
		if(DD)
			to_chat(user, "<span class='warning'>This unit is already equipped with a BSD module.</span>")
			return FALSE

	var/D_index = find_module_index(R, /obj/item/pickaxe/drill/cyborg)
	D = D_index ? R.module.modules[D_index] : null
	if(!D)
		return FALSE // No original instrument to replace.

	DD = new(R.module)
	R.module.basic_modules += DD
	R.module.add_module(DD, FALSE, TRUE)
	var/DD_index = R.module.modules.Find(DD)
	swap_module_entries(R, D_index, DD_index)
	R.module.remove_module(D, TRUE) // Замена произошла - избавляемся от старого инструмента

/obj/item/borg/upgrade/ddrill/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	var/DD_index = find_module_index(R, /obj/item/pickaxe/drill/cyborg/diamond)
	if(!DD_index)
		// Модуль уже сброшен (ResetModule) или инструмент вынули - менять нечего.
		DD = null
		return
	DD = R.module.modules[DD_index]

	D = new(R.module)
	R.module.basic_modules += D
	R.module.add_module(D, FALSE, TRUE)
	var/D_index = R.module.modules.Find(D)
	swap_module_entries(R, DD_index, D_index)
	if(DD)
		R.module.remove_module(DD, TRUE)

/obj/item/borg/upgrade/advcutter
	name = "mining cyborg advanced plasma cutter"
	desc = "Улучшение для плазменного резака шахтёрского киборга, приводящее его к продвинутой эксплуатации."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/miner)
	module_flags = BORG_MODULE_MINER

/obj/item/borg/upgrade/advcutter/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		for(var/obj/item/gun/energy/plasmacutter/cyborg/C in R.module)
			C.name = "advanced cyborg plasma cutter"
			C.desc = "Улучшенная версия плазменного резака киборга. Функциональность идентична стандартной ручной версии."
			C.icon_state = "adv_plasmacutter"
			for(var/obj/item/ammo_casing/energy/plasma/weak/L in C.ammo_type)
				L.projectile_type = /obj/item/projectile/plasma/adv

/obj/item/borg/upgrade/advcutter/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		for(var/obj/item/gun/energy/plasmacutter/cyborg/C in R.module)
			C.name = initial(name)
			C.desc = initial(desc)
			C.icon_state = initial(icon_state)
			for(var/obj/item/ammo_casing/energy/plasma/weak/L in C.ammo_type)
				L.projectile_type = initial(L.projectile_type)

/obj/item/borg/upgrade/premiumka
	name = "mining cyborg premium KA"
	desc = "Премиум-кинетический ускоритель для замены стандартного кинетического ускорителя шахтёрского модуля."
	icon_state = "cyborg_upgrade3"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/miner)
	module_flags = BORG_MODULE_MINER

/obj/item/borg/upgrade/premiumka/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	// Добавлем счёт кол-ва акселлераторов
	var/ka_quantity = 0
	var/obj/item/gun/energy/kinetic_accelerator/premiumka/cyborg/PKA
	for(PKA in R.module.modules)
		ka_quantity++
	if(ka_quantity == 2)
		to_chat(user, "<span class='warning'>This unit is already equipped with two kinetic accelerators.</span>")
		return FALSE

	for(var/obj/item/gun/energy/kinetic_accelerator/cyborg/KA in R.module)
		for(var/obj/item/borg/upgrade/modkit/M in KA.modkits)
			M.uninstall(KA)
		R.module.remove_module(KA, TRUE)

	PKA = new /obj/item/gun/energy/kinetic_accelerator/premiumka/cyborg(R.module) // var/ переместили выше как code cleaness
	R.module.basic_modules += PKA
	R.module.add_module(PKA, FALSE, TRUE)

// SANDSTORM EDIT START мы это модифицировали
/obj/item/borg/upgrade/premiumka/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/replaced_premium_ka = FALSE
	for(var/obj/item/gun/energy/kinetic_accelerator/premiumka/cyborg/PKA in R.module)
		replaced_premium_ka = TRUE
		for(var/obj/item/borg/upgrade/modkit/M in PKA.modkits)
			M.uninstall(PKA)
		R.module.remove_module(PKA, TRUE)
	if(!replaced_premium_ka)
		return // ResetModule already replaced this tool.

	var/obj/item/gun/energy/kinetic_accelerator/cyborg/KA = new (R.module)
	R.module.basic_modules += KA
	R.module.add_module(KA, FALSE, TRUE)
// SANDSTORM EDIT END

/obj/item/borg/upgrade/tboh
	name = "janitor cyborg trash bag of holding"
	desc = "Мусорный мешок размораживания для замены стандартного мусорного мешка уборочного киборга."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/butler)
	module_flags = BORG_MODULE_JANITOR
	// Старый мешок
	var/obj/item/storage/bag/trash/cyborg/oldbag
	// Новый мешок
	var/obj/item/storage/bag/trash/bluespace/cyborg/bsbag

/obj/item/borg/upgrade/tboh/action(mob/living/silicon/robot/R, user = src)
	. = ..()
	if(!.)
		return

	for(bsbag in R.module.modules)
		if(bsbag)
			to_chat(user, "<span class='warning'>This unit is already equipped with a bluespace trash bag module.</span>")
			return FALSE

	var/oldbag_index = find_module_index(R, /obj/item/storage/bag/trash/cyborg)
	oldbag = oldbag_index ? R.module.modules[oldbag_index] : null
	if(!oldbag)
		return FALSE // No original instrument to replace.

	bsbag = new(R.module)
	R.module.basic_modules += bsbag
	R.module.add_module(bsbag, FALSE, TRUE)
	var/bsbag_index = R.module.modules.Find(bsbag)
	swap_module_entries(R, oldbag_index, bsbag_index)
	R.module.remove_module(oldbag, TRUE) // Замена произошла - избавляемся от старого инструмента

/obj/item/borg/upgrade/tboh/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	var/bsbag_index = find_module_index(R, /obj/item/storage/bag/trash/bluespace/cyborg)
	if(!bsbag_index)
		// Модуль уже сброшен (ResetModule) или инструмент вынули - менять нечего.
		bsbag = null
		return
	bsbag = R.module.modules[bsbag_index]

	oldbag = new(R.module)
	R.module.basic_modules += oldbag
	R.module.add_module(oldbag, FALSE, TRUE)
	var/oldbag_index = R.module.modules.Find(oldbag)
	swap_module_entries(R, bsbag_index, oldbag_index)
	if(bsbag)
		R.module.remove_module(bsbag, TRUE)

/obj/item/borg/upgrade/amop
	name = "janitor cyborg advanced mop"
	desc = "Продвинутая швабра для замены стандартной швабры уборочного киборга."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/butler)
	module_flags = BORG_MODULE_JANITOR
	/// Старая швабра
	var/obj/item/mop/cyborg/oldmop
	/// Новая швабра
	var/obj/item/mop/advanced/cyborg/advmop

/obj/item/borg/upgrade/amop/action(mob/living/silicon/robot/R, user = src)
	. = ..()
	if(!.)
		return

	for (advmop in R.module)
		if(advmop)
			to_chat(user, "<span class='warning'>This unit is already equipped with an advanced mop module.</span>")
			return FALSE

	var/oldmop_index = find_module_index(R, /obj/item/mop/cyborg)
	oldmop = oldmop_index ? R.module.modules[oldmop_index] : null
	if(!oldmop)
		return FALSE // No original instrument to replace.

	advmop = new(R.module)
	R.module.basic_modules += advmop
	R.module.add_module(advmop, FALSE, TRUE)
	var/advmop_index = R.module.modules.Find(advmop)
	swap_module_entries(R, oldmop_index, advmop_index)
	R.module.remove_module(oldmop, TRUE) // Замена произошла - избавляемся от старой сварки

/obj/item/borg/upgrade/amop/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/advmop_index = find_module_index(R, /obj/item/mop/advanced/cyborg)
	if(!advmop_index)
		// Модуль уже сброшен (ResetModule) или инструмент вынули - менять нечего.
		advmop = null
		return
	advmop = R.module.modules[advmop_index]

	oldmop = new(R.module)
	R.module.basic_modules += oldmop
	R.module.add_module(oldmop, FALSE, TRUE)
	var/oldmop_index = R.module.modules.Find(oldmop)
	swap_module_entries(R, advmop_index, oldmop_index)
	if(advmop)
		R.module.remove_module(advmop, TRUE)

/obj/item/borg/upgrade/syndicate
	name = "illegal equipment module"
	desc = "Разблокирует скрытые, более смертоносные функции киборга."
	icon_state = "cyborg_upgrade3"
	require_module = 1

/obj/item/borg/upgrade/syndicate/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		if(R.emagged)
			return FALSE

		R.SetEmagged(1)

		return TRUE

/obj/item/borg/upgrade/syndicate/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		R.SetEmagged(FALSE)

/obj/item/borg/upgrade/lavaproof
	name = "mining cyborg lavaproof tracks"
	desc = "Комплект модернизации для установки специализированных систем охлаждения и изоляционных слоёв на гусеницы шахтёрского киборга, позволяя им выдерживать воздействие расплавленной породы."
	icon_state = "ash_plating"
	resistance_flags = LAVA_PROOF | FIRE_PROOF
	require_module = 1
	module_type = list(/obj/item/robot_module/miner)
	module_flags = BORG_MODULE_MINER

/obj/item/borg/upgrade/lavaproof/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		ADD_TRAIT(R, TRAIT_LAVA_IMMUNE, type)

/obj/item/borg/upgrade/lavaproof/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		REMOVE_TRAIT(R, TRAIT_LAVA_IMMUNE, type)

/obj/item/borg/upgrade/selfrepair
	name = "self-repair module"
	desc = "Этот модуль со временем будет ремонтировать киборга."
	icon_state = "cyborg_upgrade5"
	require_module = 1
	var/repair_amount = -1
	var/repair_tick = 1
	var/msg_cooldown = 0
	var/on = FALSE
	var/powercost = 10
	var/datum/action/toggle_action

/obj/item/borg/upgrade/selfrepair/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		var/obj/item/borg/upgrade/selfrepair/U = locate() in R
		if(U)
			to_chat(user, "<span class='warning'>This unit is already equipped with a self-repair module.</span>")
			return FALSE

		icon_state = "selfrepair_off"
		toggle_action = new /datum/action/item_action/toggle(src)
		toggle_action.Grant(R)

/obj/item/borg/upgrade/selfrepair/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		// toggle_action создаётся только в activate(), а сюда приходят и без него: перерезанный
		// провод Reset Module двигает апгрейд, сигнал перемещения зовёт remove_from_upgrades ->
		// deactivate(), и на пустом поле выходило "Cannot execute null.Remove()" (раунд 9834).
		if(toggle_action)
			toggle_action.Remove(R)
		QDEL_NULL(toggle_action)
		deactivate_sr()

/obj/item/borg/upgrade/selfrepair/ui_action_click()
	if(on)
		to_chat(toggle_action.owner, "<span class='notice'>You deactivate the self-repair module.</span>")
		deactivate_sr()
	else
		to_chat(toggle_action.owner, "<span class='notice'>You activate the self-repair module.</span>")
		activate_sr()

/obj/item/borg/upgrade/selfrepair/update_icon_state()
	if(toggle_action)
		icon_state = "selfrepair_[on ? "on" : "off"]"
	else
		icon_state = "cyborg_upgrade5"

/obj/item/borg/upgrade/selfrepair/proc/activate_sr()
	START_PROCESSING(SSobj, src)
	on = TRUE
	update_icon()

/obj/item/borg/upgrade/selfrepair/proc/deactivate_sr()
	STOP_PROCESSING(SSobj, src)
	on = FALSE
	update_icon()

/obj/item/borg/upgrade/selfrepair/process()
	if(!repair_tick)
		repair_tick = 1
		return

	var/mob/living/silicon/robot/cyborg = toggle_action.owner

	if(istype(cyborg) && (cyborg.stat != DEAD) && on)
		if(!cyborg.cell)
			to_chat(cyborg, "<span class='warning'>Self-repair module deactivated. Please, insert the power cell.</span>")
			deactivate_sr()
			return

		if(cyborg.cell.charge < powercost * 2)
			to_chat(cyborg, "<span class='warning'>Self-repair module deactivated. Please recharge.</span>")
			deactivate_sr()
			return

		if(cyborg.health < cyborg.maxHealth)
			if(cyborg.health < 0)
				repair_amount = -2.5
				powercost = 30
			else
				repair_amount = -1
				powercost = 10
			cyborg.adjustBruteLoss(repair_amount)
			cyborg.adjustFireLoss(repair_amount)
			cyborg.updatehealth()
			cyborg.cell.use(powercost)
		else
			cyborg.cell.use(5)
		repair_tick = 0

		if((world.time - 2000) > msg_cooldown )
			var/msgmode = "standby"
			if(cyborg.health < 0)
				msgmode = "critical"
			else if(cyborg.health < cyborg.maxHealth)
				msgmode = "normal"
			to_chat(cyborg, "<span class='notice'>Self-repair is active in <span class='boldnotice'>[msgmode]</span> mode.</span>")
			msg_cooldown = world.time
	else
		deactivate_sr()

/obj/item/borg/upgrade/hypospray
	name = "medical cyborg hypospray advanced synthesiser"
	desc = "Улучшение гипоспрея медицинского киборга, позволяющее \
		производить более продвинутые и сложные медицинские реагенты."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/medical,
		/obj/item/robot_module/syndicate_medical)
	var/list/additional_reagents = list()
	module_flags = BORG_MODULE_MEDICAL
	abstract_type = /obj/item/borg/upgrade/hypospray

/obj/item/borg/upgrade/hypospray/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
			if(H.accepts_reagent_upgrades)
				for(var/re in additional_reagents)
					H.add_reagent(re)

/obj/item/borg/upgrade/hypospray/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
			if(H.accepts_reagent_upgrades)
				for(var/re in additional_reagents)
					H.del_reagent(re)

/obj/item/borg/upgrade/hypospray/expanded
	name = "medical cyborg expanded hypospray"
	desc = "Улучшение гипоспрея медицинского модуля, позволяющее \
		лечить более широкий спектр состояний и проблем."
	additional_reagents = list(/datum/reagent/medicine/mannitol, /datum/reagent/medicine/oculine, /datum/reagent/medicine/inacusiate,
		/datum/reagent/medicine/mutadone, /datum/reagent/medicine/haloperidol)

/obj/item/borg/upgrade/hypospray/high_strength
	name = "medical cyborg high-strength hypospray"
	desc = "Улучшение гипоспрея медицинского модуля, содержащее \
		более сильные версии существующих химикатов."
	additional_reagents = list(/datum/reagent/medicine/oxandrolone, /datum/reagent/medicine/sal_acid,
								/datum/reagent/medicine/rezadone, /datum/reagent/medicine/pen_acid, /datum/reagent/medicine/prussian_blue)

/obj/item/borg/upgrade/piercing_hypospray
	name = "cyborg piercing hypospray"
	desc = "Улучшение гипоспрея киборга, позволяющее \
		пробивать броню и толстый материал."
	icon_state = "cyborg_upgrade3"
	module_type = list(/obj/item/robot_module/medical,
		/obj/item/robot_module/syndicate_medical)
	var/list/additional_reagents = list()
	module_flags = BORG_MODULE_MEDICAL

/obj/item/borg/upgrade/piercing_hypospray/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		var/found_hypo = FALSE
		for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
			H.bypass_protection = TRUE
			found_hypo = TRUE

		if(!found_hypo)
			return FALSE

/obj/item/borg/upgrade/piercing_hypospray/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
			H.bypass_protection = initial(H.bypass_protection)

/obj/item/borg/upgrade/defib/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		var/obj/item/shockpaddles/cyborg/S = locate() in R.module
		R.module.remove_module(S, TRUE)

/obj/item/borg/upgrade/processor
	name = "medical cyborg surgical processor"
	desc = "Улучшение медицинского модуля, устанавливающее процессор, \
		способный сканировать хирургические диски и выполнять \
		операции."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(/obj/item/robot_module/medical,
		/obj/item/robot_module/syndicate_medical)
	module_flags = BORG_MODULE_MEDICAL

/obj/item/borg/upgrade/processor/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		var/obj/item/surgical_processor/SP = new(R.module)
		R.module.basic_modules += SP
		R.module.add_module(SP, FALSE, TRUE)

/obj/item/borg/upgrade/processor/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		var/obj/item/surgical_processor/SP = locate() in R.module
		R.module.remove_module(SP, TRUE)

/obj/item/borg/upgrade/advhealth
	name = "advanced cyborg health scanner"
	desc = "Улучшение медицинских модулей, устанавливающее встроенный \
		продвинутый сканер здоровья для лучших показаний пациентов."
	icon_state = "cyborg_upgrade3"
	require_module = 1
	module_type = list(
		/obj/item/robot_module/medical,
		/obj/item/robot_module/syndicate_medical)
	module_flags = BORG_MODULE_MEDICAL
	// Старый сканер
	var/obj/item/healthanalyzer/cyborg/AHBasic
	// Новый сканер
	var/obj/item/healthanalyzer/advanced/cyborg/AHAdv

/obj/item/borg/upgrade/advhealth/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for(AHAdv in R.module.modules)
		if(AHAdv)
			to_chat(user, "<span class='warning'>This unit is already equipped with an advanced scanner module.</span>")
			return FALSE

	var/AHBasic_index = find_module_index(R, /obj/item/healthanalyzer/cyborg)
	AHBasic = AHBasic_index ? R.module.modules[AHBasic_index] : null
	if(!AHBasic)
		return FALSE // No original instrument to replace.

	AHAdv = new(R.module)
	R.module.basic_modules += AHAdv
	R.module.add_module(AHAdv, FALSE, TRUE)
	var/AHAdv_index = R.module.modules.Find(AHAdv)
	swap_module_entries(R, AHBasic_index, AHAdv_index)
	R.module.remove_module(AHBasic, TRUE) // Замена произошла - избавляемся от старого РПД

/obj/item/borg/upgrade/advhealth/deactivate(mob/living/silicon/robot/R, user = usr) // BLUEMOON FIX you forgot to change processor to advhealth
	. = ..()
	if(!.)
		return

	var/AHAdv_index = find_module_index(R, /obj/item/healthanalyzer/advanced/cyborg)
	if(!AHAdv_index)
		// Модуль уже сброшен (ResetModule) или инструмент вынули - менять нечего.
		AHAdv = null
		return
	AHAdv = R.module.modules[AHAdv_index]

	AHBasic = new(R.module)
	R.module.basic_modules += AHBasic
	R.module.add_module(AHBasic, FALSE, TRUE)
	var/AHBasic_index = R.module.modules.Find(AHBasic)
	swap_module_entries(R, AHAdv_index, AHBasic_index)
	if(AHAdv)
		R.module.remove_module(AHAdv, TRUE)

/obj/item/borg/upgrade/ai
	name = "B.O.R.I.S. module"
	desc = "Блюспейс-оптимизированная синхронизация удалённого интеллекта. Устройство-приёмник, которое заменяет ММИ в эндоскелетах киборгов, создавая роботизированную оболочку, управляемую ИИ."
	icon_state = "boris"

/obj/item/borg/upgrade/ai/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		if(R.shell)
			to_chat(user, "<span class='warning'>This unit is already an AI shell!</span>")
			return FALSE
		if(R.key) //You cannot replace a player unless the key is completely removed.
			to_chat(user, "<span class='warning'>Intelligence patterns detected in this [R.braintype]. Aborting.</span>")
			return FALSE

		R.make_shell(src)

/obj/item/borg/upgrade/ai/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		if(R.shell)
			R.undeploy()
			R.notify_ai(AI_SHELL)

/obj/item/borg/upgrade/expand
	name = "borg expander"
	desc = "Изменитель размера киборга, делает киборга огромным."
	icon_state = "cyborg_upgrade3"

/* moved to modular_sand
/obj/item/borg/upgrade/expand/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)

		if(R.hasExpanded)
			to_chat(usr, "<span class='notice'>This unit already has an expand module installed!</span>")
			return FALSE

		R.mob_transforming = TRUE
		var/prev_locked_down = R.locked_down
		R.SetLockdown(1)
		R.anchored = TRUE
		var/datum/effect_system/smoke_spread/smoke = new
		smoke.set_up(1, R.loc)
		smoke.start()
		sleep(2)
		for(var/i in 1 to 4)
			playsound(R, pick('sound/items/drill3.ogg', 'sound/items/jaws_cut.ogg', 'sound/items/jaws_pry.ogg', 'sound/items/welder.ogg', 'sound/items/ratchet.ogg'), 80, 1, -1)
			sleep(12)
		if(!prev_locked_down)
			R.SetLockdown(0)
		R.anchored = FALSE
		R.mob_transforming = FALSE
		R.resize = 2
		R.hasExpanded = TRUE
		R.update_transform()

/obj/item/borg/upgrade/expand/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (. && R.hasExpanded)
		R.resize = 0.5
		R.hasExpanded = FALSE
		R.update_transform()
*/

/obj/item/borg/upgrade/rped
	name = "engineering cyborg BSRPED"
	desc = "Устройство быстрой замены деталей для инженерного киборга."
	icon = 'icons/obj/storage.dmi'
	icon_state = "borg_BS_RPED"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering, /obj/item/robot_module/saboteur)
	module_flags = BORG_MODULE_ENGINEERING
	// Старый РПЕД
	var/obj/item/storage/part_replacer/cyborg/RPED
	// Новый БСРПЕД
	var/obj/item/storage/part_replacer/bluespace/cyborg/BSRPED

/obj/item/borg/upgrade/rped/Destroy()
	RPED = null
	BSRPED = null
	return ..()

/obj/item/borg/upgrade/rped/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for(BSRPED in R.module.modules)
		if(BSRPED)
			to_chat(user, "<span class='warning'>This unit is already equipped with a BSRPED module.</span>")
			return FALSE

	var/RPED_index = find_module_index(R, /obj/item/storage/part_replacer/cyborg)
	RPED = RPED_index ? R.module.modules[RPED_index] : null
	if(!RPED)
		return FALSE // No original instrument to replace.

	BSRPED = new(R.module)
	R.module.basic_modules += BSRPED
	R.module.add_module(BSRPED, FALSE, TRUE)
	var/BSRPED_index = R.module.modules.Find(BSRPED)
	swap_module_entries(R, RPED_index, BSRPED_index)
	SEND_SIGNAL(RPED, COMSIG_TRY_STORAGE_QUICK_EMPTY)
	R.module.remove_module(RPED, TRUE) // Замена произошла - избавляемся от старого инструмента
	RPED = null

/obj/item/borg/upgrade/rped/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	var/BSRPED_index = find_module_index(R, /obj/item/storage/part_replacer/bluespace/cyborg)
	if(!BSRPED_index)
		// Модуль уже сброшен (ResetModule) или инструмент вынули - менять нечего.
		BSRPED = null
		return
	BSRPED = R.module.modules[BSRPED_index]

	RPED = new(R.module)
	R.module.basic_modules += RPED
	R.module.add_module(RPED, FALSE, TRUE)
	var/RPED_index = R.module.modules.Find(RPED)
	swap_module_entries(R, BSRPED_index, RPED_index)
	SEND_SIGNAL(BSRPED, COMSIG_TRY_STORAGE_QUICK_EMPTY)
	R.module.remove_module(BSRPED, TRUE)
	BSRPED = null


/obj/item/borg/upgrade/pinpointer
	name = "medical cyborg crew pinpointer"
	desc = "Модуль указателя членов экипажа для медицинского киборга."
	icon = 'icons/obj/device.dmi'
	icon_state = "pinpointer_crew"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/medical, /obj/item/robot_module/syndicate_medical)
	module_flags = BORG_MODULE_MEDICAL

/obj/item/borg/upgrade/pinpointer/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)

		var/obj/item/pinpointer/crew/PP = locate() in R
		if(PP)
			to_chat(user, "<span class='warning'>This unit is already equipped with a pinpointer module.</span>")
			return FALSE

		PP = new(R.module)
		R.module.basic_modules += PP
		R.module.add_module(PP, FALSE, TRUE)

/obj/item/borg/upgrade/pinpointer/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (.)
		var/obj/item/pinpointer/crew/PP = locate() in R.module
		if (PP)
			R.module.remove_module(PP, TRUE)

/obj/item/borg/upgrade/transform
	name = "borg module picker (Standard)"
	desc = "Позволяет превратить киборга в стандартного киборга."
	icon_state = "cyborg_upgrade3"
	var/obj/item/robot_module/new_module = /obj/item/robot_module/standard

/obj/item/borg/upgrade/transform/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(.)
		R.module.transform_to(new_module)

/obj/item/borg/upgrade/transform/clown
	name = "borg module picker (Clown)"
	desc = "Позволяет превратить киборга в клоуна, хонк."
	icon_state = "cyborg_upgrade3"
	new_module = /obj/item/robot_module/clown

// Citadel's Vtech Controller
/obj/effect/proc_holder/silicon/cyborg/vtecControl
	name = "vTec Control"
	desc = "Позволяет контролировать ускорение vTec: переключение крейсерского режима скорости."
	action_icon = 'icons/mob/actions.dmi'
	action_icon_state = "Chevron_State_0"

	var/currentState = 0


/obj/effect/proc_holder/silicon/cyborg/vtecControl/Trigger(mob/living/silicon/robot/user)
	if(!(user.cell?.charge) || (!user.cell?.self_recharge && (user.cell?.charge <= user.cell?.maxcharge * VTEC_LOWCHARGE_DISABLE)) || (user.cell?.self_recharge && (user.cell?.charge <= max(user.cell?.chargerate, user.cell?.maxcharge * VTEC_LOWCHARGE_DISABLE))))
		to_chat(user, span_warning("ВНИМАНИЕ: критический низкий заряд батареи! Системы VTEC временно отключены."))
		applyState(user, 0)
		return TRUE

	var/newState = (currentState + 1) % 2
	applyState(user, newState)

	return TRUE

/// Применяет состояние VTEC целиком: переменные робота и иконка кнопки способности
/obj/effect/proc_holder/silicon/cyborg/vtecControl/proc/applyState(mob/living/silicon/robot/user, newstate)
	if(!user)
		return

	currentState = newstate
	var/state_icon = 0
	switch(newstate)
		if (0) // Базовый режим скорости
			user.disable_vtec()
		if (1) // Режим ускорения
			user.activate_vtec_cruise()
			state_icon = 2

	action.button_icon_state = "Chevron_State_[state_icon]"
	action.UpdateButtons()

/obj/item/borg/upgrade/jukebox
	name = "cyborg jukebox module"
	desc = "Плата расширения, позволяющая киборгу транслировать музыку из внутренней библиотеки."
	icon_state = "cyborg_upgrade3"
	require_module = TRUE

/obj/item/borg/upgrade/jukebox/action(mob/living/silicon/robot/R)
	. = ..()
	if(.)
		var/obj/item/device/robot_jukebox/JB = new(R.module)
		R.module.basic_modules += JB
		R.module.add_module(JB, FALSE, TRUE)
		START_PROCESSING(SSobj, JB)

/obj/item/borg/upgrade/jukebox/deactivate(mob/living/silicon/robot/R)
	. = ..()
	if(.)
		var/obj/item/device/robot_jukebox/JB = locate() in R.module
		if(JB)
			STOP_PROCESSING(SSobj, JB)
			R.module.remove_module(JB, TRUE)
			qdel(JB)
