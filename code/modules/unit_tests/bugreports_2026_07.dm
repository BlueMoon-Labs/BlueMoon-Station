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
		TEST_ASSERT(prefs.set_antag_preference(role, 0), "Setting an antag preference must report a change")
	TEST_ASSERT_EQUAL(length(prefs.be_special), 1, "Re-picking the same priority must not append duplicate rows")
	TEST_ASSERT_EQUAL(prefs.be_special[role], 0, "The stored priority must be the one that was picked")

	prefs.set_antag_preference(role, 1)
	TEST_ASSERT_EQUAL(length(prefs.be_special), 1, "Switching priority must not append a duplicate row")
	TEST_ASSERT_EQUAL(prefs.be_special[role], 1, "Switching priority must overwrite the stored value")

	prefs.set_antag_preference(role, -1)
	TEST_ASSERT(!(role in prefs.be_special), "Disabling an antag preference must actually remove the role")
	TEST_ASSERT_EQUAL(length(prefs.be_special), 0, "Disabling must not leave a leftover row behind")

	// незнакомые роли не должны попадать в сейв
	TEST_ASSERT(!prefs.set_antag_preference("definitely not a real antag role", 0), "An unknown role must be rejected")
	TEST_ASSERT_EQUAL(length(prefs.be_special), 0, "An unknown role must not be written into be_special")

	qdel(prefs)

/// Уже испорченные сейвы обязана чинить миграция, иначе роль не выключить руками.
/datum/unit_test/antag_preference_savefile_repair/Run()
	var/datum/preferences/prefs = new
	var/role = GLOB.special_roles[1]

	// ровно то, что накапливалось у игроков: значение только у первого вхождения
	prefs.be_special = list(role, role, role)
	prefs.be_special[role] = 1

	prefs.update_preferences(77, null)

	TEST_ASSERT_EQUAL(length(prefs.be_special), 1, "The savefile migration must collapse duplicated antag rows")
	TEST_ASSERT_EQUAL(prefs.be_special[role], 1, "The migration must keep the priority the player had picked")
	TEST_ASSERT(prefs.set_antag_preference(role, -1), "A repaired preference must be switchable off")
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
