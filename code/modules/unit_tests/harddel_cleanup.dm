/// set_armor должен сохранять общие tag-кэшированные armor и удалять заменённые приватные.
/datum/unit_test/set_armor_ownership/Run()
	var/obj/effect/first = allocate(/obj/effect)
	var/obj/effect/second = allocate(/obj/effect)
	var/datum/armor/shared = getArmor(11)
	first.armor = shared
	second.armor = shared

	var/datum/armor/custom = shared.generate_new_with_specific(list(MELEE = 42))
	first.set_armor(custom)
	TEST_ASSERT(!QDELETED(shared), "Замена armor удалила общий датум из getArmor()")
	TEST_ASSERT_EQUAL(second.get_armor_rating(MELEE), 11, "Удаление общего armor сломало соседний объект")

	var/datum/armor/replacement = custom.generate_new_with_specific(list(MELEE = 57))
	first.set_armor(replacement)
	TEST_ASSERT(QDELETED(custom), "Заменённый приватный armor не был удалён")
	first.set_armor(shared)
	TEST_ASSERT(QDELETED(replacement), "Последний приватный armor не был удалён при возврате к общему")

/// Аварийное удаление offhand обязано полностью развилдить основной предмет.
/datum/unit_test/two_handed_offhand_qdel_unwields/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/weapon = allocate(/obj/item)
	TEST_ASSERT(user.put_in_active_hand(weapon, forced = TRUE), "Не удалось положить тестовый предмет в руку")
	var/datum/component/two_handed/component = weapon.AddComponent(/datum/component/two_handed, FALSE, FALSE, FALSE, FALSE, 0, 19, 7)
	component.wield(user)
	TEST_ASSERT(component.wielded, "Тестовый предмет не перешёл в wielded")
	TEST_ASSERT_NOTNULL(component.offhand_item, "Компонент не создал offhand")
	TEST_ASSERT_EQUAL(weapon.force, 19, "Wield не установил тестовую силу")

	qdel(component.offhand_item)
	TEST_ASSERT(!component.wielded, "Удаление offhand оставило компонент в wielded")
	TEST_ASSERT_NULL(component.offhand_item, "Удаление offhand оставило висящую ссылку")
	TEST_ASSERT_NULL(component.wield_user, "Удаление offhand оставило ссылку на владельца")
	TEST_ASSERT(!HAS_TRAIT(weapon, TRAIT_WIELDED), "Удаление offhand оставило TRAIT_WIELDED")
	TEST_ASSERT_EQUAL(weapon.force, 7, "Удаление offhand не восстановило unwielded-силу")

/// Прямое удаление надетого аксессуара должно выполнять полный detach от униформы.
/datum/unit_test/accessory_qdel_detaches_uniform_state/Run()
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under)
	var/obj/item/clothing/accessory/accessory = allocate(/obj/item/clothing/accessory)
	uniform.armor = getArmor(10)
	accessory.armor = getArmor(5)
	TEST_ASSERT(accessory.attach(uniform, null), "Не удалось прикрепить тестовый аксессуар")
	TEST_ASSERT(accessory in uniform.accessories_attached, "Прикреплённый аксессуар не попал в список униформы")
	TEST_ASSERT_EQUAL(uniform.armor.get_rating(MELEE), 15, "Аксессуар не добавил броню униформе")

	qdel(accessory)
	TEST_ASSERT(!(accessory in uniform.accessories_attached), "Удалённый аксессуар остался в списке униформы")
	TEST_ASSERT_EQUAL(uniform.armor.get_rating(MELEE), 10, "Удалённый аксессуар оставил бонус брони на униформе")

/// Security-запись может заимствовать фото general-записи и не владеет им.
/datum/unit_test/datacore_shared_photo_ownership/Run()
	var/datum/picture/picture = new
	var/obj/item/photo/shared_photo = new(null, picture)
	var/datum/data/record/general_record = new
	var/datum/data/record/security_record = new
	general_record.fields["photo_front"] = shared_photo
	security_record.fields["photo_front"] = shared_photo
	GLOB.data_core.general += general_record
	GLOB.data_core.security += security_record

	qdel(security_record)
	TEST_ASSERT(!QDELETED(shared_photo), "Security-запись удалила фото, принадлежащее general-записи")
	qdel(general_record)
	TEST_ASSERT(QDELETED(shared_photo), "General-запись не удалила принадлежащее ей фото")

/// Радиал-меню не владеет колбеками вызывающего: show_radial_menu делает qdel(menu) до финального
/// custom_check.Invoke(), поэтому закрытие меню не должно удалять чужой колбек.
/datum/unit_test/radial_menu_caller_callback_ownership/Run()
	var/datum/callback/check = CALLBACK(src, PROC_REF(radial_check_stub))
	var/datum/radial_menu/menu = new
	menu.custom_check_callback = check
	qdel(menu)
	TEST_ASSERT(!QDELETED(check), "Закрытие радиал-меню удалило custom_check колбек вызывающего")
	TEST_ASSERT(check.Invoke(), "custom_check колбек не сработал после закрытия радиал-меню")

	var/datum/callback/select = CALLBACK(src, PROC_REF(radial_check_stub))
	var/datum/radial_menu/persistent/persistent_menu = new
	persistent_menu.select_proc_callback = select
	qdel(persistent_menu)
	TEST_ASSERT(!QDELETED(select), "Закрытие persistent радиал-меню удалило select_proc колбек вызывающего")
	TEST_ASSERT(select.Invoke(), "select_proc колбек не сработал после закрытия persistent радиал-меню")

/datum/unit_test/radial_menu_caller_callback_ownership/proc/radial_check_stub()
	return TRUE

