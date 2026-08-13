// Регрессы по багрепортам середины августа 2026. Каждый тест назван по симптому,
// который видел игрок, а не по внутреннему механизму - чтобы при падении сразу
// было понятно, что именно сломалось на глазах у людей.

// "При разрушении pressure tank хранимый газ пропадает"
//
// Бак атмоса не переопределял deconstruct(), а базовый atmospherics только оставляет
// после себя трубу. Содержимое уходило в небытие вместе с airs[1].
/datum/unit_test/pressure_tank_releases_gas_on_deconstruct/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor.air, "test premise: the test turf must have an air mixture")

	var/moles_before = floor.air.total_moles()
	var/obj/machinery/atmospherics/components/unary/tank/oxygen/tank = allocate(/obj/machinery/atmospherics/components/unary/tank/oxygen, floor)
	var/datum/gas_mixture/stored_air = tank.airs[1]
	var/stored_moles = stored_air.total_moles()
	TEST_ASSERT(stored_moles > 0, "test premise: an oxygen pressure tank must spawn with gas inside")

	allocated -= tank //deconstruct() qdel'ит бак сам, второй раз он не наш
	tank.deconstruct(FALSE) //destroyed by damage, not carefully unwrenched
	TEST_ASSERT(floor.air.total_moles() > moles_before + (stored_moles * 0.5), \
		"a broken pressure tank must dump its gas onto the turf, not delete it")

