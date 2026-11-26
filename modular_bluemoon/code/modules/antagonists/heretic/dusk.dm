#define HERETIC_DUSK_INK "#e0b25a"
#define HERETIC_DUSK_PALE "#ece4cc"
#define HERETIC_DUSK_SHADE_INK "#2a2140"
/// Индиго долгой ночи: вспышка вознесения и дымка знамения, холодное золото даёт кольцо.
#define HERETIC_DUSK_NIGHT_INK "#4b3d9e"
#define HERETIC_DUSK_ROT_INK "#8fa64a"
#define HERETIC_DUSK_GRASP_SFX "heretic_dusk_grasp"
/// Тусклая мутация - тёмный непрозрачный тон, а не полупрозрачность: пиксель-арт не просвечивает.
#define HERETIC_DUSK_MUTATION_SHADE_COLOR "#6e6a80"
/// Всплеск перьев при смене облика: кадры dusk_burst_* идут 0.65 секунды.
#define HERETIC_DUSK_BURST_TIME (0.7 SECONDS)
/// Кадр мутации 64x64 ложится на тело 32x32 по центру.
#define HERETIC_DUSK_MUTATION_OFFSET -16
/// Отблески глаз Крыла во тьме: глаз тела в холодном бледном и пиксель под ним, с редким морганием.
#define HERETIC_DUSK_EYES_ICON 'modular_bluemoon/icons/mob/heretic_dusk_eyes.dmi'
#define HERETIC_DUSK_CHAPEL_NOTICE (6 SECONDS)

/// Подменённая освещённость клеток: юнит-тесты, где свет тестовой зоны недостоверен; в игре список пуст.
GLOBAL_LIST_EMPTY(heretic_dusk_light_overrides)
/// Часовню осквернил вознёсшийся Сумрака: до конца раунда она не святая земля.
GLOBAL_VAR_INIT(heretic_dusk_chapel_desecrated, FALSE)

GLOBAL_LIST_INIT(heretic_dusk_sounds, list(
	"stance_face" = list('modular_bluemoon/sound/heretic/dusk_stance_face.ogg'),
	"stance_wing" = list('modular_bluemoon/sound/heretic/dusk_stance_wing.ogg'),
	"hex" = list('modular_bluemoon/sound/heretic/dusk_hex.ogg'),
	"flicker" = list('modular_bluemoon/sound/heretic/dusk_flicker_1.ogg', 'modular_bluemoon/sound/heretic/dusk_flicker_2.ogg', 'modular_bluemoon/sound/heretic/dusk_flicker_3.ogg'),
	"lamp_out" = list('modular_bluemoon/sound/heretic/dusk_lamp_out_1.ogg', 'modular_bluemoon/sound/heretic/dusk_lamp_out_2.ogg'),
	"beam" = list('modular_bluemoon/sound/heretic/dusk_lamp_beam.ogg'),
	"shadow" = list('modular_bluemoon/sound/heretic/dusk_shadow_tear.ogg'),
	"grip" = list('modular_bluemoon/sound/heretic/dusk_grip.ogg'),
	"grip_break" = list('modular_bluemoon/sound/heretic/dusk_grip_break.ogg'),
	"wing_twitch" = list('modular_bluemoon/sound/heretic/dusk_wing_twitch_1.ogg', 'modular_bluemoon/sound/heretic/dusk_wing_twitch_2.ogg'),
	"mark" = list('modular_bluemoon/sound/heretic/dusk_mark.ogg'),
	"descent_charge" = list('modular_bluemoon/sound/heretic/dusk_descent_charge.ogg'),
	"descent_land" = list('modular_bluemoon/sound/heretic/dusk_descent_land.ogg'),
	"glare" = list('modular_bluemoon/sound/heretic/dusk_glare_1.ogg', 'modular_bluemoon/sound/heretic/dusk_glare_2.ogg'),
	"overload" = list('modular_bluemoon/sound/heretic/dusk_overload_1.ogg', 'modular_bluemoon/sound/heretic/dusk_overload_2.ogg'),
	"step" = list('modular_bluemoon/sound/heretic/dusk_step_1.ogg', 'modular_bluemoon/sound/heretic/dusk_step_2.ogg'),
	"wing_guard" = list('modular_bluemoon/sound/heretic/dusk_wing_guard_1.ogg', 'modular_bluemoon/sound/heretic/dusk_wing_guard_2.ogg'),
	"holy" = list('modular_bluemoon/sound/heretic/dusk_holy_burn_1.ogg', 'modular_bluemoon/sound/heretic/dusk_holy_burn_2.ogg'),
	"eclipse_warn" = list('modular_bluemoon/sound/heretic/dusk_eclipse_warn.ogg'),
	"eclipse" = list('modular_bluemoon/sound/heretic/dusk_eclipse.ogg'),
	"lantern" = list('modular_bluemoon/sound/heretic/dusk_lantern_break.ogg'),
	"eyes" = list('modular_bluemoon/sound/heretic/dusk_eyes.ogg'),
	"mutate" = list('modular_bluemoon/sound/heretic/dusk_mutate_1.ogg', 'modular_bluemoon/sound/heretic/dusk_mutate_2.ogg', 'modular_bluemoon/sound/heretic/dusk_mutate_3.ogg'),
	"sun_rise" = list('modular_bluemoon/sound/heretic/dusk_sun_rise.ogg'),
	"sun_crack" = list('modular_bluemoon/sound/heretic/dusk_sun_crack_1.ogg', 'modular_bluemoon/sound/heretic/dusk_sun_crack_2.ogg'),
	"sun_break" = list('modular_bluemoon/sound/heretic/dusk_sun_break.ogg'),
	"noon_charge" = list('modular_bluemoon/sound/heretic/dusk_noon_charge.ogg'),
	"noon" = list('modular_bluemoon/sound/heretic/dusk_noon.ogg'),
	"covenant_seraph" = list('modular_bluemoon/sound/heretic/dusk_covenant_seraph.ogg'),
	"covenant_fallen" = list('modular_bluemoon/sound/heretic/dusk_covenant_fallen.ogg'),
	"covenant_rot" = list('modular_bluemoon/sound/heretic/dusk_covenant_rot.ogg'),
	"light_burn" = list('modular_bluemoon/sound/heretic/dusk_light_burn.ogg'),
	"feather_fan" = list('modular_bluemoon/sound/heretic/dusk_feather_fan_1.ogg', 'modular_bluemoon/sound/heretic/dusk_feather_fan_2.ogg'),
	"halo_charge" = list('modular_bluemoon/sound/heretic/dusk_halo_charge.ogg'),
	"halo_flash" = list('modular_bluemoon/sound/heretic/dusk_halo_flash.ogg'),
	"slash_light" = list('modular_bluemoon/sound/heretic/dusk_slash_light.ogg'),
	"slash_shadow" = list('modular_bluemoon/sound/heretic/dusk_slash_shadow.ogg'),
	"tether" = list('modular_bluemoon/sound/heretic/dusk_tether.ogg'),
	"quill_return" = list('modular_bluemoon/sound/heretic/dusk_quill_return.ogg'),
	"drink" = list('modular_bluemoon/sound/heretic/dusk_drink.ogg'),
	"drag" = list('modular_bluemoon/sound/heretic/dusk_drag.ogg'),
	"drag_done" = list('modular_bluemoon/sound/heretic/dusk_drag_done.ogg'),
	"shade_servant" = list('modular_bluemoon/sound/heretic/dusk_shade_servant_1.ogg', 'modular_bluemoon/sound/heretic/dusk_shade_servant_2.ogg'),
	"shade_burst" = list('modular_bluemoon/sound/heretic/dusk_shade_servant_burst.ogg'),
	"rot_spread" = list('modular_bluemoon/sound/heretic/dusk_rot_spread_1.ogg', 'modular_bluemoon/sound/heretic/dusk_rot_spread_2.ogg'),
	"rot_lamp" = list('modular_bluemoon/sound/heretic/dusk_rot_lamp.ogg'),
	"rot_cleanse" = list('modular_bluemoon/sound/heretic/dusk_rot_cleanse.ogg'),
))

/// Играет звук события Сумрака из его набора и возвращает выбранный файл; события без набора молчат.
/proc/heretic_dusk_sound(atom/source, kind, volume, vary = FALSE, extrarange = 0)
	var/list/options = GLOB.heretic_dusk_sounds[kind]
	if(!length(options))
		return null
	. = pick(options)
	if(volume > 0 && source)
		playsound(source, ., volume, vary, extrarange)

/datum/sound_effect/heretic_dusk_grasp
	key = HERETIC_DUSK_GRASP_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/dusk_shadow_tear.ogg',
		'modular_bluemoon/sound/heretic/dusk_hex.ogg',
	)

/datum/sound_effect/heretic_dusk_hit
	key = HERETIC_DUSK_HIT_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/dusk_hit_1.ogg',
		'modular_bluemoon/sound/heretic/dusk_hit_2.ogg',
		'modular_bluemoon/sound/heretic/dusk_hit_3.ogg',
	)

/// Освещённость клетки от 0 до 1.
/proc/heretic_dusk_light(turf/place)
	if(!isturf(place))
		return 0
	if(length(GLOB.heretic_dusk_light_overrides))
		var/override = GLOB.heretic_dusk_light_overrides[place]
		if(!isnull(override))
			return override
	return place.get_lumcount()

/proc/heretic_dusk_lit(turf/place)
	return heretic_dusk_light(place) >= HERETIC_DUSK_LIT_LUM

/// Святая земля: часовня, пока её не осквернили.
/proc/heretic_dusk_holy_ground(atom/place)
	return !GLOB.heretic_dusk_chapel_desecrated && istype(get_area(place), /area/service/chapel)

/// Горящий переносной свет: фонарик, факел, лампа на каске.
/proc/heretic_dusk_light_item(obj/item/item)
	if(istype(item, /obj/item/flashlight))
		var/obj/item/flashlight/torch = item
		return torch.on
	return istype(item) && item.light_on && item.light_range > 0 && !istype(item, /obj/item/heretic_path_relic/dusk_lantern)

/// Горящие переносные огни в руках и на одежде человека.
/proc/heretic_dusk_carried_lights(mob/living/carbon/human/bearer)
	. = list()
	if(!istype(bearer))
		return
	for(var/obj/item/item in bearer.held_items)
		if(heretic_dusk_light_item(item))
			. += item
	for(var/obj/item/item in list(bearer.head, bearer.wear_suit, bearer.belt))
		if(heretic_dusk_light_item(item))
			. += item

