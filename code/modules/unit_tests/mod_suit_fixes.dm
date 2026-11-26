// Регрессы по багрепортам на МОД от 17.07.2026. Тесты названы по симптому,
// который видел игрок, а не по внутреннему механизму.

// "Перетаскивание сумки на мод не работает - вещи выпадают на пол"
//
// Хранилище МОД получает компонентом, а типом остаётся обычным /obj/item.
// get_dumping_location() у /obj отдаёт турф, и вся сумка уезжала на пол вместо
// отсеков костюма: правом на "меня можно наполнить" владел только тип
// /obj/item/storage, хотя storage_contents_dump_act() рядом уже давно
// диспатчится по наличию компонента.
/datum/unit_test/mod_storage_accepts_dumped_container/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/storage/module = allocate(/obj/item/mod/module/storage)
	mod.install(module)

	TEST_ASSERT_NOTNULL(mod.GetComponent(/datum/component/storage), \
		"test premise: installing the storage module must give the MOD a storage component")
	TEST_ASSERT_EQUAL(mod.get_dumping_location(), mod, \
		"A MOD with a storage module must swallow a dumped container itself instead of spilling it on the floor")

	// обратная сторона: костюм без модуля обязан остаться "неналивным"
	var/obj/item/mod/control/bare = allocate(/obj/item/mod/control)
	TEST_ASSERT_EQUAL(bare.get_dumping_location(), get_turf(bare), \
		"A MOD without a storage module must keep dumping onto the floor")

// "Вытащил модуль хранилища - вещи остались в моде, но без доступа к ним"
//
// on_uninstall() убивал компонент, ничего не выгрузив: предметы так и лежали
// в contents костюма, а UI к ним больше не открывался.
/datum/unit_test/mod_storage_module_releases_contents/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/storage/module = allocate(/obj/item/mod/module/storage)
	mod.install(module)

	var/datum/component/storage/storage = mod.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(storage, "test premise: installing the storage module must give the MOD a storage component")

	var/obj/item/stored = allocate(/obj/item/screwdriver)
	TEST_ASSERT(storage.handle_item_insertion(stored, TRUE), "test premise: the item must fit into the MOD storage")
	TEST_ASSERT_EQUAL(stored.loc, mod, "test premise: an inserted item must actually live inside the MOD")

	mod.uninstall(module)

	TEST_ASSERT_NOTEQUAL(stored.loc, mod, \
		"Pulling the storage module must not strand items inside the MOD with no way to reach them")
	TEST_ASSERT_NULL(mod.GetComponent(/datum/component/storage), \
		"Pulling the storage module must take the storage component with it")

// "Рампартка на надетых частях ломает изоляцию МОДа - поддувает и замерзаешь"
//
// Набор брони присваивал (не сливал) восемь защитных переменных с прототипа
// жилета. Запечатывание костюма восстанавливает только clothing_flags через
// visor_flags, поэтому min_cold_protection_temperature и body_parts_covered
// оставались жилетными навсегда.
/datum/unit_test/armor_kit_refuses_mod_parts/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/clothing/mod_part/suit/chestplate = mod.mod_parts[MOD_PART_CHEST]
	TEST_ASSERT_NOTNULL(chestplate, "test premise: a MOD must build itself a chestplate")

	var/covered_before = chestplate.body_parts_covered
	var/flags_before = chestplate.clothing_flags
	var/cold_before = chestplate.min_cold_protection_temperature

	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/armorkit/durathread/vest/kit = allocate(/obj/item/armorkit/durathread/vest)
	kit.afterattack(chestplate, user, TRUE)

	TEST_ASSERT(!chestplate.reinforced, "An armor kit must not reinforce a MOD part")
	TEST_ASSERT_EQUAL(chestplate.body_parts_covered, covered_before, \
		"An armor kit must not shrink the coverage of a MOD part")
	TEST_ASSERT_EQUAL(chestplate.clothing_flags, flags_before, \
		"An armor kit must not strip the clothing flags of a MOD part")
	TEST_ASSERT_EQUAL(chestplate.min_cold_protection_temperature, cold_before, \
		"An armor kit must not strip the cold protection of a MOD part - sealing only restores clothing_flags")
	TEST_ASSERT(!QDELETED(kit), "An armor kit rejected by a MOD part must not be consumed")

