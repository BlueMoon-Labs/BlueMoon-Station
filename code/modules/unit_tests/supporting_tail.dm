// Общая фикстура проходит тот же путь применения ДНК, что и создание персонажа.
/datum/unit_test/supporting_tail
	var/list/saved_features
	var/list/save_paths = list()
	var/list/saved_taurs
	var/list/saved_taur_reference

/datum/unit_test/supporting_tail/Destroy()
	if(saved_features)
		GLOB.innate_features = saved_features
		saved_features = null
	if(saved_taurs)
		GLOB.taur_list = saved_taurs
		saved_taurs = null
	if(saved_taur_reference)
		GLOB.mutant_reference_list["taur"] = saved_taur_reference
		saved_taur_reference = null
	for(var/datum/preferences/prefs in allocated)
		prefs.path = null
	. = ..()
	for(var/file_path in save_paths)
		fdel(file_path)
	save_paths = null

/datum/unit_test/supporting_tail/proc/patient(style = "Naga")
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.dna.features["taur"] = style
	human.dna.features["innate_features"] = list(INNATE_NAGA_TAIL)
	human.sync_innate_features()
	return human

/datum/unit_test/supporting_tail/proc/preferences()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.pref_species = new /datum/species/human
	prefs.features["taur"] = "Naga"
	prefs.modified_limbs = list()
	prefs.all_quirks = list()
	prefs.innate_features = list()
	prefs.be_random_body = FALSE
	return prefs

/datum/unit_test/supporting_tail/proc/feature(feature_id, primary = FALSE, cost = 0)
	if(!saved_features)
		saved_features = GLOB.innate_features
		GLOB.innate_features = saved_features.Copy()
	var/datum/innate_feature/feature = allocate(/datum/innate_feature)
	feature.id = feature_id
	feature.primary = primary
	feature.quirk_cost = cost
	feature.display_name = "Тестовая особенность"
	GLOB.innate_features[feature_id] = feature
	return feature

// allocate передаёт координаты первым аргументом; прототипу операции пациент не нужен.
/datum/unit_test/supporting_tail/proc/surgery_prototype(surgery_type)
	var/datum/surgery/surgery = new surgery_type
	allocated += surgery
	return surgery

/datum/unit_test/supporting_tail/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	TEST_ASSERT(istype(tail, /obj/item/bodypart/l_leg/naga_tail), "Применение особенности создаёт опорный хвост.")
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_R_LEG), tail, "Обе зоны указывают на один объект.")
	TEST_ASSERT_EQUAL(length(human.bodyparts), 5, "В теле нет скрытой второй ноги.")
	TEST_ASSERT_EQUAL(human.get_num_legs(FALSE), 0, "Хвост не считается физическими ногами.")
	TEST_ASSERT(!human.has_left_leg() && !human.has_right_leg(), "Проверки ступней не видят ложные ноги.")
	TEST_ASSERT_EQUAL(human.get_num_supporting_limbs(), 2, "Хвост обеспечивает полную опору.")
	TEST_ASSERT_EQUAL(length(human.get_missing_limbs()), 0, "Целый хвост не создаёт отсутствующую правую ногу.")
	TEST_ASSERT(!human.resting && CHECK_MOBILITY(human, MOBILITY_STAND), "Применение анатомии не укладывает стоящего персонажа.")

/datum/unit_test/supporting_tail/variants/Run()
	for(var/style in list("Naga", "Naga (coiled)", "Naga, Fat", "RadDog Naga (Hyper)"))
		var/mob/living/carbon/human/human = patient(style)
		TEST_ASSERT(HAS_TRAIT(human, TRAIT_NAGA_ANATOMY), "Поддерживается вариант [style].")
	var/mob/living/carbon/human/other = patient("Tentacle")
	TEST_ASSERT(!HAS_TRAIT(other, TRAIT_NAGA_ANATOMY), "Общий змеиный стиль не даёт особенность неподходящему телу.")
	TEST_ASSERT_EQUAL(other.get_num_legs(), 2, "У другого тавра сохраняются ноги.")

/datum/unit_test/supporting_tail/idempotent/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 18, burn = 7, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	for(var/iteration in 1 to 3)
		human.sync_innate_features()
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_L_LEG), tail, "Повторное применение не создаёт новую конечность.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 18, "Синхронизация не лечит травмы.")
	TEST_ASSERT_EQUAL(tail.burn_dam, 7, "Синхронизация не лечит ожоги.")
	TEST_ASSERT_EQUAL(length(human.bodyparts), 5, "Повторное применение не накапливает хвосты.")

/datum/unit_test/supporting_tail/mind_locomotion/Run()
	var/mob/living/carbon/human/original = patient()
	original.mind_initialize()
	var/datum/mind/tail_mind = original.mind
	allocated += tail_mind
	TEST_ASSERT(HAS_TRAIT(tail_mind, TRAIT_NAGA_LOCOMOTION), "Новая личность с опорным хвостом получает хвостовую моторику.")
	var/mob/living/carbon/human/legs_body = allocate(/mob/living/carbon/human)
	legs_body.mind_initialize()
	var/datum/mind/legs_mind = legs_body.mind
	allocated += legs_mind
	tail_mind.transfer_to(legs_body)
	TEST_ASSERT_EQUAL(legs_body.get_num_legs(FALSE), 2, "Перенос разума не удаляет ноги нового тела.")
	TEST_ASSERT_EQUAL(legs_body.get_num_supporting_limbs(FALSE), 2, "Без проверки работоспособности учитываются физические ноги.")
	TEST_ASSERT_EQUAL(legs_body.get_num_supporting_limbs(), 0, "Непривычные ноги не дают личности опору для ходьбы.")
	TEST_ASSERT(!CHECK_MOBILITY(legs_body, MOBILITY_STAND), "После переноса личность сразу теряет возможность стоять на ногах.")
	TEST_ASSERT(CHECK_MOBILITY(legs_body, MOBILITY_MOVE) && (legs_body.movement_type & CRAWLING), "В новом теле сохраняется возможность ползать.")
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/list/scan = medical_scan_results(doctor, legs_body, TRUE)
	var/list/features = scan["innateFeatures"]
	TEST_ASSERT_EQUAL(length(features), 1, "Сканер показывает хвостовую моторику отдельно от анатомии нового тела.")
	var/list/motor_feature = features[1]
	TEST_ASSERT_EQUAL(motor_feature["id"], TRAIT_NAGA_LOCOMOTION, "Сканер объясняет личную причину невозможности ходить.")
	TEST_ASSERT(length(motor_feature["tooltip"]), "При несовместимой моторике сканер передаёт медицинскую подсказку.")
	legs_mind.transfer_to(original)
	original.mind_initialize()
	TEST_ASSERT(!HAS_TRAIT(legs_mind, TRAIT_NAGA_LOCOMOTION), "Чужая личность не наследует моторику тела с хвостом при входе в него.")
	TEST_ASSERT_EQUAL(original.get_num_supporting_limbs(FALSE), 2, "Непривычный хвост физически остаётся на месте.")
	TEST_ASSERT_EQUAL(original.get_num_supporting_limbs(), 0, "Личность с ножной моторикой не умеет пользоваться опорным хвостом.")
	TEST_ASSERT(!CHECK_MOBILITY(original, MOBILITY_STAND), "Обычная личность сразу теряет возможность стоять на хвосте.")
	TEST_ASSERT(CHECK_MOBILITY(original, MOBILITY_MOVE) && (original.movement_type & CRAWLING), "В хвостатом теле остаётся ползание на руках.")
	scan = medical_scan_results(doctor, original, TRUE)
	features = scan["innateFeatures"]
	var/found_leg_motor = FALSE
	for(var/list/entry as anything in features)
		if(entry["id"] == TRAIT_NAGA_LOCOMOTION && length(entry["tooltip"]))
			found_leg_motor = TRUE
	TEST_ASSERT(found_leg_motor, "Медсканер объясняет несовместимость обычной личности с опорным хвостом.")
	legs_mind.transfer_to(legs_body)
	TEST_ASSERT_EQUAL(legs_body.get_num_supporting_limbs(), 2, "Владеющая ногами личность может пользоваться ими в том же теле.")
	legs_body.set_resting(FALSE, TRUE)
	TEST_ASSERT(CHECK_MOBILITY(legs_body, MOBILITY_STAND), "Замена разума снимает ограничение ходьбы без обработки Life.")
	tail_mind.transfer_to(original)
	original.set_resting(FALSE, TRUE)
	TEST_ASSERT_EQUAL(original.get_num_supporting_limbs(), 2, "После возвращения в хвостатое тело личность снова имеет опору.")
	TEST_ASSERT(CHECK_MOBILITY(original, MOBILITY_STAND), "Хвостовая моторика не мешает стоять на опорном хвосте.")
	var/mob/living/carbon/human/spawned = patient()
	var/mob/dead/new_player/lobby = allocate(/mob/dead/new_player)
	var/datum/mind/spawn_mind = allocate(/datum/mind)
	lobby.mind = spawn_mind
	spawn_mind.set_current(lobby)
	spawn_mind.set_original_character(spawned)
	spawn_mind.transfer_to(spawned)
	TEST_ASSERT(HAS_TRAIT(spawn_mind, TRAIT_NAGA_LOCOMOTION), "Создание исходного персонажа из лобби закрепляет хвостовую моторику.")
	TEST_ASSERT(!spawned.resting && CHECK_MOBILITY(spawned, MOBILITY_STAND), "Исходное тело с хвостом не падает из-за временно неинициализированного навыка.")
	var/datum/preferences/prefs = preferences()
	prefs.apply_innate_features(spawned)
	TEST_ASSERT(!HAS_TRAIT(spawn_mind, TRAIT_NAGA_LOCOMOTION), "Явное снятие особенности в настройках снимает соответствующий навык.")
	TEST_ASSERT_EQUAL(spawned.get_num_supporting_limbs(), 2, "После явного снятия особенности обычные ноги снова дают опору.")
	TEST_ASSERT(!spawned.resting && CHECK_MOBILITY(spawned, MOBILITY_STAND), "Смена анатомии и навыка через настройки не вызывает промежуточное падение.")
	prefs.innate_features = list(INNATE_NAGA_TAIL)
	prefs.apply_innate_features(spawned)
	TEST_ASSERT(HAS_TRAIT(spawn_mind, TRAIT_NAGA_LOCOMOTION) && HAS_TRAIT(spawned, TRAIT_NAGA_ANATOMY), "Явное включение особенности меняет тело и навык вместе.")
	TEST_ASSERT(!spawned.resting && CHECK_MOBILITY(spawned, MOBILITY_STAND), "Включение особенности через настройки также не укладывает персонажа.")
	var/mob/living/carbon/human/unfamiliar_tail = patient()
	legs_mind.transfer_to(unfamiliar_tail)
	TEST_ASSERT_EQUAL(unfamiliar_tail.get_num_supporting_limbs(), 0, "Вход обычной личности в тело без прежнего разума тоже блокирует хвост.")
	TEST_ASSERT(!CHECK_MOBILITY(unfamiliar_tail, MOBILITY_STAND), "Ограничение обновляется и когда ни один из прежних разумов не имел хвостового навыка.")

