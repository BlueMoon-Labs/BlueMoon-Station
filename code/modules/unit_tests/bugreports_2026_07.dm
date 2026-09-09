// Регрессы по багрепортам конца июля 2026. Каждый тест назван по симптому,
// который ловил игрок, а не по внутреннему механизму - чтобы при падении сразу
// было понятно, что именно сломалось на глазах у людей.

// "Нельзя распечатать сообщения из консоли связи больше одного раза"
//
// В ui_data уезжал сам COOLDOWN_DECLARE-вар, то есть абсолютный дедлайн
// world.time. UI кладёт это поле прямо в disabled кнопки печати, поэтому после
// первой же распечатки число оставалось ненулевым навсегда и кнопка умирала.
/datum/unit_test/comms_console_printer_reenables/Run()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications, run_loc_floor_bottom_left)
	//поле printerCooldown отдаётся только залогиненному пользователю и только на
	//вкладке сообщений; STATE_MESSAGES сам #undef'ается в communications.dm,
	//поэтому здесь его значение литералом
	console.authenticated = TRUE
	console.state = "messages"

	var/list/fresh_data = console.ui_data()
	TEST_ASSERT(!fresh_data["printerCooldown"], "A console that never printed must not report the printer as on cooldown")

	console.print_report("test body", "test title")
	TEST_ASSERT(!COOLDOWN_FINISHED(console, report_print_cooldown), "premise: printing must start the cooldown")

	var/list/hot_data = console.ui_data()
	TEST_ASSERT_EQUAL(hot_data["printerCooldown"], TRUE, \
		"printerCooldown must be a boolean: the UI feeds it straight into `disabled`, and a raw world.time deadline disables the button forever")

	// пружина отпущена - кнопка обязана ожить
	COOLDOWN_RESET(console, report_print_cooldown)
	var/list/cooled_data = console.ui_data()
	TEST_ASSERT(!cooled_data["printerCooldown"], "Once the cooldown expires the UI must re-enable the print button")

// "Неправильное сохранение антаг префов"
//
// `be_special += role` дописывал новый элемент с тем же ключом и значением null
// на каждый клик, а выключение через `-=` снимало лишь одно вхождение, так что
// роль так и оставалась включённой.
/datum/unit_test/antag_preference_has_no_duplicates/Run()
	var/datum/preferences/prefs = new
	var/role = GLOB.special_roles[1]
	TEST_ASSERT_NOTNULL(role, "test premise: GLOB.special_roles must not be empty")

	prefs.be_special = list()

	for(var/i in 1 to 4)
		TEST_ASSERT(prefs.set_antag_preference(role, ANTAG_PRIORITY_HIGH), "Setting an antag preference must report a change")
	TEST_ASSERT_EQUAL(length(prefs.be_special), 1, "Re-picking the same priority must not append duplicate rows")
	TEST_ASSERT_EQUAL(prefs.be_special[role], ANTAG_PRIORITY_HIGH, "The stored priority must be the one that was picked")

	prefs.set_antag_preference(role, ANTAG_PRIORITY_LOW)
	TEST_ASSERT_EQUAL(length(prefs.be_special), 1, "Switching priority must not append a duplicate row")
	TEST_ASSERT_EQUAL(prefs.be_special[role], ANTAG_PRIORITY_LOW, "Switching priority must overwrite the stored value")

	prefs.set_antag_preference(role, ANTAG_PRIORITY_DISABLED)
	TEST_ASSERT(!(role in prefs.be_special), "Disabling an antag preference must actually remove the role")
	TEST_ASSERT_EQUAL(length(prefs.be_special), 0, "Disabling must not leave a leftover row behind")

	// незнакомые роли не должны попадать в сейв
	TEST_ASSERT(!prefs.set_antag_preference("definitely not a real antag role", ANTAG_PRIORITY_HIGH), "An unknown role must be rejected")
	TEST_ASSERT_EQUAL(length(prefs.be_special), 0, "An unknown role must not be written into be_special")

	qdel(prefs)

/// Уже испорченные сейвы обязана чинить миграция, иначе роль не выключить руками.
/datum/unit_test/antag_preference_savefile_repair/Run()
	var/datum/preferences/prefs = new
	var/role = GLOB.special_roles[1]

	// ровно то, что накапливалось у игроков: значение только у первого вхождения
	prefs.be_special = list(role, role, role)
	prefs.be_special[role] = ANTAG_PRIORITY_LOW

	prefs.update_preferences(77, null)

	TEST_ASSERT_EQUAL(length(prefs.be_special), 1, "The savefile migration must collapse duplicated antag rows")
	TEST_ASSERT_EQUAL(prefs.be_special[role], ANTAG_PRIORITY_LOW, "The migration must keep the priority the player had picked")
	TEST_ASSERT(prefs.set_antag_preference(role, ANTAG_PRIORITY_DISABLED), "A repaired preference must be switchable off")
	TEST_ASSERT(!(role in prefs.be_special), "A repaired preference must actually switch off")

	qdel(prefs)

