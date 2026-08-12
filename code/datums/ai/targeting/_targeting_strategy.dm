// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/targeting_strategies/_targeting_strategy.dm
// Стратегия таргетирования: чистая проверка "можно ли атаковать цель".
// Синглтоны в SSai_behaviors.targeting_strategies, доставать через
// GET_TARGETING_STRATEGY. Дистанцию и LOS проверяет ПОТРЕБИТЕЛЬ
// (find_potential_targets): здесь только пригодность цели, чтобы дорогая
// can_see звалась один раз и только для прошедших фильтр кандидатов.

/datum/targeting_strategy
	///TRUE - потребитель НЕ должен требовать прямой видимости для этой стратегии
	var/ignore_sight = FALSE

///TRUE/FALSE: пригодна ли цель для атаки этим мобом
/datum/targeting_strategy/proc/can_attack(mob/living/living_mob, atom/target, vision_range)
	return

///Фактический радиус приобретения целей для этого охотника; по умолчанию профильный
/datum/targeting_strategy/proc/get_aggro_range(mob/living/hunter, profile_range)
	return profile_range

///Нужна ли охотнику прямая видимость цели прямо сейчас (в отличие от
///статичного ignore_sight может зависеть от состояния конкретного моба)
/datum/targeting_strategy/proc/ignores_sight(mob/living/hunter)
	return ignore_sight

///Контейнер, в котором прячется цель (шкаф/мусорка/слипер), либо null
/datum/targeting_strategy/proc/find_hidden_mobs(mob/living/living_mob, atom/target)
	var/atom/target_hiding_location
	if(istype(target.loc, /obj/structure/closet) || istype(target.loc, /obj/machinery/disposal) || istype(target.loc, /obj/machinery/sleeper))
		target_hiding_location = target.loc
	return target_hiding_location

/// Simply always returns true if you have a target, so only use this if you're pre-checking the targets somewhere else
/datum/targeting_strategy/anything

/datum/targeting_strategy/anything/can_attack(mob/living/living_mob, atom/target, vision_range)
	return !!target

///Легаси-мост: делегирует mob.CanAttack() - все 28 сабтиповых переопределений
///CanAttack (конструкты, статуя, крысиный король и т.д.) работают бесплатно.
///Семантика зафиксирована тестами hostile_ai_baseline + ai_targeting.
/datum/targeting_strategy/hostile_legacy

/datum/targeting_strategy/hostile_legacy/can_attack(mob/living/living_mob, atom/target, vision_range)
	var/mob/living/simple_animal/hostile/hunter = living_mob
	if(!istype(hunter))
		return FALSE
	return hunter.CanAttack(target)

///Легаси-паритет двухуровневого восприятия: холодное приобретение идёт по
///ЖИВОМУ vision_range моба, а не по раздутому max(vision, aggro_vision).
///Aggro()/LoseAggro() поднимают vision_range до aggro_vision_range только пока
///моб в бою (легаси ListTargets звал hearers(vision_range)). Профильный радиус -
///это ПОТОЛОК: мимик/маскировка нарочно занижают его, и min() это сохраняет.
///Регресс без этого: вотчер (vision 2, aggro 9) агрился через полэкрана.
///
///Свежий боевой контакт - НЕ холодное приобретение: разжалование цели уже
///уронило живой vision_range через LoseTarget->LoseAggro, но искать только что
///скрывшуюся жертву моб обязан настороженным aggro_vision_range, иначе шамблер
///(vision 3, aggro 7) слепнул за углом и бросал погоню, глядя жертве в лицо.
///LOS-гейт и профильный потолок сохраняются.
/datum/targeting_strategy/hostile_legacy/get_aggro_range(mob/living/hunter, profile_range)
	var/mob/living/simple_animal/hostile/hostile_hunter = hunter
	if(!istype(hostile_hunter))
		return profile_range
	var/live_vision = max(1, hostile_hunter.vision_range)
	if(hostile_hunter.ai_controller?.is_combat_alert())
		live_vision = max(live_vision, hostile_hunter.aggro_vision_range)
	return min(profile_range, live_vision)