/datum/unit_test/supporting_tail/rejuvenation/Run()
	var/mob/living/carbon/human/original = patient("Naga, Fat")
	original.mind_initialize()
	var/datum/mind/tail_mind = original.mind
	allocated += tail_mind
	tail_mind.set_original_character(original)
	var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
	recipient.dna.features["taur"] = "None"
	var/datum/innate_feature/extra = feature("ci_rejuvenation_extra")
	recipient.dna.features["innate_features"] = list(extra.id)
	tail_mind.transfer_to(recipient)
	recipient.fully_heal()
	TEST_ASSERT_EQUAL(recipient.get_num_legs(FALSE), 2, "Обычное полное лечение не меняет ноги по моторике личности.")
	recipient.revive(full_heal = TRUE, admin_revive = TRUE)
	var/obj/item/bodypart/l_leg/naga_tail/tail = recipient.get_bodypart(BODY_ZONE_L_LEG)
	TEST_ASSERT(istype(tail), "Реджув заменяет ноги опорным хвостом для хвостовой личности.")
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_R_LEG), tail, "После реджува обе зоны относятся к единственному хвосту.")
	TEST_ASSERT_EQUAL(recipient.get_num_legs(FALSE), 0, "Обычные ноги не остаются рядом с восстановленным хвостом.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "Naga, Fat", "В чужом теле восстанавливается вариант исходного персонажа.")
	TEST_ASSERT((INNATE_NAGA_TAIL in recipient.dna.features["innate_features"]) && (extra.id in recipient.dna.features["innate_features"]), "Реджув закрепляет хвост в ДНК и сохраняет остальные особенности.")
	TEST_ASSERT(recipient.mind == tail_mind && HAS_TRAIT(tail_mind, TRAIT_NAGA_LOCOMOTION), "Реджув не меняет личность и её моторику.")
	recipient.set_resting(FALSE, TRUE)
	TEST_ASSERT(CHECK_MOBILITY(recipient, MOBILITY_STAND), "После реджува хвостовая личность снова может встать.")
	recipient.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_L_LEG), tail, "Повторный реджув не пересоздаёт целый хвост.")
	TEST_ASSERT_EQUAL(length(recipient.bodyparts), 5, "Повторный реджув не накапливает лишние конечности.")
	tail.drop_limb()
	recipient.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT(istype(recipient.get_bodypart(BODY_ZONE_L_LEG), /obj/item/bodypart/l_leg/naga_tail), "Реджув возвращает и ампутированный хвост.")
	var/mob/living/carbon/human/ordinary = allocate(/mob/living/carbon/human)
	ordinary.mind_initialize()
	var/datum/mind/leg_mind = ordinary.mind
	allocated += leg_mind
	leg_mind.transfer_to(recipient)
	recipient.fully_heal()
	TEST_ASSERT(HAS_TRAIT(recipient, TRAIT_NAGA_ANATOMY), "Обычное лечение не убирает непривычный хвост.")
	recipient.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT_EQUAL(recipient.get_num_legs(FALSE), 2, "Реджув возвращает обычной личности обе ноги вместо хвоста.")
	TEST_ASSERT(!HAS_TRAIT(recipient, TRAIT_NAGA_ANATOMY) && !HAS_TRAIT_FROM(recipient, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL), "Сняты анатомический трейт и защита хвоста.")
	TEST_ASSERT(!(INNATE_NAGA_TAIL in recipient.dna.features["innate_features"]) && (extra.id in recipient.dna.features["innate_features"]), "Из ДНК удаляется только особенность хвоста.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "None", "Обычные ноги не скрываются спрайтом прежнего хвоста.")
	TEST_ASSERT(recipient.mind == leg_mind && !HAS_TRAIT(leg_mind, TRAIT_NAGA_LOCOMOTION), "Обратная замена также не переписывает моторику личности.")
	recipient.set_resting(FALSE, TRUE)
	TEST_ASSERT(CHECK_MOBILITY(recipient, MOBILITY_STAND), "Восстановленные ноги доступны обычной личности.")
	var/mob/living/carbon/human/no_taur = allocate(/mob/living/carbon/human)
	no_taur.dna.species.mutant_bodyparts = no_taur.dna.species.mutant_bodyparts.Copy()
	no_taur.dna.species.mutant_bodyparts -= "taur"
	tail_mind.transfer_to(no_taur)
	no_taur.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT(HAS_TRAIT(no_taur, TRAIT_NAGA_ANATOMY) && no_taur.get_num_supporting_limbs() == 2, "Реджув восстанавливает хвост и в виде без исходной поддержки тавров.")
	TEST_ASSERT(no_taur.dna.species.mutant_bodyparts["taur"], "Восстановленный хвост имеет слой для отрисовки.")
	var/mob/living/carbon/human/mindless = patient()
	var/obj/item/bodypart/mindless_tail = mindless.get_bodypart(BODY_ZONE_L_LEG)
	mindless.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT_EQUAL(mindless.get_bodypart(BODY_ZONE_L_LEG), mindless_tail, "У тела без разума реджув сохраняет текущую анатомию.")

/datum/unit_test/supporting_tail/rest_motor_mismatch
	var/list/saved_chat_capture

/datum/unit_test/supporting_tail/rest_motor_mismatch/Destroy()
	GLOB.unit_test_chat_capture = saved_chat_capture
	saved_chat_capture = null
	return ..()

/datum/unit_test/supporting_tail/rest_motor_mismatch/Run()
	saved_chat_capture = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = list()
	for(var/tail_body in list(FALSE, TRUE))
		var/mob/living/carbon/human/human = tail_body ? patient() : allocate(/mob/living/carbon/human)
		human.mind_initialize()
		allocated += human.mind
		human.mind.set_naga_locomotion(!tail_body)
		TEST_ASSERT(human.resting && human.lying, "Несовместимая моторика не даёт встать.")
		var/start_time = world.time
		human.lay_down()
		human.do_resist()
		TEST_ASSERT_EQUAL(world.time, start_time, "Rest и Resist отказывают сразу, без ожидания do_after.")
		TEST_ASSERT(!LAZYLEN(human.do_afters) && !(human.combat_flags & COMBAT_FLAG_RESISTING_REST), "Не создаются длительное действие и флаг попытки встать.")
		var/warnings = 0
		var/reason = tail_body ? "не умеете пользоваться опорным хвостом" : "не умеете пользоваться ногами"
		for(var/list/entry as anything in GLOB.unit_test_chat_capture)
			if(entry[1] == human && findtext(entry[2], "class='warning'") && findtext(entry[2], reason))
				warnings++
		TEST_ASSERT_EQUAL(warnings, 2, "Обе команды объясняют причину отказа через span_warning.")
		var/message_count = length(GLOB.unit_test_chat_capture)
		TEST_ASSERT(!human.resist_a_rest(automatic = TRUE), "Автовставание также отказывает без do_after.")
		TEST_ASSERT_EQUAL(length(GLOB.unit_test_chat_capture), message_count, "Автовставание не спамит предупреждениями.")
		TEST_ASSERT(!human.resist_a_rest(ignoretimer = TRUE), "Пропуск таймера не обходит несовместимую моторику.")
		TEST_ASSERT(human.resting && human.lying, "Отклонённая попытка не меняет положение тела.")

/datum/unit_test/supporting_tail/surgical_conversion/Run()
	var/mob/living/carbon/human/donor = patient("Naga, Fat")
	donor.mind_initialize()
	var/datum/mind/tail_mind = donor.mind
	allocated += tail_mind
	var/obj/item/bodypart/l_leg/naga_tail/tail = donor.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 12, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	tail.drop_limb()
	var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	doctor.dna.features["innate_features"] = list()
	doctor.dna.transfer_identity(recipient)
	tail_mind.transfer_to(recipient)
	recipient.Paralyze(30 SECONDS)
	doctor.mind_initialize()
	allocated += doctor.mind
	doctor.zone_selected = BODY_ZONE_PRECISE_GROIN
	var/obj/item/surgical_drapes/drapes = allocate(/obj/item/surgical_drapes)
	var/datum/surgery/naga_tail_replacement/replacement = surgery_prototype(/datum/surgery/naga_tail_replacement)
	var/datum/surgery_step/add_prosthetic/regular_graft = allocate(/datum/surgery_step/add_prosthetic)
	TEST_ASSERT_EQUAL(regular_graft.preop(doctor, recipient, BODY_ZONE_L_LEG, tail, replacement), -1, "Опорный хвост нельзя поставить обычной операцией на одной ноге.")
	TEST_ASSERT(!replacement.can_start(doctor, recipient, drapes), "При наличии обеих ног пересадка хвоста не предлагается.")
	var/obj/item/bodypart/left = recipient.get_bodypart(BODY_ZONE_L_LEG)
	left.drop_limb()
	TEST_ASSERT(!replacement.can_start(doctor, recipient, drapes), "Одна оставшаяся нога также мешает пересадке хвоста.")
	var/obj/item/bodypart/right = recipient.get_bodypart(BODY_ZONE_R_LEG)
	right.drop_limb()
	TEST_ASSERT(replacement.can_start(doctor, recipient, drapes), "После обычной ампутации обеих ног предлагается пересадка через пах.")
	var/datum/surgery/operation = new /datum/surgery/naga_tail_replacement(recipient, BODY_ZONE_PRECISE_GROIN, recipient.get_bodypart(BODY_ZONE_CHEST))
	allocated += operation
	var/datum/surgery_step/attach_naga_tail/attach = allocate(/datum/surgery_step/attach_naga_tail)
	doctor.put_in_active_hand(tail)
	TEST_ASSERT(attach.success(doctor, recipient, BODY_ZONE_PRECISE_GROIN, tail, operation), "В новое тело пришивается хвост без актуализатора.")
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_R_LEG), tail, "Пришит принесённый хвост, а не новая конечность.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 12, "Переход к хвостатой анатомии сохраняет повреждения донора.")
	TEST_ASSERT(HAS_TRAIT(recipient, TRAIT_NAGA_ANATOMY), "Операция меняет анатомию тела.")
	TEST_ASSERT(INNATE_NAGA_TAIL in recipient.dna.features["innate_features"], "Хвостатая анатомия закреплена в ДНК.")
	TEST_ASSERT(!(INNATE_NAGA_TAIL in doctor.dna.features["innate_features"]), "Пересадка не меняет список особенностей источника скопированной ДНК.")
	doctor.sync_innate_features()
	TEST_ASSERT_EQUAL(doctor.get_num_legs(FALSE), 2, "Последующая синхронизация источника ДНК сохраняет его ноги.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "Naga, Fat", "Внешность берётся с пересаженного хвоста.")
	recipient.sync_innate_features()
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_L_LEG), tail, "Повторная синхронизация не пересоздаёт пришитый хвост.")
	recipient.SetParalyzed(0)
	recipient.set_resting(FALSE, TRUE)
	TEST_ASSERT(CHECK_MOBILITY(recipient, MOBILITY_STAND), "Пришитый хвост возвращает возможность стоять после наркоза.")
	var/mob/living/carbon/human/another_body = allocate(/mob/living/carbon/human)
	tail_mind.transfer_to(another_body)
	recipient.sync_innate_features()
	TEST_ASSERT_EQUAL(recipient.get_bodypart(BODY_ZONE_L_LEG), tail, "Уход разума не отменяет хирургическое изменение тела.")
	TEST_ASSERT_EQUAL(another_body.get_num_supporting_limbs(), 0, "Хвостовая моторика по-прежнему следует за личностью.")
	var/mob/living/carbon/human/empty_body = allocate(/mob/living/carbon/human)
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		empty_body.get_bodypart(zone).drop_limb()
	TEST_ASSERT(empty_body.can_receive_naga_tail(), "Медик может заранее подготовить безногую куклу без разума.")

