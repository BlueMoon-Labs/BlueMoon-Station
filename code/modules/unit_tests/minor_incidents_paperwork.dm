/// Цели подставляются напрямую: резерв теста не станционный z. Без typepath в каталог директора не попадают.
/datum/round_event_control/paperwork/inventory_audit/test_targets
	typepath = null
	var/turf/test_drop
	var/list/test_hideouts = list()

/datum/round_event_control/paperwork/inventory_audit/test_targets/find_delivery_turf(list/area_types)
	return test_drop

/datum/round_event_control/paperwork/inventory_audit/test_targets/find_hideouts(count)
	return test_hideouts.Copy(1, min(count, length(test_hideouts)) + 1)

/datum/round_event_control/paperwork/intercepted_contraband/test_targets
	typepath = null
	var/turf/test_drop
	var/list/test_hideouts = list()

/datum/round_event_control/paperwork/intercepted_contraband/test_targets/find_delivery_turf(list/area_types)
	return test_drop

/datum/round_event_control/paperwork/intercepted_contraband/test_targets/find_hideouts(count)
	return test_hideouts.Copy(1, min(count, length(test_hideouts)) + 1)

/datum/round_event_control/paperwork/id_card_recall/test_targets
	typepath = null
	var/turf/test_drop
	var/list/test_crew = list()

/datum/round_event_control/paperwork/id_card_recall/test_targets/find_terminal_turf()
	return test_drop

/datum/round_event_control/paperwork/id_card_recall/test_targets/get_recall_candidates()
	return test_crew.Copy()

/datum/round_event_control/paperwork/centcom_questionnaire/test_targets
	typepath = null
	var/obj/machinery/fax/test_fax

/datum/round_event_control/paperwork/centcom_questionnaire/test_targets/find_command_fax()
	return test_fax

/datum/round_event/paperwork/inventory_audit/test_delivery
	audit_item_pool = list(/obj/item/stamp/denied, /obj/item/flashlight)

/datum/round_event/paperwork/inventory_audit/test_delivery/deliver(turf/target, list/atom/movable/cargo)
	for(var/atom/movable/thing as anything in cargo)
		thing.forceMove(target)

/datum/round_event/paperwork/intercepted_contraband/test_delivery/deliver(turf/target, list/atom/movable/cargo)
	for(var/atom/movable/thing as anything in cargo)
		thing.forceMove(target)

/datum/round_event/paperwork/id_card_recall/test_delivery/deliver(turf/target, list/atom/movable/cargo)
	for(var/atom/movable/thing as anything in cargo)
		thing.forceMove(target)

/// Ответные факсы складываются в список вместо отправки по таймеру.
/datum/centcom_questionnaire/test_capture
	var/list/sent = list()

/datum/centcom_questionnaire/test_capture/send_fax(obj/item/paper/letter)
	sent += letter

/datum/centcom_questionnaire/test_capture/deliver_fax(obj/item/paper/letter)
	sent += letter

/datum/centcom_questionnaire/test_capture/Destroy()
	QDEL_LIST(sent)
	return ..()

/datum/unit_test/minor_incidents_paperwork

/datum/unit_test/minor_incidents_paperwork/Run()
	check_preflights()
	check_hideout_description()
	check_inventory_audit()
	check_questionnaire()
	check_fax_integration()
	check_card_recall()
	check_contraband()
	check_sprites()

/datum/unit_test/minor_incidents_paperwork/proc/make_event(event_path)
	var/datum/round_event/event = allocate(event_path, FALSE)
	SSdirector.running -= event
	return event

/datum/unit_test/minor_incidents_paperwork/proc/make_crew(crew_name, turf/location)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, location)
	crew.real_name = crew_name
	crew.name = crew_name
	crew.mind_initialize()
	crew.mind.assigned_role = "Assistant"
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = crew_name
	var/datum/bank_account/remote/account = new(crew_name)
	allocated += account
	card.registered_account = account
	crew.equip_to_slot(card, ITEM_SLOT_ID)
	return crew

/datum/unit_test/minor_incidents_paperwork/proc/corner_turf()
	return locate(run_loc_floor_bottom_left.x - 1, run_loc_floor_bottom_left.y - 1, run_loc_floor_bottom_left.z)

/datum/unit_test/minor_incidents_paperwork/proc/examine_text(atom/target, mob/user)
	return jointext(target.examine(user), " ")

/datum/unit_test/minor_incidents_paperwork/proc/paper_with(turf/location, text)
	for(var/obj/item/paper/report in location)
		allocated |= report
		if(findtext(report.get_raw_text(), text))
			return report
	return null

/datum/unit_test/minor_incidents_paperwork/proc/carried_cash(mob/living/carrier)
	. = 0
	for(var/obj/item/stack/spacecash/bill in carrier.GetAllContents())
		. += bill.get_item_credit_value()
	for(var/obj/item/holochip/chip in carrier.GetAllContents())
		. += chip.get_item_credit_value()

/datum/unit_test/minor_incidents_paperwork/proc/has_overlay(atom/target, state)
	for(var/mutable_appearance/overlay in target.update_overlays())
		if(overlay.icon_state == state)
			return TRUE
	return FALSE