///Вариант для смэш-охотников, которым разрешено вести цель без прямой видимости
///(ranged_ignores_vision / ENVIRONMENT_SMASH_WALLS кейсы решает профиль)
/datum/targeting_strategy/hostile_legacy/ignore_sight
	ignore_sight = TRUE

///Легаси-паритет: смэшер стен / стрелок-сквозь-стены ПРИОБРЕТАЕТ цель по зрению
///(легаси acquisition шёл через hearers(), а он блокируется стенами), и лишь
///уже приобретённую ВЕДЁТ сквозь стены (environment_smash-преследование,
///ranged_ignores_vision-добивание). Игнорируем зрение только пока цель есть -
///холодное приобретение снова уважает стены, как до контроллеров.
/datum/targeting_strategy/hostile_legacy/ignore_sight/ignores_sight(mob/living/hunter)
	var/mob/living/simple_animal/hostile/hostile_hunter = hunter
	if(!istype(hostile_hunter))
		return ignore_sight
	return !isnull(hostile_hunter.target)

///Retaliate-семейство: легаси фильтровал цели через ListTargets() &= enemies -
///грид-поиск обязан воспроизвести гейт "атакуем только обидчиков"
/datum/targeting_strategy/hostile_legacy/retaliate

/datum/targeting_strategy/hostile_legacy/retaliate/can_attack(mob/living/living_mob, atom/target, vision_range)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/retaliate/grudge_holder = living_mob
	if(!istype(grudge_holder))
		return FALSE
	return (target in grudge_holder.enemies)

///Охотник на мелочь (змея): мыши - легитимные цели ВСЕГДА, безо всяких обид
///(легаси ListTargets змеи выбирал мышей до retaliate-фильтра); к остальным
///применяется обычный enemies-гейт родителя
/datum/targeting_strategy/hostile_legacy/retaliate/small_prey

/datum/targeting_strategy/hostile_legacy/retaliate/small_prey/can_attack(mob/living/living_mob, atom/target, vision_range)
	if(istype(target, /mob/living/simple_animal/mouse))
		var/mob/living/simple_animal/hostile/hunter = living_mob
		if(!istype(hunter))
			return FALSE
		return hunter.CanAttack(target)
	return ..()

///Плачущий ангел: легаси search_objects=1 + сайт-флаги SEE_MOBS давали обзор
///сквозь стены - цели приобретаются и ведутся без LOS всегда, не только в бою.
///Клиент-гейт (только игроки) остаётся в делегированном CanAttack статуи;
///создатель неприкосновенен (легаси ListTargets() - creator).
/datum/targeting_strategy/hostile_legacy/statue
	ignore_sight = TRUE

/datum/targeting_strategy/hostile_legacy/statue/can_attack(mob/living/living_mob, atom/target, vision_range)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/statue/angel = living_mob
	if(istype(angel) && target == angel.creator)
		return FALSE
	return .

///Мегафауна (modular_sand-механика peaceful/enemies на базе): пока enemies
///пуст - обычная агрессия, но только в живом vision_range и с прямой
///видимостью; после первого удара - строго обидчики, зато на полном
///профильном радиусе и сквозь стены. peaceful-босс (гладиатор) без
///записанных обидчиков не трогает никого.
/datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna

/datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna/can_attack(mob/living/living_mob, atom/target, vision_range)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/megafauna/boss = living_mob
	if(!istype(boss))
		return .
	if(length(boss.enemies))
		return (target in boss.enemies)
	if(boss.peaceful)
		return FALSE
	return .

/datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna/get_aggro_range(mob/living/hunter, profile_range)
	var/mob/living/simple_animal/hostile/megafauna/boss = hunter
	if(!istype(boss) || length(boss.enemies))
		return profile_range
	//непровоцированный босс замечает только то, куда реально смотрит;
	//Aggro/LoseAggro адаптера держат vision_range актуальным
	return min(profile_range, max(1, boss.vision_range))

/datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna/ignores_sight(mob/living/hunter)
	var/mob/living/simple_animal/hostile/megafauna/boss = hunter
	if(!istype(boss))
		return ignore_sight
	return length(boss.enemies) > 0
