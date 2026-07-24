/// Размер стороны чанка в турфах
#define CHUNK_GRID_STEP 10
/// Индекс чанковой ячейки для координаты
#define CHUNK_GRID_ELEM(value) CEILING((value) / CHUNK_GRID_STEP, 1)
/// Свежесть хэша: перестраиваем не чаще раза в это окно (шаг паса Life)
#define CHUNK_HASH_TTL (2 SECONDS)
/// Ключ-часовой для мобов без фракций: он не входит ни в один список фракций,
/// поэтому такие мобы читаются как "чужие" для любого охотника
#define CHUNK_FACTION_NONE "\[no_faction]"

/**
 * SSchunks (порт TauCetiClassic): дешёвый спатиал-хэш фракций живых мобов.
 *
 * Hostile-мобы в ListTargets() зовут hearers(vision_range) - нативный view-скан
 * на каждый пасс AI, даже когда вокруг на пол-экрана никого нет. Хэш
 * перестраивается один раз в начале каждого fire SSmobs (pull-модель: обход
 * living_list, O(мобов)), после чего "есть ли рядом чужая фракция" - это
 * несколько словарных проверок вместо hearers().
 *
 * Багфиксы против оригинала TauCeti: у них верхняя граница по Y клампилась
 * world.maxx (chunks.dm:52), а hostile-вызов передавал vision_range на место
 * аргумента faction. Здесь оба исправлены, фракции у нас - списки.
 */
SUBSYSTEM_DEF(chunks)
	name = "Chunks"
	flags = SS_NO_INIT | SS_NO_FIRE // перестраивается лениво из ensure_fresh()
	var/tick = 0
	var/list/grid = list()
	///world.time, до которого текущий хэш считается свежим
	var/next_rebuild_time = 0

/datum/controller/subsystem/chunks/stat_entry(msg)
	msg = "Z:[length(grid)] t:[tick]"
	return ..()

/// Ленивая актуализация: хэш строится не чаще раза в CHUNK_HASH_TTL и только
/// когда его действительно кто-то спрашивает. На сервере без охотящихся
/// hostile-мобов перестроек нет вообще.
/datum/controller/subsystem/chunks/proc/ensure_fresh()
	if(world.time < next_rebuild_time)
		return
	next_rebuild_time = world.time + CHUNK_HASH_TTL
	rebuild()

/// Полная перестройка хэша (обход living_list, O(мобов)).
/// Ленивая инвалидация: сами ячейки чистятся при первом касании нового tick.
/datum/controller/subsystem/chunks/proc/rebuild()
	while(grid.len < world.maxz)
		add_level()
	tick += 1
	for(var/mob/living/living_mob as anything in GLOB.mob_living_list)
		if(QDELETED(living_mob) || living_mob.stat == DEAD)
			continue
		hash_mob(living_mob)

/datum/controller/subsystem/chunks/proc/add_level()
	var/x_size = CHUNK_GRID_ELEM(world.maxx)
	var/y_size = CHUNK_GRID_ELEM(world.maxy)
	var/list/z_grid[x_size][y_size]
	grid += list(z_grid)
	for(var/x in 1 to x_size)
		for(var/y in 1 to y_size)
			z_grid[x][y] = new /datum/mob_chunk

/datum/controller/subsystem/chunks/proc/hash_mob(mob/living/living_mob)
	var/turf/mob_turf = get_turf(living_mob)
	if(!mob_turf || mob_turf.z > grid.len)
		return
	var/datum/mob_chunk/zone = grid[mob_turf.z][CHUNK_GRID_ELEM(mob_turf.x)][CHUNK_GRID_ELEM(mob_turf.y)]
	zone.add_factions(living_mob.faction)

/datum/controller/subsystem/chunks/proc/get_chunks_in_range(atom/center, range)
	var/turf/center_turf = get_turf(center)
	if(!center_turf || center_turf.z > grid.len)
		return null
	var/list/z_grid = grid[center_turf.z]
	var/x_start = CHUNK_GRID_ELEM(max(1, (center_turf.x - range)))
	var/x_end = CHUNK_GRID_ELEM(min(world.maxx, center_turf.x + range))
	var/y_start = CHUNK_GRID_ELEM(max(1, (center_turf.y - range)))
	// Оригинал TauCeti клампил по world.maxx - на картах с maxy != maxx это
	// либо слепые чанки у верхнего края, либо выход за границы списка.
	var/y_end = CHUNK_GRID_ELEM(min(world.maxy, center_turf.y + range))
	. = list()
	for(var/x_index in x_start to x_end)
		for(var/y_index in y_start to y_end)
			. += z_grid[x_index][y_index]

/// TRUE если в радиусе есть хоть одна фракция, НЕ входящая в faction_list
/// (наши фракции - списки, в отличие от строк TauCeti). Ложные срабатывания
/// допустимы (дальше всё равно идёт честный hearers()), ложные пропуски - нет.
/datum/controller/subsystem/chunks/proc/has_enemy_faction(atom/center, list/faction_list, range)
	ensure_fresh()
	if(!tick) // хэш ещё ни разу не строился - не гейтим
		return TRUE
	for(var/datum/mob_chunk/chunk as anything in get_chunks_in_range(center, range))
		if(chunk.has_faction_outside(faction_list))
			return TRUE
	return FALSE

/// TRUE если в радиусе есть хоть одна фракция из faction_list
/datum/controller/subsystem/chunks/proc/has_ally_faction(atom/center, list/faction_list, range)
	ensure_fresh()
	if(!tick)
		return TRUE
	for(var/datum/mob_chunk/chunk as anything in get_chunks_in_range(center, range))
		if(chunk.has_faction_inside(faction_list))
			return TRUE
	return FALSE

/datum/mob_chunk
	var/last_updated
	/// Ассоц-набор фракционных строк мобов в чанке за текущий tick
	var/list/factions

/datum/mob_chunk/proc/update()
	if(last_updated == SSchunks.tick)
		return
	last_updated = SSchunks.tick
	factions = null

/datum/mob_chunk/proc/add_factions(list/mob_factions)
	update()
	if(!length(mob_factions)) //бесфракционный моб обязан читаться как чужой для всех
		LAZYSET(factions, CHUNK_FACTION_NONE, TRUE)
		return
	for(var/faction_entry in mob_factions)
		LAZYSET(factions, faction_entry, TRUE)

/datum/mob_chunk/proc/has_faction_outside(list/faction_list)
	update()
	for(var/faction_entry in factions)
		if(!(faction_entry in faction_list))
			return TRUE
	return FALSE

/datum/mob_chunk/proc/has_faction_inside(list/faction_list)
	update()
	for(var/faction_entry in faction_list)
		if(LAZYACCESS(factions, faction_entry))
			return TRUE
	return FALSE

#undef CHUNK_FACTION_NONE
#undef CHUNK_HASH_TTL
#undef CHUNK_GRID_ELEM
#undef CHUNK_GRID_STEP