/// remote_materials владеет after_insert и не должен оставлять удалённый callback в своём поле.
/datum/unit_test/remote_materials_callback_cleanup/Run()
	var/obj/effect/parent = allocate(/obj/effect)
	var/datum/callback/after_insert = CALLBACK(src, PROC_REF(after_insert_stub))
	var/datum/component/remote_materials/component = parent.AddComponent(/datum/component/remote_materials, "unit_test", FALSE, FALSE, FALSE, after_insert)
	TEST_ASSERT_NOTNULL(component, "Не удалось создать remote_materials")

	qdel(component)
	TEST_ASSERT(QDELETED(after_insert), "Удаление remote_materials не удалило принадлежащий ему callback")
	TEST_ASSERT_NULL(component.after_insert, "remote_materials оставил ссылку на удалённый callback")

/datum/unit_test/remote_materials_callback_cleanup/proc/after_insert_stub()
	return

/// Preinstalled borg upgrades must be real owned objects. A type path in this
/// list reaches qdel(typepath) during teardown and raises `bad del`.
/datum/unit_test/inteq_borg_preinstalled_upgrade_cleanup/Run()
	var/mob/living/silicon/robot/modules/inteq/saboteur/borg = allocate(/mob/living/silicon/robot/modules/inteq/saboteur)
	TEST_ASSERT_EQUAL(length(borg.upgrades), 1, "InteQ borg must own exactly one preinstalled upgrade")
	TEST_ASSERT(istype(borg.upgrades[1], /obj/item/borg/upgrade/vtec), "InteQ borg stored a type path instead of an installed VTEC object")

	qdel(borg)
	TEST_ASSERT(QDELETED(borg), "InteQ borg teardown did not enter qdel")
	// Let the asynchronous module transformation reach its first post-sleep
	// validity check. Any post-qdel access is reported as a test runtime.
	sleep(2)

/// With no valid human victim, initialization qdels the cluwne. It must not
/// create its orbit helper afterwards with loc pointing back to the deleted mob.
/datum/unit_test/floor_cluwne_no_post_qdel_orbit/Run()
	var/mob/living/simple_animal/hostile/floor_cluwne/cluwne = new(run_loc_floor_bottom_left)
	TEST_ASSERT(QDELETED(cluwne), "Floor cluwne without a valid victim must delete itself during initialization")
	TEST_ASSERT_NULL(cluwne.poi, "Floor cluwne created an owned orbit helper after qdel")

/// The gladiator can meet hundreds of mobs in a benchmark round. Its greeting
/// cache must not keep strong references to every mob it has seen.
/datum/unit_test/gladiator_introduced_uses_reference_keys/Run()
	var/mob/living/simple_animal/hostile/megafauna/gladiator/gladiator = allocate(/mob/living/simple_animal/hostile/megafauna/gladiator)
	var/mob/living/simple_animal/hostile/prey = allocate(/mob/living/simple_animal/hostile)
	gladiator.introduction(prey)

	TEST_ASSERT(!(prey in gladiator.introduced), "Gladiator greeting cache kept a strong reference to its target")
	var/datum/weakref/introduced_ref = gladiator.introduced[REF(prey)]
	TEST_ASSERT(istype(introduced_ref), "Gladiator greeting cache did not store a weakref for its target")
	TEST_ASSERT_EQUAL(introduced_ref.resolve(), prey, "Gladiator greeting weakref did not resolve to its target")

	qdel(gladiator)
	TEST_ASSERT_NULL(gladiator.introduced, "Gladiator retained its greeting cache during teardown")