// "Семейная реликвия: меняю инструмент на армейском ноже - он перестаёт быть реликвией"
//
// Каждое переключение пересоздавало предмет через new + qdel, поэтому любая ссылка
// именно на этот нож (реликвия, цель антагониста, метки) обрывалась.
/datum/unit_test/army_knife_switches_in_place/Run()
	var/obj/item/armyknife/knife = allocate(/obj/item/armyknife, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(user.put_in_active_hand(knife), "test premise: the knife must fit in the test subject's hand")

	TEST_ASSERT_NULL(knife.tool_behaviour, "a folded army knife must not act as a tool")

	knife.attack_self(user)
	TEST_ASSERT(!QDELETED(knife), "switching tools must keep the very same knife object alive")
	TEST_ASSERT_EQUAL(knife.tool_behaviour, TOOL_SCREWDRIVER, "the first switch must unfold the screwdriver")

	knife.attack_self(user)
	TEST_ASSERT_EQUAL(knife.tool_behaviour, TOOL_WIRECUTTER, "the second switch must unfold the wirecutters")

	knife.attack_self(user)
	TEST_ASSERT_EQUAL(knife.tool_behaviour, TOOL_KNIFE, "the third switch must unfold the blade")
	TEST_ASSERT_EQUAL(knife.sharpness, SHARP_EDGED, "the unfolded blade must be sharp")

	knife.attack_self(user)
	TEST_ASSERT_NULL(knife.tool_behaviour, "the fourth switch must fold everything back")
	TEST_ASSERT_EQUAL(knife.sharpness, SHARP_NONE, "a folded knife must not stay sharp")
	TEST_ASSERT(!QDELETED(knife), "a full cycle must not have replaced the object")
	TEST_ASSERT_EQUAL(knife, user.get_active_held_item(), "the knife must never leave the hand it was switched in")

// "Нейтральная фауна агрится на учёных ДС-1"
//
// Спавнер принимал faction и заворачивал его в list() ещё раз. Варэдит на карте задавал
// готовый список - и фракция моба становилась списком внутри списка, не совпадающим
// вообще ни с кем: враждебным этому мобу оказывался весь мир, включая своих.
/// Тихий спавнер для теста: без раундстартового автоспавна, без записи в списки POI
/// и без убийства свежесозданного моба.
/obj/effect/mob_spawn/human/unit_test_faction_probe
	roundstart = FALSE
	instant = FALSE
	death = FALSE
	ghost_usable = FALSE
	uses = -1
	mob_name = "faction probe"

/datum/unit_test/mob_spawner_faction_is_flat/Run()
	var/obj/effect/mob_spawn/human/spawner = allocate(/obj/effect/mob_spawn/human/unit_test_faction_probe, run_loc_floor_bottom_left)

	spawner.faction = list("unit_test_faction")
	var/mob/living/from_list = spawner.create()
	TEST_ASSERT_NOTNULL(from_list, "test premise: the spawner must produce a mob")
	allocated += from_list
	TEST_ASSERT(("unit_test_faction" in from_list.faction), "a list faction varedit must land in the mob's faction as plain entries")
	TEST_ASSERT(faction_check(from_list.faction, list("unit_test_faction")), "the spawned mob must actually match its own faction")

	spawner.faction = "unit_test_string"
	var/mob/living/from_string = spawner.create()
	TEST_ASSERT_NOTNULL(from_string, "test premise: the spawner must produce a mob")
	allocated += from_string
	TEST_ASSERT(faction_check(from_string.faction, list("unit_test_string")), "a plain string faction must keep working")

// "Пираты: консоль сбора кредитов разрушаема, весь прогресс антагониста обнуляется"
//
// Цель читала points прямо из терминала. Снятие кредитов обнуляло счётчик, а уничтожение
// консоли обрывало ссылку - в отчёте конца раунда оставалось пустое "собрано: /75000".
/datum/unit_test/pirate_loot_survives_terminal_loss/Run()
	var/obj/machinery/computer/piratepad_control/terminal = allocate(/obj/machinery/computer/piratepad_control, run_loc_floor_bottom_left)
	TEST_ASSERT(terminal.resistance_flags & INDESTRUCTIBLE, "the cargo hold terminal must not be destructible")

	var/datum/objective/loot/booty = new
	booty.cargo_hold = terminal
	GLOB.objectives += booty

	terminal.points = 40000
	terminal.total_collected = 40000
	TEST_ASSERT_EQUAL(booty.get_loot_value(), 40000, "collected loot must be visible to the objective")

	// Пираты обналичили добычу: остаток на счету нулевой, но собрано столько же.
	terminal.points = 0
	TEST_ASSERT_EQUAL(booty.get_loot_value(), 40000, "withdrawing credits must not erase objective progress")

	// А теперь терминала не стало вовсе (админ, взрыв шаттла).
	qdel(terminal)
	TEST_ASSERT_NULL(booty.cargo_hold, "test premise: a deleted terminal must detach itself from the objective")
	TEST_ASSERT_EQUAL(booty.get_loot_value(), 40000, "losing the terminal must not erase objective progress")

	GLOB.objectives -= booty
	qdel(booty)

// "Пинок в крио пешки: оригинал уходит в SSD и его откидывает в крио"
//
// Холодный лазурный экстракт уводит сознание в клона, а тело остаётся без клиента и
// попадает в список SSD. Автокрио стирало его, и клону было некуда возвращаться.
/datum/unit_test/slime_clone_original_body_is_not_ssd/Run()
	var/mob/living/carbon/human/original = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/original_mind = new
	original_mind.transfer_to(original)

	GLOB.ssd_mob_list |= original //как если бы тело уже записали в SSD на выходе клиента
	original.apply_status_effect(/datum/status_effect/slime_clone)

	var/datum/status_effect/slime_clone/clone_effect = original.has_status_effect(/datum/status_effect/slime_clone)
	TEST_ASSERT_NOTNULL(clone_effect, "test premise: the cerulean extract must apply the clone effect")
	allocated += clone_effect.clone
	TEST_ASSERT(!(original in GLOB.ssd_mob_list), "the body hosting a slime clone must not be an auto-cryo candidate")

	original.remove_status_effect(/datum/status_effect/slime_clone)
	GLOB.ssd_mob_list -= original
	qdel(original_mind)