// "Экстрактики не кормятся" - репродуктивный экстракт нельзя было накормить
// кубиком из био-мешка: компонент хранилища перехватывал pre_attack и уходил
// подбирать экстракт с пола, так что attackby() экстракта не вызывался вовсе.
/datum/unit_test/reproductive_extract_eats_from_bio_bag/Run()
	var/mob/living/carbon/human/xenobiologist = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/slimecross/reproductive/grey/extract = allocate(/obj/item/slimecross/reproductive/grey, run_loc_floor_bottom_left)
	var/obj/item/storage/bag/bio/bag = allocate(/obj/item/storage/bag/bio)
	var/obj/item/reagent_containers/food/snacks/cube/monkey/cube = allocate(/obj/item/reagent_containers/food/snacks/cube/monkey)

	xenobiologist.put_in_active_hand(bag, forced = TRUE)
	TEST_ASSERT(SEND_SIGNAL(bag, COMSIG_TRY_STORAGE_INSERT, cube, xenobiologist, TRUE, TRUE), \
		"test premise: a monkey cube must fit into a bio bag")
	TEST_ASSERT_EQUAL(cube.loc, bag, "test premise: the cube must end up inside the bag")

	TEST_ASSERT_EQUAL(extract.cubes_eaten, 0, "test premise: a fresh extract has eaten nothing")

	bag.melee_attack_chain(xenobiologist, extract)

	TEST_ASSERT_EQUAL(extract.cubes_eaten, 1, "Clicking a reproductive extract with a bio bag must feed it a monkey cube")
	TEST_ASSERT(QDELETED(cube), "The fed cube must be consumed")
	TEST_ASSERT_EQUAL(extract.loc, run_loc_floor_bottom_left, "Feeding must not scoop the extract into the bag instead")

/// А вот обычный экстракт сумка обязана по-прежнему подбирать: вето выдаёт
/// только тот, кому сумка нужна сама по себе.
/datum/unit_test/bio_bag_still_gathers_extracts/Run()
	var/mob/living/carbon/human/xenobiologist = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/storage/bag/bio/bag = allocate(/obj/item/storage/bag/bio)
	var/obj/item/slime_extract/grey/plain = allocate(/obj/item/slime_extract/grey, run_loc_floor_bottom_left)
	var/obj/item/slimecross/reproductive/grey/hungry = allocate(/obj/item/slimecross/reproductive/grey, run_loc_floor_bottom_left)

	TEST_ASSERT(!(SEND_SIGNAL(plain, COMSIG_ATOM_PRE_STORAGE_GATHER, bag, xenobiologist) & COMPONENT_CANCEL_STORAGE_GATHER), \
		"A plain slime extract must not veto the bag's click-gather")
	TEST_ASSERT(SEND_SIGNAL(hungry, COMSIG_ATOM_PRE_STORAGE_GATHER, bag, xenobiologist) & COMPONENT_CANCEL_STORAGE_GATHER, \
		"A reproductive extract must veto the bio bag's click-gather so its own attackby can feed it")

	var/obj/item/storage/backpack/sack = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(!(SEND_SIGNAL(hungry, COMSIG_ATOM_PRE_STORAGE_GATHER, sack, xenobiologist) & COMPONENT_CANCEL_STORAGE_GATHER), \
		"A reproductive extract must only veto bio bags, so other containers can still pick it up")

// "Терраристы интек превращают в людей" - у шлема биозащиты РнД не было спрайта
// в мордатом листе, а он скрывает волосы и лицо: вместо шлема морда показывала
// лысую человеческую голову.
/datum/unit_test/muzzled_head_sprites_exist/Run()
	var/static/list/muzzled_states = icon_states('icons/mob/clothing/head_muzzled.dmi')
	for(var/obj/item/clothing/head/bio_hood/hood_type as anything in typesof(/obj/item/clothing/head/bio_hood))
		var/hood_state = initial(hood_type.icon_state)
		if(!(initial(hood_type.mutantrace_variation) & STYLE_MUZZLE))
			continue
		TEST_ASSERT(hood_state in muzzled_states, \
			"[hood_type] uses icon_state '[hood_state]', which head_muzzled.dmi does not have: snouted species would see a bare head")

