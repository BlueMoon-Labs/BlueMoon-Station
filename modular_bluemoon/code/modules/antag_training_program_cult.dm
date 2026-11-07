#define ANTAG_TRAINING_CULT_SUMMONERS 3
#define ANTAG_TRAINING_CULT_ROUND_SUMMONERS 9
#define ANTAG_TRAINING_CULT_RITUAL_RADIUS 3
#define ANTAG_TRAINING_CULT_METAL 10
#define ANTAG_TRAINING_CULT_RITES_CHARGES 500
#define ANTAG_TRAINING_CULT_NARSIE_SCRIBE (10 SECONDS)
#define ANTAG_TRAINING_CULT_NARSIE_DAMAGE 10
#define ANTAG_TRAINING_CULT_SUMMON_EFFECT (5 SECONDS)

GLOBAL_LIST_INIT(antag_training_cult_runes, list(
	"Offer" = /obj/effect/rune/convert/training,
	"Empower" = /obj/effect/rune/empower,
	"Teleport" = /obj/effect/rune/teleport/training,
	"Revive" = /obj/effect/rune/antag_training_revive,
	"Barrier" = /obj/effect/rune/wall,
	"Boil Blood" = /obj/effect/rune/blood_boil,
	"Nar'Sie" = /obj/effect/rune/narsie/training,
))
GLOBAL_LIST_EMPTY(antag_training_teleport_runes)

/datum/antag_training_arena
	/// Учебный культ этой арены: один на всех участников-культистов, обращённых и манекены-призыватели.
	var/datum/weakref/cult_team_ref

/datum/antag_training_program/antag/cult
	name = "Кровавый культист"
	category = "Культы и магия"
	desc = "Руны учебным ритуальным кинжалом, магия крови, жертвоприношение учебных целей, обращение участников и учебный призыв Нар'Си в ритуальном зале станционного макета."
	icon = "droplet"
	color = "red"
	learn = "Руны ритуальным кинжалом|Магия крови|Жертвоприношение и обращение|Призыв Нар'Си в ритуальном зале"
	difficulty = 2
	order = 6
	sector = "station"
	antag_type = /datum/antagonist/cult/training
	options = list("Заряды крови", "Рунный металл", "Цель для жертвы", "Культисты для призыва")
	var/datum/team/cult/training/joining_team

/datum/antag_training_program/antag/cult/New()
	. = ..()
	option_hints = list(
		"Заряды крови" = "Подготовленные заклинания магии крови снова получают полный запас зарядов, у Blood Rites становится [ANTAG_TRAINING_CULT_RITES_CHARGES] зарядов крови - хватит на копьё, алебарду, залп и луч, а кровь в теле восполняется. В раунде заряды не возвращаются: заклинание без зарядов исчезает, а Blood Rites копит заряды, высасывая кровь из луж и живых людей.",
		"Рунный металл" = "[ANTAG_TRAINING_CULT_METAL] листов рунного металла, а потерянный учебный кинжал выдаётся заново. Пилоны, кузни, алтари и архивы из металла ставятся только в станционном макете; сферы проклятий и факел пустоты из архивов на полигоне не работают - они бьют по станции. В раунде металл получают в начале и делают заклинанием Twisted Construction из пластали.",
		"Цель для жертвы" = "Рядом встанет учебная цель, из безопасного центра - в лаборатории. Положите её на руну Offer: живую приносят в жертву трое культистов, мёртвую - один. Жертва открывает руну Нар'Си и копит воскрешения руны Revive: первое бесплатно, каждое следующее - за [SOULS_TO_REVIVE] жертвы. В раунде цель жертвы - конкретный член экипажа, а камень душ из жертвы зовёт призрака.",
		"Культисты для призыва" = "У учебной руны Нар'Си, а без неё - вокруг вас, встанут учебные культисты, чтобы вместе с вами их стало [ANTAG_TRAINING_CULT_SUMMONERS]. Они читают руны Offer и Nar'Sie вместе с вами. В раунде для призыва нужно [ANTAG_TRAINING_CULT_ROUND_SUMMONERS] культистов в сознании и с голосом, каждая жертва снижает это число.",
	)

/datum/antag_training_program/antag/cult/grant_role(datum/antag_training_session/session)
	if(!session.arena)
		return FALSE
	var/datum/team/cult/training/team = session.arena.cult_team_ref?.resolve()
	if(QDELETED(team))
		team = new
		team.arena_ref = WEAKREF(session.arena)
		session.arena.cult_team_ref = WEAKREF(team)
	joining_team = team
	. = ..()
	joining_team = null
	if(!length(team.members))
		qdel(team)
	if(!.)
		return
	var/datum/antagonist/cult/training/cultist = session.avatar_mind.has_antag_datum(antag_type)
	cultist.issue_tools()