/datum/unit_test/minor_incidents_paperwork/proc/check_preflights()
	var/datum/round_event_control/paperwork/inventory_audit/test_targets/audit = allocate(/datum/round_event_control/paperwork/inventory_audit/test_targets)
	TEST_ASSERT(!audit.director_preflight(), "Аудит без места для ящика и тайников не должен тратить бюджет директора")
	audit.test_drop = run_loc_floor_top_right
	TEST_ASSERT(!audit.director_preflight(), "Аудит без укромных мест в техтоннелях не запускается")
	audit.test_hideouts = list(corner_turf())
	TEST_ASSERT(audit.director_preflight(), "Аудит с ящиком и тайником готов к запуску")
	TEST_ASSERT_EQUAL(audit.bin_areas[1], /area/cargo/lobby, "Ящик возврата первым делом садится в общедоступную приёмную карго")
	TEST_ASSERT(!(/area/command/heads_quarters/hop in audit.bin_areas), "Ящик возврата не садится в запертый кабинет HoP")

	var/datum/round_event_control/paperwork/intercepted_contraband/test_targets/contraband = allocate(/datum/round_event_control/paperwork/intercepted_contraband/test_targets)
	contraband.test_hideouts = list(corner_turf())
	TEST_ASSERT(!contraband.director_preflight(), "Посылке нужно место в грузовом отсеке")
	contraband.test_drop = run_loc_floor_top_right
	TEST_ASSERT(contraband.director_preflight(), "Контрабанда с местом посадки и тайником готова к запуску")

	var/datum/round_event_control/paperwork/id_card_recall/test_targets/recall = allocate(/datum/round_event_control/paperwork/id_card_recall/test_targets)
	recall.test_drop = run_loc_floor_top_right
	recall.test_crew = list(make_crew("Recall Single", run_loc_floor_bottom_left))
	TEST_ASSERT(!recall.director_preflight(), "Одной карты мало для отзыва партии")
	recall.test_crew += make_crew("Recall Second", run_loc_floor_bottom_left)
	TEST_ASSERT(recall.director_preflight(), "Две карты и место для терминала достаточно")
	recall.test_drop = null
	TEST_ASSERT(!recall.director_preflight(), "Без места для терминала отзыв не запускается")

	var/datum/round_event_control/paperwork/centcom_questionnaire/test_targets/questionnaire = allocate(/datum/round_event_control/paperwork/centcom_questionnaire/test_targets)
	TEST_ASSERT(!questionnaire.director_preflight(), "Без факса командования анкета не запускается")
	questionnaire.test_fax = allocate(/obj/machinery/fax)
	TEST_ASSERT(questionnaire.director_preflight(), "С факсом командования анкета готова к запуску")

	TEST_ASSERT(!is_maintenance_hideout(corner_turf()), "Резерв теста не техтоннели станции")

/datum/unit_test/minor_incidents_paperwork/proc/check_hideout_description()
	var/turf/corner = corner_turf()
	TEST_ASSERT_EQUAL(hideout_wall_count(corner), 2, "Угол резерва зажат двумя стенами")
	var/obj/structure/rack/rack = allocate(/obj/structure/rack, locate(corner.x + 2, corner.y, corner.z))
	var/obj/machinery/portable_atmospherics/canister/canister = allocate(/obj/machinery/portable_atmospherics/canister, locate(corner.x + 1, corner.y + 1, corner.z))
	var/description = describe_hideout(corner)
	TEST_ASSERT(findtext(description, "в углу"), "Описание называет форму закутка: [description]")
	TEST_ASSERT(findtext(description, "отсек "), "Описание называет отсек: [description]")
	TEST_ASSERT(findtext(description, "в двух шагах к западу от стеллажа"), "Описание называет закреплённую примету с расстоянием и направлением: [description]")
	TEST_ASSERT(!findtext(description, "газового баллона"), "Подвижный баллон не служит приметой, когда есть закреплённая: [description]")
	qdel(rack)
	description = describe_hideout(corner)
	TEST_ASSERT(findtext(description, "газового баллона"), "Без закреплённых примет годится и подвижная: [description]")
	qdel(canister)
	allocate(/obj/structure/falsewall, locate(corner.x + 1, corner.y, corner.z))
	allocate(/obj/structure/rack, locate(corner.x + 2, corner.y, corner.z))
	description = describe_hideout(corner)
	TEST_ASSERT(!findtext(description, "стеллажа"), "Примета за непрозрачной преградой не видна из тайника: [description]")

