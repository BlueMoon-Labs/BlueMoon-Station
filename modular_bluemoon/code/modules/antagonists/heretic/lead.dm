#define HERETIC_LEAD_INK "#d8a85a"
#define HERETIC_LEAD_GREY "#9ba6b3"
#define HERETIC_LEAD_START 2
#define HERETIC_LEAD_HEX_COOLDOWN (15 SECONDS)
#define HERETIC_LEAD_NAMED_COOLDOWN (25 SECONDS)
#define HERETIC_LEAD_HEAVY_CHECK (0.5 SECONDS)
#define HERETIC_LEAD_HEAVY_SLOWDOWN 1.5
#define HERETIC_LEAD_HEAVY_TINT "#8e98a4"
#define HERETIC_LEAD_ASSIST_ANGLE 25
#define HERETIC_LEAD_CATCH_COOLDOWN (20 SECONDS)
#define HERETIC_LEAD_RICOCHET_COOLDOWN (15 SECONDS)
#define HERETIC_LEAD_RAIN_COOLDOWN (30 SECONDS)
#define HERETIC_LEAD_RAIN_SLOWDOWN 1
#define HERETIC_LEAD_EAR_LIMIT 4
#define HERETIC_LEAD_EAR_REPEAT (1 SECONDS)
#define HERETIC_LEAD_EAR_PRUNE 32
#define HERETIC_LEAD_EAR_RANGE 30
#define HERETIC_LEAD_INNATE_STAMINA 8
#define HERETIC_LEAD_INNATE_BANG_GUARD 1
#define LEAD_KNOCKED_SHOWN 3
#define HERETIC_LEAD_GRASP_SFX "heretic_lead_grasp"
#define HERETIC_LEAD_HIT_SFX "heretic_lead_hit"
#define TRAIT_HERETIC_LEAD_BENT "heretic_lead_bent"

GLOBAL_LIST_INIT(heretic_lead_sounds, list(
	"casing" = list('modular_bluemoon/sound/heretic/lead_casing_1.ogg', 'modular_bluemoon/sound/heretic/lead_casing_2.ogg', 'modular_bluemoon/sound/heretic/lead_casing_3.ogg'),
	"catch" = list('modular_bluemoon/sound/heretic/lead_catch_1.ogg', 'modular_bluemoon/sound/heretic/lead_catch_2.ogg', 'modular_bluemoon/sound/heretic/lead_catch_3.ogg'),
	"misfire" = list('modular_bluemoon/sound/heretic/lead_misfire_1.ogg', 'modular_bluemoon/sound/heretic/lead_misfire_2.ogg', 'modular_bluemoon/sound/heretic/lead_misfire_3.ogg'),
	"named_cast" = list('modular_bluemoon/sound/heretic/lead_named_cast_1.ogg', 'modular_bluemoon/sound/heretic/lead_named_cast_2.ogg'),
	"named_hit" = list('modular_bluemoon/sound/heretic/lead_named_hit_1.ogg', 'modular_bluemoon/sound/heretic/lead_named_hit_2.ogg'),
	"rain" = list('modular_bluemoon/sound/heretic/lead_rain_1.ogg', 'modular_bluemoon/sound/heretic/lead_rain_2.ogg'),
	"rain_warn" = list('modular_bluemoon/sound/heretic/lead_rain_warn.ogg'),
	"empty" = list('modular_bluemoon/sound/heretic/lead_revolver_empty_1.ogg', 'modular_bluemoon/sound/heretic/lead_revolver_empty_2.ogg'),
	"shot" = list('modular_bluemoon/sound/heretic/lead_revolver_shot_1.ogg', 'modular_bluemoon/sound/heretic/lead_revolver_shot_2.ogg', 'modular_bluemoon/sound/heretic/lead_revolver_shot_3.ogg'),
	"cock" = list('modular_bluemoon/sound/heretic/lead_cock_1.ogg', 'modular_bluemoon/sound/heretic/lead_cock_2.ogg', 'modular_bluemoon/sound/heretic/lead_cock_3.ogg'),
	"last_round_charge" = list('modular_bluemoon/sound/heretic/lead_last_round_charge.ogg'),
	"last_round_shot" = list('modular_bluemoon/sound/heretic/lead_last_round_shot.ogg'),
	"gun_turns" = list('modular_bluemoon/sound/heretic/lead_gun_turns.ogg'),
	"phantom_shot" = list('modular_bluemoon/sound/heretic/lead_phantom_shot_1.ogg', 'modular_bluemoon/sound/heretic/lead_phantom_shot_2.ogg'),
	"drum" = list('modular_bluemoon/sound/heretic/lead_drum_count_1.ogg', 'modular_bluemoon/sound/heretic/lead_drum_count_2.ogg'),
	"ricochet" = list('modular_bluemoon/sound/heretic/lead_ricochet_1.ogg', 'modular_bluemoon/sound/heretic/lead_ricochet_2.ogg', 'modular_bluemoon/sound/heretic/lead_ricochet_3.ogg'),
	"smelt" = list('modular_bluemoon/sound/heretic/lead_crucible_bubble_1.ogg', 'modular_bluemoon/sound/heretic/lead_crucible_bubble_2.ogg'),
	"quench" = list('modular_bluemoon/sound/heretic/lead_crucible_quench_1.ogg', 'modular_bluemoon/sound/heretic/lead_crucible_quench_2.ogg'),
	"drum_spin" = list('modular_bluemoon/sound/heretic/lead_cylinder_spin_1.ogg', 'modular_bluemoon/sound/heretic/lead_cylinder_spin_2.ogg'),
	"drum_select" = list('modular_bluemoon/sound/heretic/lead_cylinder_select_1.ogg', 'modular_bluemoon/sound/heretic/lead_cylinder_select_2.ogg'),
	"fan" = list('modular_bluemoon/sound/heretic/lead_fan_cock.ogg'),
	"school_gunslinger" = list('modular_bluemoon/sound/heretic/lead_school_gunslinger.ogg'),
	"school_hunter" = list('modular_bluemoon/sound/heretic/lead_school_hunter.ogg'),
	"school_cannoneer" = list('modular_bluemoon/sound/heretic/lead_school_cannoneer.ogg'),
	"standoff_in" = list('modular_bluemoon/sound/heretic/lead_standoff_in.ogg'),
	"standoff_out" = list('modular_bluemoon/sound/heretic/lead_standoff_out.ogg'),
	"tripwire_set" = list('modular_bluemoon/sound/heretic/lead_tripwire_set.ogg'),
	"tripwire_click" = list('modular_bluemoon/sound/heretic/lead_tripwire_click.ogg'),
	"charge_set" = list('modular_bluemoon/sound/heretic/lead_charge_set.ogg'),
	"charge_arm" = list('modular_bluemoon/sound/heretic/lead_charge_arm.ogg'),
	"pop" = list('modular_bluemoon/sound/heretic/lead_pop.ogg'),
))

/// Играет звук события Свинца из его набора и возвращает выбранный файл.
/proc/heretic_lead_sound(atom/source, kind, volume, vary = FALSE, extrarange = 0)
	. = pick(GLOB.heretic_lead_sounds[kind])
	if(volume > 0 && source)
		playsound(source, ., volume, vary, extrarange)

/datum/sound_effect/heretic_lead_grasp
	key = HERETIC_LEAD_GRASP_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/lead_catch_1.ogg',
		'modular_bluemoon/sound/heretic/lead_catch_2.ogg',
		'modular_bluemoon/sound/heretic/lead_catch_3.ogg',
	)

/datum/sound_effect/heretic_lead_hit
	key = HERETIC_LEAD_HIT_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/lead_hit_1.ogg',
		'modular_bluemoon/sound/heretic/lead_hit_2.ogg',
		'modular_bluemoon/sound/heretic/lead_hit_3.ogg',
	)

/// Игрушечные и небоевые пули: поролон, жвачка, стрелы, дротики и шприцы.
/proc/heretic_lead_toy_projectile(projectile_type)
	var/static/list/toys = typecacheof(list(
		/obj/item/projectile/bullet/reusable,
		/obj/item/projectile/bullet/dart,
		/obj/item/projectile/bullet/dnainjector,
	))
	return ispath(projectile_type) && toys[projectile_type]

/// Баллистика: пули и дробь, а не лучи, энергия, игрушки и брошенные вещи.
/proc/heretic_lead_ballistic(obj/item/projectile/projectile)
	return istype(projectile, /obj/item/projectile/bullet) && !heretic_lead_toy_projectile(projectile.type) && projectile.flag == BULLET && !projectile.nodamage && projectile.damage > 0

/proc/heretic_lead_ballistic_type(projectile_type)
	if(!ispath(projectile_type, /obj/item/projectile/bullet) || heretic_lead_toy_projectile(projectile_type))
		return FALSE
	var/obj/item/projectile/sample = projectile_type
	return initial(sample.flag) == BULLET && !initial(sample.nodamage) && initial(sample.damage) > 0

/// Патрон или гильза боевого огнестрела: не заряд энергооружия и не игрушка.
/proc/heretic_lead_casing_lethal(obj/item/ammo_casing/casing)
	if(ispath(casing, /obj/item/ammo_casing))
		return !ispath(casing, /obj/item/ammo_casing/energy) && heretic_lead_ballistic_type(initial(casing.projectile_type))
	return istype(casing) && !istype(casing, /obj/item/ammo_casing/energy) && heretic_lead_ballistic_type(casing.projectile_type)

/// Чем стреляет огнестрел: патрон в патроннике, иначе патроны магазина или штатного магазина.
/proc/heretic_lead_gun_projectile(obj/item/gun/ballistic/gun)
	if(!istype(gun))
		return null
	if(gun.chambered?.projectile_type)
		return gun.chambered.projectile_type
	var/obj/item/ammo_casing/ammo
	if(gun.magazine)
		ammo = gun.magazine.ammo_type
	else if(ispath(gun.mag_type, /obj/item/ammo_box))
		var/obj/item/ammo_box/mag_path = gun.mag_type
		ammo = initial(mag_path.ammo_type)
	return ispath(ammo, /obj/item/ammo_casing) ? initial(ammo.projectile_type) : null

/// Выстрел боевым огнестрелом; fired - снаряд, его тип или патрон, если сигнал их передал.
/proc/heretic_lead_gunshot(obj/item/gun/gun, fired)
	if(ispath(fired, /obj/item/projectile))
		return heretic_lead_ballistic_type(fired)
	if(istype(fired, /obj/item/projectile))
		return heretic_lead_ballistic(fired)
	if(istype(fired, /obj/item/ammo_casing) || ispath(fired, /obj/item/ammo_casing))
		return heretic_lead_casing_lethal(fired)
	return heretic_lead_ballistic_type(heretic_lead_gun_projectile(gun))

/// Пуля летит от чужого стрелка: свои, слуги и сам еретик Свинец не кормят. Выстрел в упор попадает ещё до fired.
/proc/heretic_lead_feeds(obj/item/projectile/projectile, mob/living/heretic)
	if(!heretic_lead_ballistic(projectile))
		return FALSE
	var/mob/firer = projectile.firer
	return firer != heretic && !(ismob(firer) && (IS_HERETIC(firer) || IS_HERETIC_MONSTER(firer)))

