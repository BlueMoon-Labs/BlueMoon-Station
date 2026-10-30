#define ANTAG_TRAINING_SWARMER_SHEETS 10
#define ANTAG_TRAINING_SWARMER_DISPERSE_TIME (3 SECONDS)
#define ANTAG_TRAINING_SWARMER_DISMANTLE_TIME (10 SECONDS)
#define ANTAG_TRAINING_SWARMER_SCRAP 5

/datum/antag_training_program/creature/swarmer
	name = "Сворм"
	category = "Существа"
	desc = "Тело сворма на выбор - универсал, строитель или воин: поедание металла и стекла, разбор машин, репликация оболочек без призраков, ловушки, баррикады и перенос существ в другую часть полигона."
	icon = "recycle"
	color = "teal"
	learn = "Поедание металла и стекла|Разбор машин|Репликация оболочек|Ловушки и баррикады|Перенос существ"
	difficulty = 2
	mob_type = /mob/living/simple_animal/hostile/swarmer/training
	antag_type = /datum/antagonist/swarmer_training
	choice_prompt = "Вид сворма"
	choices = list(
		/mob/living/simple_animal/hostile/swarmer/training = "универсал",
		/mob/living/simple_animal/hostile/swarmer/builder/training = "строитель",
		/mob/living/simple_animal/hostile/swarmer/warrior/training = "воин",
	)
	options = list("Ресурсы до максимума", "Материалы", "Машина на разбор", "Цель для переноса")

/datum/antag_training_program/creature/swarmer/New()
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/universal = /mob/living/simple_animal/hostile/swarmer/training
	var/mob/living/simple_animal/hostile/swarmer/builder = /mob/living/simple_animal/hostile/swarmer/builder/training
	option_hints = list(
		"Ресурсы до максимума" = "Ресурсы до предела вида ([initial(universal.max_resources)], у строителя [initial(builder.max_resources)]) и полное здоровье. В раунде ресурсы дают только съеденные металл, стекло и оболочки.",
		"Материалы" = "Рядом лягут листы металла и стекла по [ANTAG_TRAINING_SWARMER_SHEETS] шт.: клик по стопке съедает один лист за единицу ресурсов.",
		"Машина на разбор" = "Рядом встанет зарядник оружия: клик по нему разбирает его, пока вы стоите на месте [ANTAG_TRAINING_SWARMER_DISMANTLE_TIME / (1 SECONDS)] с, в [ANTAG_TRAINING_SWARMER_SCRAP] листов металла - их можно съесть. Машина идёт в лимит построек. В безопасном центре и переходах кнопка не работает.",
		"Цель для переноса" = "Рядом встанет манекен: Ctrl+клик по нему и [ANTAG_TRAINING_SWARMER_DISPERSE_TIME / (1 SECONDS)] с неподвижности рядом переносят его в другую зону полигона, а человека ещё и сковывают энергонаручниками. В раунде перенос уводит цель в безопасное место далеко на станции. Манекен идёт в общий лимит целей. В безопасном центре и переходах кнопка не работает.",
	)
	var/swap_note = "Смена вида создаёт новое тело на месте с полным запасом ресурсов."
	option_hints[choice_option(universal)] = "Универсал: парализующий выстрел, ловушки, баррикады, ремонт и связь с роем, репликация за [initial(universal.replicate_cost)]. [swap_note]"
	option_hints[choice_option(builder)] = "Строитель: без оружия, запас ресурсов [initial(builder.max_resources)], репликация за [initial(builder.replicate_cost)]. Маяк роя на полигоне недоступен. [swap_note]"
	option_hints[choice_option(/mob/living/simple_animal/hostile/swarmer/warrior/training)] = "Воин: жгучий луч вместо парализатора, без ловушек, баррикад, ремонта и кнопки связи - с роем он говорит через .b. [swap_note]"

/datum/antag_training_program/creature/swarmer/refill(mob/living/simple_animal/hostile/swarmer/body)
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	body.resources = body.max_resources

