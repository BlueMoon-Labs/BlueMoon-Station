/// Сработавшая защита называет цели предмет и сообщает об этом не чаще раза в окно; захват и старая хватка тоже сообщают.
/datum/unit_test/heretic_ward_notice/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	TEST_ASSERT(victim.put_in_active_hand(rod), "Цель держит нулевой жезл.")
	var/victim_key = "victim [REF(victim)]"
	GLOB.heretic_ward_notice_times -= victim_key
	TEST_ASSERT(!heretic_can_affect(user, victim), "Жезл отводит чары.")
	TEST_ASSERT_EQUAL(GLOB.heretic_ward_notice_times[victim_key], world.time, "Цель узнаёт о сработавшей защите.")
	GLOB.heretic_ward_notice_times[victim_key] = world.time - 1
	TEST_ASSERT(!heretic_can_affect(user, victim, chargecost = 0), "Проба тоже видит защиту.")
	TEST_ASSERT_EQUAL(GLOB.heretic_ward_notice_times[victim_key], world.time - 1, "Повтор внутри окна не шлёт второго сообщения.")
	TEST_ASSERT_NULL(heretic_ward_notice(user, victim, rod), "Окно глушит и прямой вызов.")
	GLOB.heretic_ward_notice_times[victim_key] = world.time - HERETIC_WARD_NOTICE_COOLDOWN
	var/notice = heretic_ward_notice(user, victim, rod)
	TEST_ASSERT(findtext(notice, rod.name), "Сообщение называет предмет защиты: [notice]")
	GLOB.heretic_ward_notice_times -= victim_key
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "echo"), "защищена от магии"), "Захват отказывает защищённой цели.")
	TEST_ASSERT_EQUAL(GLOB.heretic_ward_notice_times[victim_key], world.time, "Отказ захвата сообщается цели.")
	GLOB.heretic_ward_notice_times -= victim_key
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(victim, user, TRUE)
	TEST_ASSERT_EQUAL(GLOB.heretic_ward_notice_times[victim_key], world.time, "Отбитая хватка старых путей сообщается цели.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Отбитая хватка не ранит.")
	victim.dropItemToGround(rod)
	GLOB.heretic_ward_notice_times -= victim_key
	TEST_ASSERT(heretic_can_affect(user, victim), "Без жезла чары проходят.")
	TEST_ASSERT_NULL(GLOB.heretic_ward_notice_times[victim_key], "Без защиты сообщения нет.")

/// Шапочка из фольги защищает только от ментальных чар: обычные чары, течение и захваты её не замечают, маска безумия отступает.
/datum/unit_test/heretic_tinfoil_mental_only/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(user, WEST))
	var/obj/item/clothing/head/foilhat/hat = allocate(/obj/item/clothing/head/foilhat)
	TEST_ASSERT(victim.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD), "Шапочка надета.")
	var/datum/component/anti_magic/psychic = hat.GetComponent(/datum/component/anti_magic)
	TEST_ASSERT(heretic_can_affect(user, victim), "Обычные чары шапочку не замечают.")
	TEST_ASSERT_NULL(heretic_capture_block_reason(user, victim, "echo"), "Захват шапочку не замечает.")
	TEST_ASSERT(!heretic_can_affect(user, victim, chargecost = 0, tinfoil = TRUE), "Ментальные чары шапочка отводит.")
	TEST_ASSERT_EQUAL(psychic.charges, 6, "Ни обычные чары, ни проба не тратят заряды шапочки.")
	victim.set_resting(TRUE, TRUE)
	TEST_ASSERT(tide.current_carries(victim), "Течение несёт лежащего в шапочке.")
	victim.set_resting(FALSE, TRUE)
	var/obj/item/clothing/mask/gas/void_mask/mask = allocate(/obj/item/clothing/mask/gas/void_mask)
	TEST_ASSERT(user.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Еретик надел маску безумия.")
	mask.process(1)
	TEST_ASSERT(HAS_TRAIT(bystander, TRAIT_VOID_MASK_IMMUNE), "Маска задевает человека без защиты.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_VOID_MASK_IMMUNE), "Шапочка отводит маску безумия.")
	TEST_ASSERT_EQUAL(victim.hallucination, 0, "Под шапочкой нет галлюцинаций.")

/// Скользкая кровь не роняет цель с нулевым жезлом.
/datum/unit_test/heretic_antimagic_blood_slick/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/slick_turf = locate(user.x + 2, user.y, user.z)
	heretic_test_area(slick_turf, /area/unit_test_blood_slick)
	allocate(/obj/effect/heretic_blood_slick, slick_turf, user, EAST)
	var/mob/living/carbon/human/runner = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y, user.z))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	runner.put_in_active_hand(rod)
	runner.m_intent = MOVE_INTENT_RUN
	runner.combat_flags |= COMBAT_FLAG_SPRINT_ACTIVE
	runner.forceMove(slick_turf)
	TEST_ASSERT(!heretic_capture_downed(runner), "Защищённый бегун не скользит.")
	var/mob/living/carbon/human/plain = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 1, user.z))
	plain.m_intent = MOVE_INTENT_RUN
	plain.combat_flags |= COMBAT_FLAG_SPRINT_ACTIVE
	plain.forceMove(slick_turf)
	TEST_ASSERT(heretic_capture_downed(plain), "Бегун без защиты падает.")

