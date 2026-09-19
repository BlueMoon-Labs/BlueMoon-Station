#define HERETIC_MANSUS_DURATION (180 SECONDS)
#define HERETIC_MANSUS_RECALL_TIME (2 SECONDS)
#define HERETIC_MANSUS_ROOM_SIZE 21
#define HERETIC_MANSUS_MEMORIES 3
#define HERETIC_MANSUS_WARNING_TIME (2 SECONDS)
#define HERETIC_MANSUS_HAZARD_LIFETIME (3 SECONDS)
#define HERETIC_MANSUS_LINGERING_LIFETIME (6 SECONDS)
#define HERETIC_MANSUS_HAZARD_LINE 5
#define HERETIC_MANSUS_HIT_GRACE (4 SECONDS)
#define HERETIC_MANSUS_HUNTER_GRACE (3 SECONDS)
#define HERETIC_MANSUS_GATE_SAFETY 1
#define HERETIC_MANSUS_GATE_CLEARANCE 2
#define HERETIC_MANSUS_TRAIL_LENGTH 6
#define HERETIC_MANSUS_TRAIL_CARRY_LENGTH 3
#define HERETIC_MANSUS_FINAL_PRESSURE 2
#define HERETIC_MANSUS_HUNTER_STEP (1 SECONDS)
#define HERETIC_MANSUS_HUNTER_FAST_STEP (0.5 SECONDS)
#define HERETIC_MANSUS_HUNTER_DISTANCE 6
#define HERETIC_MANSUS_RELENTLESS_DISTANCE 4
#define HERETIC_MANSUS_RELENTLESS_HASTE 0.7
#define HERETIC_MANSUS_UNSEEN_RANGE 3
#define HERETIC_MANSUS_SHIFT_INTERVAL (20 SECONDS)
#define HERETIC_MANSUS_PENALTY_PER_MEMORY (60 SECONDS)
#define HERETIC_MANSUS_TWIST_SLICK "slick"
#define HERETIC_MANSUS_TWIST_UNSEEN "unseen"
#define HERETIC_MANSUS_TWIST_LINGERING "lingering"
#define HERETIC_MANSUS_TWIST_SHIFTING "shifting"
#define HERETIC_MANSUS_TWIST_RELENTLESS "relentless"
#define HERETIC_MANSUS_ALERT "heretic_mansus"
#define HERETIC_MANSUS_ECHO_TINT list(0.79, 0, 0, 0, 0.79, 0, 0, 0, 0.79, 0, 0, 0, 0.12, 0.12, 0.12)

GLOBAL_LIST_EMPTY(heretic_mansus_visits)
GLOBAL_LIST_INIT(heretic_mansus_twist_hints, list(
	HERETIC_MANSUS_TWIST_SLICK = "Пол здесь скользкий: шаг проносит вас на клетку дальше. Светлая галерея держит ногу.",
	HERETIC_MANSUS_TWIST_UNSEEN = "Тень здесь не видна издали. Слушайте шаги: она проявляется только в трёх клетках от вас.",
	HERETIC_MANSUS_TWIST_LINGERING = "Трещины здесь гаснут вдвое дольше. Не давайте им перекрыть дорогу.",
	HERETIC_MANSUS_TWIST_SHIFTING = "Проходы здесь не стоят на месте: раз в двадцать секунд одни смыкаются, другие открываются.",
	HERETIC_MANSUS_TWIST_RELENTLESS = "Тень здесь не отступает далеко и ускоряется, когда вы с ней на одной прямой. Сворачивайте за углы.",
))

/// Строки идут с севера на юг; цифры - центры комнат, a и b - затворы, открытые по очереди.
GLOBAL_LIST_INIT(heretic_mansus_layouts, list(
	list(
		"#####################",
		"#######.......#######",
		"#######.S.G.S.#######",
		"#######.......#######",
		"#######.V.D.V.#######",
		"#######3.+++..#######",
		"#########+++#########",
		"#.....#+++++++#.....#",
		"#.S...#+S+V+S+#...S.#",
		"#..V..a++OOO++b..V..#",
		"#..1..aV+OOO+Vb..2..#",
		"#..V..a++OOO++b..V..#",
		"#.S...#+S+V+S+#...S.#",
		"#.....#+++++++#.....#",
		"####bbb##+++##aaa####",
		"####+++..+++..+++####",
		"####+++++++++++++####",
		"#######.......#######",
		"#######.SVEVS.#######",
		"#######.......#######",
		"#####################",
	),
	list(
		"#####################",
		"#######.......#######",
		"#######.S.G.S.#######",
		"#######.......#######",
		"#######.V.D.V.#######",
		"#######3.+++..#######",
		"#########+++#########",
		"#.....#+++++++#.....#",
		"#.S...#+S+V+S+#...S.#",
		"#..V..++OO+OO++..V..#",
		"#..1..b+OOaOO+b..2..#",
		"#..V..++OO+OO++..V..#",
		"#.S...#+S+V+S+#...S.#",
		"#.....#+++++++#.....#",
		"####aaa##+++##bbb####",
		"####+++..+++..+++####",
		"####+++++++++++++####",
		"#######.......#######",
		"#######.SVEVS.#######",
		"#######.......#######",
		"#####################",
	),
	list(
		"#####################",
		"#######.......#######",
		"#######.S.G.S.#######",
		"#######.......#######",
		"#######.V.D.V.#######",
		"#######3.+++..#######",
		"#########+++#########",
		"#.....#+++++++#.....#",
		"#.S...#+OOO+O+#...S.#",
		"#..V..b+++O+O+a..V..#",
		"#..1..b+O+a+O+a..2..#",
		"#..V..b+O+O+++a..V..#",
		"#.S...#+O+OOO+#...S.#",
		"#.....#+++++++#.....#",
		"####+++##+++##+++####",
		"####+++..+++..+++####",
		"####+++++++++++++####",
		"#######.......#######",
		"#######.SVEVS.#######",
		"#######.......#######",
		"#####################",
	),
))