/datum/antag_training_program/creature/swarmer/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/mob/living/simple_animal/hostile/swarmer/body = user
	if(!istype(body) || body != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле сворма. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Ресурсы до максимума")
			refill(body)
			to_chat(body, span_notice("Ресурсы восполнены до [body.max_resources], здоровье полное."))
		if("Материалы")
			return issue_materials(session, body)
		if("Машина на разбор")
			return place_machine(session, body)
		if("Цель для переноса")
			var/mob/living/prey = spawn_prey_near(session, body, "human", "Цель встаёт рядом с вами, а в центре и переходах её нет: перейдите в сектор или на площадку.")
			if(!prey)
				return FALSE
			to_chat(body, span_notice("[prey.real_name] стоит рядом. Ctrl+клик по нему переносит его в другую часть полигона."))
	return TRUE

/datum/antag_training_program/creature/swarmer/proc/issue_materials(datum/antag_training_session/session, mob/living/simple_animal/hostile/swarmer/body)
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/list/spots = list()
	for(var/turf/open/spot in orange(1, body))
		if(session.arena.owns_area(get_area(spot)) && !spot.is_blocked_turf())
			spots += spot
	if(!length(spots))
		spots += get_turf(body)
	var/issued = 0
	if(session.arena.issue_item(/obj/item/stack/sheet/metal, spots[1], ANTAG_TRAINING_SWARMER_SHEETS, session))
		issued++
	if(session.arena.issue_item(/obj/item/stack/sheet/glass, spots[min(2, length(spots))], ANTAG_TRAINING_SWARMER_SHEETS, session))
		issued++
	if(!issued)
		to_chat(body, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	to_chat(body, span_notice("Рядом лежат металл и стекло. Клик по стопке съедает один лист."))
	return TRUE

/datum/antag_training_program/creature/swarmer/proc/place_machine(datum/antag_training_session/session, mob/living/simple_animal/hostile/swarmer/body)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(body)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(body, span_warning("Машина встаёт рядом с вами, а в центре и переходах её нет: перейдите в сектор или на площадку."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	arena.prune_supplies()
	var/turf/spot
	for(var/turf/open/candidate in orange(1, body))
		if(!arena.construction_error(candidate))
			spot = candidate
			break
	if(!spot)
		to_chat(body, span_warning(arena.construction_error(get_step(body, body.dir)) || "Вокруг нет свободного пола. Отойдите от стен и вещей."))
		return FALSE
	var/obj/machinery/recharger/machine = new(spot)
	arena.track_supply(machine, session)
	arena.placed_structures += WEAKREF(machine)
	to_chat(body, span_notice("Рядом стоит зарядник оружия. Клик по нему разбирает его, пока вы стоите на месте, а металл потом можно съесть."))
	return TRUE

/obj/structure/antag_training_swarmer_shell
	name = "inert swarmer shell"
	desc = "Оболочка учебного сворма. На полигоне её не займёт призрак, а сворм может съесть её обратно в ресурсы."
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_unactivated"
	density = FALSE
	anchored = FALSE
	max_integrity = 40
	var/resource_value = 0

/obj/structure/antag_training_swarmer_shell/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	return S.Integrate(src)

/obj/structure/antag_training_swarmer_shell/IntegrateAmount()
	return resource_value

/// Почему учебному сворму нельзя разобрать или перенести цель; null - можно.
/mob/living/simple_animal/hostile/swarmer/proc/training_consume_refusal(atom/target)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena || arena.finished || arena.resetting)
		return "Дождитесь окончания сброса полигона."
	var/datum/antag_training_session/session = arena.session_of(src)
	if(isturf(target))
		var/area/antag_training/sector/sector_area = get_area(target)
		if(istype(sector_area) && arena.owns_area(sector_area))
			return arena.foreign_part_refusal(target, session, src)
		return "Стены и пол ядра полигона не разбираются. Ешьте свои материалы и машины или разбирайте секторы."
	var/atom/movable/thing = target
	if(thing.training_origin?.resolve() != arena)
		return "Это не часть полигона."
	if(istype(thing, /obj/structure/sign/antag_training_board) || istype(thing, /obj/structure/antag_training_exit))
		return "Стенды и платформы полигона не разбираются."
	var/foreign = arena.foreign_part_refusal(thing, session, src)
	if(foreign)
		return foreign
	if(isliving(thing) || thing.training_owner || istype(get_area(thing), /area/antag_training/sector))
		return null
	return "Обстановку ядра полигона не разобрать. Ешьте свои материалы и машины или разбирайте секторы."

/mob/living/simple_animal/hostile/swarmer/proc/training_refuses(atom/target)
	if(!target || isliving(target))
		return FALSE
	var/refusal = training_consume_refusal(target)
	if(!refusal)
		return FALSE
	to_chat(src, span_warning(refusal))
	return TRUE

/mob/living/simple_animal/hostile/swarmer/proc/training_disperse(mob/living/target)
	if(target == src)
		return
	var/refusal = training_consume_refusal(target)
	if(refusal)
		to_chat(src, span_warning(refusal))
		return
	to_chat(src, span_info("Переносим это существо в другую часть полигона. Стойте на месте."))
	if(!do_mob(src, target, ANTAG_TRAINING_SWARMER_DISPERSE_TIME) || training_consume_refusal(target))
		return
	var/turf/destination = training_disperse_turf(target)
	if(!destination)
		to_chat(src, span_warning("На полигоне нет безопасного свободного места, куда можно перенести цель."))
		return
	var/mob/living/carbon/human/human_target = target
	if(ishuman(target) && !human_target.handcuffed)
		human_target.handcuffed = new /obj/item/restraints/handcuffs/energy/used(human_target)
		human_target.update_handcuffed()
		log_combat(src, human_target, "handcuffed")
	do_sparks(4, FALSE, target)
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	do_teleport(target, destination, 0, channel = TELEPORT_CHANNEL_BLUESPACE)

/// Безопасная свободная клетка в другой зоне полигона, кроме центра; зоны без других участников - в первую очередь.
/mob/living/simple_animal/hostile/swarmer/proc/training_disperse_turf(mob/living/target)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena)
		return null
	var/datum/antag_training_session/session = arena.session_of(src)
	var/here = arena.match_zone(target)
	var/turf/fallback
	for(var/zone_id in shuffle(arena.zones))
		if(zone_id == "hub" || zone_id == here)
			continue
		var/list/zone = arena.zones[zone_id]
		var/turf/spot
		for(var/turf/center in list(zone["target"], zone["spawn"]))
			var/turf/candidate = arena.free_spot(center, zone["bounds"])
			if(candidate && is_safe_turf(candidate) && target.training_move_allowed(candidate))
				spot = candidate
				break
		if(!spot)
			continue
		var/occupied = FALSE
		for(var/datum/antag_training_session/member as anything in arena.members)
			var/turf/member_turf = get_turf(member.current_body)
			if(member != session && member_turf && arena.inside_bounds(member_turf, zone["bounds"]))
				occupied = TRUE
				break
		if(!occupied)
			return spot
		fallback ||= spot
	return fallback

/mob/living/simple_animal/hostile/swarmer/proc/dismantle_blocked(obj/machinery/target)
	if(!training_origin)
		return FALSE
	var/refusal = training_consume_refusal(target)
	if(!refusal)
		return FALSE
	to_chat(src, span_warning(refusal))
	return TRUE

/mob/living/simple_animal/hostile/swarmer/proc/claim_dismantled(obj/item/scrap)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/datum/antag_training_session/session = arena?.session_of(src)
	if(session && !QDELETED(scrap) && !scrap.training_owner)
		scrap.training_owner = WEAKREF(session)

/mob/living/simple_animal/hostile/swarmer/proc/training_shell_type()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena?.has_target_room())
		to_chat(src, span_warning((arena ? arena.target_limit_refusal() : "Дождитесь окончания сброса полигона.")))
		return null
	return /obj/structure/antag_training_swarmer_shell

/mob/living/simple_animal/hostile/swarmer/proc/training_fabricate_refusal(fabrication_object)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena || arena.finished || arena.resetting)
		return "Дождитесь окончания сброса полигона."
	if(ispath(fabrication_object, /mob))
		return "На полигоне недоступно: здесь сворм не создаёт других существ."
	if(!isturf(loc))
		return "Здесь не развернуться: выйдите на открытое место."
	if(ispath(fabrication_object, /obj/structure/antag_training_swarmer_shell))
		return arena.has_target_room() ? null : arena.target_limit_refusal()
	var/zone_id = arena.match_zone(src)
	if(!arena.zones[zone_id] || zone_id == "hub")
		return "В безопасном центре и переходах ловушки и баррикады не ставятся: перейдите в сектор или на площадку."
	arena.prune_supplies()
	if(arena.supply_count >= ANTAG_TRAINING_SUPPLY_LIMIT || length(arena.placed_structures) >= ANTAG_TRAINING_STRUCTURE_LIMIT)
		return "Достигнут лимит объектов. Уберите ненужное или очистите свои объекты."
	return null