// Регресс по раунду 10137: части МОДа составляли 44 харддела из 127 за смену -
// половину всего бюджета заморозки от SSgarbage (15.0 с из 29.6 с).
//
// mod_parts это alist с числовыми ключами MOD_PART_*, а вычитание из alist идёт
// ПО КЛЮЧУ. Destroy() костюма передавал в `mod_parts -= ...` саму часть, то есть
// значение, и не удалял ничего: alist продолжал держать уже qdel-нутую часть, та
// проваливала окно GC и уходила в харддел. Батарея в лог хардделов не попадала
// только потому, что её чистил QDEL_NULL(MOD_CELL) - этот макрос разворачивается
// в mod_parts[MOD_PART_CELL] и работает как lvalue.
/datum/unit_test/mod_destroy_releases_its_parts/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/list/parts = mod.get_mod_parts(include_cell = FALSE)
	TEST_ASSERT(length(parts), "test premise: a MOD must build itself some parts")

	qdel(mod)

	for(var/obj/item/clothing/mod_part/part as anything in parts)
		TEST_ASSERT(QDELETED(part), \
			"Destroying a MOD must actually destroy [part.type], not just detach it")
		TEST_ASSERT(!mod.is_mod_part(part), \
			"A destroyed MOD must not keep holding [part.type] in mod_parts - that reference is what sent every part to hard delete")

// Пин на семантику alist: именно она сломала Destroy выше. Если однажды alist
// начнёт вычитать по значению, этот тест упадёт и правку можно будет упростить.
/datum/unit_test/mod_parts_are_keyed_not_valued/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/clothing/mod_part/head/helmet = mod.mod_parts[MOD_PART_HEAD]
	TEST_ASSERT_NOTNULL(helmet, "test premise: a MOD must build itself a helmet")

	mod.mod_parts -= helmet
	TEST_ASSERT(mod.is_mod_part(helmet), \
		"Subtracting a part by value must stay a no-op on an alist - if this changed, revisit /obj/item/mod/control/Destroy")

	TEST_ASSERT(mod.clear_mod_part(helmet), "clear_mod_part must report that it found the part")
	TEST_ASSERT(!mod.is_mod_part(helmet), "clear_mod_part must actually drop the part out of mod_parts")
	TEST_ASSERT(!mod.clear_mod_part(helmet), "clear_mod_part must report a miss the second time round")
	// Отцепленный шлем костюм при своём qdel уже не увидит - убираем сами, иначе тест
	// оставляет в нулевом пространстве шлем с mod на удалённый костюм (ровно тот
	// харддел, ради которого он написан).
	qdel(helmet)

// Перебор alist отдаёт КЛЮЧИ, поэтому `for(var/obj/item/part in mod_parts)` молча
// не исполнялся ни разу: фильтр по типу отбрасывал числа. На этом стояли проверка
// "выдвиньте элементы МОДа", сокрытие частей при обыске и пружинная ловушка.
/datum/unit_test/mod_part_iteration_yields_parts/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)

	var/naive_hits = 0
	for(var/obj/item/part in mod.mod_parts)
		naive_hits++
	TEST_ASSERT_EQUAL(naive_hits, 0, \
		"test premise: iterating the alist directly must keep yielding keys, not parts")

	var/list/parts = mod.get_mod_parts(include_cell = FALSE)
	TEST_ASSERT(length(parts), "get_mod_parts must return the actual parts")
	for(var/part in parts)
		TEST_ASSERT(istype(part, /obj/item/clothing/mod_part), \
			"get_mod_parts must return parts, got [part]")