GLOBAL_LIST_INIT(heretic_mansus_themes, list(
	PATH_ASH = list(
		"id" = "ash",
		"twist" = HERETIC_MANSUS_TWIST_LINGERING,
		"title" = "Пепел",
		"description" = "Тлеющие печи и почерневший камень хранят чужой пепел.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/ash_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/ash_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/ash_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/ash_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/ash_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/ash_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/ash_step.ogg',
	),
	PATH_RUST = list(
		"id" = "rust",
		"twist" = HERETIC_MANSUS_TWIST_SHIFTING,
		"title" = "Ржавчина",
		"description" = "Ржавчина обглодала железо. Из пустых мехов доносится скрежет.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/rust_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/rust_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/rust_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/rust_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/rust_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/rust_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/rust_step.ogg',
	),
	PATH_FLESH = list(
		"id" = "flesh",
		"twist" = HERETIC_MANSUS_TWIST_RELENTLESS,
		"title" = "Плоть",
		"description" = "Стены дышат. Под ногами сокращается живая ткань.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/flesh_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/flesh_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/flesh_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/flesh_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/flesh_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/flesh_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/flesh_step.ogg',
	),
	PATH_VOID = list(
		"id" = "void",
		"twist" = HERETIC_MANSUS_TWIST_SLICK,
		"title" = "Пустота",
		"description" = "Лёд глушит шаги. Между кристаллами неподвижно висит чужое дыхание.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/void_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/void_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/void_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/void_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/void_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/void_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/void_step.ogg',
	),
	PATH_BLADE = list(
		"id" = "blade",
		"twist" = HERETIC_MANSUS_TWIST_RELENTLESS,
		"title" = "Клинок",
		"description" = "Металл истёрт лезвиями. Пустая броня повторяет каждый шаг.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/blade_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/blade_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/blade_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/blade_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/blade_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/blade_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/blade_step.ogg',
	),
	PATH_MOON = list(
		"id" = "moon",
		"twist" = HERETIC_MANSUS_TWIST_UNSEEN,
		"title" = "Луна",
		"description" = "Бледные свечи отбрасывают тени в сторону луны, которой здесь нет.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/moon_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/moon_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/moon_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/moon_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/moon_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/moon_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/moon_step.ogg',
	),
	PATH_COSMIC = list(
		"id" = "cosmic",
		"twist" = HERETIC_MANSUS_TWIST_RELENTLESS,
		"title" = "Космос",
		"description" = "Среди погасших звёзд вращаются обломки незнакомого неба.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/cosmic_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/cosmic_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/cosmic_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/cosmic_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/cosmic_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/cosmic_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/cosmic_step.ogg',
	),
	PATH_LOCK = list(
		"id" = "lock",
		"twist" = HERETIC_MANSUS_TWIST_SHIFTING,
		"title" = "Замок",
		"description" = "Каждый замок закрыт изнутри. В глубине святилищ щёлкают невидимые ключи.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/lock_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/lock_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/lock_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/lock_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/lock_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/lock_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/lock_step.ogg',
	),
	PATH_TIDE = list(
		"id" = "tide",
		"twist" = HERETIC_MANSUS_TWIST_SLICK,
		"title" = "Пучина",
		"description" = "Мокрый камень хранит соль. Между колоннами слышен далёкий прибой.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/tide_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/tide_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/tide_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/tide_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/tide_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/tide_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/tide_step.ogg',
	),
	PATH_GLASS = list(
		"id" = "glass",
		"twist" = HERETIC_MANSUS_TWIST_SLICK,
		"title" = "Стекло",
		"description" = "В кристаллах остаются отражения тех, кто уже ушёл.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/glass_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/glass_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/glass_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/glass_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/glass_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/glass_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/glass_step.ogg',
	),
	PATH_BLOOD = list(
		"id" = "blood",
		"twist" = HERETIC_MANSUS_TWIST_LINGERING,
		"title" = "Кровь",
		"description" = "По алтарям сочится кровь. Её пульс не совпадает с вашим.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/blood_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/blood_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/blood_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/blood_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/blood_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/blood_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/blood_step.ogg',
	),
	PATH_ECHO = list(
		"id" = "echo",
		"twist" = HERETIC_MANSUS_TWIST_UNSEEN,
		"title" = "Эхо",
		"description" = "Под деревянными сводами возвращается эхо ещё не сделанного шага.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/echo_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/echo_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/echo_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/echo_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/echo_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/echo_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/echo_step.ogg',
	),
	PATH_SAND = list(
		"id" = "sand",
		"twist" = HERETIC_MANSUS_TWIST_SHIFTING,
		"title" = "Песок",
		"description" = "Песок шуршит в погасших печах и стачивает выбитые на камне имена.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/sand_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/sand_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/sand_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/sand_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/sand_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/sand_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/sand_step.ogg',
	),
	PATH_WAX = list(
		"id" = "wax",
		"twist" = HERETIC_MANSUS_TWIST_LINGERING,
		"title" = "Воск",
		"description" = "Застывшие потёки воска хранят тепло чужих рук.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/wax_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/wax_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/wax_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/wax_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/wax_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/wax_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/wax_step.ogg',
	),
	PATH_SPIRIT = list(
		"id" = "spirit",
		"twist" = HERETIC_MANSUS_TWIST_UNSEEN,
		"title" = "Дух",
		"description" = "За свечами скользит пустой саван. На старых досках не остаётся его следов.",
		"ambience" = 'modular_bluemoon/sound/heretic/mansus/spirit_ambience.ogg',
		"pickup" = 'modular_bluemoon/sound/heretic/mansus/spirit_pickup.ogg',
		"deposit" = 'modular_bluemoon/sound/heretic/mansus/spirit_deposit.ogg',
		"warning" = 'modular_bluemoon/sound/heretic/mansus/spirit_warning.ogg',
		"hit" = 'modular_bluemoon/sound/heretic/mansus/spirit_hit.ogg',
		"escape" = 'modular_bluemoon/sound/heretic/mansus/spirit_escape.ogg',
		"step" = 'modular_bluemoon/sound/heretic/mansus/spirit_step.ogg',
	),
))


/// Комната принадлежит одному посещению: чужие жертвы никогда не встречаются внутри.
/area/heretic_mansus
	name = "Mansus: House of Memory"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	area_flags = UNIQUE_AREA | NOTELEPORT | RADIO_BLACKOUT

/turf/open/indestructible/heretic_mansus
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_floor0"
	name = "forgotten road"
	desc = "Под камнями слышны шаги тех, кто ещё не родился."
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	baseturfs = /turf/open/indestructible/heretic_mansus

/turf/open/indestructible/heretic_mansus/path
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_path"
	name = "road home"
	desc = "Светлый камень помнит шаги. Галерея огибает провал и соединяет комнаты Дома."
	baseturfs = /turf/open/indestructible/heretic_mansus/path

/turf/closed/indestructible/heretic_mansus
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_wall15"
	name = "wall of the House"
	desc = "Слишком много дверей. Ни одной ручки."
	baseturfs = /turf/closed/indestructible/heretic_mansus

/turf/closed/indestructible/heretic_mansus/shutter
	name = "closed passage"
	desc = "Недавно здесь была галерея. Дом переставил стены; ищите другой путь."
	baseturfs = /turf/closed/indestructible/heretic_mansus/shutter

/turf/closed/indestructible/heretic_mansus/abyss
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_abyss0"
	name = "bottomless courtyard"
	desc = "Внизу нет ни пола, ни звёзд. По краю провала тянется каменная галерея."
	opacity = FALSE
	baseturfs = /turf/closed/indestructible/heretic_mansus/abyss

/// Владеет таймерами, комнатой и сигналами; снятие роли еретика не бросает жертву внутри.
/datum/heretic_mansus_visit
	var/mob/living/carbon/human/victim
	var/list/theme
	var/datum/mind/soul
	var/datum/turf_reservation/reservation
	var/area/heretic_mansus/room
	var/turf/return_turf
	var/turf/fallback_turf
	var/turf/entry_turf
	var/obj/effect/heretic_mansus_gate/gate
	var/obj/effect/heretic_mansus_offering/offering
	var/list/route_steps = list()
	var/list/trail = list()
	var/list/memories = list()
	var/list/scenery = list()
	var/list/timers = list()
	var/list/walkable_turfs = list()
	var/list/hazards = list()
	var/memories_found = 0
	var/forced_exit = 0
	var/entered_at = 0
	var/hits_taken = 0
	var/recall_duration = HERETIC_MANSUS_RECALL_TIME
	var/delivery_duration = 1 SECONDS
	var/obj/effect/heretic_mansus_memory/recalling_memory
	var/obj/effect/heretic_mansus_memory/carried_memory
	var/delivering_memory = FALSE
	var/danger_enabled = TRUE
	var/next_hazard_at = 0
	var/next_hazard_hit = 0
	var/list/hunters = list()
	var/layout_index
	var/list/shutters_a = list()
	var/list/shutters_b = list()
	var/shutter_phase = FALSE
	var/twist
	var/shift_timer
	var/sliding = FALSE
	var/hazard_volleys = 0
	var/hazard_lifetime = HERETIC_MANSUS_HAZARD_LIFETIME
	var/hunter_respawn_distance = HERETIC_MANSUS_HUNTER_DISTANCE
	var/music_channel
	var/client/music_listener
	var/visit_duration = HERETIC_MANSUS_DURATION
	var/started = FALSE
	var/finished = FALSE
	var/finish_pending = FALSE

/datum/heretic_mansus_visit/Destroy()
	if(!finish(delete_visit = FALSE) && !finished)
		return QDEL_HINT_LETMELIVE
	return ..()

