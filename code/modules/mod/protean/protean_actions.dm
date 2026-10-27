/datum/action/protean
	background_icon_state = "bg_tech_blue"
	icon_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	required_mobility_flags = NONE
	var/ability_proc

/datum/action/protean/IsAvailable(silent = FALSE)
	if(!..() || !isprotean(owner))
		return FALSE
	var/mob/living/carbon/human/human = owner
	var/datum/species/protean/species = human.dna.species
	var/obj/item/organ/brain/protean/brain = human.getorganslot(ORGAN_SLOT_BRAIN)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	if(species != target || species.busy_action || human.stat == DEAD || !istype(brain) || brain.dead || brain.transform_user || brain.rebuilding || !suit)
		return FALSE
	return human.loc == suit || !human.incapacitated()

/datum/action/protean/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/datum/species/protean/species = target
	species.busy_action = src
	species.update_buttons()
	call(owner, ability_proc)()
	if(!QDELETED(species))
		species.busy_action = null
		species.update_buttons()
	return TRUE

/datum/action/protean/ui
	name = "Интерфейс MOD"
	desc = "Открыть интерфейс встроенного MOD."
	button_icon_state = "panel"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_ui)
	icon_icon = 'icons/mob/actions/actions_mod.dmi'

/datum/action/protean/heal
	name = "Восстановить органы и конечности"
	desc = "Восстановить органы и конечности внутри MOD за 6 единиц металла."
	button_icon_state = "health"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_heal)

/datum/action/protean/lock
	name = "Блокировка MOD"
	desc = "Разрешить или запретить другому носителю снимать MOD и управлять им."
	button_icon_state = "dnalock"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_lock)

/datum/action/protean/transform
	name = "Сменить форму MOD"
	desc = "Свернуться внутрь MOD или восстановить тело."
	button_icon_state = "deploy"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_transform)
	icon_icon = 'icons/mob/actions/actions_mod.dmi'

/datum/action/protean/remove_suit
	name = "Извлечь поглощённый MOD"
	desc = "Извлечь поглощённый MOD вместе с его модулями."
	button_icon_state = "recall"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_remove_suit)
	icon_icon = 'icons/mob/actions/actions_mod.dmi'

/datum/action/protean/remove_plating
	name = "Сбросить поглощённое покрытие"
	desc = "Восстановить исходный внешний вид MOD."
	button_icon_state = "base_armor"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_remove_plating)

/datum/action/protean/low_power
	name = "Режим энергосбережения"
	desc = "Уменьшить расход металла ценой скорости передвижения."
	button_icon_state = "regulator"
	ability_proc = TYPE_PROC_REF(/mob/living/carbon, do_protean_low_power)

/datum/action/protean/transform/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	var/mob/living/carbon/human/human = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	var/datum/species/protean/species = human.dna.species
	if(species.is_puddle())
		return FALSE
	return human.loc == suit ? !!get_turf(suit) : (isturf(human.loc) && human.back == suit)

/datum/action/protean/heal/IsAvailable(silent = FALSE)
	if(!..() || owner.loc != get_protean_modsuit(owner))
		return FALSE
	var/mob/living/carbon/human/human = owner
	var/obj/item/organ/stomach/protean/stomach = human.getorganslot(ORGAN_SLOT_STOMACH)
	return istype(stomach) && stomach.metal >= PROTEAN_REBUILD_COST

/datum/action/protean/low_power/IsAvailable(silent = FALSE)
	if(!..() || owner.loc == get_protean_modsuit(owner))
		return FALSE
	var/mob/living/carbon/human/human = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	return !suit.is_activating() && istype(human.getorganslot(ORGAN_SLOT_STOMACH), /obj/item/organ/stomach/protean)

/datum/action/protean/remove_suit/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	var/mob/living/carbon/human/human = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	return suit.stored_modsuit && !suit.is_active() && !suit.is_activating() && human.loc != suit && human.has_active_hand()

/datum/action/protean/remove_plating/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(owner)
	return !suit.stored_modsuit && !suit.is_active() && !suit.is_activating() && suit.theme.type != /datum/mod_theme/protean

/mob/living/carbon/proc/protean_ui()
	set name = "Интерфейс MOD"
	set category = "Protean"
	var/datum/action/protean/ui/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_ui()
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(src)
	suit?.ui_interact(src)

/mob/living/carbon/proc/protean_heal()
	set name = "Восстановить органы и конечности"
	set category = "Protean"
	var/datum/action/protean/heal/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_heal()
	var/obj/item/organ/brain/protean/brain = getorganslot(ORGAN_SLOT_BRAIN)
	if(istype(brain))
		brain.replace_limbs()

