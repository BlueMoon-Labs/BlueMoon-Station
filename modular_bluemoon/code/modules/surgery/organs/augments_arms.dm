/obj/item/organ/cyberimp/arm/mantis_blade
	name = "Mantis blade implant"
	desc = "An integrated blade implant designed to be installed into a persons arm. Stylish and deadly; Although, being caught with this without proper permits is sure to draw unwanted attention."
	contents = newlist(/obj/item/melee/implantarmblade)
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis"
	occupies_both_arms = TRUE

/obj/item/organ/cyberimp/arm/mantis_blade/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/mantis_blade/sec_level
	name = "Corporate Mantis blade implant"
	icon_state = "mantis_corpo"
	contents = newlist(/obj/item/melee/implantarmblade/corpo)
	active_security_level = MANTIS_IMPLANT_SEC_LEVEL

/obj/item/organ/cyberimp/arm/mantis_blade/sec_level/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/mantis_blade/syndie
	name = "Gorlex Mantis blade implant"
	icon_state = "mantis_syndie"
	contents = newlist(/obj/item/melee/implantarmblade/syndie)

/obj/item/organ/cyberimp/arm/mantis_blade/syndie/l
	zone = BODY_ZONE_L_ARM

///////////////
//Monostring//
///////////////

/obj/item/organ/cyberimp/arm/monostring
	name = "Monomolecular string implant"
	desc = "A thin monomolecular filament concealed in the forearm, designed to deploy as a razor wire garrote. Occupies both arms when installed."
	contents = newlist(/obj/item/melee/implantmonostring)
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis"
	occupies_both_arms = TRUE

/obj/item/organ/cyberimp/arm/monostring/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/monostring/sec_level
	name = "Corporate Monomolecular string implant"
	icon_state = "mantis_corpo"
	contents = newlist(/obj/item/melee/implantmonostring/corpo)
	active_security_level = MANTIS_IMPLANT_SEC_LEVEL

/obj/item/organ/cyberimp/arm/monostring/sec_level/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/monostring/syndie
	name = "Agent Monomolecular string implant"
	icon_state = "mantis_syndie"
	contents = newlist(/obj/item/melee/implantmonostring/syndie)

/obj/item/organ/cyberimp/arm/monostring/syndie/l
	zone = BODY_ZONE_L_ARM

///////////////
//Gorilla Arms//
///////////////

/obj/item/organ/cyberimp/arm/gorilla
	name = "Gorilla arms implant"
	desc = "Reinforced myomer actuators integrated into both arms. Passively enhances punch damage, allows forcing airlocks open with an alt-click, and stabilizes your arms to fully negate weapon recoil. Occupies both arms when installed."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis"
	occupies_both_arms = TRUE
	actions_types = list() // пассивный имплант, выдвигать нечего
	/// Бонус к урону кулаков.
	var/punch_bonus = 5
	/// Бонус к ранам от кулаков.
	var/punch_wound_bonus = 5
	/// Время вскрытия запитанного шлюза (челюсти жизни — 5 секунд).
	var/door_force_time = 4 SECONDS
	/// Боевой бонус сейчас применён к виду владельца (для корпоративной версии, зависящей от кода тревоги).
	var/punch_bonus_applied = FALSE

/// Пассивному импланту нечего выдвигать, поэтому проверка ручного импланта на содержимое пропускается;
/// остаются только общие органные проверки (код тревоги у корпоративной версии) и исправность.
/obj/item/organ/cyberimp/arm/gorilla/activate_allowed(datum/action/action, mob/user, silent = FALSE)
	if(crit_fail || (organ_flags & ORGAN_FAILING))
		return FALSE
	return call(/obj/item/organ/proc/activate_allowed)(action, user, silent)

/obj/item/organ/cyberimp/arm/gorilla/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	RegisterSignal(M, COMSIG_MOB_ALTCLICKON, PROC_REF(on_door_altclick))
	ADD_TRAIT(M, TRAIT_NO_RECOIL, ORGAN_TRAIT)
	if(activate_allowed(silent = TRUE))
		apply_punch_bonus()