/datum/unit_test/supporting_tail/limbgrower/Run()
	var/obj/machinery/limbgrower/grower = allocate(/obj/machinery/limbgrower)
	allocated += grower.stored_research
	var/datum/design/design = grower.stored_research.isDesignResearchedID("supporting_tail")
	TEST_ASSERT(istype(design), "Рецепт опорного хвоста доступен в Limb Grower без исследования.")
	var/list/interface_data = grower.ui_static_data()
	var/found_recipe = FALSE
	for(var/list/category as anything in interface_data["categories"])
		if(category["name"] != "human")
			continue
		for(var/list/recipe as anything in category["designs"])
			if(recipe["id"] == design.id)
				found_recipe = TRUE
	TEST_ASSERT(found_recipe, "Рецепт виден в интерфейсе человеческих конечностей.")
	for(var/reagent_type in design.reagents_list)
		grower.reagents.add_reagent(reagent_type, design.reagents_list[reagent_type])
	grower.being_built = design
	grower.build_item(design.reagents_list)
	var/obj/item/bodypart/l_leg/naga_tail/tail = locate() in get_turf(grower)
	TEST_ASSERT(istype(tail), "Limb Grower создаёт опорный хвост.")
	allocated += tail
	TEST_ASSERT_EQUAL(grower.reagents.total_volume, 0, "Печать расходует реагенты, указанные в рецепте.")
	TEST_ASSERT(!grower.busy, "После печати машина снова свободна.")
	TEST_ASSERT_EQUAL(tail.taur_style, "Naga", "Выращенный хвост имеет стандартную форму наги.")
	TEST_ASSERT(islist(tail.tail_item_color), "Цветовая маска хвоста получает нейтральную окраску вместо исходных цветов каналов.")
	var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		recipient.get_bodypart(zone).drop_limb()
	TEST_ASSERT(tail.attach_limb(recipient), "Выращенный хвост можно пересадить в подготовленное тело без разума.")
	TEST_ASSERT_EQUAL(recipient.get_num_supporting_limbs(), 2, "Выращенный хвост возвращает опору.")

/datum/unit_test/supporting_tail/missing_and_regeneration/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/list/missing = human.get_missing_limbs()
	TEST_ASSERT_EQUAL(length(missing), 1, "Отсутствующий хвост учитывается один раз.")
	TEST_ASSERT_EQUAL(missing[1], BODY_ZONE_L_LEG, "У отсутствующего хвоста одна каноническая зона.")
	TEST_ASSERT_EQUAL(human.get_num_supporting_limbs(), 0, "Без хвоста нет опоры.")
	TEST_ASSERT(!HAS_TRAIT_FROM(human, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL), "Потеря хвоста снимает его защиту ступней.")
	human.sync_innate_features()
	TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_L_LEG), "Синхронизация не отращивает ампутированный хвост.")
	TEST_ASSERT_EQUAL(human.regenerate_limbs(), 1, "Регенерация восстанавливает одну конечность.")
	TEST_ASSERT(istype(human.get_bodypart(BODY_ZONE_R_LEG), /obj/item/bodypart/l_leg/naga_tail), "Регенерация не создаёт обычных ног.")

/datum/unit_test/supporting_tail/resting_and_reversion/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_resting(TRUE, TRUE)
	human.dna.features["taur"] = "Naga"
	human.dna.features["innate_features"] = list(INNATE_NAGA_TAIL)
	human.sync_innate_features()
	TEST_ASSERT(human.resting, "Выбранный отдых не отменяется заменой анатомии.")
	human.set_resting(FALSE, TRUE)
	human.dna.features["innate_features"] = list()
	human.sync_innate_features()
	TEST_ASSERT_EQUAL(human.get_num_legs(), 2, "Снятие особенности возвращает две ноги.")
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_NAGA_ANATOMY), "Снятие особенности удаляет признак анатомии.")
	TEST_ASSERT(!human.resting, "Обратная замена опоры не укладывает персонажа.")

/datum/unit_test/supporting_tail/hard_soles_sources/Run()
	var/mob/living/carbon/human/human = patient()
	ADD_TRAIT(human, TRAIT_HARD_SOLES, "ci_other_source")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	TEST_ASSERT(HAS_TRAIT_FROM(human, TRAIT_HARD_SOLES, "ci_other_source"), "Удаление хвоста сохраняет чужой источник трейта.")
	REMOVE_TRAIT(human, TRAIT_HARD_SOLES, "ci_other_source")
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_HARD_SOLES), "Собственный источник хвоста не остаётся после отсечения.")

/datum/unit_test/supporting_tail/damage_zones/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	human.apply_damage(10, BRUTE, BODY_ZONE_L_LEG, wound_bonus = CANT_WOUND)
	human.apply_damage(15, BRUTE, BODY_ZONE_R_LEG, wound_bonus = CANT_WOUND)
	TEST_ASSERT_EQUAL(tail.brute_dam, 25, "Урон из двух зон суммируется на одном хвосте один раз.")
	TEST_ASSERT_EQUAL(human.getBruteLoss(), 25, "Суммарные травмы учитывают хвост один раз.")
	TEST_ASSERT_EQUAL(human.maxHealth - human.health, 25 * tail.body_damage_coeff, "Урон здоровью учитывает коэффициент хвоста.")
	human.get_bodypart(BODY_ZONE_R_LEG).heal_damage(10, 0)
	TEST_ASSERT_EQUAL(tail.brute_dam, 15, "Лечение через правую зону попадает в тот же хвост.")
	human.acid_act(100, 10, BODY_ZONE_R_LEG)
	TEST_ASSERT_EQUAL(tail.brute_dam, 20, "Кислота повреждает единый хвост один раз.")
	TEST_ASSERT_EQUAL(tail.burn_dam, 10, "Две зоны ног не удваивают кислотные ожоги хвоста.")