/datum/heretic_path/lead
	id = PATH_LEAD
	deed_type = /datum/heretic_deed/lead
	innate_type = /datum/heretic_innate/lead
	name = "Свинец"
	tagline = "Стреляет дробью из пальца, плавит металл в Свинец, ловит чужие пули и уходит рикошетом."
	craft_summary = "Хватка в «Помощи» заговаривает ружьё или магазин: два выстрела экипажа - осечки, осечки по отделам - дело."
	capture_summary = "Пуля с именем за 2 Свинца: 6 секунд тяжести, затем цель падает на 4 секунды; сердце уводит её в изнанку."
	escape_summary = "Рикошет за единицу Свинца переносит к месту удара вашей пули или дробины в 12 клетках."
	strength_points = list(
		"Палец-ствол бьёт дробиной издали, а гильзы, металл и затишье дают Свинец и без чужих пуль.",
		"Патронташ на 6 Свинца сам дозаряжает пустой барабан, а каждый выстрел в вашу сторону его пополняет.",
		"Заговорённое ружьё осекается у экипажа, а Пуля с именем сама доворачивает к цели и валит её.",
		"С Мишенью пули экипажа рядом сворачивают в меченого; с ней же приходит Школа, полезная сразу.",
		"Шестизарядник: шесть камор, прицел, веер и удар рукоятью; попадание - Свинец, убийство - ещё 3.",
		"Свинцовый дождь бьёт круг радиусом 2, а ствол павшего рядом стрелка встаёт и стреляет сам.",
	)
	weakness_points = list(
		"Лазеры, энергия, игрушки и химия не дают Свинца и не ловятся; дробину пальца держат щит и броня.",
		"Пулю с именем можно заслонить телом или щитом: чужого она не узнаёт и рассыпается.",
		"Тяжесть снимают нулевой жезл, святая вода в крови и толчок за 2 секунды, а ещё уход дальше 13 клеток.",
		"Детектив, капеллан и еретики видят свинцовую патину на заговорённом оружии; жезл и святая вода её снимают.",
		"Выдают запах пороха с 4 Свинца, прицел Последнего патрона, линия прицела, кольцо Мгновения, круг дождя.",
		"Оглушение глушит заклинания; растяжку находят осмотром клетки и режут кусачками, закладку заливают водой.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_lead,
		/datum/eldritch_knowledge/lead_grasp,
		/datum/eldritch_knowledge/spell/lead_named,
		/datum/eldritch_knowledge/lead_mark,
		/datum/eldritch_knowledge/lead_relic,
		/datum/eldritch_knowledge/spell/lead_catch,
		/datum/eldritch_knowledge/spell/lead_ricochet,
		/datum/eldritch_knowledge/lead_ear,
		/datum/eldritch_knowledge/spell/lead_rain,
		/datum/eldritch_knowledge/final_eldritch/lead_final,
	)
	rune_inscription_icon = 'modular_bluemoon/icons/obj/ritual_inscriptions_extended.dmi'
	rune_cast_icon = 'modular_bluemoon/icons/obj/ritual_casts_extended.dmi'
	book_type = /obj/item/forbidden_book/lead
	book_name = "Ars Glandis Ultimae"
	book_title = "Устав последнего выстрела"
	book_subtitle = "У каждой пули уже есть имя"
	book_desc = "Потёртый стрелковый устав в переплёте из тусклой свинцовой фольги. Уголки - латунные гильзы, закладка - шнур от мишени, а на полях чья-то рука вычертила перекрестья."
	book_cover = "lead"
	book_ink = HERETIC_LEAD_INK
	book_rune = "sigil_lead"
	rune_inscription = "lead_cylinder"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_lead_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_lead_page.ogg'
	vfx_particles = /particles/heretic_ascension/lead
	vfx_accent = HERETIC_LEAD_GREY
	ascension_title = "Тот, Кто Держит Курок"
	ascension_message = "Над станцией щёлкает взведённый курок. Каждая пуля на борту уже знает, чьё имя на ней написано."
	ascension_omen = "В ушах звенит, как после выстрела в упор. На языке привкус пороха; на миг кажется, что кто-то навёл на вас прицел."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_lead.ogg'
	ascension_climax_sound = 'modular_bluemoon/sound/heretic/ascend_lead_climax.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_lead.dmi'
	ascension_aura_state = "lead_aura"
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/lead.dmi'
	sky_tint = "#4d5b6e"
	sky_dim = 110
	sky_particles = /particles/heretic_sky/lead
	sky_texture_drift = 140 SECONDS
	sky_texture_angle = 0
	sky_loop = 'modular_bluemoon/sound/heretic/sky/lead_loop.ogg'
	sky_event_sound = 'modular_bluemoon/sound/heretic/sky/lead_event.ogg'
	combat_practice = "Пусть напарник постреляет рядом из баллистического оружия: пули мимо и в вас дают Свинец, лазеры - нет. Свинец добывается и без чужих пуль: в любом намерении, кроме «Помощи», Хватка по живой цели в 6 клетках стреляет дробиной на 15 ушибов; в «Помощи» она впитывает гильзы, переплавляет стопку из 5 листов железа и заговаривает ружьё - дайте его напарнику, два его выстрела дадут осечку. Сглаз ствола срывает осечкой следующий выстрел напарника. Изучив Отдачу, толкните цель Хваткой и выпустите в неё Пулю с именем: 6 секунд тяжести, затем падение на 4 секунды, а цель охоты под Пристрелкой падает сразу; на полигоне это пробуется на учебной цели охоты - кнопка «Первое подношение» или «Цель охоты» у цели. Ловля пули 1,5 секунды ловит выстрелы напарника, Рикошет переносит к месту, куда последней попала ваша пуля или дробина. Со ступенью Мишени кнопка «Школа стрельбы» один раз выбирает Стрелка, Охотника или Канонира. У Шестизарядника шесть камор: Alt-клик выбирает камору, Ctrl-клик крутит барабан, «Использовать в руке» меняет стиль, а в «Вреде» вплотную он бьёт рукоятью. Со Слухом стрелка при полном барабане Alt-клик по Шестизаряднику взводит Шестую камору, и выстрел в человека - Последний патрон. Потерянный Шестизарядник возвращает в руку кнопка «Призвать Шестизарядник». Пошагово всё ведёт кнопка «Урок Свинца» среди упражнений полигона."

/obj/item/forbidden_book/lead
	book_path = PATH_LEAD

/particles/heretic_ascension/lead
	icon = HERETIC_LEAD_FX_ICON
	icon_state = list("lead_p_casing" = 3, "lead_p_spark" = 2)
	velocity = generator("circle", 3, 6)
	gravity = list(0, -0.25)
	friction = 0.08
	spin = generator("num", -20, 20)
	lifespan = 1.4 SECONDS

/particles/heretic_sky/lead
	icon = HERETIC_LEAD_FX_ICON
	icon_state = list("lead_p_casing" = 2, "lead_p_spark" = 3)
	velocity = generator("circle", 0.05, 0.2)
	gravity = list(0, -0.015)

/datum/eldritch_knowledge/base_lead
	name = "Тяжёлый металл Сатурна"
	summary = "Хватка издали стреляет дробиной, вблизи собирает гильзы, плавит металл и заговаривает оружие экипажа."
	details = list(
		"Нож и патрон или гильза дают Штык Сатурна; осечка у экипажа в новом отделе продвигает дело пути.",
		"Палец-ствол: Хватка не в «Помощи» по живой цели в 6 клетках, турели или меху - дробина на 15 ушибов; по полу заряд цел.",
		"Сглаз ствола за единицу срывает осечкой следующий выстрел стрелка в 7 клетках; без боя Свинец сам копится до 3.",
		"Хватка в «Помощи» по гильзам и патронам, своим тоже, впитывает до 3 штук с клетки: единица за каждую.",
		"Переплавка: секунда Хватки в «Помощи» - 5 листов железа или 10 прутьев дают единицу, 2 патрона магазина - 2.",
		"Хватка в «Помощи» по огнестрелу или магазину, даже в шкафу или ящике рядом, - 2 осечки экипажа; до 4 заговоров.",
		"Цель охоты и меченые в 7 клетках, не видя вас, слышат щелчки курка; с 4 Свинца от вас пахнет порохом.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Я поднял с пола гильзу. Она была ещё тёплой, хотя здесь давно никто не стрелял."
	route = PATH_LEAD
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/ammo_casing)
	result_atoms = list(/obj/item/melee/sickly_blade/lead)
	combat_resource = HERETIC_LEAD_START
	combat_resource_max = HERETIC_LEAD_CAPACITY
	combat_resource_name = "Свинец"
	resource_rules = list(
		"Начальный запас 2 из 6; смерть обнуляет и барабан, и патронташ.",
		"Свинец - это заряженные каморы Шестизарядника подряд от курка: выстрел тратит камору под курком, способности гасят последнюю.",
		"Патронташ: Свинец сверх полного барабана ложится на пояс, до 6; пустой барабан за 1 секунду дозаряжается из него, а способностям недостающее берётся оттуда.",
		"Тлеющий запас: 20 секунд не получали и не наносили урона - единица Свинца раз в 20 секунд, но не больше 3.",
		"Пуля или дробь в вас или в 1 клетке - единица раз в 2 секунды; выстрел из огнестрела в вашу сторону в 7 клетках - единица в патронташ, от стрелка раз в 1 секунду. Лазеры и энергия не в счёт.",
		"Хватка по врагу, взрыв метки, удар клинком и удар рукоятью Шестизарядника - по единице; гильзы и переплавка Хваткой в «Помощи» - тоже, заряд Хватки при этом цел.",
		"Попадание Шестизарядника в живого врага возвращает единицу, а убитый им человек - ещё 3; убитый меченый человек - 2, у Стрелка 3 разных человека за 6 секунд - ещё 2.",
		"Цены: Палец-ствол - только заряд Хватки; Сглаз, Рикошет, Растяжка, Пороховая закладка и выстрел - единица; Пуля с именем - 2, дождь - 2, у Канонира единица.",
		"Взведённая Шестая камора с полным барабаном уходит в человека одним Последним патроном за весь Свинец; убитый им человек вернёт 3.",
		"Смена тела снимает тяжесть, Пристрелку, метки и точку Рикошета; заговоры остаются.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_lead/hex
	grasp_visual = /obj/effect/temp_visual/heretic_lead/grasp
	grasp_sound = HERETIC_LEAD_GRASP_SFX
	grasp_catchphrase = "SVI'NAS SA'TURNO"
	var/mob/living/lead_body
	/// Заговоры Хваткой, старейший первым; Сглаз сюда не входит.
	var/list/datum/component/heretic_lead_curse/curses = list()
	var/list/datum/status_effect/heretic_lead_heavy/heavies = list()
	var/list/datum/status_effect/heretic_lead_zeroed/zeroed = list()
	var/list/datum/status_effect/eldritch/lead/marks = list()
	/// Последняя клетка, где ударилась пуля Шестизарядника или Пуля с именем.
	var/turf/impact_turf
	var/impact_at = 0
	var/lead_failure
	var/hex_deflected = FALSE
	var/ascension_active = FALSE
	/// Сбитые Тяжёлой пулей или хлопком: weakref => когда; панель показывает, кого пока не свалить.
	var/list/knocked = list()
	/// Последнее показанное состояние: такт жизни обновляет подсказку значка, только когда оно изменилось.
	var/shown_state
	var/static/list/whiz_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_whiz),
	)
	COOLDOWN_DECLARE(whiz_harvest)
	COOLDOWN_DECLARE(ascension_regen)

/datum/eldritch_knowledge/base_lead/on_body_gain(mob/living/user)
	if(!user?.mind || lead_body == user)
		return
	if(lead_body)
		on_body_lose(lead_body)
	lead_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_body_shot))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_body_moved))
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_body_examine))
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_body_damaged))
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_body_item_attack))
	RegisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_body_unarmed))
	RegisterSignal(user, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_body_projectile))
	RegisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED, PROC_REF(on_heard_shot))
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))
	RegisterSignal(src, COMSIG_HERETIC_LEAD_EVENT, PROC_REF(on_lead_event))
	AddComponent(/datum/component/connect_range, user, whiz_connections, HERETIC_LEAD_WHIZ_RANGE, FALSE)
	grant_combat_power(user)
	notify_resource_changed()

/datum/eldritch_knowledge/base_lead/on_body_lose(mob/living/user)
	if(lead_body)
		UnregisterSignal(lead_body, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_BULLET_ACT, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOB_ITEM_ATTACK, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_LIVING_HIT_BY_PROJECTILE))
	UnregisterSignal(SSdcs, list(COMSIG_GLOB_GUN_FIRED, COMSIG_GLOB_MOB_DEATH))
	UnregisterSignal(src, COMSIG_HERETIC_LEAD_EVENT)
	qdel(GetComponent(/datum/component/connect_range))
	stop_reserve()
	stop_reload()
	clear_school_effects()
	lead_body = null
	ascension_active = FALSE
	remove_combat_power()
	clear_lead()

/datum/eldritch_knowledge/base_lead/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(lead_body)

/datum/eldritch_knowledge/base_lead/on_death(mob/user)
	clear_lead()
	stop_reload()
	clear_school_effects()
	clear_traps()
	combat_resource = 0
	bandolier = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_lead/on_lose(mob/user)
	. = ..()
	clear_curses()
	clear_traps()

/datum/eldritch_knowledge/base_lead/Destroy()
	on_body_lose(lead_body)
	clear_curses()
	clear_traps()
	return ..()

/datum/eldritch_knowledge/base_lead/proc/clear_curses()
	for(var/datum/component/heretic_lead_curse/curse as anything in curses.Copy())
		qdel(curse)
	curses.Cut()