/datum/antag_training_program/antag/cult/apply_choice(datum/antagonist/cult/training/role)
	role.cult_team = joining_team

/datum/antag_training_program/antag/cult/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/cult/training/cultist = role(session)
	if(!cultist)
		to_chat(user, span_warning("Роль культиста снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Заряды крови")
			cultist.refill_blood_magic()
		if("Рунный металл")
			cultist.resupply()
		if("Цель для жертвы")
			var/mob/living/carbon/human/victim = place_practice_dummy(session, user)
			if(victim)
				to_chat(user, span_notice("[victim.real_name] встал[victim.ru_a()] в зоне «[dummy_zone_name(session, victim)]». Положите [victim.ru_ego()] на руну Offer: живую цель приносят в жертву трое культистов, мёртвую - один."))
		if("Культисты для призыва")
			place_summoners(session, user, cultist)
	return TRUE

/datum/antag_training_program/antag/cult/proc/place_summoners(datum/antag_training_session/session, mob/living/user, datum/antagonist/cult/training/cultist)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/team/cult/training/team = cultist.cult_team
	var/obj/effect/rune/narsie/training/rune = team.summon_rune_ref?.resolve()
	var/turf/anchor = rune ? get_turf(rune) : get_turf(user)
	var/zone_id = arena.match_zone(anchor)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(user, span_warning("Культисты встают в секторе или зоне полигона. Выйдите из центра и нажмите кнопку снова."))
		return 0
	if(world.time < arena.next_spawn_at)
		to_chat(user, span_warning("Подождите секунду перед следующей расстановкой."))
		return 0
	arena.next_spawn_at = world.time + 1 SECONDS
	var/needed = ANTAG_TRAINING_CULT_SUMMONERS - 1
	var/list/spots = list()
	for(var/turf/open/spot in range(1, anchor))
		var/mob/living/standing = locate() in spot
		if(standing && standing != user && iscultist(standing) && standing.stat == CONSCIOUS)
			needed--
		else if(spot != anchor && !standing && !is_blocked_turf(spot))
			spots += spot
	var/placed = 0
	for(var/turf/spot as anything in spots)
		if(placed >= needed)
			break
		var/mob/living/carbon/human/helper = arena.spawn_creature("human", zone_id, FALSE, session, spot)
		if(!helper)
			to_chat(user, span_warning(arena.target_limit_refusal()))
			break
		if(get_turf(helper) != spot)
			helper.forceMove(spot)
		if(!team.add_cultist(helper.mind, session))
			QDEL_NULL(helper.mind)
			qdel(helper)
			break
		placed++
	if(needed <= 0)
		to_chat(user, span_notice("Культистов у [rune ? "руны Нар'Си" : "вас"] уже достаточно для призыва."))
	else if(placed < needed)
		to_chat(user, span_warning("Встало учебных культистов: [placed] из [needed]. Освободите клетки вокруг [rune ? "руны" : "себя"] и нажмите кнопку снова."))
	else
		to_chat(user, span_notice("Учебные культисты встали у [rune ? "руны Нар'Си" : "вас"]: их [placed], вместе с вами - [ANTAG_TRAINING_CULT_SUMMONERS]."))
	return placed

/datum/action/innate/cult/mastervote/training

/datum/action/innate/cult/mastervote/training/Grant(mob/grant_to)
	return

/datum/antagonist/cult/training
	name = "Учебный культист"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	ignore_eligibility_checks = TRUE
	var/datum/antag_training_session/training
	/// Манекен-призыватель: без приветствия и без кровавого чутья на экране.
	var/practice_dummy = FALSE

/datum/antagonist/cult/training/New()
	. = ..()
	QDEL_NULL(vote)
	vote = new /datum/action/innate/cult/mastervote/training

/datum/antagonist/cult/training/create_team(datum/team/cult/new_team)
	if(istype(new_team, /datum/team/cult/training))
		cult_team = new_team

/datum/antagonist/cult/training/on_gain()
	. = ..()
	SSticker.mode.cult -= owner

/datum/antagonist/cult/training/apply_innate_effects(mob/living/mob_override)
	. = ..()
	if(practice_dummy)
		var/mob/living/body = mob_override || owner.current
		body.clear_alert("bloodsense")

/datum/antagonist/cult/training/threat()
	return 0

/datum/antagonist/cult/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/cult/training/proc/brief()
	var/list/lines = list(
		span_boldnotice("Тренировка кровавого культиста."),
		span_notice("Учебный ритуальный кинжал чертит руны только на полигоне: Offer, Empower, Teleport, Revive, Barrier, Boil Blood и Nar'Sie. Кнопка Prepare Blood Magic готовит заклинания крови, у руны Empower - быстрее и больше."),
		span_notice("Руна Offer обращает в учебного культиста другого участника полигона, а учебные цели приносит в жертву: обратить можно только живого игрока, как и в раунде."),
		span_notice("Цель - учебный призыв: принесите жертву, начертите руну Нар'Си в ритуальном зале станционного макета и прочтите её вместе с [ANTAG_TRAINING_CULT_SUMMONERS] культистами. На полигоне призыв - только эффект: без Нар'Си на станции, объявлений и конца раунда."),
		span_notice("Причастие слышат только культисты этого полигона."),
	)
	if(istype(training?.program, /datum/antag_training_program/antag/cult))
		lines += span_notice("«Пульт полигона», раздел «Моя роль»: заряды крови, рунный металл, цель для жертвы и культисты для призыва.")
	to_chat(owner.current, jointext(lines, "<br>"))
	owner.announce_objectives()

/datum/antagonist/cult/training/get_admin_commands()
	. = ..()
	. -= list("Dagger", "Dagger and Metal")

/datum/antagonist/cult/training/proc/issue_tools(metal = TRUE)
	var/mob/living/carbon/human/body = owner.current
	var/datum/antag_training_arena/arena = training?.arena
	if(!istype(body) || !arena)
		return FALSE
	. = TRUE
	if(!(locate(/obj/item/melee/cultblade/dagger/training) in body.GetAllContents()) && !stow(arena.issue_item(/obj/item/melee/cultblade/dagger/training, get_turf(body), 1, training)))
		. = FALSE
	if(metal && !stow(arena.issue_item(/obj/item/stack/sheet/runed_metal, get_turf(body), ANTAG_TRAINING_CULT_METAL, training)))
		. = FALSE

/datum/antagonist/cult/training/proc/stow(obj/item/supply)
	var/mob/living/carbon/human/body = owner.current
	if(supply && !body.equip_to_slot_if_possible(supply, ITEM_SLOT_BACKPACK, qdel_on_fail = FALSE, disable_warning = TRUE))
		body.put_in_hands(supply)
	return supply

/datum/antagonist/cult/training/proc/resupply()
	var/mob/living/body = owner.current
	if(world.time < training.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	training.next_supply_at = world.time + 1 SECONDS
	if(!issue_tools())
		to_chat(body, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	to_chat(body, span_notice("Рунный металл в рюкзаке. Учебный кинжал при вас."))
	return TRUE

/datum/antagonist/cult/training/proc/refill_blood_magic()
	var/mob/living/carbon/human/body = owner.current
	var/refilled = 0
	for(var/datum/action/innate/cult/blood_spell/spell as anything in magic.spells)
		var/full = istype(spell, /datum/action/innate/cult/blood_spell/manipulation) ? ANTAG_TRAINING_CULT_RITES_CHARGES : initial(spell.charges)
		spell.charges = max(spell.charges, full)
		if(spell.hand_magic)
			spell.hand_magic.uses = spell.charges
		spell.desc = "[spell.base_desc]<br><b><u>Has [spell.charges] use\s remaining</u></b>."
		spell.UpdateButtons()
		refilled++
	if(istype(body))
		body.blood_volume = max(body.blood_volume, BLOOD_VOLUME_NORMAL * body.blood_ratio)
	if(refilled)
		to_chat(body, span_notice("Заклинания крови снова полны: [refilled]. Кровь восполнена."))
	else
		to_chat(body, span_notice("Кровь восполнена. Подготовленных заклинаний нет: их готовит кнопка Prepare Blood Magic."))
	return refilled

/datum/antagonist/cult/training/Destroy()
	. = ..()
	training = null
	cult_team = null

/// Учебный культ: вне списка команд раунда, без счёта экипажа, своих объявлений и цели-члена экипажа.
/datum/team/cult/training
	name = "Training Cult"
	show_roundend_report = FALSE
	var/datum/weakref/arena_ref
	var/datum/weakref/summon_rune_ref
	var/sacrifices = 0
	var/revives = 0
	var/datum/objective/antag_training/cult_sacrifice/sacrifice_objective
	var/datum/objective/eldergod/training/summon_objective

/datum/team/cult/training/New()
	. = ..()
	GLOB.antagonist_teams -= src
	STOP_PROCESSING(SSprocessing, src)
	setup_objectives()

/datum/team/cult/training/setup_objectives()
	sacrifice_objective = new
	sacrifice_objective.team = src
	objectives += sacrifice_objective
	summon_objective = new
	summon_objective.team = src
	objectives += summon_objective

/datum/team/cult/training/sort_sacrifice(replacement = FALSE)
	return

/datum/team/cult/training/check_size()
	return

/datum/team/cult/training/roundend_report()
	return ""

/datum/team/cult/training/is_gamemode_hero()
	return FALSE

/datum/team/cult/training/remove_member(datum/mind/member)
	. = ..()
	if(!length(members) && !QDELETED(src))
		qdel(src)

/datum/team/cult/training/proc/can_convert(mob/living/target)
	var/datum/antag_training_arena/arena = arena_ref?.resolve()
	if(!arena?.session_of(target) || !target.mind || target.stat == DEAD || iscultist(target))
		return FALSE
	if(target.mind.unconvertable || jobban_isbanned(target, ROLE_CULTIST))
		return FALSE
	return !(HAS_TRAIT(target, TRAIT_MINDSHIELD) || issilicon(target) || is_servant_of_ratvar(target) || IS_HERETIC(target))

/datum/team/cult/training/proc/add_cultist(datum/mind/recruit_mind, datum/antag_training_session/creator)
	var/datum/antag_training_arena/arena = arena_ref?.resolve()
	if(!arena || !recruit_mind?.current || recruit_mind.has_antag_datum(/datum/antagonist/cult))
		return null
	var/datum/antagonist/cult/training/recruit = new
	recruit.training = arena.session_of(recruit_mind.current)
	if(!recruit.training)
		recruit.training = creator
		recruit.practice_dummy = TRUE
		recruit.silent = TRUE
	return recruit_mind.add_antag_datum(recruit, src)

/datum/team/cult/training/proc/record_sacrifice()
	sacrifices++
	sacrifice_objective.completed = TRUE

/datum/team/cult/training/proc/revives_left()
	return round(sacrifices / SOULS_TO_REVIVE) + 1 - revives

/// Клетка внутри ритуального зала станционного макета этой арены.
/datum/team/cult/training/proc/in_ritual_hall(turf/spot)
	var/datum/antag_training_arena/arena = arena_ref?.resolve()
	var/datum/antag_training_sector/station = arena?.sectors["station"]
	var/turf/mark = station?.landmark_turf("ritual")
	return mark && spot?.z == mark.z && get_area(spot) == get_area(mark) && get_dist(spot, mark) <= ANTAG_TRAINING_CULT_RITUAL_RADIUS

/datum/team/cult/training/proc/complete_summon(obj/effect/rune/narsie/training/rune, mob/living/summoner)
	var/turf/spot = get_turf(rune)
	summon_objective.completed = TRUE
	new /obj/effect/temp_visual/antag_training_narsie(spot)
	playsound(spot, 'sound/creatures/narsie_rises.ogg', 80, FALSE)
	log_game("[key_name(summoner)] на тренировочном полигоне выполняет учебный призыв Нар'Си.")
	for(var/datum/mind/member as anything in members)
		var/datum/antagonist/cult/training/cultist = member.has_antag_datum(/datum/antagonist/cult/training)
		if(cultist && !cultist.practice_dummy && cultist.training?.current_body == member.current)
			cultist.training.practice_message("Учебный призыв Нар'Си выполнен. В раунде Нар'Си выходит на станцию: объявления, дельта-тревога, конец раунда через несколько минут.")

/datum/team/cult/training/Destroy(force, ...)
	for(var/datum/mind/member as anything in members.Copy())
		var/datum/antagonist/cult/training/cultist = member.has_antag_datum(/datum/antagonist/cult/training)
		if(cultist)
			cultist.silent = TRUE
			member.remove_antag_datum(/datum/antagonist/cult/training)
	sacrifice_objective = null
	summon_objective = null
	QDEL_LIST(objectives)
	arena_ref = null
	summon_rune_ref = null
	return ..()

/datum/objective/antag_training/cult_sacrifice
	name = "training sacrifice"
	explanation_text = "Учебная жертва: принесите учебную цель в жертву на руне Offer."

/// Учебный призыв: не выбирает мест на станции и не засчитывается раундом, даже если Нар'Си раунда отметит все культы.
/datum/objective/eldergod/training

/datum/objective/eldergod/training/New()
	. = ..()
	summon_spots = list("ритуальный зал станционного макета")
	update_explanation_text()

/datum/objective/eldergod/training/update_explanation_text()
	explanation_text = "Учебный призыв: начертите руну Нар'Си в ритуальном зале станционного макета и прочтите её вместе с [ANTAG_TRAINING_CULT_SUMMONERS] культистами."

/datum/objective/eldergod/training/check_completion()
	return FALSE

/obj/effect/temp_visual/antag_training_narsie
	name = "Nar'Sie"
	icon = 'icons/obj/narsie_spawn_anim.dmi'
	icon_state = "narsie_spawn_anim"
	pixel_x = -236
	pixel_y = -256
	layer = MASSIVE_OBJ_LAYER
	randomdir = FALSE
	duration = ANTAG_TRAINING_CULT_SUMMON_EFFECT

/obj/effect/temp_visual/antag_training_narsie/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(settle)), 1.1 SECONDS)

/obj/effect/temp_visual/antag_training_narsie/proc/settle()
	icon = 'icons/obj/narsie.dmi'
	icon_state = ""
	animate(src, alpha = 0, time = duration - 1.1 SECONDS)

/// Культист раунда, обращаемый на полигоне любым путём (подчинение, конструкт), вступает в учебный культ арены.
/proc/antag_training_add_cultist(datum/mind/cult_mind, stun)
	var/mob/living/body = cult_mind.current
	var/area/antag_training/place = get_area(body)
	var/datum/antag_training_arena/arena = body.training_origin?.resolve() || (istype(place) ? place.arena : null)
	var/datum/team/cult/training/team = arena?.cult_team_ref?.resolve()
	if(QDELETED(team) || !team.add_cultist(cult_mind))
		log_game("[key_name(body)] на тренировочном полигоне не обращён: учебного культа на арене нет.")
		return FALSE
	if(stun)
		body.Unconscious(100)
	return TRUE

/obj/item/melee/cultblade/dagger/training
	name = "training ritual dagger"
	desc = "Учебный ритуальный кинжал полигона. Чертит учебные руны и только на полигоне."

/obj/item/melee/cultblade/dagger/training/scribe_rune(mob/living/user)
	if(!antag_training_cult_team(user))
		to_chat(user, span_warning("Учебный кинжал слушается только учебного культиста полигона."))
		return null
	if(!check_rune_turf(get_turf(user), user))
		return null
	var/choice = tgui_input_list(user, "Какую руну начертить?", "Учебные руны", GLOB.antag_training_cult_runes)
	var/obj/effect/rune/rune_type = GLOB.antag_training_cult_runes[choice]
	if(!rune_type || QDELETED(src) || !Adjacent(user) || user.incapacitated())
		return null
	var/keyword
	if(initial(rune_type.req_keyword))
		keyword = stripped_input(user, "Слово для новой руны.", "Слова силы")
		if(!keyword)
			return null
	return scribe(user, rune_type, keyword)

/// Чертит выбранную руну под культистом; руна Нар'Си - только после жертвы и только в ритуальном зале.
/obj/item/melee/cultblade/dagger/training/proc/scribe(mob/living/user, obj/effect/rune/rune_type, keyword)
	var/turf/spot = get_turf(user)
	var/datum/team/cult/training/team = antag_training_cult_team(user)
	if(!team || QDELETED(src) || user.incapacitated() || !check_rune_turf(spot, user))
		return null
	var/list/shields = list()
	if(ispath(rune_type, /obj/effect/rune/narsie/training))
		if(!team.sacrifices)
			to_chat(user, span_warning("Сначала принесите учебную жертву на руне Offer. В раунде руну Нар'Си не начертить, пока не принесена в жертву цель культа."))
			return null
		if(!team.in_ritual_hall(spot))
			to_chat(user, span_warning("Руну Нар'Си чертят в ритуальном зале станционного макета, не дальше [ANTAG_TRAINING_CULT_RITUAL_RADIUS] клеток от его центра. В раунде место призыва - одна из трёх областей станции из цели культа."))
			return null
		to_chat(user, span_notice("В раунде на этом шаге всей станции объявляют, где чертится руна, а черчение длится 50 секунд."))
		for(var/turf/around as anything in spiral_range_turfs(1, user, 1))
			shields += new /obj/structure/emergency_shield/sanguine(around)
	user.visible_message(span_warning("[user] [user.blood_volume ? "надрезает руку и выводит знаки собственной кровью" : "начинает чертить странный узор"]!"), \
		span_cult("Вы [user.blood_volume ? "надрезаете руку и " : ""]начинаете чертить знак Геометра."))
	if(user.blood_volume)
		user.apply_damage(initial(rune_type.scribe_damage), BRUTE, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
	var/delay = initial(rune_type.scribe_delay)
	if(istype(spot, /turf/open/floor/engine/cult) && !ispath(rune_type, /obj/effect/rune/narsie))
		delay *= 0.5
	var/drawn = do_after(user, delay, target = spot)
	QDEL_LIST(shields)
	if(!drawn || !check_rune_turf(spot, user))
		return null
	var/obj/effect/rune/rune = new rune_type(spot, keyword)
	rune.add_mob_blood(user)
	if(istype(rune, /obj/effect/rune/narsie/training))
		team.summon_rune_ref = WEAKREF(rune)
	user.visible_message(span_warning("[user] заканчивает странный круг."), span_cult("Руна [rune.cultist_name] готова: [rune.cultist_desc]"))
	return rune

/obj/item/melee/cultblade/dagger/training/check_rune_turf(turf/T, mob/user)
	if(isspaceturf(T))
		to_chat(user, span_warning("В космосе руну не начертить."))
		return FALSE
	if(locate(/obj/effect/rune) in T)
		to_chat(user, span_cult("Здесь уже есть руна."))
		return FALSE
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena?.owns_area(get_area(T)))
		to_chat(user, span_warning("Учебный кинжал чертит только на своём полигоне."))
		return FALSE
	if(arena.match_zone(T) == "hub")
		to_chat(user, span_warning("В безопасном центре руны не чертятся: перейдите в сектор или боевую зону."))
		return FALSE
	return TRUE

/proc/antag_training_cult_team(mob/living/cultist)
	var/datum/antagonist/cult/training/role = cultist?.mind?.has_antag_datum(/datum/antagonist/cult/training)
	var/datum/team/cult/training/team = role?.cult_team
	return istype(team) && !QDELETED(team) ? team : null

/obj/effect/rune
	/// Учебная руна полигона: настоящий кинжал её не чертит.
	var/antag_training_rune = FALSE

/// Распев и свечение общей руны: учебные подтипы обходят станционные проверки родителя.
/obj/effect/rune/proc/antag_training_chant(list/invokers)
	for(var/invoker in invokers)
		if(isliving(invoker))
			var/mob/living/chanter = invoker
			if(invocation)
				chanter.say(invocation, language = /datum/language/common, ignore_spam = TRUE, forced = "cult invocation")
				playsound(get_turf(chanter), BLOOD_SCREAMS_PICK, 65, 1, 1, ignore_walls = FALSE)
			if(invoke_damage)
				chanter.apply_damage(invoke_damage, BRUTE)
		else if(istype(invoker, /obj/item/toy/plush/narplush))
			var/obj/item/toy/plush/narplush/plush = invoker
			plush.visible_message(span_cultitalic("[plush] громко пищит!"))
	do_invoke_glow()

/obj/effect/rune/convert/training
	antag_training_rune = TRUE
	cultist_desc = "обращает живого участника полигона в учебного культиста, а учебную цель или того, кого не обратить, приносит в жертву."
	req_cultists_text = "2 для обращения, 3 для живой жертвы."

/obj/effect/rune/convert/training/invoke(list/invokers)
	if(rune_in_use)
		return
	var/mob/living/first = invokers[1]
	var/datum/team/cult/training/team = antag_training_cult_team(first)
	if(!team)
		to_chat(first, span_warning("Учебная руна откликается только учебному культу полигона."))
		fail_invoke()
		return
	var/list/candidates = list()
	for(var/mob/living/candidate in get_turf(src))
		if(!iscultist(candidate))
			candidates += candidate
	if(!length(candidates))
		fail_invoke()
		return
	var/mob/living/target = pick(candidates)
	if(HAS_TRAIT(target, TRAIT_SACRIFICED))
		to_chat(invokers, span_warning("[target] уже принесен[target.ru_a()] в жертву."))
		fail_invoke()
		return
	rune_in_use = TRUE
	visible_message(span_warning("[src] вспыхивает кроваво-красным!"))
	var/oldcolor = color
	color = RUNE_COLOR_DARKRED
	if(target.stat != DEAD && is_servant_of_ratvar(target))
		invocation = "Mah'weyh pleggh at e'ntrath."
		antag_training_chant(invokers)
		target.visible_message(span_warning("Глаза [target] вспыхивают упрямым жёлтым светом!"))
		target.DefaultCombatKnockdown(80)
	else if(team.can_convert(target))
		invocation = "Mah'weyh pleggh at e'ntrath."
		antag_training_chant(invokers)
		do_convert(target, invokers)
	else
		invocation = "Barhah hra zar'garis."
		antag_training_chant(invokers)
		do_sacrifice(target, invokers)
	animate(src, color = oldcolor, time = 5)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 5)
	rune_in_use = FALSE

/obj/effect/rune/convert/training/do_convert(mob/living/convertee, list/invokers)
	if(length(invokers) < 2)
		to_chat(invokers, span_warning("Чтобы обратить [convertee], нужны двое культистов у руны."))
		return FALSE
	if(convertee.anti_magic_check(TRUE, TRUE, chargecost = 0))
		to_chat(invokers, span_warning("Разум [convertee] что-то защищает."))
		return FALSE
	var/mob/living/first = invokers[1]
	var/datum/team/cult/training/team = antag_training_cult_team(first)
	var/datum/antagonist/cult/training/recruit = team?.add_cultist(convertee.mind)
	if(!recruit)
		to_chat(invokers, span_warning("[convertee] не принимает знак Геометра."))
		return FALSE
	var/brutedamage = convertee.getBruteLoss()
	var/burndamage = convertee.getFireLoss()
	convertee.adjustBruteLoss(-(brutedamage * 0.75))
	convertee.adjustFireLoss(-(burndamage * 0.75))
	convertee.visible_message(span_warning("[convertee] корчится от боли, а знаки под [convertee.ru_na()] наливаются кровью!"), span_cultlarge("<i>АААААААААААААА-</i>"))
	var/datum/antag_training_arena/arena = team.arena_ref?.resolve()
	arena?.issue_item(/obj/item/melee/cultblade/dagger/training, get_turf(src), 1, recruit.training)
	to_chat(convertee, span_cultitalic("<b>Кровь стучит в висках, мир становится красным. Вы - учебный культист Геометра: служите культу полигона и помогите ему призвать Нар'Си.</b>"))
	if(ishuman(convertee))
		var/mob/living/carbon/human/human_convertee = convertee
		human_convertee.uncuff()
		human_convertee.stuttering = 0
		human_convertee.cultslurring = 0
	return TRUE

/obj/effect/rune/convert/training/do_sacrifice(mob/living/sacrificial, list/invokers)
	var/mob/living/first = invokers[1]
	var/datum/team/cult/training/team = antag_training_cult_team(first)
	if(!team)
		return FALSE
	if((ishuman(sacrificial) || iscyborg(sacrificial)) && sacrificial.stat != DEAD && length(invokers) < 3)
		to_chat(invokers, span_cultitalic("[sacrificial] слишком крепко держится за жизнь: нужны трое культистов у руны."))
		return FALSE
	team.record_sacrifice()
	new /obj/effect/temp_visual/cult/sac(get_turf(src))
	to_chat(invokers, span_cultlarge("\"Я принимаю эту жертву.\""))
	ADD_TRAIT(sacrificial, TRAIT_SACRIFICED, "sacrificed")
	if(iscyborg(sacrificial))
		var/mob/living/silicon/robot/bot = sacrificial
		playsound(sacrificial, 'sound/magic/disable_tech.ogg', 100, TRUE)
		bot.cyborg_deconstruct()
	else if(ishuman(sacrificial))
		var/mob/living/carbon/human/victim = sacrificial
		playsound(victim, 'sound/magic/disintegrate.ogg', 100, TRUE)
		victim.spew_organ(2, 6, exclude_brain = TRUE)
		victim.death()
	return TRUE

/obj/effect/rune/teleport/training
	antag_training_rune = TRUE
	cultist_desc = "переносит всё, что на ней стоит, к другой учебной руне Teleport этого полигона."

/obj/effect/rune/teleport/training/Initialize(mapload, set_keyword)
	. = ..()
	GLOB.teleport_runes -= src
	GLOB.antag_training_teleport_runes += src

/obj/effect/rune/teleport/training/Destroy()
	GLOB.antag_training_teleport_runes -= src
	return ..()

/obj/effect/rune/teleport/training/invoke(list/invokers)
	var/mob/living/user = invokers[1]
	var/list/destinations = list()
	var/list/used_names = list()
	for(var/obj/effect/rune/teleport/training/other as anything in GLOB.antag_training_teleport_runes)
		if(other != src && other.training_origin == training_origin)
			destinations[avoid_assoc_duplicate_keys(other.listkey, used_names)] = other
	if(!length(destinations))
		to_chat(user, span_warning("На полигоне нет другой учебной руны Teleport."))
		fail_invoke()
		return
	var/choice = length(destinations) == 1 ? destinations[1] : tgui_input_list(user, "Куда перенести?", "Учебная руна Teleport", destinations)
	var/obj/effect/rune/teleport/training/destination = destinations[choice]
	if(QDELETED(src) || QDELETED(destination) || !Adjacent(user) || user.incapacitated())
		fail_invoke()
		return
	var/turf/target = get_turf(destination)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena?.owns_area(get_area(target)) || arena.match_zone(target) == "hub")
		fail_invoke()
		return
	if(is_blocked_turf(target, TRUE))
		to_chat(user, span_warning("Руна назначения загорожена."))
		fail_invoke()
		return
	var/turf/origin = get_turf(src)
	var/list/cargo = list()
	for(var/atom/movable/thing in origin)
		if(!thing.anchored && thing != src)
			cargo += thing
	if(!length(cargo))
		fail_invoke()
		return
	antag_training_chant(invokers)
	var/moved = 0
	for(var/atom/movable/thing as anything in cargo)
		if(!do_teleport(thing, target, forceMove = (thing != user), channel = TELEPORT_CHANNEL_CULT))
			continue
		moved++
		if(ishuman(thing))
			new /obj/effect/temp_visual/dir_setting/cult/phase/out(origin, thing.dir)
			new /obj/effect/temp_visual/dir_setting/cult/phase(target, thing.dir)
	if(!moved)
		to_chat(user, span_cultitalic("Руна вспыхивает, но ничего не уходит."))
		fail_invoke()
		return
	target.visible_message(span_warning("Над руной с хлопком появляется что-то из ниоткуда!"))

/// Руна воскрешения учебного культа: бюджет - жертвы своей команды, неактивного культиста не отдаёт призракам.
/obj/effect/rune/antag_training_revive
	cultist_name = "Revive"
	invocation = "Pasnar val'keriam usinar. Savrae ines amutan. Yam'toth remium il'tarat."
	icon_state = "golem"
	color = RUNE_COLOR_MEDIUMRED
	antag_training_rune = TRUE

/obj/effect/rune/antag_training_revive/Initialize(mapload, set_keyword)
	. = ..()
	cultist_desc = "воскрешает мёртвого культиста на руне. Первое воскрешение бесплатное, каждое следующее - за [SOULS_TO_REVIVE] учебные жертвы."

/obj/effect/rune/antag_training_revive/examine(mob/user)
	. = ..()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/datum/team/cult/training/team = arena?.cult_team_ref?.resolve()
	if(team && (iscultist(user) || user.stat == DEAD))
		. += "<b>Воскрешений осталось:</b> [max(team.revives_left(), 0)]"

/obj/effect/rune/antag_training_revive/invoke(list/invokers)
	var/mob/living/user = invokers[1]
	var/datum/team/cult/training/team = antag_training_cult_team(user)
	if(!team)
		to_chat(user, span_warning("Учебная руна откликается только учебному культу полигона."))
		fail_invoke()
		return
	var/mob/living/patient
	for(var/mob/living/candidate in get_turf(src))
		if(iscultist(candidate) && candidate.stat == DEAD)
			patient = candidate
			break
	if(!patient)
		to_chat(user, span_cultitalic("На руне нет мёртвого культиста."))
		fail_invoke()
		return
	if(team.revives_left() <= 0)
		to_chat(user, span_warning("Для следующего воскрешения культу нужно больше жертв: по [SOULS_TO_REVIVE] на каждое."))
		fail_invoke()
		return
	team.revives++
	antag_training_chant(invokers)
	patient.revive(full_heal = TRUE, admin_revive = TRUE)
	patient.grab_ghost()
	to_chat(patient, span_cultlarge("\"PASNAR SAVRAE YAM'TOTH. Восстань.\""))
	patient.visible_message(span_warning("[patient] резко вдыхает, в глазах вспыхивает красный свет."), span_cultlarge("Вы вырываетесь из пустоты. Вы живы!"))

/obj/effect/rune/narsie/training
	antag_training_rune = TRUE
	scribe_delay = ANTAG_TRAINING_CULT_NARSIE_SCRIBE
	scribe_damage = ANTAG_TRAINING_CULT_NARSIE_DAMAGE

/obj/effect/rune/narsie/training/Initialize(mapload, set_keyword)
	. = ..()
	GLOB.poi_list -= src
	cultist_desc = "учебный призыв Геометра: нужно [ANTAG_TRAINING_CULT_SUMMONERS] культиста у руны, считая читающего. Только эффект, станция его не видит."
	req_cultists_text = "[ANTAG_TRAINING_CULT_SUMMONERS]"

/obj/effect/rune/narsie/training/invoke(list/invokers)
	if(used)
		return
	var/mob/living/user = invokers[1]
	var/datum/team/cult/training/team = antag_training_cult_team(user)
	if(!team || team.arena_ref?.resolve() != training_origin?.resolve())
		to_chat(user, span_warning("Учебная руна откликается только учебному культу этого полигона."))
		fail_invoke()
		return
	if(!team.in_ritual_hall(get_turf(src)))
		to_chat(user, span_cultlarge("Завеса здесь слишком крепка: учебный призыв идёт только в ритуальном зале станционного макета."))
		fail_invoke()
		return
	if(length(invokers) < ANTAG_TRAINING_CULT_SUMMONERS)
		to_chat(user, span_danger("Нужно ещё культистов у руны: [ANTAG_TRAINING_CULT_SUMMONERS - length(invokers)]. Кнопка «Культисты для призыва» в пульте поставит учебных."))
		fail_invoke()
		return
	used = TRUE
	antag_training_chant(invokers)
	team.complete_summon(src, user)
	qdel(src)

/obj/effect/rune/narsie/training/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/melee/cultblade/dagger) && iscultist(user))
		user.visible_message(span_warning("[user] начинает стирать [src]..."), span_notice("Вы начинаете стирать [src]..."))
		if(do_after(user, 5 SECONDS, target = src))
			qdel(src)
		return
	if(istype(I, /obj/item/storage/book/bible) || istype(I, /obj/item/nullrod))
		user.say("BEGONE FOUL MAGICKS!!", forced = "bible")
		qdel(src)

#undef ANTAG_TRAINING_CULT_SUMMONERS
#undef ANTAG_TRAINING_CULT_ROUND_SUMMONERS
#undef ANTAG_TRAINING_CULT_RITUAL_RADIUS
#undef ANTAG_TRAINING_CULT_METAL
#undef ANTAG_TRAINING_CULT_RITES_CHARGES
#undef ANTAG_TRAINING_CULT_NARSIE_SCRIBE
#undef ANTAG_TRAINING_CULT_NARSIE_DAMAGE
#undef ANTAG_TRAINING_CULT_SUMMON_EFFECT