/obj/item/organ/cyberimp/arm/gorilla/Remove(special = FALSE)
	if(owner)
		UnregisterSignal(owner, COMSIG_MOB_ALTCLICKON)
		REMOVE_TRAIT(owner, TRAIT_NO_RECOIL, ORGAN_TRAIT)
	remove_punch_bonus()
	return ..()

/// Кулачный урон и вскрытие дверей зависят от activate_allowed():
/// у корпоративной версии ниже синего кода бонусы отключаются (подавление отдачи остаётся).
/obj/item/organ/cyberimp/arm/gorilla/proc/apply_punch_bonus()
	if(punch_bonus_applied || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.dna.species.punchdamagehigh += punch_bonus
	H.dna.species.punchdamagelow += punch_bonus
	H.dna.species.punchwoundbonus += punch_wound_bonus
	punch_bonus_applied = TRUE

/obj/item/organ/cyberimp/arm/gorilla/proc/remove_punch_bonus()
	if(!punch_bonus_applied || !ishuman(owner))
		punch_bonus_applied = FALSE
		return
	var/mob/living/carbon/human/H = owner
	H.dna.species.punchdamagehigh -= punch_bonus
	H.dna.species.punchdamagelow -= punch_bonus
	H.dna.species.punchwoundbonus -= punch_wound_bonus
	punch_bonus_applied = FALSE

/// Корпоративная версия: автоматически включает/выключает кулачный бонус при смене кода тревоги.
/obj/item/organ/cyberimp/arm/gorilla/code_activate()
	apply_punch_bonus()

/obj/item/organ/cyberimp/arm/gorilla/deactivate(removing = FALSE)
	. = ..()
	remove_punch_bonus()

/obj/item/organ/cyberimp/arm/gorilla/emag_act()
	. = ..()
	if(.)
		INVOKE_ASYNC(src, PROC_REF(apply_punch_bonus))

/// Альт-клик по шлюзу — вскрытие голыми руками, как челюстями жизни.
/obj/item/organ/cyberimp/arm/gorilla/proc/on_door_altclick(datum/source, atom/target)
	SIGNAL_HANDLER
	if(!owner || source != owner || !istype(target, /obj/machinery/door/airlock))
		return
	if(!activate_allowed(silent = TRUE)) // корпоративная версия ниже синего кода не вскрывает двери
		return
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !H.Adjacent(target) || !CHECK_MOBILITY(H, MOBILITY_USE))
		return
	var/obj/machinery/door/airlock/A = target
	if(A.operating || !A.density || A.prying_so_hard)
		return
	if(A.welded)
		to_chat(H, span_warning("It's welded, it won't budge!"))
		return COMSIG_MOB_CANCEL_CLICKON
	if(A.locked)
		to_chat(H, span_warning("The bolts are down, it won't budge!"))
		return COMSIG_MOB_CANCEL_CLICKON
	if(A.hasPower() && A.isElectrified())
		A.shock(H, 100) // голые руки на электрическом шлюзе — плохая идея
		return COMSIG_MOB_CANCEL_CLICKON
	INVOKE_ASYNC(src, PROC_REF(pry_door), A, H)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/organ/cyberimp/arm/gorilla/proc/pry_door(obj/machinery/door/airlock/A, mob/living/carbon/human/H)
	A.prying_so_hard = TRUE
	H.visible_message(span_danger("[H] digs [H.p_their()] fingers into [A] and starts forcing it open!"), \
		span_notice("You dig your fingers into [A] and start forcing it open..."))
	if(A.hasPower())
		playsound(A, 'sound/machines/airlock_alien_prying.ogg', 100, 1)
		if(do_after(H, door_force_time, target = A))
			A.open(2)
	else
		A.open(2) // без питания моторы не сопротивляются
	A.prying_so_hard = FALSE

/obj/item/organ/cyberimp/arm/gorilla/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/gorilla/sec_level
	name = "Corporate Gorilla arms implant"
	icon_state = "mantis_corpo"
	active_security_level = SEC_LEVEL_BLUE

