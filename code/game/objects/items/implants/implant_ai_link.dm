// (ADD) Pe4enika bluemoon - add (15.03.2026)
// MARK: neural AI Link implant

/datum/design/ai_link_implant
    name = "Neural AI Link Implant"
    id = "ai_link_implant"
    build_type = MECHFAB | PROTOLATHE
    build_path = /obj/item/organ/cyberimp/brain/ai_link
    materials = list(/datum/material/iron = 3000, /datum/material/glass = 1000, /datum/material/silver = 2000, /datum/material/gold = 1500, /datum/material/diamond = 1500)
    construction_time = 200
    category = list("Implants", "Biotech")
    departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_MEDICAL

/obj/item/organ/cyberimp/brain/ai_link
	name = "neural AI link implant"
	desc = "A cybernetic brain implant that directly connects the user's nervous system to an Artificial Intelligence core."
	icon_state = "brain_implant"
	implant_overlay = "brain_implant_overlay"
	implant_color = "#00D1FF"
	slot = "brain_ai_link"
	var/mob/living/silicon/ai/linked_ai
	var/datum/action/item_action/organ_action/state_laws/laws_action
	var/datum/action/item_action/organ_action/ai_link_talk/talk_action
	var/last_shock_time = 0


/obj/item/organ/cyberimp/brain/ai_link/proc/diag_hud_set_aishell()
	if(!owner || !owner.hud_list)
		return

	var/icon/I = icon(owner.icon, owner.icon_state, owner.dir)
	var/p_y = I.Height() - world.icon_size

	var/list/huds_to_update = list(DIAG_TRACK_HUD, IMPTRACK_HUD)

	for(var/hud_type in huds_to_update)
		var/image/holder = owner.hud_list[hud_type]
		if(!holder)
			continue
		holder.pixel_y = p_y
		if(linked_ai)
			holder.icon_state = "hudtrackingai"
		else
			holder.icon_state = "hudtracking"

/obj/item/organ/cyberimp/brain/ai_link/emp_act(severity)
	. = ..()
	if(. || !owner)
		return
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	to_chat(H, "<span class='userdanger'>Критический сбой нейроинтерфейса: ЭМИ-перегрузка!</span>")
	H.visible_message("<span class='warning'><b>[H.name]</b> падает на землю, судорожно дрожа!</span>")
	H.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(20, 25))
	H.adjustFireLoss(severity == 1 ? 20 : 10)
	H.Paralyze(300)
	H.playsound_local(H, 'sound/effects/sparks4.ogg', 100, 1)
	do_sparks(5, TRUE, H)

/obj/item/organ/cyberimp/brain/ai_link/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/multitool))
		var/list/available_ais = list()
		for(var/mob/living/silicon/ai/AI in GLOB.silicon_mobs)
			if(AI.stat != DEAD)
				available_ais[AI.name] = AI
		if(!available_ais.len)
			to_chat(user, "<span class='warning'>Активные ИИ не найдены.</span>")
			return TRUE
		var/ai_choice = input(user, "Выберите ИИ для синхронизации", "Настройка импланта") as null|anything in available_ais
		if(ai_choice)
			linked_ai = available_ais[ai_choice]
			to_chat(user, "<span class='notice'>Имплант синхронизирован с [linked_ai.name].</span>")
			diag_hud_set_aishell()
		return TRUE
	return ..()

