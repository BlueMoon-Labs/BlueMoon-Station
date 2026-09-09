// Реестр редактируемых знаков собирается из дерева типов по паре is_editable +
// sign_change_name, а ключ списка - имя. Значит любая опечатка или унаследованное
// подтипом имя тихо выкидывает тип из выбора у ручки, ничего при этом не ломая.
/datum/unit_test/editable_sign_types_registry/Run()
	TEST_ASSERT(length(GLOB.editable_sign_types), "the editable sign registry must not be empty")

	for(var/change_name in GLOB.editable_sign_types)
		TEST_ASSERT(istext(change_name) && length(change_name), "the editable sign registry must not hold a blank key")
		var/obj/structure/sign/sign_type = GLOB.editable_sign_types[change_name]
		TEST_ASSERT_NOTNULL(sign_type, "editable sign \"[change_name]\" must map to a type")
		// Совпадение имени с ключом означает, что запись поставил сам тип, а не его родитель:
		// подтип с унаследованным sign_change_name затёр бы родителя под тем же ключом.
		TEST_ASSERT_EQUAL(initial(sign_type.sign_change_name), change_name, \
			"editable sign \"[change_name]\" must be registered by the type that names itself so, not by a subtype of it")

	// Список, который до разбора был захардкожен в /obj/structure/sign/attackby.
	var/static/list/expected = list(
		"Blank Sign", "Secure Area", "Biohazard", "High Voltage", "Radiation", "Hard Vacuum Ahead",
		"Disposal: Leads To Space", "Danger: Fire", "No Smoking", "Medbay", "Science", "Chemistry",
		"Hydroponics", "Xenobiology",
	)
	for(var/change_name in expected)
		TEST_ASSERT(change_name in GLOB.editable_sign_types, "a pen on a sign must still offer \"[change_name]\"")

	// Подтипы помеченных типов гасят флаг сами - иначе они заняли бы имя родителя.
	for(var/obj/structure/sign/shadowing as anything in list(/obj/structure/sign/warning/vacuum/external, /obj/structure/sign/warning/radiation/rad_area))
		TEST_ASSERT(!initial(shadowing.is_editable), "[shadowing] inherits its parent's sign_change_name and must not stay editable")

// Со стены знак снимается в /obj/item/sign - единственную подложку. Отдельного
// /obj/item/sign_backing больше нет: он ставился на любой турф без сдвига на стену,
// поэтому снятый и повешенный обратно знак оказывался посреди пола.
/datum/unit_test/sign_backing_is_one_type/Run()
	TEST_ASSERT_NULL(text2path("/obj/item/sign_backing"), "the second sign backing type must stay deleted")

	var/obj/structure/sign/warning/biohazard/reference = /obj/structure/sign/warning/biohazard
	var/obj/item/sign/backing = allocate(/obj/item/sign, run_loc_floor_bottom_left)
	backing.set_sign_type(reference)
	TEST_ASSERT_EQUAL(backing.sign_path, reference, "a backing must remember which sign it turns into")
	TEST_ASSERT_EQUAL(backing.icon_state, initial(reference.icon_state), "a backing must look like the sign it turns into")
	TEST_ASSERT_EQUAL(backing.name, initial(reference.name), "a backing must be named after the sign it turns into")