// Обычная одежда обязана и дальше укрепляться - фикс не должен убить сам механизм.
/datum/unit_test/armor_kit_still_reinforces_clothing/Run()
	var/obj/item/clothing/suit/hooded/wintercoat/coat = allocate(/obj/item/clothing/suit/hooded/wintercoat)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/armorkit/durathread/vest/kit = allocate(/obj/item/armorkit/durathread/vest)

	kit.afterattack(coat, user, TRUE)

	TEST_ASSERT(coat.reinforced, "An armor kit must still reinforce ordinary outer clothing")

/// Модуль longfall гасит урон от падения, пока костюм включён, и не гасит после выключения.
/datum/unit_test/mod_longfall_cancels_fall_damage/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	var/obj/item/mod/module/longfall/module = allocate(/obj/item/mod/module/longfall)
	mod.install(module)
	mod.wearer = wearer
	module.on_suit_activation()

	wearer.ZImpactDamage(get_turf(wearer), 1)
	TEST_ASSERT_EQUAL(wearer.getBruteLoss(), 0, "A fall with an active longfall module must deal no damage")

	module.on_suit_deactivation()
	wearer.ZImpactDamage(get_turf(wearer), 1)
	TEST_ASSERT(wearer.getBruteLoss() > 0, "A fall after the suit is off must hurt again")
	mod.wearer = null