///Broodmother and children hold bidirectional family references during combat.
///Either side must detach cleanly when an arena teardown deletes it directly.
/datum/unit_test/broodmother_children_release_family_refs/Run()
	var/mob/living/simple_animal/hostile/asteroid/elite/broodmother/mother = allocate(/mob/living/simple_animal/hostile/asteroid/elite/broodmother, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/orphan = allocate(/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child, get_step(run_loc_floor_bottom_left, EAST))
	mother.children_list += orphan
	orphan.mother = mother

	qdel(mother)
	TEST_ASSERT_NULL(orphan.mother, "A surviving child retained its qdeleted broodmother")
	TEST_ASSERT_NULL(mother.children_list, "A qdeleted broodmother retained its child list")

	var/mob/living/simple_animal/hostile/asteroid/elite/broodmother/second_mother = allocate(/mob/living/simple_animal/hostile/asteroid/elite/broodmother, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/deleted_child = new(get_step(run_loc_floor_bottom_left, WEST))
	second_mother.children_list += deleted_child
	deleted_child.mother = second_mother

	qdel(deleted_child)
	TEST_ASSERT(!(deleted_child in second_mother.children_list), "A qdeleted child remained in its broodmother's child list")
	TEST_ASSERT_NULL(deleted_child.mother, "A qdeleted child retained its broodmother")

///Paper Wizard mimics are owned helpers and must neither outlive nor retain
///their original when the arena deletes the boss directly.
/datum/unit_test/paper_wizard_copies_release_owner_refs/Run()
	var/mob/living/simple_animal/hostile/boss/paper_wizard/wizard = allocate(/mob/living/simple_animal/hostile/boss/paper_wizard, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/boss/paper_wizard/copy/first_copy = new(get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/simple_animal/hostile/boss/paper_wizard/copy/second_copy = new(get_step(run_loc_floor_bottom_left, WEST))
	wizard.copies = list(first_copy, second_copy)
	first_copy.original = wizard
	second_copy.original = wizard

	qdel(wizard)
	TEST_ASSERT_NULL(wizard.copies, "A qdeleted Paper Wizard retained its copy list")
	TEST_ASSERT(QDELETED(first_copy) && QDELETED(second_copy), "Paper Wizard copies survived direct owner teardown")
	TEST_ASSERT_NULL(first_copy.original, "A deleted Paper Wizard copy retained its original")
	TEST_ASSERT_NULL(second_copy.original, "A deleted Paper Wizard copy retained its original")

///Legionnaire's detachable head and bonfire are owned helpers with backrefs.
/datum/unit_test/legionnaire_helpers_release_owner_refs/Run()
	var/mob/living/simple_animal/hostile/asteroid/elite/legionnaire/body = allocate(/mob/living/simple_animal/hostile/asteroid/elite/legionnaire, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/elite/legionnairehead/head = new(get_step(run_loc_floor_bottom_left, EAST))
	var/obj/structure/legionnaire_bonfire/pile = new(get_step(run_loc_floor_bottom_left, WEST))
	body.myhead = head
	body.mypile = pile
	head.body = body
	pile.myowner = body

	qdel(body)
	TEST_ASSERT_NULL(body.myhead, "A qdeleted Legionnaire retained its head")
	TEST_ASSERT_NULL(body.mypile, "A qdeleted Legionnaire retained its bonfire")
	TEST_ASSERT(QDELETED(head) && QDELETED(pile), "Legionnaire helpers survived direct owner teardown")
	TEST_ASSERT_NULL(head.body, "A deleted Legionnaire head retained its body")
	TEST_ASSERT_NULL(pile.myowner, "A deleted Legionnaire bonfire retained its owner")

/// Terror queens use themselves as the root of their brood hierarchy. The
/// shared teardown must break that self-cycle as well as ordinary brood links.
/datum/unit_test/terror_spider_teardown_clears_lineage/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/queen = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen)
	TEST_ASSERT_EQUAL(queen.spider_myqueen, queen, "Terror queen test fixture did not create its expected self-reference")
	queen.spider_mymother = queen
	var/obj/structure/spider/spiderling/terror_spiderling/spiderling = allocate(/obj/structure/spider/spiderling/terror_spiderling)
	spiderling.spider_myqueen = queen
	spiderling.spider_mymother = queen
	spiderling.enemies += queen

	qdel(spiderling)
	TEST_ASSERT(!(spiderling in GLOB.ts_spiderling_list), "Deleted terror spiderling remained in the global processing list")
	TEST_ASSERT_NULL(spiderling.spider_myqueen, "Terror spiderling retained its queen during teardown")
	TEST_ASSERT_NULL(spiderling.spider_mymother, "Terror spiderling retained its mother during teardown")
	TEST_ASSERT_NULL(spiderling.enemies, "Terror spiderling retained its enemies during teardown")
	qdel(queen)
	TEST_ASSERT_NULL(queen.spider_myqueen, "Terror queen retained its self-reference during teardown")
	TEST_ASSERT_NULL(queen.spider_mymother, "Terror spider retained its mother reference during teardown")

/// Conjure spell владеет последним созданным предметом и обязан обнулить ссылку после qdel.
/datum/unit_test/conjure_item_destroy_clears_item/Run()
	var/obj/effect/proc_holder/spell/targeted/conjure_item/summon_pie/spell = new
	var/obj/item/item = spell.make_item()
	TEST_ASSERT_NOTNULL(item, "Summon pie не создал предмет")

	qdel(spell)
	TEST_ASSERT(QDELETED(item), "Удаление conjure spell не удалило созданный предмет")
	TEST_ASSERT_NULL(spell.item, "Conjure spell оставил ссылку на удалённый предмет")

/// Удалившаяся slab ability должна разорвать обратную ссылку живого slab.
/datum/unit_test/clockwork_slab_ability_backref_cleanup/Run()
	var/obj/item/clockwork/slab/slab = allocate(/obj/item/clockwork/slab)
	var/obj/effect/proc_holder/slab/volt/ability = new(slab)
	slab.slab_ability = ability
	ability.slab = slab

	qdel(ability)
	TEST_ASSERT_NULL(slab.slab_ability, "Clockwork slab оставил ссылку на удалённую ability")

/// Однотиковый список конвейера не должен сохраняться в var машины после process().
/datum/unit_test/conveyor_process_does_not_cache_affecting/Run()
	var/source = read_source_file("code/modules/recycling/conveyor2.dm")
	TEST_ASSERT_NOTNULL(source, "Не удалось прочитать conveyor2.dm")
	TEST_ASSERT(!findtext(source, "\tvar/list/affecting\t// the list of all items that will be moved this ptick"), "Конвейер хранит однотиковый affecting как долгоживущий var")
	TEST_ASSERT(findtext(source, "\tvar/list/affecting = loc.contents - src"), "process() не использует локальный affecting")

/// Кэш screentip обязан инвалидироваться, если закэшированный атом удалён.
/datum/unit_test/hud_screentip_cache_qdel_cleanup/Run()
	var/mob/owner = allocate(/mob)
	var/datum/hud/hud = new(owner)
	var/atom/movable/screen/fullscreen/dimmer/target = allocate(/atom/movable/screen/fullscreen/dimmer)
	hud.set_screentip_cache(target, null)
	TEST_ASSERT_EQUAL(hud.last_screentip_atom, target, "Тест не заполнил screentip-кэш")

	qdel(target)
	TEST_ASSERT_NULL(hud.last_screentip_atom, "HUD оставил ссылку на удалённый screentip target")
	qdel(hud)

/// Cached spawnpanel живёт дольше тела админа и должен отпустить удаляемого owner.
/datum/unit_test/spawnpanel_owner_qdel_cleanup/Run()
	var/mob/owner = allocate(/mob)
	var/datum/spawnpanel/panel = new(owner)
	TEST_ASSERT_EQUAL(panel.owner, owner, "Spawnpanel проигнорировал переданного owner")

	qdel(owner)
	TEST_ASSERT_NULL(panel.owner, "Spawnpanel оставил ссылку на удалённого owner")
	qdel(panel)

/// Mind живёт дольше loadout-реликвии и должен очистить assigned_heirloom по её qdel.
/datum/unit_test/mind_assigned_heirloom_qdel_cleanup/Run()
	var/datum/mind/mind = new
	var/obj/item/clothing/wrists/clockwork_watch/red/heirloom = allocate(/obj/item/clothing/wrists/clockwork_watch/red)
	mind.set_assigned_heirloom(heirloom)
	TEST_ASSERT_EQUAL(mind.assigned_heirloom, heirloom, "Тест не назначил реликвию")

	qdel(heirloom)
	TEST_ASSERT_NULL(mind.assigned_heirloom, "Mind оставил ссылку на удалённую assigned_heirloom")
	qdel(mind)

/// APC обязан немедленно отпустить удаляемый светильник из долгоживущего кэша.
/datum/unit_test/apc_light_cache_qdel_cleanup/Run()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	var/obj/machinery/light/light = allocate(/obj/machinery/light)
	apc.cached_area_lights = list(light)
	apc.light_cache_dirty = FALSE

	apc.mark_light_cache_dirty()
	TEST_ASSERT(apc.light_cache_dirty, "APC не пометил кэш светильников грязным")
	TEST_ASSERT_NULL(apc.cached_area_lights, "APC сохранил ссылку на светильник после инвалидации кэша")

/// Virtualspeaker переживает исходный объект несколько секунд и должен отпустить его по qdel.
/datum/unit_test/virtualspeaker_source_qdel_cleanup/Run()
	var/obj/item/source = allocate(/obj/item)
	var/obj/item/radio/radio = allocate(/obj/item/radio)
	var/atom/movable/virtualspeaker/speaker = new(null, source, radio)
	TEST_ASSERT_EQUAL(speaker.GetSource(), source, "Virtualspeaker не сохранил источник")
	TEST_ASSERT_EQUAL(speaker.GetRadio(), radio, "Virtualspeaker не сохранил радио")

	qdel(source)
	TEST_ASSERT_NULL(speaker.GetSource(), "Virtualspeaker оставил ссылку на удалённый источник")
	qdel(radio)
	TEST_ASSERT_NULL(speaker.GetRadio(), "Virtualspeaker оставил ссылку на удалённое радио")
	qdel(speaker)

/// Завершённое парирование не должно удерживать использованный предмет.
/datum/unit_test/active_parry_item_qdel_cleanup/Run()
	var/mob/living/user = allocate(/mob/living)
	var/obj/item/item = allocate(/obj/item)
	user.set_active_parry_item(item)
	TEST_ASSERT_EQUAL(user.active_parry_item, item, "Тест не назначил предмет парирования")

	qdel(item)
	TEST_ASSERT_NULL(user.active_parry_item, "Моб оставил ссылку на удалённый предмет парирования")

/// Колода задаёт parentdeck на себя и обязана разорвать этот цикл в Destroy().
/datum/unit_test/card_deck_parent_qdel_cleanup/Run()
	var/obj/item/toy/cards/deck/deck = allocate(/obj/item/toy/cards/deck)
	TEST_ASSERT_EQUAL(deck.parentdeck, deck, "Тестовая колода не создала self-reference parentdeck")

	qdel(deck)
	TEST_ASSERT_NULL(deck.parentdeck, "Удалённая колода оставила self-reference parentdeck")

/// RemoveSpell должен удалить все совпадения, а внешний qdel — инвалидировать spell_list.
/datum/unit_test/mind_spell_list_qdel_cleanup/Run()
	var/datum/mind/mind = new
	var/obj/effect/proc_holder/spell/first = new
	var/obj/effect/proc_holder/spell/second = new

	// `in` связывает слабее `||`: без скобок проверка вырождается в `(!S || S) in spell_list`.
	mind.AddSpell(null)
	TEST_ASSERT(!length(mind.spell_list), "AddSpell записал null в spell_list")
	mind.AddSpell(first)
	mind.AddSpell(first)
	TEST_ASSERT_EQUAL(length(mind.spell_list), 1, "AddSpell продублировал заклинание в spell_list")
	mind.AddSpell(second)

	mind.RemoveSpell(/obj/effect/proc_holder/spell)
	TEST_ASSERT(!length(mind.spell_list), "RemoveSpell пропустил заклинание при изменении spell_list во время обхода")
	TEST_ASSERT(QDELETED(first) && QDELETED(second), "RemoveSpell не удалил все совпавшие заклинания")

	var/obj/effect/proc_holder/spell/external = new
	mind.AddSpell(external)
	qdel(external)
	TEST_ASSERT(!(external in mind.spell_list), "Mind оставил внешне удалённое заклинание в spell_list")

	var/obj/effect/proc_holder/spell/owned = new
	mind.AddSpell(owned)
	qdel(mind)
	TEST_ASSERT(QDELETED(owned), "Удаление mind не удалило принадлежащее ему заклинание")
	TEST_ASSERT(!length(mind.spell_list), "Удалённый mind сохранил spell_list")

/// Внешний qdel призванного предмета должен очистить ссылку в живом заклинании.
/datum/unit_test/conjure_item_qdel_cleanup/Run()
	var/obj/effect/proc_holder/spell/targeted/conjure_item/summon_cumburger/spell = allocate(/obj/effect/proc_holder/spell/targeted/conjure_item/summon_cumburger)
	var/obj/item/reagent_containers/food/snacks/burger/cumburger/item = spell.make_item()
	TEST_ASSERT_EQUAL(spell.item, item, "Заклинание не сохранило созданный предмет")

	qdel(item)
	TEST_ASSERT_NULL(spell.item, "Заклинание оставило ссылку на удалённый cumburger")

/// RemoveSource может синхронно удалить последний neural_interface: holder очищается до вызова.
/datum/unit_test/hud_neural_interface_qdel_cleanup/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/glasses/hud/health/glasses = allocate(/obj/item/clothing/glasses/hud/health)
	var/datum/component/neural_interface/interface = user.LoadComponent(/datum/component/neural_interface)
	interface.AddSource(glasses.interface_source)
	glasses.interface = interface

	glasses.clear_neural_interface()
	TEST_ASSERT_NULL(glasses.interface, "HUD-очки оставили ссылку на удалённый neural_interface")
	TEST_ASSERT(QDELETED(interface), "Последний neural_interface не удалился после RemoveSource")

/// Точные типы из harddel-лога должны пройти softcheck после освобождения исправленных ссылок.
/datum/unit_test/harddel_cleanup_soft_gc
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/harddel_cleanup_soft_gc/proc/target_record(datum/target, label)
	return list(
		"ref" = REF(target),
		"type_path" = target.type,
		"label" = label,
	)

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_mapped_light(type_path, label)
	var/list/candidates = SSmachines.get_machines_by_type(type_path)
	var/obj/machinery/light/target
	var/obj/machinery/power/apc/target_apc
	for(var/obj/machinery/light/candidate as anything in candidates)
		var/obj/machinery/power/apc/candidate_apc = candidate.get_area_apc()
		if(!candidate_apc)
			continue
		if(!(candidate in candidate_apc.get_cached_area_lights()))
			continue
		target = candidate
		target_apc = candidate_apc
		break
	TEST_ASSERT_NOTNULL(target, "Не найден уже инициализированный [type_path] с APC-кэшем")
	var/list/record = target_record(target, label)

	qdel(target)
	TEST_ASSERT_NULL(target_apc.cached_area_lights, "Удаление [type_path] не очистило кэш APC")
	candidates.Cut()
	target = null
	target_apc = null
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_virtualspeaker_source()
	var/obj/item/warp_machine_beacon/source = new(run_loc_floor_bottom_left)
	var/obj/item/radio/radio = allocate(/obj/item/radio)
	var/atom/movable/virtualspeaker/speaker = allocate(/atom/movable/virtualspeaker, run_loc_floor_bottom_left, source, radio)
	var/list/record = target_record(source, "virtualspeaker source: /obj/item/warp_machine_beacon")

	qdel(source)
	TEST_ASSERT_NULL(speaker.GetSource(), "Virtualspeaker оставил ссылку на удалённый warp beacon")
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_active_parry_item()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/chair/stool/bar/stool = new(run_loc_floor_bottom_left)
	var/list/record = target_record(stool, "active_parry_item: /obj/item/chair/stool/bar")
	user.set_active_parry_item(stool)

	qdel(stool)
	TEST_ASSERT_NULL(user.active_parry_item, "Моб оставил ссылку на удалённый bar stool")
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_card_deck()
	var/obj/item/toy/cards/deck/deck = new(run_loc_floor_bottom_left)
	var/list/record = target_record(deck, "parentdeck: /obj/item/toy/cards/deck")
	qdel(deck)
	TEST_ASSERT_NULL(deck.parentdeck, "Удалённая колода оставила self-reference parentdeck")
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_mind_spell()
	var/datum/mind/mind = new
	allocated += mind
	var/obj/effect/proc_holder/spell/targeted/lewd_chems/spell = new
	var/list/record = target_record(spell, "mind spell_list: /obj/effect/proc_holder/spell/targeted/lewd_chems")
	mind.AddSpell(spell)

	qdel(spell)
	TEST_ASSERT(!(spell in mind.spell_list), "Mind оставил удалённый lewd_chems в spell_list")
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_conjured_item()
	var/obj/effect/proc_holder/spell/targeted/conjure_item/summon_cumburger/spell = allocate(/obj/effect/proc_holder/spell/targeted/conjure_item/summon_cumburger)
	var/obj/item/reagent_containers/food/snacks/burger/cumburger/item = spell.make_item()
	var/list/record = target_record(item, "conjure_item item: /obj/item/reagent_containers/food/snacks/burger/cumburger")

	qdel(item)
	TEST_ASSERT_NULL(spell.item, "Заклинание оставило удалённый cumburger в item")
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/qdel_neural_interface()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/glasses/hud/health/glasses = allocate(/obj/item/clothing/glasses/hud/health)
	var/datum/component/neural_interface/interface = user.LoadComponent(/datum/component/neural_interface)
	interface.AddSource(glasses.interface_source)
	glasses.interface = interface
	var/list/record = target_record(interface, "HUD interface: /datum/component/neural_interface")

	glasses.clear_neural_interface()
	TEST_ASSERT_NULL(glasses.interface, "HUD-очки оставили ссылку на удалённый neural_interface")
	TEST_ASSERT(QDELETED(interface), "Последний neural_interface не удалился после RemoveSource")
	return record

/datum/unit_test/harddel_cleanup_soft_gc/proc/assert_soft_collected(list/target)
	var/type_path = target["type_path"]
	var/label = target["label"]
	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(type_path)
	TEST_ASSERT(item.qdels > 0, "[label] не попал в qdel")
	TEST_ASSERT_EQUAL(item.failures, 0, "[label] не прошёл softcheck")
	TEST_ASSERT_EQUAL(item.warnfail_count, 0, "[label] дошёл до warnfail")
	TEST_ASSERT_EQUAL(item.hard_deletes, 0, "[label] ушёл в hard delete")
	TEST_ASSERT(!(target["ref"] in SSgarbage.queue_refs[GC_QUEUE_SOFTCHECK]), "[label] остался в очереди softcheck")

/datum/unit_test/harddel_cleanup_soft_gc/Run()
	configure_immediate_gc()
	var/list/targets = list()
	targets += list(qdel_mapped_light(/obj/machinery/light, "APC cached_area_lights: /obj/machinery/light"))
	targets += list(qdel_mapped_light(/obj/machinery/light/small, "APC cached_area_lights: /obj/machinery/light/small"))
	targets += list(qdel_virtualspeaker_source())
	targets += list(qdel_active_parry_item())
	targets += list(qdel_card_deck())
	targets += list(qdel_mind_spell())
	targets += list(qdel_conjured_item())
	targets += list(qdel_neural_interface())

	for(var/list/target in targets)
		var/label = target["label"]
		TEST_ASSERT(target["ref"] in SSgarbage.queue_refs[GC_QUEUE_SOFTCHECK], "[label] не был поставлен в очередь softcheck")
	var/start_soft_passes = SSgarbage.pass_counts[GC_QUEUE_SOFTCHECK]
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	TEST_ASSERT(SSgarbage.pass_counts[GC_QUEUE_SOFTCHECK] >= start_soft_passes + length(targets), "SSgarbage не обработал все проверяемые softcheck-записи")

	for(var/list/target in targets)
		assert_soft_collected(target)

/// Обезьяна должна удалять qdeleted предметы из blacklistItems.
/datum/unit_test/monkey_blacklist_item_qdel_cleanup/Run()
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey)
	var/obj/item/item = allocate(/obj/item)
	item.setAnchored(TRUE)
	monkey.set_pickup_target(item)
	TEST_ASSERT(!monkey.equip_item(item), "Обезьяна неожиданно подобрала anchored предмет")
	TEST_ASSERT_NULL(monkey.pickupTarget, "Blacklist-путь не очистил pickupTarget")
	TEST_ASSERT(item in monkey.blacklistItems, "Тестовый предмет не попал в blacklistItems")

	qdel(item)
	TEST_ASSERT(!(item in monkey.blacklistItems), "Обезьяна оставила удалённый предмет в blacklistItems")

/// Halloween closet не должен удерживать моба после удаления или постановки delayed qdel.
/datum/unit_test/spooky_closet_trapped_mob_cleanup/Run()
	var/obj/structure/closet/closet = allocate(/obj/structure/closet)
	var/mob/first_mob = allocate(/mob)
	closet.set_trapped_mob(first_mob)
	qdel(first_mob)
	TEST_ASSERT_NULL(closet.trapped_mob, "Шкаф оставил ссылку на удалённого trapped_mob")

	var/mob/second_mob = allocate(/mob)
	closet.set_trapped_mob(second_mob)
	closet.trapped = SPOOKY_SKELETON
	closet.trigger_spooky_trap()
	TEST_ASSERT_NULL(closet.trapped_mob, "Шкаф удерживает trapped_mob во время delayed qdel")

/// Возврат удаляемого предмета в contents стораджа = вечный harddel (прод: магазин e45
/// в сатчеле). Оба пути вставки (проверочный и force) обязаны отбрасывать QDELETED-ссылки.
/datum/unit_test/storage_rejects_qdeleted_item/Run()
	var/obj/item/storage/backpack/satchel/bag = allocate(/obj/item/storage/backpack/satchel)
	var/obj/item/ammo_box/magazine/e45/magazine = allocate(/obj/item/ammo_box/magazine/e45)
	var/datum/component/storage/storage_comp = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(storage_comp, "У сатчела нет компонента стораджа")

	qdel(magazine)
	TEST_ASSERT(!storage_comp.can_be_inserted(magazine, TRUE), "can_be_inserted пропустил QDELETED-предмет")
	TEST_ASSERT(!storage_comp.handle_item_insertion(magazine, TRUE), "handle_item_insertion вставил QDELETED-предмет")
	TEST_ASSERT_NOTEQUAL(magazine.loc, bag, "QDELETED-предмет оказался в contents сатчела")

/// Броня зомби-генлинга уничтожается и внешними путями (integrity) - компонент обязан
/// отпустить ссылку по сигналу, а не держать её до конца раунда (прод-harddel шлема).
/datum/unit_test/changeling_zombie_armor_qdel_cleanup/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	host.AddComponent(/datum/component/changeling_zombie_infection)
	var/datum/component/changeling_zombie_infection/infection = host.GetComponent(/datum/component/changeling_zombie_infection)
	TEST_ASSERT_NOTNULL(infection, "Компонент заражения не установился на тестового человека")

	infection.make_zombie()
	TEST_ASSERT_NOTNULL(infection.armor, "make_zombie() не выдал броню")
	TEST_ASSERT_NOTNULL(infection.armor_head, "make_zombie() не выдал шлем")

	qdel(infection.armor_head)
	TEST_ASSERT_NULL(infection.armor_head, "Компонент оставил ссылку на удалённый шлем")
	qdel(infection.armor)
	TEST_ASSERT_NULL(infection.armor, "Компонент оставил ссылку на удалённую броню")

/// Магазин и патрон в патроннике лежат в contents ствола, то есть их loc - это
/// жёсткая ссылка обратно на ствол. Без чистки в Destroy ни один удалённый
/// баллистический ствол не собирается мягко и уходит в hard delete; для оружия,
/// которое удаляет себя на каждый выстрел (DROPDEL зачарованные винтовки, залп
/// Arcane Barrage), это был топ-1 источник хардделов в прод-логах.
/datum/unit_test/ballistic_gun_destroy_releases_ammo/Run()
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol)
	var/obj/item/ammo_box/magazine/loaded_magazine = gun.magazine
	var/obj/item/ammo_casing/loaded_round = gun.chambered
	TEST_ASSERT_NOTNULL(loaded_magazine, "Санити: тестовый пистолет обязан заспавниться с магазином")
	TEST_ASSERT_NOTNULL(loaded_round, "Санити: тестовый пистолет обязан заспавниться с патроном в патроннике")
	TEST_ASSERT_EQUAL(loaded_magazine.loc, gun, "Санити: магазин обязан лежать в стволе")

	qdel(gun)

	TEST_ASSERT(QDELETED(loaded_magazine), "Удалённый ствол оставил живой магазин у себя в contents - это внешняя ссылка и гарантированный harddel")
	TEST_ASSERT(QDELETED(loaded_round), "Удалённый ствол оставил живой патрон в патроннике - это внешняя ссылка и гарантированный harddel")
	TEST_ASSERT_NULL(gun.magazine, "Destroy не обнулил ссылку на магазин")
	TEST_ASSERT_NULL(gun.chambered, "Destroy не обнулил ссылку на патронник")

/// Зачарованная винтовка удаляет себя внутри shoot_live_shot. Продолжать цикл
/// выстрела на удалённом стволе нельзя: process_chamber -> chamber_round
/// заталкивает свежий патрон forceMove'ом в qdel-нутый ствол, и тот больше
/// никогда не соберётся.
/datum/unit_test/self_consuming_gun_stops_after_shot/Run()
	var/obj/item/gun/ballistic/shotgun/boltaction/enchanted/arcane_barrage/rifle = allocate(/obj/item/gun/ballistic/shotgun/boltaction/enchanted/arcane_barrage)
	TEST_ASSERT(rifle.item_flags & DROPDEL, "Санити: зачарованная винтовка обязана быть DROPDEL")

	qdel(rifle)

	TEST_ASSERT_NULL(rifle.chambered, "Удалённый самоуничтожающийся ствол оставил патрон в патроннике")
	TEST_ASSERT_NULL(rifle.magazine, "Удалённый самоуничтожающийся ствол оставил магазин")
	for(var/atom/movable/leftover in rifle)
		TEST_FAIL("В contents удалённого ствола остался живой [leftover.type] - он держит ствол от сборки")

/// client.moused_over_objects (память автопарри) обязана хранить текстовые ref'ы,
/// а не сами атомы: жёсткая ссылка здесь переживает qdel цели и невидима
/// ref-сканеру - /client не датум, а клиентский проб читает только
/// mob/eye/statobj/screen/images.
/datum/unit_test/moused_over_tracker_holds_no_hard_refs/Run()
	var/list/tracker = list()
	var/obj/effect/hovered = allocate(/obj/effect)

	register_moused_over(tracker, hovered)

	TEST_ASSERT_EQUAL(length(tracker), 1, "Наведение курсора не попало в память автопарри")
	for(var/key in tracker)
		TEST_ASSERT(istext(key), "Память автопарри держит [key] жёсткой ссылкой вместо текстового ref - это гарантированный harddel цели")

/// Ради автопарри lookup обязан находить именно тот атом, на который наводились.
/datum/unit_test/moused_over_tracker_lookup/Run()
	var/list/tracker = list()
	var/obj/effect/hovered = allocate(/obj/effect)
	var/obj/effect/untouched = allocate(/obj/effect)

	register_moused_over(tracker, hovered)

	TEST_ASSERT_EQUAL(moused_over_time(tracker, hovered), world.time, "Lookup не нашёл наведённый атом - автопарри перестанет срабатывать")
	TEST_ASSERT_NULL(moused_over_time(tracker, untouched), "Lookup нашёл атом, на который не наводились")

/// Память ограничена MOUSED_OVER_MEMORY_MAX и вытесняет самые старые наведения.
/datum/unit_test/moused_over_tracker_evicts_oldest/Run()
	var/list/tracker = list()
	var/list/hovered = list()
	for(var/i in 1 to MOUSED_OVER_MEMORY_MAX + 2)
		var/obj/effect/target = allocate(/obj/effect)
		hovered += target
		register_moused_over(tracker, target)

	TEST_ASSERT(length(tracker) <= MOUSED_OVER_MEMORY_MAX, "Память автопарри разрослась выше капа: [length(tracker)]")
	TEST_ASSERT_NULL(moused_over_time(tracker, hovered[1]), "Самое старое наведение не вытеснилось из памяти")
	TEST_ASSERT_NOTNULL(moused_over_time(tracker, hovered[length(hovered)]), "Самое свежее наведение потерялось при вытеснении")

/// has_status_effect обязан возвращать null, а не 0: DM не считает 0 и null одним
/// и тем же, и QDELETED(0) роняет прок рантаймом "Cannot read 0.gc_destroyed".
/datum/unit_test/absent_status_effect_returns_null/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)

	TEST_ASSERT_NULL(subject.has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE), "Отсутствующий статус-эффект вернул не null - каждый QDELETED() на результате упадёт рантаймом")

