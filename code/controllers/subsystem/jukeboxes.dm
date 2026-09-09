//As a brief warning to all those who dare tread upon these grounds:
//The bulk of this code here was written years ago, back in the days of 512.
//We were incredibly drunk back then. And nowadays, we've found that being drunk is a hard requirement for working with this code.
//So if you're here to make changes? Brandish a glass. There are many sins here, but it's exactly as engineered as it needs to be.
//We physically won't be able to tell you what half of this code does. The only thing that'll help you here is the ballmer peak.
//Bottoms up, friend. And be sure to drink responsibly. Be sure to fetch some water, too; it eases the hangover. - Bhijn & Myr


// Jukelist indices
#define JUKE_TRACK 1
#define JUKE_CHANNEL 2
#define JUKE_BOX 3
#define JUKE_FALLOFF 4
#define JUKE_SOUND 5
#define JUKE_PERSONAL 6
/// Ассоциативный список ckey тех, кому ресурс трека уже отправлен и у кого занят канал.
/// Ключ - именно ckey, а не клиент: переподключившийся игрок трек не догонит, но и до этой
/// правки он его не догонял, потому что рассылка была разовой на старте.
#define JUKE_SENT 7
/// Ограничение зоны: area либо номер комнаты отеля. Пересчитывается каждый fire()
/// по ТЕКУЩЕЙ зоне джукбокса - переносной автомат выносят из комнаты в руках.
#define JUKE_AREA_LIMIT 8
/// world.time старта трека. Запасной отсчёт для подхвата, если реальное время не снято
#define JUKE_START 9
/// REALTIMEOFDAY старта трека - основной отсчёт для подхвата опоздавшего слушателя
#define JUKE_START_REAL 10

/// Радиус, за пределами которого джукбокс слышно только внутри его собственной зоны
#define JUKEBOX_HEARING_RANGE 7
/// Доля громкости прямого звука, ниже которой личной шкатулке незачем слать файл: BYOND гасит
/// звук как falloff / d в единицах звука, при громкости 70 (falloff 2) это 16 тайлов.
#define JUKEBOX_AUDIBLE_GAIN 0.05

// Координаты звука относительно слушателя - те же, что кладутся в /sound. Одна формула на
// рассылку и на отправку, чтобы радиус досылки не разъезжался с тем, что реально слышно.
#define JUKEBOX_SOUND_X(source, listener) ((source.x - listener.x) * SOUND_DEFAULT_DISTANCE_MULTIPLIER)
#define JUKEBOX_SOUND_Z(source, listener) ((source.y - listener.y) * SOUND_DEFAULT_DISTANCE_MULTIPLIER)
#define JUKEBOX_SOUND_Y(source, listener) (((source.z - listener.z) * 10 * SOUND_DEFAULT_DISTANCE_MULTIPLIER) + ((source.z < listener.z) ? -5 : 5))

// Track data
/// Name of the track
#define TRACK_NAME 1
/// Length of the track (in deciseconds)
#define TRACK_LENGTH 2
/// BPM of the track (in deciseconds)
#define TRACK_BEAT 3
/// Unique code-facing identifier for this track
#define TRACK_ID 4


SUBSYSTEM_DEF(jukeboxes)
	name = "Jukeboxes"
	wait = 5
	priority = FIRE_PRIORITY_SOUND_LOOPS
	var/list/songs = list()
	var/list/song_names = list()
	var/list/songs_by_name = list()
	var/list/activejukeboxes = list()
	var/list/freejukeboxchannels = list()

/datum/track
	var/song_name = "generic"
	var/song_path = null
	var/song_length = 0
	var/song_beat = 0
	var/song_associated_id = null

/datum/track/New(name, path, length, beat, assocID)
	song_name = name
	song_path = path
	song_length = length
	song_beat = beat
	song_associated_id = assocID