/obj/item/organ/cyberimp/arm/gorilla/sec_level/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/gorilla/syndie
	name = "Agent Gorilla arms implant"
	icon_state = "mantis_syndie"
	punch_bonus = 12
	punch_wound_bonus = 12
	door_force_time = 3 SECONDS
	/// Множитель ускорения от комбо ударов (меньше = быстрее). Множится на action_cooldown_mod.
	var/combo_speed_mult = 1
	/// Минимальный множитель скорости (максимальное ускорение).
	var/min_combo_speed_mult = 0.4
	/// Коэффициент ускорения за каждый успешный удар (меньше = быстрее).
	var/combo_decay = 0.95
	/// Время последнего удара
	var/last_punch_time = 0
	/// Таймер сброса комбо
	var/combo_reset_timer

/obj/item/organ/cyberimp/arm/gorilla/syndie/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	reset_combo()
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.action_cooldown_mod *= combo_speed_mult
	RegisterSignal(M, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_punch))
	RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_deleted))

/obj/item/organ/cyberimp/arm/gorilla/syndie/Remove(special = FALSE)
	if(owner)
		UnregisterSignal(owner, list(COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_PARENT_QDELETING))
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if(combo_speed_mult != 1)
				H.action_cooldown_mod /= combo_speed_mult
	reset_combo()
	return ..()

/obj/item/organ/cyberimp/arm/gorilla/syndie/proc/on_owner_deleted(datum/source)
	SIGNAL_HANDLER
	if(owner && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(combo_speed_mult != 1)
			H.action_cooldown_mod /= combo_speed_mult
	reset_combo()

/obj/item/organ/cyberimp/arm/gorilla/syndie/proc/reset_combo()
	if(combo_reset_timer)
		deltimer(combo_reset_timer)
		combo_reset_timer = null
	if(owner && ishuman(owner) && combo_speed_mult != 1)
		var/mob/living/carbon/human/H = owner
		H.action_cooldown_mod /= combo_speed_mult
	combo_speed_mult = 1
	last_punch_time = 0

/obj/item/organ/cyberimp/arm/gorilla/syndie/proc/start_combo_timer()
	if(combo_reset_timer)
		deltimer(combo_reset_timer)
	combo_reset_timer = addtimer(CALLBACK(src, PROC_REF(on_combo_timeout)), 2 SECONDS, TIMER_STOPPABLE)

/obj/item/organ/cyberimp/arm/gorilla/syndie/proc/on_combo_timeout()
	combo_reset_timer = null
	reset_combo()

/obj/item/organ/cyberimp/arm/gorilla/syndie/proc/on_punch(mob/living/carbon/human/source, atom/target)
	SIGNAL_HANDLER
	if(QDELETED(source) || QDELETED(target) || source != owner)
		return
	if(!ishuman(source))
		return
	last_punch_time = world.time
	start_combo_timer()
	if(combo_speed_mult <= min_combo_speed_mult)
		return
	var/old_mult = combo_speed_mult
	combo_speed_mult = max(min_combo_speed_mult, combo_speed_mult * combo_decay)
	source.action_cooldown_mod = source.action_cooldown_mod / old_mult * combo_speed_mult

/obj/item/organ/cyberimp/arm/gorilla/syndie/l
	zone = BODY_ZONE_L_ARM

///////////////
//Hand Cannon//
///////////////

/obj/item/organ/cyberimp/arm/handgun
	name = "Integrated hand cannon implant"
	desc = "A compact, arm-integrated explosive launcher. The barrel deploys from the forearm and retracts when not in use."
	contents = newlist(/obj/item/gun/energy/implanthandgun)
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis"
	occupies_both_arms = FALSE

/obj/item/organ/cyberimp/arm/handgun/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/handgun/sec_level
	name = "Corporate Integrated hand cannon implant"
	icon_state = "mantis_corpo"
	contents = newlist(/obj/item/gun/energy/implanthandgun/corpo)
	active_security_level = MANTIS_IMPLANT_SEC_LEVEL

/obj/item/organ/cyberimp/arm/handgun/sec_level/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/handgun/syndie
	name = "Agent Integrated hand cannon implant"
	icon_state = "mantis_syndie"
	contents = newlist(/obj/item/gun/energy/implanthandgun/syndie)

/obj/item/organ/cyberimp/arm/handgun/syndie/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/ballistic_processor
	name = "Ballistic processor implant"
	desc = "A neural-linked ballistic processor that allows bullets to ricochet off of surfaces and home towards nearby targets."
	icon_state = "muscle"
	actions_types = list()
	zone = BODY_ZONE_R_ARM
	/// Шанс рикошета
	var/ricochet_chance = 70
	/// Максимальное количество рикошетов
	var/max_ricochets = 2
	/// Угол самонаведения в градусах
	var/homing_angle = 15
	/// Дальность поиска цели
	var/homing_range = 7

/obj/item/organ/cyberimp/arm/ballistic_processor/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/ballistic_processor/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	ADD_TRAIT(M, TRAIT_BALLISTIC_PROCESSOR, ORGAN_TRAIT)

/obj/item/organ/cyberimp/arm/ballistic_processor/Remove(special = FALSE)
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_BALLISTIC_PROCESSOR, ORGAN_TRAIT)
	return ..()