// "Вышел с полигона в инфильтраторе - рантайм" (10600)
//
// Выключение модуля возвращало голос из префов клиента носителя. У тела,
// которое удаляют без игрока, клиента нет: удаление падало на null.prefs.
/datum/unit_test/mod_infiltrator_deactivates_without_client/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/mod/control/pre_equipped/infiltrator_inteq/mod = allocate(/obj/item/mod/control/pre_equipped/infiltrator_inteq)
	var/obj/item/mod/module/infiltrator/module = locate() in mod.modules
	TEST_ASSERT_NOTNULL(module, "test premise: the InteQ infiltrator MOD must come with the infiltrator module")
	var/own_bark
	for(var/bark_id in GLOB.bark_list)
		if(bark_id != "bump")
			own_bark = bark_id
			break
	wearer.set_bark(own_bark)
	mod.set_wearer(wearer)
	ENABLE_BITFIELD(mod.status_flags, MOD_ACTIVE)
	var/obj/item/clothing/mod_part/head/helmet = mod.mod_parts[MOD_PART_HEAD]
	TEST_ASSERT(wearer.equip_to_slot_if_possible(helmet, ITEM_SLOT_HEAD, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "test premise: the helmet must go on the head")

	TEST_ASSERT(module.on_activation(), "test premise: the module must turn on")
	TEST_ASSERT_EQUAL(wearer.vocal_bark_id, "bump", "The infiltrator must swap the voice while on")
	module.on_deactivation()
	TEST_ASSERT_EQUAL(wearer.vocal_bark_id, own_bark, "Turning the infiltrator off without a client must give back the wearer's own voice")

	TEST_ASSERT(module.on_activation(), "test premise: the module must turn on again")
	qdel(wearer)
	TEST_ASSERT_NULL(mod.wearer, "Deleting a clientless wearer with the module on must let the MOD drop its wearer")

// "Развернул и свернул перчатки МОДа поверх перчаток-хватателей - бросок не работает, пока не переоденешь"
//
// Вернувшиеся на руки хвататели брали себе уникальный tackler, выданный МОДом
// на время развёртывания, а restore_normal_features() следом его удалял.
/datum/unit_test/mod_gauntlets_give_back_working_tackle_gloves
	var/area/gravity_area
	var/saved_gravity

/datum/unit_test/mod_gauntlets_give_back_working_tackle_gloves/Destroy()
	if(gravity_area)
		gravity_area.has_gravity = saved_gravity
		gravity_area = null
	return ..()

/datum/unit_test/mod_gauntlets_give_back_working_tackle_gloves/Run()
	// резервный z без гравитации, а без неё checkTackle() не прыгает
	gravity_area = get_area(run_loc_floor_bottom_left)
	saved_gravity = gravity_area.has_gravity
	gravity_area.has_gravity = STANDARD_GRAVITY
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/clothing/gloves/tackler/gripper = allocate(/obj/item/clothing/gloves/tackler)
	var/obj/item/mod/control/pre_equipped/standard/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	TEST_ASSERT(user.equip_to_slot_if_possible(gripper, ITEM_SLOT_GLOVES), "test premise: the gripper gloves must go on the hands")
	TEST_ASSERT(user.equip_to_slot_if_possible(mod, ITEM_SLOT_BACK), "test premise: the MOD must go on the back")
	var/obj/item/clothing/mod_part/gloves/gauntlets = mod.get_gauntlets()

	TEST_ASSERT(mod.deploy(user, gauntlets), "test premise: the gauntlets must deploy over the gripper gloves")
	TEST_ASSERT_EQUAL(gripper.loc, gauntlets, "test premise: the gripper gloves must wait inside the gauntlets")
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/tackler), "Gauntlets deployed over gripper gloves must keep the tackle")

	mod.conceal(user, gauntlets)
	TEST_ASSERT_EQUAL(user.gloves, gripper, "test premise: retracting the gauntlets must put the gripper gloves back on")
	var/datum/component/tackler/tackle = user.GetComponent(/datum/component/tackler)
	TEST_ASSERT(tackle && !QDELETED(tackle), "Gripper gloves given back by the MOD must tackle without being taken off and put on again")
	TEST_ASSERT(gripper.tackler == tackle, "The gripper gloves must own their tackle again, or taking them off would leave it on the wearer")

	var/deadline = world.time + 3 SECONDS
	while(user.tackling && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(!user.tackling, "test premise: the tackle cooldown from putting the gloves on must run out")
	user.throw_mode_on()
	user.CommonClickOn(target, "")
	TEST_ASSERT(user.IsKnockdown(), "A throw-mode click with the given back gripper gloves must launch a tackle")

// RIG regression tests: shared Bulwark, equipment lifetime and patient transport.
/datum/unit_test/rig_security_support/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, get_step(user, EAST))
	user.mob_weight = MOB_WEIGHT_NORMAL
	target.mob_weight = MOB_WEIGHT_HEAVY_SUPER
	var/obj/item/clothing/suit/space/hardsuit/security/rig = allocate(/obj/item/clothing/suit/space/hardsuit/security)
	TEST_ASSERT(!user.can_pull_superheavy_mob(), "Ordinary test human must not have superheavy pull before equipping")
	TEST_ASSERT(user.equip_to_slot_if_possible(rig, ITEM_SLOT_OCLOTHING), "Security RIG must equip")
	TEST_ASSERT(user.can_pull_superheavy_mob(), "Security RIG must allow superheavy pulling")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED), "RIG must grant Bulwark shove protection")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NO_THROW_HITPUSH), "RIG must grant Bulwark hitpush protection")
	TEST_ASSERT(SEND_SIGNAL(user, COMSIG_LIVING_STATUS_STAGGER, 10, TRUE, FALSE) & COMPONENT_NO_STUN, "Bulwark must block normal stagger")
	TEST_ASSERT(!(SEND_SIGNAL(user, COMSIG_LIVING_STATUS_STAGGER, 10, TRUE, TRUE) & COMPONENT_NO_STUN), "Bulwark must not block forced stagger")
	user.start_pulling(target, supress_message = TRUE)
	TEST_ASSERT_EQUAL(user.pulling, target, "Security RIG must actually start the pull")
	var/datum/movespeed_modifier/weight = user.has_movespeed_modifier(/datum/movespeed_modifier/heavy_mob_drag)
	TEST_ASSERT_NOTNULL(weight, "Security RIG must pay a superheavy penalty even without a pull chain")
	TEST_ASSERT_EQUAL(weight.multiplicative_slowdown, 1.5, "Unexpected security RIG weight penalty")
	ADD_TRAIT(user, TRAIT_NO_THROW_HITPUSH, "rig_test_other_source")
	TEST_ASSERT(user.dropItemToGround(rig, TRUE), "Security RIG must be removable")
	TEST_ASSERT_NULL(user.pulling, "Removing the only source of superheavy support must release the target")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heavy_mob_drag), "Removing RIG must clear the weight modifier")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED), "Removing RIG must remove shove protection")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NO_THROW_HITPUSH), "Removing RIG must not remove another trait source")
	REMOVE_TRAIT(user, TRAIT_NO_THROW_HITPUSH, "rig_test_other_source")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NO_THROW_HITPUSH), "RIG trait source leaked")
	TEST_ASSERT(!(SEND_SIGNAL(user, COMSIG_LIVING_STATUS_STAGGER, 10, TRUE, FALSE) & COMPONENT_NO_STUN), "RIG stagger handler leaked")