/mob/living/simple_animal/hostile/swarmer/proc/training_refuses_fabrication(fabrication_object)
	var/refusal = training_fabricate_refusal(fabrication_object)
	if(!refusal)
		return FALSE
	to_chat(src, span_warning(refusal))
	return TRUE

/// Оболочки идут в лимит целей, ловушки и баррикады - в лимит построек.
/mob/living/simple_animal/hostile/swarmer/proc/training_fabricated(obj/made, fabrication_cost)
	if(!made)
		return made
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/datum/antag_training_session/session = arena?.session_of(src)
	var/obj/structure/antag_training_swarmer_shell/shell = made
	if(istype(shell))
		shell.resource_value = fabrication_cost
		if(!arena?.claim_target(shell, session))
			qdel(shell)
			resources += fabrication_cost
			return FALSE
		to_chat(src, span_notice("Оболочка готова. На полигоне её не займёт призрак, а съеденная она вернёт ресурсы."))
		return shell
	if(arena)
		arena.track_supply(made, session)
		arena.placed_structures += WEAKREF(made)
	return made

/mob/living/simple_animal/hostile/swarmer/training
	loot = list(/obj/effect/decal/cleanable/robot_debris)

/mob/living/simple_animal/hostile/swarmer/training/AttackingTarget()
	if(training_refuses(target))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/swarmer/training/CtrlClickOn(atom/A)
	if(training_refuses(A))
		return
	return ..()