// "Flashdark не спасает от смерти" - фонарик обязан давать пузырь темноты вокруг
// носителя. С унаследованным от обычного фонарика конусом затемнялось всё, кроме
// собственного турфа, а именно по нему считает /datum/element/photosynthesis.
/datum/unit_test/flashdark_darkens_its_holder/Run()
	var/obj/item/flashlight/flashdark/lamp = allocate(/obj/item/flashlight/flashdark, run_loc_floor_bottom_left)

	TEST_ASSERT_EQUAL(lamp.cone_angle, 0, "The flashdark must emit a bubble, not a forward cone: a cone never darkens the holder's own turf")
	TEST_ASSERT(lamp.flashlight_power < 0, "The flashdark must emit negative light")
	TEST_ASSERT(lamp.brightness_on > 0, "The flashdark must have a darkness radius")

	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	owner.put_in_active_hand(lamp, forced = TRUE)
	lamp.on = TRUE
	lamp.update_brightness(owner)

	TEST_ASSERT(lamp.light_on, "A switched-on flashdark must actually carry a light source")
	TEST_ASSERT_EQUAL(lamp.light_cone_angle, 0, "Held by a mob the flashdark must stay omnidirectional")
	TEST_ASSERT(lamp.light_power < 0, "A switched-on flashdark must keep its negative light power")

// "Мыш-борг и ваниш" - меню поз отдыха предлагало Belly up шасси без такого
// спрайта, и update_rest_icon() присваивал несуществующий icon_state: борг
// пропадал с экрана целиком.
//
// Шасси Ratge из репорта - точная пара к багу: у него есть ratge-rest и
// ratge-sit, но нет ratge-bellyup.
/datum/unit_test/robot_rest_poses_all_have_sprites/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(borg.module, "test premise: a cyborg must come up with a module")

	borg.module.cyborg_base_icon = "ratge"
	borg.module.cyborg_icon_override = 'modular_bluemoon/icons/mob/robot/ratge.dmi'
	borg.module.hasrest = TRUE
	borg.update_icons()

	var/list/available_states = icon_states(borg.icon)
	TEST_ASSERT(("ratge-rest" in available_states) && ("ratge-sit" in available_states), \
		"test premise: the Ratge chassis must have its rest and sit sprites")
	TEST_ASSERT(!("ratge-bellyup" in available_states), \
		"test premise: the Ratge chassis is the reported case precisely because it has no belly-up sprite")

	// сверяемся по суффиксам icon_state, а не по подписям в меню: подписи
	// локализуются, и тест на них молча выродился бы в вечнозелёный
	var/list/poses = borg.available_rest_styles()
	var/list/offered_states = list()
	for(var/pose_name in poses)
		offered_states += poses[pose_name]

	TEST_ASSERT(length(poses), "A chassis with resting sprites must offer at least one pose")
	TEST_ASSERT(!("bellyup" in offered_states), "A chassis without a belly-up sprite must not offer the pose: picking it made the cyborg invisible")
	TEST_ASSERT("rest" in offered_states, "A chassis with a resting sprite must still offer the resting pose")
	TEST_ASSERT("sit" in offered_states, "A chassis with a sitting sprite must still offer the sitting pose")

	// каждая предложенная поза обязана давать существующий icon_state
	for(var/pose_name in poses)
		TEST_ASSERT("[borg.module.cyborg_base_icon]-[poses[pose_name]]" in available_states, \
			"Offered pose '[pose_name]' points at a missing icon_state: the cyborg would turn invisible")

// "Перетащил призрака в тело - в логи посыпался CRASH про безмозглый разум"
//
// mind_initialize() отправлял COMSIG_MOB_ON_NEW_MIND до mind.set_current(src),
// а подписчики сигнала (body-bound скилл-модификаторы настроения) сразу же лезут
// в mind.current. На пустом current add_skill_modifier честно валился в CRASH
// "Body-bound skill modifier Mood (Elated) was tried to be added to a mob-less mind".
/datum/unit_test/new_mind_signal_fires_with_body/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	QDEL_NULL(body.mind)
	TEST_ASSERT_NULL(body.mind, "test premise: тело должно остаться без разума")

	var/datum/new_mind_signal_probe/probe = new
	probe.RegisterSignal(body, COMSIG_MOB_ON_NEW_MIND, TYPE_PROC_REF(/datum/new_mind_signal_probe, on_new_mind))

	body.mind_initialize()
	TEST_ASSERT(probe.fired, "test premise: сигнал о новом разуме обязан прийти")
	TEST_ASSERT_EQUAL(probe.seen_current, body, "Подписчик COMSIG_MOB_ON_NEW_MIND получил разум без тела")

	// живой путь, который падал в проде
	var/datum/skill_modifier/prototype = GLOB.skill_modifiers[GET_SKILL_MOD_ID(/datum/skill_modifier/great_mood, null)] || new /datum/skill_modifier/great_mood(null, TRUE)
	body.mind.add_skill_modifier(prototype.identifier)
	TEST_ASSERT(LAZYACCESS(body.mind.skill_holder.all_current_skill_modifiers, prototype.identifier), \
		"Body-bound модификатор не выдался разуму со свежим телом")

/datum/new_mind_signal_probe
	var/fired = FALSE
	var/mob/seen_current