/datum/unit_test/supporting_tail/capacity_and_recovery/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/bodypart/l_leg/leg = allocate(/obj/item/bodypart/l_leg)
	var/buff = tail.max_damage / (leg.max_damage * 2)
	TEST_ASSERT(buff > 1, "Хвост имеет усиление сверх суммы двух ног.")
	TEST_ASSERT_EQUAL(tail.max_stamina_damage, leg.max_stamina_damage * 2 * buff, "Запас стамины использует тот же бафф, что и прочность.")
	TEST_ASSERT_EQUAL(tail.disable_threshold, leg.disable_threshold * 2 * buff, "Порог травмы использует тот же бафф, что и прочность.")
	TEST_ASSERT_EQUAL(tail.body_damage_coeff, leg.body_damage_coeff, "Коэффициент влияния травмы на здоровье не ослаблен скрытым множителем.")
	TEST_ASSERT(abs(tail.stam_heal_tick - leg.stam_heal_tick * 2 * buff) < DAMAGE_PRECISION, "Восстановление стамины усилено согласованно с запасом.")
	tail.receive_damage(stamina = tail.stam_heal_tick * 2, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	var/before = tail.stamina_dam
	tail.on_life(2, 1)
	TEST_ASSERT(abs(tail.stamina_dam - before + tail.stam_heal_tick) < DAMAGE_PRECISION, "Life действительно восстанавливает настроенный объём стамины.")

/datum/unit_test/supporting_tail/armor/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/clothing/suit/armor/vest = allocate(/obj/item/clothing/suit/armor)
	var/unprotected = human.getarmor(tail, MELEE)
	vest.body_parts_covered = CHEST
	TEST_ASSERT(human.equip_to_slot_if_possible(vest, ITEM_SLOT_OCLOTHING), "Броня надевается на носителя хвоста.")
	var/protected = human.getarmor(human.get_bodypart(BODY_ZONE_R_LEG), MELEE)
	TEST_ASSERT_EQUAL(protected, unprotected + vest.armor.getRating(MELEE), "Броня тела защищает единый хвост при попадании в правую зону.")
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), protected, "У левой и правой зон одинаковая защита.")
	vest.clothing_flags |= THICKMATERIAL
	TEST_ASSERT_EQUAL(zone2body_parts_covered_complicated(BODY_ZONE_PRECISE_GROIN), CHEST, "Пах по-прежнему соответствует покрытию тела.")
	TEST_ASSERT_EQUAL(get_bodypart_protecting_clothing_by_coverage(human, tail), vest, "Лечение находит броню тела над хвостом.")
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		TEST_ASSERT(human.is_zone_covered_by_clothing(zone), "Одежда на теле закрывает хвост для инъекций: [zone].")
		TEST_ASSERT(!human.can_inject(null, FALSE, zone), "Толстая броня тела блокирует инъекции в хвост: [zone].")
		TEST_ASSERT(!get_location_accessible(human, zone), "Покрытие тела блокирует хирургический доступ к хвосту: [zone].")
	TEST_ASSERT(!get_location_accessible(human, BODY_ZONE_PRECISE_GROIN), "Одежда на теле закрывает доступ к основанию хвоста.")
	vest.body_parts_covered = GROIN
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), unprotected, "Отдельное покрытие паха без тела не даёт броню хвосту.")
	vest.body_parts_covered = LEGS
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), unprotected, "Броня только ног не защищает хвост.")
	TEST_ASSERT(!get_bodypart_protecting_clothing_by_coverage(human, tail), "Броня ног не мешает лечить хвост.")
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		TEST_ASSERT(!human.is_zone_covered_by_clothing(zone), "Покрытие ног не закрывает хвост для инъекций: [zone].")
		TEST_ASSERT(human.can_inject(null, FALSE, zone), "Броня ног не блокирует инъекции в хвост: [zone].")
		TEST_ASSERT(get_location_accessible(human, zone), "Броня ног не закрывает хирургический доступ к хвосту: [zone].")
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under)
	uniform.limb_integrity = 1
	uniform.has_sensor = NO_SENSORS
	TEST_ASSERT(human.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Форма надевается перед проверкой повреждения покрытия.")
	tail.check_woundings_mods(WOUND_SLASH, 30, 0, 0)
	TEST_ASSERT(!(uniform.body_parts_covered & CHEST), "Удар по хвосту разрывает покрытие тела.")
	TEST_ASSERT(!(uniform.body_parts_covered & GROIN), "Разрыв покрытия тела снимает и покрытие паха, как прежде.")
	TEST_ASSERT(uniform.body_parts_covered & LEG_LEFT, "Удар по хвосту не разрывает покрытие левой ноги.")
	TEST_ASSERT_EQUAL(human.getarmor(tail, MELEE), unprotected, "Разорванная форма перестаёт защищать хвост.")
	TEST_ASSERT(get_location_accessible(human, BODY_ZONE_R_LEG), "Разрыв покрытия открывает доступ к хвосту.")

/datum/unit_test/supporting_tail/fracture_and_paralysis/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.force_wound_upwards(/datum/wound/blunt/critical)
	var/datum/wound/blunt/critical/fracture = tail.get_wound_type(/datum/wound/blunt/critical)
	TEST_ASSERT_NOTNULL(fracture, "На хвост накладывается критический перелом.")
	TEST_ASSERT(!tail.disabled, "Критический перелом не отключает хвост целиком.")
	var/datum/status_effect/limp/limp = human.has_status_effect(/datum/status_effect/limp)
	TEST_ASSERT_NOTNULL(limp, "Перелом вызывает хромоту.")
	TEST_ASSERT_EQUAL(limp.slowdown_left + limp.slowdown_right, fracture.limp_slowdown, "Один хвост не удваивает штраф перелома.")
	ADD_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	TEST_ASSERT(tail.disabled, "Паралич правой зоны отключает общий хвост.")
	REMOVE_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	TEST_ASSERT(!tail.disabled, "После снятия паралича хвост снова служит опорой.")
	qdel(fracture)
	tail.force_wound_upwards(/datum/wound/blunt/moderate)
	var/datum/wound/blunt/moderate/dislocation = tail.get_wound_type(/datum/wound/blunt/moderate)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	doctor.start_pulling(human)
	doctor.zone_selected = BODY_ZONE_R_LEG
	doctor.a_intent = INTENT_HELP
	TEST_ASSERT(dislocation.try_handling(doctor), "Выбор правой зоны позволяет начать ручное лечение вывиха хвоста.")
	doctor.stop_pulling()

/datum/unit_test/supporting_tail/jelly_cannibalism/Run()
	var/mob/living/carbon/human/human = patient()
	human.set_species(/datum/species/jelly)
	var/datum/species/jelly/species = human.dna.species
	species.Cannibalize_Body(human)
	TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_L_LEG), "При нехватке крови желейный вид сначала поглощает хвост.")
	TEST_ASSERT(human.get_num_arms(FALSE) == 2, "Поглощение хвоста сохраняет обе руки.")
	for(var/iteration in 1 to 2)
		species.Cannibalize_Body(human)
	TEST_ASSERT_EQUAL(human.get_num_arms(FALSE), 0, "После хвоста поглощаются только существующие руки.")
	var/previous_losebreath = human.losebreath
	species.Cannibalize_Body(human)
	TEST_ASSERT_EQUAL(human.losebreath, previous_losebreath + 1, "Без конечностей начинается удушье, без обращения к несуществующей правой ноге.")