/datum/eldritch_knowledge/base_lead/proc/clear_lead()
	QDEL_LIST(heavies)
	QDEL_LIST(zeroed)
	QDEL_LIST(marks)
	impact_turf = null
	impact_at = 0
	heard_turf = null
	free_last_round = FALSE
	sixth_armed = FALSE
	knocked.Cut()

/datum/eldritch_knowledge/base_lead/combat_resource_state()
	. = "Заговоров: [length(curses)] из [HERETIC_LEAD_CURSE_LIMIT]. Патронташ: [bandolier] из [HERETIC_LEAD_BANDOLIER][reload_timer ? ", барабан дозаряжается" : ""]."
	if(impact_fresh())
		. += " Точка Рикошета: [get_area_name(impact_turf, TRUE)], ещё [heretic_lead_seconds(impact_at + HERETIC_LEAD_RICOCHET_MEMORY - world.time)] с."
	if(sixth_cocked())
		. += " Шестая камора: выстрел в человека станет Последним патроном."
	. += drum_state()
	. += timer_state()
	. += school_state()
	. += crucible_state()

/proc/heretic_lead_seconds(time_left)
	return max(1, CEILING(time_left / (1 SECONDS), 1))

/// Окна и откаты, которых не видно на кнопках: Ловля, Охота на звук, Призрачный ствол, кого пока не свалить.
/datum/eldritch_knowledge/base_lead/proc/timer_state()
	. = ""
	var/datum/status_effect/heretic_lead_catch/window = catching()
	if(window)
		. += " Ловля пули: ещё [heretic_lead_seconds(window.duration - world.time)] с."
	if(sound_hunt_learned())
		. += COOLDOWN_FINISHED(src, sound_hunt) ? " Охота на звук готова." : " Охота на звук: через [heretic_lead_seconds(COOLDOWN_TIMELEFT(src, sound_hunt))] с."
	if(knows(/datum/eldritch_knowledge/spell/lead_rain) && !COOLDOWN_FINISHED(src, phantom_cooldown))
		. += " Призрачный ствол: через [heretic_lead_seconds(COOLDOWN_TIMELEFT(src, phantom_cooldown))] с."
	var/list/standing = list()
	for(var/datum/weakref/victim_ref as anything in knocked.Copy())
		var/mob/living/victim = victim_ref.resolve()
		var/datum/status_effect/heretic_lead_staggered/staggered = victim?.has_status_effect(/datum/status_effect/heretic_lead_staggered)
		if(staggered)
			standing += "[victim.name] - [heretic_lead_seconds(staggered.duration - world.time)] с"
		else if(!victim || world.time > knocked[victim_ref] + HERETIC_LEAD_HEAVY_REPEAT)
			knocked -= victim_ref
	if(length(standing))
		. += " Снова не свалить: [jointext(standing, ", ")]."

/// Тяжёлая пуля и хлопок валят одну цель не чаще раза в 6 секунд.
/datum/eldritch_knowledge/base_lead/proc/note_knocked(mob/living/victim)
	var/datum/weakref/victim_ref = WEAKREF(victim)
	if(!victim_ref)
		return
	knocked -= victim_ref
	knocked[victim_ref] = world.time
	while(length(knocked) > LEAD_KNOCKED_SHOWN)
		knocked.Cut(1, 2)

/// Пристрелка не короче lasts: уже идущую только продлевает.
/datum/eldritch_knowledge/base_lead/proc/zero_in(mob/living/victim, lasts = HERETIC_LEAD_ZEROED_TIME)
	var/datum/status_effect/heretic_lead_zeroed/effect = victim.has_status_effect(/datum/status_effect/heretic_lead_zeroed)
	if(effect)
		effect.duration = max(effect.duration, world.time + lasts)
		return effect
	return victim.apply_status_effect(/datum/status_effect/heretic_lead_zeroed, src, lasts)

/datum/eldritch_knowledge/base_lead/proc/on_lead_event(datum/source, event, atom/subject, value)
	SIGNAL_HANDLER
	if(event != "round_hit" || !ispath(value, /obj/item/projectile/bullet/heretic_lead/heavy) || !isliving(subject))
		return
	var/mob/living/victim = subject
	var/datum/status_effect/heretic_lead_staggered/staggered = victim.has_status_effect(/datum/status_effect/heretic_lead_staggered)
	if(!staggered)
		note_knocked(victim)
	else if(lead_body)
		lead_body.balloon_alert(lead_body, "снова свалить через [heretic_lead_seconds(staggered.duration - world.time)] с")

/// Такт жизни обновляет подсказку значка, пока в ней идут секунды.
/datum/eldritch_knowledge/base_lead/proc/refresh_shown_state()
	var/state = combat_resource_state()
	if(state == shown_state)
		return FALSE
	shown_state = state
	var/datum/antagonist/heretic/heretic = owner_heretic()
	heretic?.update_combat_resource_alert()
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/can_use(mob/living/user, ignore_grab = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(QDELETED(src) || !isliving(user) || user != lead_body || !isturf(user.loc) || heretic?.selected_path != PATH_LEAD || heretic.role_removed || heretic.get_knowledge(type) != src)
		return FALSE
	return !heretic_incapacitated(user, ignore_grab)

/// Владелец знания есть, даже когда он сейчас без сознания: заговоры и дело пути работают без него.
/datum/eldritch_knowledge/base_lead/proc/owner_heretic()
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	if(QDELETED(heretic) || heretic.role_removed || heretic.get_knowledge(type) != src)
		return null
	return heretic

/datum/eldritch_knowledge/base_lead/proc/knows(knowledge_type)
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/known = heretic?.get_knowledge(knowledge_type)
	return !QDELETED(known)

/// Из шкафа или меха на ту же клетку connect_range поле не восстанавливает.
/datum/eldritch_knowledge/base_lead/proc/on_body_moved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	if(!isturf(source.loc) || isturf(old_loc))
		return
	var/datum/component/connect_range/field = GetComponent(/datum/component/connect_range)
	field?.update_signals(source)

/datum/eldritch_knowledge/base_lead/proc/catching()
	return lead_body?.has_status_effect(/datum/status_effect/heretic_lead_catch)

/datum/eldritch_knowledge/base_lead/proc/on_whiz(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/obj/item/projectile/projectile = arrived
	if(!istype(projectile) || !projectile.fired || QDELETED(lead_body) || lead_body.stat == DEAD)
		return
	note_duel_shot(projectile)
	if(!catching() && heretic_lead_feeds(projectile, lead_body))
		harvest_bullet()

/datum/eldritch_knowledge/base_lead/proc/on_body_shot(datum/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	if(lead_body?.stat != DEAD && !catching() && heretic_lead_feeds(projectile, lead_body))
		harvest_bullet()

/datum/eldritch_knowledge/base_lead/proc/harvest_bullet()
	if(!COOLDOWN_FINISHED(src, whiz_harvest))
		return FALSE
	COOLDOWN_START(src, whiz_harvest, HERETIC_LEAD_WHIZ_COOLDOWN)
	gain_combat_resource()
	return TRUE

/datum/eldritch_knowledge/base_lead/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	if(!can_use(user) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return
	gain_combat_resource()

/datum/eldritch_knowledge/base_lead/on_life(mob/user)
	if(user == lead_body)
		powder_scent()
		school_tick()
		refresh_shown_state()
	if(!ascension_active || !can_use(user) || !COOLDOWN_FINISHED(src, ascension_regen))
		return
	COOLDOWN_START(src, ascension_regen, HERETIC_LEAD_ASCENDED_REGEN)
	gain_combat_resource()

/datum/eldritch_knowledge/base_lead/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !can_use(user))
		return FALSE
	if(isliving(target))
		if(!heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
			return FALSE
		mark_combat()
		gain_combat_resource()
		return TRUE
	if(user.a_intent != INTENT_HELP)
		return FALSE
	if(absorb_casings(user, target))
		return TRUE
	if(smeltable(target) && (!istype(target, /obj/item/ammo_box) || !smelt_block_reason(user, target)))
		smelt(user, target)
		return FALSE
	return curse_from_grasp(user, target)

/datum/eldritch_knowledge/base_lead/proc/casing_valid(obj/item/ammo_casing/casing, mob/living/user)
	return (istype(casing, /obj/item/ammo_casing/heretic_lead) || heretic_lead_casing_lethal(casing)) && !QDELETED(casing) && (isturf(casing.loc) || casing.loc == user)

/// Гильзы и патроны с клетки или из руки тают в ладони: единица Свинца за каждую.
/datum/eldritch_knowledge/base_lead/proc/absorb_casings(mob/living/user, atom/target)
	var/list/obj/item/ammo_casing/found = list()
	if(istype(target, /obj/item/ammo_casing))
		if(!casing_valid(target, user))
			return FALSE
		found += target
		if(isturf(target.loc))
			target = target.loc
	if(isturf(target))
		for(var/obj/item/ammo_casing/casing in target)
			if(!(casing in found) && casing_valid(casing, user))
				found += casing
	if(!length(found))
		return FALSE
	if(lead_total() >= lead_capacity())
		grasp_failure_reason = "Барабан и патронташ полны: Свинца уже [lead_capacity()]."
		return FALSE
	var/turf/place = get_turf(found[1])
	var/taken = 0
	for(var/obj/item/ammo_casing/casing as anything in found)
		if(taken >= HERETIC_LEAD_CASINGS_PER_GRASP || lead_total() + taken >= lead_capacity())
			break
		qdel(casing)
		taken++
	gain_combat_resource(taken)
	new /obj/effect/temp_visual/heretic_lead/grasp(place)
	heretic_lead_sound(place, "casing", 40, TRUE, SILENCED_SOUND_EXTRARANGE)
	to_chat(user, span_eldritch("Латунь тает в ладони, свинец уходит в кровь. [lead_count_text()]"))
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "casings", place, taken)
	return TRUE

/// Огнестрел или магазин, который заговорит Хватка: сама вещь или первая подходящая в шкафу, ящике или оружейном кейсе рядом.
/datum/eldritch_knowledge/base_lead/proc/curse_candidate(atom/target, mob/living/user)
	if(heretic_lead_curseable(target))
		return (isturf(target.loc) || target.loc == user) ? target : null
	if(!istype(target, /obj/structure/closet) && !istype(target, /obj/structure/guncase))
		return null
	for(var/obj/item/item in target)
		if(heretic_lead_curseable(item) && !item.GetComponent(/datum/component/heretic_lead_curse))
			return item
	return null

/datum/eldritch_knowledge/base_lead/proc/curse_from_grasp(mob/living/user, atom/target)
	var/obj/item/item = curse_candidate(target, user)
	if(!item)
		if(istype(target, /obj/structure/closet) || istype(target, /obj/structure/guncase))
			grasp_failure_reason = "Внутри нет огнестрела или магазина, который ещё не заговорён."
		return FALSE
	if(item.GetComponent(/datum/component/heretic_lead_curse))
		grasp_failure_reason = "[item] уже заговорено."
		return FALSE
	place_curse(user, item)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/place_curse(mob/living/user, obj/item/item)
	while(length(curses) >= HERETIC_LEAD_CURSE_LIMIT)
		var/datum/component/heretic_lead_curse/oldest = curses[1]
		var/atom/cursed = oldest.parent
		to_chat(user, span_warning("Заговор на [cursed] ([get_area_name(cursed, TRUE)]) выветрился: держится не больше [HERETIC_LEAD_CURSE_LIMIT], и его вытеснил новый."))
		log_game("[key_name(user)] теряет заговор Свинца на [cursed] в [AREACOORD(cursed)]: его вытеснил новый.")
		qdel(oldest)
	var/datum/component/heretic_lead_curse/curse = item.AddComponent(/datum/component/heretic_lead_curse, src, HERETIC_LEAD_CURSE_CHARGES, TRUE)
	if(QDELETED(curse))
		return null
	heretic_craft_placed_fx(item, src)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/turf/place = get_turf(item)
	var/wait = place && is_station_level(place.z) ? null : " Осечки вне станции дело пути не продвинут."
	to_chat(user, span_eldritch("[item] на миг тяжелеет, по металлу ползёт свинцовая патина: заговор лёг. Заговоров: [length(curses)] из [HERETIC_LEAD_CURSE_LIMIT].[wait || ""]"))
	if(heretic?.deed && !heretic.deed.complete())
		to_chat(user, span_notice("Дело пути продвинет осечка в руках члена экипажа в ещё не зачтённом отделе."))
	log_game("[key_name(user)] заговаривает Свинцом [item] ([item.type]) в [AREACOORD(item)].")
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "curse", item)
	return curse

/datum/eldritch_knowledge/base_lead/proc/on_curse_removed(datum/component/heretic_lead_curse/curse)
	if(curse in curses)
		curses -= curse
		notify_resource_changed()

/// Заговор сработал в чужих руках: дело пути, слух стрелка и лог.
/datum/eldritch_knowledge/base_lead/proc/on_misfire(obj/item/gun/gun, mob/living/shooter, crafted)
	var/turf/place = get_turf(shooter)
	log_game("[key_name(shooter)]: осечка заговорённого Свинцом [gun] ([gun.type]) в [AREACOORD(place)], заговор [crafted ? "Хваткой" : "Сглазом"].")
	var/datum/antagonist/heretic/heretic = owner_heretic()
	if(!heretic)
		return
	if(knows(/datum/eldritch_knowledge/lead_ear) && lead_body && lead_body.stat != DEAD)
		to_chat(lead_body, span_notice("Слух стрелка: осечка у [shooter.name] - [get_area_name(place, TRUE)]."))
	if(crafted)
		record_misfire_spot(place)
	count_misfire(gun, shooter)
	var/mob/living/heretic_body = heretic.owner?.current
	if(crafted && heretic_body && heretic_body.stat != DEAD && shooter.mind && !IS_HERETIC(shooter) && !IS_HERETIC_MONSTER(shooter) && place && is_station_level(place.z))
		var/deed_key = heretic.deed_key_for(place)
		if(!heretic.deed_wait_reason(deed_key))
			heretic.advance_deed(deed_key, place, silent = TRUE)
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_MISFIRE, gun, shooter, crafted)

/datum/eldritch_knowledge/base_lead/proc/hex_block_reason(mob/living/user, atom/target)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	var/mob/living/victim = target
	if(!istype(victim) || victim == user || victim.stat == DEAD)
		return "Укажите живого человека с огнестрелом в руках."
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return "Это союзник Мансуса: еретики и их слуги защищены от этой способности."
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_LEAD_HEX_RANGE)
		return "Стрелок должен стоять не дальше [HERETIC_LEAD_HEX_RANGE] клеток на вашем этаже."
	if(!length(hex_guns(victim)))
		for(var/obj/item/gun/ballistic/gun in victim.held_items)
			var/datum/component/heretic_lead_curse/curse = gun.GetComponent(/datum/component/heretic_lead_curse)
			if(curse?.crafted && !curse.spent)
				return "Оружие в руках цели уже заговорено Хваткой: осечка и так будет."
		return "В руках у цели нет боевого огнестрела: лазеры, энергия и игрушки заговору не поддаются."
	if(lead_total() < 1)
		return "Нужна единица Свинца."
	return null