/mob/living/carbon/proc/protean_lock()
	set name = "Блокировка MOD"
	set category = "Protean"
	var/datum/action/protean/lock/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_lock()
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(src)
	if(!suit)
		return
	suit.toggle_lock()
	to_chat(src, span_notice("You [suit.modlocked ? "lock" : "unlock"] the suit."))

/mob/living/carbon/proc/protean_transform()
	set name = "Сменить форму MOD"
	set category = "Protean"
	var/datum/action/protean/transform/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_transform()
	var/obj/item/organ/brain/protean/brain = getorganslot(ORGAN_SLOT_BRAIN)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(src)
	if(!istype(brain) || !suit)
		return
	if(loc == suit)
		brain.leave_modsuit()
	else if(isturf(loc) && !incapacitated())
		brain.go_into_suit()

/mob/living/carbon/proc/protean_remove_suit()
	set name = "Извлечь поглощённый MOD"
	set category = "Protean"
	var/datum/action/protean/remove_suit/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_remove_suit()
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(src)
	suit?.unassimilate_modsuit(src)

/mob/living/carbon/proc/protean_remove_plating()
	set name = "Сбросить поглощённое покрытие"
	set category = "Protean"
	var/datum/action/protean/remove_plating/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_remove_plating()
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(src)
	suit?.unassimilate_theme()

/mob/living/carbon/proc/protean_low_power()
	set name = "Режим энергосбережения"
	set category = "Protean"
	var/datum/action/protean/low_power/ability = locate() in actions
	ability?.Trigger()

/mob/living/carbon/proc/do_protean_low_power()
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(src)
	var/obj/item/organ/stomach/protean/stomach = getorganslot(ORGAN_SLOT_STOMACH)
	if(!suit || !istype(stomach) || loc == suit)
		return
	if(!do_after(src, PROTEAN_LOW_POWER_DELAY, src) || QDELETED(suit) || get_protean_modsuit(src) != suit || getorganslot(ORGAN_SLOT_STOMACH) != stomach || loc == suit || !isprotean(src))
		return
	if(has_status_effect(/datum/status_effect/protean_low_power_mode/low_power))
		remove_status_effect(/datum/status_effect/protean_low_power_mode/low_power)
		return
	if(!suit.stop_for_low_power())
		return
	remove_status_effect(/datum/status_effect/protean_low_power_mode/reform)
	apply_status_effect(/datum/status_effect/protean_low_power_mode/low_power)

/datum/status_effect/protean_low_power_mode
	id = "proteanlowpower"
	tick_interval = -1
	alert_type = /atom/movable/screen/alert/status_effect/protean_low_power_mode

/atom/movable/screen/alert/status_effect/protean_low_power_mode
	name = "Энергосбережение"
	desc = "Скорость передвижения снижена, но расход металла уменьшен в 16 раз."
	icon = 'modular_bluemoon/icons/mob/protean/screen_alert.dmi'
	icon_state = "protean_lowpower"

/datum/status_effect/protean_low_power_mode/on_apply()
	if(!..())
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/protean_low_power)
	return TRUE

/datum/status_effect/protean_low_power_mode/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/protean_low_power)
	return ..()

/datum/movespeed_modifier/protean_low_power
	multiplicative_slowdown = 5

/datum/status_effect/protean_low_power_mode/reform
	duration = 7 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/protean_low_power_mode/reform

/atom/movable/screen/alert/status_effect/protean_low_power_mode/reform
	name = "Восстановление формы"
	desc = "Наниты ещё восстанавливают тело. Скорость передвижения снижена, входящий урон увеличен."
	icon_state = "protean_reform"

/datum/status_effect/protean_low_power_mode/reform/on_apply()
	. = ..()
	var/mob/living/carbon/human/human = owner
	if(istype(human))
		human.physiology.damage_resistance -= PROTEAN_REFORM_VULNERABILITY

/datum/status_effect/protean_low_power_mode/reform/on_remove()
	. = ..()
	var/mob/living/carbon/human/human = owner
	if(istype(human))
		human.physiology.damage_resistance += PROTEAN_REFORM_VULNERABILITY

/datum/status_effect/protean_low_power_mode/low_power
	var/datum/weakref/stomach_ref

/datum/status_effect/protean_low_power_mode/low_power/on_apply()
	var/mob/living/carbon/human/human = owner
	var/obj/item/organ/stomach/protean/stomach = human.getorganslot(ORGAN_SLOT_STOMACH)
	if(!istype(stomach))
		return FALSE
	stomach_ref = WEAKREF(stomach)
	stomach.metabolism_modifier /= PROTEAN_LOW_POWER_FACTOR
	return ..()

