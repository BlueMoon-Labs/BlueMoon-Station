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
	TEST_ASSERT(accessory in uniform.attached_accessories, "Прикреплённый аксессуар не попал в список униформы")
	TEST_ASSERT_EQUAL(uniform.armor.get_rating(MELEE), 15, "Аксессуар не добавил броню униформе")

	qdel(accessory)
	TEST_ASSERT(!(accessory in uniform.attached_accessories), "Удалённый аксессуар остался в списке униформы")
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