/// Проклятие некрополиса на чистом мобе не должно спотыкаться о QDELETED(0).
/datum/unit_test/necropolis_curse_applies_to_uncursed/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)

	subject.apply_necropolis_curse(CURSE_BLINDING, 1 MINUTES)

	TEST_ASSERT_NOTNULL(subject.has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE), "Проклятие не наложилось на моба без проклятия")

/// clear_map снимал экраны прямо в цикле по тому же списку: DM сдвигал список и
/// пропускал каждый второй экран, тот оставался в client.screen. Съём карты
/// обязан отдавать ВСЕ её экраны.
/datum/unit_test/screen_map_takeover_returns_every_screen/Run()
	var/list/screen_maps = list()
	var/list/registered = list()
	for(var/i in 1 to 4)
		var/atom/movable/screen/entry = allocate(/atom/movable/screen)
		entry.assigned_map = "test_map"
		registered += entry
	screen_maps["test_map"] = registered.Copy()

	var/list/taken = take_screen_map(screen_maps, "test_map")

	TEST_ASSERT_EQUAL(length(taken), 4, "Съём карты вернул не все экраны - пропущенные останутся в client.screen")
	for(var/atom/movable/screen/entry as anything in registered)
		TEST_ASSERT(entry in taken, "Экран [entry.type] пропущен при съёме карты")
	TEST_ASSERT(!("test_map" in screen_maps), "Съём карты не удалил запись карты у клиента")