/datum/heretic_path/dusk
	id = PATH_DUSK
	deed_type = /datum/heretic_deed/dusk
	innate_type = /datum/heretic_innate/dusk
	name = "Сумрак"
	tagline = "Падший ангел двух ликов: Лик слепит светом, Крыло хватает чужие тени, святое его жжёт."
	craft_summary = "Хватка в «Помощи» заговаривает лампу: она мигает при прохожих, бьёт лучом и принимает Шаг в тень."
	capture_summary = "Хватка тени в облике Крыла прибивает цель к полу: в тени на 10 секунд, на свету на 5; сердце уводит её вниз."
	escape_summary = "Шаг в тень в облике Крыла ставит за человека в 9 клетках, на дальнюю от вас сторону, или к лампе; 2 заряда."
	strength_points = list(
		"Лик копит Сумрак на свету и жжёт Пером, Крыло копит его в тени, видит во тьме и хватает тени.",
		"Смена облика во «Вреде» бьёт врагов перьями или нимбом, каждый третий удар Пером - разрез, Перо возвращается.",
		"Крылья закрывают Крыло спереди: удары и выстрелы в лицо слабее на 50%; Лик пьёт лазер в лицо.",
		"Заговорённая лампа мигает на прохожих и бьёт лучом в того, на кого смотрит Лик.",
		"На четвёртой ступени Завет: Нимб слепит и жжёт светом, Крыло бьёт из тени, Скверна заражает и гноит раны.",
		"Хватка тени прибивает цель к полу и на свету, а Крыло с Пером утягивает прибитую в тень и лечится.",
	)
	weakness_points = list(
		"Святое жжёт его: святая вода, нулевой жезл, Библия капеллана, часовня.",
		"Лик бьёт светом только перед собой: тёмные очки и сварочная маска держат взгляд и вспышку, стреляйте сбоку.",
		"Крыло прикрыто лишь спереди: бейте ему в спину, держитесь группой спиной к стене - Шагу некуда.",
		"Хватку рвут святая вода, жезл и Библия капеллана, растолкают за 2 секунды; добивание рвут свет и два удара.",
		"Крыло выдают глаза во тьме, свет в лицо гасит ему зрение; Нимбу мешают тёмные очки, Скверне - огонь.",
		"До вознесения оглушение глушит его заклинания; толчок сбивает серию Пера, пришитую тень рвёт свет.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_dusk,
		/datum/eldritch_knowledge/spell/dusk_step,
		/datum/eldritch_knowledge/spell/dusk_grip,
		/datum/eldritch_knowledge/spell/dusk_covenant,
		/datum/eldritch_knowledge/dusk_grasp,
		/datum/eldritch_knowledge/dusk_mark,
		/datum/eldritch_knowledge/spell/dusk_glare,
		/datum/eldritch_knowledge/dusk_relic,
		/datum/eldritch_knowledge/spell/dusk_eclipse,
		/datum/eldritch_knowledge/final_eldritch/dusk_final,
	)
	rune_inscription_icon = 'modular_bluemoon/icons/obj/ritual_inscriptions_extended.dmi'
	rune_cast_icon = 'modular_bluemoon/icons/obj/ritual_casts_extended.dmi'
	book_type = /obj/item/forbidden_book/dusk
	book_name = "Liber Crepusculi"
	book_title = "Часослов падшего света"
	book_subtitle = "Между днём и ночью стоит тот, кто не вернулся"
	book_desc = "Часослов в переплёте из потемневшего золота. Поля исписаны перьями, обгоревшими по краям, а позолота на буквах тлеет, когда страницу закрывает тень."
	book_cover = "dusk"
	book_ink = HERETIC_DUSK_INK
	book_rune = "sigil_dusk"
	rune_inscription = "dusk_seraph"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_dusk_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_dusk_page.ogg'
	vfx_particles = /particles/heretic_ascension/dusk
	vfx_accent = HERETIC_DUSK_PALE
	climax_ink = HERETIC_DUSK_NIGHT_INK
	wave_type = /obj/effect/temp_visual/heretic_dusk_wave
	emergence_filters = FALSE
	ascension_title = "Падший, что Стоит в Дверях"
	ascension_message = "Над станцией наступает долгая ночь. В дверях между днём и тьмой встал тот, кто когда-то нёс свет, и его перевёрнутый нимб смотрит на каждого."
	ascension_omen = "Свет ламп на миг становится слишком белым, а ваша тень отстаёт на шаг. Где-то наверху фальшиво поёт хор, и звук идёт задом наперёд."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_dusk.ogg'
	ascension_climax_sound = 'modular_bluemoon/sound/heretic/ascend_dusk_climax.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_dusk.dmi'
	ascension_aura_state = "dusk_aura"
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/dusk.dmi'
	sky_tint = "#1e1833"
	sky_dim = 140
	sky_particles = /particles/heretic_sky/dusk
	sky_texture_drift = 160 SECONDS
	sky_texture_angle = 0
	sky_loop = 'modular_bluemoon/sound/heretic/sky/dusk_loop.ogg'
	sky_event_sound = 'modular_bluemoon/sound/heretic/sky/dusk_event.ogg'
	combat_practice = "Смените облик кнопкой «Смена облика»: Лик копит Сумрак на освещённой клетке, Крыло - в тени, а первый удар Пером падшего сразу после смены облика - Удар из тени. Хваткой в намерении «Помощь» заговорите лампу полигона: в Лике «Луч лампы» бьёт ею мишень перед вами. Пусть напарник постреляет в вас спереди и сзади в облике Крыла: спереди урон слабее, а лазер в лицо Лику не ранит, а даёт Сумрак. Смените облик рядом с мишенью: Крыло мечет перья, Лик бьёт вспышкой нимба; каждый третий удар Пером по мишени - разрез, брошенное Перо вернётся в руку. Крыло видит в темноте, а луч фонаря напарника в лицо гасит это зрение на 5 секунд. В Крыле «Шаг в тень» ставит вас за мишень, на дальнюю от вас сторону, для нового Удара из тени. Изучив Хватку тени, прибейте мишень в тени к полу: «Помощь» её не стряхнёт, напарник растолкает за 2 секунды, а святая вода, нулевой жезл или Библия капеллана сорвут сразу; Перо в намерении «Схватить» утянет прибитую мишень в тень. На четвёртой ступени кнопка «Завет» выбирает Нимб, Крыло или Скверну; на полигоне путь можно подготовить заново и попробовать другой Завет. Пошагово главные приёмы ведёт кнопка «Урок Сумрака» среди упражнений полигона."

/obj/item/forbidden_book/dusk
	book_path = PATH_DUSK

/particles/heretic_ascension/dusk
	icon = HERETIC_DUSK_FX_ICON
	icon_state = list("dusk_p_feather" = 3, "dusk_p_ash" = 2, "dusk_p_mote" = 1)
	velocity = generator("circle", 2, 5)
	gravity = list(0, -0.12)
	friction = 0.1
	spin = generator("num", -25, 25)
	lifespan = 1.6 SECONDS

/particles/heretic_sky/dusk
	icon = HERETIC_DUSK_FX_ICON
	icon_state = list("dusk_p_feather" = 2, "dusk_p_mote" = 3)
	velocity = generator("circle", 0.05, 0.15)
	gravity = list(0, -0.01)

/datum/eldritch_knowledge/base_dusk
	name = "Между днём и ночью"
	summary = "Два облика: Лик копит Сумрак на свету, Крыло - в тени; Хватка в «Помощи» заговаривает лампу."
	details = list(
		"Нож и лампочка или трубка лампы дают Перо падшего. Брошенное, оно вернётся в руку; не долетело - жмите «Позвать Перо».",
		"«Смена облика» раз в 3 секунды. Лик на свету быстрее и жжёт Пером +4 ожога, Крыло быстрее в тени и видит во тьме.",
		"Смена облика во «Вреде» бьёт врагов рядом, в «Обезоружить» - лишь бивших вас: Крыло мечет 3 пера, Лик - нимб вплотную.",
		"Первый удар Пером в 2 секунды после смены облика или Шага - Удар из тени: 15 ушибов сверху и замедление.",
		"Каждый третий удар Пером по цели - разрез: Лик жжёт и подсвечивает её на 5 секунд, Крыло пришивает её тень.",
		"Крылья закрывают Крыло спереди: в лицо урон слабее на 50%, но свет в лицо гасит ему зрение во тьме на 5 секунд.",
		"Хватка в «Помощи» заговаривает до 6 ламп; «Луч лампы» в Лике бьёт ею на 12 ожогов, Лик в спину выжигает тень.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Я стоял в дверях, и свет падал на меня с обеих сторон. Одна сторона обжигала, другая - помнила."
	route = PATH_DUSK
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/light)
	result_atoms = list(/obj/item/melee/sickly_blade/dusk)
	combat_resource = HERETIC_DUSK_START
	combat_resource_max = HERETIC_DUSK_CAPACITY
	combat_resource_name = "Сумрак"
	resource_rules = list(
		"Начальный запас 3 из 6; смерть обнуляет Сумрак.",
		"Лик на освещённой клетке и Крыло в тени копят единицу раз в 3 секунды; не тот облик - не копит.",
		"Хватка по врагу, взрыв метки и лазер, выпитый Ликом, дают единицу; у Скверны носитель - раз в 10 секунд.",
		"Святая вода в крови и часовня не дают копить; выплеснутая святая вода гасит копление на 5 секунд.",
		"Пока святая вода в крови, каждый приём стоит на единицу дороже.",
		"Цена приёмов: Луч лампы, Лик ангела и Нисхождение - 1, Хватка тени - 2, Затмение - 3.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_dusk/form
	grasp_visual = /obj/effect/temp_visual/heretic_dusk/grasp
	grasp_sound = HERETIC_DUSK_GRASP_SFX
	grasp_catchphrase = "CRE'PUS LU'CIS"
	var/mob/living/dusk_body
	var/form = HERETIC_DUSK_FORM_FACE
	/// Своя клетка на свету по последней проверке.
	var/lit = TRUE
	var/in_holy_ground = FALSE
	var/holy_blood = FALSE
	var/holy_silence_until = 0
	var/form_locked_until = 0
	var/dusk_failure
	var/ascension_active = FALSE
	/// Стоит хоть одно Чёрное солнце вознесения.
	var/suns_standing = FALSE
	var/strike_until = 0
	var/list/datum/component/heretic_dusk_lamp/lamps = list()
	var/list/charges = list("step" = 0, "descent" = 0)
	var/list/charge_progress = list("step" = 0, "descent" = 0)
	var/list/datum/status_effect/heretic_dusk_grip/grips = list()
	var/list/datum/status_effect/heretic_dusk_shadow/shadows = list()
	var/list/datum/status_effect/heretic_dusk_burnt/burnt = list()
	var/list/datum/status_effect/eldritch/dusk/marks = list()
	var/list/atom/movable/screen/heretic_dusk_beacon/beacons = list()
	var/obj/effect/proc_holder/spell/pointed/heretic_dusk/beam/beam_power
	var/mutation_level = 0
	var/mutation_hidden = FALSE
	var/list/mutation_overlays = list()
	var/screen_mode
	var/lantern_sight = FALSE
	/// null, HERETIC_DUSK_SIGHT_WING или HERETIC_DUSK_SIGHT_FULL.
	var/night_sight
	var/sight_snuffed_until = 0
	var/list/eye_overlays = list()
	var/turf/eclipse_center
	var/eclipse_until = 0
	var/obj/effect/heretic_dusk_eclipse/eclipse_zone
	var/eclipse_timer
	/// Принесённый Завет (HERETIC_DUSK_COVENANT_*), до выбора null.
	var/covenant
	var/obj/structure/heretic_dusk_shade/servant
	var/list/datum/status_effect/heretic_dusk_rot/rot = list()
	var/step_jam_until = 0
	var/shade_blur = FALSE
	COOLDOWN_DECLARE(rot_feed)
	COOLDOWN_DECLARE(light_check)
	COOLDOWN_DECLARE(gather)
	COOLDOWN_DECLARE(holy_splash)
	COOLDOWN_DECLARE(bible_hit)
	COOLDOWN_DECLARE(free_step)
	COOLDOWN_DECLARE(chapel_notice)

/datum/eldritch_knowledge/base_dusk/on_body_gain(mob/living/user)
	if(!user?.mind || dusk_body == user)
		return
	if(dusk_body)
		on_body_lose(dusk_body)
	dusk_body = user
	mutation_hidden = FALSE
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_body_exposed))
	RegisterSignal(user, COMSIG_PARENT_ATTACKBY, PROC_REF(on_body_attackby))
	RegisterSignal(user, COMSIG_LIVING_RUN_BLOCK, PROC_REF(on_body_block))
	RegisterSignal(user, COMSIG_MOB_UPDATE_SIGHT, PROC_REF(on_update_sight))
	RegisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH, PROC_REF(on_bright_flash))
	combat_body_gain(user)
	grant_combat_power(user)
	update_form_button()
	if(QDELETED(beam_power))
		beam_power = new
		user.mind.AddSpell(beam_power)
	refresh_light()
	refresh_mutation()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	heretic?.refresh_evolution(TRUE)
	notify_resource_changed()

