/datum/atom_hud/z_group_probe
	var/list/shown_to = list()

/datum/atom_hud/z_group_probe/add_to_single_hud(mob/viewer, atom/movable/target, list/hud_icon_keys = hud_icons)
	shown_to += viewer
	return ..()

/// Значки уходят только зрителям той же группы z, в том числе после переезда атома на другой уровень
/datum/unit_test/atom_hud_z_group_delivery
	var/datum/atom_hud/z_group_probe/hud

/datum/unit_test/atom_hud_z_group_delivery/Run()
	var/local_z = run_loc_floor_bottom_left.z
	var/other_z = local_z == 1 ? 2 : 1
	var/local_group = get_hud_z_group(local_z)
	var/other_group = get_hud_z_group(other_z)
	TEST_ASSERT_NOTEQUAL(local_group, other_group, "Предпосылка: резервация и уровень [other_z] должны быть в разных группах")

	hud = new
	hud.hud_icons = list(HEALTH_HUD)
	var/mob/living/carbon/human/local_viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/remote_viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	hud.add_hud_to(local_viewer)
	hud.add_hud_to(remote_viewer)
	remote_viewer.hud_view_group = other_group

	var/obj/effect/marked = allocate(/obj/effect, run_loc_floor_bottom_left)
	marked.hud_list = list(HEALTH_HUD = image('icons/mob/hud.dmi'))
	hud.add_to_hud(marked)
	TEST_ASSERT(local_viewer in hud.shown_to, "Зритель той же группы должен получить значок")
	TEST_ASSERT(!(remote_viewer in hud.shown_to), "Зритель другой группы не должен получать значок")

	hud.shown_to.Cut()
	marked.update_hud_z_group(other_z)
	TEST_ASSERT_EQUAL(marked.hud_z_group, other_group, "Переезд должен записать атому новую группу")
	TEST_ASSERT(remote_viewer in hud.shown_to, "После переезда значок должны получить зрители новой группы")
	TEST_ASSERT(!(local_viewer in hud.shown_to), "После переезда значок не должен выдаваться зрителям старой группы")

/datum/unit_test/atom_hud_z_group_delivery/Destroy()
	QDEL_NULL(hud)
	return ..()

/// Сбор значков для зрителя берёт только его группу, а снятие худа - все группы
/datum/unit_test/atom_hud_z_group_collect
	var/datum/atom_hud/hud

/datum/unit_test/atom_hud_z_group_collect/Run()
	var/other_z = run_loc_floor_bottom_left.z == 1 ? 2 : 1
	hud = new
	hud.hud_icons = list(HEALTH_HUD)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	var/obj/effect/near_atom = allocate(/obj/effect, run_loc_floor_bottom_left)
	var/image/near_image = image('icons/mob/hud.dmi')
	near_atom.hud_list = list(HEALTH_HUD = near_image)
	hud.add_to_hud(near_atom)
	var/obj/effect/far_atom = allocate(/obj/effect, run_loc_floor_bottom_left)
	var/image/far_image = image('icons/mob/hud.dmi')
	far_atom.hud_list = list(HEALTH_HUD = far_image)
	hud.add_to_hud(far_atom)
	far_atom.update_hud_z_group(other_z)

	var/list/visible = list()
	hud.collect_hud_images_for(viewer, visible)
	TEST_ASSERT(near_image in visible, "Значок атома своей группы должен собираться")
	TEST_ASSERT(!(far_image in visible), "Значок атома чужой группы не должен собираться")

	var/list/everything = list()
	hud.collect_hud_images_for(viewer, everything, check_visibility = FALSE, z_group = HUD_Z_GROUP_ANY)
	TEST_ASSERT(far_image in everything, "Снятие худа должно собирать значки всех групп")

/datum/unit_test/atom_hud_z_group_collect/Destroy()
	QDEL_NULL(hud)
	return ..()

/// Уход в nullspace и возврат переводят группу атома, а зритель пересчитывает группу по уровню переезда
/datum/unit_test/atom_hud_z_group_tracking
	var/datum/atom_hud/hud

/datum/unit_test/atom_hud_z_group_tracking/Run()
	var/local_group = get_hud_z_group(run_loc_floor_bottom_left.z)
	var/other_z = run_loc_floor_bottom_left.z == 1 ? 2 : 1
	hud = new
	hud.hud_icons = list(HEALTH_HUD)
	var/obj/item/crowbar/marked = allocate(/obj/item/crowbar, run_loc_floor_bottom_left)
	marked.hud_list = list(HEALTH_HUD = image('icons/mob/hud.dmi'))
	hud.add_to_hud(marked)
	TEST_ASSERT_EQUAL(marked.get_hud_z_group_cached(), local_group, "Атом должен получить группу своего уровня")

	marked.moveToNullspace()
	TEST_ASSERT_EQUAL(marked.hud_z_group, 0, "Уход в nullspace должен обнулять группу")
	marked.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(marked.hud_z_group, local_group, "Возврат на уровень должен восстанавливать группу")

	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(viewer.get_hud_view_group_cached(), local_group, "Зритель должен смотреть на группу своего уровня")
	viewer.refresh_hud_view_group(other_z)
	TEST_ASSERT_EQUAL(viewer.hud_view_group, get_hud_z_group(other_z), "Переезд зрителя должен переводить его группу")

/datum/unit_test/atom_hud_z_group_tracking/Destroy()
	QDEL_NULL(hud)
	return ..()