/// У экранов с assigned_map нет hud'а, поэтому из чужого client.screen они сами
/// себя не снимают: консоль камер, уничтоженная при открытом UI, оставляла весь
/// набор плейн-мастеров жить в клиенте смотрящего.
/datum/unit_test/screen_detaches_from_client_maps/Run()
	var/list/screen_maps = list()
	var/atom/movable/screen/first = allocate(/atom/movable/screen)
	var/atom/movable/screen/second = allocate(/atom/movable/screen)
	var/atom/movable/screen/stranger = allocate(/atom/movable/screen)
	first.assigned_map = "test_map"
	second.assigned_map = "test_map"
	screen_maps["test_map"] = list(first, second)

	TEST_ASSERT(detach_screen_from_client_maps(screen_maps, first), "Экран не нашёлся в картах клиента")
	var/list/remaining = screen_maps["test_map"]
	TEST_ASSERT_EQUAL(length(remaining), 1, "Отвязка сняла не тот набор экранов")
	TEST_ASSERT(second in remaining, "Отвязка сняла лишний экран")
	TEST_ASSERT(!detach_screen_from_client_maps(screen_maps, stranger), "Отвязка отчиталась об экране, которого в картах нет")

	TEST_ASSERT(detach_screen_from_client_maps(screen_maps, second), "Последний экран карты не нашёлся")
	TEST_ASSERT(!("test_map" in screen_maps), "Опустевшая карта осталась записью у клиента")