/datum/eldritch_knowledge/base_dusk/on_body_lose(mob/living/user)
	var/mob/living/body = dusk_body
	if(body)
		body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_face)
		body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_wing)
		set_form_screen(null)
		refresh_sight(FALSE)
		UnregisterSignal(body, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_EXPOSE_REAGENTS, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_RUN_BLOCK, COMSIG_MOB_UPDATE_SIGHT))
		set_shade_blur(FALSE)
		body.clear_alert(HERETIC_DUSK_ROT_ALERT)
		mutation_overlays.Cut()
		eye_overlays.Cut()
		qdel(locate(/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes) in body)
		body.update_icon()
	UnregisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH)
	combat_body_lose(body)
	sight_snuffed_until = 0
	dusk_body = null
	ascension_active = FALSE
	remove_combat_power()
	QDEL_NULL(beam_power)
	forget_stray_quill()
	clear_beacons()
	clear_dusk()

/datum/eldritch_knowledge/base_dusk/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(dusk_body)

/datum/eldritch_knowledge/base_dusk/on_death(mob/user)
	clear_dusk()
	combat_resource = 0
	mutation_hidden = TRUE
	set_form_screen(null)
	refresh_sight(FALSE)
	set_shade_blur(FALSE)
	clear_beacons()
	refresh_mutation()
	notify_resource_changed()

/datum/eldritch_knowledge/base_dusk/on_lose(mob/user)
	. = ..()
	clear_lamps()

/datum/eldritch_knowledge/base_dusk/Destroy()
	on_body_lose(dusk_body)
	clear_lamps()
	return ..()

/datum/eldritch_knowledge/base_dusk/proc/clear_lamps()
	var/list/datum/component/heretic_dusk_lamp/forgotten = lamps
	lamps = list()
	for(var/datum/component/heretic_dusk_lamp/lamp as anything in forgotten)
		qdel(lamp)

/datum/eldritch_knowledge/base_dusk/proc/clear_dusk()
	QDEL_LIST(grips)
	QDEL_LIST(shadows)
	QDEL_LIST(burnt)
	QDEL_LIST(marks)
	QDEL_LIST(rot)
	QDEL_NULL(servant)
	end_eclipse()
	strike_until = 0
	step_jam_until = 0
	grudges.Cut()

/datum/eldritch_knowledge/base_dusk/combat_resource_state()
	. = "Облик: [form == HERETIC_DUSK_FORM_FACE ? "Лик" : "Крыло"], клетка [lit ? "на свету" : "в тени"], Сумрак [can_gather() ? "копится" : "не копится"]. Ламп: [length(lamps)] из [HERETIC_DUSK_LAMP_LIMIT]."
	if(world.time < strike_until)
		. += " Удар из тени готов: бейте Пером."
	if(length(burnt))
		. += " Выжженных теней: [length(burnt)], к ним Шаг ведёт издалека, а Хватка держит полностью и на свету."
	if(form == HERETIC_DUSK_FORM_FACE && !COOLDOWN_FINISHED(src, light_drink))
		. += " Лик только что выпил лазер: следующий луч в лицо ранит."
	if(charge_cap("step"))
		. += " Шаг в тень: [charges["step"]] из [charge_cap("step")]."
	if(charge_cap("descent"))
		. += " Нисхождение: [charges["descent"]] из [charge_cap("descent")]."
	var/datum/heretic_dusk_covenant/chosen = covenant_datum()
	if(chosen)
		. += " [chosen.name]."
		if(covenant == HERETIC_DUSK_COVENANT_ROT)
			. += " Носителей скверны: [length(rot)] из [HERETIC_DUSK_ROT_CARRIERS]."
	else if(knows(/datum/eldritch_knowledge/spell/dusk_covenant))
		. += " Завет не выбран: нажмите кнопку «Завет»."
	. += suns_state()

/// Вознёсшегося держат сон, путы и стазис, а не оглушение.
/datum/eldritch_knowledge/base_dusk/proc/can_use(mob/living/user, ignore_grab = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(QDELETED(src) || !isliving(user) || user != dusk_body || !isturf(user.loc) || heretic?.selected_path != PATH_DUSK || heretic.role_removed || heretic.get_knowledge(type) != src)
		return FALSE
	return !heretic_incapacitated(user, ignore_grab)

/datum/eldritch_knowledge/base_dusk/proc/owner_heretic()
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	if(QDELETED(heretic) || heretic.role_removed || heretic.get_knowledge(type) != src)
		return null
	return heretic

/datum/eldritch_knowledge/base_dusk/proc/knows(knowledge_type)
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/known = heretic?.get_knowledge(knowledge_type)
	return !QDELETED(known)

/// Цена приёма: святая вода в крови делает каждый дороже на единицу.
/datum/eldritch_knowledge/base_dusk/proc/dusk_cost(amount)
	return amount + (holy_blood ? 1 : 0)

/datum/eldritch_knowledge/base_dusk/proc/cost_reason(amount)
	var/cost = dusk_cost(amount)
	if(combat_resource >= cost)
		return null
	return "Нужно [cost] Сумрака[holy_blood ? " (со святой водой в крови - на единицу больше)" : ""]; сейчас [combat_resource]."

/// Общий отказ приёмов пути: облик и святая земля для вознёсшегося.
/datum/eldritch_knowledge/base_dusk/proc/cast_block_reason(mob/living/user, required_form, ignore_grab = FALSE)
	if(!can_use(user, ignore_grab))
		return "Способность недоступна вашему пути или текущему телу."
	if(required_form && form != required_form)
		return required_form == HERETIC_DUSK_FORM_FACE ? "Нужен облик Лика: смените облик." : "Нужен облик Крыла: смените облик."
	if(ascension_active && heretic_dusk_holy_ground(user))
		return "Святая земля держит вашу силу: здесь работают только Перо и смена облика."
	return null

/// Своя клетка раз в 2 секунды: свет, святое, копление, заряды, облик и мутация.
/datum/eldritch_knowledge/base_dusk/on_life(mob/user)
	if(user != dusk_body || dusk_body.stat == DEAD || !COOLDOWN_FINISHED(src, light_check))
		return
	COOLDOWN_START(src, light_check, HERETIC_DUSK_LIGHT_CHECK)
	refresh_light()
	torch_in_face_check()
	gather_tick()
	tick_charges(HERETIC_DUSK_LIGHT_CHECK)
	covenant_tick()
	if(ascension_active && in_holy_ground)
		chapel_burn()
	show_beacons()

/datum/eldritch_knowledge/base_dusk/proc/refresh_light()
	if(!dusk_body)
		return
	var/turf/place = get_turf(dusk_body)
	var/was_lit = lit
	var/was_hidden = mutation_hidden
	lit = heretic_dusk_light(place) >= HERETIC_DUSK_LIT_LUM + (lit ? -HERETIC_DUSK_LIT_HYSTERESIS : HERETIC_DUSK_LIT_HYSTERESIS)
	in_holy_ground = heretic_dusk_holy_ground(place)
	holy_blood = !!dusk_body.reagents?.has_reagent(/datum/reagent/water/holywater)
	if(dusk_body.stat != DEAD)
		mutation_hidden = FALSE
	update_speed()
	update_form_screen()
	refresh_shade_blur()
	refresh_sight()
	var/level = mutation_level_now()
	if(level != mutation_level)
		var/rising = level > mutation_level && mutation_level
		mutation_level = level
		refresh_mutation()
		if(rising)
			heretic_dusk_screen_glitch(dusk_body)
			heretic_dusk_sound(dusk_body, "mutate", 40, TRUE, SILENCED_SOUND_EXTRARANGE)
	else if(was_lit != lit || was_hidden != mutation_hidden)
		refresh_mutation()
	var/gathering = can_gather()
	if(was_lit != lit || gathering != hud_gathering)
		hud_gathering = gathering
		notify_resource_changed()

/datum/eldritch_knowledge/base_dusk/proc/can_gather()
	if(!dusk_body || dusk_body.stat == DEAD || in_holy_ground || holy_blood || world.time < holy_silence_until)
		return FALSE
	if(holding_lantern())
		return TRUE
	return form == HERETIC_DUSK_FORM_FACE ? lit : !lit

/// Свет проверяется раз в 2 секунды; срок следующей единицы отсчитывается от прежнего срока, поэтому в среднем она приходит раз в 3 секунды.
/datum/eldritch_knowledge/base_dusk/proc/gather_tick(now = world.time)
	if(!can_gather() || now < gather)
		return FALSE
	gather = max(gather, now - HERETIC_DUSK_LIGHT_CHECK / 2) + HERETIC_DUSK_GATHER_TIME
	gain_combat_resource()
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/update_speed()
	if(!dusk_body)
		return
	if(form == HERETIC_DUSK_FORM_FACE && lit)
		dusk_body.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_face)
	else
		dusk_body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_face)
	if(form == HERETIC_DUSK_FORM_WING && !lit)
		dusk_body.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_wing)
	else
		dusk_body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_wing)

/datum/eldritch_knowledge/base_dusk/proc/update_form_screen()
	var/mode
	if(dusk_body?.stat != DEAD)
		if(form == HERETIC_DUSK_FORM_FACE && lit)
			mode = HERETIC_DUSK_FORM_FACE
		else if(form == HERETIC_DUSK_FORM_WING && !lit)
			mode = HERETIC_DUSK_FORM_WING
	set_form_screen(mode)

