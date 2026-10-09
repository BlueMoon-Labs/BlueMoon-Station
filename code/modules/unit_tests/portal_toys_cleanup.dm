/// Удаление портальных трусиков и фонариков в любом порядке не портит связи и списки оставшихся устройств.
/datum/unit_test/portal_toys_cleanup

/datum/unit_test/portal_toys_cleanup/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	for(var/lights_first in list(TRUE, FALSE))
		for(var/harddel_leftovers in list(FALSE, TRUE))
			check_deletion_order(user, lights_first, harddel_leftovers)
	check_reconnected_light(user)
	check_group_index()

/datum/unit_test/portal_toys_cleanup/proc/check_deletion_order(mob/living/carbon/human/user, lights_first, harddel_leftovers)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/paired_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/lonely_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/public_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/private_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/portallight/paired_light = allocate(/obj/item/portallight)
	var/obj/item/portallight/lonely_light = allocate(/obj/item/portallight)
	var/obj/item/portallight/public_light = allocate(/obj/item/portallight)
	var/obj/item/portallight/private_light = allocate(/obj/item/portallight)

	paired_panties.attackby(paired_light, user)
	public_panties.portal_settings.connection_mode = PORTAL_MODE_PUBLIC
	GLOB.public_portal_panties |= public_panties
	for(var/obj/item/portallight/light in GLOB.fleshlight_portallight)
		light.available_panties |= public_panties
	public_light.portalunderwear = public_panties
	public_panties.portallight |= public_light
	private_panties.set_private_pair(private_light)
	TEST_ASSERT(paired_light in paired_panties.portallight, "фонарик не сопрягся с трусиками")
	TEST_ASSERT(public_panties in lonely_light.available_panties, "публичные трусики не видны фонарику")

	var/list/all_panties = list(paired_panties, lonely_panties, public_panties, private_panties)
	var/list/all_lights = list(lonely_light, paired_light, public_light, private_light)
	var/list/devices = all_panties + all_lights
	var/list/order = lights_first ? all_lights + all_panties : all_panties + all_lights
	var/scenario = "[lights_first ? "фонарики первыми" : "трусики первыми"][harddel_leftovers ? ", null в глобальных списках" : ""]"
	for(var/obj/item/doomed as anything in order)
		// так в проде выглядит слот устройства, ушедшего в harddel
		if(harddel_leftovers)
			GLOB.portalpanties += null
			GLOB.fleshlight_portallight += null
		qdel(doomed)
		if(harddel_leftovers)
			GLOB.portalpanties -= null
			GLOB.fleshlight_portallight -= null
		var/problem = find_dangling(doomed, devices)
		TEST_ASSERT(isnull(problem), "[problem] ([scenario])")
		if(!QDELETED(paired_panties) && !QDELETED(paired_light))
			TEST_ASSERT(paired_light in paired_panties.portallight, "удаление [doomed] разорвало чужую пару ([scenario])")
			TEST_ASSERT_EQUAL(paired_light.portalunderwear, paired_panties, "удаление [doomed] отключило чужой фонарик ([scenario])")
		if(!QDELETED(public_panties) && !QDELETED(public_light))
			TEST_ASSERT(public_light in public_panties.portallight, "удаление [doomed] отключило фонарик от публичных трусиков ([scenario])")
		if(!QDELETED(private_panties) && !QDELETED(private_light))
			TEST_ASSERT_EQUAL(private_panties.private_pair, private_light, "удаление [doomed] сбросило чужую приватную пару ([scenario])")

/// Текст первой найденной ссылки на удалённое устройство или поломанного списка, null если всё чисто.
/datum/unit_test/portal_toys_cleanup/proc/find_dangling(obj/item/doomed, list/devices)
	if(!isnull(doomed.loc))
		return "[doomed.type] не дошёл до конца Destroy"
	for(var/list/global_list in list(GLOB.portalpanties, GLOB.fleshlight_portallight, GLOB.public_portal_panties))
		if(doomed in global_list)
			return "удалённый [doomed.type] остался в глобальном списке"
		if(null in global_list)
			return "в глобальном списке портальных устройств остался null"
	for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/panties in devices)
		if(QDELETED(panties))
			continue
		if(!islist(panties.portallight))
			return "portallight у живых трусиков стал [isnull(panties.portallight) ? "null" : panties.portallight]"
		if((doomed in panties.portallight) || panties.private_pair == doomed)
			return "живые трусики держат удалённый [doomed.type]"
	for(var/obj/item/portallight/light in devices)
		if(QDELETED(light))
			continue
		if(!islist(light.available_panties))
			return "available_panties у живого фонарика не список"
		if((doomed in light.available_panties) || light.portalunderwear == doomed || light.private_pair == doomed)
			return "живой фонарик держит удалённый [doomed.type]"
	return null

/datum/unit_test/portal_toys_cleanup/proc/check_reconnected_light(mob/living/carbon/human/user)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/first_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/second_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/current_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/portallight/light = allocate(/obj/item/portallight)
	first_panties.attackby(light, user)
	second_panties.attackby(light, user)
	current_panties.attackby(light, user)
	TEST_ASSERT_EQUAL(light.portalunderwear, current_panties, "фонарик не переключился на последние трусики")
	qdel(first_panties)
	TEST_ASSERT_EQUAL(light.portalunderwear, current_panties, "удаление прежних трусиков отключило фонарик от нынешних")
	qdel(light)
	TEST_ASSERT(!(light in second_panties.portallight), "прежние трусики держат удалённый фонарик")
	TEST_ASSERT(!(light in current_panties.portallight), "нынешние трусики держат удалённый фонарик")

/datum/unit_test/portal_toys_cleanup/proc/check_group_index()
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/group_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/portallight/member_light = allocate(/obj/item/portallight)
	var/datum/portal_network/network = new("unit test", null)
	network.add_member(member_light.portal_settings)
	network.add_member(group_panties.portal_settings)
	group_panties.portal_settings.connection_mode = PORTAL_MODE_GROUP
	network.update_group_panties_index(group_panties.portal_settings)
	TEST_ASSERT(group_panties in network.group_mode_panties, "трусики не попали в индекс группы")
	qdel(group_panties)
	TEST_ASSERT(!(group_panties in network.group_mode_panties), "сеть держит удалённые трусики в индексе группы")
	qdel(member_light)
	TEST_ASSERT(QDELETED(network), "опустевшая сеть не удалилась")

/// Цепочка из раунда 10460 (удалить фонарик, сопрячь другой с трусиками, удалить оба) собирается без hard delete.
/datum/unit_test/portal_toys_soft_collected
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/portal_toys_soft_collected/proc/run_prod_cascade()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/panties = new(run_loc_floor_bottom_left)
	var/obj/item/portallight/first_light = new(run_loc_floor_bottom_left)
	var/obj/item/portallight/second_light = new(run_loc_floor_bottom_left)
	var/list/records = list(
		target_record(first_light, "/obj/item/portallight (удалён первым)"),
		target_record(second_light, "/obj/item/portallight (сопряжённый)"),
		target_record(panties, "/obj/item/clothing/underwear/briefs/panties/portalpanties"),
	)
	qdel(first_light)
	panties.attackby(second_light, user)
	qdel(second_light)
	qdel(panties)
	return records

/datum/unit_test/portal_toys_soft_collected/Run()
	begin_isolated_gc()
	var/list/records = run_prod_cascade()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	for(var/list/record in records)
		assert_soft_collected(record)