/// mob.machine - хардреф на объект, который игрок "использует". Ставит его
/// /obj/machinery/interact() для почти всякой машины (INTERACT_MACHINE_SET_MACHINE
/// включён по умолчанию) и сборки/консоли через set_machine() напрямую, а снимался
/// он только при открытии следующей машины. Удалённая машина оставалась висеть в
/// mob.machine - стабильный "внешних ссылок: 1" в прод-логах на телекомах,
/// протолейтах, насосах и сигналер-игнитер-сборках.
/datum/unit_test/destroyed_machine_releases_its_users/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/machinery/first = allocate(/obj/machinery, run_loc_floor_bottom_left)
	var/obj/machinery/second = allocate(/obj/machinery, get_step(run_loc_floor_bottom_left, EAST))

	user.set_machine(first)
	TEST_ASSERT_EQUAL(user.machine, first, "set_machine() обязан записать машину пользователю")
	TEST_ASSERT(user in first.machine_users, "set_machine() обязан завести обратный индекс на машине")

	// Переключение на другую машину снимает пользователя с прежней.
	user.set_machine(second)
	TEST_ASSERT(!(user in first.machine_users), "Переключение машины обязано снять пользователя с прежней")
	TEST_ASSERT(user in second.machine_users, "Переключение машины обязано записать пользователя новой")

	// Явный unset тоже чистит индекс - иначе объект держал бы моба.
	user.unset_machine()
	TEST_ASSERT_NULL(user.machine, "unset_machine() обязан снять машину с пользователя")
	TEST_ASSERT(!LAZYLEN(second.machine_users), "unset_machine() обязан очистить обратный индекс")

	// Главное: удаление машины обязано снять её со всех, кто её использовал.
	user.set_machine(second)
	qdel(second)
	TEST_ASSERT_NULL(user.machine, "Удаление машины обязано снять её с mob.machine у всех пользователей")

	qdel(first)