/datum/new_mind_signal_probe/proc/on_new_mind(mob/source)
	SIGNAL_HANDLER
	fired = TRUE
	seen_current = source.mind?.current

// "Плеснул сульфадиазином из стакана - в логи улетели два рантайма"
//
// Переопределение reaction_mob у сульфадиазина потеряло параметр touch_protection,
// а дефолтом стояла ЗОНА строкой (BODY_ZONE_CHEST) там, где код ждёт /obj/item/bodypart.
// Итог: "Cannot read "chest".body_zone" и "Cannot read "chest".burn_dam".
/datum/unit_test/splashed_medicine_targets_a_bodypart/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "test premise: у пациента должна быть грудь")
	chest.receive_damage(burn = 20)
	chest.receive_damage(brute = 20)
	var/burn_before = chest.burn_dam
	var/brute_before = chest.brute_dam

	// ровно тот вызов, что делает /datum/reagents/reaction для облитого моба
	var/datum/reagent/medicine/silver_sulfadiazine/burn_cure = new
	burn_cure.reaction_mob(patient, TOUCH, 20, FALSE, 0, null)
	TEST_ASSERT(chest.burn_dam < burn_before, "Облитый сульфадиазин не вылечил ожоги на груди")

	var/datum/reagent/medicine/styptic_powder/brute_cure = new
	brute_cure.reaction_mob(patient, TOUCH, 20, FALSE, 0, null)
	TEST_ASSERT(chest.brute_dam < brute_before, "Облитый стиптик не вылечил ушибы на груди")

	// зона строкой больше не должна доходить до разыменования
	TEST_ASSERT(!get_bodypart_protecting_clothing_by_coverage(patient, BODY_ZONE_CHEST), \
		"Хелпер покрытия принял строку зоны вместо части тела")