/datum/controller/subsystem/jukeboxes/proc/jukebox_sound_enabled(mob/M, personal = FALSE)
	if(!M.client?.prefs)
		return FALSE
	if(personal)
		return M.client.prefs.toggles & SOUND_PERSONAL_JUKEBOXES
	return M.client.prefs.toggles & SOUND_JUKEBOXES

/datum/controller/subsystem/jukeboxes/proc/addjukebox(obj/jukebox, datum/track/T, jukefalloff = 1, personal = FALSE) //BLUEMOON EDIT
	if(!istype(T))
		CRASH("[src] tried to play a song with a nonexistant track")
	var/channeltoreserve = pick(freejukeboxchannels)
	if(!channeltoreserve)
		return FALSE
	var/area/juke_area = get_area(jukebox)
	var/one_area_play = get_jukebox_area_limit(juke_area) // Зона, в которой будет играть музыка, если есть ограничения
	var/sound/song_to_init = sound(T.song_path)
	freejukeboxchannels -= channeltoreserve
	var/list/sent_to = list() // Кому ресурс уже ушёл; остальным он досылается в fire(), когда подойдут
	var/list/youvegotafreejukebox = list(T, channeltoreserve, jukebox, jukefalloff, song_to_init, personal, sent_to, one_area_play, world.time, REALTIMEOFDAY)

	song_to_init.status = SOUND_MUTE
	song_to_init.environment = 7
	song_to_init.channel = channeltoreserve
	song_to_init.volume = 1
	song_to_init.falloff = jukefalloff
	song_to_init.echo = list(0, null, -10000, null, null, null, null, null, null, null, null, null, null, 1, 1, 1, null, null)

	activejukeboxes.len++
	activejukeboxes[activejukeboxes.len] = youvegotafreejukebox

	// SEND_SOUND тянет клиенту весь файл трека: стартовая рассылка только тем, кому он слышен,
	// остальным fire() дошлёт по факту входа в радиус.
	var/turf/juke_turf = get_turf(jukebox)
	var/list/audible_zlevels = juke_turf ? get_multiz_accessible_levels(juke_turf.z) : list()
	var/list/hearerscache = hearers(JUKEBOX_HEARING_RANGE, jukebox)
	for(var/mob/M in GLOB.player_list)
		if(!M.client)
			continue
		if(!M.client.prefs)
			continue
		if(!jukebox_sound_enabled(M, personal))
			continue
		if(!jukebox_area_allows(M, jukebox, one_area_play))
			continue
		if(get_area(M) != juke_area && !(M in hearerscache) && !jukebox_within_earshot(juke_turf, get_turf(M), jukefalloff, audible_zlevels, personal))
			continue
		SEND_SOUND(M, song_to_init)
		sent_to[M.ckey] = TRUE
	return activejukeboxes.len

/// Слышен ли прямой звук трека с такой громкостью на таком удалении (координаты - единицы BYOND,
/// как в /sound.x/y/z).
/proc/jukebox_audible_at(falloff, sound_x, sound_y, sound_z)
	if(!(falloff > 0))
		return FALSE
	var/distance = sqrt(sound_x * sound_x + sound_y * sound_y + sound_z * sound_z)
	return distance * JUKEBOX_AUDIBLE_GAIN <= falloff

/// Нужен ли слушателю файл трека. Вне зоны слышна только реверберация, а она идёт по всему уровню,
/// поэтому стационарному джукбоксу хватает достижимого z; личной шкатулке (мегабайты) - порог прямого звука.
/datum/controller/subsystem/jukeboxes/proc/jukebox_within_earshot(turf/source, turf/listener, falloff, list/audible_zlevels, personal = FALSE)
	if(!source || !listener)
		return FALSE
	if(!(listener.z in audible_zlevels))
		return FALSE
	if(!personal)
		return TRUE
	return jukebox_audible_at(falloff, JUKEBOX_SOUND_X(source, listener), JUKEBOX_SOUND_Y(source, listener), JUKEBOX_SOUND_Z(source, listener))