/datum/status_effect/protean_low_power_mode/low_power/on_remove()
	var/obj/item/organ/stomach/protean/stomach = stomach_ref?.resolve()
	if(stomach)
		stomach.metabolism_modifier *= PROTEAN_LOW_POWER_FACTOR
	stomach_ref = null
	return ..()

/obj/item/mod/module/protean_servo
	name = "protean MOD servo module"
	desc = "The folded Protean can assist a second wearer with movement, medicine, or construction."
	icon_state = "no_baton"
	complexity = 0
	use_power_cost = DEFAULT_CHARGE_DRAIN
	module_type = MODULE_TOGGLE
	removable = FALSE
	var/list/servo_actions = list()
	var/datum/weakref/servo_wearer_ref

/obj/item/mod/module/protean_servo/Initialize(mapload)
	. = ..()
	servo_actions = list(new /datum/action/cooldown/protean_servo/movement(src), new /datum/action/cooldown/protean_servo/medical(src), new /datum/action/cooldown/protean_servo/engineering(src))

/obj/item/mod/module/protean_servo/Destroy()
	clear_servo()
	QDEL_LIST(servo_actions)
	return ..()

/obj/item/mod/module/protean_servo/on_activation()
	var/reason = activation_error()
	if(reason)
		mod?.balloon_alert(mod.wearer, "сервомодуль недоступен")
		to_chat(mod?.wearer, span_warning(reason))
		var/mob/living/carbon/human/protean = get_protean()
		if(protean != mod?.wearer)
			to_chat(protean, span_warning(reason))
		return FALSE
	var/obj/item/mod/core/protean/core = mod.core
	. = ..()
	if(!.)
		return
	servo_wearer_ref = WEAKREF(mod.wearer)
	for(var/datum/action/action in servo_actions)
		action.Grant(core.linked_protean)

/obj/item/mod/module/protean_servo/proc/get_protean()
	var/obj/item/mod/core/protean/core = mod?.core
	return istype(core) ? core.linked_protean : null

/obj/item/mod/module/protean_servo/proc/activation_error()
	var/mob/living/carbon/human/protean = get_protean()
	if(!protean)
		return "Сервомодулю требуется ядро MOD, связанное с Protean."
	if(protean.loc != mod)
		return "Сначала свернитесь в собственный MOD с помощью способности «Сменить форму MOD». Сервомодуль усиливает другого носителя костюма."
	if(!mod.wearer || mod.wearer == protean)
		return "Другой персонаж должен надеть ваш MOD. После включения сервомодуля кнопки усилений получит Protean внутри костюма."
	var/obj/item/organ/brain/protean/brain = protean.getorganslot(ORGAN_SLOT_BRAIN)
	if(protean.stat == DEAD || !istype(brain) || brain.dead || brain.transform_user)
		return "Protean должен завершить превращение и восстановить своё ядро, прежде чем управлять сервомодулем."
	return null

/obj/item/mod/module/protean_servo/on_deactivation(display_message = TRUE, deleting = FALSE)
	clear_servo()
	return ..()

/obj/item/mod/module/protean_servo/proc/clear_servo()
	for(var/datum/action/action in servo_actions)
		if(action.owner)
			action.Remove(action.owner)
	var/mob/living/wearer = servo_wearer_ref?.resolve()
	wearer?.remove_status_effect(/datum/status_effect/protean_servo_movement)
	wearer?.remove_status_effect(/datum/status_effect/protean_servo_medical)
	wearer?.remove_status_effect(/datum/status_effect/protean_servo_engineer)
	servo_wearer_ref = null

/obj/item/mod/module/protean_servo/on_unequip()
	if(active)
		on_deactivation()

/obj/item/mod/module/protean_servo/on_active_process(delta_time)
	if(activation_error())
		on_deactivation()

/datum/action/cooldown/protean_servo
	required_mobility_flags = NONE
	icon_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	background_icon_state = "bg_tech_blue"
	cooldown_time = 1 MINUTES
	shared_cooldown = PROTEAN_SERVO_TRAIT
	var/effect_type

/datum/action/cooldown/protean_servo/IsAvailable()
	if(!..())
		return FALSE
	var/obj/item/mod/module/protean_servo/module = target
	return module?.active && module.get_protean() == owner && !module.activation_error()

/datum/action/cooldown/protean_servo/Activate(atom/clicked)
	if(!IsAvailable())
		return FALSE
	var/obj/item/mod/module/protean_servo/module = target
	module.mod.wearer.apply_status_effect(effect_type)
	StartCooldown()
	return TRUE