/// Подготовка может ждать mapping; до её завершения обряд не выдаёт награду.
/datum/heretic_mansus_visit/proc/prepare(mob/living/carbon/human/target, turf/destination, turf/origin, path_id = PATH_ASH)
	if(QDELETED(target) || target.stat == DEAD || QDELETED(target.mind) || !destination || started || reservation)
		return FALSE
	theme = GLOB.heretic_mansus_themes[path_id] || GLOB.heretic_mansus_themes[PATH_ASH]
	twist = theme["twist"]
	if(twist == HERETIC_MANSUS_TWIST_LINGERING)
		hazard_lifetime = HERETIC_MANSUS_LINGERING_LIFETIME
	if(twist == HERETIC_MANSUS_TWIST_RELENTLESS)
		hunter_respawn_distance = HERETIC_MANSUS_RELENTLESS_DISTANCE
	victim = target
	soul = target.mind
	return_turf = destination
	fallback_turf = origin
	var/datum/turf_reservation/new_reservation = SSmapping.RequestBlockReservation(HERETIC_MANSUS_ROOM_SIZE, HERETIC_MANSUS_ROOM_SIZE)
	if(QDELETED(src) || QDELETED(new_reservation) || QDELETED(victim) || QDELETED(soul))
		qdel(new_reservation)
		return FALSE
	reservation = new_reservation
	// BYOND не собирает области автоматически; отдельные посещения разделены резервированиями.
	room = GLOB.areas_by_type[/area/heretic_mansus] || new /area/heretic_mansus
	var/left = reservation.bottom_left_coords[1]
	var/bottom = reservation.bottom_left_coords[2]
	var/level = reservation.bottom_left_coords[3]
	if(!layout_index)
		layout_index = rand(1, length(GLOB.heretic_mansus_layouts))
	var/list/layout = GLOB.heretic_mansus_layouts[layout_index]
	var/list/words = list("Ваше имя. Никто здесь не вправе его отнять.", "Знакомый голос. Он ждёт вас по ту сторону стены.", "Собственное дыхание. Вы всё ещё живы.")
	var/list/memory_names = list("name", "voice", "breath")
	var/list/chamber_centers = list(null, null, null)
	for(var/row in 1 to HERETIC_MANSUS_ROOM_SIZE)
		var/row_layout = layout[row]
		for(var/column in 1 to HERETIC_MANSUS_ROOM_SIZE)
			var/turf/reserved = locate(left + column - 1, bottom + HERETIC_MANSUS_ROOM_SIZE - row, level)
			room.contents += reserved
			var/tile = copytext(row_layout, column, column + 1)
			if(tile == "#")
				reserved.ChangeTurf(/turf/closed/indestructible/heretic_mansus)
				continue
			if(tile == "O")
				reserved.ChangeTurf(/turf/closed/indestructible/heretic_mansus/abyss)
				continue
			if(tile == "b")
				shutters_b += reserved.ChangeTurf(/turf/closed/indestructible/heretic_mansus/shutter)
				continue
			reserved = reserved.ChangeTurf((tile == "+" || tile == "a") ? /turf/open/indestructible/heretic_mansus/path : /turf/open/indestructible/heretic_mansus)
			switch(tile)
				if("a")
					shutters_a += reserved
				if("E")
					entry_turf = reserved
				if("G")
					gate = new(reserved, src)
					scenery += gate
				if("D")
					offering = new(reserved, src)
					scenery += offering
				if("S")
					scenery += new /obj/effect/heretic_mansus_statue(reserved, src)
				if("V")
					scenery += new /obj/effect/heretic_mansus_candle(reserved, src)
				if("1", "2", "3")
					var/index = text2num(tile)
					chamber_centers[index] = reserved
	for(var/turf/tile as anything in reservation.reserved_turfs)
		style_turf(tile)
	for(var/turf/open/indestructible/heretic_mansus/floor in reservation.reserved_turfs)
		if(locate(/obj/effect/heretic_mansus_statue) in floor)
			continue
		walkable_turfs += floor
		if(is_safe(floor))
			scenery += new /obj/effect/heretic_mansus_sanctuary(floor)
	var/list/chamber_order = list(3) + shuffle(list(1, 2))
	var/list/used_positions = list()
	for(var/chamber in chamber_order)
		var/turf/center = chamber_centers[chamber]
		var/list/candidates = list()
		for(var/turf/floor as anything in walkable_turfs)
			if(get_dist(center, floor) <= 1 && get_dist(gate, floor) > HERETIC_MANSUS_GATE_CLEARANCE && !is_safe(floor) && floor.y < offering.y && !(locate(/obj/effect/heretic_mansus_candle) in floor) && !(floor in used_positions))
				candidates += floor
		if(!length(candidates))
			return FALSE
		var/turf/position = pick(candidates)
		used_positions += position
		var/obj/effect/heretic_mansus_memory/memory = new(position, src, words[chamber])
		memory.name = "memory shard: [memory_names[chamber]]"
		memory.chamber = chamber
		memories += memory
		scenery += memory
	for(var/index in 1 to HERETIC_MANSUS_TRAIL_LENGTH)
		var/obj/effect/heretic_mansus_trail/marker = new(entry_turf)
		trail += marker
		scenery += marker
	return TRUE

/datum/heretic_mansus_visit/proc/style_turf(turf/tile)
	if(!istype(tile, /turf/closed/indestructible/heretic_mansus))
		apply_style(tile, istype(tile, /turf/open/indestructible/heretic_mansus/path) ? "path" : "floor[pick(0, 0, 0, 1, 2)]")
		return
	var/edge_mask = NONE
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(tile, direction)
		if(istype(neighbor, /turf/open/indestructible/heretic_mansus))
			edge_mask |= direction
	apply_style(tile, "[istype(tile, /turf/closed/indestructible/heretic_mansus/abyss) ? "abyss" : "wall"][edge_mask]")

/datum/heretic_mansus_visit/proc/apply_style(atom/target, state)
	target.icon = istype(target, /obj/effect/heretic_mansus_gate) ? 'modular_bluemoon/icons/obj/heretic_mansus_gates.dmi' : 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	target.icon_state = "[theme["id"]]_[state]"
	target.color = null

/// Вызывается после повторной проверки души и компонентов обряда.
/datum/heretic_mansus_visit/proc/start()
	if(started || finished || QDELETED(victim) || victim.stat == DEAD || QDELETED(soul) || victim.mind != soul || !entry_turf || GLOB.heretic_mansus_visits[soul])
		return FALSE
	started = TRUE
	GLOB.heretic_mansus_visits[soul] = src
	heal_victim()
	victim.grab_ghost()
	ADD_TRAIT(victim, TRAIT_NOBREATH, REF(src))
	ADD_TRAIT(victim, TRAIT_NOFIRE, REF(src))
	// Не снимаем и не уничтожаем наручники: воспоминания доступны и при связанных руках.
	if(victim.buckled)
		victim.buckled.unbuckle_mob(victim, force = TRUE)
	victim.stop_pulling()
	victim.forceMove(entry_turf)
	RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(on_victim_moved))
	RegisterSignal(victim, COMSIG_LIVING_DEATH, PROC_REF(on_victim_death))
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_victim_deleted))
	RegisterSignals(soul, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING), PROC_REF(on_soul_changed))
	RegisterSignal(reservation, COMSIG_PARENT_QDELETING, PROC_REF(on_reservation_deleted))
	entered_at = world.time
	forced_exit = world.time + visit_duration
	timers += addtimer(CALLBACK(src, PROC_REF(timeout)), visit_duration, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(whisper), 1), 25 SECONDS, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(whisper), 2), 65 SECONDS, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(whisper), 3), HERETIC_MANSUS_DURATION - 15 SECONDS, TIMER_STOPPABLE)
	music_channel = SSsounds.reserve_sound_channel(src)
	music_listener = victim.client
	if(music_channel && victim.client?.prefs.toggles & SOUND_AMBIENCE)
		SEND_SOUND(victim, sound(theme["ambience"], repeat = TRUE, channel = music_channel, volume = 45))
	to_chat(victim, span_userdanger("Верните себе имя, голос и дыхание. Доставьте три осколка на светящуюся печать перед северными вратами — и сможете вернуться домой."))
	to_chat(victim, span_notice("Идите по светящимся стрелкам. Наступите на яркий осколок и остановитесь на [DisplayTimeText(recall_duration)], затем отнесите его на печать и остановитесь ещё на секунду. Связанные руки не мешают. Первый осколок можно доставить спокойно: тень и разломы появятся после него, а каждая доставка переставляет проходы Дома. Значок Дома памяти подсказывает текущую цель; нажмите на него, чтобы повторить подсказку."))
	to_chat(victim, span_notice("У печати и врат безопасно. Уходите с трещин до вспышки и не подпускайте тень: удар возвращает несомый осколок в его комнату. Уже доставленные осколки не теряются. Последний осколок придётся нести под усиленным натиском. Радиосвязь не работает; через [DisplayTimeText(visit_duration)] Дом вернёт вас сам."))
	to_chat(victim, span_notice("Дом памяти — [theme["title"]]. [theme["description"]]"))
	to_chat(victim, span_warning(GLOB.heretic_mansus_twist_hints[twist]))
	awaken_memory()
	START_PROCESSING(SSprocessing, src)
	log_game("Mansus: [key_name(victim)] entered [theme["id"]].")
	record_mansus_memory()
	return TRUE