// "Открыл превью снаряжения в панели спавна - рантайм про null.get_all_objectives"
//
// post_equip у InteQ-комплекта выдаёт цель martyr прямо на mind, а превью одевает
// безмозглого дамми: получался "Cannot execute null.get all objectives()".
/datum/unit_test/outfit_preview_skips_mindless_dummy/Run()
	var/mob/living/carbon/human/dummy/dummy = allocate(/mob/living/carbon/human/dummy, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(dummy.mind, "test premise: дамми для превью должен быть без разума")

	var/datum/outfit/inteq/full/outfit = new
	outfit.post_equip(dummy, TRUE, null)
	TEST_ASSERT_NULL(dummy.mind, "Превью аутфита завело дамми разум")

	// а живому оперативнику цель по-прежнему выдаётся
	var/mob/living/carbon/human/operative = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	operative.mind_initialize()
	outfit.post_equip(operative, FALSE, null)
	var/found_martyr = FALSE
	for(var/datum/objective/objective in operative.mind.get_all_objectives())
		if(istype(objective, /datum/objective/martyr))
			found_martyr = TRUE
			break
	TEST_ASSERT(found_martyr, "Оперативник с разумом остался без цели martyr")

// "Нанитная помпа сыпет в логи Incompatible ... assigned to a ... каждые 15 секунд"
//
// check_nanites() безусловно пытался повесить компонент нанитов на носителя,
// а на несовместимом теле AddComponent пишет stack_trace и возвращает
// COMPONENT_INCOMPATIBLE. Раунд 9827: 25 рантаймов подряд.
/datum/unit_test/nanite_pump_asks_before_adding_nanites/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/implant/nanite_pump/pump = allocate(/obj/item/implant/nanite_pump, run_loc_floor_bottom_left)
	pump.imp_in = host

	TEST_ASSERT(pump.can_be_implanted_in(host), "test premise: обычный человек совместим с нанитами")
	TEST_ASSERT(pump.check_nanites(), "Помпа не смогла завести наниты совместимому носителю")
	TEST_ASSERT(SEND_SIGNAL(host, COMSIG_HAS_NANITES), "Наниты не появились у носителя")

	// несовместимому носителю помпа обязана сдаться молча
	var/mob/living/carbon/human/immune = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	ADD_TRAIT(immune, TRAIT_NANITES_IMMUNITY, "unit test")
	var/obj/item/implant/nanite_pump/immune_pump = allocate(/obj/item/implant/nanite_pump, run_loc_floor_bottom_left)
	immune_pump.imp_in = immune

	TEST_ASSERT(!immune_pump.can_be_implanted_in(immune), "test premise: носитель с иммунитетом несовместим")
	TEST_ASSERT(!immune_pump.check_nanites(), "Помпа отчиталась об успехе на несовместимом носителе")
	TEST_ASSERT(!SEND_SIGNAL(immune, COMSIG_HAS_NANITES), "На несовместимом носителе всё-таки завелись наниты")

	// imp_in мы проставили руками, минуя implant(): разбор теста иначе полезет
	// в removed() и будет вычитать имплант из несуществующего списка носителя
	pump.imp_in = null
	immune_pump.imp_in = null

// "После сброса двуручника на пол падал ещё и его оффхенд - qdel-нутым"
//
// /obj/item/Destroy снимает DROPDEL "чтобы не было реqdel'ов", так что следующий
// doUnEquip честно тащил труп оффхенда на пол: "doMove qdel-нутого /obj/item/offhand".
/datum/unit_test/dropping_never_moves_a_deleted_item/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/dummy = new /obj/item/stack/rods(run_loc_floor_bottom_left)
	TEST_ASSERT(user.put_in_hands(dummy), "test premise: предмет должен взяться в руки")

	// Ровно состояние оффхенда после qdel: DROPDEL уже снят в Destroy, а слот
	// руки ещё занят. Штатным qdel такое не собрать - Destroy тут же вычищает
	// предмет из инвентаря, поэтому метку удаления ставим руками.
	dummy.item_flags &= ~DROPDEL
	dummy.gc_destroyed = world.time
	user.dropItemToGround(dummy, force = TRUE)
	TEST_ASSERT(!isturf(dummy.loc), "Сброс из рук перетащил удалённый предмет на пол")
	dummy.gc_destroyed = null
	qdel(dummy)

// "parent_qdeleting overridden" от обезьяны
//
// Чёрный список и цель подбора вешали на один и тот же предмет свой
// COMSIG_PARENT_QDELETING от одного и того же регистранта, а вторая регистрация
// перебивает первую. Побеждал обработчик подбора, и мёртвый ключ навсегда оставался
// в blacklistItems - другой уборки у этого списка нет.
/datum/unit_test/monkey_shares_one_item_qdel_watch/Run()
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)
	var/obj/item/rejected = allocate(/obj/item, run_loc_floor_bottom_left)

	// порядок из handle_combat: предмет уже отвергнут, но снова попадает в цели подбора
	monkey.blacklist_item(rejected)
	TEST_ASSERT(monkey.blacklistItems[rejected], "test premise: предмет должен попасть в чёрный список")
	monkey.set_pickup_target(rejected)
	TEST_ASSERT_EQUAL(monkey.pickupTarget, rejected, "test premise: предмет должен стать целью подбора")
	TEST_ASSERT(monkey.watched_qdel_items[rejected], "Обе причины обязаны делить одну подписку на удаление")

	qdel(rejected)
	TEST_ASSERT_NULL(monkey.pickupTarget, "Удалённый предмет остался целью подбора")
	TEST_ASSERT_NULL(monkey.pickupTargetSignalTarget, "Обезьяна не отпустила подписку на удалённую цель подбора")
	TEST_ASSERT(!(rejected in monkey.blacklistItems), "Мёртвый ключ остался в blacklistItems: чистить его больше некому")
	TEST_ASSERT(!(rejected in monkey.watched_qdel_items), "Обезьяна не сняла подписку с удалённого предмета")

	// обратный порядок: смена цели подбора не должна ронять подписку,
	// которая всё ещё нужна чёрному списку
	var/obj/item/dropped = allocate(/obj/item, run_loc_floor_bottom_left)
	monkey.set_pickup_target(dropped)
	monkey.blacklist_item(dropped)
	monkey.set_pickup_target(null)
	TEST_ASSERT(monkey.watched_qdel_items[dropped], "Смена цели подбора сняла подписку, нужную чёрному списку")

	qdel(dropped)
	TEST_ASSERT(!(dropped in monkey.blacklistItems), "Отпущенный, но всё ещё отвергнутый предмет остался в blacklistItems")
	TEST_ASSERT(!(dropped in monkey.watched_qdel_items), "Обезьяна не сняла подписку с удалённого предмета из чёрного списка")

	// а предмет, за которым больше некому следить, подписку обязан потерять
	var/obj/item/forgotten = allocate(/obj/item, run_loc_floor_bottom_left)
	monkey.set_pickup_target(forgotten)
	TEST_ASSERT(monkey.watched_qdel_items[forgotten], "test premise: цель подбора обязана заводить подписку")
	monkey.set_pickup_target(null)
	TEST_ASSERT(!(forgotten in monkey.watched_qdel_items), "Подписка пережила предмет, за которым больше нет причин следить")

