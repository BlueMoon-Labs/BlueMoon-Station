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
	TEST_ASSERT(!has_sepia_colour(host), "Смерть в поле обязана сразу снимать сепию с тела")

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

/datum/unit_test/proc/make_timestop_field(mob/living/victim)
	var/obj/effect/timestop/field = allocate(/obj/effect/timestop, run_loc_floor_bottom_left, 1, 10 SECONDS, null, FALSE)
	field.timestop()
	TEST_ASSERT_NOTNULL(field.chronofield, "Sanity: таймстоп обязан построить хронополе")
	TEST_ASSERT(field.chronofield.frozen_mobs.Find(victim), "Sanity: моб в радиусе поля обязан замёрзнуть")
	return field

/// Стиль HUD, сменённый за время заморозки (наркотик вернул интерфейс), снятие поля не перезаписывает сохранённым
/datum/unit_test/timestop_keeps_hud_changed_during_freeze

/datum/unit_test/timestop_keeps_hud_changed_during_freeze/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(victim)
	victim.set_hud_used(hud)
	hud.show_hud(HUD_STYLE_REDUCED)
	var/obj/effect/timestop/field = make_timestop_field(victim)
	field.chronofield.show_frozen_world(victim)
	TEST_ASSERT_EQUAL(hud.hud_version, HUD_STYLE_NOHUD, "Sanity: застывший мир обязан прятать HUD")

	hud.show_hud(HUD_STYLE_STANDARD)
	qdel(field)
	TEST_ASSERT_EQUAL(hud.hud_version, HUD_STYLE_STANDARD, "Снятие поля вернуло стиль HUD до заморозки поверх выбранного за время заморозки")

	var/obj/effect/timestop/second_field = make_timestop_field(victim)
	hud.show_hud(HUD_STYLE_REDUCED)
	second_field.chronofield.show_frozen_world(victim)
	qdel(second_field)
	TEST_ASSERT_EQUAL(hud.hud_version, HUD_STYLE_REDUCED, "Снятие поля не вернуло стиль HUD до заморозки")

/// Наблюдатели моба без клиента получают тот же стиль HUD, что запомнил моб
/datum/unit_test/hud_version_without_client_updates_observers

/datum/hud/human/unit_test_recorder
	/// Наблюдатель -> стиль, показанный ему
	var/list/shown_to = list()

/datum/hud/human/unit_test_recorder/show_hud(version = 0, mob/viewmob)
	if(viewmob)
		shown_to[viewmob] = version
	return ..()

/datum/unit_test/hud_version_without_client_updates_observers/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/watcher = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/unit_test_recorder/hud = new(owner)
	owner.set_hud_used(hud)
	LAZYADD(owner.observers, watcher)

	hud.show_hud(HUD_STYLE_NOHUD)
	LAZYREMOVE(owner.observers, watcher)
	var/shown_version = hud.shown_to[watcher]
	hud.shown_to.Cut()
	TEST_ASSERT_EQUAL(shown_version, HUD_STYLE_NOHUD, "Наблюдатель моба без клиента не получил новый стиль HUD")

/// Убитый в поле сразу видит живой мир, а тело остаётся замороженным
/datum/unit_test/timestop_death_restores_view_inside_field

/datum/unit_test/timestop_death_restores_view_inside_field/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.set_hud_used(new /datum/hud/human(victim))
	var/obj/effect/timestop/field = make_timestop_field(victim)
	var/datum/proximity_monitor/advanced/timestop/chronofield = field.chronofield
	chronofield.show_frozen_world(victim)
	TEST_ASSERT(victim.sight & BLIND, "Sanity: застывший мир обязан слепить")

	victim.death()
	TEST_ASSERT(chronofield.frozen_mobs.Find(victim), "Тело убитого обязано остаться замороженным")
	TEST_ASSERT(!has_sepia_colour(victim), "Убитый в поле остался в сепии до конца поля")
	TEST_ASSERT_EQUAL(victim.hud_used.hud_version, HUD_STYLE_STANDARD, "Убитый в поле остался без HUD до конца поля")
	TEST_ASSERT(!(victim.sight & BLIND), "Убитый в поле остался слепым до конца поля")
	TEST_ASSERT(!chronofield.hidden_view_by_mob[victim], "Поле продолжает считать убитого смотрящим в застывший мир")
	qdel(field)

