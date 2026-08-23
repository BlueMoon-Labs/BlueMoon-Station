// Регрессы по багрепортам середины августа 2026. Каждый тест назван по симптому,
// который видел игрок, а не по внутреннему механизму - чтобы при падении сразу
// было понятно, что именно сломалось на глазах у людей.

// "При разрушении pressure tank хранимый газ пропадает"
//
// Бак атмоса не переопределял ни deconstruct(), ни Destroy(), а базовый atmospherics только
// оставляет после себя трубу. Содержимое уходило в небытие вместе с airs[1]. Проверяем оба
// пути смерти: аккуратный obj_destruction() через deconstruct() и прямой qdel() от взрыва
// первой категории, который deconstruct() вообще не зовёт.
/datum/unit_test/pressure_tank_releases_gas_on_destruction/Run()
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

	// Взрыв: /obj/ex_act первой категории обнуляет obj_integrity и делает qdel(src) в обход
	// deconstruct(), поэтому выпуск газа обязан висеть на Destroy(), а не на деконструкции.
	moles_before = floor.air.total_moles()
	var/obj/machinery/atmospherics/components/unary/tank/oxygen/bombed = allocate(/obj/machinery/atmospherics/components/unary/tank/oxygen, floor)
	stored_moles = bombed.airs[1].total_moles()
	TEST_ASSERT(stored_moles > 0, "test premise: the second oxygen tank must spawn with gas inside")

	allocated -= bombed
	qdel(bombed)
	TEST_ASSERT(floor.air.total_moles() > moles_before + (stored_moles * 0.5), \
		"a tank deleted outright must dump its gas onto the turf too")

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

// "Костяной клинок из слизи пропадает вместе с оторванной рукой"
//
// Базовый армблейд помечен DROPDEL: отделение от тела стирает предмет, потому что ченджлинг
// отращивает его заново. Слизневый клинок - собственная кость руки, и владелец оставался ни с чем.
/datum/unit_test/slime_boneblade_survives_losing_the_arm/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, floor)
	var/obj/item/melee/arm_blade/slime/blade = allocate(/obj/item/melee/arm_blade/slime, floor)
	TEST_ASSERT(user.put_in_active_hand(blade), "test premise: the boneblade must fit in the test subject's hand")

	allocated -= blade //DROPDEL уносит клинок в qdel сам
	user.dropItemToGround(blade, force = TRUE)
	TEST_ASSERT(QDELETED(blade), "test premise: DROPDEL must still delete the arm-mounted blade itself")

	var/list/left_behind = list()
	for(var/obj/item/melee/severed_boneblade/severed in floor)
		left_behind += severed
	TEST_ASSERT_EQUAL(length(left_behind), 1, "losing the arm must leave exactly one severed boneblade behind")
	allocated += left_behind
	var/obj/item/melee/severed_boneblade/dropped_blade = left_behind[1]
	TEST_ASSERT_NOTNULL(dropped_blade.GetComponent(/datum/component/butchering), \
		"the severed boneblade must keep its butchering component")

	// Владельца чистят вместе с содержимым - на такой уборке новых предметов не плодим.
	var/obj/item/melee/arm_blade/slime/orphan = allocate(/obj/item/melee/arm_blade/slime, floor)
	allocated -= orphan
	orphan.dropped(null)
	TEST_ASSERT(QDELETED(orphan), "test premise: DROPDEL must delete an ownerless blade too")

	var/leftovers = 0
	for(var/obj/item/melee/severed_boneblade/extra in floor)
		leftovers++
	TEST_ASSERT_EQUAL(leftovers, 1, "a blade dropped with no live owner must not spawn a second boneblade")

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

// То же самое, но для заложника: его цена списывается с терминала при отправке, а приходит
// минут через десять, когда выкуп наконец проведут. Терминала к этому моменту может не быть,
// и без запомненной цели набранное за заложника не вернулось бы вообще никуда.
/datum/unit_test/pirate_ransom_survives_terminal_loss/Run()
	var/obj/machinery/computer/piratepad_control/terminal = allocate(/obj/machinery/computer/piratepad_control, run_loc_floor_bottom_left)
	var/datum/objective/loot/booty = new
	booty.cargo_hold = terminal
	GLOB.objectives += booty

	terminal.points = 10000
	terminal.total_collected = 10000

	var/datum/ransom_extraction/sequence = new
	sequence.pirate_gang_value = 25000
	sequence.bind_pirate_console(terminal)
	TEST_ASSERT_EQUAL(sequence.pirate_objective?.resolve(), booty, "queueing a ransom must remember the team's objective, not just the terminal")

	// Терминал исчез между отправкой заложника и выкупом.
	allocated -= terminal
	qdel(terminal)
	sequence.pay_out_pirate_gang()
	TEST_ASSERT_EQUAL(booty.get_loot_value(), 35000, "a hostage's ransom must reach the objective even without the terminal")

	GLOB.objectives -= booty
	qdel(booty)
	qdel(sequence)

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