/datum/eldritch_knowledge/base_lead/proc/hex_guns(mob/living/victim)
	. = list()
	for(var/obj/item/gun/ballistic/gun in victim.held_items)
		var/datum/component/heretic_lead_curse/curse = gun.GetComponent(/datum/component/heretic_lead_curse)
		if(heretic_lead_curseable(gun) && (!curse || !curse.crafted || curse.spent))
			. += gun

/// Сглаз ствола: оружие в руках стрелка один раз даст осечку в ближайшие 10 секунд. Отведённый защитой сглаз Свинца не тратит, но перезарядку не возвращает.
/datum/eldritch_knowledge/base_lead/proc/hex(mob/living/user, mob/living/victim)
	hex_deflected = FALSE
	lead_failure = hex_block_reason(user, victim)
	if(lead_failure)
		return FALSE
	if(!heretic_can_affect(user, victim, chargecost = 1))
		hex_deflected = TRUE
		lead_failure = "Защита от магии отводит сглаз: Свинец цел, но перезарядка идёт."
		return FALSE
	if(!spend_combat_resource())
		return FALSE
	for(var/obj/item/gun/ballistic/gun as anything in hex_guns(victim))
		qdel(gun.GetComponent(/datum/component/heretic_lead_curse))
		gun.AddComponent(/datum/component/heretic_lead_curse, src, 1, FALSE, HERETIC_LEAD_HEX_TIME)
	user.Beam(victim, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = 0.4 SECONDS)
	to_chat(victim, span_warning("Оружие в руке вдруг тяжелеет, будто в ствол залили свинец."))
	log_combat(user, victim, "наводит Сглаз ствола на оружие в руках")
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "hex", victim)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/impact_fresh()
	return impact_turf && world.time <= impact_at + HERETIC_LEAD_RICOCHET_MEMORY

/datum/eldritch_knowledge/base_lead/proc/record_impact(turf/place)
	if(!isturf(place))
		return
	impact_turf = place
	impact_at = world.time
	notify_resource_changed()

/// Клетка удара или соседняя свободная: на месте попадания часто стоит сам подстреленный.
/datum/eldritch_knowledge/base_lead/proc/ricochet_landing()
	if(!impact_turf)
		return null
	if(heretic_lead_landable(impact_turf))
		return impact_turf
	for(var/direction in GLOB.alldirs)
		var/turf/nearby = get_step(impact_turf, direction)
		if(heretic_lead_landable(nearby) && impact_turf.Adjacent(nearby))
			return nearby
	return null

/proc/heretic_lead_landable(turf/spot)
	return isopenturf(spot) && !isgroundlessturf(spot) && !spot.is_blocked_turf()

/datum/eldritch_knowledge/base_lead/proc/impact_block_reason(mob/living/user)
	if(!impact_fresh())
		return "Некуда рикошетить: за последние [HERETIC_LEAD_RICOCHET_MEMORY / (1 SECONDS)] секунд ваша пуля никуда не попала."
	if(impact_turf.z != user.z)
		return "Ваша пуля ударила на другом этаже: Рикошет сквозь этажи не ведёт."
	if(get_dist(user, impact_turf) > HERETIC_LEAD_RICOCHET_RANGE)
		return "Место удара пули дальше [HERETIC_LEAD_RICOCHET_RANGE] клеток."
	var/area/destination_area = get_area(impact_turf)
	if(destination_area.area_flags & NOTELEPORT)
		return "Зона закрыта для телепортации: Рикошет не унесёт."
	if(!ricochet_landing())
		return "У места удара нет свободного пола: переходить некуда."
	return null

/// Своя пуля ведёт сразу; без неё после третьей души - Охота на звук к чужому выстрелу.
/datum/eldritch_knowledge/base_lead/proc/ricochet_block_reason(mob/living/user, check_cost = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet)
	if(!can_use(user, ignore_grab = TRUE) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = impact_block_reason(user)
	if(reason && sound_hunt_learned())
		var/hunt_reason = sound_hunt_reason(user)
		reason = hunt_reason ? "[reason] Охота на звук: [hunt_reason]" : null
	if(reason)
		return reason
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: Рикошет не унесёт."
	var/area/origin_area = get_area(user)
	if(origin_area.area_flags & NOTELEPORT)
		return "Зона закрыта для телепортации: Рикошет не унесёт."
	if(check_cost && lead_total() < 1)
		return "Нужна единица Свинца."
	return null

/datum/eldritch_knowledge/base_lead/proc/ricochet(mob/living/user)
	lead_failure = ricochet_block_reason(user)
	if(lead_failure)
		return FALSE
	if(impact_block_reason(user))
		return sound_hunt(user)
	var/turf/origin = get_turf(user)
	var/turf/destination = ricochet_landing()
	if(!spend_combat_resource())
		return FALSE
	user.visible_message(span_warning("[user] пропадает в клубе порохового дыма!"), span_notice("Вы уходите вслед за своей пулей."))
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		gain_combat_resource()
		lead_failure = "Рикошет сорвался: перенос что-то остановило. Свинец сохранён."
		return FALSE
	heretic_lead_powder_smoke(origin, smoke_tint())
	new /obj/effect/temp_visual/heretic_lead/ricochet(destination)
	heretic_lead_sound(destination, "ricochet", 60, TRUE)
	log_game("[key_name(user)] уходит Рикошетом Свинца из [AREACOORD(origin)] в [AREACOORD(destination)].")
	impact_turf = null
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "ricochet", destination)
	return TRUE

/// Пороховой дым на месте ухода закрывает обзор на 3 секунды.
/proc/heretic_lead_powder_smoke(turf/origin, tint)
	if(!isturf(origin))
		return
	var/obj/effect/temp_visual/heretic_lead/smoke/puff = new(origin)
	puff.color = tint
	for(var/direction in GLOB.cardinals)
		var/turf/nearby = get_step(origin, direction)
		if(isopenturf(nearby) && !nearby.density)
			puff = new(nearby)
			puff.color = tint

/datum/eldritch_knowledge/base_lead/pocket_exits(mob/living/user)
	. = list()
	if(impact_turf)
		heretic_add_pocket_exit(., "Рикошет - [get_area_name(impact_turf, TRUE)]", heretic_pocket_landing(impact_turf))

/datum/eldritch_knowledge/base_lead/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в свинец", "text" = "Свинцовая тяжесть тянет [victim] сквозь пол.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель лежит под своей Свинцовой тяжестью, еретик рядом.
/datum/eldritch_knowledge/base_lead/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	var/datum/status_effect/heretic_lead_heavy/heavy = victim.has_status_effect(/datum/status_effect/heretic_lead_heavy)
	return heavy?.lead_ref?.resolve() == src && heavy.fallen

/datum/eldritch_knowledge/base_lead/proc/zeroed_by_me(mob/living/victim)
	for(var/datum/status_effect/heretic_lead_zeroed/effect as anything in zeroed)
		if(effect.owner == victim)
			return TRUE
	return FALSE

/// Пристрелка: пуля еретика слегка доворачивает к цели под ней, если та почти на линии выстрела.
/datum/eldritch_knowledge/base_lead/proc/assist_aim(obj/item/projectile/projectile)
	var/mob/living/best
	var/best_angle = HERETIC_LEAD_ASSIST_ANGLE
	for(var/datum/status_effect/heretic_lead_zeroed/effect as anything in zeroed)
		var/mob/living/target = effect.owner
		if(!isturf(target?.loc) || target.z != projectile.z || get_dist(projectile, target) > HERETIC_LEAD_NAMED_RANGE)
			continue
		var/difference = abs(closer_angle_difference(projectile.Angle, get_projectile_angle(projectile, target)))
		if(difference <= best_angle)
			best = target
			best_angle = difference
	if(!best)
		return null
	heretic_lead_home(projectile, best, HERETIC_LEAD_ASSIST_TURN)
	return best

/// Доворот снаряда к цели; цель становится прямой, чтобы пуля попала и в лежачего. Ссылку на цель до выстрела подпишет fire(), в полёте - сам доворот.
/proc/heretic_lead_home(obj/item/projectile/projectile, mob/living/target, turn_speed)
	projectile.set_homing_target(target)
	if(projectile.homing_target != target)
		return FALSE
	projectile.homing_turn_speed = turn_speed
	projectile.original = target
	if(projectile.fired)
		projectile.RegisterSignal(target, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/obj/item/projectile, clear_deleted_combat_reference), override = TRUE)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/named_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/lead_named)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_LEAD_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_LEAD_NAMED_RANGE)
		return "Цель должна стоять не дальше [HERETIC_LEAD_NAMED_RANGE] клеток на вашем этаже."
	if(victim.has_status_effect(/datum/status_effect/heretic_lead_heavy))
		return "Цель уже тяжелеет от свинца."
	if(check_cost && lead_total() < HERETIC_LEAD_NAMED_COST)
		return "Нужно [HERETIC_LEAD_NAMED_COST] Свинца; сейчас [lead_total()]."
	return null

/datum/eldritch_knowledge/base_lead/proc/fire_named(mob/living/user, mob/living/victim)
	lead_failure = named_block_reason(user, victim)
	if(lead_failure || !spend_combat_resource(HERETIC_LEAD_NAMED_COST))
		return FALSE
	mark_combat()
	var/obj/item/projectile/heretic_lead_named/bullet = new(get_turf(user))
	bullet.firer = user
	bullet.lead_ref = WEAKREF(src)
	bullet.aim_at(victim)
	bullet.def_zone = BODY_ZONE_CHEST
	bullet.preparePixelProjectile(victim, user)
	heretic_lead_home(bullet, victim, HERETIC_LEAD_NAMED_TURN)
	bullet.fire()
	var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(get_turf(user))
	flash.setDir(get_dir(user, victim))
	heretic_lead_sound(user, "named_cast", 55, TRUE)
	user.visible_message(span_danger("С ладони [user] срывается тусклая свинцовая пуля и медленно плывёт к [victim]!"), span_notice("Пуля с именем [victim] уходит с ладони."))
	to_chat(victim, span_userdanger("К вам плывёт тусклая пуля - на ней ваше имя! Заслонитесь кем-нибудь или щитом."))
	log_combat(user, victim, "выпускает Пулю с именем в")
	return bullet