/datum/action/cooldown/protean_servo/movement
	name = "Усилить движение"
	desc = "Ненадолго ускорить носителя, ограничив использование рук."
	button_icon_state = "jetpack"
	effect_type = /datum/status_effect/protean_servo_movement

/datum/action/cooldown/protean_servo/medical
	name = "Усилить медицинские действия"
	desc = "Ускорить операции, применение лекарств и перенос пациентов."
	button_icon_state = "defibrillator"
	effect_type = /datum/status_effect/protean_servo_medical

/datum/action/cooldown/protean_servo/engineering
	name = "Усилить строительство"
	desc = "Ускорить строительство и работу с инструментами."
	button_icon_state = "constructor"
	effect_type = /datum/status_effect/protean_servo_engineer

/datum/status_effect/protean_servo_movement
	id = "protean_servo_movement"
	duration = 7 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/protean_servo/movement
	var/list/held = list()

/datum/status_effect/protean_servo_movement/on_apply()
	if(!..())
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/protean_servo)
	for(var/obj/item/item in owner.held_items)
		held += item
		ADD_TRAIT(item, TRAIT_NODROP, PROTEAN_SERVO_TRAIT)
		RegisterSignal(item, list(COMSIG_ITEM_DROPPED, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(release_item))
	ADD_TRAIT(owner, TRAIT_RESTRAINED, PROTEAN_SERVO_TRAIT)
	return TRUE

/datum/status_effect/protean_servo_movement/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/protean_servo)
	REMOVE_TRAIT(owner, TRAIT_RESTRAINED, PROTEAN_SERVO_TRAIT)
	for(var/obj/item/item in held.Copy())
		release_item(item)
	held = null
	return ..()

/datum/status_effect/protean_servo_movement/proc/release_item(obj/item/item)
	SIGNAL_HANDLER
	REMOVE_TRAIT(item, TRAIT_NODROP, PROTEAN_SERVO_TRAIT)
	UnregisterSignal(item, list(COMSIG_ITEM_DROPPED, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	held -= item

/datum/movespeed_modifier/protean_servo
	multiplicative_slowdown = -0.4
	blacklisted_movetypes = FLYING | FLOATING

/datum/status_effect/protean_servo_medical
	id = "protean_servo_medical"
	duration = 1 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/protean_servo/medical

/datum/status_effect/protean_servo_medical/on_apply()
	if(!..())
		return FALSE
	ADD_TRAIT(owner, TRAIT_QUICKER_CARRY, PROTEAN_SERVO_TRAIT)
	ADD_TRAIT(owner, TRAIT_FASTMED, PROTEAN_SERVO_TRAIT)
	ADD_TRAIT(owner, TRAIT_PROTEAN_SURGERY, PROTEAN_SERVO_TRAIT)
	return TRUE

/datum/status_effect/protean_servo_medical/on_remove()
	REMOVE_TRAIT(owner, TRAIT_QUICKER_CARRY, PROTEAN_SERVO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_FASTMED, PROTEAN_SERVO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_PROTEAN_SURGERY, PROTEAN_SERVO_TRAIT)
	return ..()

/datum/status_effect/protean_servo_engineer
	id = "protean_servo_engineer"
	duration = 1 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/protean_servo/engineer

/datum/status_effect/protean_servo_engineer/on_apply()
	if(!..())
		return FALSE
	owner.add_actionspeed_modifier(/datum/actionspeed_modifier/protean_servo)
	ADD_TRAIT(owner, TRAIT_QUICK_BUILD, PROTEAN_SERVO_TRAIT)
	return TRUE

/datum/status_effect/protean_servo_engineer/on_remove()
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/protean_servo)
	REMOVE_TRAIT(owner, TRAIT_QUICK_BUILD, PROTEAN_SERVO_TRAIT)
	return ..()

/datum/actionspeed_modifier/protean_servo
	multiplicative_slowdown = -0.35

/atom/movable/screen/alert/status_effect/protean_servo
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'

/atom/movable/screen/alert/status_effect/protean_servo/movement
	name = "Усиление движения"
	desc = "Наниты протеана ускоряют ваше движение, ограничивая использование рук."
	icon_state = "jetpack"

/atom/movable/screen/alert/status_effect/protean_servo/medical
	name = "Медицинское усиление"
	desc = "Наниты протеана ускоряют операции, применение лекарств и перенос пациентов."
	icon_state = "defibrillator"

/atom/movable/screen/alert/status_effect/protean_servo/engineer
	name = "Инженерное усиление"
	desc = "Наниты протеана ускоряют строительство и работу с инструментами."
	icon_state = "constructor"