/// Обратная сторона: индекс на машине держит мобов, поэтому смерть моба обязана
/// вычищать его оттуда, иначе машина пинит труп.
/datum/unit_test/destroyed_machine_user_leaves_the_index/Run()
	var/obj/machinery/machine = allocate(/obj/machinery, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)

	user.set_machine(machine)
	TEST_ASSERT(user in machine.machine_users, "Sanity: пользователь обязан попасть в индекс")

	qdel(user)
	TEST_ASSERT(!LAZYLEN(machine.machine_users), "Удаление моба обязано убрать его из machine_users - иначе машина держит труп")

	qdel(machine)

/// Сборка отдаёт электронику готовой двери, после чего сама уходит в qdel.
/// Если сборка не обнулит свою переменную, её QDEL_NULL(electronics) убьёт
/// электронику уже живой двери: дверь остаётся с висячей ссылкой, а electronics
/// не собирается GC (прод-раунд 9807 - найдена в вар electronics живого шлюза).
/datum/unit_test/door_assembly_hands_off_electronics/Run()
	var/obj/structure/door_assembly/assembly = allocate(/obj/structure/door_assembly, run_loc_floor_bottom_left)
	var/obj/item/electronics/airlock/brain = allocate(/obj/item/electronics/airlock)
	assembly.electronics = brain
	brain.forceMove(assembly)

	var/obj/machinery/door/airlock/door = assembly.finish_door()

	TEST_ASSERT_NOTNULL(door, "finish_door() не вернул дверь")
	TEST_ASSERT(QDELETED(assembly), "Сборка обязана удалиться после сборки двери")
	TEST_ASSERT(!QDELETED(brain), "Destroy сборки удалил электронику, уже отданную двери")
	TEST_ASSERT_EQUAL(door.electronics, brain, "Дверь не получила электронику сборки")

	qdel(door)

/// Тот же контракт для промежуточной пересборки (смена материала/типа сборки):
/// электроника переезжает в target, source уходит в qdel и не должен её утащить.
/datum/unit_test/door_assembly_transfer_keeps_electronics/Run()
	var/obj/structure/door_assembly/source = allocate(/obj/structure/door_assembly, run_loc_floor_bottom_left)
	var/obj/structure/door_assembly/target = allocate(/obj/structure/door_assembly, run_loc_floor_bottom_left)
	var/obj/item/electronics/airlock/brain = allocate(/obj/item/electronics/airlock)
	source.electronics = brain
	brain.forceMove(source)

	source.transfer_assembly_vars(source, target)

	TEST_ASSERT(QDELETED(source), "Исходная сборка обязана удалиться после переноса")
	TEST_ASSERT(!QDELETED(brain), "Destroy исходной сборки удалил перенесённую электронику")
	TEST_ASSERT_EQUAL(target.electronics, brain, "Целевая сборка не получила электронику")