/obj/item/organ/cyberimp/brain/berserker
	name = "Berserker implant"
	desc = "A combat implant that floods the user's system with stimulants, greatly enhancing melee combat at the cost of temporarily disabling ranged weapon use. Mutually exclusive with the sandvistan."
	slot = ORGAN_SLOT_BRAIN_ANTISTUN
	icon_state = "muscle"
	actions_types = list(/datum/action/item_action/organ_action/use)
	/// Время действия берсерка
	var/berserk_time = 12 SECONDS
	/// КД берсерка
	var/cooldown_time = 5 MINUTES
	/// Резист урона
	var/armor_mult = 0.4 // 60% сопротивление
	/// Модификатор скорости удара
	var/attack_speed_mult = 0.5 // 50% ускорение
	var/active = FALSE
	var/cooldown_end = 0

/obj/item/organ/cyberimp/brain/berserker/sec_level
	name = "Corporate Berserker implant"
	armor_mult = 0.4
	attack_speed_mult = 0.5
	cooldown_time = 5 MINUTES
	berserk_time = 12 SECONDS

/obj/item/organ/cyberimp/brain/berserker/syndie
	name = "Agent Berserker implant"
	armor_mult = 0.2 // 80% сопротивление
	attack_speed_mult = 0.5 // будет удваивать скорость в логике
	berserk_time = 20 SECONDS
	cooldown_time = 5 MINUTES

/obj/item/organ/cyberimp/brain/berserker/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/cyberimp/brain/sandevistan/sand = H.getorgan(/obj/item/organ/cyberimp/brain/sandevistan)
		if(sand)
			to_chat(H, "<span class='warning'>[sand] prevents [src] from being installed!</span>")
			return FALSE
	return ..()

/obj/item/organ/cyberimp/brain/berserker/ui_action_click()
	if(active)
		to_chat(owner, "<span class='warning'>Berserker mode is already active!</span>")
		return
	if(world.time < cooldown_end)
		to_chat(owner, "<span class='warning'>[src] is still recharging!</span>")
		return
	activate_berserk()

/obj/item/organ/cyberimp/brain/berserker/proc/activate_berserk()
	if(!owner || active)
		return
	active = TRUE
	cooldown_end = world.time + cooldown_time
	var/mob/living/carbon/human/H = owner
	if(ishuman(H))
		H.physiology.armor.melee += (1 - armor_mult) * 100
		H.physiology.armor.bullet += (1 - armor_mult) * 100
		H.physiology.armor.laser += (1 - armor_mult) * 100
		// Запрещаем стрельбу из дальнобойного оружия
		ADD_TRAIT(H, TRAIT_NOGUNS, "berserker")
		// Ускорение удара
		if(istype(src, /obj/item/organ/cyberimp/brain/berserker/syndie))
			H.action_cooldown_mod *= 0.5 // удваивает скорость ударов
		else
			if(H.action_cooldown_mod > attack_speed_mult)
				H.action_cooldown_mod *= attack_speed_mult
			else
				H.action_cooldown_mod = attack_speed_mult
		to_chat(H, "<span class='notice'>You enter berserker mode! You feel unstoppable!</span>")
		addtimer(CALLBACK(src, PROC_REF(deactivate_berserk)), berserk_time)

