/datum/unit_test/proc/has_sepia_colour(mob/living/viewer)
	for(var/datum/client_colour/colour as anything in viewer.client_colours)
		if(colour.type == /datum/client_colour/sepia)
			return TRUE
	return FALSE

/datum/unit_test/proc/make_split_personality(mob/living/carbon/human/host)
	var/datum/brain_trauma/severe/split_personality/trauma = new
	trauma.owner = host
	trauma.make_backseats()
	trauma.RegisterSignal(host, COMSIG_MOB_DEATH, TYPE_PROC_REF(/datum/brain_trauma/severe/split_personality, revert_to_normal))
	return trauma

/// Клиент ушёл из замороженного тела (смерть, призрак): снятие поля обязано вернуть телу HUD, цвет и зрение, иначе следующий вход видит серый экран без интерфейса
/datum/unit_test/timestop_restores_view_after_client_left

/datum/unit_test/timestop_restores_view_after_client_left/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.set_hud_used(new /datum/hud/human(victim))
	var/old_sight = victim.sight
	var/obj/effect/timestop/field = allocate(/obj/effect/timestop, run_loc_floor_bottom_left, 1, 10 SECONDS, null, FALSE)
	field.timestop()
	var/datum/proximity_monitor/advanced/timestop/chronofield = field.chronofield
	TEST_ASSERT_NOTNULL(chronofield, "Sanity: таймстоп обязан построить хронополе")
	TEST_ASSERT(chronofield.frozen_mobs.Find(victim), "Sanity: человек в радиусе поля обязан замёрзнуть")

	// так заморозка видит тело с клиентом; клиент затем уходит, и снятие поля застаёт тело пустым
	chronofield.show_frozen_world(victim)
	TEST_ASSERT(has_sepia_colour(victim), "Sanity: застывший мир обязан красить экран сепией")
	TEST_ASSERT_EQUAL(victim.hud_used.hud_version, HUD_STYLE_NOHUD, "Sanity: застывший мир обязан прятать HUD")
	victim.death()

	qdel(field)
	TEST_ASSERT(!has_sepia_colour(victim), "Сепия таймстопа осталась на теле, которое покинул клиент")
	TEST_ASSERT_EQUAL(victim.hud_used.hud_version, HUD_STYLE_STANDARD, "HUD остался скрытым после таймстопа, пока в теле не было клиента")
	TEST_ASSERT(victim.hud_used.hud_shown, "HUD после таймстопа не помечен показанным")
	TEST_ASSERT_EQUAL(victim.sight, old_sight, "Слепота таймстопа осталась на теле без клиента")

/// Раздвоение личности: вторая личность у руля, тело убивают внутри таймстопа - хозяин возвращается в тело, а после поля оно без серого фильтра и со своим HUD
/datum/unit_test/timestop_split_personality_death_restores_view

/datum/unit_test/timestop_split_personality_death_restores_view/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	host.set_hud_used(new /datum/hud/human(host))
	var/datum/brain_trauma/severe/split_personality/trauma = make_split_personality(host)
	trauma.current_controller = TRUE
	var/obj/effect/timestop/field = allocate(/obj/effect/timestop, run_loc_floor_bottom_left, 1, 10 SECONDS, null, FALSE)
	field.timestop()
	var/datum/proximity_monitor/advanced/timestop/chronofield = field.chronofield
	TEST_ASSERT_NOTNULL(chronofield, "Sanity: таймстоп обязан построить хронополе")
	chronofield.show_frozen_world(host)

	host.death()
	TEST_ASSERT(QDELETED(trauma), "Смерть тела обязана снимать раздвоение личности")
	TEST_ASSERT(has_sepia_colour(host), "Sanity: поле ещё стоит, сепия должна держаться")

	qdel(field)
	TEST_ASSERT(!has_sepia_colour(host), "После смены личности и смерти в таймстопе на теле осталась сепия")
	TEST_ASSERT_EQUAL(host.hud_used.hud_version, HUD_STYLE_STANDARD, "После смены личности и смерти в таймстопе HUD остался скрытым")

/// Без таймстопа смерть тела с второй личностью у руля не трогает его HUD и цвет экрана
/datum/unit_test/split_personality_death_keeps_hud

/datum/unit_test/split_personality_death_keeps_hud/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(host)
	host.set_hud_used(hud)
	var/datum/brain_trauma/severe/split_personality/trauma = make_split_personality(host)
	var/mob/living/split_personality/stranger = trauma.stranger_backseat
	trauma.current_controller = TRUE

	host.death()
	TEST_ASSERT(QDELETED(trauma), "Смерть тела обязана снимать раздвоение личности")
	TEST_ASSERT(QDELETED(stranger), "Снятие раздвоения обязано удалять бэксит второй личности")
	TEST_ASSERT_EQUAL(host.hud_used, hud, "Смена личности при смерти заменила HUD тела")
	TEST_ASSERT_EQUAL(hud.hud_version, HUD_STYLE_STANDARD, "Смена личности при смерти спрятала HUD тела")
	TEST_ASSERT(!length(host.client_colours), "Смена личности при смерти оставила цвет экрана")

/// Стиль HUD, выбранный без клиента, обязан дожить до следующего входа: Login показывает hud_version
/datum/unit_test/hud_version_kept_without_client

/datum/unit_test/hud_version_kept_without_client/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(owner)
	owner.set_hud_used(hud)
	hud.hud_version = HUD_STYLE_NOHUD
	hud.hud_shown = FALSE

	hud.show_hud(HUD_STYLE_STANDARD)
	TEST_ASSERT_EQUAL(hud.hud_version, HUD_STYLE_STANDARD, "show_hud() без клиента забыл запрошенный стиль")
	TEST_ASSERT(hud.hud_shown, "show_hud() без клиента не пометил HUD показанным")
	hud.show_hud()
	TEST_ASSERT_EQUAL(hud.hud_version, HUD_STYLE_STANDARD, "Переключение по F12 без клиента не должно менять стиль")