/**
 * Ограничение зоны для джукбокса, стоящего в этой зоне: сама зона, номер комнаты отеля либо
 * null, если зона музыку не запирает.
 *
 * Считается по ТЕКУЩЕЙ зоне и на старте, и на каждой досылке. Раньше значение снималось один
 * раз в addjukebox() и после этого решало судьбу каждого нового слушателя: шкатулку, включённую
 * в номере отеля и вынесенную в коридор, не мог услышать вообще никто - ограничение продолжало
 * требовать той самой комнаты, в которой шкатулки уже нет. Обратный случай так же плох: автомат,
 * занесённый в комнату, продолжал бы играть на весь коридор.
 */
/datum/controller/subsystem/jukeboxes/proc/get_jukebox_area_limit(area/juke_area)
	if(!juke_area || !juke_area.jukebox_restrain) // Запрет выхода музыки из зоны
		return null
	// Отель передаёт номер комнаты: все инфинити - экземпляры одного типа зоны, и сравнение
	// по самой зоне их не различает, музыка одной комнаты играла бы во всех.
	var/area/hilbertshotel/hotel_area = juke_area
	if(istype(hotel_area))
		return hotel_area.roomnumber
	return juke_area

/// Пропускает ли зона слушателя музыку этого джукбокса: глушилки, приватизация зоны
/// стационарным автоматом и ограничение "играет только в своей зоне".
/datum/controller/subsystem/jukeboxes/proc/jukebox_area_allows(mob/listener, obj/jukebox, area_limit)
	var/area/mob_area = get_area(listener)
	if(!mob_area)
		return FALSE
	if(mob_area.jukebox_silent) // Джукбокс заглушен в зоне игрока
		return FALSE
	if(mob_area.jukebox_privatized_by && mob_area.jukebox_privatized_by != jukebox) // Стационарные джукбоксы имеют приоритет игры в своей зоне и все кто в ней сидят не слышат иных джукбоксов
		return FALSE
	if(!area_limit)
		return TRUE
	if(isnum(area_limit)) // Если число, то оно обозначает номер комнаты (мы не хотим чтобы из одних инфинити слышали в других)
		var/area/hilbertshotel/hotel_area = mob_area
		if(!istype(hotel_area))
			return FALSE
		return hotel_area.roomnumber == area_limit
	return mob_area == area_limit

/**
 * Сколько секунд трека уже проиграно к этому моменту.
 *
 * Считается по РЕАЛЬНОМУ времени, а не по world.time. world.time - это игровое время, и под
 * дилатацией оно отстаёт от настенного: в раунде 10137 сервер шёл на 67%, то есть за десять
 * настоящих минут трека world.time насчитывал около шести. Опоздавший слушатель подхватывал
 * файл на шестой минуте, тогда как у всех остальных играла десятая - четыре минуты рассинхрона
 * на ровном месте, и тем больше, чем дольше играет трек.
 *
 * REALTIMEOFDAY сам переносит счётчик через полночь (MIDNIGHT_ROLLOVER_CHECK), но отметка,
 * снятая до первого обновления этого счётчика, всё равно может оказаться "в будущем", а
 * отрицательное смещение /sound понимает как перемотку в начало - поэтому режем снизу нулём.
 *
 * Чистой функцией: дилатацию иначе не проверить, не заведя настоящий джукбокс и не поспав.
 *
 * Аргументы:
 * * real_start_time - REALTIMEOFDAY на старте трека; null = отметки нет, идём в запасной отсчёт
 * * world_start_time - world.time на старте трека, запасной отсчёт
 * * real_now, world_now - "сейчас" в тех же шкалах; отдельными аргументами ради теста
 */
/proc/jukebox_catchup_seconds(real_start_time, world_start_time, real_now = REALTIMEOFDAY, world_now = world.time)
	if(!isnull(real_start_time))
		return max(real_now - real_start_time, 0) / (1 SECONDS)
	if(!isnull(world_start_time))
		return max(world_now - world_start_time, 0) / (1 SECONDS)
	return 0