/// Экран еретика в родной стихии облика: Лик видит мир выбеленным, Крыло - выцветшим, с перьями по краям.
/datum/eldritch_knowledge/base_dusk/proc/set_form_screen(mode)
	if(screen_mode == mode || !dusk_body)
		screen_mode = mode
		return
	var/previous_colour = dusk_body.client?.color
	dusk_body.remove_client_colour(/datum/client_colour/heretic_dusk_face)
	dusk_body.remove_client_colour(/datum/client_colour/heretic_dusk_wing)
	dusk_body.clear_fullscreen("heretic_dusk_feathers", 1 SECONDS)
	dusk_body.clear_fullscreen("heretic_dusk_glare", 1 SECONDS)
	screen_mode = mode
	if(mode == HERETIC_DUSK_FORM_FACE)
		dusk_body.add_client_colour(/datum/client_colour/heretic_dusk_face)
		dusk_body.overlay_fullscreen("heretic_dusk_glare", /atom/movable/screen/fullscreen/scaled/heretic_dusk/glare)
	else if(mode == HERETIC_DUSK_FORM_WING)
		dusk_body.add_client_colour(/datum/client_colour/heretic_dusk_wing)
		dusk_body.overlay_fullscreen("heretic_dusk_feathers", /atom/movable/screen/fullscreen/scaled/heretic_dusk/feathers)
	heretic_dusk_fade_world(dusk_body.client, previous_colour)

/// Кнопка «Смена облика» показывает нынешний облик: нимб Лика или сомкнутые крылья Крыла.
/datum/eldritch_knowledge/base_dusk/proc/update_form_button()
	var/obj/effect/proc_holder/spell/self/heretic_dusk/form/power = combat_power
	if(!istype(power))
		return
	power.action_icon_state = form == HERETIC_DUSK_FORM_WING ? "dusk_cov_fallen" : "dusk_cov_seraph"
	if(power.action)
		power.action.button_icon_state = power.action_icon_state
		power.action.UpdateButtons()

/datum/eldritch_knowledge/base_dusk/proc/set_form(new_form, forced = FALSE)
	if(form == new_form || !dusk_body)
		return FALSE
	form = new_form
	if(!forced)
		strike_until = world.time + HERETIC_DUSK_STRIKE_WINDOW
	update_speed()
	update_form_screen()
	refresh_shade_blur()
	refresh_sight()
	refresh_mutation()
	update_form_button()
	dusk_body.update_action_buttons_icon()
	if(!forced || COOLDOWN_FINISHED(src, forced_glitch))
		COOLDOWN_START(src, forced_glitch, HERETIC_DUSK_FORCED_GLITCH_GAP)
		heretic_dusk_screen_glitch(dusk_body, forced)
	heretic_dusk_sound(dusk_body, form == HERETIC_DUSK_FORM_FACE ? "stance_face" : "stance_wing", 50, TRUE, forced ? 0 : SILENCED_SOUND_EXTRARANGE)
	new /obj/effect/temp_visual/heretic_dusk/stance_switch(get_turf(dusk_body))
	new /obj/effect/temp_visual/heretic_dusk_burst(get_turf(dusk_body), mutation_icon(), form == HERETIC_DUSK_FORM_FACE ? "dusk_burst_face" : "dusk_burst_wing")
	if(form == HERETIC_DUSK_FORM_FACE)
		dusk_body.visible_message(span_warning("Над [dusk_body] рывком разгорается больной белый нимб, тень за спиной складывается, по телу бегут трещины света."), span_notice("Вы обращаете к миру Лик: свет ваш, но бьёт он только перед вами."))
	else
		dusk_body.visible_message(span_warning("Нимб над [dusk_body] гаснет, и над плечами с треском раскрываются крылья из тени, роняя перья."), span_notice("Вы раскрываете Крыло: тени людей ваши, спереди вас закрывают перья."))
	notify_resource_changed()
	lesson_event("form", dusk_body, form)
	if(!forced)
		INVOKE_ASYNC(src, PROC_REF(form_strike), dusk_body)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/toggle_form(mob/living/user)
	dusk_failure = null
	if(!can_use(user, TRUE))
		dusk_failure = "Способность недоступна вашему пути или текущему телу."
		return FALSE
	if(world.time < form_locked_until)
		dusk_failure = "Святое сбило ваш облик: сменить его можно через [heretic_capture_seconds_left(form_locked_until)] с."
		return FALSE
	return set_form(form == HERETIC_DUSK_FORM_FACE ? HERETIC_DUSK_FORM_WING : HERETIC_DUSK_FORM_FACE)

/datum/eldritch_knowledge/base_dusk/proc/charge_cap(key)
	. = 0
	switch(key)
		if("step")
			if(knows(/datum/eldritch_knowledge/spell/dusk_step))
				. = covenant == HERETIC_DUSK_COVENANT_FALLEN ? HERETIC_DUSK_FALLEN_STEP_CHARGES : HERETIC_DUSK_STEP_CHARGES
		if("descent")
			. = knows(/datum/eldritch_knowledge/spell/dusk_covenant) ? 1 : 0
	if(. && ascension_active)
		.++

/datum/eldritch_knowledge/base_dusk/proc/charge_time(key)
	return key == "step" ? HERETIC_DUSK_STEP_RECHARGE : HERETIC_DUSK_DESCENT_RECHARGE

/datum/eldritch_knowledge/base_dusk/proc/fill_charges(key)
	charges[key] = max(charges[key], charge_cap(key))
	charge_progress[key] = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_dusk/proc/tick_charges(elapsed)
	for(var/key in charges)
		var/cap = charge_cap(key)
		if(charges[key] >= cap)
			charges[key] = cap
			charge_progress[key] = 0
			continue
		if(key == "step" && (holy_blood || in_holy_ground))
			continue
		charge_progress[key] += elapsed
		if(charge_progress[key] >= charge_time(key))
			charge_progress[key] = 0
			charges[key]++
			notify_resource_changed()

/datum/eldritch_knowledge/base_dusk/proc/charge_wait(key)
	return max(1, CEILING((charge_time(key) - charge_progress[key]) / (1 SECONDS), 1))

/datum/eldritch_knowledge/base_dusk/proc/use_charge(key)
	if(charges[key] < 1)
		return FALSE
	charges[key]--
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/refund_charge(key)
	charges[key] = min(charge_cap(key), charges[key] + 1)
	notify_resource_changed()

/datum/eldritch_knowledge/base_dusk/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !can_use(user))
		return FALSE
	if(isliving(target))
		if(!heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
			return FALSE
		gain_combat_resource()
		if(covenant == HERETIC_DUSK_COVENANT_ROT)
			infect_rot(target)
		return TRUE
	if(!istype(target, /obj/machinery/light))
		return FALSE
	if(user.a_intent != INTENT_HELP)
		grasp_failure_reason = "Лампу заговаривают Хваткой в намерении «Помощь»."
		return FALSE
	return hex_lamp(user, target)

/datum/eldritch_knowledge/base_dusk/proc/hex_lamp(mob/living/user, obj/machinery/light/lamp)
	if(lamp.status != LIGHT_OK)
		grasp_failure_reason = "Лампа разбита или пуста: заговорить можно только целую."
		return FALSE
	if(lamp.GetComponent(/datum/component/heretic_dusk_lamp))
		grasp_failure_reason = "Эта лампа уже помнит вас."
		return FALSE
	while(length(lamps) >= HERETIC_DUSK_LAMP_LIMIT)
		var/datum/component/heretic_dusk_lamp/oldest = lamps[1]
		var/atom/oldest_lamp = oldest.parent
		lamps -= oldest
		to_chat(user, span_warning("Старейшая заговорённая лампа забывает вас - [get_area_name(oldest_lamp, TRUE)]: помнят не больше [HERETIC_DUSK_LAMP_LIMIT]."))
		log_game("[key_name(user)] теряет заговор Сумрака на лампе в [AREACOORD(oldest_lamp)]: его вытеснил новый.")
		qdel(oldest)
	var/datum/component/heretic_dusk_lamp/hex = lamp.AddComponent(/datum/component/heretic_dusk_lamp, src)
	if(QDELETED(hex))
		return FALSE
	heretic_craft_placed_fx(lamp, src)
	heretic_dusk_sound(lamp, "hex", 30, TRUE, SILENCED_SOUND_EXTRARANGE)
	if(covenant == HERETIC_DUSK_COVENANT_ROT)
		hex.set_rot(TRUE)
	var/turf/place = get_turf(lamp)
	var/wait = place && is_station_level(place.z) ? "" : " Мигание вне станции дело пути не продвинет."
	var/rotten = hex.rot_stage ? " Скверна гноит её свет: комната вокруг будет тускнеть." : ""
	to_chat(user, span_eldritch("Свет лампы на миг становится слишком белым, по плафону ползёт копоть в форме пера: лампа помнит вас. Ламп: [length(lamps)] из [HERETIC_DUSK_LAMP_LIMIT].[rotten][wait]"))
	log_game("[key_name(user)] заговаривает лампу Сумраком в [AREACOORD(lamp)].")
	notify_resource_changed()
	lesson_event("lamp", lamp)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/on_lamp_removed(datum/component/heretic_dusk_lamp/hex)
	if(!(hex in lamps))
		return
	lamps -= hex
	var/area/place = get_area(hex.parent)
	if(dusk_body && dusk_body.stat != DEAD)
		to_chat(dusk_body, span_warning("Заговорённая лампа забыла вас - [place ? place.name : "лампы больше нет"]. Ламп: [length(lamps)] из [HERETIC_DUSK_LAMP_LIMIT]."))
	notify_resource_changed()

/// Лампа мигнула на прохожем: экипаж в новом отделе продвигает дело; еретику - о зачёте всегда, об остальном раз в минуту на лампу.
/datum/eldritch_knowledge/base_dusk/proc/on_lamp_flicker(obj/machinery/light/lamp, mob/living/passerby)
	var/turf/place = get_turf(lamp)
	var/datum/antagonist/heretic/heretic = owner_heretic()
	if(!heretic)
		return FALSE
	lesson_event("lamp_flicker", passerby)
	var/credited = FALSE
	var/mob/living/heretic_body = heretic.owner?.current
	if(heretic_body && heretic_body.stat != DEAD && ishuman(passerby) && passerby.mind && !IS_HERETIC(passerby) && !IS_HERETIC_MONSTER(passerby) && place && is_station_level(place.z))
		var/deed_key = heretic.deed_key_for(place)
		if(!heretic.deed_wait_reason(deed_key))
			credited = heretic.advance_deed(deed_key, place, silent = TRUE)
	var/datum/component/heretic_dusk_lamp/hex = lamp.GetComponent(/datum/component/heretic_dusk_lamp)
	if(!dusk_body || dusk_body.stat == DEAD || (!credited && hex && !COOLDOWN_FINISHED(hex, owner_notice)))
		return FALSE
	if(hex)
		COOLDOWN_START(hex, owner_notice, HERETIC_DUSK_LAMP_NOTICE_GAP)
	to_chat(dusk_body, span_notice("Заговорённая лампа мигнула: мимо прошёл [passerby.name] - [get_area_name(place, TRUE)].[credited ? " Отдел засчитан в дело." : ""]"))
	return TRUE

/datum/component/heretic_dusk_lamp
	COOLDOWN_DECLARE(owner_notice)

/datum/eldritch_knowledge/base_dusk/proc/lamps_on_z(z_level)
	. = list()
	for(var/datum/component/heretic_dusk_lamp/hex as anything in lamps)
		var/atom/lamp = hex.parent
		if(lamp?.z == z_level)
			. += lamp

/datum/eldritch_knowledge/base_dusk/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	if(!can_use(user) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return
	if(strike_until && world.time <= strike_until)
		strike_until = 0
		var/fallen = covenant == HERETIC_DUSK_COVENANT_FALLEN
		target.adjustBruteLoss(HERETIC_DUSK_STRIKE_DAMAGE + (fallen ? HERETIC_DUSK_FALLEN_STRIKE_BONUS : 0))
		if(QDELETED(target))
			return
		target.apply_status_effect(/datum/status_effect/heretic_dusk_slowed)
		if(fallen)
			strike_bleed(user, target)
		target.visible_message(span_danger("Из тени за спиной [target] вырывается крыло, и удар Пера сбивает [target] с шага!"), span_userdanger("Удар из тени! Ноги не слушаются."))
		log_combat(user, target, "бьёт Ударом из тени Сумрака")
		lesson_event("strike", target)
	if(form == HERETIC_DUSK_FORM_FACE && lit && !QDELETED(target))
		target.adjustFireLoss(HERETIC_DUSK_FACE_BURN)
	if(covenant == HERETIC_DUSK_COVENANT_ROT && !QDELETED(target) && target.has_status_effect(/datum/status_effect/heretic_dusk_rot) && heretic_dusk_rot_wound(target, HERETIC_DUSK_ROT_QUILL_TOX))
		to_chat(target, span_warning("Гниль въедается в рану от Пера!"))
	if(QDELETED(target))
		return
	if(form == HERETIC_DUSK_FORM_FACE && (get_dir(user, target) & target.dir))
		target.apply_status_effect(/datum/status_effect/heretic_dusk_burnt, src)
		lesson_event("burnt", target)
	if(!QDELETED(target))
		combo_hit(user, target)

/datum/eldritch_knowledge/base_dusk/proc/shadowed_by_me(mob/living/victim)
	for(var/datum/status_effect/heretic_dusk_shadow/shadow as anything in shadows)
		if(shadow.owner == victim)
			return TRUE
	for(var/datum/status_effect/heretic_dusk_burnt/scorch as anything in burnt)
		if(scorch.owner == victim)
			return TRUE
	for(var/datum/status_effect/heretic_dusk_rot/spot as anything in rot)
		if(spot.owner == victim)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_dusk/proc/in_eclipse(atom/place)
	var/turf/spot = get_turf(place)
	return spot && eclipse_center && world.time < eclipse_until && spot.z == eclipse_center.z && get_dist(spot, eclipse_center) <= HERETIC_DUSK_ECLIPSE_RADIUS

/// Вознёсшийся при стоящем Чёрном солнце лечится от каждой отнятой у экипажа тени.
/datum/eldritch_knowledge/base_dusk/proc/feed_on_shadow()
	if(ascension_active && suns_standing && dusk_body && dusk_body.stat != DEAD)
		heretic_heal_pool(dusk_body, HERETIC_DUSK_SHADOW_HEAL)

/datum/eldritch_knowledge/base_dusk/pocket_exits(mob/living/user)
	. = list()
	for(var/datum/component/heretic_dusk_lamp/hex as anything in lamps)
		var/atom/lamp = hex.parent
		if(lamp)
			heretic_add_pocket_exit(., "Тень лампы - [get_area_name(lamp, TRUE)]", heretic_pocket_landing(get_turf(lamp)))

/datum/eldritch_knowledge/base_dusk/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в тень", "text" = "Тень [victim] тянет хозяина за собой сквозь пол.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель прибита своей Хваткой тени, еретик рядом.
/datum/eldritch_knowledge/base_dusk/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	var/datum/status_effect/heretic_dusk_grip/grip = victim.has_status_effect(/datum/status_effect/heretic_dusk_grip)
	return grip?.dusk_ref?.resolve() == src

/// Сила святого: в осквернённой часовне нулевой жезл и Библия работают как обычно.
/datum/eldritch_knowledge/base_dusk/proc/holy_power_here()
	return !(GLOB.heretic_dusk_chapel_desecrated && istype(get_area(dusk_body), /area/service/chapel))

/datum/eldritch_knowledge/base_dusk/proc/on_body_exposed(atom/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message)
	SIGNAL_HANDLER
	if(method != TOUCH && method != VAPOR)
		return
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water/holywater))
			holy_splash(reagent.volume * volume_modifier)
			return