/datum/unit_test/supporting_tail/vehicle/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/vehicle/ridden/atv/vehicle = allocate(/obj/vehicle/ridden/atv)
	vehicle.buckle_mob(human, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_EQUAL(human.buckled, vehicle, "Работающий хвост позволяет управлять транспортом.")
	vehicle.unbuckle_mob(human)
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	ADD_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	vehicle.buckle_mob(human, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_NULL(human.buckled, "Парализованный хвост не позволяет управлять транспортом.")
	REMOVE_TRAIT(human, TRAIT_PARALYSIS_R_LEG, "ci_paralysis")
	tail.update_disabled()
	tail.drop_limb()
	vehicle.buckle_mob(human, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_NULL(human.buckled, "После потери хвоста транспорт снова требует опору.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	vehicle.buckle_mob(other, force = TRUE, check_loc = FALSE)
	TEST_ASSERT_EQUAL(other.buckled, vehicle, "Обычные ноги по-прежнему позволяют управлять транспортом.")

/datum/unit_test/supporting_tail/graft_retains_wounds/Run()
	var/mob/living/carbon/human/donor = patient("Naga, Fat")
	var/mob/living/carbon/human/recipient = patient()
	var/obj/item/bodypart/old_tail = recipient.get_bodypart(BODY_ZONE_L_LEG)
	old_tail.drop_limb()
	var/obj/item/bodypart/l_leg/naga_tail/tail = donor.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 12, burn = 4, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	tail.force_wound_upwards(/datum/wound/blunt/severe)
	var/datum/wound/blunt/severe/fracture = tail.get_wound_type(/datum/wound/blunt/severe)
	TEST_ASSERT_NOTNULL(fracture, "У донора есть перелом перед пересадкой.")
	tail.drop_limb()
	TEST_ASSERT(tail.attach_limb(recipient), "Повреждённый хвост можно пересадить подходящему телу.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 12, "Пересадка сохраняет травмы.")
	TEST_ASSERT_EQUAL(tail.burn_dam, 4, "Пересадка сохраняет ожоги.")
	TEST_ASSERT(fracture in recipient.all_wounds, "Рана присоединяется к новому пациенту.")
	TEST_ASSERT_EQUAL(fracture.victim, recipient, "Рана больше не ссылается на донора.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "Naga", "Повреждённый хвост принимает форму текущего владельца.")

/datum/unit_test/supporting_tail/reject_normal_legs/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/obj/item/bodypart/l_leg/leg = allocate(/obj/item/bodypart/l_leg)
	TEST_ASSERT(!leg.attach_limb(human), "Обычная нога не пришивается вместо хвоста.")
	TEST_ASSERT_NULL(leg.owner, "Отвергнутая нога не получает владельца.")
	var/mob/living/carbon/human/normal = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!tail.attach_limb(normal), "Хвост не пришивается телу с обычной анатомией.")

/datum/unit_test/supporting_tail/equipment/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/clothing/shoes/shoes = allocate(/obj/item/clothing/shoes)
	var/obj/item/socks = allocate(/obj/item)
	socks.slot_flags = ITEM_SLOT_SOCKS
	TEST_ASSERT(!human.equip_to_slot_if_possible(shoes, ITEM_SLOT_FEET, disable_warning = TRUE), "Обычное надевание обуви запрещено.")
	human.equip_to_slot(shoes, ITEM_SLOT_FEET)
	human.equip_to_slot(socks, ITEM_SLOT_SOCKS)
	TEST_ASSERT_NULL(human.shoes, "Низкоуровневое надевание не обходит запрет обуви.")
	TEST_ASSERT_NULL(human.w_socks, "Низкоуровневое надевание не обходит запрет носков.")

/datum/unit_test/supporting_tail/restraints/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/normal = allocate(/mob/living/carbon/human)
	var/obj/item/restraints/legcuffs/bola/bola = allocate(/obj/item/restraints/legcuffs/bola)
	var/obj/item/restraints/legcuffs/beartrap/trap = allocate(/obj/item/restraints/legcuffs/beartrap)
	TEST_ASSERT(!bola.can_apply_to_legs(human), "Бола не связывает один хвост.")
	TEST_ASSERT(bola.can_apply_to_legs(normal), "Бола по-прежнему подходит обычному человеку.")
	TEST_ASSERT(trap.can_apply_to_legs(human), "Капкан может зажать существующий хвост.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	TEST_ASSERT(!trap.can_apply_to_legs(human), "Без хвоста капкан не хватает пустую зону.")
	human.apply_status_effect(/datum/status_effect/bola_snared)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/bola_snared), "Прямое наложение статуса болы также отвергается.")

/datum/unit_test/supporting_tail/mod_without_boots/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	TEST_ASSERT(human.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK), "Костюм надевается на носителя хвоста.")
	var/obj/item/boots = mod.get_boots()
	TEST_ASSERT(!(boots in mod.get_deployable_parts()), "Ботинки исключены из развёртываемых частей.")
	for(var/obj/item/part as anything in mod.get_deployable_parts())
		TEST_ASSERT(mod.deploy(human, part), "Доступная часть костюма разворачивается: [part.type].")
	TEST_ASSERT(boots.loc != human && mod.is_mod_part(boots), "Ботинки остаются свёрнутыми и принадлежат костюму.")
	TEST_ASSERT(mod.can_activate() && mod.all_parts_deployed(), "Костюм готов к включению без ботинок.")
	mod.finish_activation(TRUE)
	TEST_ASSERT(mod.is_active(), "Костюм включается без ботинок.")
	var/total_slowdown = 0
	for(var/obj/item/clothing/mod_part/part as anything in mod.get_deployable_parts())
		total_slowdown += part.slowdown
	TEST_ASSERT(abs(total_slowdown - mod.slowdown_active) < 0.001, "Штраф скорости полностью распределён по доступным частям.")
	var/obj/item/mod/module/magboot/magnets = allocate(/obj/item/mod/module/magboot)
	mod.install(magnets)
	magnets.on_select()
	TEST_ASSERT(magnets.active, "Магниты включаются через корпус без ботинок.")
	TEST_ASSERT(HAS_TRAIT(human, TRAIT_NOSLIPWATER) && human.mob_negates_gravity(), "Хвост получает сцепление и опору в невесомости.")
	ADD_TRAIT(human, TRAIT_NOSLIPWATER, "ci_other_noslip")
	mod.finish_activation(FALSE)
	TEST_ASSERT(!magnets.active && !HAS_TRAIT(human, TRAIT_NEGATES_GRAVITY), "Отключение костюма снимает магнитное сцепление.")
	TEST_ASSERT(HAS_TRAIT(human, TRAIT_NOSLIPWATER), "Магниты не снимают защиту от скольжения другого источника.")
	REMOVE_TRAIT(human, TRAIT_NOSLIPWATER, "ci_other_noslip")
	mod.finish_activation(TRUE)
	magnets.on_activation()
	mod.unset_wearer()
	TEST_ASSERT(!magnets.active && !HAS_TRAIT(human, TRAIT_NEGATES_GRAVITY) && !HAS_TRAIT(human, TRAIT_NOSLIPWATER), "Смена носителя очищает эффекты магнитов.")

/datum/unit_test/supporting_tail/surgery/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	var/obj/item/surgical_drapes/drapes = allocate(/obj/item/surgical_drapes)
	surgeon.zone_selected = BODY_ZONE_PRECISE_GROIN
	human.Paralyze(30 SECONDS)
	var/datum/surgery/naga_tail_removal/removal = surgery_prototype(/datum/surgery/naga_tail_removal)
	var/datum/surgery/naga_tail_replacement/replacement = surgery_prototype(/datum/surgery/naga_tail_replacement)
	TEST_ASSERT(removal.can_start(surgeon, human, drapes), "Удаление предлагается при наличии хвоста.")
	TEST_ASSERT(!replacement.can_start(surgeon, human, drapes), "Второй хвост нельзя пришить поверх первого.")
	var/obj/item/bodypart/chest = human.get_bodypart(BODY_ZONE_CHEST)
	var/datum/surgery/operation = new /datum/surgery/naga_tail_removal(human, BODY_ZONE_PRECISE_GROIN, chest)
	allocated += operation
	var/datum/surgery_step/sever_naga_tail/sever = allocate(/datum/surgery_step/sever_naga_tail)
	TEST_ASSERT(sever.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, null, operation), "Хирург удаляет именно хвост.")
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_CHEST), chest, "Удаление хвоста не удаляет туловище.")
	TEST_ASSERT(!QDELETED(operation), "Отсоединение хвоста не удаляет операцию на пахе.")
	TEST_ASSERT(replacement.can_start(surgeon, human, drapes), "После удаления предлагается пересадка.")
	TEST_ASSERT(!removal.can_start(surgeon, human, drapes), "Повторно отсечь отсутствующий хвост нельзя.")
	var/obj/item/bodypart/l_leg/naga_tail/detached = locate() in get_turf(human)
	TEST_ASSERT_NOTNULL(detached, "Отделённый хвост появляется предметом на полу.")
	surgeon.put_in_active_hand(detached)
	var/datum/surgery_step/attach_naga_tail/attach = allocate(/datum/surgery_step/attach_naga_tail)
	TEST_ASSERT(attach.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, detached, operation), "Хирург может пришить хвост из руки.")
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_L_LEG), detached, "Пришит тот же хвост.")

/datum/unit_test/supporting_tail/surgery_bleeding/Run()
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	for(var/preexisting_bleeding in list(0, 5))
		var/mob/living/carbon/human/human = patient()
		var/obj/item/bodypart/chest = human.get_bodypart(BODY_ZONE_CHEST)
		chest.generic_bleedstacks = preexisting_bleeding
		var/datum/surgery/operation = new /datum/surgery/naga_tail_removal(human, BODY_ZONE_PRECISE_GROIN, chest)
		allocated += operation
		for(var/step_type in operation.steps)
			var/datum/surgery_step/step = allocate(step_type)
			if(istype(step, /datum/surgery_step/close/naga_tail_removal))
				TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_L_LEG), "Прижигание проводится после удаления хвоста.")
				TEST_ASSERT_EQUAL(chest.generic_bleedstacks, preexisting_bleeding + 4, "До закрытия разрез на оставшемся туловище ещё кровоточит.")
			TEST_ASSERT(step.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, null, operation), "Этап удаления хвоста [step_type] завершается.")
		TEST_ASSERT_EQUAL(chest.generic_bleedstacks, preexisting_bleeding, "Закрытие устраняет кровотечение от операции, сохраняя прежние источники.")
		if(!preexisting_bleeding)
			TEST_ASSERT_EQUAL(chest.get_bleed_rate(), 0, "Завершённая операция не оставляет кровотечение из туловища.")
			TEST_ASSERT_NULL(chest.bleed_overlay_icon, "После закрытия исчезает оверлей хирургического кровотечения.")
		var/obj/item/bodypart/l_leg/naga_tail/tail = locate() in get_turf(human)
		TEST_ASSERT_NOTNULL(tail, "Удалённый хвост доступен для обратной пересадки.")
		surgeon.put_in_active_hand(tail)
		var/datum/surgery/replacement = new /datum/surgery/naga_tail_replacement(human, BODY_ZONE_PRECISE_GROIN, chest)
		allocated += replacement
		for(var/step_type in replacement.steps)
			var/datum/surgery_step/step = allocate(step_type)
			TEST_ASSERT(step.success(surgeon, human, BODY_ZONE_PRECISE_GROIN, tail, replacement), "Этап пересадки [step_type] завершается.")
		TEST_ASSERT_EQUAL(chest.generic_bleedstacks, preexisting_bleeding, "Пересадка тоже закрывает свой разрез, сохраняя прежнее кровотечение.")