/// Пуля нашла цель. Чужого она не узнаёт.
/datum/eldritch_knowledge/base_lead/proc/named_hit(obj/item/projectile/heretic_lead_named/bullet, atom/target)
	record_impact(get_turf(bullet))
	if(!isliving(target))
		return FALSE
	var/mob/living/victim = target
	var/mob/living/named = bullet.named_ref?.resolve()
	if(victim != named)
		victim.visible_message(span_notice("Пуля не узнаёт [victim] и осыпается свинцовой пылью."), span_notice("Пуля ударяет вас и осыпается свинцовой пылью: имя на ней было чужое."))
		return FALSE
	if(!bullet.struck)
		victim.visible_message(span_notice("Пуля с именем вязнет в защите [victim] и осыпается."))
		return FALSE
	if(!can_use(lead_body))
		named_fizzle(victim)
		return FALSE
	var/reason = heretic_capture_block_reason(lead_body, victim, HERETIC_LEAD_CAPTURE)
	if(reason)
		to_chat(lead_body, span_warning("Пуля с именем: [reason]"))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(lead_body)
	var/immediate = zeroed_by_me(victim) && victim.mind && victim.mind == heretic.hunt_target
	var/datum/status_effect/heretic_lead_heavy/heavy = victim.apply_status_effect(/datum/status_effect/heretic_lead_heavy, src, immediate)
	if(QDELETED(heavy))
		return FALSE
	heretic_lead_sound(victim, "named_hit", 55, TRUE)
	heretic.advance_combat_deed(victim, PATH_LEAD)
	log_combat(lead_body, victim, "вешает Свинцовую тяжесть Пулей с именем на", addition = immediate ? "цель охоты под Пристрелкой падает сразу" : null)
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "named", victim)
	return TRUE

/// Пуля долетела, а стрелок не может её удержать: она осыпается, а живому стрелку свинец возвращается в барабан.
/datum/eldritch_knowledge/base_lead/proc/named_fizzle(mob/living/victim)
	victim.visible_message(span_notice("Пуля с именем касается [victim] и осыпается свинцовой пылью: стрелок её не удержал."), span_notice("Пуля с вашим именем касается вас и осыпается пылью."))
	var/refund = lead_body && lead_body.stat != DEAD && owner_heretic()
	if(refund)
		gain_combat_resource(HERETIC_LEAD_NAMED_COST)
		to_chat(lead_body, span_warning("Пуля с именем долетела до [victim], но вы не смогли её удержать: свинец вернулся в барабан. Свинец: [combat_resource] из [combat_resource_max]."))
	log_game("[key_name(lead_body)]: Пуля с именем осыпалась у [key_name(victim)] в [AREACOORD(victim)], стрелок недееспособен[refund ? ", Свинец возвращён" : ""].")

/datum/eldritch_knowledge/base_lead/proc/rain_turfs(turf/center)
	. = list()
	var/radius = rain_radius()
	for(var/turf/open/tile in heretic_field_view(radius, center))
		if(get_dist_euclidian(tile, center) <= radius + 0.5)
			. += tile

/datum/eldritch_knowledge/base_lead/proc/rain_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	if(!can_use(user) || !rain_known())
		return "Способность недоступна вашему пути или текущему телу."
	var/turf/center = get_turf(target)
	if(!isopenturf(center) || center.z != user.z || get_dist(user, center) > HERETIC_LEAD_RAIN_RANGE)
		return "Выберите видимый пол не дальше [HERETIC_LEAD_RAIN_RANGE] клеток."
	if(check_cost && lead_total() < rain_cost())
		return "Нужно [rain_cost()] Свинца; сейчас [lead_total()]."
	return null

/datum/eldritch_knowledge/base_lead/proc/rain(mob/living/user, atom/target)
	lead_failure = rain_block_reason(user, target)
	if(lead_failure || !spend_combat_resource(rain_cost()))
		return FALSE
	mark_combat()
	var/turf/center = get_turf(target)
	var/list/turf/field = rain_turfs(center)
	for(var/turf/tile as anything in field)
		new /obj/effect/temp_visual/heretic_lead/rain_marker(tile)
	heretic_lead_sound(center, "rain_warn", 55, FALSE)
	addtimer(CALLBACK(src, PROC_REF(rain_strike), center, field), HERETIC_LEAD_RAIN_DELAY)
	log_game("[key_name(user)] вызывает Свинцовый дождь в [AREACOORD(center)].")
	return TRUE

/// Свинец падает на подсвеченные клетки; кто ушёл из круга - цел.
/datum/eldritch_knowledge/base_lead/proc/rain_strike(turf/center, list/turf/field)
	if(QDELETED(src) || QDELETED(lead_body) || lead_body.stat == DEAD)
		return 0
	var/datum/antagonist/heretic/heretic = IS_HERETIC(lead_body)
	. = 0
	for(var/turf/tile as anything in field)
		new /obj/effect/temp_visual/heretic_lead/rain_impact(tile)
		for(var/mob/living/victim in tile)
			if(!heretic_can_affect(lead_body, victim))
				continue
			victim.adjustBruteLoss(HERETIC_LEAD_RAIN_DAMAGE)
			if(QDELETED(victim))
				continue
			victim.apply_status_effect(/datum/status_effect/heretic_lead_slowed)
			heretic?.advance_combat_deed(victim, PATH_LEAD)
			log_combat(lead_body, victim, "бьёт Свинцовым дождём")
			.++
	heretic_lead_sound(center, "rain", 65, TRUE)

/obj/effect/proc_holder/spell/pointed/heretic_lead
	clothes_req = FALSE
	invocation_type = "none"
	selection_type = "view"
	aim_assist = FALSE
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	active_msg = "Наведите прицел."
	deactive_msg = "Вы опускаете руку."

/obj/effect/proc_holder/spell/pointed/heretic_lead/proc/lead_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)

/obj/effect/proc_holder/spell/pointed/heretic_lead/can_cast(mob/user, skipcharge, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	return ..() && heretic_check(user, lead?.can_use(user, usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_lead/hex
	name = "Сглаз ствола"
	desc = "За единицу Свинца заговорите огнестрел в руках стрелка не дальше 7 клеток: в ближайшие 10 секунд его выстрел даст осечку, и ствол заклинит на 2 секунды. Лазеры, энергия и игрушки не поддаются. Защита от магии отводит сглаз: Свинец цел, но перезарядка идёт. Перезарядка 15 секунд."
	summary = "За единицу Свинца оружие стрелка в 7 клетках даст осечку и заклинит на 2 секунды."
	charge_max = HERETIC_LEAD_HEX_COOLDOWN
	range = HERETIC_LEAD_HEX_RANGE
	aim_assist_radius = 1
	action_icon_state = "lead_curse"

/obj/effect/proc_holder/spell/pointed/heretic_lead/hex/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead ? lead.hex_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_lead/hex/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!length(targets) || !lead)
		heretic_revert_cast(user)
		return
	if(lead.hex(user, targets[1]))
		return
	if(lead.hex_deflected)
		heretic_check(user, FALSE, FALSE, lead.lead_failure)
	else
		heretic_revert_cast(user, lead.lead_failure)

/obj/effect/proc_holder/spell/pointed/heretic_lead/named
	name = "Пуля с именем"
	desc = "За 2 Свинца выпустите с ладони медленную пулю в видимую цель не дальше 9 клеток: она сама доворачивает к цели около двух секунд. Попав, она 6 секунд тяжелит и замедляет цель, затем валит её на 4 секунды; цель охоты под Пристрелкой падает сразу. Пулю можно заслонить телом или щитом. Тяжесть снимают нулевой жезл, святая вода в крови, толчок за 2 секунды и уход дальше 13 клеток от вас - туда пуля уже не долетает. Если в миг попадания вы оглушены, пуля осыпается, а Свинец возвращается. Перезарядка 25 секунд."
	summary = "За 2 Свинца медленная пуля к цели в 9 клетках: 6 секунд тяжести, затем падение на 4 секунды."
	charge_max = HERETIC_LEAD_NAMED_COOLDOWN
	range = HERETIC_LEAD_NAMED_RANGE
	aim_assist_radius = 1
	action_icon_state = "lead_named"

/obj/effect/proc_holder/spell/pointed/heretic_lead/named/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead ? lead.named_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_lead/named/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!length(targets) || !lead?.fire_named(user, targets[1]))
		heretic_revert_cast(user, lead?.lead_failure)

/obj/effect/proc_holder/spell/pointed/heretic_lead/rain
	name = "Свинцовый дождь"
	desc = "За 2 Свинца подсветите круг радиусом 2 клетки на видимом полу не дальше 7 клеток. Через 1,5 секунды на него падает свинец: 30 ушибов и замедление на 3 секунды каждому врагу в круге. Подсветку видят все; стены закрывают клетки за собой. У Канонира круг радиусом 3 клетки, цена - единица Свинца, а сам дождь приходит сразу с выбором Школы. Перезарядка 30 секунд."
	summary = "За 2 Свинца круг радиусом 2 в 7 клетках: через 1,5 секунды 30 ушибов и замедление."
	charge_max = HERETIC_LEAD_RAIN_COOLDOWN
	range = HERETIC_LEAD_RAIN_RANGE
	aim_assist = TRUE
	aim_assist_turf = TRUE
	action_icon_state = "lead_rain"

/obj/effect/proc_holder/spell/pointed/heretic_lead/rain/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead ? lead.rain_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_lead/rain/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!length(targets) || !lead?.rain(user, targets[1]))
		heretic_revert_cast(user, lead?.lead_failure)

/obj/effect/proc_holder/spell/self/heretic_lead
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_lead/proc/lead_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)

