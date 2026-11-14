/obj/item/mod/module/mind_swap
	name = "MOD neural transference module"
	desc = "Обменивает управление владельца МОДа и его бортового ИИ."
	module_type = MODULE_ACTIVE
	need_full_deploy = TRUE
	cooldown_time = 30 SECONDS
	incompatible_modules = list(/obj/item/mod/module/mind_swap)
	var/mob/living/carbon/human/linked_wearer
	var/mob/living/silicon/linked_ai
	var/wearer_key
	var/ai_key

/obj/item/mod/module/mind_swap/on_select()
	if(!can_swap())
		return FALSE
	return ..()

/obj/item/mod/module/mind_swap/proc/can_swap()
	if(!mod?.wearer)
		return FALSE
	if(!mod.ai)
		balloon_alert(mod.wearer, "нет бортового ИИ")
		return FALSE
	if(!mod.wearer.client)
		balloon_alert(mod.ai, "владелец не отвечает")
		return FALSE
	if(!mod.ai.client)
		balloon_alert(mod.wearer, "ИИ не отвечает")
		return FALSE
	return TRUE

/obj/item/mod/module/mind_swap/on_activation()
	if(!can_swap() || !..())
		return FALSE
	linked_wearer = mod.wearer
	linked_ai = mod.ai
	wearer_key = linked_wearer.key
	ai_key = linked_ai.key
	RegisterSignal(linked_wearer, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(linked_ai, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	linked_wearer.ghostize(FALSE)
	linked_ai.ghostize(FALSE)
	linked_wearer.key = ai_key
	linked_ai.key = wearer_key
	balloon_alert(linked_wearer, "управление обменяно")
	balloon_alert(linked_ai, "управление обменяно")
	return TRUE

/obj/item/mod/module/mind_swap/on_deactivation()
	restore_control()
	if(mod?.wearer)
		return ..()
	active = FALSE
	return TRUE

/obj/item/mod/module/mind_swap/on_active_process(delta_time)
	if(mod?.wearer == linked_wearer && mod?.ai == linked_ai && linked_wearer?.client && linked_ai?.client)
		return
	on_deactivation()

/obj/item/mod/module/mind_swap/on_suit_deactivation()
	if(linked_wearer)
		on_deactivation()

/obj/item/mod/module/mind_swap/on_unequip()
	restore_control()

/obj/item/mod/module/mind_swap/on_uninstall(deleting = FALSE, user)
	restore_control()
	return ..()

/obj/item/mod/module/mind_swap/Destroy()
	restore_control()
	return ..()

/obj/item/mod/module/mind_swap/proc/on_body_deleted()
	SIGNAL_HANDLER
	restore_control()
	active = FALSE

/obj/item/mod/module/mind_swap/proc/restore_control()
	if(!linked_wearer && !linked_ai)
		return
	var/mob/living/carbon/human/user = linked_wearer
	var/mob/living/silicon/assistant = linked_ai
	UnregisterSignal(user, COMSIG_PARENT_QDELETING)
	UnregisterSignal(assistant, COMSIG_PARENT_QDELETING)
	linked_wearer = null
	linked_ai = null
	if(user?.ckey == ckey(ai_key))
		user.ghostize(FALSE)
	if(assistant?.ckey == ckey(wearer_key))
		assistant.ghostize(FALSE)
	if(!QDELETED(user) && !QDELING(user) && !user.ckey)
		user.key = wearer_key
	if(!QDELETED(assistant) && !QDELING(assistant) && !assistant.ckey)
		assistant.key = ai_key
	wearer_key = null
	ai_key = null