/datum/unit_test/supporting_tail/surgery_underwear/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/underwear = allocate(/obj/item/clothing)
	underwear.body_parts_covered = CHEST | GROIN | LEGS | ARMS | HANDS | FEET
	human.w_underwear = underwear
	human.w_shirt = underwear
	human.w_socks = underwear
	human.wrists = underwear
	for(var/zone in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_FOOT))
		TEST_ASSERT(get_location_accessible(human, zone), "Бельё, майка, носки и часы не закрывают хирургический доступ: [zone].")
	human.wrists = null
	human.w_socks = null
	human.w_shirt = null
	human.w_underwear = null
	human.w_uniform = underwear
	TEST_ASSERT(!get_location_accessible(human, BODY_ZONE_PRECISE_GROIN), "Обычная форма продолжает закрывать пах.")

/datum/unit_test/supporting_tail/medical_scan/Run()
	var/mob/living/carbon/human/human = patient()
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/list/data = medical_scan_results(doctor, human, TRUE)
	var/list/features = data["innateFeatures"]
	TEST_ASSERT_EQUAL(length(features), 1, "В сканер попадает применённая особенность.")
	var/list/feature = features[1]
	TEST_ASSERT_EQUAL(feature["id"], INNATE_NAGA_TAIL, "Сканер использует стабильный идентификатор.")
	var/datum/innate_feature/definition = GLOB.innate_features[INNATE_NAGA_TAIL]
	TEST_ASSERT_EQUAL(feature["tooltip"], definition.medical_tooltip, "Сканер передаёт медицинскую подсказку из определения особенности.")
	TEST_ASSERT_EQUAL(length(data["damageLocalization"]), 0, "Целый хвост не создаёт ложные сообщения об отсутствующих конечностях.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	data = medical_scan_results(doctor, human, TRUE)
	var/list/localization = data["damageLocalization"]
	TEST_ASSERT_EQUAL(length(localization), 1, "Сканер не дублирует отсутствующий хвост.")
	var/list/missing = localization[1]
	TEST_ASSERT(missing["missing"], "Сканер сообщает о потере конечности.")
	TEST_ASSERT_EQUAL(length(data["innateFeatures"]), 1, "Потеря хвоста не скрывает врождённую анатомию.")

/datum/unit_test/supporting_tail/preferences_requirements/Run()
	var/datum/preferences/prefs = preferences()
	var/datum/innate_feature/tail = GLOB.innate_features[INNATE_NAGA_TAIL]
	TEST_ASSERT(tail.available(prefs), "Подходящее тело с естественными ногами допускает особенность.")
	prefs.features["taur"] = "Tentacle"
	TEST_ASSERT(!tail.available(prefs), "Другой змеиный тавр не проходит проверку типа.")
	prefs.features["taur"] = "Naga"
	prefs.be_random_body = TRUE
	TEST_ASSERT(!tail.available(prefs), "Случайная внешность несовместима с требованием тела.")
	prefs.be_random_body = FALSE
	prefs.modified_limbs[BODY_ZONE_R_LEG] = list(LOADOUT_LIMB_AMPUTATED)
	TEST_ASSERT(!tail.available(prefs), "Ампутация в настройках несовместима с исходной анатомией.")
	prefs.modified_limbs = list()
	prefs.all_quirks = list(/datum/quirk/hard_soles::name)
	TEST_ASSERT(!tail.available(prefs), "Отдельные твёрдые ступни несовместимы с хвостом.")

/datum/unit_test/supporting_tail/preferences_primary_and_cost/Run()
	var/datum/preferences/prefs = preferences()
	var/datum/innate_feature/first = feature("ci_first", TRUE)
	var/datum/innate_feature/second = feature("ci_second", TRUE)
	var/datum/innate_feature/extra = feature("ci_extra", FALSE)
	prefs.innate_features = list(first.id)
	TEST_ASSERT(!second.available(prefs), "Нельзя выбрать вторую основную особенность.")
	TEST_ASSERT(extra.available(prefs), "Основная особенность не запрещает дополнительную.")
	var/balance = prefs.quirk_balance()
	extra.quirk_cost = 2
	prefs.innate_features += extra.id
	TEST_ASSERT_EQUAL(prefs.quirk_balance(), balance - 2, "Стоимость особенности вычитается из общего бюджета.")
	prefs.innate_features = list(first.id, second.id, extra.id, extra.id, "unknown", 123)
	prefs.sanitize_innate_features()
	TEST_ASSERT_EQUAL(length(prefs.innate_features), 2, "Санитизация убирает вторую основную, дубли и неизвестные значения.")
	TEST_ASSERT((first.id in prefs.innate_features) && (extra.id in prefs.innate_features), "Первая основная и дополнительные сохраняются.")

/datum/unit_test/supporting_tail/preferences_save/Run()
	var/datum/preferences/prefs = preferences()
	var/file_path = "data/unit_tests/[unit_test_shard_subdir()]supporting_tail_[REF(src)].sav"
	save_paths += file_path
	prefs.path = file_path
	prefs.innate_features = list(INNATE_NAGA_TAIL)
	TEST_ASSERT(prefs.save_character(bypass_cooldown = TRUE, silent = TRUE), "Настройки сохраняются в отдельный файл теста.")
	prefs.innate_features = list()
	TEST_ASSERT(prefs.load_character(bypass_cooldown = TRUE), "Сохранённый слот загружается.")
	TEST_ASSERT(INNATE_NAGA_TAIL in prefs.innate_features, "Особенность переживает сохранение и загрузку.")

/datum/unit_test/supporting_tail/colors_and_item/Run()
	var/mob/living/carbon/human/human = patient()
	human.dna.features["color_scheme"] = ADVANCED_CHARACTER_COLORING
	human.dna.features["taur_primary"] = "112233"
	human.dna.features["taur_secondary"] = "445566"
	human.dna.features["taur_tertiary"] = "778899"
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list["Naga"]
	TEST_ASSERT_EQUAL(taur.get_severed_color(human, MUTCOLORS), "#112233", "Красный канал выбирает основную палитру хвоста.")
	TEST_ASSERT_EQUAL(taur.get_severed_color(human, MUTCOLORS2), "#445566", "Второй источник выбирает второй цвет.")
	TEST_ASSERT_EQUAL(taur.get_severed_color(human, MUTCOLORS3), "#778899", "Третий источник выбирает третий цвет.")
	TEST_ASSERT_NULL(taur.get_severed_color(human, NONE), "Статичный оверлей не перекрашивается.")
	var/obj/item/bodypart/l_leg/naga_tail/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/list/old_color = tail.tail_item_color
	TEST_ASSERT(islist(old_color), "Матричная окраска предмета хранится списком коэффициентов.")
	old_color = old_color.Copy()
	TEST_ASSERT_EQUAL(old_color[1], 0x11 / 255, "Отсечение снимает актуальный цвет даже без обновления кэша конечностей.")
	human.dna.features["taur_primary"] = "FFFFFF"
	TEST_ASSERT_EQUAL(tail.tail_item_color[1], old_color[1], "Предмет хранит снимок цвета донора.")
	TEST_ASSERT_NULL(tail.tail_item_extra_color, "Срез предмета сохраняет исходные цвета.")
	var/mob/living/carbon/human/recipient = patient()
	recipient.get_bodypart(BODY_ZONE_L_LEG).drop_limb()
	recipient.dna.features["color_scheme"] = ADVANCED_CHARACTER_COLORING
	recipient.dna.features["taur"] = "RadDog Naga (Hyper)"
	recipient.dna.features["taur_primary"] = "ABCDEF"
	recipient.dna.features["taur_secondary"] = "123456"
	recipient.dna.features["taur_tertiary"] = "789ABC"
	TEST_ASSERT(tail.attach_limb(recipient), "Отделённый хвост пересаживается другому персонажу.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "RadDog Naga (Hyper)", "Сохраняется форма владельца вместо донорской.")
	tail.update_limb(FALSE)
	recipient.dna.features["taur_primary"] = "FEDCBA"
	tail.drop_limb()
	TEST_ASSERT_EQUAL(tail.taur_style, "RadDog Naga (Hyper)", "Повторное отсечение сохраняет новую форму.")
	TEST_ASSERT_EQUAL(tail.tail_palette[1], "FEDCBA", "Повторное отсечение заново копирует палитру владельца.")
	TEST_ASSERT_EQUAL(tail.tail_item_color[1], 0xFE / 255, "Предмет отображает новый цвет, изменённый после пересадки.")

/datum/unit_test/supporting_tail/asset_states/Run()
	for(var/style in list("Naga", "Naga (coiled)", "Naga, Fat", "RadDog Naga (Hyper)"))
		var/datum/sprite_accessory/taur/variant = GLOB.taur_list[style]
		var/list/body_states = icon_states(variant.icon)
		TEST_ASSERT("m_taur_[variant.severed_body_state]_ADJUP" in body_states, "Основной атлас хвоста содержит верхний слой культи для [style].")
		TEST_ASSERT("m_taur_[variant.severed_body_state]_FRONT" in body_states, "Основной атлас хвоста содержит передний слой культи для [style].")
		TEST_ASSERT("m_taur_extra_[variant.severed_body_extra_state]_FRONT" in body_states, "Основной атлас хвоста содержит срез для [style].")
		for(var/layer in list("ADJUP", "FRONT"))
			TEST_ASSERT("m_taur_extra_[variant.severed_body_extra_matrix_state]_[layer]" in body_states, "Атлас содержит матричный срез [style] для слоя [layer].")
			TEST_ASSERT("m_taur_extra_[variant.severed_body_extra_slime_state]_[layer]" in body_states, "Атлас содержит слаймовый срез [style] для слоя [layer].")
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list["Naga"]
	var/list/item_states = icon_states(taur.severed_item_icon)
	TEST_ASSERT(taur.severed_item_state in item_states, "В DMI существует подключённая основа предмета.")
	TEST_ASSERT(taur.severed_item_extra_state in item_states, "В DMI существует подключённый срез.")
	TEST_ASSERT(taur.severed_item_extra_matrix_state in item_states, "В DMI существует матричный срез предмета.")
	TEST_ASSERT(taur.severed_item_extra_slime_state in item_states, "В DMI существует слаймовый срез предмета.")
	var/list/doll_states = icon_states(NAGA_DOLL_ICON)
	for(var/state in list("healthdoll_OVERLAY", "healthdoll_DEAD", "tail1", "tail2", "tail3", "tail4", "tail5", "tail6", "tail7"))
		TEST_ASSERT(state in doll_states, "Атлас куклы содержит состояние [state].")

/datum/unit_test/supporting_tail/matrixed_severed_overlays/Run()
	for(var/style in list("Naga", "Naga (coiled)", "Naga, Fat", "RadDog Naga (Hyper)"))
		for(var/species_type in list(/datum/species/human, /datum/species/jelly/roundstartslime, /datum/species/mammal/synthetic))
			var/mob/living/carbon/human/human = patient(style)
			human.set_species(species_type)
			human.dna.features["color_scheme"] = ADVANCED_CHARACTER_COLORING
			human.dna.features["taur_primary"] = "12AB34"
			human.dna.features["taur_secondary"] = "CD56EF"
			human.dna.features["taur_tertiary"] = "789ABC"
			var/datum/sprite_accessory/taur/taur = GLOB.taur_list[style]
			var/obj/item/bodypart/l_leg/naga_tail/tail = human.get_bodypart(BODY_ZONE_L_LEG)
			tail.drop_limb()
			var/matrixed = species_type != /datum/species/human
			var/slime = species_type == /datum/species/jelly/roundstartslime
			var/expected_item_state = slime ? taur.severed_item_extra_slime_state : (matrixed ? taur.severed_item_extra_matrix_state : taur.severed_item_extra_state)
			TEST_ASSERT_EQUAL(tail.tail_item_extra_state, expected_item_state, "Вид владельца выбирает срез предмета: [style], [species_type].")
			if(matrixed)
				TEST_ASSERT_EQUAL(json_encode(tail.tail_item_extra_color), json_encode(tail.tail_item_color), "Срез предмета использует всю матрицу основной палитры.")
			else
				TEST_ASSERT_NULL(tail.tail_item_extra_color, "У органического владельца мясной срез остаётся фиксированным.")
			human.update_mutant_bodyparts()
			var/mutable_appearance/base_overlay
			var/mutable_appearance/cut_overlay
			var/expected_state = slime ? taur.severed_body_extra_slime_state : (matrixed ? taur.severed_body_extra_matrix_state : taur.severed_body_extra_state)
			for(var/mutable_appearance/part as anything in human.overlays_standing[BODY_FRONT_LAYER])
				if(part.icon_state == "m_taur_[taur.severed_body_state]_FRONT")
					base_overlay = part
				if(part.icon_state == "m_taur_extra_[expected_state]_FRONT")
					cut_overlay = part
			TEST_ASSERT_NOTNULL(base_overlay, "После отсечения отображается основа культи.")
			TEST_ASSERT_NOTNULL(cut_overlay, "После отсечения отображается срез подходящего типа.")
			if(matrixed)
				TEST_ASSERT_EQUAL(json_encode(cut_overlay.color), json_encode(base_overlay.color), "Срез культи использует ту же окраску, что и её основа.")
			else
				TEST_ASSERT_NULL(cut_overlay.color, "У органической культи сохраняются исходные цвета среза.")

/datum/unit_test/supporting_tail/matrixed_cut_transplant/Run()
	var/mob/living/carbon/human/donor = patient()
	donor.set_species(/datum/species/jelly/roundstartslime)
	donor.dna.features["color_scheme"] = ADVANCED_CHARACTER_COLORING
	donor.dna.features["taur_primary"] = "112233"
	donor.dna.features["taur_secondary"] = "445566"
	var/obj/item/bodypart/l_leg/naga_tail/tail = donor.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list["Naga"]
	TEST_ASSERT_EQUAL(tail.tail_item_extra_state, taur.severed_item_extra_slime_state, "Отделённый хвост слайма получает срез без кости.")
	donor.dna.features["taur_primary"] = "FFFFFF"
	donor.set_species(/datum/species/human)
	TEST_ASSERT_EQUAL(tail.tail_item_extra_color[1], 0x11 / 255, "Смена вида и цвета бывшего владельца не перекрашивает предмет на полу.")
	var/mob/living/carbon/human/recipient = patient()
	recipient.get_bodypart(BODY_ZONE_L_LEG).drop_limb()
	TEST_ASSERT(tail.attach_limb(recipient), "Хвост слайма пересаживается органическому владельцу.")
	TEST_ASSERT_EQUAL(tail.tail_item_extra_state, taur.severed_item_extra_state, "Пересадка органическому владельцу возвращает мясной срез.")
	TEST_ASSERT_NULL(tail.tail_item_extra_color, "После пересадки не остаётся старая матрица среза.")
	recipient.set_species(/datum/species/mammal/synthetic)
	tail.drop_limb()
	TEST_ASSERT_EQUAL(tail.tail_item_extra_state, taur.severed_item_extra_matrix_state, "Повторное отсечение учитывает новый синтетический вид владельца.")
	TEST_ASSERT_EQUAL(json_encode(tail.tail_item_extra_color), json_encode(tail.tail_item_color), "Повторное отсечение сохраняет актуальную матрицу среза.")

/datum/unit_test/supporting_tail/proc/taur_states(mob/living/carbon/human/human)
	var/list/states = list()
	for(var/list/layer as anything in human.overlays_standing)
		if(!islist(layer))
			continue
		for(var/mutable_appearance/part as anything in layer)
			if(findtext(part.icon_state, "taur_"))
				states += part.icon_state
	return states

/datum/unit_test/supporting_tail/legacy_overlays/Run()
	saved_taurs = GLOB.taur_list
	GLOB.taur_list = saved_taurs.Copy()
	saved_taur_reference = GLOB.mutant_reference_list["taur"]
	GLOB.mutant_reference_list["taur"] = GLOB.taur_list
	var/datum/sprite_accessory/taur/naga/legacy = allocate(/datum/sprite_accessory/taur/naga)
	legacy.severed_body_state = null
	legacy.extra = TRUE
	legacy.extra2 = TRUE
	GLOB.taur_list["Naga"] = legacy
	var/mob/living/carbon/human/human = patient()
	var/list/before = taur_states(human)
	TEST_ASSERT(length(before) >= 3, "До удаления есть основной и дополнительные слои тавра.")
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/list/after = taur_states(human)
	TEST_ASSERT_EQUAL(jointext(after, ";"), jointext(before, ";"), "Без severed_body_state основной спрайт, extra и extra2 сохраняются.")

/datum/unit_test/supporting_tail/delete_attached/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	qdel(tail)
	TEST_ASSERT_NULL(human.get_bodypart(BODY_ZONE_R_LEG), "Удаление прикреплённого хвоста не оставляет ссылку в bodyparts.")
	TEST_ASSERT(!HAS_TRAIT_FROM(human, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL), "Destroy снимает принадлежащий хвосту трейт.")
	TEST_ASSERT_EQUAL(human.get_num_supporting_limbs(), 0, "Destroy пересчитывает потерю опоры.")

/datum/unit_test/supporting_tail/preferences_copy_keeps_injuries/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/bodypart/tail = human.get_bodypart(BODY_ZONE_L_LEG)
	tail.receive_damage(brute = 15, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	var/datum/preferences/prefs = preferences()
	prefs.innate_features = list(INNATE_NAGA_TAIL)
	prefs.copy_to(human, icon_updates = FALSE, roundstart_checks = FALSE)
	TEST_ASSERT_EQUAL(human.get_bodypart(BODY_ZONE_L_LEG), tail, "Применение префов не пересоздаёт хвост через временно пустую ДНК.")
	TEST_ASSERT_EQUAL(tail.brute_dam, 15, "Применение префов не лечит хвост.")

/datum/unit_test/supporting_tail/preferences_incompatibilities/Run()
	var/datum/preferences/prefs = preferences()
	var/datum/innate_feature/first = feature("ci_a")
	var/datum/innate_feature/second = feature("ci_b")
	second.incompatible_features = list(first.id)
	prefs.innate_features = list(first.id)
	TEST_ASSERT(!second.available(prefs), "Несовместимость особенностей проверяется на сервере.")
	prefs.innate_features = list()
	TEST_ASSERT(second.available(prefs), "Удаление конфликта восстанавливает доступность.")
	second.required_quirks = list(/datum/quirk/hard_soles::name)
	TEST_ASSERT(!second.available(prefs), "Обязательный квирк проверяется на сервере.")
	prefs.all_quirks += /datum/quirk/hard_soles::name
	TEST_ASSERT(second.available(prefs), "Наличие обязательного квирка открывает особенность.")
	var/list/selection = list()
	for(var/index in 1 to 12)
		var/datum/innate_feature/additional = feature("ci_extra_[index]")
		selection += additional.id
	prefs.innate_features = selection
	prefs.sanitize_innate_features()
	TEST_ASSERT_EQUAL(length(prefs.innate_features), 12, "Дополнительные особенности не ограничены количеством.")

/datum/unit_test/supporting_tail/mod_normal_wearer/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	human.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK)
	TEST_ASSERT(mod.get_boots() in mod.get_deployable_parts(), "Для обычного носителя ботинки входят в набор частей.")
	for(var/obj/item/part as anything in mod.get_deployable_parts())
		if(part == mod.get_boots())
			continue
		mod.deploy(human, part)
	TEST_ASSERT(!mod.all_parts_deployed(), "Обычный носитель не может считать костюм полностью развёрнутым без ботинок.")
	TEST_ASSERT(mod.deploy(human, mod.get_boots()), "Обычный носитель разворачивает ботинки.")
	TEST_ASSERT(mod.all_parts_deployed(), "После ботинок обычный костюм готов.")

/datum/unit_test/supporting_tail/preferences_mobility/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.mind_initialize()
	var/datum/preferences/prefs = preferences()
	prefs.innate_features = list(INNATE_NAGA_TAIL)
	prefs.copy_to(human, icon_updates = FALSE, roundstart_checks = FALSE)
	TEST_ASSERT(HAS_TRAIT(human, TRAIT_NAGA_ANATOMY) && HAS_MIND_TRAIT(human, TRAIT_NAGA_LOCOMOTION), "Полное применение настроек даёт тело и моторику хвоста.")
	TEST_ASSERT(!human.resting && CHECK_MOBILITY(human, MOBILITY_STAND), "Полный copy_to не укладывает персонажа при включении хвоста.")
	prefs.innate_features = list()
	prefs.copy_to(human, icon_updates = FALSE, roundstart_checks = FALSE)
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_NAGA_ANATOMY) && human.get_num_legs() == 2, "Повторное применение возвращает ноги.")
	TEST_ASSERT(!human.resting && CHECK_MOBILITY(human, MOBILITY_STAND), "Снятие хвоста через полный copy_to тоже не вызывает падения.")

