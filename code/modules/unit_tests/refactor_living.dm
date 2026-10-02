/// Тело отпускается сразу после qdel при связях, которые заводит living.dm.
/datum/unit_test/living_destroy_releases_body
	var/list/failed_labels

/datum/unit_test/living_destroy_releases_body/proc/new_human()
	var/mob/living/carbon/human/body = new(run_loc_floor_bottom_left)
	return body

/datum/unit_test/living_destroy_releases_body/proc/new_sleeper()
	var/mob/living/carbon/human/sleeper = new_human()
	allocated += sleeper
	sleeper.SetSleeping(100)
	sleeper.update_stat()
	return sleeper

/datum/unit_test/living_destroy_releases_body/proc/release(mob/living/carbon/human/body)
	var/ref = REF(body)
	qdel(body)
	return ref

/datum/unit_test/living_destroy_releases_body/proc/scenario_plain()
	return release(new_human())

/datum/unit_test/living_destroy_releases_body/proc/scenario_sleeping_near_sleeper()
	new_sleeper()
	var/mob/living/carbon/human/body = new_human()
	body.SetSleeping(100)
	body.update_stat()
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/scenario_pulling()
	var/mob/living/carbon/human/body = new_human()
	var/mob/living/carbon/human/other = new_human()
	allocated += other
	body.start_pulling(other, supress_message = TRUE)
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/scenario_pulled()
	var/mob/living/carbon/human/body = new_human()
	var/mob/living/carbon/human/other = new_human()
	allocated += other
	other.start_pulling(body, supress_message = TRUE)
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/scenario_burning()
	var/mob/living/carbon/human/body = new_human()
	body.adjust_fire_stacks(5)
	body.IgniteMob()
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/scenario_sterilized()
	var/mob/living/carbon/human/body = new_human()
	body.sterilize(10, 1 MINUTES)
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/scenario_buckled()
	var/mob/living/carbon/human/body = new_human()
	var/obj/structure/chair/seat = new(run_loc_floor_bottom_left)
	allocated += seat
	seat.buckle_mob(body, force = TRUE)
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/scenario_revived()
	var/mob/living/carbon/human/body = new_human()
	body.death()
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	return release(body)

/datum/unit_test/living_destroy_releases_body/proc/check_released(label, proc_name)
	var/ref = call(src, proc_name)()
	for(var/attempt in 1 to 50)
		// view() держит атомы последнего результата до следующего вызова
		pass(view(0, run_loc_floor_bottom_left))
		sleep(1)
		if(!locate(ref))
			return
	LAZYADD(failed_labels, label)

/datum/unit_test/living_destroy_releases_body/Run()
	check_released("plain", PROC_REF(scenario_plain))
	check_released("sleeping_near_sleeper", PROC_REF(scenario_sleeping_near_sleeper))
	check_released("pulling", PROC_REF(scenario_pulling))
	check_released("pulled", PROC_REF(scenario_pulled))
	check_released("burning", PROC_REF(scenario_burning))
	check_released("sterilized", PROC_REF(scenario_sterilized))
	check_released("buckled", PROC_REF(scenario_buckled))
	check_released("revived", PROC_REF(scenario_revived))
	TEST_ASSERT(!length(failed_labels), "Тело не отпущено после qdel: [english_list(failed_labels)]")

/// Новый человек попадает в зрители своей внешности для спящего ровно один раз.
/datum/unit_test/living_init_unconscious_appearance_once/Run()
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human)
	sleeper.SetSleeping(100)
	sleeper.update_stat()
	TEST_ASSERT_EQUAL(sleeper.stat, UNCONSCIOUS, "Спящий не без сознания")

	var/mob/living/carbon/human/newcomer = allocate(/mob/living/carbon/human)
	var/datum/atom_hud/alternate_appearance/basic/unconscious_obscurity/obscurity = newcomer.alternate_appearances?["[REF(newcomer)]_unconscious"]
	TEST_ASSERT_NOTNULL(obscurity, "У нового человека нет внешности для спящих")
	TEST_ASSERT_EQUAL(obscurity.hudusers[sleeper], 1, "Спящий записан в зрители внешности не один раз")

/// После qdel моб не остаётся ни в одном data-худе.
/datum/unit_test/living_destroy_leaves_data_huds/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	var/datum/atom_hud/medhud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	TEST_ASSERT(body in medhud.hudatoms, "Человек не попал в медицинский худ")
	qdel(body)
	for(var/datum/atom_hud/data/hud in GLOB.all_huds)
		TEST_ASSERT(!(body in hud.hudatoms), "[hud.type] держит удалённого моба в hudatoms")
	TEST_ASSERT(!LAZYLEN(body.hud_memberships), "У удалённого моба остались hud_memberships")
