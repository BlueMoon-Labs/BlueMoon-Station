#define SOL_INSPECTION_SCAN_DURATION (10 SECONDS)
#define SOL_INSPECTION_STANDARD_FINE 25000
#define SOL_INSPECTION_DURAND_FINE 50000
#define SOL_INSPECTION_CONFISCATION_SPARKS 5

/obj/item/circuitboard/machine/cryptominer
	/// The ckey of the person who most recently assembled this machine.
	var/sol_inspection_builder_ckey

/obj/item/circuitboard/machine/bluespace_miner
	/// The ckey of the person who most recently assembled this machine.
	var/sol_inspection_builder_ckey

/obj/vehicle/sealed/mecha/combat/durand
	var/sol_inspection_builder_ckey

/obj/vehicle/sealed/mecha/combat/gygax
	var/sol_inspection_builder_ckey

/proc/record_sol_inspection_builder(atom/target, mob/living/builder)
	if(!builder?.key)
		return
	var/builder_ckey = ckey(builder.key)
	if(istype(target, /obj/machinery/mineral/bluespace_miner))
		var/obj/machinery/mineral/bluespace_miner/bluespace_miner = target
		var/obj/item/circuitboard/machine/bluespace_miner/board = bluespace_miner.circuit
		if(board)
			board.sol_inspection_builder_ckey = builder_ckey
		return
	if(istype(target, /obj/machinery/cryptominer))
		var/obj/machinery/cryptominer/crypto_miner = target
		var/obj/item/circuitboard/machine/cryptominer/board = crypto_miner.circuit
		if(board)
			board.sol_inspection_builder_ckey = builder_ckey
		return
	if(istype(target, /obj/vehicle/sealed/mecha/combat/durand))
		var/obj/vehicle/sealed/mecha/combat/durand/durand = target
		durand.sol_inspection_builder_ckey = builder_ckey
		return
	if(istype(target, /obj/vehicle/sealed/mecha/combat/gygax))
		var/obj/vehicle/sealed/mecha/combat/gygax/gygax = target
		gygax.sol_inspection_builder_ckey = builder_ckey

/obj/item/sol_inspection_scanner
	name = "SOL Ccanner"
	desc = "Служебный сканер для выявления и изъятия незаконной добывающей техники и боевых экзокостюмов."
	icon = 'icons/obj/device.dmi'
	icon_state = "survey-adv"
	item_state = "electronic"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL

/obj/item/sol_inspection_scanner/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(!can_scan(user, target))
		return TRUE

	var/reason = violation_reason(target)
	if(!reason)
		balloon_alert(user, "нарушений не найдено")
		return TRUE

	to_chat(user, span_notice("Вы начинаете инспекцию [target]."))
	if(!do_after(user, SOL_INSPECTION_SCAN_DURATION, target))
		return TRUE

	if(!can_scan(user, target))
		return TRUE

	reason = violation_reason(target)
	if(!reason)
		balloon_alert(user, "нарушение устранено")
		return TRUE

	var/datum/antagonist/sol_inspector/inspector = user.mind?.has_antag_datum(/datum/antagonist/sol_inspector)
	if(!inspector?.inspection_team)
		return TRUE

	if(handle_inspector_sabotage(target, inspector.inspection_team))
		confiscate_target(target)
		return TRUE

	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/fine_amount = get_fine_amount(target)
	if(!cargo?.assess_sol_inspection_fine(fine_amount, inspector.inspection_team.account, reason))
		to_chat(user, span_warning("Не удалось взыскать штраф с бюджета Карго."))
		return TRUE

	print_receipt(user, target, reason, fine_amount)
	inspector.inspection_team.report_violation("Взыскан штраф [fine_amount] кредитов за [reason]. Объект: [target] в [get_area(target)]. Техника изъята.")
	confiscate_target(target)
	to_chat(user, span_notice("Инспекция завершена. Штраф взыскан, техника изъята."))
	return TRUE

