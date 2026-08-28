#define COMSIG_MOB_EMOTE "mob_emote" // from /mob/emote(): (proc args list)
	// used to access COMSIG_MOB_SAY argslist
	#define EMOTE_ACT 1
	#define EMOTE_MTYPE 2
	#define EMOTE_MESSAGE 3
	#define EMOTE_INTENTIONAL 4

///from /mob/say_dead(): (mob/speaker, message)
#define COMSIG_MOB_DEADSAY "mob_deadsay"
	#define MOB_DEADSAY_SIGNAL_INTERCEPT (1<<0)
/// from base of [/client/proc/handle_spam_prevention] (message, mute_type)
#define COMSIG_MOB_AUTOMUTE_CHECK "client_automute_check" // The check is performed by the client.
	/// Prevents the automute system checking this client for repeated messages.
	#define WAIVE_AUTOMUTE_CHECK (1<<0)

/*
 * # COMSIG_MOB_UPDATE_GENITALS
 * From modular_splurt\code\modules\arousal\genitals.dm
 * Used by signals for determining when genitals have been updated
*/
#define COMSIG_MOB_UPDATE_GENITALS "mob_genitals_updated"

///called on [/obj/item] AFTER unequip from base of [mob/proc/doUnEquip]: (force, atom/newloc, no_move, invdrop, silent)
#define COMSIG_ITEM_POST_UNEQUIP "item_post_unequip"

///from /obj/machinery/set_occupant(atom/movable/O): (new_occupant)
#define COMSIG_MACHINERY_SET_OCCUPANT "machinery_set_occupant"

///from /obj/effect/mob_spawn/create(), глобальный (SEND_GLOBAL_SIGNAL): (mob/living/new_spawn) - вызывается только когда роль занял живой игрок
#define COMSIG_GHOST_ROLE_CLAIMED "ghost_role_claimed"
