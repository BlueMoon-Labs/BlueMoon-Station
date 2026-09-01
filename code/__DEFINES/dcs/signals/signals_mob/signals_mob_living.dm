///From base of mob/living/MobBump() (mob/living)
#define COMSIG_LIVING_MOB_BUMP "living_mob_bump"
/// Из /datum/element/death_drops/on_death() перед спавном лута: (list/loot, gibbed)
#define COMSIG_LIVING_DROP_LOOT "living_drop_loot"
	/// Вернуть из обработчика, чтобы лут не заспавнился
	#define COMPONENT_NO_LOOT_DROP (1<<0)
/// Из /datum/element/death_drops/on_death() после спавна лута: (list/loot, gibbed)
#define COMSIG_LIVING_DROPPED_LOOT "living_dropped_loot"