// "mob_death overridden" от верба навигации
//
// cut_navigation() читала client.navigation_images до UnregisterSignal и без проверки
// клиента: у разлогиненного моба прок падал на первой же строке, а подписка на
// COMSIG_MOB_DEATH оставалась висеть - следующий маршрут её перебивал.
/datum/unit_test/navigation_cut_survives_a_clientless_mob/Run()
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(walker.client, "test premise: тестовый моб должен быть без клиента")
	TEST_ASSERT(!watches_own_death(walker), "test premise: моб не должен быть подписан на собственную смерть заранее")

	// ровно то, что делает create_navigation() в конце
	walker.RegisterSignal(walker, COMSIG_MOB_DEATH, TYPE_PROC_REF(/mob/living, cut_navigation))
	TEST_ASSERT(watches_own_death(walker), "test premise: подписка навигации должна завестись")

	walker.cut_navigation()
	TEST_ASSERT(!watches_own_death(walker), \
		"cut_navigation() у моба без клиента не сняла подписку на COMSIG_MOB_DEATH")

/// Подписан ли моб сам на свою смерть: маршрут навигации заводит эту подписку и обязан снимать её сам.
/datum/unit_test/navigation_cut_survives_a_clientless_mob/proc/watches_own_death(mob/living/walker)
	var/list/all_registrations = walker.signal_procs
	if(!all_registrations)
		return FALSE
	var/list/own_registrations = all_registrations[walker]
	if(!own_registrations)
		return FALSE
	return !isnull(own_registrations[COMSIG_MOB_DEATH])

/// Сеть, которой заведомо нет ни у одного типа консоли: только так видно, что
/// набор пережил разборку, а не подставился заводским значением.
#define CAMERA_CONSOLE_TEST_NETWORK "unit_test_cameras"

// "Плата security cameras некорректно работает" (багрепорт 28.07.2026)
//
// Разбор консоли, собранной руками, терял плату: у такой консоли плата лежит в
// нуль-спейсе (on_construction её туда уводит), поэтому forceMove во фрейм не
// зовёт Exited() машины и не вычёркивает плату из component_parts - Destroy
// удалял её вместе с машиной. Существующий тест разбора брал консоль, которую
// собрал сам Initialize - у неё плата лежит внутри, и этот путь он не покрывал.
//
// Второй симптом того же узла: сеть камер живёт только в типе консоли, так что
// собранный обратно монитор всегда получал заводской набор.
/datum/unit_test/camera_console_rebuild_keeps_board_and_network/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, floor)
	var/obj/item/screwdriver/driver = allocate(/obj/item/screwdriver, floor)
	var/obj/item/crowbar/pry = allocate(/obj/item/crowbar, floor)

	var/obj/machinery/computer/security/console = allocate(/obj/machinery/computer/security, floor)
	var/obj/item/circuitboard/computer/security/board = console.circuit
	TEST_ASSERT_NOTNULL(board, "Консоль камер завелась без платы")
	TEST_ASSERT(board in console.component_parts, "test premise: плата обязана числиться в деталях консоли")
	TEST_ASSERT(!(CAMERA_CONSOLE_TEST_NETWORK in board.get_configured_network()), \
		"test premise: тестовая сеть не должна встречаться среди заводских")

	// сеть, отличная от заводской - именно её обязаны пережить разбор и сборка
	console.network = list(CAMERA_CONSOLE_TEST_NETWORK)

	console.deconstruct(TRUE, user)
	var/obj/structure/frame/computer/frame = locate(/obj/structure/frame/computer) in floor
	TEST_ASSERT_NOTNULL(frame, "Разбор консоли камер не оставил фрейм")
	TEST_ASSERT(!QDELETED(board), "Разбор консоли, не проходившей через фрейм, удалил плату")
	TEST_ASSERT_EQUAL(frame.circuit, board, "Плата не легла во фрейм")
	TEST_ASSERT(CAMERA_CONSOLE_TEST_NETWORK in board.get_configured_network(), \
		"Плата не запомнила сеть разобранной консоли")

	// закручиваем фрейм обратно - ровно тот путь, на котором монитор "багуется"
	frame.attackby(driver, user, null)
	TEST_ASSERT(QDELETED(frame), "Закрученный фрейм не превратился в консоль")
	var/obj/machinery/computer/security/rebuilt = locate(/obj/machinery/computer/security) in floor
	TEST_ASSERT_NOTNULL(rebuilt, "Закручивание фрейма не собрало консоль камер")
	TEST_ASSERT_EQUAL(rebuilt.circuit, board, "Собранная консоль получила не ту плату")
	TEST_ASSERT(board in rebuilt.component_parts, "Плата не числится в деталях собранной консоли")
	TEST_ASSERT(CAMERA_CONSOLE_TEST_NETWORK in rebuilt.network, "Собранная консоль потеряла сеть камер")

	// собранную руками консоль тоже обязаны разобрать с возвратом платы
	rebuilt.deconstruct(TRUE, user)
	var/obj/structure/frame/computer/second_frame = locate(/obj/structure/frame/computer) in floor
	TEST_ASSERT_NOTNULL(second_frame, "Разбор собранной консоли не оставил фрейм")
	TEST_ASSERT(!QDELETED(board), "Разбор собранной руками консоли удалил плату")
	TEST_ASSERT_EQUAL(second_frame.circuit, board, "Плата не легла во второй фрейм")

	// и ломик обязан вынуть её из фрейма живой
	second_frame.state = 1
	second_frame.attackby(pry, user, null)
	TEST_ASSERT(!QDELETED(board), "Снятие платы ломиком добралось до удалённой платы")
	TEST_ASSERT_NULL(second_frame.circuit, "Ломик не вынул плату из фрейма")
	TEST_ASSERT_EQUAL(board.loc, floor, "Вынутая плата не легла на пол")