/datum/heretic_mansus_visit/proc/timeout()
	finish(exit_reason = "timeout")

/datum/heretic_mansus_visit/proc/is_safe(atom/position)
	return contains(position) && ((!QDELETED(gate) && get_dist(position, gate) <= HERETIC_MANSUS_GATE_SAFETY) || (!QDELETED(offering) && get_dist(position, offering) <= HERETIC_MANSUS_GATE_SAFETY))

/datum/heretic_mansus_visit/proc/contains(atom/thing)
	return reservation && (get_turf(thing) in reservation.reserved_turfs)

/// Админское fully_heal() удаляет все наручники в инвентаре. Восстанавливаем тело без этого побочного эффекта.
/datum/heretic_mansus_visit/proc/heal_victim()
	victim.regenerate_limbs()
	victim.regenerate_organs()
	victim.revive(full_heal = TRUE)

/datum/heretic_mansus_visit/proc/can_recall(obj/effect/heretic_mansus_memory/memory, mob/user)
	if(QDELETED(src) || !started || finished || QDELETED(memory) || QDELETED(user))
		return FALSE
	if(user != victim || user.stat != CONSCIOUS || !contains(user) || !contains(memory))
		return FALSE
	return (memory in memories) && memory.awake && !memory.recalled && get_dist(user, memory) <= 1

/datum/heretic_mansus_visit/proc/collect_memory(obj/effect/heretic_mansus_memory/memory, mob/user)
	if(recalling_memory || carried_memory || !can_recall(memory, user))
		return FALSE
	recalling_memory = memory
	memory.balloon_alert(victim, "собираете осколок")
	var/recalled = do_after(user, recall_duration, memory, timed_action_flags = IGNORE_HELD_ITEM | IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(can_recall), memory, user))
	recalling_memory = null
	if(!recalled || !can_recall(memory, user))
		return FALSE
	memory.recalled = TRUE
	memory.awake = FALSE
	carried_memory = memory
	animate(memory)
	memory.alpha = 0
	memory.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	memory.desc = "Этот осколок нужно донести на печать перед северными вратами."
	to_chat(victim, span_notice("[memory.recollection] Осколок с вами. Следуйте стрелкам к светящейся печати перед вратами и остановитесь на ней."))
	playsound(memory, theme["pickup"], 45, FALSE)
	log_game("Mansus: [key_name(victim)] collected fragment [memories_found + 1]/[HERETIC_MANSUS_MEMORIES], chamber [memory.chamber].")
	update_route()
	update_guidance()
	return TRUE

/datum/heretic_mansus_visit/proc/awaken_memory()
	if(finished || carried_memory || memories_found >= HERETIC_MANSUS_MEMORIES)
		return
	var/obj/effect/heretic_mansus_memory/memory = memories[memories_found + 1]
	if(QDELETED(memory))
		return
	memory.awake = TRUE
	memory.recalled = FALSE
	memory.alpha = 255
	memory.mouse_opacity = MOUSE_OPACITY_ICON
	memory.desc = "Наступите на осколок и остановитесь на [DisplayTimeText(recall_duration)]. Затем следуйте стрелкам к печати перед вратами. Наручники не мешают."
	animate(memory, alpha = 170, time = 1 SECONDS, loop = -1)
	animate(alpha = 255, time = 1 SECONDS)
	var/list/directions = list("В западной комнате загорается осколок.", "Из восточной комнаты доносится зов осколка.", "В северной комнате пробуждается осколок.")
	to_chat(victim, span_boldnotice(directions[memory.chamber]))
	update_route()
	update_guidance()

/datum/heretic_mansus_visit/proc/update_route()
	route_steps.Cut()
	var/obj/effect/heretic_mansus_memory/memory = memories[min(memories_found + 1, HERETIC_MANSUS_MEMORIES)]
	var/turf/target = get_turf(carried_memory ? offering : memory)
	if(!(target in walkable_turfs))
		return
	var/list/frontier = list(target)
	var/index = 1
	while(index <= length(frontier))
		var/turf/current = frontier[index++]
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current, direction)
			if(!(neighbor in walkable_turfs) || neighbor == target || route_steps[neighbor])
				continue
			route_steps[neighbor] = current
			frontier += neighbor
	update_trail()

/datum/heretic_mansus_visit/proc/update_trail()
	var/turf/current = get_turf(victim)
	var/markers_left = carried_memory ? HERETIC_MANSUS_TRAIL_CARRY_LENGTH : HERETIC_MANSUS_TRAIL_LENGTH
	for(var/obj/effect/heretic_mansus_trail/marker as anything in trail)
		var/turf/next = markers_left-- > 0 ? route_steps[current] : null
		marker.alpha = next ? 230 : 0
		if(!next)
			continue
		marker.forceMove(current)
		marker.setDir(get_dir(current, next))
		current = next

/datum/heretic_mansus_visit/proc/update_guidance()
	if(finished || QDELETED(victim))
		return
	var/atom/movable/screen/alert/heretic_mansus/indicator = victim.throw_alert(HERETIC_MANSUS_ALERT, /atom/movable/screen/alert/heretic_mansus, no_anim = TRUE)
	apply_style(indicator, "memory")
	indicator.name = "[carried_memory ? "Отнесите осколок на печать" : "Идите к яркому осколку"]: [memories_found]/[HERETIC_MANSUS_MEMORIES]"
	var/list/chambers = list("западной", "восточной", "северной")
	var/obj/effect/heretic_mansus_memory/next_memory = memories[min(memories_found + 1, HERETIC_MANSUS_MEMORIES)]
	indicator.desc = "[carried_memory ? "Вы несёте осколок: остановитесь на светящейся печати перед северными вратами на секунду." : "Следуйте стрелкам к осколку [chambers[next_memory.chamber]] комнаты. Наступите на него и остановитесь на [DisplayTimeText(recall_duration)]."] [memories_found ? "Избегайте тени и вспыхнувших трещин: удар возвращает несомый осколок в его комнату." : "Пока вы не доставите первый осколок, опасностей нет."] У печати безопасно. Доставленные осколки не теряются. Автоматическое возвращение через [DisplayTimeText(max(0, forced_exit - world.time))]."
	indicator.maptext = MAPTEXT("[memories_found]/[HERETIC_MANSUS_MEMORIES][carried_memory ? "+" : ""]")

/datum/heretic_mansus_visit/proc/open_gate()
	if(!started || finished || QDELETED(gate) || gate.opened || memories_found < HERETIC_MANSUS_MEMORIES)
		return
	gate.opened = TRUE
	apply_style(gate, "gate_open")
	gate.desc = "Все осколки на месте. Коснитесь врат или войдите в них."
	gate.balloon_alert(victim, "путь домой открыт")

/datum/heretic_mansus_visit/proc/can_deliver(mob/user, obj/effect/heretic_mansus_memory/memory)
	return !finished && !QDELETED(user) && !QDELETED(gate) && !QDELETED(memory) && user == victim && user.stat == CONSCIOUS && carried_memory == memory && is_safe(user)