/obj/effect/proc_holder/spell/self/heretic_lead/can_cast(mob/user, skipcharge, silent)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	return ..() && heretic_check(user, lead?.can_use(user, usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_lead/catch_bullet
	name = "Ловля пули"
	desc = "На 1,5 секунды ловите каждую баллистическую пулю и дробь, летящие в вас: пойманная не ранит и даёт единицу Свинца, пока барабан и патронташ не полны. Пока окно открыто, над экраном горит его значок. Лазеры, энергия, игрушки, удары и брошенные вещи проходят как обычно. Работает и в чужой хватке, но не в наручниках. Перезарядка 20 секунд."
	summary = "1,5 секунды ловите пули и дробь, летящие в вас: единица Свинца за каждую."
	charge_max = HERETIC_LEAD_CATCH_COOLDOWN
	usable_while_grabbed = TRUE
	action_icon_state = "lead_catch"

/obj/effect/proc_holder/spell/self/heretic_lead/catch_bullet/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!lead?.can_use(user, usable_while_grabbed))
		heretic_revert_cast(user)
		return
	var/datum/status_effect/heretic_lead_catch/window = user.apply_status_effect(/datum/status_effect/heretic_lead_catch, lead)
	if(QDELETED(window))
		heretic_revert_cast(user, "Ловля пули уже идёт.")

/obj/effect/proc_holder/spell/self/heretic_lead/ricochet
	name = "Рикошет"
	desc = "За единицу Свинца мгновенно перенеситесь к месту, куда за последние 20 секунд ударилась пуля вашего Шестизарядника, Пуля с именем или дробина Пальца-ствола, если оно не дальше 12 клеток на вашем этаже. Если там стоит человек, вы окажетесь рядом. На прежнем месте 3 секунды стоит пороховой дым. Уводит и из чужой хватки; зоны без телепортации, наручники и пристёгивание не пускают. С 3 принятых душ, если своей пули нет, раз в 3 минуты Рикошет ведёт на звук чужого выстрела из огнестрела в 12 клетках: там встаёт столб порохового дыма, а вы секунду стоите на месте. Сколько осталось точке и Охоте на звук, видно в подсказке значка Свинца. Перезарядка 15 секунд."
	summary = "За единицу Свинца переход к месту удара вашей пули в 12 клетках; на старом месте дым."
	charge_max = HERETIC_LEAD_RICOCHET_COOLDOWN
	usable_while_grabbed = TRUE
	action_icon_state = "lead_ricochet"

/obj/effect/proc_holder/spell/self/heretic_lead/ricochet/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead.ricochet_block_reason(user)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_lead/ricochet/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	if(!lead?.ricochet(user))
		heretic_revert_cast(user, lead?.lead_failure)

/datum/eldritch_knowledge/lead_grasp
	name = "Отдача"
	summary = "Хватка отбрасывает врага на 2 клетки и вешает на него Пристрелку на 20 секунд."
	details = list(
		"Пуля Шестизарядника слегка доворачивает к цели под Пристрелкой, если та почти на линии выстрела.",
		"Цель охоты под Пристрелкой от Пули с именем падает сразу, без 6 секунд тяжести.",
		"Толчок упирается в стены и двери; союзники и защита от магии не принимают ни толчка, ни Пристрелки.",
		"Третья за раунд осечка заговорённого оружия у одного стрелка разворачивает ствол: пуля ему в ногу.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Я выстрелил, и меня не отбросило. Отбросило того, в кого я целился."
	cost = 1
	route = PATH_LEAD

/datum/eldritch_knowledge/lead_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(!proximity_flag || !lead?.can_use(user) || !isliving(target) || !isturf(target.loc) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	var/mob/living/victim = target
	lead.zero_in(victim)
	var/turf/landing = get_ranged_target_turf(victim, get_dir(user, victim), HERETIC_LEAD_RECOIL_DISTANCE)
	if(!victim.anchored && victim.move_resist < MOVE_FORCE_STRONG)
		victim.safe_throw_at(landing, HERETIC_LEAD_RECOIL_DISTANCE, 1, user, force = MOVE_FORCE_STRONG)
	log_combat(user, victim, "отбрасывает Отдачей и берёт на Пристрелку")
	SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "recoil", victim)
	return TRUE

/datum/eldritch_knowledge/lead_grasp/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(lead)
		QDEL_LIST(lead.zeroed)

/datum/eldritch_knowledge/spell/lead_named
	name = "Пуля с именем"
	summary = "За 2 Свинца медленная пуля летит к видимой цели в 9 клетках: тяжесть, затем падение."
	details = list(
		"Пуля летит около 2 секунд и доворачивает к цели; её заслоняют тело или щит, лазер её не собьёт.",
		"Чужому человеку на пути пуля почти не вредит и осыпается: имени его она не знает.",
		"Цель 6 секунд тяжелеет и замедляется, затем падает на 4 секунды; всё это держит как захват.",
		"Тяжесть снимают нулевой жезл, святая вода в крови, толчок за 2 секунды и уход дальше 13 клеток от вас.",
		"Упавшую цель охоты сердце уводит в изнанку, если вы стоите рядом. Перезарядка 25 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Я выцарапал на пуле имя. Она сразу стала тяжелее."
	cost = 2
	route = PATH_LEAD
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_lead/named

/datum/eldritch_knowledge/spell/lead_named/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(lead)
		QDEL_LIST(lead.heavies)
	return ..()

/datum/eldritch_knowledge/lead_mark
	name = "Мишень"
	summary = "Хватка вешает Мишень на 15 секунд; кнопка «Школа стрельбы» выбирает Стрелка, Охотника или Канонира."
	details = list(
		"Пули экипажа в 2 клетках от меченого сворачивают в него; перекрестие видят все, рядом лучше не стрелять.",
		"Взрыв метки клинком - Прострел: 20 ушибов и 2 секунды на полу; на цели охоты Мишень держится 25 секунд.",
		"Меченая камора Шестизарядника: пуля на 25 ушибов вешает Мишень; убитый меченый человек даёт вам 2 Свинца.",
		"Школа выбирается один раз и работает сразу; сменить её можно только сбросом пути. Она красит трассеры и дым.",
		"Стрелок: вооружённые враги на виду, до 4, ускоряют шаг и выстрелы; 3 стрелка за 3 секунды - Мгновение и Ловля.",
		"Охотник: прицел за 0,6 секунды в 12 клетках, Мишень на 10 секунд дольше и видна сквозь стены, Растяжки.",
		"Канонир: Свинцовый дождь сразу, радиусом 3 за единицу; веер на 2 пули длиннее, хлопающая пуля, Пороховые закладки.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Я нарисовал на его спине круг. Теперь в него будут целиться все."
	cost = 2
	route = PATH_LEAD

/datum/eldritch_knowledge/lead_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(!proximity_flag || !lead?.can_use(user) || !isliving(target) || !isturf(target.loc) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	return TRUE

/datum/eldritch_knowledge/lead_mark/on_body_lose(mob/living/user)
	drop_school_powers()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(lead)
		QDEL_LIST(lead.marks)

/datum/eldritch_knowledge/lead_relic
	name = "Шестизарядник Мансуса"
	summary = "Гильза и лист железа на руне дают револьвер на шесть камор; потерянный можно призвать обратно в руку."
	details = list(
		"Попадание в живого врага возвращает камору, убитый - ещё 3 Свинца; пустой барабан за 1 секунду дозаряжает патронташ.",
		"Свинцовая: 35 ушибов, пробитие 40; Тяжёлая: 25 и валит на 1,5 секунды сквозь броню; закрытые - Свинцовые.",
		"Alt-клик - выбрать камору за 0,5 секунды; Ctrl-клик раз в 6 секунд крутит барабан, выпавшая пуля бьёт на 25% сильнее.",
		"«Использовать в руке» - стиль: прицельный (секунда без движения) +50% урона и пробитие; веер - все каморы за секунду.",
		"В голову стоящему - +30% урона и звон в ушах; каждая душа - +5 пробития всем пулям, до 20.",
		"«Призвать Шестизарядник»: из своей сумки даром и без отката, издалека за 1 Свинец; жезл и святая вода срывают призыв.",
		"Вред вплотную - удар рукоятью: 20 ушибов, замедление на 2 секунды и Свинец; чужому револьвер бьёт в ногу.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "В барабане шесть камор. Пустых не бывает, пока я жив."
	cost = 1
	route = PATH_LEAD
	required_atoms = list(/obj/item/ammo_casing, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/heretic_path_relic/lead_revolver)

/datum/eldritch_knowledge/lead_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/lead_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/lead_revolver)

/datum/eldritch_knowledge/spell/lead_catch
	name = "Ловля пули"
	summary = "Полторы секунды вы ловите пули и дробь, летящие в вас: единица Свинца за каждую."
	details = list(
		"Пойманная пуля не ранит; лазеры, энергия, игрушки, удары и брошенные вещи проходят как обычно.",
		"Работает и в чужой хватке, но не в наручниках. Перезарядка 20 секунд.",
		"У Шестизарядника открывается Пороховая камора: 20 ушибов, цель вспыхивает и ещё 10 ожогов получает сквозь броню.",
	)
	role = HERETIC_ROLE_DEFENSE
	gain_text = "Я поймал пулю зубами. На вкус она была как чужое обещание."
	cost = 1
	route = PATH_LEAD
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_lead/catch_bullet

/datum/eldritch_knowledge/spell/lead_ricochet
	name = "Рикошет"
	summary = "За единицу Свинца мгновенно уводит к месту удара вашей пули за последние 20 секунд."
	details = list(
		"Точку ставит пуля Шестизарядника, Пуля с именем или дробина Пальца-ствола, попавшая в стену, вещь или человека.",
		"Место удара не дальше 12 клеток на вашем этаже; на прежнем месте 3 секунды стоит пороховой дым.",
		"Уводит и из чужой хватки; зоны без телепортации, наручники и пристёгивание не пускают. Перезарядка 15 секунд.",
		"Из изнанки можно выйти к последнему месту удара своей пули на станции.",
		"С 3 душ без своей пули раз в 3 минуты ведёт на чужой выстрел в 12 клетках: столб дыма и секунда ожидания.",
		"У Шестизарядника открывается Звонкая камора: 25 ушибов, затем видимый рикошет на 15 в соседа в 4 клетках.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Пуля ушла от стены под углом. Я ушёл вместе с ней."
	cost = 1
	route = PATH_LEAD
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_lead/ricochet

/datum/eldritch_knowledge/lead_ear
	name = "Слух стрелка"
	summary = "Указатель на выстрел из огнестрела в 30 клетках, Пристрелка на стрелявших рядом и Последний патрон."
	details = list(
		"Красный указатель на выстрел видите только вы; лазеры, энергию и игрушки это ухо не слышит.",
		"Стрелявший в 7 клетках в вашу сторону или у вас на виду получает Пристрелку на 5 секунд; сквозь стену - нет.",
		"Осечка заговорённого оружия называет вам отсек, где пытались выстрелить.",
		"Шестая камора: при полном барабане Alt-клик взводит её, и выстрел в человека - Последний патрон за весь Свинец.",
		"Снять Шестую камору с курка - выбрать другую камору или Ctrl-клик. Убитый Последним патроном человек вернёт 3 Свинца.",
		"1,5 секунды к цели тянется линия огня и горит прицел, затем пуля на 45 ушибов пробивает до 2 целей и валит на 2 секунды.",
		"Лежачего, укрывшегося за углом или щитом Последний патрон не достанет. Улучшения: Пристрелка на 10 и 15 секунд.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Я слышу каждый выстрел. Каждый - как своё имя, произнесённое шёпотом."
	cost = 2
	route = PATH_LEAD
	passive_values = list(5 SECONDS, 10 SECONDS, 15 SECONDS)
	passive_desc = "Стрелявший из огнестрела в 7 клетках от вас в вашу сторону или у вас на виду получает Пристрелку на 5 / 10 / 15 секунд: пули Шестизарядника доворачивают к нему, а цель охоты под ней Пуля с именем валит сразу. Указатель на выстрел на любом уровне работает в 30 клетках."
	var/mob/living/listener
	var/list/atom/movable/screen/heretic_lead_ear/arrows = list()
	var/list/heard_at = list()

/datum/eldritch_knowledge/lead_ear/on_body_gain(mob/living/user)
	if(!user || listener == user)
		return
	on_body_lose(listener)
	listener = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_listener_deleted))
	RegisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED, PROC_REF(on_gunshot))

/datum/eldritch_knowledge/lead_ear/on_body_lose(mob/living/user)
	UnregisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED)
	if(listener)
		UnregisterSignal(listener, COMSIG_PARENT_QDELETING)
	listener = null
	QDEL_LIST(arrows)
	heard_at.Cut()

/datum/eldritch_knowledge/lead_ear/Destroy()
	on_body_lose(listener)
	return ..()

/datum/eldritch_knowledge/lead_ear/proc/on_listener_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(listener)

/datum/eldritch_knowledge/lead_ear/proc/hearing_range()
	return HERETIC_LEAD_EAR_RANGE

/datum/eldritch_knowledge/lead_ear/proc/zeroing_time()
	return passive_values[clamp(passive_level, 1, length(passive_values))]

/// Стрелявший рядом в вашу сторону или у вас на виду сам подставился: на нём Пристрелка. Сквозь стены ухо не целится.
/datum/eldritch_knowledge/lead_ear/proc/zero_shooter(mob/living/shooter, turf/here, atom/target)
	var/turf/from = get_turf(shooter)
	if(!isliving(shooter) || !from || from.z != here.z || get_dist(here, from) > HERETIC_LEAD_UNDER_FIRE_RANGE)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(listener)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(!lead || (!lead.shot_toward_body(shooter, target) && !can_see(shooter, listener, HERETIC_LEAD_UNDER_FIRE_RANGE)))
		return
	if(lead.can_use(listener, TRUE) && heretic_can_affect(listener, shooter, chargecost = 0, notify = FALSE))
		lead.zero_in(shooter, zeroing_time())

/datum/eldritch_knowledge/lead_ear/proc/on_gunshot(datum/source, obj/item/gun/gun, mob/living/shooter, atom/target, fired)
	SIGNAL_HANDLER
	if(QDELETED(listener) || listener.stat == DEAD || shooter == listener || !heretic_lead_gunshot(gun, fired))
		return
	var/turf/here = get_turf(listener)
	var/turf/there = get_turf(gun)
	if(!here || !there || here == there || here.z != there.z || get_dist(here, there) > hearing_range())
		return
	zero_shooter(shooter, here, target)
	var/key = REF(shooter || gun)
	if(heard_at[key] > world.time)
		return
	if(length(heard_at) >= HERETIC_LEAD_EAR_PRUNE)
		heard_at.Cut()
	heard_at[key] = world.time + HERETIC_LEAD_EAR_REPEAT
	show_arrow(get_dir(here, there))

/datum/eldritch_knowledge/lead_ear/proc/show_arrow(direction)
	while(length(arrows) >= HERETIC_LEAD_EAR_LIMIT)
		qdel(arrows[1])
	var/atom/movable/screen/heretic_lead_ear/arrow = new(null, src, direction)
	arrows += arrow
	listener.client?.screen += arrow
	QDEL_IN(arrow, HERETIC_LEAD_EAR_TIME)
	return arrow

/atom/movable/screen/heretic_lead_ear
	name = "gunshot"
	icon = 'icons/effects/multitool_arrows.dmi'
	icon_state = "navigate_arrow_appear"
	screen_loc = around_player
	pixel_x = -32
	pixel_y = -32
	color = "#d2362b"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/datum/eldritch_knowledge/lead_ear/ear

/atom/movable/screen/heretic_lead_ear/Initialize(mapload, datum/eldritch_knowledge/lead_ear/ear, direction)
	. = ..(mapload)
	src.ear = ear
	transform = matrix(dir2angle(direction), MATRIX_ROTATE)

/atom/movable/screen/heretic_lead_ear/Destroy()
	if(ear)
		ear.listener?.client?.screen -= src
		ear.arrows -= src
		ear = null
	return ..()

/datum/eldritch_knowledge/spell/lead_rain
	name = "Свинцовый дождь"
	summary = "За 2 Свинца круг радиусом 2 в 7 клетках подсвечивается, через 1,5 секунды на него падает свинец."
	details = list(
		"Удар: 30 ушибов и замедление на 3 секунды всем в круге, кроме еретиков и их слуг.",
		"Подсветку видят все, из круга можно выйти; стены закрывают клетки за собой. Перезарядка 30 секунд.",
		"Мёртвый стрелок: огнестрел павшего в 5 клетках от вас человека встаёт призрачным стволом на 10 секунд.",
		"Ствол 2 раза стреляет по живым на 15 ушибов, каждый раз после 1 секунды красной линии; раз в минуту.",
		"Призрачный ствол сбивает удар или выстрел в него; только на станции.",
		"Канонир получает дождь сразу с выбором Школы: круг радиусом 3 клетки за единицу Свинца.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Небо над тиром почернело. Сверху посыпались гильзы, а за ними - то, что из них вылетело."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_LEAD
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_lead/rain

/datum/eldritch_knowledge/final_eldritch/lead_final
	name = "Тот, Кто Держит Курок"
	summary = "Три Литейных тигля: пока горят, вы слышите выстрелы станции и приходите на них; Последний залп по шестерым."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне станции; станция узнаёт место обряда.",
		"Встают 3 Литейных тигля в общих отсеках, первые - у мест осечек заговорённого оружия; станции объявят где.",
		"Тигель гасят 3 струи воды или пены, оружие (150 прочности), нулевой жезл за 2 удара; со смертью тигли остынут.",
		"Пока горит тигель, Шестизарядник даром, а барабан бьёт раз в минуту: каждый 3-й удар - 2 Свинца и Шестая камора.",
		"«На выстрел»: за 1 секунду к стрелку последнего выстрела за 15 секунд, на любом этаже; перезарядка 30 секунд.",
		"Последний залп: до 6 врагов в 8 клетках, линии прицела 1,5 секунды, затем пуля на 35 ушибов; перезарядка 30 секунд.",
		"Залп за угол бьёт рикошетом вполовину силы; Свинец копится раз в 5 секунд; Свинцовая камора - Бронебойная.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Я больше не держу оружие. Теперь оружие держит меня - и целится оно туда, куда смотрю я."
	route = PATH_LEAD
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_lead/final_volley, /obj/effect/proc_holder/spell/self/heretic_lead/to_shot)

/datum/eldritch_knowledge/final_eldritch/lead_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(lead)
		lead.ascension_active = TRUE
		lead.update_drum_hud()
	update_crucible_alert()

/datum/eldritch_knowledge/final_eldritch/lead_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	var/datum/antagonist/heretic/heretic = IS_HERETIC(body)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(lead)
		lead.ascension_active = FALSE
	body?.clear_alert(HERETIC_LEAD_CRUCIBLE_ALERT)
	return ..()

/obj/item/melee/sickly_blade/lead
	name = "Saturn's bayonet"
	desc = "Длинный гранёный штык из тусклого свинца. Рукоять - обрезок ствола в латунных кольцах, и из его дула всё время тянется пороховой дымок. На гарде свинцовый шар в наклонном латунном кольце, как Сатурн, а на шаре алеет перекрестие прицела."
	icon = 'modular_bluemoon/icons/obj/heretic_lead.dmi'
	icon_state = "lead_blade"
	item_state = "lead_blade"
	hitsound = HERETIC_LEAD_HIT_SFX
	route = PATH_LEAD
	mark_type = /datum/status_effect/eldritch/lead

/datum/heretic_deed/lead
	name = "Осечки"
	next_step = "Заговорите Хваткой в намерении «Помощь» огнестрел или магазин и дождитесь, когда из него попробует выстрелить член экипажа в ещё не зачтённом отделе."
	desc = "Заговаривайте Хваткой Мансуса в намерении «Помощь» огнестрельное оружие и магазины. Дело продвигает осечка в руках члена экипажа на станции: засчитывается отдел, где стоял стрелок, каждый отдел один раз."
	craft_wait = "осечка случится, но в дело не пойдёт"
	craft_wait_place = "в ещё не зачтённом отделе"
	hint = "Держатся четыре заговора, новый вытесняет самый старый. Оружейная, снабжение и ящики с оружием - хорошие места. Детектив, капеллан и еретики замечают вблизи свинцовую патину, а нулевой жезл и святая вода снимают заговор."
	trace_name = "flattened bullet"
	trace_desc = "На полу лежит сплющенная свинцовая пуля, хотя никто не помнит выстрела."
	trace_state = "trace_lead"
	combat_hint = "Поразите назначенную цель Пулей с именем или Свинцовым дождём."

/datum/heretic_innate/lead
	name = "Тугое ухо"
	desc = "Грохот светошумовой гранаты вы переносите, как в наушниках: он не глушит и не валит с ног. Вспышка и взрыв вплотную действуют как обычно. Баллистическая пуля, попавшая в вас, восстанавливает 8 выносливости раз в 6 секунд."

/datum/heretic_innate/lead/bind(mob/living/user)
	. = ..()
	if(body)
		RegisterSignal(body, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet), override = TRUE)
		RegisterSignal(body, COMSIG_CARBON_SOUNDBANG, PROC_REF(on_soundbang), override = TRUE)

/datum/heretic_innate/lead/unbind()
	if(body)
		UnregisterSignal(body, list(COMSIG_ATOM_BULLET_ACT, COMSIG_CARBON_SOUNDBANG))
	return ..()

/datum/heretic_innate/lead/proc/on_soundbang(datum/source, list/reflist)
	SIGNAL_HANDLER
	if(valid())
		reflist[1] = max(0, reflist[1] - HERETIC_LEAD_INNATE_BANG_GUARD)

/datum/heretic_innate/lead/proc/on_bullet(datum/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	if(!valid() || world.time < ready_at || !heretic_lead_feeds(projectile, body))
		return
	trigger()
	body.adjustStaminaLoss(-HERETIC_LEAD_INNATE_STAMINA)

/// Свинцовая тяжесть: 6 секунд замедления, затем падение на 4 секунды; держит как захват.
/datum/status_effect/heretic_lead_heavy
	id = "heretic_lead_heavy"
	duration = HERETIC_LEAD_HEAVY_TIME + HERETIC_LEAD_FALL_TIME
	tick_interval = HERETIC_LEAD_HEAVY_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_lead_heavy
	examine_text = span_warning("SUBJECTPRONOUN гнёт к полу невидимая тяжесть, кожа отливает свинцом. Растолкайте за 2 секунды, ударьте нулевым жезлом, дайте святой воды или уведите подальше от еретика.")
	var/datum/weakref/lead_ref
	var/mob/living/shooter
	var/fallen = FALSE
	var/applied = FALSE
	var/held_since = 0
	var/fall_at = 0

/datum/status_effect/heretic_lead_heavy/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_lead/lead, immediate = FALSE)
	lead_ref = WEAKREF(lead)
	shooter = lead?.lead_body
	if(immediate)
		duration = HERETIC_LEAD_FALL_TIME
	fall_at = world.time + (immediate ? 0 : HERETIC_LEAD_HEAVY_TIME)
	. = ..()
	if(linked_alert)
		var/fall_text = immediate ? "Свинец свалил вас сразу: [HERETIC_LEAD_FALL_TIME / (1 SECONDS)] секунды на полу." : "Тело налито свинцом: шаг медленнее, через [HERETIC_LEAD_HEAVY_TIME / (1 SECONDS)] секунд вы упадёте на [HERETIC_LEAD_FALL_TIME / (1 SECONDS)] секунды."
		linked_alert.desc = "[fall_text] Уйдите от стрелка дальше [HERETIC_LEAD_HEAVY_BREAK_RANGE] клеток или на другой этаж; тяжесть снимут нулевой жезл, святая вода в крови и тот, кто растолкает вас за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды."

/datum/status_effect/heretic_lead_heavy/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!. || !lead || QDELETED(shooter) || owner.stat == DEAD)
		return FALSE
	applied = TRUE
	held_since = world.time
	lead.heavies += src
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(shaken_off))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice_starting))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_distance))
	RegisterSignal(shooter, COMSIG_MOVABLE_MOVED, PROC_REF(check_distance))
	RegisterSignal(shooter, COMSIG_PARENT_QDELETING, PROC_REF(on_shooter_deleted))
	heretic_capture_hold(owner, HERETIC_LEAD_CAPTURE)
	owner.add_atom_colour(HERETIC_LEAD_HEAVY_TINT, TEMPORARY_COLOUR_PRIORITY)
	if(world.time >= fall_at)
		fall()
	else
		owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_heavy)
		owner.visible_message(span_warning("[owner] тяжелеет и сутулится, кожа отливает свинцом."), span_userdanger("Свинец наливает тело тяжестью: через [HERETIC_LEAD_HEAVY_TIME / (1 SECONDS)] секунд вы рухнете! Уйдите от стрелка дальше [HERETIC_LEAD_HEAVY_BREAK_RANGE] клеток или пусть вас растолкают."))
	return TRUE

