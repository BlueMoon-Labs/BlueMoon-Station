/// Сколько шкафов оживёт за событие
#define CLOSET_SKELETONS_MIN 4
#define CLOSET_SKELETONS_MAX 7
/// Шанс лязга на каждый тик тряски у каждого шкафа
#define CLOSET_SKELETONS_RATTLE_SOUND_PROB 40

/// Скелеты в шкафах (порт идеи goonstation): несколько закрытых шкафов по станции
/// начинают греметь и трястись, а спустя десяток секунд распахиваются - изнутри лезут
/// оживлённые скелеты. Буквализация поговорки: у каждого отдела свои скелеты в шкафу.
/// Скелеты хрупкие (40 хп), это спук и разминка, а не боевая тревога.
/datum/round_event_control/closet_skeletons
	name = "Closet Skeletons"
	typepath = /datum/round_event/closet_skeletons
	weight = 12
	max_occurrences = 2
	earliest_start = 25 MINUTES
	min_players = 10
	category = EVENT_CATEGORY_ENTITIES
	// Категория ENTITIES по умолчанию даёт MAJOR; горстка ломких скелетов - средний хаос
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "Several lockers rattle for a while, then burst open with reanimated skeletons."

/datum/round_event/closet_skeletons
	fakeable = FALSE
	start_when = 1
	announce_when = 2
	announce_chance = 75
	// ~десять секунд грохота между началом тряски и вылезанием
	end_when = 6
	/// Шкафы, из которых полезут скелеты
	var/list/obj/structure/closet/haunted = list()

/datum/round_event/closet_skeletons/announce(fake)
	priority_announce("В вашем секторе зафиксирована некротическая аномалия низкой интенсивности. Возможна спонтанная реанимация костных останков в замкнутых объёмах хранения.", "Отдел Паранормальных Явлений")

/datum/round_event/closet_skeletons/start()
	var/list/obj/structure/closet/candidates = list()
	for(var/obj/structure/closet/hideout in world)
		// Каламбур именно про шкафы: ящики карго с гремящими костями - уже другой жанр
		if(istype(hideout, /obj/structure/closet/crate))
			continue
		var/turf/hideout_turf = get_turf(hideout)
		if(!hideout_turf || !is_station_level(hideout_turf.z))
			continue
		// Заваренные и запертые не трогаем: ломать замки секурных шкафчиков - уже не шутка
		if(hideout.opened || hideout.welded || hideout.locked)
			continue
		candidates += hideout
		CHECK_TICK
	if(!length(candidates))
		return kill()
	for(var/i in 1 to min(rand(CLOSET_SKELETONS_MIN, CLOSET_SKELETONS_MAX), length(candidates)))
		haunted += pick_n_take(candidates)

/datum/round_event/closet_skeletons/tick()
	for(var/obj/structure/closet/hideout as anything in haunted)
		if(QDELETED(hideout) || hideout.opened)
			haunted -= hideout
			continue
		hideout.shake_animation(rand(4, 6))
		if(prob(CLOSET_SKELETONS_RATTLE_SOUND_PROB))
			playsound(hideout, pick('sound/effects/clangsmall1.ogg', 'sound/effects/clangsmall2.ogg'), 50, TRUE)

/datum/round_event/closet_skeletons/end()
	var/announced_to_ghosts = FALSE
	for(var/obj/structure/closet/hideout as anything in haunted)
		if(QDELETED(hideout))
			continue
		var/turf/hideout_turf = get_turf(hideout)
		if(!hideout_turf)
			continue
		// open(force), а не bust_open(): последний метит шкаф broken и ломает замки навсегда
		if(!hideout.opened)
			hideout.open(force = TRUE)
		var/mob/living/simple_animal/hostile/skeleton/bones = new(hideout_turf)
		if(!announced_to_ghosts)
			announced_to_ghosts = TRUE
			announce_to_ghosts(bones)
	haunted.Cut()

#undef CLOSET_SKELETONS_MIN
#undef CLOSET_SKELETONS_MAX
#undef CLOSET_SKELETONS_RATTLE_SOUND_PROB