/// Смещение для того, кто подключается к уже играющему треку: он должен услышать ту же секунду,
/// что и остальные, а не начало файла.
/datum/controller/subsystem/jukeboxes/proc/set_catchup_offset(sound/song, real_start_time, world_start_time)
	song.offset = jukebox_catchup_seconds(real_start_time, world_start_time)

/// Снимает смещение после досылки - именно в null, а НЕ в ноль. У /sound это разные значения:
/// null означает "позицию не трогать", ноль - "перемотать в начало". Датум звука один на всех
/// слушателей и живёт весь трек, поэтому оставленный ноль уезжает дальше с каждым SOUND_UPDATE,
/// а их fire() шлёт раз в полсекунды каждому, кто слышит: канал перематывается в начало
/// дважды в секунду, и трек играет первые полсекунды по кругу.
/datum/controller/subsystem/jukeboxes/proc/clear_catchup_offset(sound/song)
	song.offset = null


//Updates jukebox by transferring to different object or modifying falloff.
/datum/controller/subsystem/jukeboxes/proc/updatejukebox(IDtoupdate, obj/jukebox, jukefalloff)
	if(islist(activejukeboxes[IDtoupdate]))
		if(istype(jukebox))
			activejukeboxes[IDtoupdate][JUKE_BOX] = jukebox
		if(!isnull(jukefalloff))
			activejukeboxes[IDtoupdate][JUKE_FALLOFF] = jukefalloff

/datum/controller/subsystem/jukeboxes/proc/removejukebox(IDtoremove)
	if(!IDtoremove)
		return
	if(islist(activejukeboxes[IDtoremove]))
		var/jukechannel = activejukeboxes[IDtoremove][JUKE_CHANNEL]
		for(var/mob/M in GLOB.player_list)
			if(!M.client)
				continue
			M.stop_sound_channel(jukechannel)
		freejukeboxchannels |= jukechannel
		activejukeboxes.Cut(IDtoremove, IDtoremove+1)
		return TRUE
	else
		CRASH("Tried to remove jukebox with invalid ID")

/datum/controller/subsystem/jukeboxes/proc/findjukeboxindex(obj/jukebox)
	if(activejukeboxes.len)
		for(var/list/jukeinfo in activejukeboxes)
			if(jukebox in jukeinfo)
				return activejukeboxes.Find(jukeinfo)
	return FALSE

/datum/controller/subsystem/jukeboxes/Initialize()
	init_channels()

	if(!fexists("config/jukebox_music/sounds/"))
		return ..()

	var/list/tracks = flist("config/jukebox_music/sounds/")
	//SPLURT EDIT
	var/max_tracks = CONFIG_GET(number/max_jukebox_songs)
	if(max_tracks >= 0)
		while(tracks.len > max_tracks)
			LAZYREMOVE(tracks, pick(tracks))
	//SPLURT EDIT END
	for(var/track in tracks)
		var/datum/track/track_datum = add_track(track)
		if(!track_datum)
			continue
		songs |= track_datum

	for(var/datum/track/T in songs)
		song_names += T.song_name
		songs_by_name[T.song_name] = T

	return ..()

/// Creates audio channels for jukeboxes to use, run first to prevent init failing to fill this
/datum/controller/subsystem/jukeboxes/proc/init_channels()
	for(var/i in CHANNEL_JUKEBOX_START to CHANNEL_JUKEBOX)
		freejukeboxchannels |= i

