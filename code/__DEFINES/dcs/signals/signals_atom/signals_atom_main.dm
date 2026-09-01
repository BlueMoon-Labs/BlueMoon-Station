///from base of atom/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
#define COMSIG_ATOM_HITBY "atom_hitby"
///when an atom is processed (mob/living/user, obj/item/process_item, list/atom/results)
#define COMSIG_ATOM_PROCESSED "atom_processed"
///for when an atom has been created through processing (atom/original_atom, list/chosen_processing_option)
#define COMSIG_ATOM_CREATEDBY_PROCESSING "atom_createdby_processing"
///Из элемента relay_attackers: по цели кто-то ударил/попал: (atom/attacker, attack_flags, direction)
#define COMSIG_ATOM_WAS_ATTACKED "atom_was_attacked"
	///Урон атаки нелетальный (стамина)
	#define ATTACKER_STAMINA_ATTACK (1<<0)
	///Атакующий толкает жертву
	#define ATTACKER_SHOVING (1<<1)
	///Атака наносит урон
	#define ATTACKER_DAMAGING_ATTACK (1<<2)
	///Атака дальнобойная
	#define ATTACK_RANGED (1<<3)
