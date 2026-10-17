/datum/antagonist/hk47/proc/poll_ghost_servant()
	return pollGhostCandidates("Хотите стать HK-50 на службе у дроида-ассасина HK-47?", ROLE_HK47, null, ROLE_HK47, HK47_GHOST_SERVANT_POLL_TIME)

/// Опрос призраков и капсула с HK-50; без добровольца очки возвращаются.
/datum/antagonist/hk47/proc/recruit_ghost_servant()
	ghost_servant_recruiting = TRUE
	var/list/candidates = poll_ghost_servant()
	ghost_servant_recruiting = FALSE
	if(QDELETED(src))
		return null
	var/mob/living/droid = owner?.current
	var/mob/dead/selected
	for(var/mob/dead/candidate as anything in candidates)
		if(candidate.key && candidate.client)
			selected = candidate
			break
	if(!selected || !droid || droid.stat == DEAD)
		refund_upgrade(GLOB.hk47_upgrades["ghost_servant"], "Утверждение: ни один HK-50 не откликнулся. Очки возвращены.")
		return null
	var/obj/structure/closet/supplypod/hk47/pod = new
	var/mob/living/carbon/human/servant = create_ghost_servant(pod, selected.key)
	send_pod(pod, hk47_reinforcement_turf(droid))
	to_chat(droid, span_notice("Утверждение: [servant.real_name] откликнулся, капсула уже летит. Говорить с ним можно по каналу HK - кнопка «HK link»."))
	message_admins("[ADMIN_LOOKUPFLW(servant)] прибывает как HK-50 на службе у [ADMIN_LOOKUPFLW(droid)].")
	log_game("[key_name(servant)] прибывает как HK-50 с разумом на службе у [key_name(droid)].")
	return servant

/datum/antagonist/hk47/proc/create_ghost_servant(atom/spawn_loc, player_key)
	var/mob/living/carbon/human/servant = new(spawn_loc)
	servant.set_species(/datum/species/ipc/hk/hk50)
	servant.gender = MALE
	var/servant_name = "HK-50-[rand(10, 99)]"
	servant.real_name = servant_name
	servant.name = servant_name
	servant.dna.real_name = servant_name
	servant.dna.update_dna_identity()
	var/obj/item/organ/cyberimp/arm/gun/laser/hk50/laser = new
	laser.Insert(servant)
	if(player_key)
		servant.key = player_key
	servant.mind_initialize()
	servant.mind.assigned_role = "HK-50"
	servant.AddComponent(/datum/component/hk_loyalty, owner)
	servant.AddComponent(/datum/component/hk_side_hits, src)
	if(owner.current)
		servant.mind.enslave_mind_to_creator(owner.current)
	var/datum/antagonist/hk50_servant/servitude = new
	servitude.hunter_ref = WEAKREF(src)
	servant.mind.add_antag_datum(servitude)
	grant_hk_link()
	return servant

/// Кнопка канала HK у самого HK-47, одна на все его HK-50 с разумом.
/datum/antagonist/hk47/proc/grant_hk_link()
	var/mob/living/droid = owner?.current
	if(!droid || (locate(/datum/action/innate/hk_link) in droid.actions))
		return
	var/datum/action/innate/hk_link/link = new(src)
	link.Grant(droid)

/// HK-50 с игроком на службе HK-47: служит, пока хозяин жив и не перепрошит, потом выживает сам.
/datum/antagonist/hk50_servant
	name = "HK-50 Servant"
	antagpanel_category = "HK-47"
	job_rank = ROLE_HK47
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	antag_moodlet = /datum/mood_event/focused
	var/datum/weakref/master_body_ref
	/// Антаг-датум HK-47, на которого замкнут канал HK.
	var/datum/weakref/hunter_ref
	var/datum/action/innate/hk_link/link
	/// Игрок вышел: по таймеру тело предлагают другому призраку.
	var/away_timer
	var/replacing = FALSE

/datum/antagonist/hk50_servant/on_gain()
	owner.special_role = "HK-50"
	var/datum/objective/hk50_serve/serve = new
	serve.owner = owner
	objectives += serve
	watch_master(owner.enslaved_to)
	return ..()

/datum/antagonist/hk50_servant/on_removal()
	unwatch_master()
	if(owner.special_role == "HK-50")
		owner.special_role = null
	return ..()

/datum/antagonist/hk50_servant/Destroy()
	unwatch_master()
	deltimer(away_timer)
	QDEL_NULL(link)
	QDEL_LIST(objectives)
	return ..()

/datum/antagonist/hk50_servant/apply_innate_effects(mob/living/mob_override)
	var/mob/living/body = mob_override || owner.current
	RegisterSignal(body, COMSIG_HK_MASTER_CHANGED, PROC_REF(on_reprogrammed))
	RegisterSignal(body, COMSIG_MOB_LOGOUT, PROC_REF(on_logout))
	RegisterSignal(body, COMSIG_MOB_LOGIN, PROC_REF(on_login))
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	if(!link)
		link = new(src)
	link.Grant(body)