/datum/unit_test/rig_medical_transport/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/carbon/human/third = allocate(/mob/living/carbon/human, get_step(target, EAST))
	user.mob_weight = MOB_WEIGHT_NORMAL
	target.mob_weight = MOB_WEIGHT_HEAVY_SUPER
	var/obj/item/clothing/suit/space/hardsuit/medical/rig = allocate(/obj/item/clothing/suit/space/hardsuit/medical)
	TEST_ASSERT(user.equip_to_slot_if_possible(rig, ITEM_SLOT_OCLOTHING), "Medical RIG must equip")
	user.start_pulling(target, supress_message = TRUE)
	TEST_ASSERT_EQUAL(user.pulling, target, "Medical RIG must allow superheavy pulling")
	target.set_resting(TRUE, TRUE)
	user.update_pull_movespeed()
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/bulky_drag), "One prone patient must not slow a medical RIG")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heavy_mob_drag), "One passive superheavy patient must not slow a medical RIG")
	target.set_resting(FALSE, TRUE)
	target.start_pulling(third, supress_message = TRUE)
	TEST_ASSERT_EQUAL(target.pulling, third, "Test premise: three-person pull chain")
	user.update_pull_movespeed()
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/pull_slowdown), "Medical RIG must not waive pull-chain penalties")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heavy_mob_drag), "Medical RIG must not waive chain weight penalties")
	target.stop_pulling()
	user.update_pull_movespeed()
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/pull_slowdown), "Chain penalty must clear when chain ends")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heavy_mob_drag), "Weight penalty must clear when chain ends")
	user.can_pull_superheavy_entities = TRUE
	qdel(rig)
	TEST_ASSERT_EQUAL(user.pulling, target, "Destroying a RIG must preserve an independent pull permission")
	TEST_ASSERT(!user.get_rig_pull_support(), "Destroyed RIG must not provide pull support")
	user.stop_pulling()

/datum/unit_test/rig_ce_meson_cleanup/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/space/hardsuit/engine/elite/rig = allocate(/obj/item/clothing/suit/space/hardsuit/engine/elite)
	TEST_ASSERT(user.equip_to_slot_if_possible(rig, ITEM_SLOT_OCLOTHING), "CE RIG must equip")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_MESON_VISION), "Folded helmet must not provide mesons")
	rig.ToggleHelmet(FALSE)
	TEST_ASSERT_EQUAL(user.head, rig.helmet, "CE helmet must deploy")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_MESON_VISION), "Deployed CE helmet must provide mesons")
	rig.RemoveHelmet(FALSE)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_MESON_VISION), "Folded CE helmet must remove mesons")
	rig.ToggleHelmet(FALSE)
	ADD_TRAIT(user, TRAIT_MESON_VISION, "rig_test_other_source")
	qdel(rig)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_MESON_VISION), "Deleting CE RIG must preserve independent mesons")
	REMOVE_TRAIT(user, TRAIT_MESON_VISION, "rig_test_other_source")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_MESON_VISION), "Deleting deployed CE RIG must remove its meson source")

