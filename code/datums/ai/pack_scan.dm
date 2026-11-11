// Общая память поиска целей стаи. Сородичи одного типа, фракции и правил атаки делят
// отказы can_attack, найденные oview объекты и проверку клеток вокруг общей цели. В орде
// из сотни мобов каждый скан иначе заново прогонял CanAttack по всей сотне союзников и свой
// oview по тому же месту, где только что смотрел сосед.
//
// Делятся только отказы: годный кандидат всегда перепроверяется своим can_attack,
// поэтому чужая память может лишь на окно задержать замечание цели, ставшей годной
// (сменила фракцию, вышла из невидимости), но не подсунуть негодную. Окна сбрасываются
// таймером целиком, ссылки на атомы дольше окна не живут.

///Сколько живёт общая память отказов стаи
#define AI_PACK_SCAN_WINDOW (0.5 SECONDS)
///Сколько живут найденные стаей объекты: вещи не бегают, новая замечается не позже этого
#define AI_PACK_OBJECT_WINDOW (2 SECONDS)
///С какого расстояния до точки чужого oview можно взять его найденные объекты
#define AI_PACK_OBJECT_SHARE_DIST 3
///Сколько последних oview стаи держится для соседей
#define AI_PACK_OBJECT_SCANS_MAX 8

///Ключ стаи -> /datum/ai_pack_scan текущего окна
GLOBAL_LIST_EMPTY(ai_pack_scans)
GLOBAL_VAR_INIT(ai_pack_scan_reset_armed, FALSE)
///Ключ стаи -> список /datum/ai_pack_object_scan текущего окна объектов
GLOBAL_LIST_EMPTY(ai_pack_object_scans)
GLOBAL_VAR_INIT(ai_pack_object_reset_armed, FALSE)

///Типы, чей CanAttack читает состояние конкретной особи (создатель, хозяин, текущая цель,
///компонент службы): их отказ нельзя переносить на сородича. Новый такой оверрайд - сюда.
GLOBAL_LIST_INIT(ai_pack_scan_excluded, typecacheof(list(
	/mob/living/simple_animal/hostile/deathclaw/funclaw,
	/mob/living/simple_animal/hostile/gorilla,
	/mob/living/simple_animal/hostile/hellhound/funwolf,
	/mob/living/simple_animal/hostile/hk50,
	/mob/living/simple_animal/hostile/ice_wolf/funwolf,
	/mob/living/simple_animal/hostile/illusion/heretic_moon,
	/mob/living/simple_animal/hostile/mimic/copy,
	/mob/living/simple_animal/hostile/statue,
	/mob/living/simple_animal/hostile/syndicate/mecha_pilot,
	/mob/living/simple_animal/hostile/the_mosley/funwolf,
	/mob/living/simple_animal/hostile/werewolf/funwolf,
)))

/datum/ai_pack_scan
	///Ключ стаи: по нему же лежат её oview объектов
	var/key
	///Кандидаты, которых can_attack сородича отверг в этом окне
	var/alist/rejected = alist()

/datum/ai_pack_scan/New(pack_key)
	key = pack_key

/datum/ai_pack_scan/Destroy(force)
	rejected = null
	return ..()

///Запомнить отказ для стаи. Отказ из-за личной фракции-ссылки охотника (питомец, призыв)
///сородичу не передаётся: у того своя ссылка.
/datum/ai_pack_scan/proc/note_rejection(atom/candidate, hunter_ref)
	var/mob/living/living_candidate = candidate
	if(!istype(living_candidate) || (hunter_ref in living_candidate.faction))
		return
	rejected[candidate] = TRUE

///Найденные сородичем объекты, если он смотрел с той же дальности почти с той же точки
/datum/ai_pack_scan/proc/shared_objects(turf/origin, range)
	for(var/datum/ai_pack_object_scan/object_scan as anything in GLOB.ai_pack_object_scans[key])
		if(object_scan.range == range && object_scan.origin.z == origin.z && get_dist(object_scan.origin, origin) <= AI_PACK_OBJECT_SHARE_DIST)
			return object_scan.hits
	return null

/datum/ai_pack_scan/proc/store_objects(turf/origin, range, list/hits)
	var/list/object_scans = GLOB.ai_pack_object_scans[key]
	if(!object_scans)
		object_scans = list()
		GLOB.ai_pack_object_scans[key] = object_scans
	object_scans += new /datum/ai_pack_object_scan(origin, range, hits)
	if(length(object_scans) > AI_PACK_OBJECT_SCANS_MAX)
		var/datum/ai_pack_object_scan/oldest = object_scans[1]
		object_scans.Cut(1, 2)
		qdel(oldest)
	if(!GLOB.ai_pack_object_reset_armed)
		GLOB.ai_pack_object_reset_armed = TRUE
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ai_pack_object_scans_reset)), AI_PACK_OBJECT_WINDOW)