/datum/heretic_mansus_visit/proc/try_exit(mob/user)
	if(finished || QDELETED(gate) || user != victim || !is_safe(user) || user.stat != CONSCIOUS || delivering_memory)
		return FALSE
	if(memories_found >= HERETIC_MANSUS_MEMORIES)
		return finish(exit_reason = "completed")
	var/obj/effect/heretic_mansus_memory/memory = carried_memory
	if(!memory)
		gate.balloon_alert(victim, "доставлено: [memories_found]/[HERETIC_MANSUS_MEMORIES]")
		return FALSE
	delivering_memory = TRUE
	gate.balloon_alert(victim, "закрепляете осколок")
	var/delivered = do_after(user, delivery_duration, gate, timed_action_flags = IGNORE_HELD_ITEM | IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(can_deliver), user, memory), progress_loc = offering)
	delivering_memory = FALSE
	if(!delivered || !can_deliver(user, memory))
		return FALSE
	carried_memory = null
	memory.delivered = TRUE
	memory.alpha = 0
	memory.desc = "Этот осколок уже закреплён во вратах. Дом больше не отнимет его."
	memories_found++
	offering.icon_state = "offering[memories_found]"
	playsound(gate, theme["deposit"], 45, FALSE)
	to_chat(victim, span_boldnotice("Врата удержали осколок: [memories_found]/[HERETIC_MANSUS_MEMORIES]."))
	log_game("Mansus: [key_name(victim)] delivered [memories_found]/[HERETIC_MANSUS_MEMORIES] after [(world.time - entered_at) / (1 SECONDS)] seconds.")
	if(memories_found >= HERETIC_MANSUS_MEMORIES)
		open_gate()
		return finish(exit_reason = "completed")
	toggle_shutters()
	if(memories_found == 1 && danger_enabled)
		next_hazard_at = world.time + 6 SECONDS
		spawn_hunter()
		if(twist == HERETIC_MANSUS_TWIST_SHIFTING)
			arm_shift()
		to_chat(victim, span_warning("Дом заметил вас и переставил проходы. Теперь тень идёт по галерее, а трещины предупреждают о вспышке - под ногами или линией впереди. Продолжайте по стрелкам; у печати можно передохнуть."))
	if(memories_found == HERETIC_MANSUS_FINAL_PRESSURE)
		if(danger_enabled)
			spawn_hunter()
		to_chat(victim, span_userdanger("Остался последний осколок. Тень ускоряется, за ней выходит вторая, трещины вспыхивают чаще. Выманите обеих из комнаты, прежде чем останавливаться у осколка!"))
	awaken_memory()
	return TRUE

/datum/heretic_mansus_visit/process(delta_time)
	if(finished || !started)
		return PROCESS_KILL
	update_guidance()
	if(!danger_enabled || QDELETED(victim) || !contains(victim))
		return
	for(var/obj/effect/heretic_mansus_hazard/hazard as anything in hazards.Copy())
		if(world.time >= hazard.expires_at)
			qdel(hazard)
			continue
		if(!hazard.armed && world.time >= hazard.armed_at)
			hazard.armed = TRUE
			apply_style(hazard, "danger")
			hazard.alpha = 255
		if(hazard.armed && get_turf(victim) == get_turf(hazard))
			suffer_hazard(victim)
	if(memories_found && world.time >= next_hazard_at)
		next_hazard_at = world.time + (memories_found >= HERETIC_MANSUS_FINAL_PRESSURE ? rand(5, 7) : rand(7, 9)) * 1 SECONDS
		spawn_hazards()

/datum/heretic_mansus_visit/proc/spawn_hazards()
	if(finished || !contains(victim))
		return
	var/turf/center = get_turf(victim)
	var/list/positions = list(center)
	hazard_volleys++
	if(hazard_volleys % 2)
		var/direction = pick(NORTH, EAST)
		positions += get_step(center, direction)
		positions += get_step(center, turn(direction, 180))
	else
		var/direction = (victim.dir in GLOB.cardinals) ? victim.dir : (victim.dir & (NORTH | SOUTH))
		var/turf/ahead = center
		for(var/index in 2 to HERETIC_MANSUS_HAZARD_LINE)
			ahead = get_step(ahead, direction)
			if(!(ahead in walkable_turfs))
				break
			positions += ahead
	var/created_hazard = FALSE
	for(var/turf/position as anything in positions)
		if(!(position in walkable_turfs) || is_safe(position) || (locate(/obj/effect/heretic_mansus_hazard) in position))
			continue
		var/obj/effect/heretic_mansus_hazard/hazard = new(position, src)
		hazards += hazard
		created_hazard = TRUE
	if(created_hazard)
		playsound(victim, theme["warning"], 45, FALSE)

/datum/heretic_mansus_visit/proc/toggle_shutters()
	if(finished || !reservation)
		return
	shutter_phase = !shutter_phase
	set_shutters(shutter_phase ? shutters_b : shutters_a, TRUE)
	set_shutters(shutter_phase ? shutters_a : shutters_b, FALSE)
	update_route()

/datum/heretic_mansus_visit/proc/set_shutters(list/shutters, open)
	for(var/turf/shutter as anything in shutters)
		if(shutter.density == !open)
			continue
		if(open)
			shutter = shutter.ChangeTurf(/turf/open/indestructible/heretic_mansus/path)
			walkable_turfs += shutter
		else
			if((locate(/mob/living) in shutter) || (locate(/obj/effect/heretic_mansus_hunter) in shutter))
				animate(shutter, color = null, time = 0.2 SECONDS)
				continue
			for(var/obj/effect/heretic_mansus_hazard/hazard in shutter)
				qdel(hazard)
			walkable_turfs -= shutter
			shutter = shutter.ChangeTurf(/turf/closed/indestructible/heretic_mansus/shutter)
		style_turf(shutter)
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(shutter, direction)
			if(istype(neighbor, /turf/closed/indestructible/heretic_mansus))
				style_turf(neighbor)

