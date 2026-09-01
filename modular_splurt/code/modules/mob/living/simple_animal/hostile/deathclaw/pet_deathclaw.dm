// ===== Адаптер-профиль капсульных петов =====
// Пет живёт приказами хозяина (Hear -> new_order): в покое vision 0 и целей
// нет вовсе, приказ поднимает зрение и отдаёт хозяина синком GiveTarget.
// Профильный радиус тут не годится: BB-кэш max(vision, aggro) снимается при
// возможности один раз на Initialize, а зрение пета меняют приказы - поэтому
// стратегия читает ЖИВЫЕ переменные моба.

///Капсульный пет: радиус приобретения = живой max(vision, aggro) (0 в покое,
///9 после приказа); пригодность цели дальше гейтит CanAttack сабтипа
///(только capsule_owner) через делегацию родителя.
/datum/targeting_strategy/hostile_legacy/capsule_pet

/datum/targeting_strategy/hostile_legacy/capsule_pet/can_attack(mob/living/living_mob, atom/target, vision_range)
	var/mob/living/simple_animal/hostile/pet = living_mob
	//ослеплённый пет ("stop" или покой) не лапает даже хозяина вплотную
	if(!istype(pet) || pet.vision_range <= 0)
		return FALSE
	//легаси CanAttack пета ОСЛЕПЛЯЕТ его на любом чужом кандидате (side effect
	//сброса приказа). Скан пула контроллера дёргает CanAttack по всем соседям,
	//поэтому чужих отсекаем ДО делегации - иначе прохожий гасил бы приказ
	var/mob/owner = get_capsule_owner(pet)
	if(!isnull(owner) && target != owner)
		return FALSE
	return ..()

///Хозяин капсульного пета; null - у типа нет механики приказов
/datum/targeting_strategy/hostile_legacy/capsule_pet/proc/get_capsule_owner(mob/living/simple_animal/hostile/pet)
	if(istype(pet, /mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw))
		var/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw/fem_pet = pet
		return fem_pet.capsule_owner
	if(istype(pet, /mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw))
		var/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw/claw_pet = pet
		return claw_pet.capsule_owner
	return null

/datum/targeting_strategy/hostile_legacy/capsule_pet/get_aggro_range(mob/living/hunter, profile_range)
	var/mob/living/simple_animal/hostile/pet = hunter
	if(!istype(pet))
		return profile_range
	return max(pet.vision_range, pet.aggro_vision_range)

///Профиль капсульного пета: обычный мили-план, но стратегия живого зрения
/datum/ai_controller/hostile_adapter/melee_chaser/capsule_pet/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/capsule_pet

/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw
	vision_range = 0
	aggro_vision_range = 0
	wander = 1
	melee_damage_lower = 0
	melee_damage_upper = 0
	stop_automated_movement_when_pulled = 1
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/capsule_pet

	//Ordering mechanics
	var/list/speech_buffer = ""
	var/mob/capsule_owner

/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw/pet_mommyclaw
	icon_state = "mommyclaw"
	desc = "A machine that turns her victim's pelvis into pelvwas."
	name = "Mommy Funclaw"

/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw
	vision_range = 0
	aggro_vision_range = 0
	wander = 1
	melee_damage_lower = 0
	melee_damage_upper = 0
	stop_automated_movement_when_pulled = 1
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/capsule_pet

	//Ordering mechanics
	var/list/speech_buffer = ""
	var/mob/capsule_owner

/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw/pet_alphaclaw
	name = "Alpha Funclaw"
	icon_state = "alphaclaw"
	base_state = "alphaclaw"
	cock_state = "alphaclaw_cocked"


/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans, message_mode, atom/movable/source)
	. = ..()
	SEND_SIGNAL(src, COMSIG_MOB_EMOTE, args)
	if(speaker != src && !radio_freq && !stat)
		if (speaker == capsule_owner)
			speech_buffer = ""
			speech_buffer = lowertext(html_decode(message))
			new_order()

/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw/proc/new_order()
	if(speech_buffer != null)
		if (findtext(speech_buffer, "fuck") && findtext(speech_buffer, "me"))
			aggro_vision_range = 9
			vision_range = 9
			//GiveTarget вместо голого target=: приказ синхронизируется в
			//контроллер (и остаётся легаси-совместимым шагом 4)
			GiveTarget(capsule_owner)
		if (findtext(speech_buffer, "stop"))
			aggro_vision_range = 0
			vision_range = 0
			LoseTarget()

/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw/CanAttack(atom/the_target)
	. = ..()
	if(the_target != capsule_owner)
		aggro_vision_range = 0
		vision_range = 0
		return FALSE

/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans, message_mode, atom/movable/source)
	. = ..()
	SEND_SIGNAL(src, COMSIG_MOB_EMOTE, args)
	if(speaker != src && !radio_freq && !stat)
		if (speaker == capsule_owner)
			speech_buffer = ""
			speech_buffer = lowertext(html_decode(message))
			new_order()

/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw/proc/new_order()
	if(speech_buffer != null)
		if (findtext(speech_buffer, "fuck") && findtext(speech_buffer, "me"))
			aggro_vision_range = 9
			vision_range = 9
			//GiveTarget вместо голого target=: приказ синхронизируется в
			//контроллер (и остаётся легаси-совместимым шагом 4)
			GiveTarget(capsule_owner)
		if (findtext(speech_buffer, "stop"))
			aggro_vision_range = 0
			vision_range = 0
			LoseTarget()

/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw/CanAttack(atom/the_target)
	. = ..()
	if(the_target != capsule_owner)
		aggro_vision_range = 0
		vision_range = 0
		return FALSE