/// ЭМИ по активному берсерку заставляет носителя избивать самого себя.
/obj/item/organ/cyberimp/brain/berserker/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!active || !ishuman(owner))
		return
	INVOKE_ASYNC(src, PROC_REF(emp_selfharm))

/obj/item/organ/cyberimp/brain/berserker/proc/emp_selfharm()
	if(!active || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.visible_message(span_danger("[H] starts attacking themselves uncontrollably!"), span_userdanger("Your berserker implant malfunctions from EMP and forces you to attack yourself!"))
	H.a_intent_change(INTENT_HARM)
	H.SetNextAction(0, flush = TRUE)
	for(var/i in 1 to 5)
		if(QDELETED(H))
			return
		H.ClickOn(H, list())
		sleep(2)

/obj/item/organ/cyberimp/brain/berserker/proc/deactivate_berserk()
	if(!active || !owner)
		active = FALSE
		return
	active = FALSE
	var/mob/living/carbon/human/H = owner
	if(ishuman(H))
		REMOVE_TRAIT(H, TRAIT_NOGUNS, "berserker")
		H.physiology.armor.melee -= (1 - armor_mult) * 100
		H.physiology.armor.bullet -= (1 - armor_mult) * 100
		H.physiology.armor.laser -= (1 - armor_mult) * 100
		// Восстанавливаем скорость удара
		if(istype(src, /obj/item/organ/cyberimp/brain/berserker/syndie))
			H.action_cooldown_mod *= 2
		else
			H.action_cooldown_mod /= attack_speed_mult
		to_chat(H, "<span class='warning'>Berserker mode subsides...</span>")

/obj/item/organ/cyberimp/brain/berserker/Remove(special = FALSE)
	if(active)
		deactivate_berserk()
	return ..()

/obj/item/melee/implantarmblade
	name = "Mantis blade"
	desc = "A blade designed to be hidden just beneath the skin. The brain is directly linked to this bad boy, allowing it to spring into action."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	icon_state = "mantis"
	force = 25
	armour_penetration = MELEE_AP_COMBAT
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_POINTY
	total_mass = TOTAL_MASS_HAND_REPLACEMENT
	attack_verb = list("slashed", "cut")
	item_flags = NEEDS_PERMIT //Beepers gets angry if you get caught with this.
	hitsound = 'sound/weapons/bladeslice.ogg'
	tool_behaviour = TOOL_CROWBAR
	can_force_powered = TRUE
	usesound = 'sound/items/jaws_pry.ogg'

/obj/item/melee/implantarmblade/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/ambidextria_attack, /obj/item/melee/implantarmblade)

/obj/item/melee/implantarmblade/corpo
	name = "Corporate Mantis blade"
	icon_state = "mantis_corpo"

/obj/item/melee/implantarmblade/syndie
	name = "Gorlex mantis blade"
	icon_state = "mantis_syndie"
	force = 30
	armour_penetration = MELEE_AP_ANTAGONIST

/obj/item/melee/implantmonostring
	name = "Monomolecular string"
	desc = "A nearly invisible monomolecular filament, perfect for cutting through flesh with surgical precision. Can be lashed out at distant targets, or wrapped around an unsuspecting victim's neck."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	icon_state = "mantis"
	force = 18
	armour_penetration = MELEE_AP_COMBAT
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_POINTY
	total_mass = TOTAL_MASS_HAND_REPLACEMENT
	reach = 3
	attack_verb = list("sliced", "severed")
	item_flags = NEEDS_PERMIT
	hitsound = 'sound/weapons/bladeslice.ogg'

