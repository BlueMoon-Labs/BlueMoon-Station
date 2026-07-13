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