/// Leave the effect on the turf, and evacuate pilots before deleting the seized equipment.
/obj/item/sol_inspection_scanner/proc/confiscate_target(atom/target)
	if(QDELETED(target))
		return
	var/turf/location = get_turf(target)
	if(istype(target, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/mech = target
		for(var/mob/living/pilot as anything in mech.occupants?.Copy())
			if(isAI(pilot))
				var/mob/living/silicon/ai/ai = pilot
				ai.controlled_equipment = null
				ai.remote_control = null
				ai.mobility_flags = NONE
				// A card-uploaded AI has no return core. Preserve its body on the seizure turf.
				if(!ai.linked_core || QDELETED(ai.linked_core))
					ai.linked_core = null
					ai.eyeobj?.UnregisterSignal(mech, COMSIG_MOVABLE_MOVED)
					ai.eyeobj?.forceMove(location)
					mech.remove_occupant(ai)
					ai.forceMove(location)
					ai.reset_perspective()
					continue
			if(istype(pilot, /mob/living/simple_animal/hostile/syndicate/mecha_pilot))
				mech.aimob_exit_mech(pilot)
				continue
			mech.mob_exit(pilot, silent = TRUE)
			if(isbrain(pilot))
				var/mob/living/brain/brain = pilot
				// The generic vehicle exit moves the brain again after the MMI is ejected.
				if(brain.container)
					brain.forceMove(brain.container)
				brain.remote_control = null
				brain.update_mobility()
	if(location)
		target.visible_message(span_notice("[target] исчезает во вспышке искр: техника изъята инспекцией Солнечной Федерации."))
		do_fake_sparks(SOL_INSPECTION_CONFISCATION_SPARKS, FALSE, location)
	qdel(target)

/obj/item/sol_inspection_scanner/proc/can_scan(mob/living/user, atom/target)
	if(QDELETED(user) || QDELETED(target) || !user.Adjacent(target) || !sol_inspection_allowed_level(target.z))
		return FALSE
	if(user.get_active_held_item() != src)
		return FALSE
	var/datum/antagonist/sol_inspector/inspector = user.mind?.has_antag_datum(/datum/antagonist/sol_inspector)
	return inspector?.inspection_team && !inspector.suspended && !inspector.inspection_team.returned_home

/obj/item/sol_inspection_scanner/proc/get_fine_amount(atom/target)
	return istype(target, /obj/vehicle/sealed/mecha/combat/durand) ? SOL_INSPECTION_DURAND_FINE : SOL_INSPECTION_STANDARD_FINE

/obj/item/sol_inspection_scanner/proc/violation_reason(atom/target)
	if(istype(target, /obj/machinery/mineral/bluespace_miner) || istype(target, /obj/machinery/cryptominer))
		return "незаконная добывающая установка"

	if(istype(target, /obj/vehicle/sealed/mecha/combat/durand))
		if(!istype(get_area(target), /area/ai_monitored/security/armory) && GLOB.security_level < SEC_LEVEL_RED)
			return "экзокостюм Durand вне оружейной до кода Красный"

	if(istype(target, /obj/vehicle/sealed/mecha/combat/gygax))
		if(!istype(get_area(target), /area/ai_monitored/security/armory) && GLOB.security_level < SEC_LEVEL_AMBER)
			return "экзокостюм Gygax вне оружейной до кода Янтарный"

/obj/item/sol_inspection_scanner/proc/get_builder_ckey(atom/target)
	if(istype(target, /obj/machinery/mineral/bluespace_miner))
		var/obj/machinery/mineral/bluespace_miner/bluespace_miner = target
		var/obj/item/circuitboard/machine/bluespace_miner/board = bluespace_miner.circuit
		return board?.sol_inspection_builder_ckey
	if(istype(target, /obj/machinery/cryptominer))
		var/obj/machinery/cryptominer/crypto_miner = target
		var/obj/item/circuitboard/machine/cryptominer/board = crypto_miner.circuit
		return board?.sol_inspection_builder_ckey
	if(istype(target, /obj/vehicle/sealed/mecha/combat/durand))
		var/obj/vehicle/sealed/mecha/combat/durand/durand = target
		return durand.sol_inspection_builder_ckey
	if(istype(target, /obj/vehicle/sealed/mecha/combat/gygax))
		var/obj/vehicle/sealed/mecha/combat/gygax/gygax = target
		return gygax.sol_inspection_builder_ckey

/obj/item/sol_inspection_scanner/proc/handle_inspector_sabotage(atom/target, datum/team/sol_inspection/inspection_team)
	var/builder_ckey = get_builder_ckey(target)
	if(!builder_ckey)
		return FALSE
	for(var/datum/team/sol_inspection/team as anything in GLOB.antagonist_teams)
		if(!istype(team))
			continue
		for(var/datum/mind/member as anything in team.members)
			if(ckey(member.key) != builder_ckey)
				continue
			var/datum/antagonist/sol_inspector/actor_inspector = member.has_antag_datum(/datum/antagonist/sol_inspector)
			if(!actor_inspector)
				continue
			if(!actor_inspector.suspended)
				actor_inspector.suspended = TRUE
				var/actor_name = member.current?.real_name || member.name
				GLOB.data_core.issue_permanent_arrest(member, "Грандиозный Саботаж", "Создание подставного нарушения для взыскания штрафа и саботаж репутации Солнечного Государства. Требование Транс-Солнечной Федерации: арест и заключение в пермабриг. Объект: [target.name].", "Транс-Солнечная Федерация")
				priority_announce("Выявлено тяжёлое нарушение со стороны сотрудника Всеобщего Бюро Контроля [actor_name]: создание подставного нарушения для взыскания штрафа. Требуем арестовать сотрудника и заключить в пермабриг по обвинению в «Грандиозном Саботаже» репутации Солнечного Государства. Его полномочия на сканирование приостановлены. Подставной штраф отклонён.", "Транс-Солнечная Федерация")
				inspection_team.report_violation("Подставной штраф за [target] отклонён. Полномочия [actor_name] на сканирование приостановлены; требуется арест.")
			return TRUE
	return FALSE

/obj/item/sol_inspection_scanner/proc/print_receipt(mob/living/user, atom/target, reason, fine_amount)
	var/obj/item/paper/receipt = new(get_turf(src))
	var/area/inspection_area = get_area(target)
	receipt.name = "квитанция Всеобщего Бюро Контроля"
	receipt.add_raw_text({"
<h2 style='text-align:center;'>ТРАНС-СОЛНЕЧНАЯ ФЕДЕРАЦИЯ</h2>
<h3 style='text-align:center;'>КВИТАНЦИЯ ОБ ИНСПЕКЦИОННОМ ШТРАФЕ</h3>
<hr>
<p><b>Сумма:</b> [fine_amount] кредитов</p>
<p><b>Причина:</b> [reason]</p>
<p><b>Объект:</b> [html_encode(target.name)]</p>
<p><b>Место:</b> [html_encode(inspection_area.name)]</p>
<p><b>Время:</b> [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]</p>
<p><b>Инспектор:</b> [html_encode(user.real_name)]</p>
<p><b>Мера:</b> изъятие незаконной техники.</p>
"})
	receipt.update_appearance()
	user.put_in_hands(receipt)

#undef SOL_INSPECTION_SCAN_DURATION
#undef SOL_INSPECTION_STANDARD_FINE
#undef SOL_INSPECTION_DURAND_FINE
#undef SOL_INSPECTION_CONFISCATION_SPARKS