/// Удар со спины (цель смотрит в ту же сторону) или по лежачей цели обвивает шею жертвы
/// струной: агрессивный захват, мгновенно переводимый в удушение (GRAB_KILL сам наносит окси-урон через life()).
/obj/item/melee/implantmonostring/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(iscarbon(M) && istype(user) && M != user && !user.pulling && (M.lying || M.dir == user.dir))
		var/mob/living/carbon/C = M
		var/victimdir = C.dir
		C.grabbedby(user, 1)
		if(user.pulling != C) // захват не удался (сверхтяж, иммунитет и т.п.) — бьём как обычно
			return ..()
		C.dir = victimdir
		user.setGrabState(GRAB_KILL)
		C.AdjustSilence(6 SECONDS)
		C.drop_all_held_items()
		C.visible_message("<span class='danger'>[user] wraps [user.p_their()] [src] around [C]'s neck and pulls it tight!</span>", \
			"<span class='userdanger'>[user] wraps [user.p_their()] [src] around your neck and pulls it tight! You are unable to speak!</span>", \
			"You hear struggling and wire strain against flesh!")
		playsound(src.loc, 'sound/weapons/cablecuff.ogg', 15, 1, -1)
		log_combat(user, C, "started choking", addition="monostring garrote")
		return TRUE
	return ..()

/obj/item/melee/implantmonostring/corpo
	name = "Corporate Monomolecular string"
	icon_state = "mantis_corpo"

/obj/item/melee/implantmonostring/syndie
	name = "Agent Monomolecular string"
	icon_state = "mantis_syndie"
	force = 28
	armour_penetration = MELEE_AP_ANTAGONIST
	reach = 5
	/// Шанс разряда тока по цели при ударе.
	var/shock_chance = 10

/obj/item/melee/implantmonostring/syndie/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	. = ..()
	if(QDELETED(M) || !isliving(M) || !prob(shock_chance))
		return
	M.Paralyze(3 SECONDS)
	M.Jitter(20)
	SEND_SIGNAL(M, COMSIG_LIVING_MINOR_SHOCK)
	do_sparks(3, FALSE, M)
	playsound(M, 'sound/weapons/egloves.ogg', 50, 1, -1)
	M.visible_message("<span class='danger'>Electric current surges down [user]'s [src], shocking [M]!</span>", \
		"<span class='userdanger'>Electric current surges down [user]'s [src], shocking you!</span>")
	if(user)
		log_combat(user, M, "shocked", addition="agent monostring discharge")

/obj/item/gun/energy/implanthandgun
	name = "Integrated hand cannon"
	desc = "A compact arm-integrated explosive launcher. No visible barrel until deployed."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis"
	item_state = "gun"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/implanthandgun)
	cell_type = /obj/item/stock_parts/cell/emproof
	can_charge = FALSE
	w_class = WEIGHT_CLASS_BULKY
	item_flags = NEEDS_PERMIT | NO_MAT_REDEMPTION
	force = 5
	selfcharge = 0
	/// Таймер перезарядки
	var/reload_timer
	/// Доступна ли пушка для выстрела
	var/ready_to_fire = TRUE
	/// Время перезарядки
	var/reload_time = 30 SECONDS
	/// Время зарядки перед выстрелом
	var/charge_time = 1.5 SECONDS
	/// Модификатор разброса при стрельбе с двух рук
	dual_wield_spread = 12
	/// Улучшенная точность при стрельбе с двух рук
	var/dual_wield_inaccuracy_mult = 0.7

/obj/item/gun/energy/implanthandgun/Initialize()
	. = ..()
	ready_to_fire = TRUE
	update_icon()

/obj/item/gun/energy/implanthandgun/proc/has_dual_wield(mob/living/user)
	if(!istype(user))
		return FALSE
	var/obj/item/gun/energy/implanthandgun/other = null
	if(user.get_active_held_item() == src)
		other = user.get_inactive_held_item()
	else
		other = user.get_active_held_item()
	if(istype(other, /obj/item/gun/energy/implanthandgun))
		return TRUE
	return FALSE