/// Чтение крови не ведёт к защищённому владельцу, а защита, взятая по дороге, обрывает след.
/datum/unit_test/heretic_antimagic_blood_trail/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/quarry = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y, origin.z))
	quarry.dna.unique_enzymes = "antimagic trail quarry"
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	quarry.put_in_active_hand(rod)
	var/obj/effect/decal/cleanable/blood/stain = blood_tide_stain(get_step(user, EAST), donor = quarry.dna.unique_enzymes)
	blood.read_blood(user, stain)
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_blood_trail), "Кровь защищённого не даёт следа.")
	quarry.dropItemToGround(rod)
	var/datum/status_effect/heretic_blood_trail/trail = user.apply_status_effect(/datum/status_effect/heretic_blood_trail, quarry)
	TEST_ASSERT_NOTNULL(trail, "След на незащищённого берётся.")
	quarry.put_in_active_hand(rod)
	trail.tick()
	TEST_ASSERT(QDELETED(trail), "Защита обрывает след.")

/// Нить Кровопускания не подтягивает защищённую цель, даже если еретик отходит.
/datum/unit_test/heretic_antimagic_blood_drain_pull/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/far_spot = locate(start.x + 4, start.y, start.z)
	var/mob/living/carbon/human/victim = blood_debtor(blood, far_spot)
	TEST_ASSERT(blood.drain(user, victim), "Кровопускание начато.")
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	drain.start_channel()
	TEST_ASSERT(!QDELETED(drain) && drain.channel_started, "Канал идёт.")
	victim.forceMove(far_spot)
	victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	drain.pull_close()
	TEST_ASSERT_EQUAL(get_turf(victim), far_spot, "Защищённую цель нить не тянет.")

/// Натянуть жилу и Связать по защищённой цели сжигают её заряд защиты и называют еретику причину.
/datum/unit_test/heretic_antimagic_blood_spells/Run()
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(run_loc_floor_bottom_left)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_lance)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y, user.z))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(blood.release(user, victim), "Попытка связи засчитывается.")
	TEST_ASSERT(findtext(blood.ability_failure, "защищ"), "Еретик узнаёт, что связь отбита: [blood.ability_failure]")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), "Связь не легла.")
	TEST_ASSERT(blood.lance(user, victim), "Попытка жилы засчитывается.")
	TEST_ASSERT(findtext(blood.ability_failure, "защищ"), "Еретик узнаёт, что жила отбита: [blood.ability_failure]")
	TEST_ASSERT_EQUAL(protection.charges, 3, "Каждая отбитая попытка сжигает один заряд.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Защищённый не ранен.")