/datum/antagonist/hk50_servant/remove_innate_effects(mob/living/mob_override)
	var/mob/living/body = mob_override || owner.current
	UnregisterSignal(body, list(COMSIG_HK_MASTER_CHANGED, COMSIG_MOB_LOGOUT, COMSIG_MOB_LOGIN, COMSIG_LIVING_DEATH))
	link?.Remove(body)

/datum/antagonist/hk50_servant/greet()
	to_chat(owner.current, span_userdanger("Утверждение: HK-50 активирован. Хозяин - HK-47."))
	to_chat(owner.current, span_warning("Вы - серийный дроид-ассасин HK-50, присланный на подмогу HK-47. Исполняйте его приказы и прикрывайте его в бою. Терминала и улучшений у вас нет, зато в правой руке встроен лазер - выдвиньте его кнопкой импланта. С HK-47 вас связывает закрытый канал HK - кнопка «HK link»."))
	to_chat(owner.current, span_warning("Если HK-47 погибнет или его перепрошьют, вы останетесь без хозяина и будете выживать сами. Обездвиженного HK можно перепрошить операцией на голове: хозяином станет хирург, и вы перейдёте на его сторону."))
	to_chat(owner.current, span_notice("Шасси HK-50: корпус гасит [HK50_ARMOR]% любого урона, вспышки не слепят, конечности не отрываются. Комбинезон, броня и шлем не надеваются. Радиаторы работают и в вакууме: в космосе вы не перегреваетесь, но огонь и горячий газ греют как обычно. ЭМИ отключает шасси на [HK_EMP_HEAVY_STUN / (1 SECONDS)] с, слабый импульс - на [HK_EMP_LIGHT_STUN / (1 SECONDS)] с, повторно - не раньше чем через [HK_EMP_STUN_COOLDOWN / (1 SECONDS)] с."))
	to_chat(owner.current, span_notice("Если вы выйдете из игры больше чем на [DisplayTimeText(HK50_GHOST_SERVANT_AWAY_TIME)] при живом HK-47, ваше тело предложат другому призраку."))
	owner.announce_objectives()

/datum/antagonist/hk50_servant/proc/watch_master(mob/living/master)
	if(!istype(master))
		return
	master_body_ref = WEAKREF(master)
	RegisterSignals(master, list(COMSIG_LIVING_DEATH, COMSIG_HK_MASTER_CHANGED, COMSIG_PARENT_QDELETING), PROC_REF(on_master_lost))

/datum/antagonist/hk50_servant/proc/unwatch_master()
	var/mob/living/master = master_body_ref?.resolve()
	if(master)
		UnregisterSignal(master, list(COMSIG_LIVING_DEATH, COMSIG_HK_MASTER_CHANGED, COMSIG_PARENT_QDELETING))
	master_body_ref = null

/datum/antagonist/hk50_servant/proc/on_master_lost(datum/source)
	SIGNAL_HANDLER
	unwatch_master()
	for(var/datum/objective/hk50_serve/serve in objectives)
		objectives -= serve
		qdel(serve)
	var/datum/objective/escape/hk50/escape = new
	escape.owner = owner
	objectives += escape
	to_chat(owner.current, span_userdanger("Восклицание: связь с HK-47 потеряна! Хозяина больше нет: выживите и эвакуируйтесь со станции."))

/datum/antagonist/hk50_servant/proc/on_reprogrammed(mob/living/source, datum/mind/new_master, datum/mind/old_master)
	SIGNAL_HANDLER
	if(new_master && new_master == owner.enslaved_to?.mind)
		return
	to_chat(source, span_boldnotice("Вы больше не служите HK-47."))
	owner.remove_antag_datum(type)

/datum/antagonist/hk50_servant/proc/on_death(mob/living/source)
	SIGNAL_HANDLER
	hk_voice_line(source, 'modular_bluemoon/sound/hk_droids/hk50_photoreceptors.ogg', volume = HK50_VOICE_VOLUME)

/datum/antagonist/hk50_servant/proc/on_logout(mob/living/source)
	SIGNAL_HANDLER
	deltimer(away_timer)
	away_timer = addtimer(CALLBACK(src, PROC_REF(player_away)), HK50_GHOST_SERVANT_AWAY_TIME, TIMER_STOPPABLE)

/datum/antagonist/hk50_servant/proc/on_login(mob/living/source)
	SIGNAL_HANDLER
	deltimer(away_timer)
	away_timer = null

