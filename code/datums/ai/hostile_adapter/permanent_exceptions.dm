// Hostile-типы без собственного NPC-AI.
// Каждый тип здесь обязан быть AI_OFF и иметь актуальную причину в
// MIGRATION_EXCEPTIONS.md. null запрещает наследовать профиль контроллера.

///Игровой сварнер - гост-роль (шелл занимает призрак, AIStatus = AI_OFF).
///AI-подтипы swarmer/ai используют специализированные профили.
/mob/living/simple_animal/hostile/swarmer
	ai_profile_type = null

///Элдрич-демоны еретиков - гост-роли с AIStatus = AI_OFF; сегменты armsy
///двигаются сценарными сигналами, а не NPC-AI.
/mob/living/simple_animal/hostile/eldritch
	ai_profile_type = null

///Холопаразиты - игровые духи с AIStatus = AI_OFF.
///Пин: ai_guardian_stays_player_shell.
/mob/living/simple_animal/hostile/guardian
	ai_profile_type = null

///Зеркало вестника - управляемая хозяином марионетка с AIStatus = AI_OFF.
///null перебивает унаследованный боссовый профиль элиток.
///Пин: ai_herald_mirror_stays_marionette.
/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror
	ai_profile_type = null
