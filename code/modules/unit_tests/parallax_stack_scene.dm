/// Этажи одной стопки делят сцену параллакса, пока на них нет своих модификаторов.

#define PARALLAX_STACK_TEST_TOKEN "unit_test_stack_scene"

/datum/unit_test/parallax_stack_shares_scene
	var/lower_z
	var/upper_z
	var/list/saved = list()

/datum/unit_test/parallax_stack_shares_scene/Run()
	var/list/by_environment = list()
	for(var/z in 1 to world.maxz)
		var/environment_key = "[SSparallax.environment_for_z(z)]"
		var/list/same = by_environment[environment_key] || list()
		same += z
		by_environment[environment_key] = same
		if(length(same) == 2)
			lower_z = same[1]
			upper_z = same[2]
			break
	TEST_ASSERT_NOTNULL(upper_z, "Нет двух z с одинаковым окружением для учебной стопки")
	isolate_levels()

	TEST_ASSERT_EQUAL(SSparallax.get_base_profile(upper_z), SSparallax.get_base_profile(lower_z), "Этажи одной стопки обязаны получить один профиль неба")
	var/datum/parallax/shared = SSparallax.get_parallax_template(lower_z)
	TEST_ASSERT_NOTNULL(shared, "Сцена нижнего этажа не собралась")
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(upper_z), shared, "Этажи одной стопки обязаны делить одну сцену")

	SSparallax.add_modifier(upper_z, PARALLAX_STACK_TEST_TOKEN, "unit_test_scene_alt")
	var/datum/parallax/upper_own = SSparallax.get_parallax_template(upper_z)
	TEST_ASSERT_NOTEQUAL(upper_own, shared, "Модификатор этажа обязан дать ему свою сцену")
	TEST_ASSERT(QDELETED(shared), "Сцена, которую сменил модификатор, обязана удалиться")
	var/datum/parallax/lower_after = SSparallax.get_parallax_template(lower_z)
	TEST_ASSERT(!QDELETED(lower_after), "Соседний этаж не должен остаться с удалённой сценой")
	TEST_ASSERT_NOTEQUAL(lower_after, upper_own, "Чужой модификатор не должен попасть в сцену соседа")

	SSparallax.remove_modifier(upper_z, PARALLAX_STACK_TEST_TOKEN)
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(upper_z), SSparallax.get_parallax_template(lower_z), "Без модификаторов этажи обязаны снова делить сцену")

/// Учебная стопка из двух z с чистым кэшем неба; Destroy() возвращает всё как было.
/datum/unit_test/parallax_stack_shares_scene/proc/isolate_levels()
	var/list/fake_stack = list(lower_z, upper_z)
	for(var/z in fake_stack)
		var/key = "[z]"
		saved[key] = list(
			"stack" = SSmapping.z_level_to_stack[z],
			"profile" = SSparallax.base_profile_by_z[key],
			"template" = SSparallax.parallax_templates_by_z[key],
			"modifiers" = SSparallax.modifiers_by_z[key],
			"revision" = SSparallax.revision_by_z[key],
		)
		SSmapping.z_level_to_stack[z] = fake_stack
		SSparallax.base_profile_by_z -= key
		SSparallax.parallax_templates_by_z -= key
		SSparallax.modifiers_by_z -= key
		SSparallax.revision_by_z[key] = 0

/datum/unit_test/parallax_stack_shares_scene/Destroy()
	for(var/key in saved)
		var/z = text2num(key)
		var/list/state = saved[key]
		SSparallax.remove_modifier(z, PARALLAX_STACK_TEST_TOKEN)
		var/datum/parallax/ours = SSparallax.parallax_templates_by_z[key]
		SSmapping.z_level_to_stack[z] = state["stack"]
		SSparallax.base_profile_by_z[key] = state["profile"]
		SSparallax.parallax_templates_by_z[key] = state["template"]
		SSparallax.modifiers_by_z[key] = state["modifiers"]
		SSparallax.revision_by_z[key] = state["revision"]
		if(ours && ours != state["template"] && !QDELETED(ours))
			qdel(ours)
	return ..()

#undef PARALLAX_STACK_TEST_TOKEN