#undef CAMERA_CONSOLE_TEST_NETWORK

// ===== Регрессы по багрепортам 3 августа 2026 =====

// "Химия внутри моба молча не работает"
//
// Индекс рецептов строится по ПЕРВОМУ реагенту (holder.dm, break в цикле сборки), а
// разбор натыкался на запрещённый в мобах рецепт и делал return вместо continue - то
// есть обрывал handle_reactions() ЦЕЛИКОМ, вместе с уже собранными кандидатами.
// /datum/chemical_reaction/food/caramel (mob_react = FALSE) сидит на ключе "сахар",
// поэтому одного сахара в теле хватало, чтобы у моба перестала идти вся химия разом.
// Так же ломались вода (dough), кровь (synthmeat) и salglu (coagulant_weak).
/datum/unit_test/mob_chemistry_survives_a_recipe_banned_in_mobs/Run()
	// Мартышка, а не человек: удавшаяся реакция печатает mix_message через visible_message с
	// icon2html(my_atom), и человек в этом тесте засаливал бы кеш icon2html раньше, чем до него
	// доберётся /datum/unit_test/icon2html_human_result_cached - тот проверяет РОСТ кеша.
	// Для самой проверки разницы нет: гейт mob_react смотрит на isliving(cached_my_atom).
	var/mob/living/carbon/monkey/patient = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)

	// Сахар кладём ПЕРВЫМ: разбор должен наткнуться на запрещённый рецепт раньше разрешённого
	patient.reagents.add_reagent(/datum/reagent/consumable/sugar, 10)
	patient.reagents.add_reagent(/datum/reagent/carbon, 10)
	patient.reagents.add_reagent(/datum/reagent/silicon, 10)
	patient.reagents.handle_reactions()

	TEST_ASSERT(patient.reagents.has_reagent(/datum/reagent/medicine/kelotane), \
		"Разрешённая в мобах реакция не пошла: запрещённый рецепт на ключе сахара обрывает весь разбор")

// "Стабилизированные экстракты теперь засасывает в холодильник"
//
// accept_check проверял РОДИТЕЛЬСКИЙ тип /obj/item/slimecross, под который подходит и
// подтип stabilized. Разгрузка сумки идёт через тот же accept_check, так что био-сумку
// вычищало подчистую, а в холодильнике стабилизированный экстракт теряет носителя,
// пишет "сила иссякла" и самоудаляется вместе с эффектом.
/datum/unit_test/extract_fridge_keeps_stabilized_extracts_out/Run()
	var/obj/machinery/smartfridge/extract/fridge = allocate(/obj/machinery/smartfridge/extract, run_loc_floor_bottom_left)
	var/obj/item/slimecross/stabilized/pink/stabilized = allocate(/obj/item/slimecross/stabilized/pink, run_loc_floor_bottom_left)
	var/obj/item/slimecross/regenerative/grey/crossbred = allocate(/obj/item/slimecross/regenerative/grey, run_loc_floor_bottom_left)

	TEST_ASSERT(!fridge.accept_check(stabilized), "Холодильник принял стабилизированный экстракт - он работает только при носителе")
	TEST_ASSERT(fridge.accept_check(crossbred), "Холодильник перестал принимать обычные скрещенные экстракты (ради них холодильник и правили)")

// "Слаймы сидят в загоне с мартышками и не едят"
//
// Погоня бросает добычу ниже SLIME_AI_TARGET_SPENT_HEALTH, а отбор её брал - и брал
// первой попавшейся, с break. Мартышка живёт до -100, так что полоса -70..-100 вечная:
// одна недоеденная тушка закрывала слаймам доступ к здоровым соседкам навсегда.
/datum/unit_test/slime_skips_prey_its_pursuit_would_drop/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, floor)
	var/mob/living/carbon/monkey/spent = allocate(/mob/living/carbon/monkey, get_step(floor, EAST))
	var/mob/living/carbon/monkey/healthy = allocate(/mob/living/carbon/monkey, get_step(floor, NORTH))

	// Выедаем добычу ровно в мёртвую зону: погоня её уже бросает, но умереть она не может
	spent.adjustCloneLoss(spent.health - (SLIME_AI_TARGET_SPENT_HEALTH - 10))
	TEST_ASSERT(spent.health <= SLIME_AI_TARGET_SPENT_HEALTH, "Премиса: добыча должна быть ниже порога отказа погони")
	TEST_ASSERT(spent.stat != DEAD, "Премиса: добыча обязана остаться ЖИВОЙ, иначе тест ловит не тот отсев")

	hunter.set_nutrition(hunter.get_starve_nutrition() - 1) //голодает: берёт кого угодно, без броска
	hunter.handle_targets()

	TEST_ASSERT_EQUAL(hunter.Target, healthy, "Слайм взял целью выеденную мартышку - погоня бросит её тем же тиком, и загон встанет намертво")