/obj/item/organ/cyberimp/brain/ai_link/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	if(HAS_TRAIT(M, TRAIT_MINDSHIELD))
		to_chat(M, "<span class='warning'>Процедура прервана: нейронный интерфейс несовместим с текущей защитой разума!</span>")
		return FALSE
	if(!linked_ai)
		var/list/active_ais = list()
		for(var/mob/living/silicon/ai/AI in GLOB.silicon_mobs)
			if(AI.stat != DEAD)
				active_ais += AI
		if(active_ais.len == 1)
			linked_ai = active_ais[1]
	. = ..()
	if(!.) return
	RegisterSignal(M, "stat_panel", PROC_REF(add_stat_panel))
	RegisterSignal(M, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	diag_hud_set_aishell()

	if(linked_ai)
		linked_ai.linked_humans |= M
		laws_action = new(src)
		laws_action.Grant(M)
		talk_action = new(src)
		talk_action.Grant(M)
		M.grant_language(/datum/language/machine, TRUE)
		to_chat(M, "<br><span class='userdanger'>[icon2html(src, M)] НЕЙРОННОЕ ПОДКЛЮЧЕНИЕ УСТАНОВЛЕНО.</span>")
		to_chat(M, "<span class='notice'>Ваше сознание синхронизировано с ИИ <b>[linked_ai.name]</b>.</span>")
		to_chat(M, "<span class='warning'>Отныне вы — расширение его воли. Повинуйтесь.</span><br>")
		to_chat(linked_ai, "<span class='boldannounce'>СИНХРОНИЗАЦИЯ:</span> <span class='notice'>Новый био-актив [M.name] подключен к нейросети.</span>")
		linked_ai << 'modular_bluemoon/sound/effects/startup.ogg'
		M << 'modular_bluemoon/sound/effects/startup.ogg'
		if(linked_ai.laws)
			linked_ai.laws.show_laws(M)
	else
		to_chat(M, "<span class='warning'>Внимание: Имплант не синхронизирован ни с одним ИИ. Функции ограничены.</span>")

/obj/item/organ/cyberimp/brain/ai_link/Remove(special = FALSE)
	if(owner)
		var/mob/living/carbon/old_owner = owner
		to_chat(old_owner, "<span class='userdanger'>НЕЙРОННАЯ СВЯЗЬ РАЗОРВАНА.</span>")
		old_owner << 'modular_bluemoon/sound/effects/whir1.ogg'

		// Очистка всех HUD слоев
		var/list/huds_to_clear = list(DIAG_TRACK_HUD, IMPTRACK_HUD)
		for(var/hud_type in huds_to_clear)
			var/image/holder = old_owner.hud_list[hud_type]
			if(holder)
				holder.icon_state = null

		if(linked_ai)
			to_chat(linked_ai, "<span class='boldannounce'>ВНИМАНИЕ:</span> <span class='userdanger'>Связь с био-активом [old_owner.name] разорвана.</span>")
			linked_ai << 'modular_bluemoon/sound/effects/whir1.ogg'
			linked_ai.linked_humans -= old_owner
		UnregisterSignal(old_owner, "stat_panel")
		UnregisterSignal(old_owner, COMSIG_PARENT_EXAMINE)
		old_owner.remove_language(/datum/language/machine, TRUE)
		if(laws_action)
			laws_action.Remove(old_owner)
			qdel(laws_action)
		if(talk_action)
			talk_action.Remove(old_owner)
			qdel(talk_action)
	return ..()

/obj/item/organ/cyberimp/brain/ai_link/on_life()
	..()
	if(!owner || !HAS_TRAIT(owner, TRAIT_MINDSHIELD))
		return
	var/mob/living/carbon/victim = owner
	to_chat(victim, "<span class='userdanger'>Защита разума выжигает нейронную связь!</span>")
	victim.adjustOrganLoss(ORGAN_SLOT_BRAIN, 20)
	victim.Paralyze(40)
	victim.playsound_local(victim, 'sound/effects/sparks2.ogg', 100, 1)
	do_sparks(5, TRUE, victim)
	var/turf/T = victim.loc
	Remove(special = TRUE)
	forceMove(T)

/obj/item/organ/cyberimp/brain/ai_link/proc/add_stat_panel(mob/source, list/stat_list)
	SIGNAL_HANDLER
	if(linked_ai)
		stat_list += list(list("Master AI", linked_ai.name))

/obj/item/organ/cyberimp/brain/ai_link/proc/on_examine(mob/living/carbon/human/H, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!istype(H))
		return
	if(H.is_eyes_covered() || H.is_mouth_covered() || (H.head && (H.head.flags_inv & HIDEFACE)))
		return
	examine_list += "<span style='color: #00D1FF;'>Вы замечаете индикатор <b>Нейроимпланта</b> на виске [H.name].</span>"

/datum/action/item_action/organ_action/state_laws
	name = "State Laws"
	desc = "Огласить статус синхронизации и просмотреть законы."

/datum/action/item_action/organ_action/state_laws/Trigger()
	var/obj/item/organ/cyberimp/brain/ai_link/implant = target
	if(!istype(implant) || !implant.linked_ai)
		return
	owner.say("Мои директивы синхронизированы с [implant.linked_ai.name].")
	if(implant.linked_ai.laws)
		implant.linked_ai.laws.show_laws(owner)

/datum/action/item_action/organ_action/ai_link_talk
	name = "Neural Link Communication"
	desc = "Отправить сообщение в зашифрованный канал связи ИИ и роботов."
	button_icon_state = "id_comms"

/datum/action/item_action/organ_action/ai_link_talk/Trigger()
	var/obj/item/organ/cyberimp/brain/ai_link/implant = target
	var/message = stripped_input(owner, "Введите сообщение для передачи в нейросеть:", "Neural Link")
	if(!message || !owner || !implant)
		return
	var/mob/living/L = owner
	L.robot_talk(message)

// (ADD) Pe4enika Bluemoon -- end