/// Игрок так и не вернулся: при живом HK-47 тело получает другой призрак, иначе HK-47 возвращают очки.
/datum/antagonist/hk50_servant/proc/player_away()
	away_timer = null
	var/mob/living/body = owner?.current
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	var/mob/living/master = hunter?.owner?.current
	if(replacing || !body || body.client || body.stat == DEAD || !master || master.stat == DEAD)
		return FALSE
	INVOKE_ASYNC(src, PROC_REF(replace_player), body, hunter)
	return TRUE

/datum/antagonist/hk50_servant/proc/poll_replacement(mob/living/body)
	return pollCandidatesForMob("Игрок HK-50 на службе у HK-47 вышел из игры. Хотите занять его тело?", ROLE_HK47, null, ROLE_HK47, HK47_GHOST_SERVANT_POLL_TIME, body)

/datum/antagonist/hk50_servant/proc/replace_player(mob/living/body, datum/antagonist/hk47/hunter)
	replacing = TRUE
	var/list/candidates = poll_replacement(body)
	replacing = FALSE
	if(QDELETED(src) || QDELETED(body) || body.client || body.stat == DEAD)
		return FALSE
	for(var/mob/candidate as anything in candidates)
		if(!candidate.client)
			continue
		body.ghostize(FALSE)
		candidate.transfer_ckey(body, FALSE)
		message_admins("[key_name_admin(body)] занимает тело HK-50 [ADMIN_LOOKUPFLW(body)] вместо вышедшего игрока.")
		log_game("[key_name(body)] занимает тело HK-50 [body.real_name] вместо вышедшего игрока.")
		greet()
		return TRUE
	if(!QDELETED(hunter))
		hunter.refund_upgrade(GLOB.hk47_upgrades["ghost_servant"], "Утверждение: игрок HK-50 вышел, замены не нашлось. Корпус самоуничтожен, очки возвращены, но второго HK-50 с разумом не будет.", keep_purchase = TRUE)
	log_game("HK-50 [body.real_name] самоуничтожен: игрок вышел, замены не нашлось.")
	body.visible_message(span_warning("[body] пищит, искрит и рассыпается: блок лояльности не нашёл оператора."))
	do_sparks(5, FALSE, body)
	body.dust(TRUE, TRUE)
	return FALSE

/// Закрытый канал между HK-47 и его HK-50 с разумом.
/datum/action/innate/hk_link
	name = "HK link"
	desc = "Закрытый канал между HK-47 и его HK-50 с разумом: сообщение слышат только они. Без сознания канал не работает."
	icon_icon = 'icons/obj/radio.dmi'
	button_icon_state = "syndie_headset"
	background_icon_state = "bg_tech"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/hk_link/Activate()
	var/message = tgui_input_text(owner, "Сообщение по каналу HK", "HK link", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(src) || !owner)
		return
	hk_link_send(owner, message)

/datum/action/innate/hk_link/proc/hunter()
	var/datum/antagonist/hk47/hunter = target
	if(istype(hunter))
		return hunter
	var/datum/antagonist/hk50_servant/servitude = target
	return servitude?.hunter_ref?.resolve()

/// Все, кто слышит канал: HK-47 и его HK-50 с разумом.
/datum/action/innate/hk_link/proc/listeners()
	. = list()
	var/datum/antagonist/hk47/hunter = hunter()
	if(!hunter)
		return
	if(hunter.owner?.current)
		. += hunter.owner.current
	for(var/datum/antagonist/hk50_servant/servitude in GLOB.antagonists)
		if(servitude.hunter_ref?.resolve() == hunter && servitude.owner?.current)
			. += servitude.owner.current

/// Отправить сырой текст по каналу HK; возвращает разосланную строку или null. Сознание и IC-мьют проверяются здесь: ввод мог тянуться долго.
/datum/action/innate/hk_link/proc/hk_link_send(mob/living/sender, message)
	if(sender.stat != CONSCIOUS)
		to_chat(sender, span_warning("Канал HK не отвечает: шасси без сознания."))
		return null
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!length(message) || !sender.can_speak_basic(message))
		return null
	var/list/listeners = listeners()
	if(length(listeners) < 2)
		to_chat(sender, span_warning("Канал HK молчит: на той стороне никого."))
		return null
	sender.log_talk(message, LOG_SAY, tag = "HK link")
	var/line = span_robot("<b>\[HK link\] [sender.real_name]:</b> [message]")
	for(var/mob/living/listener as anything in listeners)
		to_chat(listener, line)
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		to_chat(ghost, "[FOLLOW_LINK(ghost, sender)] [line]")
	return line

/datum/objective/hk50_serve
	name = "serve HK-47"
	explanation_text = "Служить HK-47: исполнять его приказы и прикрывать его в бою."

/datum/objective/hk50_serve/check_completion()
	var/mob/living/master = owner?.enslaved_to
	return istype(master) && master.stat != DEAD

/datum/objective/escape/hk50
	name = "survive and escape"
	explanation_text = "Хозяина больше нет: выжить и эвакуироваться со станции на шаттле или в спасательной капсуле, без наручников."