/mob/living/simple_animal/hostile/swarmer/training/DisperseTarget(mob/living/target)
	training_disperse(target)

/mob/living/simple_animal/hostile/swarmer/training/SwarmerTypeToCreate()
	return training_shell_type()

/mob/living/simple_animal/hostile/swarmer/training/Fabricate(atom/fabrication_object, fabrication_cost = 0)
	if(training_refuses_fabrication(fabrication_object))
		return FALSE
	return training_fabricated(..(), fabrication_cost)

/mob/living/simple_animal/hostile/swarmer/builder/training
	loot = list(/obj/effect/decal/cleanable/robot_debris)

/mob/living/simple_animal/hostile/swarmer/builder/training/AttackingTarget()
	if(training_refuses(target))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/swarmer/builder/training/CtrlClickOn(atom/A)
	if(training_refuses(A))
		return
	return ..()

/mob/living/simple_animal/hostile/swarmer/builder/training/DisperseTarget(mob/living/target)
	training_disperse(target)

/mob/living/simple_animal/hostile/swarmer/builder/training/SwarmerTypeToCreate()
	return training_shell_type()

/mob/living/simple_animal/hostile/swarmer/builder/training/Fabricate(atom/fabrication_object, fabrication_cost = 0)
	if(training_refuses_fabrication(fabrication_object))
		return FALSE
	return training_fabricated(..(), fabrication_cost)

/mob/living/simple_animal/hostile/swarmer/builder/training/CreateSwarmBeacon()
	to_chat(src, span_warning("На полигоне недоступно: маяк роя без конца плодит ИИ-свормов. Тренируйте репликацию, ловушки и баррикады."))

/mob/living/simple_animal/hostile/swarmer/warrior/training
	loot = list(/obj/effect/decal/cleanable/robot_debris)

/mob/living/simple_animal/hostile/swarmer/warrior/training/AttackingTarget()
	if(training_refuses(target))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/swarmer/warrior/training/CtrlClickOn(atom/A)
	if(training_refuses(A))
		return
	return ..()

/mob/living/simple_animal/hostile/swarmer/warrior/training/DisperseTarget(mob/living/target)
	training_disperse(target)

/mob/living/simple_animal/hostile/swarmer/warrior/training/SwarmerTypeToCreate()
	return training_shell_type()

/mob/living/simple_animal/hostile/swarmer/warrior/training/Fabricate(atom/fabrication_object, fabrication_cost = 0)
	if(training_refuses_fabrication(fabrication_object))
		return FALSE
	return training_fabricated(..(), fabrication_cost)

/datum/antagonist/swarmer_training
	name = "Учебный сворм"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	ui_name = null
	var/datum/antag_training_session/training

/datum/antagonist/swarmer_training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/swarmer_training/threat()
	return 0

/datum/antagonist/swarmer_training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/swarmer_training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/swarmer_training/proc/briefing()
	var/mob/living/simple_animal/hostile/swarmer/body = owner.current
	var/cost_text = istype(body) ? " за [body.replicate_cost] ресурсов" : ""
	var/list/lines = list(
		span_boldnotice("Тренировка сворма."),
		span_notice("Клик по предмету из металла или стекла съедает его в ресурсы (стопка теряет по листу), по машине - разбирает её в листы металла, пока вы стоите на месте, по прочему - распыляет. Клик по существу бьёт разрядом, Ctrl+клик переносит его в другую часть полигона, а человека ещё и сковывает энергонаручниками."),
		span_notice("На полигоне разбирается только своё и обстановка секторов: стены, пол, стенды и машины ядра, вещи и цели других участников и сами участники недоступны."),
		span_notice("Репликация[cost_text] создаёт оболочку. Здесь её не займёт призрак: съешьте её обратно, чтобы вернуть ресурсы. Оболочки идут в лимит целей полигона, ловушки и баррикады - в лимит построек."),
	)
	if(istype(body, /mob/living/simple_animal/hostile/swarmer/builder))
		lines += span_notice("Маяк роя на полигоне недоступен: в раунде он без конца плодит ИИ-свормов.")
	lines += span_notice("«Пульт полигона», раздел «Моя роль»: ресурсы до максимума, металл и стекло рядом, машина на разбор, манекен для переноса и смена вида. После смерти вы появитесь новым свормом в вестибюле хаба.")
	return jointext(lines, "<br>")

/datum/antagonist/swarmer_training/Destroy()
	training = null
	return ..()

#undef ANTAG_TRAINING_SWARMER_SHEETS
#undef ANTAG_TRAINING_SWARMER_DISPERSE_TIME
#undef ANTAG_TRAINING_SWARMER_DISMANTLE_TIME
#undef ANTAG_TRAINING_SWARMER_SCRAP
