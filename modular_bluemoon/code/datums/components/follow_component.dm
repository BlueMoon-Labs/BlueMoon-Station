#define COMSIG_HOSTILE_MOB_LOST_TARGET "hostile_mob_lost_target"

/**
 * Follow component
 *
 * A simple component that allows hostile mobs to follow another mob in their faction.
 * Default behaviour is alt click.
 *
 * @author Gandalf2k15
 */
/datum/component/follow
	/// Sounds we play when the mob starts following.
	var/list/follow_sounds
	/// Sounds we play when the mob stops following via alt click.
	var/list/unfollow_sounds
	/// The speed at which we follow the user.
	var/follow_speed = 2
	/// The distance we keep from the user.
	var/follow_distance = 1
	/// Are we currently following? Used for playing sounds.
	var/following = FALSE
	/// Our parent mob.
	var/mob/living/simple_animal/hostile/parent_mob
	/// За кем сейчас идёт нативный цикл walk_to(). Тот держит цель жёсткой ссылкой
	/// мимо любого DM-скана, а LoseTarget() его не гасит - ушедший из раунда игрок
	/// оставался висеть на питомце до конца смены.
	var/mob/living/followed

/datum/component/follow/Initialize(_follow_sounds, _unfollow_sounds, _follow_distance = 1, _follow_speed = 2)
	if(!ishostile(parent))
		return COMPONENT_INCOMPATIBLE
	if(_follow_sounds)
		follow_sounds = _follow_sounds
	if(_unfollow_sounds)
		unfollow_sounds = _unfollow_sounds
	if(_follow_distance)
		follow_distance = _follow_distance
	if(_follow_speed)
		follow_speed = _follow_speed
	RegisterSignal(parent, COMSIG_HOSTILE_MOB_LOST_TARGET, PROC_REF(lost_target))
	RegisterSignal(parent, COMSIG_CLICK_ALT, PROC_REF(toggle_follow))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	parent_mob = parent

/datum/component/follow/Destroy(force, silent)
	UnregisterSignal(parent, COMSIG_HOSTILE_MOB_LOST_TARGET)
	UnregisterSignal(parent, COMSIG_CLICK_ALT)
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)
	stop_following()
	parent_mob = null
	return ..()

/datum/component/follow/proc/lost_target()
	SIGNAL_HANDLER
	following = FALSE
	stop_following()

/// Заводит нативный цикл слежения и берёт цель под подписку на удаление.
/datum/component/follow/proc/start_following(mob/living/living_user)
	if(!istype(living_user) || QDELETED(parent_mob))
		return
	stop_following()
	followed = living_user
	RegisterSignal(followed, COMSIG_PARENT_QDELETING, PROC_REF(on_followed_qdeleting))
	walk_to(parent_mob, followed, follow_distance, follow_speed)

/// Гасит цикл и отпускает цель. Идемпотентно.
/datum/component/follow/proc/stop_following()
	if(!followed)
		return
	UnregisterSignal(followed, COMSIG_PARENT_QDELETING)
	followed = null
	if(!QDELETED(parent_mob))
		walk(parent_mob, 0)

/datum/component/follow/proc/on_followed_qdeleting(datum/source)
	SIGNAL_HANDLER

	following = FALSE
	stop_following()

/datum/component/follow/proc/toggle_follow(datum/source, mob/living/living_user)
	SIGNAL_HANDLER
	if(!istype(living_user) || !living_user.canUseTopic(parent_mob, TRUE))
		return
	following = !following
	if(following)
		if(follow_sounds)
			playsound(parent_mob, pick(follow_sounds), 100)
		INVOKE_ASYNC(parent_mob, TYPE_PROC_REF(/atom/movable, say), "Следую!")
		start_following(living_user)
	else
		if(unfollow_sounds)
			playsound(parent_mob, pick(unfollow_sounds), 100)
		INVOKE_ASYNC(parent_mob, TYPE_PROC_REF(/atom/movable, say), "Пока побуду тут.")
		stop_following()
		parent_mob.LoseTarget()

/datum/component/follow/proc/on_examine(datum/source, mob/examiner, list/examine_text)
	examine_text += "Alt-click заставит идти за собой!"

#undef COMSIG_HOSTILE_MOB_LOST_TARGET