/datum/status_effect/heretic_lead_heavy/tick()
	var/reason = break_reason()
	if(reason)
		lift(reason)
		return
	if(!fallen && world.time >= fall_at)
		fall()

/// Почему тяжесть больше не держится, или null, если держится.
/datum/status_effect/heretic_lead_heavy/proc/break_reason()
	var/turf/shooter_turf = get_turf(shooter)
	var/turf/owner_turf = get_turf(owner)
	if(!shooter_turf || !owner_turf || shooter_turf.z != owner_turf.z)
		return "цель ушла на другой этаж"
	if(get_dist(shooter_turf, owner_turf) > HERETIC_LEAD_HEAVY_BREAK_RANGE)
		return "цель ушла дальше [HERETIC_LEAD_HEAVY_BREAK_RANGE] клеток"
	if(owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		return "в крови цели святая вода"
	if(owner.stat == DEAD)
		return "цель мертва"
	if(!heretic_can_affect(shooter, owner, chargecost = 0, notify = FALSE))
		return "цель под защитой от магии"
	return null

/datum/status_effect/heretic_lead_heavy/proc/fall()
	fallen = TRUE
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_heavy)
	owner.Knockdown(HERETIC_LEAD_FALL_TIME)
	new /obj/effect/temp_visual/heretic_lead/fall(get_turf(owner))
	owner.visible_message(span_danger("[owner] рушится на пол, будто налитый свинцом!"), span_userdanger("Тяжесть валит вас с ног!"))

/datum/status_effect/heretic_lead_heavy/proc/check_distance(datum/source)
	SIGNAL_HANDLER
	var/reason = break_reason()
	if(reason)
		lift(reason)

/datum/status_effect/heretic_lead_heavy/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(istype(item, /obj/item/nullrod))
		lift("её коснулись нулевым жезлом")

/datum/status_effect/heretic_lead_heavy/proc/shaken_off(datum/source)
	SIGNAL_HANDLER
	lift("цель растолкали")

/datum/status_effect/heretic_lead_heavy/proc/on_shooter_deleted(datum/source)
	SIGNAL_HANDLER
	lift()

/// Тяжесть спадает раньше срока: свинец уходит из тела, сбитый встаёт, стрелок узнаёт почему.
/datum/status_effect/heretic_lead_heavy/proc/lift(reason)
	if(QDELETED(src))
		return
	if(fallen)
		owner.SetKnockdown(0)
	owner.visible_message(span_notice("Свинцовая тяжесть отпускает [owner]."), span_notice("Тяжесть уходит из тела."))
	if(reason && !QDELETED(shooter))
		to_chat(shooter, span_warning("Тяжесть сошла с [owner]: [reason]."))
	qdel(src)