///Один oview стаи: откуда, на какую дальность и что нашёл
/datum/ai_pack_object_scan
	var/turf/origin
	var/range
	var/list/hits

/datum/ai_pack_object_scan/New(turf/scan_origin, scan_range, list/scan_hits)
	origin = scan_origin
	range = scan_range
	hits = scan_hits

/datum/ai_pack_object_scan/Destroy(force)
	origin = null
	hits = null
	return ..()

///Память стаи для этого охотника, либо null, если его отказы личные
/proc/ai_pack_scan_for(mob/living/simple_animal/hostile/hunter, datum/targeting_strategy/strategy)
	if(!AI_HORDE_SAVINGS || !istype(hunter) || !strategy)
		return null
	if(strategy.type != /datum/targeting_strategy/hostile_legacy && strategy.type != /datum/targeting_strategy/hostile_legacy/ignore_sight)
		return null
	if(length(hunter.foes) || length(hunter.friends) || GLOB.ai_pack_scan_excluded[hunter.type])
		return null
	//у каждой особи в фракциях есть её собственная ссылка, сородичей она не различает
	var/key = "[hunter.type]|[strategy.type]|[jointext(hunter.faction - "[REF(hunter)]", ",")]|[hunter.see_invisible]|[hunter.search_objects]|[hunter.robust_searching]|[hunter.attack_same]|[hunter.stat_attack]|[length(hunter.wanted_objects)]"
	var/datum/ai_pack_scan/scan = GLOB.ai_pack_scans[key]
	if(scan)
		return scan
	scan = new(key)
	GLOB.ai_pack_scans[key] = scan
	if(!GLOB.ai_pack_scan_reset_armed)
		GLOB.ai_pack_scan_reset_armed = TRUE
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ai_pack_scans_reset)), AI_PACK_SCAN_WINDOW)
	return scan

/proc/ai_pack_scans_reset()
	GLOB.ai_pack_scan_reset_armed = FALSE
	QDEL_LIST_ASSOC_VAL(GLOB.ai_pack_scans)

/proc/ai_pack_object_scans_reset()
	GLOB.ai_pack_object_reset_armed = FALSE
	for(var/pack_key in GLOB.ai_pack_object_scans)
		var/list/object_scans = GLOB.ai_pack_object_scans[pack_key]
		QDEL_LIST(object_scans)
	GLOB.ai_pack_object_scans.Cut()

///Клетки вокруг цели, проверенные стаей в этот тик: тип и способ прохода -> alist(турф -> открыт)
GLOBAL_LIST_EMPTY(ai_approach_tile_memo)
GLOBAL_VAR_INIT(ai_approach_tile_memo_time, -1)

///Можно ли пауну встать на клетку рядом с целью. Ответ зависит от клетки, того, как такой
///моб проходит, и стороны, с которой он подходит, поэтому за тик стая спрашивает каждую
///клетку с каждой стороны один раз. Подход и окружение планируются только с дистанции больше
///одной клетки, так что сам паун на этих клетках не стоит.
/proc/ai_approach_tile_open(datum/ai_controller/controller, turf/tile)
	var/atom/movable/pawn = controller.pawn
	if(!AI_HORDE_SAVINGS || tile == pawn.loc)
		return controller.can_enter_turf(tile) && !tile.is_blocked_turf(source_atom = pawn)
	if(GLOB.ai_approach_tile_memo_time != world.time)
		GLOB.ai_approach_tile_memo_time = world.time
		GLOB.ai_approach_tile_memo.Cut()
	var/memo_key = "[pawn.type]|[pawn.pass_flags]|[pawn.movement_type]|[pawn.density]|[controller.cross_dangerous_turfs]|[get_dir(tile, pawn)]"
	var/alist/memo = GLOB.ai_approach_tile_memo[memo_key]
	if(!memo)
		memo = alist()
		GLOB.ai_approach_tile_memo[memo_key] = memo
	. = memo[tile]
	if(!isnull(.))
		return
	. = controller.can_enter_turf(tile) && !tile.is_blocked_turf(source_atom = pawn)
	memo[tile] = .

#undef AI_PACK_OBJECT_SCANS_MAX
#undef AI_PACK_OBJECT_SHARE_DIST
#undef AI_PACK_OBJECT_WINDOW
#undef AI_PACK_SCAN_WINDOW
