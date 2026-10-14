/obj/item/circuitboard/machine/cryptominer
	/// The fine cooldown follows this board when its machine is rebuilt.
	var/sol_inspection_last_fined

/obj/item/circuitboard/machine/bluespace_miner
	/// The fine cooldown follows this board when its machine is rebuilt.
	var/sol_inspection_last_fined

/obj/vehicle/sealed/mecha/combat/durand
	var/sol_inspection_last_fined

/obj/vehicle/sealed/mecha/combat/gygax
	var/sol_inspection_last_fined

/obj/item/sol_inspection_scanner
	name = "сканер инспекции"
	desc = "Служебный сканер для выявления незаконной добывающей техники и боевых экзокостюмов."
	icon = 'icons/obj/device.dmi'
	icon_state = "survey-adv"
	item_state = "electronic"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL

	var/const/fine_cooldown = 20 MINUTES

/obj/item/sol_inspection_scanner/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(!can_scan(user, target))
		return TRUE

	var/reason = violation_reason(target)
	if(!reason)
		balloon_alert(user, "нарушений не найдено")
		return TRUE

	if(is_on_cooldown(target))
		balloon_alert(user, "цель уже оштрафована")
		return TRUE

	to_chat(user, span_notice("Вы начинаете инспекцию [target]."))
	if(!do_after(user, 10 SECONDS, target))
		return TRUE

	if(!can_scan(user, target) || is_on_cooldown(target))
		return TRUE

	reason = violation_reason(target)
	if(!reason)
		balloon_alert(user, "нарушение устранено")
		return TRUE

	var/datum/antagonist/sol_inspector/inspector = user.mind?.has_antag_datum(/datum/antagonist/sol_inspector)
	if(!inspector?.inspection_team)
		return TRUE

	if(handle_inspector_sabotage(target, inspector.inspection_team))
		return TRUE

	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/fine_amount = get_fine_amount(target)
	if(!cargo?.assess_sol_inspection_fine(fine_amount, inspector.inspection_team.account, reason))
		to_chat(user, span_warning("Не удалось взыскать штраф с бюджета Карго."))
		return TRUE

	set_last_fined(target)
	print_receipt(user, target, reason, fine_amount)
	inspector.inspection_team.report_violation("Взыскан штраф [fine_amount] кредитов за [reason]. Объект: [target] в [get_area(target)].")
	to_chat(user, span_notice("Инспекция завершена. Штраф взыскан."))
	return TRUE

/obj/item/sol_inspection_scanner/proc/can_scan(mob/living/user, atom/target)
	if(QDELETED(user) || QDELETED(target) || !user.Adjacent(target) || !sol_inspection_allowed_level(target.z))
		return FALSE
	if(user.get_active_held_item() != src)
		return FALSE
	var/datum/antagonist/sol_inspector/inspector = user.mind?.has_antag_datum(/datum/antagonist/sol_inspector)
	return inspector?.inspection_team && !inspector.suspended && !inspector.inspection_team.returned_home

/obj/item/sol_inspection_scanner/proc/get_fine_amount(atom/target)
	return istype(target, /obj/vehicle/sealed/mecha/combat/durand) ? 50000 : 25000

/obj/item/sol_inspection_scanner/proc/violation_reason(atom/target)
	if(istype(target, /obj/machinery/mineral/bluespace_miner) || istype(target, /obj/machinery/cryptominer))
		return "незаконная добывающая установка"

	if(istype(target, /obj/vehicle/sealed/mecha/combat/durand))
		if(!istype(get_area(target), /area/ai_monitored/security/armory) && GLOB.security_level < SEC_LEVEL_RED)
			return "экзокостюм Durand вне оружейной до кода Красный"

	if(istype(target, /obj/vehicle/sealed/mecha/combat/gygax))
		if(!istype(get_area(target), /area/ai_monitored/security/armory) && GLOB.security_level < SEC_LEVEL_AMBER)
			return "экзокостюм Gygax вне оружейной до кода Янтарный"

/obj/item/sol_inspection_scanner/proc/is_on_cooldown(atom/target)
	var/last_fined = get_last_fined(target)
	return !isnull(last_fined) && world.time < last_fined + fine_cooldown

/obj/item/sol_inspection_scanner/proc/get_last_fined(atom/target)
	if(istype(target, /obj/machinery/mineral/bluespace_miner))
		var/obj/machinery/mineral/bluespace_miner/bluespace_miner = target
		var/obj/item/circuitboard/machine/bluespace_miner/board = bluespace_miner.circuit
		return board?.sol_inspection_last_fined
	if(istype(target, /obj/machinery/cryptominer))
		var/obj/machinery/cryptominer/crypto_miner = target
		var/obj/item/circuitboard/machine/cryptominer/board = crypto_miner.circuit
		return board?.sol_inspection_last_fined
	if(istype(target, /obj/vehicle/sealed/mecha/combat/durand))
		var/obj/vehicle/sealed/mecha/combat/durand/durand = target
		return durand.sol_inspection_last_fined
	if(istype(target, /obj/vehicle/sealed/mecha/combat/gygax))
		var/obj/vehicle/sealed/mecha/combat/gygax/gygax = target
		return gygax.sol_inspection_last_fined

/obj/item/sol_inspection_scanner/proc/set_last_fined(atom/target)
	if(istype(target, /obj/machinery/mineral/bluespace_miner))
		var/obj/machinery/mineral/bluespace_miner/bluespace_miner = target
		var/obj/item/circuitboard/machine/bluespace_miner/board = bluespace_miner.circuit
		if(board)
			board.sol_inspection_last_fined = world.time
		return
	if(istype(target, /obj/machinery/cryptominer))
		var/obj/machinery/cryptominer/crypto_miner = target
		var/obj/item/circuitboard/machine/cryptominer/board = crypto_miner.circuit
		if(board)
			board.sol_inspection_last_fined = world.time
		return
	if(istype(target, /obj/vehicle/sealed/mecha/combat/durand))
		var/obj/vehicle/sealed/mecha/combat/durand/durand = target
		durand.sol_inspection_last_fined = world.time
		return
	if(istype(target, /obj/vehicle/sealed/mecha/combat/gygax))
		var/obj/vehicle/sealed/mecha/combat/gygax/gygax = target
		gygax.sol_inspection_last_fined = world.time

/obj/item/sol_inspection_scanner/proc/handle_inspector_sabotage(atom/target, datum/team/sol_inspection/inspection_team)
	if(!target.fingerprintslast)
		return FALSE
	for(var/datum/team/sol_inspection/team as anything in GLOB.antagonist_teams)
		if(!istype(team))
			continue
		for(var/datum/mind/member as anything in team.members)
			if(ckey(member.key) != target.fingerprintslast)
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
"})
	receipt.update_appearance()
	user.put_in_hands(receipt)