/// Вход в замороженное тело (SSD вернулся, призрак вошёл) показывает застывший мир, но не трупу
/datum/unit_test/timestop_login_shows_frozen_world

/datum/unit_test/timestop_login_shows_frozen_world/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.set_hud_used(new /datum/hud/human(victim))
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	corpse.set_hud_used(new /datum/hud/human(corpse))
	corpse.death()
	var/obj/effect/timestop/field = make_timestop_field(victim)
	TEST_ASSERT(field.chronofield.frozen_mobs.Find(corpse), "Sanity: труп в радиусе поля тоже замерзает")
	TEST_ASSERT(!has_sepia_colour(victim), "Sanity: тело без клиента не красится до входа")

	SEND_SIGNAL(victim, COMSIG_MOB_LOGIN)
	TEST_ASSERT(has_sepia_colour(victim), "Вошедший в замороженное тело видит живой мир без сепии")
	TEST_ASSERT_EQUAL(victim.hud_used.hud_version, HUD_STYLE_NOHUD, "Вошедший в замороженное тело получил HUD")
	TEST_ASSERT(victim.sight & BLIND, "Вошедший в замороженное тело не ослеп")

	SEND_SIGNAL(corpse, COMSIG_MOB_LOGIN)
	TEST_ASSERT(!has_sepia_colour(corpse), "Вошедшему в труп показали застывший мир")
	TEST_ASSERT_EQUAL(corpse.hud_used.hud_version, HUD_STYLE_STANDARD, "Вошедшему в труп спрятали HUD")

	qdel(field)
	TEST_ASSERT(!has_sepia_colour(victim), "После поля на вошедшем осталась сепия")
	TEST_ASSERT_EQUAL(victim.hud_used.hud_version, HUD_STYLE_STANDARD, "После поля вошедший остался без HUD")
	// Предсмертный вздох трупа зовёт view(), а кэш его результата держит обоих до следующего вызова
	qdel(victim)
	qdel(corpse)
	pass(view(0, run_loc_floor_top_right))

/// Очки и шлем пересчитывают зрение, но слепота застывшего мира держится до конца поля
/datum/unit_test/timestop_sight_survives_equipment

/datum/unit_test/timestop_sight_survives_equipment/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.mock_client = new /datum/client_interface
	victim.set_hud_used(new /datum/hud/human(victim))
	var/obj/item/clothing/glasses/meson/mesons = allocate(/obj/item/clothing/glasses/meson)
	var/obj/effect/timestop/field = make_timestop_field(victim)
	field.chronofield.show_frozen_world(victim)

	TEST_ASSERT(victim.equip_to_slot_if_possible(mesons, ITEM_SLOT_EYES), "Sanity: мезоны надеты")
	TEST_ASSERT(victim.sight & BLIND, "Надетые в поле очки сняли слепоту застывшего мира")
	victim.dropItemToGround(mesons)
	TEST_ASSERT(victim.sight & BLIND, "Снятые в поле очки сняли слепоту застывшего мира")

	qdel(field)
	TEST_ASSERT(!(victim.sight & BLIND), "Слепота осталась после поля")
	TEST_ASSERT(victim.equip_to_slot_if_possible(mesons, ITEM_SLOT_EYES), "Sanity: мезоны надеты снова")
	TEST_ASSERT(!(victim.sight & BLIND), "Поле продолжает слепить после снятия")
	TEST_ASSERT(victim.sight & SEE_TURFS, "Мезоны после поля не дают видеть сквозь стены")
	victim.mock_client = null