/datum/heretic_mansus_visit/proc/arm_shift()
	shift_timer = addtimer(CALLBACK(src, PROC_REF(warn_shift)), HERETIC_MANSUS_SHIFT_INTERVAL - HERETIC_MANSUS_WARNING_TIME, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/warn_shift()
	shift_timer = addtimer(CALLBACK(src, PROC_REF(shift_shutters)), HERETIC_MANSUS_WARNING_TIME, TIMER_STOPPABLE)
	for(var/turf/shutter as anything in (shutter_phase ? shutters_b : shutters_a))
		animate(shutter, color = "#808080", time = HERETIC_MANSUS_WARNING_TIME)
	if(contains(victim))
		to_chat(victim, span_warning("Стены приходят в движение: потускневшие проходы вот-вот сомкнутся."))
		playsound(victim, theme["warning"], 35, FALSE)

/datum/heretic_mansus_visit/proc/shift_shutters()
	deltimer(shift_timer)
	shift_timer = null
	if(finished)
		return
	toggle_shutters()
	arm_shift()

/datum/heretic_mansus_visit/proc/spawn_hunter()
	var/obj/effect/heretic_mansus_hunter/hunter = new(entry_turf, src)
	hunters += hunter
	scenery += hunter
	reset_hunter(hunter)
	return hunter

/datum/heretic_mansus_visit/proc/reset_hunter(obj/effect/heretic_mansus_hunter/hunter)
	if(finished || QDELETED(hunter))
		return
	deltimer(hunter.step_timer)
	hunter.step_timer = null
	var/list/candidates = list()
	var/list/apart = list()
	for(var/turf/position as anything in walkable_turfs)
		if(get_dist(position, victim) < hunter_respawn_distance || is_safe(position))
			continue
		candidates += position
		var/crowded = FALSE
		for(var/obj/effect/heretic_mansus_hunter/other as anything in hunters)
			if(other != hunter && get_dist(position, other) < HERETIC_MANSUS_HUNTER_DISTANCE)
				crowded = TRUE
				break
		if(!crowded)
			apart += position
	if(length(candidates))
		hunter.alpha = 0
		hunter.forceMove(pick(length(apart) ? apart : candidates))
	hunter.ready_at = world.time + HERETIC_MANSUS_HUNTER_GRACE
	animate(hunter, alpha = twist == HERETIC_MANSUS_TWIST_UNSEEN ? 0 : 85, time = 0.5 SECONDS)
	if(danger_enabled)
		hunter.step_timer = addtimer(CALLBACK(src, PROC_REF(advance_hunter), hunter), HERETIC_MANSUS_HUNTER_GRACE, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/hunter_step_delay(obj/effect/heretic_mansus_hunter/hunter)
	var/step_delay = HERETIC_MANSUS_HUNTER_STEP
	if(memories_found >= HERETIC_MANSUS_FINAL_PRESSURE && length(hunters) && hunter == hunters[1])
		step_delay = HERETIC_MANSUS_HUNTER_FAST_STEP
	if(twist == HERETIC_MANSUS_TWIST_RELENTLESS && !QDELETED(victim) && (hunter.x == victim.x || hunter.y == victim.y))
		step_delay *= HERETIC_MANSUS_RELENTLESS_HASTE
	return step_delay

/datum/heretic_mansus_visit/proc/advance_hunter(obj/effect/heretic_mansus_hunter/hunter)
	if(QDELETED(hunter))
		return
	deltimer(hunter.step_timer)
	hunter.step_timer = null
	if(finished || !danger_enabled || QDELETED(victim) || !contains(victim))
		return
	var/step_delay = hunter_step_delay(hunter)
	if(world.time >= hunter.ready_at)
		move_hunter(hunter, step_delay)
		hunter.alpha = (twist == HERETIC_MANSUS_TWIST_UNSEEN && get_dist(hunter, victim) > HERETIC_MANSUS_UNSEEN_RANGE) ? 0 : 190
		if(get_turf(hunter) == get_turf(victim))
			suffer_hazard(victim)
	if(!hunter.step_timer && !finished)
		hunter.step_timer = addtimer(CALLBACK(src, PROC_REF(advance_hunter), hunter), step_delay, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/move_hunter(obj/effect/heretic_mansus_hunter/hunter, step_delay = HERETIC_MANSUS_HUNTER_STEP)
	var/turf/destination = get_turf(victim)
	var/turf/origin = get_turf(hunter)
	if(finished || !(destination in walkable_turfs) || !(origin in walkable_turfs) || is_safe(destination))
		return
	var/list/frontier = list(destination)
	var/list/next_steps = list()
	var/index = 1
	while(index <= length(frontier))
		var/turf/current = frontier[index++]
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current, direction)
			if(!(neighbor in walkable_turfs) || neighbor == destination || next_steps[neighbor])
				continue
			next_steps[neighbor] = current
			if(neighbor == origin)
				if(hunter.Move(current, get_dir(origin, current), DELAY_TO_GLIDE_SIZE(step_delay)))
					playsound(hunter, theme["step"], 40, FALSE)
				return
			frontier += neighbor

/datum/heretic_mansus_visit/proc/suffer_hazard(mob/user)
	if(finished || user != victim || !contains(user) || world.time < next_hazard_hit || is_safe(user))
		return FALSE
	next_hazard_hit = world.time + HERETIC_MANSUS_HIT_GRACE
	hits_taken++
	LAZYREMOVE(victim.do_afters, recalling_memory)
	LAZYREMOVE(victim.do_afters, gate)
	playsound(victim, theme["hit"], 50, FALSE)
	victim.Knockdown(1 SECONDS)
	if(carried_memory)
		carried_memory = null
		awaken_memory()
		to_chat(victim, span_userdanger("Дом вырвал несомый осколок и вернул его в комнату. Доставленные осколки остаются во вратах. Следуйте стрелкам, чтобы повторить попытку."))
	else
		to_chat(victim, span_warning("Чужая память сбивает вас с ног. Уходите с разлома и держитесь дальше от тени!"))
	for(var/obj/effect/heretic_mansus_hunter/hunter as anything in hunters)
		reset_hunter(hunter)
	log_game("Mansus: [key_name(victim)] hit [hits_taken] times, delivered [memories_found]/[HERETIC_MANSUS_MEMORIES].")
	return TRUE

/// Видения принадлежат комнате; они не наносят урон и не остаются после возвращения.
/datum/heretic_mansus_visit/proc/whisper(stage)
	if(finished || QDELETED(victim) || !contains(victim))
		return
	var/list/words = list("Кто-то за вашей спиной произносит ваше имя вашим же голосом.", "На мгновение в стене проступает лицо. Оно открывает рот одновременно с вами.", "Дом делает вдох. Врата дрожат; совсем скоро вас вытолкнет наружу.")
	to_chat(victim, span_warning(words[stage]))
	playsound(victim, theme["warning"], 25, FALSE)
	var/turf/shadow_turf = get_step(get_turf(victim), turn(victim.dir, 180))
	if(contains(shadow_turf) && !shadow_turf.density)
		var/obj/effect/heretic_mansus_echo/echo = new(shadow_turf)
		apply_style(echo, "hunter")
		echo.color = HERETIC_MANSUS_ECHO_TINT
		echo.alpha = 82
		echo.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		scenery += echo
		animate(echo, alpha = 0, time = 4 SECONDS)

/datum/heretic_mansus_visit/proc/on_victim_moved(datum/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	if(!finished && contains(victim))
		update_trail()
		if(twist == HERETIC_MANSUS_TWIST_SLICK && direction && !forced && !sliding)
			INVOKE_ASYNC(src, PROC_REF(slide_victim), direction)
		return
	if(!finished && !finish_pending && !contains(victim))
		finish_pending = TRUE
		timers += addtimer(CALLBACK(src, PROC_REF(finish), TRUE), 0, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/slide_victim(direction)
	var/turf/floor = get_turf(victim)
	if(finished || victim.stat != CONSCIOUS || istype(floor, /turf/open/indestructible/heretic_mansus/path) || is_safe(floor))
		return
	var/obj/effect/heretic_mansus_memory/memory = locate() in floor
	if(memory?.awake)
		return
	sliding = TRUE
	step(victim, direction)
	sliding = FALSE

/datum/heretic_mansus_visit/proc/on_victim_death()
	SIGNAL_HANDLER
	LAZYREMOVE(victim.do_afters, recalling_memory)
	// Этот сигнал предшествует set_stat(DEAD); сперва даём death() закончить работу.
	timers += addtimer(CALLBACK(src, PROC_REF(restore_victim)), 0.1 SECONDS, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/restore_victim()
	if(finished || QDELETED(victim) || victim.mind != soul || !contains(victim))
		return
	heal_victim()
	victim.grab_ghost()
	to_chat(victim, span_userdanger("Даже смерть не открывает эту дверь. Дом возвращает вам дыхание; путь наружу лежит через воспоминания."))

/datum/heretic_mansus_visit/proc/on_victim_deleted()
	SIGNAL_HANDLER
	finish()

/datum/heretic_mansus_visit/proc/on_soul_changed(datum/source, mob/new_body)
	SIGNAL_HANDLER
	// При удалении разума второй аргумент сигнала — force, а не новое тело.
	if(music_channel && ismob(new_body))
		new_body.stop_sound_channel(music_channel)
	// Возвращаем оставшееся тело; новый носитель разума не перемещается и не лечится.
	finish()

/datum/heretic_mansus_visit/proc/on_reservation_deleted()
	SIGNAL_HANDLER
	finish()

/datum/heretic_mansus_visit/proc/find_return_turf()
	if(return_turf && is_station_level(return_turf.z) && is_safe_turf(return_turf))
		return return_turf
	if(return_turf && is_station_level(return_turf.z))
		for(var/turf/nearby in range(7, return_turf))
			if(is_safe_turf(nearby))
				return nearby
	var/turf/safe = find_heretic_station_turf()
	if(safe)
		return safe
	if(fallback_turf && is_safe_turf(fallback_turf))
		return fallback_turf
	// При уничтожении станции всё равно покидаем резервную комнату.
	return return_turf || fallback_turf || get_turf(GET_ERROR_ROOM)

/// Единый идемпотентный выход для таймера, врат, удаления и смены тела.
/datum/heretic_mansus_visit/proc/finish(preserve_location = FALSE, delete_visit = TRUE, exit_reason = "interrupted")
	if(finished)
		return FALSE
	finish_pending = FALSE
	var/turf/destination = (started || reservation) ? find_return_turf() : null
	if((started || reservation) && !destination)
		finish_pending = TRUE
		timers += addtimer(CALLBACK(src, PROC_REF(finish), preserve_location, delete_visit, exit_reason), 5 SECONDS, TIMER_STOPPABLE)
		return FALSE
	finished = TRUE
	if(started)
		log_game("Mansus: [key_name(victim)] exited [theme["id"]], reason=[exit_reason], fragments=[memories_found]/[HERETIC_MANSUS_MEMORIES], hits=[hits_taken], duration=[(world.time - entered_at) / (1 SECONDS)] seconds.")
	STOP_PROCESSING(SSprocessing, src)
	deltimer(shift_timer)
	shift_timer = null
	QDEL_LIST(hazards)
	carried_memory = null
	walkable_turfs.Cut()
	route_steps.Cut()
	trail.Cut()
	recalling_memory = null
	for(var/timer in timers)
		deltimer(timer)
	timers.Cut()
	if(victim)
		victim.clear_alert(HERETIC_MANSUS_ALERT)
		UnregisterSignal(victim, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		REMOVE_TRAIT(victim, TRAIT_NOBREATH, REF(src))
		REMOVE_TRAIT(victim, TRAIT_NOFIRE, REF(src))
	if(music_channel)
		if(music_listener)
			SEND_SOUND(music_listener, sound(null, channel = music_channel))
		SSsounds.free_sound_channel(music_channel)
		music_channel = null
	music_listener = null
	if(soul)
		UnregisterSignal(soul, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING))
		if(GLOB.heretic_mansus_visits[soul] == src)
			GLOB.heretic_mansus_visits -= soul
	if(reservation)
		UnregisterSignal(reservation, COMSIG_PARENT_QDELETING)
	if(started && !QDELETED(victim))
		if(!preserve_location)
			heal_victim()
			victim.forceMove(destination)
		playsound(victim, theme["escape"], 45, FALSE)
		victim.AddComponent(/datum/component/heretic_mansus_trace)
		if(exit_reason == "completed")
			to_chat(victim, span_boldnotice("Имя, голос и дыхание снова ваши. Вы прошли испытание и открыли дверь домой. На коже остался бледный след врат."))
			SEND_SIGNAL(victim, COMSIG_ADD_MOOD_EVENT, "heretic_mansus", hits_taken ? /datum/mood_event/heretic_mansus_returned : /datum/mood_event/heretic_mansus_returned/unscathed)
		else if(exit_reason == "timeout")
			to_chat(victim, span_notice("Время истекло. Дом выталкивает вас наружу: доставлено [memories_found]/[HERETIC_MANSUS_MEMORIES] осколков. Недоставленное осталось в Доме и ещё какое-то время будет звать вас обратно. На коже остался бледный след незнакомой двери."))
			victim.apply_status_effect(/datum/status_effect/heretic_mansus_unreturned, (HERETIC_MANSUS_MEMORIES - memories_found) * HERETIC_MANSUS_PENALTY_PER_MEMORY)
		else
			to_chat(victim, span_notice("Стены Дома смыкаются за спиной. На коже остался бледный след незнакомой двери."))
	// Возвращаем также брошенные вещи, контейнеры и посторонних: Release() уничтожает содержимое.
	QDEL_LIST(scenery)
	if(reservation)
		for(var/turf/reserved in reservation.reserved_turfs)
			for(var/atom/movable/thing in reserved.contents.Copy())
				if(!QDELETED(thing) && !istype(thing, /atom/movable/lighting_object))
					thing.forceMove(destination)
		if(!QDELETED(reservation))
			qdel(reservation)
	reservation = null
	room = null
	memories.Cut()
	gate = null
	offering = null
	victim = null
	soul = null
	if(delete_visit)
		qdel(src)
	return TRUE

/// Амнезия относится к похищению; прежние записи и знания персонажа остаются на месте.
/datum/heretic_mansus_visit/proc/record_mansus_memory()
	var/recollection = "Само похищение распалось на белые пятна: лицо, голос и имя того, кто отправил вас в Мансус, не вспоминаются. По воспоминаниям о похищении вы не можете опознать этого человека — ни в Мансусе, ни после возвращения. Всё, что вы знали и видели до похищения, вы помните по-прежнему."
	soul.store_memory(recollection)
	if(soul.current)
		to_chat(soul.current, span_boldnotice(recollection))

/obj/effect/heretic_mansus_memory
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_memory"
	name = "memory of the waking world"
	desc = "Пока это лишь тусклый отголосок. Найдите яркий осколок и доставьте его к северным вратам, чтобы пробудить следующий."
	alpha = 85
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/datum/heretic_mansus_visit/visit
	var/recollection
	var/recalled = FALSE
	var/awake = FALSE
	var/delivered = FALSE
	var/chamber

/obj/effect/heretic_mansus_memory/Initialize(mapload, datum/heretic_mansus_visit/new_visit, words)
	. = ..()
	visit = new_visit
	recollection = words
	visit?.apply_style(src, "memory")

/obj/effect/heretic_mansus_memory/Destroy()
	visit = null
	return ..()

/obj/effect/heretic_mansus_memory/attack_hand(mob/user)
	if(visit)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, collect_memory), src, user)

/obj/effect/heretic_mansus_memory/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser) && visit)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, collect_memory), src, crosser)