/datum/controller/subsystem/jukeboxes/proc/add_track(track)
	var/datum/track/track_datum = new()
	track_datum.song_path = file("config/jukebox_music/sounds/[track]")

	var/list/track_data = splittext(track,"+")
	if(!LAZYLEN(track_data))
		stack_trace("Invalid track: [track]")
		return FALSE
	var/track_name = LAZYACCESS(track_data, TRACK_NAME)
	if(!track_name)
		stack_trace("Track [track] lacks name???")
		return FALSE
	track_datum.song_name = track_name
	var/track_length = LAZYACCESS(track_data, TRACK_LENGTH)
	if(!track_length)
		log_world("Jukebox: Track [track] lacks length. Use format: name+length_seconds+bpm+id")
		return FALSE
	track_length = text2num(track_length)
	if(!isnum(track_length))
		stack_trace("Track [track]'s length value is not a number")
		return FALSE
	track_datum.song_length = track_length
	var/track_beat = LAZYACCESS(track_data, TRACK_BEAT)
	if(!track_beat)
		stack_trace("Track [track] lacks BPM.")
		return FALSE
	track_beat = text2num(track_beat)
	if(!isnum(track_beat))
		stack_trace("Track [track]'s beat value is not a number")
		return FALSE
	track_datum.song_beat = track_beat
	var/track_id = LAZYACCESS(track_data, TRACK_ID)
	if(!track_id)
		stack_trace("Track [track] lacks an unique identifier.")
		return FALSE
	track_datum.song_associated_id = track_id
	return track_datum