/// Ожог от выплеснутой святой воды растёт с объёмом: брызги жгут слабо, ведро - в полную силу.
/proc/heretic_dusk_holy_burn(volume)
	return clamp(volume * HERETIC_DUSK_HOLY_BURN_PER_UNIT, HERETIC_DUSK_HOLY_SPLASH_MIN_BURN, HERETIC_DUSK_HOLY_SPLASH_BURN)

/// Выплеснутая святая вода: ожог по объёму, сбой облика с долгой перезарядкой, Сумрак не копится, хватки рвутся; запертый облик снова не сбивается.
/datum/eldritch_knowledge/base_dusk/proc/holy_splash(volume = INFINITY)
	if(!dusk_body || dusk_body.stat == DEAD || !holy_power_here() || !COOLDOWN_FINISHED(src, holy_splash))
		return FALSE
	COOLDOWN_START(src, holy_splash, HERETIC_DUSK_HOLY_SPLASH_GAP)
	var/burn = heretic_dusk_holy_burn(volume)
	dusk_body.adjustFireLoss(burn)
	if(QDELETED(dusk_body))
		return TRUE
	holy_silence_until = world.time + HERETIC_DUSK_HOLY_SILENCE
	var/broke_form = world.time >= form_locked_until
	if(broke_form)
		break_drag("святая вода сбила ваш облик.")
		set_form(form == HERETIC_DUSK_FORM_FACE ? HERETIC_DUSK_FORM_WING : HERETIC_DUSK_FORM_FACE, TRUE)
		form_locked_until = world.time + HERETIC_DUSK_HOLY_FORM_LOCK
	heretic_dusk_sound(dusk_body, "holy", 50, TRUE)
	new /obj/effect/temp_visual/heretic_dusk/holy_burn(get_turf(dusk_body))
	dusk_body.visible_message(span_danger("Святая вода шипит на [dusk_body]: трещины на коже дымят[broke_form ? ", облик ломается рывком" : ""]!"), span_userdanger("Святая вода жжёт! [broke_form ? "Облик сорвался" : "Облик ещё сбит"], Сумрак не держится."))
	for(var/datum/status_effect/heretic_dusk_grip/grip as anything in grips.Copy())
		grip.release("Святая вода на хозяине тени разжимает Хватку.")
	SEND_SIGNAL(src, COMSIG_HERETIC_DUSK_HOLY, "splash")
	log_game("[key_name(dusk_body)]: святая вода ([round(burn, 0.1)] ожогов) [broke_form ? "сбивает облик Сумрака" : "жжёт Сумрака"] в [AREACOORD(dusk_body)].")
	lesson_event("holy", dusk_body, burn)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/on_body_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!isliving(user) || user == source || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	if(heretic_dusk_light_item(item))
		light_in_face(user)
		return NONE
	if(!holy_power_here())
		return NONE
	if(istype(item, /obj/item/nullrod))
		if(use_charge("step"))
			to_chat(source, span_warning("Освящённое железо сбивает тень с ваших крыльев: заряд Шага в тень потерян."))
		return NONE
	if(istype(item, /obj/item/storage/book/bible) && user.mind?.isholy && COOLDOWN_FINISHED(src, bible_hit))
		COOLDOWN_START(src, bible_hit, HERETIC_DUSK_BIBLE_COOLDOWN)
		source.adjustFireLoss(HERETIC_DUSK_BIBLE_BURN)
		if(QDELETED(source))
			return NONE
		source.Stun(HERETIC_DUSK_BIBLE_STUN)
		heretic_dusk_sound(source, "holy", 50, TRUE)
		new /obj/effect/temp_visual/heretic_dusk/holy_burn(get_turf(source))
		user.do_attack_animation(source)
		source.visible_message(span_danger("[user] опускает Библию на [source], и падший свет на коже шипит и гаснет!"), span_userdanger("Слово капеллана обжигает вас!"))
		log_combat(user, source, "жжёт Библией еретика Сумрака")
		return COMPONENT_NO_AFTERATTACK
	return NONE