/obj/effect/heretic_mansus_gate
	icon = 'modular_bluemoon/icons/obj/heretic_mansus_gates.dmi'
	icon_state = "ash_gate_closed"
	name = "door to the waking world"
	desc = "Доставьте три осколка на светящуюся печать перед вратами. Здесь можно укрыться от тени и разломов."
	pixel_x = -16
	pixel_y = 0
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/datum/heretic_mansus_visit/visit
	var/opened = FALSE

/obj/effect/heretic_mansus_gate/examine(mob/user)
	. = ..()
	if(!visit || user != visit.victim)
		return
	. += span_notice("Воспоминания: [visit.memories_found]/[HERETIC_MANSUS_MEMORIES]. Автоматическое возвращение через [DisplayTimeText(max(0, visit.forced_exit - world.time))].")
	. += span_notice((visit.carried_memory ? "Вы несёте осколок. Коснитесь врат или встаньте на них, чтобы закрепить его." : "Найдите яркий осколок. Уже закреплённые осколки не теряются."))

/obj/effect/heretic_mansus_gate/Initialize(mapload, datum/heretic_mansus_visit/new_visit)
	. = ..()
	visit = new_visit
	visit?.apply_style(src, "gate_closed")

/obj/effect/heretic_mansus_gate/Destroy()
	visit = null
	return ..()

/obj/effect/heretic_mansus_gate/attack_hand(mob/user)
	if(visit)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, try_exit), user)

/obj/effect/heretic_mansus_gate/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser) && visit)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, try_exit), crosser)

/obj/effect/heretic_mansus_echo
	name = "someone almost familiar"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/heretic_mansus_statue
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_decor"
	name = "shrine of a stranger's memory"
	desc = "Здесь хранится что-то, чего вы никогда не переживали."
	anchored = TRUE
	density = TRUE

/obj/effect/heretic_mansus_statue/Initialize(mapload, datum/heretic_mansus_visit/visit)
	. = ..()
	visit?.apply_style(src, "decor")
	if(visit)
		desc = visit.theme["description"]

/obj/effect/heretic_mansus_candle
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_light"
	name = "memory flame"
	desc = "Бледное пламя склоняется к галерее. Оно не греет и не сжигает воск."
	anchored = TRUE

/obj/effect/heretic_mansus_candle/Initialize(mapload, datum/heretic_mansus_visit/visit)
	. = ..()
	visit?.apply_style(src, "light")
	if(visit)
		desc = visit.theme["description"]

/atom/movable/screen/alert/heretic_mansus
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_memory"
	name = "Дом памяти"
	desc = "Соберите осколки и доставьте их к северным вратам."
	maptext_width = 32
	maptext_height = 12

/atom/movable/screen/alert/heretic_mansus/Click(location, control, params)
	if(!..())
		return
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[owner?.mind]
	if(!visit || visit.victim != owner)
		return
	visit.update_guidance()
	visit.update_trail()
	to_chat(owner, span_notice(desc))
	if(visit.carried_memory)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, try_exit), owner)
	else
		var/obj/effect/heretic_mansus_memory/memory = visit.memories[visit.memories_found + 1]
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, collect_memory), memory, owner)