// "Пикетные таблички не работают: ручку подносишь, текст вводишь - на плакате пусто"
//
// retext() переписали в (инструмент, автор), но оба вызова - attackby плаката и Trigger()
// нано-действия - так и передавали одного автора. Инструмент получал моба, автор оставался
// null, и user.canUseTopic() падал в рантайм раньше, чем надпись ложилась на плакат.
/datum/unit_test/picket_sign_takes_a_label/Run()
	var/obj/item/picket_sign/sign = allocate(/obj/item/picket_sign, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	sign.set_label("Free the clown")
	TEST_ASSERT_EQUAL(sign.label, "Free the clown", "a written sign must remember its label")
	TEST_ASSERT_EQUAL(sign.name, "Free the clown sign", "a written sign must be named after its label")
	TEST_ASSERT_EQUAL(sign.desc, "It reads: Free the clown", "a written sign must read out its label on examine")

	sign.set_label("")
	TEST_ASSERT_EQUAL(sign.label, "", "an erased sign must drop its label")
	TEST_ASSERT_EQUAL(sign.name, initial(sign.name), "an erased sign must go back to its blank name")
	TEST_ASSERT_EQUAL(sign.desc, initial(sign.desc), "an erased sign must go back to its blank description")

	// Цепочку обязан останавливать сам плакат: иначе следом отработает afterattack
	// инструмента - ручка откроет второе окно переименования, мелок нарисует граффити.
	var/obj/item/pen/pen = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	TEST_ASSERT(sign.attackby(pen, user) & STOP_ATTACK_PROC_CHAIN, "writing on a sign with a pen must consume the attack chain")

	var/obj/item/toy/crayon/crayon = allocate(/obj/item/toy/crayon, run_loc_floor_bottom_left)
	TEST_ASSERT(sign.attackby(crayon, user) & STOP_ATTACK_PROC_CHAIN, "writing on a sign with a crayon must consume the attack chain")

	var/obj/item/paper/paper = allocate(/obj/item/paper, run_loc_floor_bottom_left)
	TEST_ASSERT(!(sign.attackby(paper, user) & STOP_ATTACK_PROC_CHAIN), "hitting a sign with something that cannot write must fall through to the normal attack chain")

// "Нано-плакат борга по кнопке машет собой вместо того, чтобы дать ввести надпись"
//
// Действие висит на самом нано-плакате, а разводит вызовы ui_action_click: кнопка перепрошивки
// уходит в retext(), любое другое действие - в обычный attack_self с махом и кулдауном.
/datum/unit_test/nano_picket_sign_action_retexts/Run()
	var/obj/item/picket_sign/cyborg/nano = allocate(/obj/item/picket_sign/cyborg, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	var/datum/action/item_action/nano_picket_sign/retext_action = locate() in nano.actions
	TEST_ASSERT_NOTNULL(retext_action, "test premise: a nano-sign must hand out its retext action")

	nano.ui_action_click(user, retext_action)
	TEST_ASSERT(COOLDOWN_FINISHED(nano, picket_sign_cooldown), "the retext button must not wave the sign")

	var/datum/action/item_action/plain_action = new(nano)
	nano.ui_action_click(user, plain_action)
	TEST_ASSERT(!COOLDOWN_FINISHED(nano, picket_sign_cooldown), "any other action must still fall through to waving the sign")
	qdel(plain_action)

// Вкопанный плакат: пикет должен пережить того, кто его держал.
//
// Плакат уходит в /obj/structure/picket_sign с той же надписью, руками достаётся обратно
// предметом, а разбитый не оставляет ничего - иначе пикет чинится ударом по нему.
/datum/unit_test/planted_picket_sign_round_trip/Run()
	var/turf/floor = run_loc_floor_bottom_left

	var/obj/structure/picket_sign/planted = allocate(/obj/structure/picket_sign, floor)
	planted.set_label("Free the clown")
	TEST_ASSERT_EQUAL(planted.name, "Free the clown sign", "a planted sign must be named after its label")

	allocated -= planted
	var/obj/item/picket_sign/pulled = planted.uproot()
	qdel(planted)
	TEST_ASSERT_NOTNULL(pulled, "pulling a planted sign out must give back a picket sign")
	allocated += pulled
	TEST_ASSERT_EQUAL(pulled.label, "Free the clown", "a sign pulled out of the floor must keep its label")
	TEST_ASSERT_EQUAL(pulled.name, "Free the clown sign", "a sign pulled out of the floor must keep its name")

	// Разбитый плакат уходит в ничто: deconstruct(disassembled = FALSE) - это путь через урон.
	var/signs_before = 0
	for(var/obj/item/picket_sign/lying in floor)
		signs_before++

	var/obj/structure/picket_sign/smashed = allocate(/obj/structure/picket_sign, floor)
	allocated -= smashed
	smashed.deconstruct(FALSE)
	TEST_ASSERT(QDELETED(smashed), "a smashed sign must be gone")

	var/signs_after = 0
	for(var/obj/item/picket_sign/lying in floor)
		signs_after++
	TEST_ASSERT_EQUAL(signs_after, signs_before, "a smashed sign must not drop an intact picket sign")

	// Повешенный на стену плакат снимается тем же путём и тоже держит надпись.
	var/obj/structure/picket_sign/wall/hung = allocate(/obj/structure/picket_sign/wall, floor)
	hung.set_label("Honk if you love clowns")
	allocated -= hung
	var/obj/item/picket_sign/taken_down = hung.uproot()
	qdel(hung)
	TEST_ASSERT_NOTNULL(taken_down, "taking a wall sign down must give back a picket sign")
	allocated += taken_down
	TEST_ASSERT_EQUAL(taken_down.label, "Honk if you love clowns", "a sign taken off a wall must keep its label")

// Незарегистрированный звуковой ключ get_sfx() возвращает сам себя, и playsound()
// на нём просто молчит - опечатка в ключе не ломает ничего, кроме тишины.
/datum/unit_test/picket_sign_writing_sound_resolves/Run()
	TEST_ASSERT(!istext(get_sfx(SFX_WRITING_PEN)), "SFX_WRITING_PEN must resolve to a sound file, not stay a bare key")

// "Голодек: загрузил Beach - bad index в copy template list"
//
// copy_template_list ходила по списку позиционно, а source[i] для ассоциативного
// списка отдаёт ЗНАЧЕНИЕ слота, не ключ. Элемент-список (atom_colours хранит пары
// цвет+приоритет вложенными списками) уезжал в source[ключ] как индекс: списки
// индексами быть не могут, и голодек падал "bad index" на каждом ковре шаблона Beach.
// Ассоциативные пары при этом разваливались - настоящий ключ через source[i] вообще
// не достать.
/datum/unit_test/copy_template_list_survives_nested_lists/Run()

	// Вложенные списки-элементы копируются глубоко и независимо от шаблона.
	var/list/nested = list(list("#ff0000", 2), list("#00ff00", 2))
	var/list/nested_copy = copy_template_list(nested)
	TEST_ASSERT_EQUAL(length(nested_copy), 2, "вложенные списки-элементы не должны теряться")
	TEST_ASSERT(islist(nested_copy[1]), "элемент должен остаться вложенным списком, а не рассыпаться")
	nested_copy[1][1] = "#000000"
	TEST_ASSERT_EQUAL(nested[1][1], "#ff0000", "копия должна быть независимой от списка шаблона")

	// Тайпкэш (typecacheof) переезжает парами ключ-значение, а не кучей элементов TRUE.
	var/list/cache_copy = copy_template_list(typecacheof(list(/mob/living/carbon/human)))
	TEST_ASSERT(cache_copy[/mob/living/carbon/human], "тайпкэш обязан переехать ассоциацией: путь -> TRUE")

	// Чужие датумы выкидываются - одиночные и как ключи пар.
	var/datum/foreign = new()
	TEST_ASSERT(!length(copy_template_list(list(foreign))), "ссылка на датум не должна уехать в копию шаблона")
	TEST_ASSERT(!length(copy_template_list(list("ключ" = foreign))), "датум в значении выкидывает пару целиком")
	qdel(foreign)

	// Простые числа (bitflag-группы сглаживания) остаются на своих местах:
	// source[число] был бы доступом по индексу со всеми вытекающими.
	var/list/numbers_copy = copy_template_list(list(9, 20))
	TEST_ASSERT_EQUAL(numbers_copy.len, 2, "числовые элементы не должны теряться")
	TEST_ASSERT_EQUAL(numbers_copy[1], 9, "числа обязаны остаться элементами, а не превратиться в индексы")
	TEST_ASSERT_EQUAL(numbers_copy[2], 20, "числа обязаны остаться элементами, а не превратиться в индексы")

	// Картинка - значение внешнего вида, её копия получает по ссылке.
	var/image/picture = image('icons/turf/floors/carpet.dmi')
	TEST_ASSERT(picture in copy_template_list(list(picture)), "картинки копия забирает себе по ссылке")

// "Энергометлой затащил предмет в ресайклер - doMove qdel-нутого ghostcafe"
//
// Ресайклер ест снаряд через Crossed -> eat(), и GetAllContents забирает предметы,
// которые волна несла в себе. recycle_item удаляет их ДО того, как qdel(projectile)
// из того же eat() вызовет drop_everything() - и тот тянул труп forceMove'ом на пол.
/datum/unit_test/broom_wave_drop_skips_recycled_items/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	var/obj/item/projectile/broom/wave = allocate(/obj/item/projectile/broom, floor)

	// Живой предмет из contents волны: обязан вернуться на турф под ней.
	var/obj/item/paper/survivor = allocate(/obj/item/paper, floor)
	survivor.forceMove(wave)
	wave.vis_contents += survivor
	wave.pushedstuff += survivor

	// Предмет, который ресайклер успел сожрать раньше Destroy самого снаряда.
	var/obj/item/storage/box/syndie_kit/chameleon/eaten = allocate(/obj/item/storage/box/syndie_kit/chameleon, floor)
	wave.pushedstuff += eaten
	allocated -= eaten //ресайклер удаляет его сам, второй раз он не наш
	qdel(eaten)

	// Седок-моб мог быть стёрт прямо посреди поездки на волне.
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human, floor)
	rider.forceMove(wave)
	wave.pushedstuff += rider
	wave.losers += rider
	allocated -= rider
	qdel(rider)

	// Раньше здесь падал рантайм doMove qdel-нутого - юнит-тесты считают рантаймы падением.
	wave.drop_everything()
	TEST_ASSERT_EQUAL(survivor.loc, floor, "уцелевший предмет обязан вернуться на турф под волной")
	TEST_ASSERT(!length(wave.vis_contents), "vis_contents волны должен очиститься после сброса")
	TEST_ASSERT(QDELETED(eaten) && QDELETED(rider), "сожранное и стёртое должны остаться мёртвыми")

// "Гибнущий носитель нанитов - Cannot read null.armor"
//
// human/Destroy удаляет physiology раньше содержимого, где умирает компонент нанитов,
// а тот на прощание гасит пассивки: Dermal Hardening читал physiology.armor трупа.
// Откат баффа при уже удалённой физиологии просто пропускается.
/datum/unit_test/nanite_hardening_skips_dead_physiology/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/component/nanites/nanites = host.AddComponent(/datum/component/nanites, 50)
	TEST_ASSERT_NOTNULL(nanites, "test premise: носитель должен получить наниты")

	var/datum/nanite_program/hardening/program = new()
	TEST_ASSERT_EQUAL(nanites.add_program(null, program), COMPONENT_PROGRAM_INSTALLED, "test premise: программа закалки должна установиться")

	var/melee_before = host.physiology.armor.melee
	program.activate()
	program.enable_passive_effect() //так же включает пассивку рабочий цикл on_process
	TEST_ASSERT(program.passive_enabled, "test premise: закалка должна быть включена")
	TEST_ASSERT_EQUAL(host.physiology.armor.melee, melee_before + 35, "закалка обязана усилить броню живого носителя")

	// Полный qdel носителя - ровно продовый путь: physiology умрёт раньше программ.
	allocated -= host
	qdel(host) //здесь раньше падал "Cannot read null.armor"