/// Крылья закрывают Крыло спереди; нулевой жезл бьёт падшего сильнее.
/datum/eldritch_knowledge/base_dusk/proc/on_body_block(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(real_attack)
		note_attacker(attacker)
		drag_hit(attacker, damage, attack_type)
	if(!real_attack || !return_list || return_list[HERETIC_BLOCK_ABSORBED] || damage <= 0 || source.stat == DEAD)
		return BLOCK_NONE
	if(drink_light(source, object, attacker, attack_type, return_list))
		return BLOCK_SUCCESS
	var/factor = 1
	var/holy = istype(object, /obj/item/nullrod) && (attack_type & ATTACK_TYPE_MELEE) && holy_power_here()
	if(holy)
		factor *= 1 + HERETIC_DUSK_NULLROD_BONUS / 100
	if(form == HERETIC_DUSK_FORM_WING && (attack_type & (ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN)) && attack_from_front(object, attacker))
		factor *= 1 - HERETIC_DUSK_WING_FRONT_CUT / 100
		heretic_dusk_sound(source, "wing_guard", 50, TRUE)
		var/obj/effect/temp_visual/heretic_dusk/wing_guard/guard = new(get_turf(source))
		guard.setDir(source.dir)
		lesson_event("wing_block", attacker, damage)
	else if(form == HERETIC_DUSK_FORM_WING)
		lesson_event("wing_open", attacker, damage)
	if(factor == 1)
		return BLOCK_NONE
	var/final_damage = block_calculate_resultant_damage(damage, return_list) * factor
	return_list[BLOCK_RETURN_SET_DAMAGE_TO] = final_damage
	return_list[BLOCK_RETURN_MITIGATION_PERCENT] = max(0, 100 * (1 - final_damage / damage))
	return BLOCK_SHOULD_CHANGE_DAMAGE

/// Удар или снаряд пришёл с той стороны, куда смотрит еретик.
/datum/eldritch_knowledge/base_dusk/proc/attack_from_front(atom/object, mob/living/attacker)
	var/atom/origin = attacker
	if(istype(object, /obj/item/projectile))
		var/obj/item/projectile/projectile = object
		origin = projectile.starting || projectile.firer
	var/turf/from = get_turf(origin || object)
	if(!from || from == get_turf(dusk_body))
		return FALSE
	return is_A_facing_B(dusk_body, from)

/// Вознёсшегося святая земля жжёт, пока он в ней стоит.
/datum/eldritch_knowledge/base_dusk/proc/chapel_burn()
	dusk_body.adjustFireLoss(HERETIC_DUSK_CHAPEL_BURN)
	if(QDELETED(dusk_body))
		return
	new /obj/effect/temp_visual/heretic_dusk/holy_burn(get_turf(dusk_body))
	if(COOLDOWN_FINISHED(src, chapel_notice))
		COOLDOWN_START(src, chapel_notice, HERETIC_DUSK_CHAPEL_NOTICE)
		heretic_dusk_sound(dusk_body, "holy", 50, TRUE)
		dusk_body.visible_message(span_warning("Мутация [dusk_body] шипит и дымится: святая земля жжёт падшего."), span_userdanger("Святая земля жжёт вас! Здесь работают только Перо и смена облика."))

/datum/eldritch_knowledge/base_dusk/proc/mutation_level_now()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	if(!heretic)
		return 0
	if(ascension_active)
		return 4
	return max(1, heretic.evolution_stage_tier(PATH_DUSK))

/// Мутация по ступени: трещины, культи крыльев, треснувший нимб; у вознёсшегося - полные крылья и перевёрнутый нимб.
/// В Крыле его поднятые крылья заменяют культи и крылья вознесения: пара крыльев на теле всегда одна.
/datum/eldritch_knowledge/base_dusk/proc/mutation_states()
	. = list()
	var/level = mutation_level
	if(!level)
		return
	var/face = form == HERETIC_DUSK_FORM_FACE
	. += "dusk_mut_cracks_body"
	. += "dusk_mut_cracks"
	if(level >= 4)
		if(face)
			. += "dusk_mut_wings_full"
		. += "dusk_mut_halo_inverted"
	else
		if(level >= 2 && face)
			. += "dusk_mut_wing_stumps"
		if(level >= 3)
			. += "dusk_mut_halo_cracked"
	. += face ? "dusk_stance_face" : "dusk_stance_wing"

/// Слой мутации на теле: трещины тела под одеждой, крылья за телом, остальное поверх; облик ложится последним.
/datum/eldritch_knowledge/base_dusk/proc/mutation_layer(state)
	if(state == "dusk_mut_cracks_body")
		return -BODY_ADJ_LAYER
	if(findtext(state, "dusk_mut_wing") || state == "dusk_stance_wing")
		return -BODY_BEHIND_LAYER
	return -BODY_FRONT_LAYER

/// Тело видно в обоих обликах; облик меняет силуэт и свечение: у Лика ярче нимб и трещины, у Крыла нимб тусклый. В тени всё темнеет, кроме облика вознёсшегося.
/datum/eldritch_knowledge/base_dusk/proc/mutation_overlay(state, layer, dim)
	var/mutable_appearance/look = mutable_appearance(mutation_icon(), state, layer)
	if(dim)
		look.color = HERETIC_DUSK_MUTATION_SHADE_COLOR
	look.pixel_x = HERETIC_DUSK_MUTATION_OFFSET
	look.pixel_y = HERETIC_DUSK_MUTATION_OFFSET
	look.appearance_flags = RESET_COLOR
	return look

/datum/eldritch_knowledge/base_dusk/proc/mutation_glow(state, layer)
	var/mutable_appearance/glow = emissive_appearance(mutation_icon(), state, layer, offset_spokesman = dusk_body)
	glow.pixel_x = HERETIC_DUSK_MUTATION_OFFSET
	glow.pixel_y = HERETIC_DUSK_MUTATION_OFFSET
	return glow

/datum/eldritch_knowledge/base_dusk/proc/refresh_mutation()
	mutation_overlays = list()
	if(!dusk_body)
		return
	if(!mutation_hidden)
		mutation_level = mutation_level || mutation_level_now()
		var/face = form == HERETIC_DUSK_FORM_FACE
		var/shown_lit = mutation_lit()
		for(var/state in mutation_states())
			var/layer = mutation_layer(state)
			var/halo = findtext(state, "halo")
			var/dim = !shown_lit || (halo && !face)
			mutation_overlays += mutation_overlay(state, layer, dim)
			if(layer == -BODY_BEHIND_LAYER)
				mutation_overlays += mutation_overlay("[state]_front", -BODY_FRONT_LAYER, dim)
			if(shown_lit && face && (halo || state == "dusk_mut_cracks" || state == "dusk_stance_face"))
				mutation_overlays += mutation_glow(state, layer)
			// Крылья вознёсшегося не тонут в его ночи: светится контровой свет по кромке перьев.
			if(ascension_active && (state == "dusk_mut_wings_full" || state == "dusk_stance_wing"))
				mutation_overlays += mutation_glow("[state]_rim", layer)
				if(layer == -BODY_BEHIND_LAYER)
					mutation_overlays += mutation_glow("[state]_front_rim", -BODY_FRONT_LAYER)
	refresh_eyes()
	dusk_body.update_icon()

/// Облик вознёсшегося не тонет в его же ночи: крылья, нимб и трещины видны, как на свету.
/datum/eldritch_knowledge/base_dusk/proc/mutation_lit()
	return lit || ascension_active

/datum/eldritch_knowledge/base_dusk/proc/mutation_examine(list/examine_list)
	if(!dusk_body || mutation_hidden || !mutation_level)
		return
	examine_list += span_warning((mutation_lit() ? "По коже бегут светлые трещины, из них сочится больной белый свет: на свету мутация видна, а святое её жжёт." : "В полумраке по коже ползут тёмные трещины, а сам он будто тонет в тени: в темноте его почти не видно."))
	if(mutation_level >= 4)
		examine_list += span_warning("За спиной раскрыты огромные крылья из тени и обгоревших перьев, над головой висит расколотый перевёрнутый нимб.")
	else
		if(mutation_level >= 2)
			examine_list += span_warning("Из лопаток торчат культи крыльев: голые кости в обгоревших перьях.")
		if(mutation_level >= 3)
			examine_list += span_warning("Над головой дрожит треснувший нимб, из трещин сочится свет.")
	var/datum/heretic_dusk_covenant/chosen = covenant_datum()
	if(chosen)
		examine_list += span_warning(chosen.examine_line)
	if(form == HERETIC_DUSK_FORM_FACE)
		examine_list += span_warning("Нимб пылает, глаза светятся белым - не смотрите ему в лицо: наденьте тёмные очки или сварочную маску и заходите сбоку, лазер в лицо он пьёт.")
	else
		examine_list += span_warning("Крылья раскрыты и закрывают его спереди - бейте и стреляйте в спину, а от пришитой тени уходите на свет; святая вода и нулевой жезл жгут его в любом облике.")
		if(length(eye_overlays))
			examine_list += span_warning("Во тьме горят два бледных отблеска его глаз: он видит в темноте, но луч фонаря в лицо или вспышка ненадолго гасят это зрение.")

/// Всплеск перьев при смене облика: кольцо рывка у груди и перья в цвете Завета, к концу осыпаются.
/obj/effect/temp_visual/heretic_dusk_burst
	icon = HERETIC_DUSK_MUTATION_ICON
	icon_state = "dusk_burst_face"
	duration = HERETIC_DUSK_BURST_TIME
	pixel_x = HERETIC_DUSK_MUTATION_OFFSET
	pixel_y = HERETIC_DUSK_MUTATION_OFFSET
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_dusk_burst/Initialize(mapload, sheet, state)
	if(sheet)
		icon = sheet
	if(state)
		icon_state = state
	return ..()

/// Сумрак не прячется: мутация видна с первой ступени и поверх одежды, свет, тень и облик решает базовое знание.
/datum/heretic_path/dusk
	evolution_thresholds = list(1, HERETIC_EVOLUTION_FIRST_STAGE, HERETIC_EVOLUTION_SECOND_STAGE)

/datum/heretic_path/dusk/proc/dusk_of(datum/heretic_evolution/evolution)
	var/datum/eldritch_knowledge/base_dusk/dusk = evolution.heretic.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	return dusk?.dusk_body == evolution.body ? dusk : null

/// Одежда сменилась: отблески глаз пересчитываются с учётом снимаемой вещи.
/datum/heretic_path/dusk/evolution_build_overlays(datum/heretic_evolution/evolution, obj/item/gone)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(evolution)
	dusk?.refresh_eyes(gone)
	return list()

/datum/heretic_path/dusk/evolution_build_burst(datum/heretic_evolution/evolution)
	return list()

/datum/heretic_path/dusk/evolution_live_overlays(datum/heretic_evolution/evolution)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(evolution)
	return dusk ? dusk.mutation_overlays + dusk.eye_overlays : null

/datum/heretic_path/dusk/evolution_examine_lines(datum/heretic_evolution/evolution, mob/examiner, list/examine_list)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(evolution)
	dusk?.mutation_examine(examine_list)

/datum/eldritch_knowledge/base_dusk/proc/holding_lantern()
	if(!dusk_body)
		return FALSE
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/dusk_relic/relic_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/dusk_relic)
	var/obj/item/lantern = relic_knowledge?.new_path_relic_ref?.resolve()
	return lantern && dusk_body.is_holding(lantern)

/// Тёмное зрение: Фонарь в руке и вознесение видят тьму как день, Крыло - холодными сумерками, Лик - как человек.
/// Свет в лицо гасит своё зрение Сумрака, но не зрение Фонаря.
/datum/eldritch_knowledge/base_dusk/proc/refresh_sight(allowed = TRUE)
	var/alive = allowed && dusk_body && dusk_body.stat != DEAD
	var/holding = alive && holding_lantern()
	var/own = alive && world.time >= sight_snuffed_until
	var/level
	if(holding || (own && ascension_active))
		level = HERETIC_DUSK_SIGHT_FULL
	else if(own && form == HERETIC_DUSK_FORM_WING)
		level = HERETIC_DUSK_SIGHT_WING
	lantern_sight = holding
	if(level == night_sight)
		return
	night_sight = level
	if(!dusk_body)
		return
	if(level == HERETIC_DUSK_SIGHT_FULL)
		ADD_TRAIT(dusk_body, TRAIT_TRUE_NIGHT_VISION, REF(src))
		dusk_body.playsound_local(get_turf(dusk_body), pick(GLOB.heretic_dusk_sounds["eyes"]), 30, FALSE)
	else
		REMOVE_TRAIT(dusk_body, TRAIT_TRUE_NIGHT_VISION, REF(src))
	dusk_body.update_sight()

/// Сумерки Крыла поверх обычного зрения тела: тьма светлеет и холодеет, но не до дня.
/datum/eldritch_knowledge/base_dusk/proc/on_update_sight(mob/living/source)
	SIGNAL_HANDLER
	if(night_sight != HERETIC_DUSK_SIGHT_WING || source != dusk_body)
		return
	source.lighting_alpha = min(source.lighting_alpha, HERETIC_DUSK_WING_SIGHT_ALPHA)
	source.see_in_dark = max(source.see_in_dark, HERETIC_DUSK_WING_DARKSIGHT)
	var/list/dusk_cutoffs = HERETIC_DUSK_WING_SIGHT_CUTOFFS
	source.lighting_color_cutoffs = length(source.lighting_color_cutoffs) == 3 ? blend_cutoff_colors(source.lighting_color_cutoffs, dusk_cutoffs) : dusk_cutoffs

/// Луч фонаря в лицо Крылу гасит ему тёмное зрение, у Завета Крыла ещё и сбивает Шаг.
/datum/eldritch_knowledge/base_dusk/proc/light_in_face(mob/living/user)
	if(!dusk_body || dusk_body.stat == DEAD || !is_A_facing_B(dusk_body, user))
		return FALSE
	break_drag("вам посветили фонарём в лицо.")
	. = snuff_sight(user)
	if(covenant == HERETIC_DUSK_COVENANT_FALLEN && jam_step(user))
		. = TRUE

