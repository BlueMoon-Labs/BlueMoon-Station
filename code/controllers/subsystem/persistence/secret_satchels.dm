/**
 * Secret satchel persistence - allows storing of items in underfloor satchels that's loaded later.
 */

/// Сколько записей пула тайных сатчелов переживают закрытие раунда.
/// За раунд из пула забирается РОВНО ОДНА запись (LoadSatchels), а дописывается по одной
/// на каждый спрятанный игроками сатчел - без капа файл растёт вечно. На проде (раунд
/// 10119) в нём лежало 17 752 записи: ~4 МБ живых assoc-списков плюс json_encode одной
/// непрерывной строкой на каждом закрытии раунда, а такая аллокация на 32-битном
/// DreamDaemon и есть тот способ умереть, при котором до потолка ещё гигабайт.
/// Пул - лотерея чужого лута, глубина истории важна только на порядок: 500 записей это
/// примерно полсотни раундов.
#define SECRET_SATCHEL_POOL_CAP 500

/datum/controller/subsystem/persistence
	var/list/satchel_blacklist 		= list() //this is a typecache
	var/list/new_secret_satchels 	= list() //these are objects
	var/list/old_secret_satchels 	= list()

/// Оставляет в пуле только самые свежие cap записей. Старьё уходит первым: свежие сатчелы
/// спрятаны в этом раунде, древние лежат в файле десятками раундов.
/proc/trim_satchel_pool(list/pool, cap = SECRET_SATCHEL_POOL_CAP)
	// islist явно: у строки в DM есть и length(), и Copy(), поэтому битый json без этой
	// проверки молча проехал бы дальше куском текста вместо пула
	if(!islist(pool) || !length(pool))
		return list()
	if(length(pool) <= cap)
		return pool
	return pool.Copy(length(pool) - cap + 1)

/datum/controller/subsystem/persistence/LoadGamePersistence()
	. = ..()
	LoadSatchels()

/datum/controller/subsystem/persistence/SaveGamePersistence()
	. = ..()
	CollectSecretSatchels()

/datum/controller/subsystem/persistence/proc/LoadSatchels()
	var/placed_satchel = 0
	var/path

	var/json_file = file("data/npc_saves/SecretSatchels[SSmapping.config.map_name].json")
	var/list/json = list()
	if(fexists(json_file))
		json = json_decode(file2text(json_file))

	// Кап на входе, а не только на выходе: без него уже накопленный файл целиком висит в
	// памяти весь раунд, и выигрыш пришёл бы только со следующего.
	old_secret_satchels = trim_satchel_pool(json["data"])
	var/obj/item/storage/backpack/satchel/flat/F
	if(old_secret_satchels && old_secret_satchels.len >= 10) //guards against low drop pools assuring that one player cannot reliably find his own gear.
		var/pos = rand(1, old_secret_satchels.len)
		// Read the entry *before* removing it from the list — the previous code did Cut(pos, pos+1)
		// and then indexed old_secret_satchels[pos], which is out of bounds when pos was the last
		// element and runs as a runtime error in every other case (reads a shifted neighbour).
		var/list/picked = old_secret_satchels[pos]
		old_secret_satchels.Cut(pos, pos + 1)
		F = new()
		F.x = picked["x"]
		F.y = picked["y"]
		F.z = SSmapping.station_start
		path = text2path(picked["saved_obj"])

	if(F)
		if(isfloorturf(F.loc) && !isplatingturf(F.loc))
			F.hide(1)
		if(ispath(path))
			var/spawned_item = new path(F)
			spawned_objects[spawned_item] = TRUE
		placed_satchel++
	var/free_satchels = 0
	for(var/turf/T in shuffle(block(locate(TRANSITIONEDGE,TRANSITIONEDGE,SSmapping.station_start), locate(world.maxx-TRANSITIONEDGE,world.maxy-TRANSITIONEDGE,SSmapping.station_start)))) //Nontrivially expensive but it's roundstart only
		if(isfloorturf(T) && !isplatingturf(T))
			new /obj/item/storage/backpack/satchel/flat/secret(T)
			free_satchels++
			if((free_satchels + placed_satchel) == 10) //ten tiles, more than enough to kill anything that moves
				break

/datum/controller/subsystem/persistence/proc/CollectSecretSatchels()
	satchel_blacklist = typecacheof(list(/obj/item/stack/tile/plasteel, /obj/item/crowbar))
	var/list/satchels_to_add = list()
	for(var/A in new_secret_satchels)
		var/obj/item/storage/backpack/satchel/flat/F = A
		if(QDELETED(F) || F.z != SSmapping.station_start || F.invisibility != INVISIBILITY_MAXIMUM)
			continue
		var/list/savable_obj = list()
		for(var/obj/O in F)
			if(is_type_in_typecache(O, satchel_blacklist) || (O.flags_1 & ADMIN_SPAWNED_1))
				continue
			if(O.persistence_replacement)
				savable_obj += O.persistence_replacement
			else
				savable_obj += O.type
		if(isemptylist(savable_obj))
			continue
		var/list/data = list()
		data["x"] = F.x
		data["y"] = F.y
		data["saved_obj"] = pick(savable_obj)
		satchels_to_add += list(data)

	var/json_file = file("data/npc_saves/SecretSatchels[SSmapping.config.map_name].json")
	var/list/file_data = list()
	fdel(json_file)
	file_data["data"] = trim_satchel_pool(old_secret_satchels + satchels_to_add)
	WRITE_FILE(json_file, json_encode(file_data))