/datum/unit_test/supporting_tail/appearance_fallback/Run()
	var/mob/living/carbon/human/donor = patient("Naga, Fat")
	donor.dna.features["color_scheme"] = ADVANCED_CHARACTER_COLORING
	donor.dna.features["taur_primary"] = "123456"
	donor.dna.features["taur_secondary"] = "654321"
	donor.dna.features["taur_tertiary"] = "ABCDEF"
	var/obj/item/bodypart/l_leg/naga_tail/tail = donor.get_bodypart(BODY_ZONE_L_LEG)
	tail.drop_limb()
	var/mob/living/carbon/human/recipient = patient()
	recipient.get_bodypart(BODY_ZONE_L_LEG).drop_limb()
	recipient.dna.features["taur"] = "None"
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list["Naga"]
	for(var/key in list("mcolor", "mcolor2", "mcolor3", "taur_primary", "taur_secondary", "taur_tertiary"))
		recipient.dna.features -= key
	TEST_ASSERT(tail.attach_limb(recipient), "Хвост пришивается к кукле без настроенной внешности хвоста.")
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "Naga, Fat", "При отсутствии формы используется снимок хвоста.")
	TEST_ASSERT_EQUAL(taur.get_tail_color(recipient.dna.features, 1), "123456", "При отсутствии цветов используется снимок палитры.")
	tail.drop_limb()
	recipient.dna.features["taur"] = "None"
	for(var/key in list("mcolor", "mcolor2", "mcolor3", "taur_primary", "taur_secondary", "taur_tertiary"))
		recipient.dna.features -= key
	var/list/preferred_features = list("taur" = "RadDog Naga (Hyper)", "color_scheme" = ADVANCED_CHARACTER_COLORING, "taur_primary" = "AABBCC", "taur_secondary" = "DDEEFF", "taur_tertiary" = "112233")
	tail.adopt_owner_appearance(recipient, preferred_features)
	TEST_ASSERT_EQUAL(recipient.dna.features["taur"], "RadDog Naga (Hyper)", "Совместимая форма из префов имеет приоритет над снимком хвоста.")
	TEST_ASSERT_EQUAL(taur.get_tail_color(recipient.dna.features, 1), "AABBCC", "Палитра из префов заполняет отсутствующий цвет куклы.")