/// Вспышка рядом, у которой еретик стоит лицом или вплотную, слепит его тьму, если глаза не защищены.
/datum/eldritch_knowledge/base_dusk/proc/on_bright_flash(datum/source, turf/origin, mob/user)
	SIGNAL_HANDLER
	var/turf/here = get_turf(dusk_body)
	if(!origin || !here || user == dusk_body || origin.z != here.z || get_dist(origin, here) > HERETIC_DUSK_SIGHT_FLASH_RANGE)
		return
	if(get_dist(origin, here) > 1 && !is_A_facing_B(dusk_body, origin))
		return
	if(!(here in heretic_field_view(HERETIC_DUSK_SIGHT_FLASH_RANGE, origin)))
		return
	break_drag("рядом ударила вспышка.")
	snuff_sight(user)

/// Гасит своё тёмное зрение Сумрака и отблески глаз на HERETIC_DUSK_SIGHT_SNUFF; защита глаз держит свет.
/datum/eldritch_knowledge/base_dusk/proc/snuff_sight(mob/living/culprit)
	if(!dusk_body || dusk_body.stat == DEAD || (form != HERETIC_DUSK_FORM_WING && !ascension_active) || dusk_body.get_eye_protection() > 0)
		return FALSE
	var/was_dark = world.time >= sight_snuffed_until
	sight_snuffed_until = world.time + HERETIC_DUSK_SIGHT_SNUFF
	addtimer(CALLBACK(src, PROC_REF(end_snuff)), HERETIC_DUSK_SIGHT_SNUFF, TIMER_UNIQUE | TIMER_OVERRIDE)
	refresh_sight()
	refresh_mutation()
	if(was_dark)
		to_chat(dusk_body, span_warning("Свет бьёт в глаза, и тьма снова слепит вас: тёмное зрение вернётся через [HERETIC_DUSK_SIGHT_SNUFF / (1 SECONDS)] секунд."))
		if(isliving(culprit))
			log_combat(culprit, dusk_body, "гасит светом тёмное зрение Сумрака у")
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/end_snuff()
	if(!dusk_body || world.time < sight_snuffed_until)
		return
	refresh_sight()
	refresh_mutation()

/// Эмиссив виден, только пока виден турф: в полной темноте дальше see_in_dark глаза выдаёт светимость тела.
/// Клетки этот свет не освещает и пятна вокруг не рисует, иначе Крыло само выводило бы себя из тени.
/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes
	name = "Dusk eye glint"
	light_range = 1
	light_power = 0.1

/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/Initialize(mapload, _color, _range, _power, _duration)
	. = ..()
	silence()

/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/set_light_power(new_power)
	. = ..()
	silence()

/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/Moved(atom/OldLoc, Dir)
	. = ..()
	if(!QDELETED(src) && !ismob(loc))
		qdel(src)

/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/proc/silence()
	var/datum/component/overlay_lighting/glow = GetComponent(/datum/component/overlay_lighting)
	if(!glow)
		return
	glow.set_lum_power(0)
	glow.hide_from_holder()
	glow.set_alpha = 0
	glow.visible_mask.alpha = 0
	glow.show_to_holder()

/// Два бледных отблеска глаз Крыла в тени: экипаж видит их во тьме, маска, шлем и очки их закрывают.
/datum/eldritch_knowledge/base_dusk/proc/refresh_eyes(obj/item/gone)
	eye_overlays = build_eyes(gone)
	if(!dusk_body)
		return
	var/obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes/glow = locate() in dusk_body
	if(!length(eye_overlays))
		qdel(glow)
	else if(!glow)
		new /obj/effect/dummy/lighting_obj/moblight/heretic_dusk_eyes(dusk_body)

/datum/eldritch_knowledge/base_dusk/proc/build_eyes(obj/item/gone)
	. = list()
	var/mob/living/carbon/human/body = dusk_body
	if(!istype(body) || body.stat == DEAD || mutation_hidden || form != HERETIC_DUSK_FORM_WING || lit || world.time < sight_snuffed_until)
		return
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/heretic_evolution/evolution = heretic?.evolution
	if(evolution?.body != body || evolution.part_hidden(HERETIC_EVOLUTION_EYES, gone))
		return
	var/datum/species/kind = body.dna?.species
	if(!kind || (NOEYES in kind.species_traits) || !body.getorganslot(ORGAN_SLOT_EYES))
		return
	var/eye_type = ("[kind.eye_type]_left_eye" in icon_states(HERETIC_DUSK_EYES_ICON)) ? kind.eye_type : "normal"
	var/list/offset = (OFFSET_EYES in kind.offset_features) ? kind.offset_features[OFFSET_EYES] : null
	for(var/side in list("left", "right"))
		var/state = "[eye_type]_[side]_eye"
		var/mutable_appearance/glint = mutable_appearance(HERETIC_DUSK_EYES_ICON, state, -BODY_FRONT_LAYER)
		glint.appearance_flags = RESET_COLOR
		var/mutable_appearance/glow = emissive_appearance(HERETIC_DUSK_EYES_ICON, state, -BODY_FRONT_LAYER, offset_spokesman = body)
		for(var/mutable_appearance/look as anything in list(glint, glow))
			look.pixel_x += offset ? offset[1] : 0
			look.pixel_y += offset ? offset[2] : 0
			. += look

/// Отблески сквозь стены: меченые в тени всегда, носители света - пока в руке Фонарь полуночи.
/datum/eldritch_knowledge/base_dusk/proc/show_beacons()
	if(!dusk_body?.client)
		return
	var/turf/here = get_turf(dusk_body)
	if(!here)
		return
	var/list/mob/living/seen = list()
	var/range = sight_range()
	for(var/datum/status_effect/eldritch/dusk/mark as anything in marks)
		var/mob/living/victim = mark.owner
		if(victim?.z == here.z && get_dist(victim, here) <= range && !heretic_dusk_lit(get_turf(victim)))
			seen[victim] = HERETIC_DUSK_SHADE_INK
	for(var/datum/status_effect/heretic_dusk_rot/carrier as anything in rot)
		var/mob/living/victim = carrier.owner
		if(victim?.z == here.z && get_dist(victim, here) <= range)
			seen[victim] = HERETIC_DUSK_ROT_INK
	if(lantern_sight)
		for(var/mob/living/carbon/human/bearer as anything in GLOB.human_list)
			if(bearer == dusk_body || bearer.z != here.z || bearer.stat == DEAD || get_dist(bearer, here) > range)
				continue
			if(length(heretic_dusk_carried_lights(bearer)))
				seen[bearer] = HERETIC_DUSK_INK
	for(var/mob/living/victim as anything in seen)
		show_beacon(victim, seen[victim])

/// Дальность отблесков: растёт с улучшениями Фонаря полуночи.
/datum/eldritch_knowledge/base_dusk/proc/sight_range()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/dusk_relic/relic_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/dusk_relic)
	if(!relic_knowledge)
		return HERETIC_DUSK_SIGHT_RANGE
	return relic_knowledge.passive_values[clamp(relic_knowledge.passive_level, 1, length(relic_knowledge.passive_values))]

/datum/eldritch_knowledge/base_dusk/proc/show_beacon(mob/living/victim, tint)
	while(length(beacons) >= HERETIC_DUSK_SIGHT_RANGE)
		qdel(beacons[1])
	var/atom/movable/screen/heretic_dusk_beacon/beacon = new(null, src, victim, dusk_body, tint)
	beacons += beacon
	dusk_body.client.screen += beacon
	return beacon

/datum/eldritch_knowledge/base_dusk/proc/clear_beacons()
	QDEL_LIST(beacons)

/datum/eldritch_knowledge/base_dusk/proc/suns_state()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/final_eldritch/dusk_final/finale = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/dusk_final)
	if(!finale?.suns_raised)
		return ""
	return " Чёрных солнц стоит: [length(finale.suns)]."