/datum/unit_test/minor_incidents_paperwork/proc/check_inventory_audit()
	var/datum/round_event_control/paperwork/inventory_audit/test_targets/audit = allocate(/datum/round_event_control/paperwork/inventory_audit/test_targets)
	audit.test_drop = run_loc_floor_top_right
	audit.test_hideouts = list(corner_turf(), run_loc_floor_bottom_left)
	var/datum/round_event/paperwork/inventory_audit/test_delivery/event = make_event(/datum/round_event/paperwork/inventory_audit/test_delivery)
	event.control = audit
	event.start()
	var/obj/structure/lost_and_found_bin/bin = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(bin, "Ящик возврата доставлен на место посадки")
	allocated += bin
	TEST_ASSERT_EQUAL(length(bin.tagged_items), 2, "Каждый тайник получает по вещи с биркой")
	TEST_ASSERT(bin.pickup_timer, "Ящик ждёт капсулу по таймеру")
	var/datum/weakref/first_ref = bin.tagged_items[1]
	var/datum/weakref/second_ref = bin.tagged_items[2]
	var/obj/item/first_lost = first_ref.resolve()
	var/obj/item/second_lost = second_ref.resolve()
	allocated += first_lost
	allocated += second_lost
	TEST_ASSERT_EQUAL(get_turf(first_lost), corner_turf(), "Вещь лежит в тайнике")
	var/obj/item/paper/listing = paper_with(run_loc_floor_top_right, "Опись недостачи")
	TEST_ASSERT_NOTNULL(listing, "Вместе с ящиком прилетает опись")
	TEST_ASSERT(findtext(listing.get_raw_text(), describe_hideout(corner_turf())), "Опись описывает место каждой вещи: [listing.get_raw_text()]")
	TEST_ASSERT(findtext(listing.get_raw_text(), "DENIED rubber stamp") && findtext(listing.get_raw_text(), "flashlight"), "Опись называет вещи: [listing.get_raw_text()]")

	var/mob/living/carbon/human/finder = make_crew("Audit Finder", run_loc_floor_top_right)
	var/mob/living/carbon/human/courier = make_crew("Audit Courier", run_loc_floor_top_right)
	TEST_ASSERT(findtext(examine_text(first_lost, finder), "инвентарная бирка"), "Бирка видна в описании вещи")
	TEST_ASSERT(has_overlay(first_lost, "audit_tag"), "На вещи висит наклейка-бирка")
	first_lost.pickup(finder)
	first_lost.pickup(courier)
	TEST_ASSERT(findtext(examine_text(first_lost, courier), "нашедшего: Audit Finder"), "Бирка помнит первого, кто поднял вещь")

	var/obj/item/storage/toolbox/mechanical/toolbox = allocate(/obj/item/storage/toolbox/mechanical)
	bin.register_item(toolbox)
	var/list/tools = toolbox.contents.Copy()
	allocated += tools

	var/datum/bank_account/finder_account = paperwork_account_of(finder)
	var/datum/bank_account/courier_account = paperwork_account_of(courier)
	var/datum/bank_account/cargo_budget = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/finder_balance = finder_account.account_balance
	var/courier_balance = courier_account.account_balance
	var/cargo_balance = cargo_budget.account_balance
	TEST_ASSERT(bin.accept_item(first_lost, courier), "Вещь с биркой этой описи принимается")
	TEST_ASSERT(QDELETED(first_lost), "Сданная вещь исчезает в ящике")
	TEST_ASSERT_EQUAL(finder_account.account_balance, finder_balance + 150, "Награда уходит тому, кто первым поднял вещь")
	TEST_ASSERT_EQUAL(courier_account.account_balance, courier_balance, "Сдавший чужую находку денег не получает")
	TEST_ASSERT(!bin.accept_item(first_lost, courier), "Повторная сдача той же вещи невозможна")
	TEST_ASSERT_EQUAL(finder_account.account_balance, finder_balance + 150, "Награда за вещь выдаётся один раз")

	var/obj/item/wrench/untagged = allocate(/obj/item/wrench)
	TEST_ASSERT(!bin.accept_item(untagged, courier), "Вещь без бирки не принимается")
	TEST_ASSERT(!QDELETED(untagged), "Чужая вещь остаётся у владельца")
	var/obj/structure/lost_and_found_bin/other_bin = allocate(/obj/structure/lost_and_found_bin)
	var/obj/item/flashlight/foreign = allocate(/obj/item/flashlight)
	other_bin.register_item(foreign)
	TEST_ASSERT(!bin.accept_item(foreign, courier), "Бирка другой описи не принимается")

	TEST_ASSERT(bin.accept_item(toolbox, courier), "Ящик с инструментами принимается")
	TEST_ASSERT_EQUAL(courier_account.account_balance, courier_balance + 150, "Ничью находку оплачивают сдавшему")
	for(var/obj/item/tool as anything in tools)
		TEST_ASSERT(!QDELETED(tool) && get_turf(tool) == get_turf(bin), "Содержимое сданного ящика выкладывается рядом, а не удаляется: [tool]")
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, cargo_balance, "Премия снабжению только за всю опись")
	var/timer_before_full = bin.pickup_timer
	TEST_ASSERT(bin.accept_item(second_lost, courier), "Последняя вещь описи принимается")
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, cargo_balance + 200, "За полный возврат бюджет снабжения получает премию")
	TEST_ASSERT(bin.pickup_timer && bin.pickup_timer != timer_before_full, "После полного возврата таймер капсулы переставлен")
	TEST_ASSERT(timeleft(bin.pickup_timer) <= 1 MINUTES, "Когда всё сдано, ящик забирают раньше срока")

	TEST_ASSERT(bin.finish_audit(launch_pod = FALSE), "Аудит завершается")
	TEST_ASSERT_NULL(bin.pickup_timer, "После итога таймер не висит")
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, cargo_balance + 200, "Премия за полный возврат выдаётся один раз")
	var/obj/item/paper/summary = paper_with(get_turf(bin), "Итог аудита")
	TEST_ASSERT_NOTNULL(summary, "Ящик печатает итог аудита")
	TEST_ASSERT(findtext(summary.get_raw_text(), "Возвращено: 3"), "Итог считает сданные вещи")
	TEST_ASSERT(findtext(summary.get_raw_text(), "закрыта полностью"), "Итог отмечает полный возврат")
	TEST_ASSERT(!bin.finish_audit(launch_pod = FALSE), "Итог печатается один раз")

	TEST_ASSERT(other_bin.finish_audit(launch_pod = FALSE), "Аудит с несданной вещью тоже завершается")
	TEST_ASSERT_NULL(foreign.GetComponent(/datum/component/audit_tag), "С несданной вещи бирка снимается")
	TEST_ASSERT(!QDELETED(foreign), "Несданная вещь остаётся в мире")
	var/obj/item/paper/other_summary = paper_with(get_turf(other_bin), "Не найдено: 1")
	TEST_ASSERT_NOTNULL(other_summary, "Итог называет число ненайденных вещей")

	var/obj/structure/closet/supplypod/centcompod/paperwork_pickup/pod = new(null, FALSE, bin)
	allocated += pod
	TEST_ASSERT(pod.insertion_allowed(bin), "Возвратная капсула берёт свой ящик")
	TEST_ASSERT(!pod.insertion_allowed(untagged), "Возвратная капсула не уносит соседние вещи")
	TEST_ASSERT(!pod.insertion_allowed(get_turf(bin)), "Возвратная капсула не снимает пол")
	bin.forceMove(pod)
	pod.handleReturnAfterDeparting()
	TEST_ASSERT(QDELETED(bin), "Ящик удаляется вместе с улетевшей капсулой")
	TEST_ASSERT(QDELETED(pod), "Капсула не остаётся висеть после возврата")