// "Шкаф с замком не оставляет плату после разборки"
//
// Destroy() удаляет плату безусловно, а deconstruct() не снимал с неё ссылку - в отличие
// от шлюза, который обнуляет electronics перед forceMove.
/datum/unit_test/secure_closet_returns_its_electronics/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/structure/closet/secure_closet/closet = allocate(/obj/structure/closet/secure_closet, floor)
	var/obj/item/electronics/airlock/board = closet.lockerelectronics
	TEST_ASSERT_NOTNULL(board, "Премиса: у защищённого шкафа плата ставится в Initialize")

	closet.deconstruct(TRUE)

	TEST_ASSERT(!QDELETED(board), "Разбор шкафа удалил плату доступа вместо того, чтобы её отдать")
	TEST_ASSERT_EQUAL(board.loc, floor, "Плата не легла на пол после разбора шкафа")

// "Розовый стабильный больше не успокаивает фауну"
//
// CanAttack смотрит foes[цель] ПЕРЕД общей фракцией, а RetaliateAgainst пишет обидчика в
// foes навсегда - срока у записи нет. Поэтому аура мира не действовала ни на кого, кого
// носитель хоть раз задел предметом или подстрелил.
/datum/unit_test/pink_aura_forgives_old_grudges/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, floor)
	var/mob/living/simple_animal/hostile/beast = allocate(/mob/living/simple_animal/hostile, get_step(floor, EAST))
	var/obj/item/slimecross/stabilized/pink/extract = allocate(/obj/item/slimecross/stabilized/pink, floor)
	holder.put_in_hands(extract) //иначе базовый tick() снесёт эффект как потерявший носителя

	beast.RetaliateAgainst(holder)
	TEST_ASSERT(beast.foes[holder], "Премиса: обида на носителя должна быть записана")

	var/datum/status_effect/stabilized/pink/aura = holder.apply_status_effect(/datum/status_effect/stabilized/pink)
	TEST_ASSERT_NOTNULL(aura, "Премиса: эффект розового стабильного не навесился")
	aura.linked_extract = extract
	aura.tick()

	TEST_ASSERT(!beast.foes[holder], "Аура мира не сняла персональную обиду - именно она перебивает общую фракцию в CanAttack")
	TEST_ASSERT(holder.real_name in beast.faction, "Аура мира не поделилась фракцией с фауной")

// "Бонусных шансов при операциях больше нет"
//
// Проверяет всю цепочку стерилизина ровно так, как её проходит спрей в руках хирурга:
// reaction(PATCH) долей объёма -> reaction_mob -> sterilize(20, 600) -> sterilize_power,
// который хирургия читает как "+0.2 к множителю" (surgery.dm, get_propability_multiplier).
// Ловит и "бонус не выставился вовсе", и "выставился, но погас в первые же тики".
/datum/unit_test/sterilizine_spray_gives_surgery_bonus/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/reagent_containers/medspray/sterilizine/spray = allocate(/obj/item/reagent_containers/medspray/sterilizine, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(patient.sterilize_power, 0, "Премиса: до обработки бонуса быть не должно")
	TEST_ASSERT(spray.reagents.total_volume > 0, "Премиса: спрей обязан быть заправлен")

	// ровно то, что делает /obj/item/reagent_containers/medspray/attack()
	var/fraction = min(spray.amount_per_transfer_from_this / spray.reagents.total_volume, 1)
	spray.reagents.reaction(patient, spray.apply_type, fraction)

	TEST_ASSERT(patient.sterilize_power > 0, "Спрей стерилизина не выставил sterilize_power - бонуса к операции не будет и зелёной строки на сканере тоже")

	var/datum/timedevent/expiry = SStimer.timer_id_dict[patient._sterilize_timer_id]
	TEST_ASSERT_NOTNULL(expiry, "Стерилизация не завела таймер снятия")
	TEST_ASSERT(expiry.timeToRun > world.time + 30 SECONDS, "Таймер снятия стерилизации назначен слишком рано: бонус погаснет раньше, чем хирург сделает шаг")

	for(var/settle_tick in 1 to 5)
		stoplag(1)

	TEST_ASSERT(patient.sterilize_power > 0, "Бонус стерилизина погас в первые же тики после нанесения")