/datum/eldritch_knowledge/spell/dusk_step
	name = "Шаг в тень"
	summary = "В облике Крыла вы шагаете в чужую тень: за человека в 9 клетках, на дальнюю от вас сторону, или к лампе."
	details = list(
		"Клетка за целью, с дальней от вас стороны, должна быть свободной и не на ярком свету; в часовню Шаг не ведёт.",
		"К цели с отнятой или выжженной тенью и к носителю скверны Шаг ведёт до 14 клеток и на свет.",
		"К заговорённой лампе на этаже Шаг уводит за 2 секунды: укажите себя или лампу.",
		"2 заряда, каждый возвращается за 6 секунд; святая вода в крови и часовня держат их.",
		"После Шага первый удар Пером в 2 секунды - Удар из тени; на обоих концах 2 секунды стоит чернильная лужа.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "У каждого есть тень. У каждой тени есть место за спиной. Там теперь стою я."
	cost = 1
	route = PATH_DUSK
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_dusk/step

/datum/eldritch_knowledge/spell/dusk_step/on_gain(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	dusk?.fill_charges("step")

/datum/eldritch_knowledge/spell/dusk_grip
	name = "Хватка тени"
	summary = "В облике Крыла за 2 Сумрака тень цели прибивает её к полу: в тени на 10 секунд, на свету на 5."
	details = list(
		"Цель в 7 клетках. На свету Хватка держит 5 секунд, по отнятой или выжженной тени, носителю скверны и в затмении - 10.",
		"За 0,8 секунды под целью вспухает тень; ушедшую за 7 клеток она теряет: Сумрак вернётся, Хватка готова через 5 секунд.",
		"Святая вода на цели или на вас, нулевой жезл и Библия капеллана рвут Хватку сразу; растолкать - за 2 секунды.",
		"Фонарик по прибитой цели укорачивает Хватку вдвое и отбрасывает тени назад.",
		"Прибитую цель охоты сердце уводит в изнанку, если вы стоите рядом. Перезарядка 25 секунд.",
		"Перо в намерении «Схватить» по прибитой цели в Крыле за 2 секунды утягивает её в тень: 40 ушибов, вам +25.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Его тень легла на пол раньше него. И уже не отпустила."
	cost = 2
	route = PATH_DUSK
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_dusk/grip

/datum/eldritch_knowledge/spell/dusk_grip/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(dusk)
		QDEL_LIST(dusk.grips)
	return ..()

/// Четвёртая ступень: Нисхождение и выбор Завета, который смещает упор пути до конца раунда.
/datum/eldritch_knowledge/spell/dusk_covenant
	name = "Завет падшего"
	summary = "Нисхождение падает к цели на свету, а кнопка «Завет» до конца раунда выбирает Нимб, Крыло или Скверну."
	details = list(
		"Нисхождение в Лике за единицу Сумрака: прыжок к цели на свету в 4 клетках, за полсекунды встаёт столб света.",
		"Задетая цель получает 12 ушибов и падает на 1,5 секунды; заряд вернётся за 12 секунд, в часовню прыжок не ведёт.",
		"Завет выбирается один раз, с подтверждением, и держится до конца раунда; мутация перерастает под него.",
		"Нимб: Лик слепит в 4 клетках на 6 секунд, луч идёт цепью ламп, Нисхождение жжёт пол светом; на свету лечит.",
		"Крыло: 3 заряда Шага, Удар из тени режет до крови, Хватка дольше на 3 секунды, отнятая тень становится слугой.",
		"Скверна: Хватка заражает, носители кормят вас Сумраком, Хватка и Шаг берут их на свету, Перо гноит их раны.",
		"С этой ступени из лопаток прорастают культи крыльев.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Ангелы не ходят. Они нисходят - и каждый однажды выбирает, во что падать: в свет, во тьму или в гниль."
	cost = 2
	route = PATH_DUSK
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_dusk/descent
	var/obj/effect/proc_holder/spell/self/heretic_dusk/covenant/choice_power

/datum/eldritch_knowledge/spell/dusk_covenant/on_gain(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	dusk?.fill_charges("descent")
	if(user && !dusk?.covenant)
		to_chat(user, span_eldritch("Кнопка «Завет» ждёт вашего выбора: Нимб, Крыло или Скверна. Выбор держится до конца раунда."))

/datum/eldritch_knowledge/spell/dusk_covenant/on_body_gain(mob/living/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(!user?.mind || dusk?.covenant || !QDELETED(choice_power))
		return
	choice_power = new
	user.mind.AddSpell(choice_power)

/datum/eldritch_knowledge/spell/dusk_covenant/on_body_lose(mob/living/user)
	QDEL_NULL(choice_power)
	return ..()

/datum/eldritch_knowledge/spell/dusk_covenant/Destroy()
	QDEL_NULL(choice_power)
	return ..()

/datum/eldritch_knowledge/dusk_grasp
	name = "Отнятая тень"
	summary = "В облике Крыла Хватка отнимает у цели тень на 20 секунд: в темноте она почти ничего не видит."
	details = list(
		"Отнятая тень видна всем: тёмный силуэт рядом с целью тянется к вам.",
		"На свету цель видит как обычно, в тени экран темнеет и сужается к центру; святая вода в крови возвращает тень.",
		"Шаг в тень ведёт к отнятой тени дальше и на ярком свету; Хватка тени держит такую цель полные 10 секунд и на свету.",
		"У Завета Крыла тень встаёт слугой на 30 секунд: бежит за вами и путает ноги погоне; удар или фонарик её рвут.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Я накрыл его крылом. Когда я убрал его, тень осталась у меня."
	cost = 1
	route = PATH_DUSK

/datum/eldritch_knowledge/dusk_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(!proximity_flag || !dusk?.can_use(user) || dusk.form != HERETIC_DUSK_FORM_WING || !isliving(target) || !isturf(target.loc) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_dusk_shadow/shadow = victim.apply_status_effect(/datum/status_effect/heretic_dusk_shadow, dusk)
	if(QDELETED(shadow))
		return FALSE
	log_combat(user, victim, "отнимает тень Хваткой Сумрака у")
	if(dusk.covenant == HERETIC_DUSK_COVENANT_FALLEN)
		dusk.raise_servant(victim)
	return TRUE

/datum/eldritch_knowledge/dusk_grasp/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(dusk)
		QDEL_LIST(dusk.shadows)
		QDEL_NULL(dusk.servant)

/datum/eldritch_knowledge/dusk_mark
	name = "Перевёрнутый нимб"
	summary = "Хватка вешает над целью перевёрнутый нимб на 15 секунд: в тени вы видите её сквозь стены."
	details = list(
		"Нимб видят все, а вокруг меченого тускнеет свет.",
		"Пока меченый в тени и не дальше 9 клеток, его отблеск виден вам сквозь стены.",
		"Взрыв метки Пером - вспышка тьмы: 15 ушибов и 2 секунды слепоты.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Я перевернул над ним нимб. Теперь свет падает с него вниз, прямо мне в руки."
	cost = 1
	route = PATH_DUSK

/datum/eldritch_knowledge/dusk_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(!proximity_flag || !dusk?.can_use(user) || !isliving(target) || !isturf(target.loc) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/dusk, dusk)
	return TRUE

/datum/eldritch_knowledge/dusk_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(dusk)
		QDEL_LIST(dusk.marks)

/datum/eldritch_knowledge/spell/dusk_glare
	name = "Лик ангела"
	summary = "В облике Лика за единицу Сумрака взгляд слепит смотрящих на вас в конусе 3 клеток на 4 секунды."
	details = list(
		"Слепнет только тот, кто стоит перед вами и смотрит в вашу сторону; тёмные очки и сварочные маски защищают.",
		"Указав на человека с горящим фонариком в 7 клетках, вы перегружаете свет: вспышка в лицо и 10 секунд без фонарика.",
		"Перезарядка 20 секунд, на освещённой клетке вдвое быстрее. У Завета Нимба Лик бьёт в 4 клетках на 6 секунд.",
		"С этой ступени над головой встаёт треснувший нимб.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Я поднял лицо к ним. Тот, кто посмотрел, увидел ангела - и больше ничего."
	cost = 1
	route = PATH_DUSK
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_dusk/glare

/datum/eldritch_knowledge/dusk_relic
	name = "Фонарь полуночи"
	summary = "Фонарик и лист стекла дают фонарь с чёрным пламенем: в руке копит Сумрак и выдаёт носителей света."
	details = list(
		"С Фонарём в руке Сумрак копится в любом облике, вы видите тьму как день и носителей света в 9 клетках сквозь стены.",
		"В руке он гасит до 3 ближайших ламп в 3 клетках на 20 секунд; выключатель зажжёт их раньше. Перезарядка 40 секунд.",
		"Не-еретику Фонарь не светит. Реликвия одна: новую можно сделать, только если прежняя уничтожена.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Я зажёг фонарь, и вокруг стало темнее. Теперь я вижу тех, кто несёт свет."
	cost = 2
	route = PATH_DUSK
	passive_values = list(9, 12, 15)
	passive_desc = "Отблески носителей света и меченых сквозь стены видны в 9 / 12 / 15 клетках."
	required_atoms = list(/obj/item/flashlight, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/heretic_path_relic/dusk_lantern)

/datum/eldritch_knowledge/dusk_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/dusk_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/dusk_lantern)

/datum/eldritch_knowledge/spell/dusk_eclipse
	name = "Локальное затмение"
	summary = "За 3 Сумрака лампы в 4 клетках мигают 1,5 секунды и гаснут на 25 секунд."
	details = list(
		"Гаснут до 8 ближайших целых ламп; выключатель или починка зажигает их раньше.",
		"Внутри затмения Хватка тени держит полные 10 секунд и на свету, а экипаж видит тёмную виньетку.",
		"Фонарики и факелы экипажа светят внутри как обычно. Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Я закрыл крылом лампы, и они вспомнили, какой была ночь до них."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_DUSK
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_dusk/eclipse

/datum/eldritch_knowledge/final_eldritch/dusk_final
	name = "Падший, что Стоит в Дверях"
	summary = "Долгая ночь: 3 Чёрных солнца гасят общие отсеки; Полдень в полночь слепит всех вокруг."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне станции; станция узнаёт место обряда.",
		"Встают 3 Чёрных солнца в общих отсеках, не в часовне; там гаснет свет, и выключатели его не зажгут.",
		"Пока стоит солнце: лечение от отнятых теней, Шаг без заряда раз в 10 секунд, полная Хватка и в полутени.",
		"Солнце - 200 прочности; святая вода снимает 50, нулевой жезл раскалывает за 2 удара, Библия капеллана - 30.",
		"Стойкость, крылья над столами, тьма как день, смена облика без перезарядки, заряд Шага и Нисхождения сверху.",
		"Святая земля жжёт вас 3 ожогами раз в 2 секунды. У Скверны вокруг солнц растёт налёт, он заражает прохожих.",
		"Полдень в полночь: свет собирается 1,5 секунды и слепит смотрящих в 5 клетках на 6 секунд, гася их фонарики на 15.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Я перестал выбирать между днём и ночью. Теперь они выбирают, кому из них стоять у меня за спиной."
	route = PATH_DUSK
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_dusk/noon, /obj/effect/proc_holder/spell/self/heretic_dusk/desecrate)

/obj/item/melee/sickly_blade/dusk
	name = "fallen quill"
	desc = "Маховое перо падшего ангела, заточенное в клинок: одна половина опахала - застывший больной свет с режущей кромкой, другая обгорела до тлеющих бородок. Гарда - сорванный треснувший нимб кольцом, а в обгоревшей половине иногда открывается глаз. Свет по кромке запинается и гаснет не в такт."
	icon = HERETIC_DUSK_ICON
	icon_state = "dusk_blade"
	item_state = "dusk_blade"
	hitsound = HERETIC_DUSK_HIT_SFX
	route = PATH_DUSK
	mark_type = /datum/status_effect/eldritch/dusk

/datum/heretic_deed/dusk
	name = "Лампы помнят"
	next_step = "Заговорите Хваткой в намерении «Помощь» лампу и дождитесь, когда мимо неё пройдёт член экипажа в ещё не зачтённом отделе."
	desc = "Заговаривайте Хваткой Мансуса в намерении «Помощь» лампы станции. Дело продвигает мигание заговорённой лампы на члене экипажа: засчитывается отдел, где висит лампа, каждый отдел один раз."
	craft_wait = "лампа мигнёт, но в дело не пойдёт"
	craft_wait_place = "в ещё не зачтённом отделе"
	hint = "Держатся шесть ламп, новая вытесняет старейшую. Коридоры у отделов и проходные залы - хорошие места. На плафоне остаётся копоть в форме пера, а нулевой жезл и святая вода снимают заговор."
	trace_name = "burnt feather"
	trace_desc = "На полу лежит обгоревшее перо, тёплое, как будто его только что уронили с потолка."
	trace_state = "trace_dusk"
	combat_hint = "Поразите назначенную цель Хваткой тени или Нисхождением."

/datum/heretic_innate/dusk
	name = "Привычка к ночи"
	desc = "В тени ваши шаги беззвучны, на свету слышны как обычно. Свет вашей клетки проверяется раз в 2 секунды."

/datum/heretic_innate/dusk/on_tick()
	var/datum/eldritch_knowledge/base_dusk/dusk = knowledge_ref?.resolve()
	var/shaded = dusk?.dusk_body == body ? !dusk.lit : !heretic_dusk_lit(get_turf(body))
	if(shaded)
		ADD_TRAIT(body, TRAIT_SILENT_STEP, REF(src))
	else
		REMOVE_TRAIT(body, TRAIT_SILENT_STEP, REF(src))

#undef HERETIC_DUSK_INK
#undef HERETIC_DUSK_PALE
#undef HERETIC_DUSK_SHADE_INK
#undef HERETIC_DUSK_NIGHT_INK
#undef HERETIC_DUSK_ROT_INK
#undef HERETIC_DUSK_GRASP_SFX
#undef HERETIC_DUSK_MUTATION_SHADE_COLOR
#undef HERETIC_DUSK_BURST_TIME
#undef HERETIC_DUSK_MUTATION_OFFSET
#undef HERETIC_DUSK_EYES_ICON
#undef HERETIC_DUSK_CHAPEL_NOTICE