/obj/item/gun/energy/implanthandgun/afterattack(atom/target, mob/living/user, flag, params)
	if(!ready_to_fire)
		to_chat(user, "<span class='warning'>[src] is recharging!</span>")
		return
	if(!can_shoot())
		to_chat(user, "<span class='warning'>[src] is not ready!</span>")
		return
	ready_to_fire = FALSE
	user.visible_message("<span class='warning'>[user] begins charging [src]!</span>", "<span class='notice'>You start charging [src].</span>")
	playsound(user, 'sound/machines/chargers/charger.ogg', 50, 1)
	if(do_after(user, charge_time, target = user))
		if(ready_to_fire)
			return
		if(!can_shoot() || !user.is_holding(src))
			ready_to_fire = TRUE
			return
		var/dual = has_dual_wield(user)
		if(dual)
			var/obj/item/gun/energy/implanthandgun/other_gun = (user.get_active_held_item() == src ? user.get_inactive_held_item() : user.get_active_held_item())
			if(istype(other_gun) && other_gun.ready_to_fire && other_gun.can_shoot() && user.is_holding(other_gun))
				other_gun.ready_to_fire = FALSE
		if(dual)
			// При стрельбе с двух рук - повышенная точность и меньший разброс
			var/old_inacc = inaccuracy_modifier
			var/old_spread = dual_wield_spread
			inaccuracy_modifier = dual_wield_inaccuracy_mult
			dual_wield_spread = max(6, dual_wield_spread - 12)
			. = ..()
			inaccuracy_modifier = old_inacc
			dual_wield_spread = old_spread
		else
			. = ..()
		// После выстрела начинается перезарядка
		start_reload(user)
		if(dual)
			var/obj/item/gun/energy/implanthandgun/other_gun = (user.get_active_held_item() == src ? user.get_inactive_held_item() : user.get_active_held_item())
			if(istype(other_gun) && !other_gun.ready_to_fire)
				other_gun.start_reload(user)
	else
		ready_to_fire = TRUE
		to_chat(user, "<span class='warning'>Charging interrupted!</span>")

/obj/item/gun/energy/implanthandgun/proc/start_reload(mob/user)
	playsound(user, 'sound/machines/click.ogg', 40, 1)
	if(reload_timer)
		deltimer(reload_timer)
	reload_timer = addtimer(CALLBACK(src, PROC_REF(finish_reload), user), reload_time, TIMER_STOPPABLE)
	update_icon()

/obj/item/gun/energy/implanthandgun/proc/finish_reload(mob/user)
	reload_timer = null
	ready_to_fire = TRUE
	if(user && user.is_holding(src))
		to_chat(user, "<span class='notice'>[src] is ready to fire again.</span>")
		playsound(user, 'sound/machines/ping.ogg', 30, 1)
	update_icon()

/obj/item/gun/energy/implanthandgun/Destroy()
	if(reload_timer)
		deltimer(reload_timer)
	return ..()

/obj/item/gun/energy/implanthandgun/corpo
	name = "Corporate Integrated hand cannon"
	icon_state = "mantis_corpo"
	dual_wield_spread = 12
	inaccuracy_modifier = 0.7

/obj/item/gun/energy/implanthandgun/syndie
	name = "Agent Integrated hand cannon"
	icon_state = "mantis_syndie"
	ammo_type = list(/obj/item/ammo_casing/energy/implanthandgun/burst)
	reload_time = 10 SECONDS
	dual_wield_spread = 12
	inaccuracy_modifier = 0.7

/obj/item/ammo_casing/energy/implanthandgun
	projectile_type = /obj/item/projectile/bullet/implanthandgun
	select_name = "explosive"
	e_cost = 1000
	fire_sound = 'sound/weapons/rocket.ogg'
	delay = 30

/obj/item/ammo_casing/energy/implanthandgun/burst
	projectile_type = /obj/item/projectile/bullet/implanthandgun/burst
	select_name = "burst"
	e_cost = 1000
	pellets = 3
	variance = 4
	fire_sound = 'sound/weapons/laser.ogg'

/obj/item/projectile/bullet/implanthandgun
	name = "explosive charge"
	icon_state = "missile"
	damage = 50
	range = 15
	knockdown = 0
	stun = 0

/obj/item/projectile/bullet/implanthandgun/burst
	name = "mini explosive charge"
	damage = 25
	range = 12

/obj/item/projectile/bullet/implanthandgun/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	explosion(target, 0, 1, 2, 0, 0, 0, 0)
	return BULLET_ACT_HIT

/obj/item/projectile/bullet/implanthandgun/burst/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	explosion(target, 0, 0, 1, 0, 0, 0, 0)
	return BULLET_ACT_HIT