/datum/unit_test/minor_incidents_paperwork/proc/fill_field(obj/item/paper/form, field_index, text)
	form.add_field_input(null, "[field_index]", text, null, null, FALSE, "Captain")

/datum/unit_test/minor_incidents_paperwork/proc/latest_news()
	for(var/datum/news/feed_channel/channel as anything in GLOB.news_network.network_channels)
		if(channel.channel_name == "Станционные Объявления")
			return length(channel.messages) ? channel.messages[length(channel.messages)] : null
	return null

/datum/unit_test/minor_incidents_paperwork/proc/forget_news(datum/news/feed_message/message)
	for(var/datum/news/feed_channel/channel as anything in GLOB.news_network.network_channels)
		channel.messages -= message

/datum/unit_test/minor_incidents_paperwork/proc/check_questionnaire()
	var/obj/machinery/fax/fax = allocate(/obj/machinery/fax)
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_CIV)
	var/datum/centcom_questionnaire/test_capture/survey = new(fax)
	allocated += survey
	survey.open(20 MINUTES)
	TEST_ASSERT(survey.deadline_timer, "У анкеты есть срок ответа")
	TEST_ASSERT_EQUAL(length(survey.sent), 1, "Бланк уходит на факс командования")
	var/obj/item/paper/centcom_questionnaire/form = survey.sent[1]
	TEST_ASSERT_EQUAL(form.input_field_count, 4, "В анкете три вопроса и подпись")
	TEST_ASSERT_EQUAL(form.survey, survey, "Бланк знает свою анкету")
	TEST_ASSERT(findtext(form.get_raw_text(), "Кого из сотрудников"), "Третий вопрос - кого отметить")
	TEST_ASSERT(form.special_fax_auto_note("central_command"), "Отправку анкеты в ЦК админская панель видит как обработанную")
	TEST_ASSERT_NULL(form.special_fax_auto_note("syndicate"), "Отправка синдикату остаётся обычным факсом")

	var/balance = budget.account_balance
	form.on_special_fax(fax, "syndicate", null)
	TEST_ASSERT_EQUAL(length(survey.sent), 1, "Отправка синдикату не считается ответом ЦК")
	form.add_stamp("paper121x54 stamp-ntr", 0, 0, 0, "stamp-ntr")
	fill_field(form, 0, "Семь")
	fill_field(form, 3, "Captain")
	form.moveToNullspace()
	TEST_ASSERT(!survey.receive(form, fax, null), "Неполная анкета не принимается")
	TEST_ASSERT_EQUAL(length(survey.sent), 3, "На неполную анкету приходят пояснение и сама анкета")
	var/obj/item/paper/explanation = survey.sent[2]
	TEST_ASSERT(findtext(explanation.get_raw_text(), "нет ответов на вопросы 2 и 3"), "Пояснение называет пустые вопросы: [explanation.get_raw_text()]")
	TEST_ASSERT(!findtext(explanation.get_raw_text(), "подписи"), "Подпись на месте, о ней не пишут: [explanation.get_raw_text()]")
	TEST_ASSERT(!findtext(explanation.get_raw_text(), "печати"), "Печать представителя NanoTrasen принимается: [explanation.get_raw_text()]")
	var/obj/item/paper/centcom_questionnaire/returned = survey.sent[3]
	TEST_ASSERT(istype(returned), "Вернулась анкета, а не простая бумага")
	TEST_ASSERT_EQUAL(returned.survey, survey, "Возвращённая анкета связана с опросом")
	TEST_ASSERT_EQUAL(survey.field_answer(returned, 0), "Семь", "Возвращённая анкета сохраняет ответы")
	TEST_ASSERT(survey.has_command_stamp(returned), "Возвращённая анкета сохраняет печать")
	TEST_ASSERT_EQUAL(budget.account_balance, balance, "Неполная анкета не приносит денег")

	var/mob/living/carbon/human/commended = make_crew("Иван Петров", run_loc_floor_bottom_left)
	var/datum/bank_account/commended_account = paperwork_account_of(commended)
	var/commended_balance = commended_account.account_balance
	var/long_incident = "<b>[jointext(new /list(80), "ы")]</b>"
	fill_field(returned, 1, long_incident)
	fill_field(returned, 2, "иван петров")
	returned.on_special_fax(fax, "central_command", null)
	TEST_ASSERT(survey.rewarded, "Дополненная возвращённая анкета принята")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 450, "Гражданский бюджет получает премию")
	TEST_ASSERT_EQUAL(commended_account.account_balance, commended_balance + 100, "Отмеченному сотруднику начислена благодарность")
	TEST_ASSERT_NULL(survey.deadline_timer, "После ответа напоминание не придёт")
	var/obj/item/paper/thanks = survey.sent[4]
	TEST_ASSERT(findtext(thanks.get_raw_text(), "благодарит"), "ЦК присылает благодарность командованию")
	TEST_ASSERT(findtext(thanks.get_raw_text(), "Иван Петров"), "Письмо называет отмеченного сотрудника")
	var/obj/item/paper/certificate = survey.sent[length(survey.sent)]
	TEST_ASSERT(findtext(certificate.get_raw_text(), "БЛАГОДАРНОСТЬ") && findtext(certificate.get_raw_text(), "Иван Петров"), "Отмеченному приходит грамота")
	var/datum/news/feed_message/news = latest_news()
	TEST_ASSERT(news && findtext(news.body, "КС-7"), "Итоги опроса вышли в ленте новостей")
	TEST_ASSERT(findtext(news.body, "Семь") && findtext(news.body, "Иван Петров"), "В новостях оценка смены и отмеченный: [news.body]")
	TEST_ASSERT(!findtext(news.body, "<b>"), "Ответы игроков в новостях экранированы")
	TEST_ASSERT(!findtext(news.body, jointext(new /list(70), "ы")), "Длинный ответ в новостях обрезан")
	forget_news(news)
	TEST_ASSERT(!survey.receive(returned, fax, null), "Повторная отправка не даёт второй премии")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 450, "Премия за анкету выдаётся один раз")
	TEST_ASSERT_EQUAL(commended_account.account_balance, commended_balance + 100, "Благодарность выдаётся один раз")

	var/datum/centcom_questionnaire/test_capture/late = new(fax)
	allocated += late
	late.open(20 MINUTES)
	late.expire()
	TEST_ASSERT(late.resolved, "Срок анкеты истекает")
	var/obj/item/paper/reminder = late.sent[length(late.sent)]
	TEST_ASSERT(findtext(reminder.get_raw_text(), "Взысканий не будет"), "Без ответа приходит напоминание без штрафа")
	var/obj/item/paper/centcom_questionnaire/late_form = late.sent[1]
	fill_field(late_form, 0, "5")
	fill_field(late_form, 1, "Ничего")
	fill_field(late_form, 2, "Петров")
	fill_field(late_form, 3, "Ivan")
	late_form.add_stamp("paper121x54 stamp-hop", 0, 0, 0, "stamp-hop")
	balance = budget.account_balance
	commended_balance = commended_account.account_balance
	TEST_ASSERT(!late.receive(late_form, fax, commended), "Анкета после срока премии не даёт")
	TEST_ASSERT_EQUAL(budget.account_balance, balance, "Опоздание не приносит денег")
	TEST_ASSERT_EQUAL(commended_account.account_balance, commended_balance, "Себя отметить нельзя")
	var/obj/item/paper/late_reply = late.sent[length(late.sent)]
	TEST_ASSERT(findtext(late_reply.get_raw_text(), "Самовыдвижение"), "ЦК объясняет отказ в благодарности: [late_reply.get_raw_text()]")
	forget_news(latest_news())

	var/datum/centcom_questionnaire/test_capture/self_signed = new(fax)
	allocated += self_signed
	self_signed.open(20 MINUTES)
	var/obj/item/paper/centcom_questionnaire/self_form = self_signed.sent[1]
	fill_field(self_form, 0, "8")
	fill_field(self_form, 1, "Ничего")
	fill_field(self_form, 2, "Иван Петров")
	self_form.add_field_input(null, "3", "%sign", null, null, FALSE, "Иван Петров")
	self_form.add_stamp("paper121x54 stamp-cap", 0, 0, 0, "stamp-cap")
	commended_balance = commended_account.account_balance
	TEST_ASSERT(self_signed.receive(self_form, fax, null), "Анкета, отправленная в срок другим человеком, принимается")
	TEST_ASSERT_EQUAL(commended_account.account_balance, commended_balance, "Подписавший анкету не может отметить себя, даже если факс отправил другой")
	var/obj/item/paper/self_reply = self_signed.sent[length(self_signed.sent)]
	TEST_ASSERT(findtext(self_reply.get_raw_text(), "Самовыдвижение"), "ЦК объясняет, почему подписавшему не положена благодарность: [self_reply.get_raw_text()]")
	forget_news(latest_news())