/obj/effect/heretic_mansus_trail
	name = "memory trail"
	desc = "Стрелка указывает путь к осколку или к печати. Она не предупреждает об опасности: следите за трещинами и тенью."
	icon = 'modular_bluemoon/icons/obj/heretic_mansus_guidance.dmi'
	icon_state = "trail"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = TURF_LAYER + 0.1
	alpha = 0

/obj/effect/heretic_mansus_offering
	name = "seal of return"
	desc = "Остановитесь на печати с осколком на одну секунду, чтобы закрепить его. Три огня откроют выход. Печать и соседние клетки защищают от тени и разломов."
	icon = 'modular_bluemoon/icons/obj/heretic_mansus_guidance.dmi'
	icon_state = "offering0"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	var/datum/heretic_mansus_visit/visit

/obj/effect/heretic_mansus_sanctuary
	name = "ward of the seal"
	icon = 'modular_bluemoon/icons/obj/heretic_mansus_guidance.dmi'
	icon_state = "sanctuary"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = TURF_LAYER + 0.1

/obj/effect/heretic_mansus_offering/Initialize(mapload, datum/heretic_mansus_visit/new_visit)
	. = ..()
	visit = new_visit

/obj/effect/heretic_mansus_offering/Destroy()
	visit = null
	return ..()

/obj/effect/heretic_mansus_offering/attack_hand(mob/user)
	if(visit)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, try_exit), user)

/obj/effect/heretic_mansus_offering/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser) && visit)
		INVOKE_ASYNC(visit, TYPE_PROC_REF(/datum/heretic_mansus_visit, try_exit), crosser)

/obj/effect/heretic_mansus_hazard
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_warning"
	name = "crack of oblivion"
	desc = "Уходите с отмеченной клетки до вспышки: разлом выбивает несомый осколок."
	alpha = 255
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = BELOW_MOB_LAYER
	var/datum/heretic_mansus_visit/visit
	var/armed = FALSE
	var/armed_at
	var/expires_at

/obj/effect/heretic_mansus_hazard/Initialize(mapload, datum/heretic_mansus_visit/new_visit)
	. = ..()
	visit = new_visit
	visit?.apply_style(src, "warning")
	armed_at = world.time + HERETIC_MANSUS_WARNING_TIME
	expires_at = armed_at + (visit?.hazard_lifetime || HERETIC_MANSUS_HAZARD_LIFETIME)

/obj/effect/heretic_mansus_hazard/Destroy()
	visit?.hazards -= src
	visit = null
	return ..()

/obj/effect/heretic_mansus_hazard/Crossed(atom/movable/crosser)
	. = ..()
	if(armed && world.time < expires_at && ismob(crosser))
		visit?.suffer_hazard(crosser)

/obj/effect/heretic_mansus_hunter
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_hunter"
	name = "shade of oblivion"
	desc = "Она идёт по галерее за вами. Не подпускайте её к себе: тень вырывает несомый осколок. Возле северных врат безопасно."
	anchored = TRUE
	animate_movement = SLIDE_STEPS
	appearance_flags = TILE_BOUND | PIXEL_SCALE | LONG_GLIDE
	layer = ABOVE_MOB_LAYER
	var/datum/heretic_mansus_visit/visit
	var/ready_at = 0
	var/step_timer

/obj/effect/heretic_mansus_hunter/Initialize(mapload, datum/heretic_mansus_visit/new_visit)
	. = ..()
	visit = new_visit
	visit?.apply_style(src, "hunter")

/obj/effect/heretic_mansus_hunter/Destroy()
	deltimer(step_timer)
	step_timer = null
	visit?.hunters -= src
	visit = null
	return ..()

/obj/effect/heretic_mansus_hunter/Crossed(atom/movable/crosser)
	. = ..()
	if(visit && world.time >= ready_at && ismob(crosser))
		visit.suffer_hazard(crosser)

/// Часть памяти осталась в Доме: дрожь, шёпот и подавленность, без урона и стана.
/datum/status_effect/heretic_mansus_unreturned
	id = "heretic_mansus_unreturned"
	tick_interval = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_mansus_unreturned

/datum/status_effect/heretic_mansus_unreturned/on_creation(mob/living/new_owner, set_duration)
	if(set_duration)
		duration = set_duration
	return ..()

/datum/status_effect/heretic_mansus_unreturned/on_apply()
	. = ..()
	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "heretic_mansus", /datum/mood_event/heretic_mansus_unreturned)

/datum/status_effect/heretic_mansus_unreturned/on_remove()
	. = ..()
	SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "heretic_mansus")
	to_chat(owner, span_notice("Зов Дома памяти стихает. То, что осталось за вратами, больше не тянет вас назад."))

/datum/status_effect/heretic_mansus_unreturned/tick()
	owner.Jitter(5)
	to_chat(owner, span_warning(pick("Кто-то зовёт вас по имени, которое вы не донесли до врат.", "Собственный голос на мгновение кажется чужим.", "Вы ловите себя на том, что забыли вдохнуть.")))

/atom/movable/screen/alert/status_effect/heretic_mansus_unreturned
	name = "Недовозвращённый"
	desc = "Часть вашей памяти осталась в Доме. Пока зов не стихнет, вас будет бить дрожь и преследовать чужой шёпот."
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_memory"

/datum/mood_event/heretic_mansus_unreturned
	description = span_warning("Часть меня осталась за той дверью. Я слышу, как она зовёт.\n")
	mood_change = -6

/datum/mood_event/heretic_mansus_returned
	description = span_nicegreen("Я вернул себе имя, голос и дыхание. Дом меня отпустил.\n")
	mood_change = 2
	timeout = 5 MINUTES

/datum/mood_event/heretic_mansus_returned/unscathed
	description = span_nicegreen("Я прошёл Дом памяти, и он ни разу меня не коснулся.\n")
	mood_change = 4

/// Косметический след остаётся на этом теле до конца раунда, не меняя органы или память.
/datum/component/heretic_mansus_trace
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/heretic_mansus_trace/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_mansus_trace/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("На коже проступает бледный контур двери. Стоит отвести взгляд — и кажется, что она приоткрылась.")

#undef HERETIC_MANSUS_DURATION
#undef HERETIC_MANSUS_ECHO_TINT
#undef HERETIC_MANSUS_RECALL_TIME
#undef HERETIC_MANSUS_ROOM_SIZE
#undef HERETIC_MANSUS_MEMORIES
#undef HERETIC_MANSUS_WARNING_TIME
#undef HERETIC_MANSUS_HAZARD_LIFETIME
#undef HERETIC_MANSUS_HIT_GRACE
#undef HERETIC_MANSUS_HUNTER_GRACE
#undef HERETIC_MANSUS_GATE_SAFETY
#undef HERETIC_MANSUS_GATE_CLEARANCE
#undef HERETIC_MANSUS_TRAIL_LENGTH
#undef HERETIC_MANSUS_FINAL_PRESSURE
#undef HERETIC_MANSUS_HUNTER_STEP
#undef HERETIC_MANSUS_HUNTER_FAST_STEP
#undef HERETIC_MANSUS_HUNTER_DISTANCE
#undef HERETIC_MANSUS_RELENTLESS_DISTANCE
#undef HERETIC_MANSUS_RELENTLESS_HASTE
#undef HERETIC_MANSUS_UNSEEN_RANGE
#undef HERETIC_MANSUS_SHIFT_INTERVAL
#undef HERETIC_MANSUS_PENALTY_PER_MEMORY
#undef HERETIC_MANSUS_TWIST_SLICK
#undef HERETIC_MANSUS_TWIST_UNSEEN
#undef HERETIC_MANSUS_TWIST_LINGERING
#undef HERETIC_MANSUS_TWIST_SHIFTING
#undef HERETIC_MANSUS_TWIST_RELENTLESS
#undef HERETIC_MANSUS_LINGERING_LIFETIME
#undef HERETIC_MANSUS_HAZARD_LINE
#undef HERETIC_MANSUS_TRAIL_CARRY_LENGTH
#undef HERETIC_MANSUS_ALERT