/datum/controller/subsystem/jukeboxes/fire()
	if(!activejukeboxes.len)
		return
	for(var/list/jukeinfo in activejukeboxes)
		if(!jukeinfo.len)
			stack_trace("Active jukebox without any associated metadata.")
			continue
		var/datum/track/juketrack = jukeinfo[JUKE_TRACK]
		if(!istype(juketrack))
			stack_trace("Invalid jukebox track datum.")
			continue
		var/obj/jukebox = jukeinfo[JUKE_BOX]
		var/turf/jukebox_loc = jukebox.loc
		if(!istype(jukebox))
			stack_trace("Nonexistant or invalid object associated with jukebox.")
			continue

		if(!jukebox_loc)
			return

		var/list/audible_zlevels = get_multiz_accessible_levels(jukebox_loc.z) //TODO - for multiz refresh, this should use the cached zlevel connections var in SSMapping. For now this is fine!

		var/personal = jukeinfo[JUKE_PERSONAL]
		var/sound/song_played = jukeinfo[JUKE_SOUND]
		var/turf/currentturf = get_turf(jukebox)
		var/area/currentarea = get_area(jukebox)
		var/list/hearerscache = hearers(JUKEBOX_HEARING_RANGE, jukebox)
		var/list/sent_to = jukeinfo[JUKE_SENT]
		// Ограничение зоны берётся по ТЕКУЩЕЙ зоне, а не по той, где трек включили: переносную
		// шкатулку выносят из номера отеля в руках, и застывшее ограничение навсегда запирало
		// первую досылку любому новому слушателю. Пишем обратно, чтобы в списке не оставалось
		// протухшей копии.
		var/area_limit = get_jukebox_area_limit(currentarea)
		jukeinfo[JUKE_AREA_LIMIT] = area_limit
		var/start_time = jukeinfo[JUKE_START]
		var/real_start_time = jukeinfo[JUKE_START_REAL]
		var/targetfalloff = jukeinfo[JUKE_FALLOFF]
		var/mixes = ((targetfalloff*250)-750)
		var/inrange
		var/audible
		var/pressure_factor


		var/datum/gas_mixture/source_env = (istype(currentturf) ? currentturf.return_air() : null)
		var/datum/gas_mixture/hearer_env //We init this var outside of the mob loop for the sake of performance
		var/turf/hearerturf //ditto

		var/source_pressure = (istype(source_env) ? source_env.return_pressure() : 0)

		song_played.falloff = targetfalloff
		song_played.volume = min((targetfalloff * 50), 100)

		for(var/mob/M in GLOB.player_list)
			if(!M.client)
				continue
			if(!M.client.prefs)
				continue
			if(!jukebox_sound_enabled(M, personal))
				M.stop_sound_channel(jukeinfo[JUKE_CHANNEL])
				sent_to -= M.ckey // Канал освобождён: если настройку вернут, ресурс придётся выслать заново
				continue

			// Глушилку и приватизацию зоны надо пересматривать и для тех, кому трек уже играет:
			// раньше зона сверялась только на старте, и зашедший в заглушенную комнату продолжал
			// слышать музыку. Ограничение one_area_play сюда НЕ входит намеренно - оно решает,
			// кому вообще стартовать трек, а вышедшего за порог зоны глушить нельзя, иначе
			// шаг из комнаты рвал бы музыку вместо приглушения эхом.
			if(sent_to[M.ckey] && !jukebox_area_allows(M, jukebox, null))
				M.stop_sound_channel(jukeinfo[JUKE_CHANNEL])
				sent_to -= M.ckey // вернётся в разрешённую зону - трек стартует заново с той же секунды
				continue

			inrange = FALSE
			audible = FALSE
			song_played.status = SOUND_MUTE | SOUND_UPDATE

			if(source_pressure)
				hearerturf = get_turf(M)
				hearer_env = (istype(hearerturf) ? hearerturf.return_air() : null)
				if(istype(hearer_env))
					pressure_factor = min(source_pressure, hearer_env.return_pressure())
				if(pressure_factor && targetfalloff && M.can_hear() && (hearerturf.z in audible_zlevels))
					if(get_area(hearerturf) == currentarea)
						inrange = TRUE
					else if(M in hearerscache)
						inrange = TRUE

					song_played.x = JUKEBOX_SOUND_X(currentturf, hearerturf)
					song_played.z = JUKEBOX_SOUND_Z(currentturf, hearerturf)
					song_played.y = JUKEBOX_SOUND_Y(currentturf, hearerturf)
					audible = personal ? jukebox_audible_at(targetfalloff, song_played.x, song_played.y, song_played.z) : TRUE

					if(pressure_factor < ONE_ATMOSPHERE)
						song_played.volume = (min((targetfalloff * 50), 100) * max((pressure_factor - SOUND_MINIMUM_PRESSURE)/(ONE_ATMOSPHERE - SOUND_MINIMUM_PRESSURE), 1))

					song_played.echo[1] = (inrange ? 0 : -10000)
					song_played.echo[3] = (inrange ? mixes : max(mixes, 0))
					song_played.status = SOUND_UPDATE
			var/first_send = FALSE
			if(!sent_to[M.ckey])
				// Ресурса у клиента ещё нет, а SOUND_UPDATE пустой канал не поднимет
				if((!inrange && !audible) || !jukebox_area_allows(M, jukebox, area_limit))
					continue
				first_send = TRUE
				sent_to[M.ckey] = TRUE
				song_played.status = 0 // Обычный старт, а не обновление уже играющего канала
				set_catchup_offset(song_played, real_start_time, start_time) // Подхватываем с той же секунды, что слышат остальные
			var/juke_vol = M.client?.prefs?.get_sound_volume(personal ? "personal_jukeboxes" : "jukeboxes")
			var/original_volume = song_played.volume
			song_played.volume = round(original_volume * juke_vol / 100)
			SEND_SOUND(M, song_played)
			song_played.volume = original_volume
			if(first_send)
				clear_catchup_offset(song_played)
			CHECK_TICK
	return

#undef TRACK_NAME
#undef TRACK_LENGTH
#undef TRACK_BEAT
#undef TRACK_ID

#undef JUKE_TRACK
#undef JUKE_CHANNEL
#undef JUKE_BOX
#undef JUKE_FALLOFF
#undef JUKE_SOUND
#undef JUKE_PERSONAL
#undef JUKE_SENT
#undef JUKE_AREA_LIMIT
#undef JUKE_START
#undef JUKE_START_REAL

#undef JUKEBOX_HEARING_RANGE
#undef JUKEBOX_AUDIBLE_GAIN
#undef JUKEBOX_SOUND_X
#undef JUKEBOX_SOUND_Y
#undef JUKEBOX_SOUND_Z