/// Защита, взятая во время Колыбельной или захлёба, не даёт им усыпить цель в конце.
/datum/unit_test/heretic_antimagic_capture_endings/Run()
	var/datum/antagonist/heretic/singer = allocate_heretic()
	singer.selected_path = PATH_ECHO
	singer.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	singer.gain_knowledge(/datum/eldritch_knowledge/spell/echo_lullaby)
	var/mob/living/carbon/human/echo_user = singer.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = singer.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human, get_step(echo_user, EAST))
	echo.set_ringing(sleeper)
	echo.combat_resource = 4
	TEST_ASSERT(echo.lullaby(echo_user, sleeper), "Колыбельная начата.")
	var/datum/status_effect/heretic_echo_lullaby/lullaby = sleeper.has_status_effect(/datum/status_effect/heretic_echo_lullaby)
	sleeper.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	lullaby.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(lullaby, 1 SECONDS), "Колыбельная кончилась.")
	TEST_ASSERT(!sleeper.IsSleeping(), "Защищённая к концу Колыбельной цель не засыпает.")
	var/datum/antagonist/heretic/drowner = allocate_heretic(locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z))
	drowner.selected_path = PATH_TIDE
	drowner.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/tide_user = drowner.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = drowner.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/pool = get_step(tide_user, EAST)
	var/mob/living/carbon/human/swimmer = allocate(/mob/living/carbon/human, pool)
	tide.wet_floor(pool)
	var/datum/status_effect/heretic_tide_drowning/drowning = swimmer.apply_status_effect(/datum/status_effect/heretic_tide_drowning, tide)
	TEST_ASSERT_NOTNULL(drowning, "Цель захлёбывается.")
	swimmer.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	drowning.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(drowning, 1 SECONDS), "Захлёб кончился.")
	TEST_ASSERT(!swimmer.IsUnconscious(), "Защищённая к концу захлёба цель не теряет сознание.")

/// Воронка списывает с защищённой цели не больше одного заряда за всё время жизни.
/datum/unit_test/heretic_antimagic_tide_well_charges/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(center, WEST))
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_well)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide.combat_resource = 4
	TEST_ASSERT(tide.create_well(user, center), "Создаётся воронка.")
	var/obj/structure/heretic_tide_well/well = tide.active_well
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	for(var/pulse_index in 1 to 3)
		well.pulse()
	TEST_ASSERT_EQUAL(protection.charges, 4, "Три пульса списывают один заряд.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Защищённая цель не ранена.")

/// Метка Космоса не ложится на труп.
/datum/unit_test/heretic_antimagic_cosmic_mark_corpse/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/cosmic_mark/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_mark)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, get_step(user, EAST))
	corpse.death()
	TEST_ASSERT(!knowledge.on_mansus_grasp(corpse, user, TRUE), "Мёртвого не пометить.")
	TEST_ASSERT_NULL(corpse.has_status_effect(/datum/status_effect/eldritch/cosmic), "На трупе нет метки.")

/// Открывающий удар не выбирает защищённую цель и не тратит на неё перезарядку.
/datum/unit_test/heretic_antimagic_lock_bolt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt)
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y, user.z))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Защищённого не выбрать.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "защищ"), "Отказ называет защиту: [spell.heretic_failure_reason]")
	spell.charge_counter = 0
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Удар по защищённому возвращает перезарядку.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Прицел не тратит заряды защиты.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Защищённый не обожжён.")

/// Святой клеймор подсказывает при осмотре, что защищает только в руке.
/datum/unit_test/heretic_antimagic_claymore_hint/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/nullrod/claymore/claymore = allocate(/obj/item/nullrod/claymore, get_turf(holder))
	TEST_ASSERT(findtext(jointext(claymore.examine(holder), " "), "Сейчас не защищает"), "Вне руки осмотр предупреждает о снятой защите.")
	TEST_ASSERT(holder.put_in_active_hand(claymore), "Клеймор в руке.")
	TEST_ASSERT(!findtext(jointext(claymore.examine(holder), " "), "Сейчас не защищает"), "В руке предупреждения нет.")
	TEST_ASSERT(holder.check_magic_resistance(chargecost = 0), "В руке клеймор защищает.")
