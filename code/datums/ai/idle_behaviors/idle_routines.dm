// Живой idle: вместо одного случайного шага на всех - небольшая библиотека
// фоновых рутин, назначаемых по тому, ЧТО ЭТО ЗА МОБ.
//
// До этого весь мир нейтрального времени выглядел одинаково: любая фауна, от
// пчелы до голиафа, наматывала одинаковые случайные шаги вокруг якоря. Рутины
// не добавляют планировщику работы - каждая это один прок выбора направления
// поверх той же механики шага, что была (см. pick_idle_direction).
//
// Патрульная бухгалтерия якоря и амбиент-речь остаются в hostile_ambience:
// рутины его наследуют и территорию у мобов не отбирают.

///Выпас: безобидная травоядная живность топчется на месте и ходит редко
/datum/idle_behavior/idle_random_walk/hostile_ambience/grazing
	walk_chance = 8

///Лежбище: моб держится своего логова. Внутри радиуса бродит свободно, снаружи
///шаг смещён к якорю - хищник живёт у норы, а не дрейфует по карте.
/datum/idle_behavior/idle_random_walk/hostile_ambience/denning
	walk_chance = 15

/datum/idle_behavior/idle_random_walk/hostile_ambience/denning/pick_idle_direction(mob/living/living_pawn, datum/ai_controller/controller)
	var/turf/anchor = controller.blackboard[BB_AI_PATROL_ANCHOR]
	var/turf/pawn_turf = get_turf(living_pawn)
	if(!anchor || !pawn_turf || anchor.z != pawn_turf.z)
		return ..()
	if(get_dist(pawn_turf, anchor) <= AI_DEN_RADIUS)
		return ..()
	return get_dir(pawn_turf, anchor)

///Суетливая мелочь: ходит часто, но короткими рывками в одну сторону, а не
///дёргается на месте каждым шагом в новом направлении.
/datum/idle_behavior/idle_random_walk/hostile_ambience/skittish
	walk_chance = 40

/datum/idle_behavior/idle_random_walk/hostile_ambience/skittish/pick_idle_direction(mob/living/living_pawn, datum/ai_controller/controller)
	var/burst_dir = controller.blackboard[BB_AI_IDLE_BURST_DIR]
	if(burst_dir && world.time < (controller.blackboard[BB_AI_IDLE_BURST_UNTIL] || 0))
		return burst_dir
	burst_dir = pick(GLOB.alldirs)
	controller.blackboard[BB_AI_IDLE_BURST_DIR] = burst_dir
	controller.blackboard[BB_AI_IDLE_BURST_UNTIL] = world.time + AI_IDLE_BURST_TIME
	return burst_dir

///Стайность: моб тянется к ближайшему сородичу, пока не окажется в стае.
///Внутри комфортного радиуса ходит как обычно - иначе стая слипается в точку.
/datum/idle_behavior/idle_random_walk/hostile_ambience/flocking

/datum/idle_behavior/idle_random_walk/hostile_ambience/flocking/pick_idle_direction(mob/living/living_pawn, datum/ai_controller/controller)
	//радиус поиска обязан быть шире комфортного: дефолтный спейсинг-радиус (2)
	//меньше AI_FLOCK_COMFORT_RADIUS (3), и с ним любой найденный сородич уже
	//"в стае" - ветка притяжения не срабатывала никогда
	var/list/allies = controller.get_nearby_allies(AI_FLOCK_SEARCH_RANGE)
	if(!length(allies))
		return ..()
	var/mob/living/nearest
	var/nearest_distance = INFINITY
	for(var/mob/living/ally as anything in allies)
		if(QDELETED(ally))
			continue
		var/distance = get_dist(living_pawn, ally)
		if(distance >= nearest_distance)
			continue
		nearest_distance = distance
		nearest = ally
	if(!nearest || nearest_distance <= AI_FLOCK_COMFORT_RADIUS)
		return ..()
	return get_dir(living_pawn, nearest)

///Рутина по типу моба. Профиль, выбравший idle сам (майнбот, floor cluwne,
///хаунтиум), не трогается: там фоновое поведение - часть сценария.
/proc/ai_idle_routine_for(mob/living/simple_animal/hostile/hostile_pawn)
	if(!istype(hostile_pawn))
		return null
	if(hostile_pawn.mob_biotypes & MOB_BUG)
		return /datum/idle_behavior/idle_random_walk/hostile_ambience/flocking
	if(hostile_pawn.mob_size <= MOB_SIZE_SMALL)
		return /datum/idle_behavior/idle_random_walk/hostile_ambience/skittish
	if(hostile_pawn.melee_damage_upper <= AI_GRAZER_MELEE_DAMAGE)
		return /datum/idle_behavior/idle_random_walk/hostile_ambience/grazing
	return /datum/idle_behavior/idle_random_walk/hostile_ambience/denning