/datum/status_effect/heretic_lead_heavy/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_lead_heavy/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_PARENT_ATTACKBY, COMSIG_MOVABLE_MOVED))
		if(shooter)
			UnregisterSignal(shooter, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_heavy)
		owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, HERETIC_LEAD_HEAVY_TINT)
		var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
		lead?.heavies -= src
		heretic_capture_unhold(owner, HERETIC_LEAD_CAPTURE)
		heretic_capture_release(owner, HERETIC_LEAD_CAPTURE, 0, heretic_capture_held_for(held_since))
	shooter = null
	lead_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_lead_heavy
	name = "Свинцовая тяжесть"
	desc = "Тело налито свинцом: шаг медленнее, через 6 секунд вы упадёте на 4 секунды. Уйдите от стрелка дальше 13 клеток или на другой этаж; тяжесть снимут нулевой жезл, святая вода в крови и тот, кто растолкает вас за 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "lead_heavy"

/datum/movespeed_modifier/heretic_lead_heavy
	multiplicative_slowdown = HERETIC_LEAD_HEAVY_SLOWDOWN

/// Пристрелка: пули еретика доворачивают к цели, а цель охоты Пуля с именем валит сразу.
/datum/status_effect/heretic_lead_zeroed
	id = "heretic_lead_zeroed"
	duration = HERETIC_LEAD_ZEROED_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_lead_zeroed
	examine_text = span_warning("На одежде дрожит едва заметная красная точка, будто кто-то навёл прицел.")
	var/datum/weakref/lead_ref
	var/applied = FALSE

/datum/status_effect/heretic_lead_zeroed/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_lead/lead, lasts = HERETIC_LEAD_ZEROED_TIME)
	lead_ref = WEAKREF(lead)
	duration = lasts
	return ..()

/datum/status_effect/heretic_lead_zeroed/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!. || !lead || owner.stat == DEAD)
		return FALSE
	applied = TRUE
	lead.zeroed |= src
	to_chat(owner, span_warning("По спине пробегает холодок: на вас пристрелялись."))
	return TRUE

/datum/status_effect/heretic_lead_zeroed/on_remove()
	if(applied)
		var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
		lead?.zeroed -= src
	lead_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_lead_zeroed
	name = "Пристрелка"
	desc = "На вас пристрелялись: пули еретика Свинца доворачивают к вам, а его Пуля с именем свалит вас сразу, если вы его цель. Сходит сама за 5-20 секунд, но стрельба в его сторону или у него на виду её обновляет."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "lead_marked"

/// Замедление от Свинцового дождя.
/datum/status_effect/heretic_lead_slowed
	id = "heretic_lead_slowed"
	duration = HERETIC_LEAD_RAIN_SLOW_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	examine_text = span_warning("SUBJECTPRONOUN еле переставляет ноги: в мышцах будто осел свинец.")
	var/slow_type = /datum/movespeed_modifier/heretic_lead_slowed

/datum/status_effect/heretic_lead_slowed/on_apply()
	. = ..()
	owner.add_movespeed_modifier(slow_type)

/datum/status_effect/heretic_lead_slowed/on_remove()
	owner.remove_movespeed_modifier(slow_type)
	return ..()

/datum/movespeed_modifier/heretic_lead_slowed
	multiplicative_slowdown = HERETIC_LEAD_RAIN_SLOWDOWN

/// Ловля пули: полторы секунды пули и дробь, летящие в еретика, застревают у него в зубах и ладонях.
/datum/status_effect/heretic_lead_catch
	id = "heretic_lead_catch"
	duration = HERETIC_LEAD_CATCH_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_lead_catch
	var/datum/weakref/lead_ref
	var/caught = 0
	var/last_sound_at = -1

/datum/status_effect/heretic_lead_catch/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_lead/lead, lasts = HERETIC_LEAD_CATCH_TIME)
	lead_ref = WEAKREF(lead)
	duration = lasts
	return ..()

/datum/status_effect/heretic_lead_catch/on_apply()
	. = ..()
	if(!. || !lead_ref?.resolve())
		return FALSE
	RegisterSignal(owner, COMSIG_LIVING_RUN_BLOCK, PROC_REF(catch_bullet))
	heretic_vfx_pulse(owner, HERETIC_LEAD_INK, 1, duration)
	return TRUE

/datum/status_effect/heretic_lead_catch/proc/catch_bullet(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!real_attack || return_list?[HERETIC_BLOCK_ABSORBED] || !(attack_type & ATTACK_TYPE_PROJECTILE) || !heretic_lead_feeds(object, owner))
		return BLOCK_NONE
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!lead)
		return BLOCK_NONE
	return_list?[BLOCK_RETURN_PROJECTILE_BLOCK_PERCENTAGE] = 100
	return_list?[HERETIC_BLOCK_ABSORBED] = TRUE
	caught++
	lead.gain_combat_resource()
	new /obj/effect/temp_visual/heretic_lead/catch(get_turf(owner))
	if(last_sound_at != world.time)
		last_sound_at = world.time
		heretic_lead_sound(owner, "catch", 55, TRUE)
	if(caught == 1)
		owner.visible_message(span_danger("[owner] ловит пулю на лету!"), span_notice("Вы ловите пулю: свинец ваш."))
		SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "catch", owner, caught)
	return BLOCK_SUCCESS

/datum/status_effect/heretic_lead_catch/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_RUN_BLOCK)
	if(caught)
		log_game("[key_name(owner)] ловит Ловлей пули Свинца пуль: [caught] в [AREACOORD(owner)].")
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead)
		SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "catch_end", owner, caught)
	lead_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_lead_catch
	name = "Ловля пули"
	desc = "Пули и дробь, летящие в вас, вязнут в ладонях: пойманная не ранит и даёт единицу Свинца."
	icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	icon_state = "lead_catch"

/// Мишень: перекрестие над меченым и пули экипажа, сворачивающие в него.
/datum/status_effect/eldritch/lead
	id = "lead_mark"
	mark_name = "Мишень"
	mark_alert_state = "sigil_lead"
	effect_sprite_icon = HERETIC_LEAD_FX_ICON
	effect_sprite = "lead_mark"
	effect_sprite_layer = ABOVE_MOB_LAYER
	detonation_sound = 'modular_bluemoon/sound/heretic/lead_named_hit_2.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_lead/ricochet
	examine_text = span_warning("Над головой висит красное перекрестие: пули рядом сворачивают в него. Не стреляйте рядом с меченым и уведите его от еретика.")
	var/datum/weakref/lead_ref
	var/mutable_appearance/crosshair
	var/applied = FALSE
	var/static/list/bend_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/datum/status_effect/eldritch/lead/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_lead/lead)
	lead_ref = WEAKREF(lead)
	var/lasts = hunt_duration(new_owner, lead)
	duration = lasts
	crosshair = mutable_appearance(HERETIC_LEAD_FX_ICON, "lead_crosshair", ABOVE_MOB_LAYER)
	crosshair.appearance_flags = RESET_COLOR | KEEP_APART
	. = ..()
	if(linked_alert)
		linked_alert.desc = "Над вами красное перекрестие: пули рядом сворачивают в вас, а удар клинком еретика Свинца собьёт с ног. Не стойте рядом со стрелками; метка погаснет через [lasts / (1 SECONDS)] секунд."

/datum/status_effect/eldritch/lead/on_apply()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!lead || !..())
		return FALSE
	applied = TRUE
	lead.marks += src
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))
	AddComponent(/datum/component/connect_range, owner, bend_connections, HERETIC_LEAD_MARK_BEND_RANGE, FALSE)
	return TRUE

/datum/status_effect/eldritch/lead/update_owner_underlay(atom/source, list/overlays)
	. = ..()
	overlays += crosshair

/// Пуля экипажа, залетевшая в 2 клетки от меченого, сворачивает в него.
/datum/status_effect/eldritch/lead/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/obj/item/projectile/projectile = arrived
	if(!istype(projectile) || !projectile.fired || HAS_TRAIT(projectile, TRAIT_HERETIC_LEAD_BENT) || !heretic_lead_ballistic(projectile) || owner.stat == DEAD)
		return
	var/mob/firer = projectile.firer
	if(firer == owner || (ismob(firer) && (IS_HERETIC(firer) || IS_HERETIC_MONSTER(firer))) || projectile.homing_target == owner)
		return
	ADD_TRAIT(projectile, TRAIT_HERETIC_LEAD_BENT, REF(src))
	projectile.setAngle(get_projectile_angle(projectile, owner))
	heretic_lead_home(projectile, owner, HERETIC_LEAD_MARK_TURN)
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(firer)
		log_combat(firer, owner, "стреляет пулей, согнутой Мишенью Свинца, в", projectile, "метку поставил [key_name(lead?.lead_body)]")
	else
		owner.log_message("получает пулю без стрелка, согнутую Мишенью Свинца: [key_name(projectile)], метку поставил [key_name(lead?.lead_body)]", LOG_ATTACK, color = "red")

/datum/status_effect/eldritch/lead/on_effect()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead?.can_use(lead.lead_body) && isturf(owner.loc) && heretic_can_affect(lead.lead_body, owner, chargecost = 0))
		owner.adjustBruteLoss(HERETIC_LEAD_MARK_DAMAGE)
		if(!QDELETED(owner))
			owner.Knockdown(HERETIC_LEAD_MARK_KNOCKDOWN)
			owner.visible_message(span_danger("Перекрестие над [owner] вспыхивает, и [owner] валится, как от выстрела в упор!"))
	return ..()

/datum/status_effect/eldritch/lead/on_remove()
	qdel(GetComponent(/datum/component/connect_range))
	if(applied)
		var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
		lead?.marks -= src
	lead_ref = null
	return ..()

/datum/status_effect/eldritch/lead/Destroy()
	crosshair = null
	return ..()

/obj/effect/temp_visual/heretic_lead
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_ricochet"
	duration = 0.35 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_lead/grasp
	icon_state = "lead_ricochet"

/obj/effect/temp_visual/heretic_lead/ricochet
	icon_state = "lead_ricochet"

/obj/effect/temp_visual/heretic_lead/fall
	icon_state = "lead_rain_impact"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_lead/muzzle
	icon_state = "lead_muzzle"
	duration = 0.7 SECONDS

/obj/effect/temp_visual/heretic_lead/catch
	icon_state = "lead_catch"
	duration = 0.75 SECONDS

/obj/effect/temp_visual/heretic_lead/smoke
	name = "powder smoke"
	icon_state = "lead_smoke"
	duration = HERETIC_LEAD_SMOKE_TIME
	layer = FLY_LAYER
	opacity = TRUE

/obj/effect/temp_visual/heretic_lead/rain_marker
	name = "lead rain"
	icon_state = "lead_rain_marker"
	duration = HERETIC_LEAD_RAIN_DELAY
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_lead/rain_impact
	icon_state = "lead_rain_impact"
	duration = 1 SECONDS

#undef HERETIC_LEAD_INK
#undef HERETIC_LEAD_GREY
#undef HERETIC_LEAD_START
#undef HERETIC_LEAD_HEX_COOLDOWN
#undef HERETIC_LEAD_NAMED_COOLDOWN
#undef HERETIC_LEAD_HEAVY_CHECK
#undef HERETIC_LEAD_HEAVY_SLOWDOWN
#undef HERETIC_LEAD_HEAVY_TINT
#undef HERETIC_LEAD_ASSIST_ANGLE
#undef HERETIC_LEAD_CATCH_COOLDOWN
#undef HERETIC_LEAD_RICOCHET_COOLDOWN
#undef HERETIC_LEAD_RAIN_COOLDOWN
#undef HERETIC_LEAD_RAIN_SLOWDOWN
#undef HERETIC_LEAD_EAR_LIMIT
#undef HERETIC_LEAD_EAR_REPEAT
#undef HERETIC_LEAD_EAR_PRUNE
#undef HERETIC_LEAD_EAR_RANGE
#undef HERETIC_LEAD_INNATE_STAMINA
#undef HERETIC_LEAD_INNATE_BANG_GUARD
#undef LEAD_KNOCKED_SHOWN
#undef HERETIC_LEAD_GRASP_SFX
#undef HERETIC_LEAD_HIT_SFX
#undef TRAIT_HERETIC_LEAD_BENT