/datum/unit_test/minor_incidents_paperwork/proc/check_fax_integration()
	var/obj/machinery/fax/fax = allocate(/obj/machinery/fax)
	var/obj/item/paper/letter = allocate(/obj/item/paper)
	fax.receive(letter, "NT HR Department", automated = TRUE)
	var/list/entry = GLOB.centcom_communications_messages[length(GLOB.centcom_communications_messages)]
	TEST_ASSERT(entry["handled"], "Автоответ ЦК в панели связи сразу обработан")
	GLOB.centcom_communications_messages -= list(entry)

/datum/unit_test/minor_incidents_paperwork/proc/check_card_recall()
	var/datum/round_event_control/paperwork/id_card_recall/test_targets/recall = allocate(/datum/round_event_control/paperwork/id_card_recall/test_targets)
	recall.test_drop = run_loc_floor_top_right
	var/mob/living/carbon/human/first = make_crew("Recall Owner One", run_loc_floor_bottom_left)
	var/mob/living/carbon/human/second = make_crew("Recall Owner Two", run_loc_floor_bottom_left)
	var/mob/living/carbon/human/third = make_crew("Recall Owner Three", run_loc_floor_bottom_left)
	TEST_ASSERT(is_recall_eligible(first), "Член экипажа со своей картой подходит для отзыва")
	var/mob/living/carbon/human/synthetic = make_crew("Recall Synthetic", run_loc_floor_bottom_left)
	ADD_TRAIT(synthetic, TRAIT_ROBOTIC_ORGANISM, "minor_incidents_paperwork")
	TEST_ASSERT(!is_recall_eligible(synthetic), "Синтетиков отзыв не касается")
	var/mob/living/carbon/human/borrower = make_crew("Recall Borrower", run_loc_floor_bottom_left)
	var/obj/item/card/id/borrowed = borrower.wear_id
	borrowed.registered_name = "Someone Else"
	TEST_ASSERT(!is_recall_eligible(borrower), "Чужая карта на теле не помечается")

	recall.test_crew = list(first, second, third)
	var/datum/round_event/paperwork/id_card_recall/test_delivery/event = make_event(/datum/round_event/paperwork/id_card_recall/test_delivery)
	event.control = recall
	event.start()
	var/obj/structure/card_recall_terminal/terminal = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(terminal, "Терминал отзыва доставлен")
	allocated += terminal
	TEST_ASSERT(event.recalled_count >= 2 && event.recalled_count <= 3, "Отзывается от двух карт до числа кандидатов")
	TEST_ASSERT_EQUAL(length(terminal.recalled_cards), event.recalled_count, "Терминал знает все отозванные карты")
	var/obj/item/paper/listing = paper_with(run_loc_floor_top_right, "Список отзываемых")
	TEST_ASSERT_NOTNULL(listing, "Вместе с терминалом приходит список карт для HoP")

	var/datum/weakref/card_ref = terminal.recalled_cards[1]
	var/obj/item/card/id/card = card_ref.resolve()
	var/mob/living/carbon/human/owner = get(card, /mob/living/carbon/human)
	var/list/access_before = card.access.Copy()
	TEST_ASSERT(card.GetComponent(/datum/component/id_card_recall), "Карта помечена")
	TEST_ASSERT(has_overlay(card, "recall_mark"), "На помеченной карте мигает метка")
	TEST_ASSERT(findtext(listing.get_raw_text(), card.registered_name), "В списке есть имя владельца")
	TEST_ASSERT(findtext(examine_text(card, owner), "отозванной партии"), "Пометка видна при осмотре карты")
	TEST_ASSERT_EQUAL(json_encode(card.access), json_encode(access_before), "Доступ карты не меняется")
	var/datum/bank_account/account = card.registered_account
	var/balance = account.account_balance
	TEST_ASSERT(terminal.attackby(synthetic.wear_id, synthetic), "Терминал отвечает на исправную карту")
	TEST_ASSERT_EQUAL(length(terminal.replaced_cards), 0, "Исправная карта не меняется")
	owner.cached_multiplicative_actions_slowdown = 0.01
	TEST_ASSERT(terminal.attackby(card, owner), "Терминал берёт помеченную карту")
	TEST_ASSERT_NULL(card.GetComponent(/datum/component/id_card_recall), "После замены через слот пометка снята")
	TEST_ASSERT(!has_overlay(card, "recall_mark"), "После замены метка гаснет")
	TEST_ASSERT(!terminal.busy && terminal.icon_state == "terminal", "После замены терминал свободен")
	TEST_ASSERT_EQUAL(account.account_balance, balance + 150, "Владельцу приходит компенсация")
	TEST_ASSERT(!terminal.replace_chip(card, owner), "Повторная замена невозможна")
	TEST_ASSERT_EQUAL(account.account_balance, balance + 150, "Компенсация выдаётся один раз")

	var/mob/living/carbon/human/hop = make_crew("Recall HoP", run_loc_floor_bottom_left)
	hop.mind.assigned_role = "Head of Personnel"
	var/datum/bank_account/hop_account = paperwork_account_of(hop)
	var/hop_balance = hop_account.account_balance
	for(var/datum/weakref/other_ref as anything in terminal.recalled_cards)
		var/obj/item/card/id/other_card = other_ref.resolve()
		if(other_card.GetComponent(/datum/component/id_card_recall))
			TEST_ASSERT(terminal.replace_chip(other_card, hop), "HoP меняет чип чужой карты")
	TEST_ASSERT_EQUAL(hop_account.account_balance, hop_balance + 50 * (event.recalled_count - 1), "HoP получает плату за каждую чужую карту")
	TEST_ASSERT(timeleft(terminal.pickup_timer) <= 2 MINUTES, "Когда все карты заменены, терминал забирают раньше срока")
	TEST_ASSERT(terminal.finish_recall(launch_pod = FALSE), "Кампания закрывается")
	TEST_ASSERT(terminal.anchored, "Закрытый терминал не утащить от капсулы")
	TEST_ASSERT_NULL(terminal.pickup_timer, "После закрытия таймер не висит")
	TEST_ASSERT_NOTNULL(paper_with(get_turf(terminal), "Все карты партии заменены"), "Итог отмечает полную замену")
	TEST_ASSERT(terminal.attackby(card, owner), "Закрытый терминал отвечает на карту")

	var/mob/living/carbon/human/late_owner = make_crew("Recall Late Owner", run_loc_floor_bottom_left)
	var/obj/item/card/id/late_card = late_owner.wear_id
	var/obj/structure/card_recall_terminal/other_terminal = allocate(/obj/structure/card_recall_terminal, run_loc_floor_bottom_left)
	other_terminal.recall_card(late_card, null, "test")
	other_terminal.start_recall(40 MINUTES)
	TEST_ASSERT(other_terminal.finish_recall(launch_pod = FALSE), "Кампания закрывается по сроку")
	TEST_ASSERT_NULL(late_card.GetComponent(/datum/component/id_card_recall), "Оставшиеся пометки снимаются")
	var/obj/item/paper/summary = paper_with(get_turf(other_terminal), "Итог отзыва")
	TEST_ASSERT_NOTNULL(summary, "Терминал печатает итог")
	TEST_ASSERT(findtext(summary.get_raw_text(), "Не заменены") && findtext(summary.get_raw_text(), "Recall Late Owner"), "Итог перечисляет незаменённые карты: [summary.get_raw_text()]")