/datum/unit_test/rig_jetpack_research/Run()
	var/datum/techweb_node/node = SSresearch.techweb_node_by_id("adv_engi")
	TEST_ASSERT_NOTNULL(node, "Advanced engineering node must exist")
	TEST_ASSERT("hardsuitjpack" in node.design_ids, "Advanced engineering must unlock the RIG jetpack upgrade")
	TEST_ASSERT(!("chardsuit" in node.design_ids), "Advanced engineering must not unlock production of the RIG itself")
	var/datum/design/design = SSresearch.techweb_design_by_id("hardsuitjpack")
	TEST_ASSERT_NOTNULL(design, "Jetpack design must exist")
	TEST_ASSERT_EQUAL(design.build_path, /obj/item/tank/jetpack/suit, "Design must build the existing RIG upgrade")


/datum/unit_test/rig_specialist_profiles/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	user.mob_weight = MOB_WEIGHT_NORMAL
	var/obj/item/clothing/suit/space/hardsuit/ert/sec/security = allocate(/obj/item/clothing/suit/space/hardsuit/ert/sec)
	TEST_ASSERT(user.equip_to_slot_if_possible(security, ITEM_SLOT_OCLOTHING), "ERT security RIG must equip")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED), "ERT security must have Bulwark")
	TEST_ASSERT(user.can_pull_superheavy_mob(), "ERT security must have assisted pull")
	TEST_ASSERT(user.dropItemToGround(security, TRUE), "ERT security RIG must be removable")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED), "ERT security Bulwark must clear")
	var/obj/item/clothing/suit/space/hardsuit/ert/alert/med/medical = allocate(/obj/item/clothing/suit/space/hardsuit/ert/alert/med)
	TEST_ASSERT(medical.rig_patient_transport, "Alert medical ERT must have patient transport")
	TEST_ASSERT_EQUAL(medical.rig_superheavy_pull_slowdown, 0, "Alert medical ERT must have zero weight penalty")
	TEST_ASSERT(!medical.rig_bulwark, "Medical ERT must not inherit security Bulwark")
	var/obj/item/clothing/suit/space/hardsuit/ert/engi/engineer = allocate(/obj/item/clothing/suit/space/hardsuit/ert/engi)
	TEST_ASSERT(engineer.rig_water_grip, "ERT engineer needs wet-floor grip")
	TEST_ASSERT(/obj/item/construction/rcd in engineer.allowed, "ERT engineer needs RCD storage")
	var/obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor/damaged/inquisitor = allocate(/obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor/damaged)
	TEST_ASSERT_EQUAL(inquisitor.rig_superheavy_pull_slowdown, -1, "Inquisitor must not inherit commander pull")
	TEST_ASSERT(!(inquisitor.clothing_flags & STOPSPRESSUREDAMAGE), "Damaged inquisitor must remain unsealed")
	var/obj/item/clothing/suit/space/hardsuit/ert/paranormal/beserker/damaged/champion = allocate(/obj/item/clothing/suit/space/hardsuit/ert/paranormal/beserker/damaged)
	TEST_ASSERT(!champion.rig_bulwark, "Damaged champion must not inherit full Bulwark")
	TEST_ASSERT_EQUAL(champion.rig_superheavy_pull_slowdown, 1.5, "Damaged champion must retain assisted pull")
	var/obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/hsc = allocate(/obj/item/clothing/suit/space/hardsuit/ert/alert/hsc)
	TEST_ASSERT_EQUAL(hsc.rig_superheavy_pull_slowdown, -1, "HSC must not inherit commander pull")
	var/obj/item/clothing/suit/space/hardsuit/wizard/mage = allocate(/obj/item/clothing/suit/space/hardsuit/wizard)
	TEST_ASSERT(/obj/item/spellbook in mage.allowed, "Wizard RIG must hold spellbook")
	TEST_ASSERT_EQUAL(mage.slowdown, -0.5, "Wizard movement bonus must remain unchanged")