/datum/unit_test/supporting_tail/mod_waddle/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	human.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK)
	for(var/obj/item/part as anything in mod.get_deployable_parts())
		mod.deploy(human, part)
	var/obj/item/mod/module/waddle/waddle = allocate(/obj/item/mod/module/waddle)
	mod.install(waddle)
	mod.finish_activation(TRUE)
	TEST_ASSERT(waddle.active && HAS_TRAIT(human, TRAIT_WADDLING), "Waddle запускается вместе с корпусом без ботинок.")
	TEST_ASSERT_NOTNULL(waddle.squeak_component, "Звук подключён к развёрнутому корпусу костюма.")
	ADD_TRAIT(human, TRAIT_WADDLING, "ci_other_waddle")
	mod.finish_activation(FALSE)
	TEST_ASSERT(!waddle.active && isnull(waddle.squeak_component), "Отключение костюма убирает его звук и состояние модуля.")
	TEST_ASSERT(HAS_TRAIT(human, TRAIT_WADDLING) && human.GetComponent(/datum/component/waddling), "Сохраняется походка от другого источника.")
	REMOVE_TRAIT(human, TRAIT_WADDLING, "ci_other_waddle")
	mod.finish_activation(TRUE)
	mod.unset_wearer()
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_WADDLING) && !human.GetComponent(/datum/component/waddling), "Смена носителя очищает походку костюма.")

/datum/unit_test/supporting_tail/mod_jump/Run()
	for(var/module_type in list(/obj/item/mod/module/jump_jet, /obj/item/mod/module/jump_jet/ninja, /obj/item/mod/module/jump_jet/inteq))
		var/mob/living/carbon/human/human = patient()
		var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
		human.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK)
		for(var/obj/item/part as anything in mod.get_deployable_parts())
			mod.deploy(human, part)
		var/obj/item/mod/module/jump_jet/jump = allocate(module_type)
		mod.install(jump)
		mod.finish_activation(TRUE)
		TEST_ASSERT_EQUAL(jump.required_modpart, mod.get_mod_part_by_index(MOD_PART_CHEST), "Прыжковый модуль [module_type] использует корпус.")
		TEST_ASSERT(jump.check_required_modpart(), "Прыжок доступен наге без развёрнутых ботинок.")
		human.get_bodypart(BODY_ZONE_L_LEG).drop_limb()
		TEST_ASSERT(!jump.on_use(), "Потеря хвоста запрещает прыжок.")
		TEST_ASSERT(COOLDOWN_FINISHED(jump, cooldown_current_timer), "Отказ без опоры не запускает перезарядку.")
		mod.finish_activation(FALSE)

/datum/unit_test/supporting_tail/shibola_payloads/Run()
	var/mob/living/carbon/human/human = patient()
	var/obj/item/shibola/shibola = allocate(/obj/item/shibola)
	TEST_ASSERT(!shibola.can_apply_payload_to(human), "Пустая шибола не подсекает хвост.")
	var/obj/item/restraints/bondage_rope/rope = allocate(/obj/item/restraints/bondage_rope)
	shibola.payload = rope
	rope.rope_target = ROPE_TARGET_LEGS
	TEST_ASSERT(!shibola.can_apply_payload_to(human), "Шибола не связывает отсутствующие ноги.")
	rope.rope_target = ROPE_TARGET_HANDS_IN_FRONT
	TEST_ASSERT(shibola.can_apply_payload_to(human), "Шибола может доставить верёвку для рук.")
	shibola.payload = allocate(/obj/item/clothing/mask)
	TEST_ASSERT(shibola.can_apply_payload_to(human), "Маска в шиболе совместима с хвостом.")
	shibola.payload = allocate(/obj/item/clothing/shoes)
	TEST_ASSERT(!shibola.can_apply_payload_to(human), "Обувь в шиболе по-прежнему не подходит наге.")
	shibola.payload = null