/datum/unit_test/minor_incidents_paperwork/proc/check_contraband()
	TEST_ASSERT_EQUAL(smuggler_cipher(smuggler_cipher("Ёжик в South Maintenance, щель!", 3), -3), "Ёжик в South Maintenance, щель!", "Шифр обратим для кириллицы и латиницы")
	var/turf/hideout = corner_turf()
	for(var/obj/structure/thing in hideout)
		qdel(thing)
	var/datum/round_event_control/paperwork/intercepted_contraband/test_targets/contraband = allocate(/datum/round_event_control/paperwork/intercepted_contraband/test_targets)
	contraband.test_drop = run_loc_floor_top_right
	contraband.test_hideouts = list(hideout)
	var/datum/round_event/paperwork/intercepted_contraband/test_delivery/event = make_event(/datum/round_event/paperwork/intercepted_contraband/test_delivery)
	event.control = contraband
	event.start()
	var/obj/structure/smuggler_stash/stash = locate() in hideout
	var/obj/item/smuggler_parcel/parcel = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(stash, "Тайник спрятан в выбранной клетке")
	TEST_ASSERT_NOTNULL(parcel, "Посылка доставлена в грузовой отсек")
	allocated += stash
	allocated += parcel
	TEST_ASSERT_EQUAL(parcel.recipient_name, event.smuggler_name, "Посылка на имя уволенного сотрудника")
	TEST_ASSERT_EQUAL(stash.mouse_opacity, MOUSE_OPACITY_OPAQUE, "Закрытый тайник ловит клик всей клеткой, а не пропускает лом в пол")

	var/list/payload = parcel.contents.Copy()
	allocated += payload
	TEST_ASSERT(locate(/obj/item/storage/fancy/cigarettes/cigpack_syndicate) in payload, "В посылке сигареты синдиката")
	TEST_ASSERT(locate(/obj/item/reagent_containers/food/drinks/bottle/absinthe) in payload, "В посылке нелегальный алкоголь")
	var/obj/item/card/id/forged = locate() in payload
	TEST_ASSERT(forged && !length(forged.access) && !forged.registered_account, "Поддельный ID без доступа и счёта")
	var/obj/item/paper/smuggler_note/note = locate() in payload
	TEST_ASSERT_NOTNULL(note, "В посылке шифрованная записка")
	var/accomplice_print = smuggler_accomplice_print(event.smuggler_name)
	TEST_ASSERT(note.fingerprints?[accomplice_print], "На записке отпечаток сообщника")
	parcel.unwrap(null)
	TEST_ASSERT(QDELETED(parcel), "Вскрытая посылка превращается в обрывки обёртки")
	TEST_ASSERT_EQUAL(get_turf(note), run_loc_floor_top_right, "Содержимое посылки высыпается на пол")
	for(var/obj/effect/decal/cleanable/wrapping/wrapping in run_loc_floor_top_right)
		qdel(wrapping)

	var/hint = describe_hideout(hideout)
	TEST_ASSERT(!findtext(note.get_raw_text(), hint), "До расшифровки подсказка не читается")
	TEST_ASSERT(note.decode(null), "Записку можно расшифровать")
	TEST_ASSERT(findtext(note.get_raw_text(), hint), "Расшифровка описывает место тайника: [note.get_raw_text()]")
	TEST_ASSERT(!note.decode(null), "Расшифровка выполняется один раз")

	var/mob/living/carbon/human/searcher = make_crew("Stash Searcher", hideout)
	var/mob/living/carbon/human/warden = make_crew("Stash Warden", run_loc_floor_top_right)
	TEST_ASSERT(findtext(examine_text(stash, searcher), "ломом"), "Вблизи видно, что плитку можно поддеть")
	TEST_ASSERT(!findtext(examine_text(stash, warden), "ломом"), "Издали тайник не выдаёт себя")
	TEST_ASSERT(stash.open_stash(searcher), "Тайник вскрывается")
	TEST_ASSERT_EQUAL(stash.mouse_opacity, MOUSE_OPACITY_ICON, "Вскрытый тайник больше не перекрывает клетку")
	var/obj/item/storage/lockbox/smuggler/box = locate() in hideout
	TEST_ASSERT_NOTNULL(box, "В тайнике шкатулка")
	var/list/box_contents = box.contents.Copy()
	allocated += box
	allocated += box_contents
	TEST_ASSERT(box.fingerprints?[accomplice_print], "На шкатулке тот же отпечаток сообщника, что на записке")
	TEST_ASSERT(length(box.suit_fibers), "На шкатулке волокна для сканера криминалиста")
	TEST_ASSERT(SEND_SIGNAL(box, COMSIG_IS_STORAGE_LOCKED), "Шкатулка заперта")
	TEST_ASSERT(box.force_open(searcher), "Замок шкатулки срывается")
	TEST_ASSERT(!SEND_SIGNAL(box, COMSIG_IS_STORAGE_LOCKED), "После взлома шкатулка открыта")
	var/cash = 0
	var/list/bills = list()
	for(var/obj/item/stack/spacecash/bill in box_contents)
		cash += bill.value * bill.amount
		bills += bill
	TEST_ASSERT_EQUAL(cash, 250, "В шкатулке 250 кр наличными")
	var/obj/item/smuggler_ledger/ledger = locate() in box_contents
	TEST_ASSERT_NOTNULL(ledger, "В шкатулке журнал контрабандиста")
	TEST_ASSERT_EQUAL(ledger.smuggler_name, event.smuggler_name, "Журнал принадлежит тому же контрабандисту")

	var/obj/machinery/computer/secure_data/console = allocate(/obj/machinery/computer/secure_data)
	console.machine_stat = NONE
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SEC)
	var/balance = budget.account_balance
	TEST_ASSERT(!ledger.register_evidence(console, searcher), "Без доступа надзирателя журнал не регистрируется")
	TEST_ASSERT_EQUAL(budget.account_balance, balance, "Отказ не приносит денег")
	var/obj/item/card/id/warden_card = warden.wear_id
	warden_card.access = list(ACCESS_SECURITY, ACCESS_ARMORY)
	var/obj/item/stack/spacecash/c200/savings = allocate(/obj/item/stack/spacecash/c200, run_loc_floor_top_right, 5)
	for(var/obj/item/stack/spacecash/bill as anything in bills)
		warden.put_in_hands(bill)
		if(bill.type == savings.type)
			savings.merge(bill)
	TEST_ASSERT(ledger.register_evidence(console, warden), "Надзиратель регистрирует журнал вместе с наличными")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 450, "Журнал и сданные наличные приносят бюджету СБ вознаграждение и премию")
	TEST_ASSERT_EQUAL(carried_cash(warden), 1000, "Изымаются ровно наличные тайника, свои деньги в той же пачке остаются у надзирателя")
	TEST_ASSERT_NOTNULL(paper_with(get_turf(console), "изъяты"), "Консоль печатает акт с изъятыми наличными")
	TEST_ASSERT(!ledger.register_evidence(console, warden), "Повторная регистрация невозможна")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 450, "Вознаграждение за журнал выдаётся один раз")

	var/mob/living/carbon/human/second_warden = make_crew("Stash Warden Two", run_loc_floor_top_right)
	var/obj/item/card/id/second_card = second_warden.wear_id
	second_card.access = list(ACCESS_SECURITY, ACCESS_ARMORY)
	var/obj/item/storage/lockbox/smuggler/merged_box = allocate(/obj/item/storage/lockbox/smuggler)
	var/list/merged_contents = merged_box.contents.Copy()
	allocated += merged_contents
	var/obj/item/smuggler_ledger/merged_ledger = locate() in merged_contents
	var/obj/item/stack/spacecash/c200/wallet = allocate(/obj/item/stack/spacecash/c200)
	second_warden.put_in_hands(wallet)
	for(var/obj/item/stack/spacecash/bill in merged_contents)
		if(istype(bill, /obj/item/stack/spacecash/c200))
			bill.merge(wallet)
		else
			second_warden.put_in_hands(bill)
	balance = budget.account_balance
	TEST_ASSERT(merged_ledger.register_evidence(console, second_warden), "Журнал регистрируется, когда купюры тайника влились в свою пачку")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 450, "Наличные тайника в своей пачке засчитываются")
	TEST_ASSERT_EQUAL(carried_cash(second_warden), 200, "Из общей пачки изымаются только наличные тайника")

	var/mob/living/carbon/human/rich_warden = make_crew("Stash Warden Three", run_loc_floor_top_right)
	var/obj/item/card/id/rich_card = rich_warden.wear_id
	rich_card.access = list(ACCESS_SECURITY, ACCESS_ARMORY)
	rich_warden.put_in_hands(allocate(/obj/item/stack/spacecash/c500))
	var/obj/item/storage/lockbox/smuggler/pocketed_box = allocate(/obj/item/storage/lockbox/smuggler)
	var/obj/item/smuggler_ledger/pocketed_ledger = locate() in pocketed_box
	allocated += pocketed_box.contents.Copy()
	pocketed_ledger.forceMove(run_loc_floor_bottom_left)
	balance = budget.account_balance
	TEST_ASSERT(pocketed_ledger.register_evidence(console, rich_warden), "Крупная купюра тоже покрывает наличные тайника")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 450, "Наличные крупной купюрой засчитываются")
	TEST_ASSERT_EQUAL(carried_cash(rich_warden), 250, "С крупной купюры выдаётся сдача")
	for(var/obj/item/holochip/change in rich_warden.held_items)
		allocated += change

	var/mob/living/carbon/human/broke_warden = make_crew("Stash Warden Four", run_loc_floor_top_right)
	var/obj/item/card/id/broke_card = broke_warden.wear_id
	broke_card.access = list(ACCESS_SECURITY, ACCESS_ARMORY)
	var/obj/item/storage/lockbox/smuggler/empty_box = allocate(/obj/item/storage/lockbox/smuggler)
	var/obj/item/smuggler_ledger/bare_ledger = locate() in empty_box
	allocated += empty_box.contents.Copy()
	bare_ledger.forceMove(run_loc_floor_bottom_left)
	balance = budget.account_balance
	TEST_ASSERT(bare_ledger.register_evidence(console, broke_warden), "Журнал без наличных тоже регистрируется")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 300, "Без наличных только вознаграждение за журнал")
	TEST_ASSERT_NOTNULL(paper_with(get_turf(console), "Наличные из тайника не сданы"), "Консоль печатает акт о несданных наличных")

/datum/unit_test/minor_incidents_paperwork/proc/check_sprites()
	var/list/expected = list(
		/obj/structure/lost_and_found_bin = list("bin", "bin_accept", "audit_tag"),
		/obj/structure/card_recall_terminal = list("terminal", "terminal_working", "terminal_done", "recall_mark"),
		/obj/structure/smuggler_stash = list("stash", "stash_open"),
		/obj/item/smuggler_parcel = list("parcel"),
		/obj/item/smuggler_ledger = list("ledger"),
	)
	for(var/atom/path as anything in expected)
		var/list/states = icon_states(initial(path.icon))
		for(var/state in expected[path])
			TEST_ASSERT(state in states, "У [path] нет состояния [state]")
	for(var/obj/item/path as anything in list(/obj/item/smuggler_parcel, /obj/item/smuggler_ledger))
		var/inhand = initial(path.item_state)
		TEST_ASSERT(inhand in icon_states(initial(path.lefthand_file)), "У [path] нет вида в левой руке")
		TEST_ASSERT(inhand in icon_states(initial(path.righthand_file)), "У [path] нет вида в правой руке")
