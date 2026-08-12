//Регресс-тесты рантаймов плейтеста 2026-07-17: null owner у конечностей и траум,
//null usr при программном бакле на транспорт

/// Отсоединённая конечность (owner = null) не должна рантаймить в is_disabled():
/// оверрайды рук и ног читали трейты владельца до null-гарда родителя
/datum/unit_test/detached_limb_is_disabled/Run()
	var/list/limb_types = list(
		/obj/item/bodypart/l_arm,
		/obj/item/bodypart/r_arm,
		/obj/item/bodypart/l_leg,
		/obj/item/bodypart/r_leg,
	)
	for(var/limb_type in limb_types)
		var/obj/item/bodypart/limb = allocate(limb_type)
		TEST_ASSERT_NULL(limb.is_disabled(), "is_disabled() отсоединённой [limb_type] должен вернуть null, а не рантаймить")

/// qdel присоединённой руки мимо drop_limb должен чистить hand_bodyparts:
/// протухшая ссылка рантаймила в put_in_hand на каждом подборе предмета
/datum/unit_test/bodypart_destroy_clears_hand_refs/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/arm = victim.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(arm, "У свежесозданного человека нет левой руки")
	var/stale_index = arm.held_index
	qdel(arm)
	TEST_ASSERT(!victim.hand_bodyparts[stale_index], "qdel присоединённой руки оставил протухшую ссылку в hand_bodyparts")
	//путь краша: put_in_hands перебирает обе руки через put_in_hand -> is_disabled
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	victim.put_in_hands(pen)

/// Вставка мозга генлингу уходит в ранний return до восстановления владельца траум:
/// фобия с owner = null рантаймила в on_life каждый Life-тик до конца раунда
/datum/unit_test/changeling_brain_insert_traumas/Run()
	var/mob/living/carbon/human/ling = allocate(/mob/living/carbon/human)
	ling.mind_initialize()
	var/datum/antagonist/changeling/antag = new
	antag.silent = TRUE
	antag.give_objectives = FALSE
	ling.mind.add_antag_datum(antag)
	TEST_ASSERT_NOTNULL(ling.mind.has_antag_datum(/datum/antagonist/changeling), "Генлинг-датум не выдался")

	var/datum/brain_trauma/trauma = ling.gain_trauma(/datum/brain_trauma/mild/stuttering)
	TEST_ASSERT_NOTNULL(trauma, "Не удалось выдать трауму")
	TEST_ASSERT_EQUAL(trauma.owner, ling, "Свежевыданная траума не привязана к мобу")

	var/obj/item/organ/brain/brain = ling.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_NOTNULL(brain, "У генлинга нет мозга")
	//мозг генлинга рудиментарен: mind остаётся в теле при извлечении,
	//поэтому реимплантация попадает именно в генлинг-ветку Insert
	brain.decoy_override = TRUE
	brain.Remove()
	TEST_ASSERT_NULL(trauma.owner, "Remove() мозга не отвязал трауму от тела")
	TEST_ASSERT_NOTNULL(ling.mind, "Mind рудиментарного мозга не должен уходить в brainmob")

	brain.Insert(ling)
	TEST_ASSERT_EQUAL(trauma.owner, ling, "Insert() генлингу не вернул трауме владельца - её on_life рантаймит каждый Life-тик")

/// Программный бакл сверхтяжёлого моба на транспорт идёт без usr:
/// pre_buckle_mob рантаймил на usr.visible_message
/datum/unit_test/vehicle_heavy_buckle_no_usr/Run()
	var/obj/vehicle/ridden/scooter/skateboard/board = allocate(/obj/vehicle/ridden/scooter/skateboard)
	var/mob/living/carbon/human/heavy = allocate(/mob/living/carbon/human)
	heavy.mob_weight = MOB_WEIGHT_HEAVY_SUPER
	var/buckled = board.buckle_mob(heavy, force = TRUE, check_loc = FALSE)
	TEST_ASSERT(!buckled, "Сверхтяжёлый моб не должен был пристегнуться к транспорту")
	TEST_ASSERT_NULL(heavy.buckled, "Сверхтяжёлый моб остался пристёгнут к транспорту")
