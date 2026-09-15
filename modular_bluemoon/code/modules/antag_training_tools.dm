GLOBAL_LIST_INIT(antag_training_equipment, list(
	"baton" = list("name" = "Электродубинка", "category" = "Ближний бой", "type" = /obj/item/melee/baton/loaded),
	"knife" = list("name" = "Боевой нож", "category" = "Ближний бой", "type" = /obj/item/kitchen/knife/combat),
	"sword" = list("name" = "Энергетический меч", "category" = "Ближний бой", "type" = /obj/item/melee/transforming/energy/sword),
	"shield" = list("name" = "Щит ОМОНа", "category" = "Ближний бой", "type" = /obj/item/shield/riot),
	"flash" = list("name" = "Вспышка", "category" = "Ближний бой", "type" = /obj/item/assembly/flash/handheld),
	"cuffs" = list("name" = "Наручники", "category" = "Ближний бой", "type" = /obj/item/restraints/handcuffs),
	"laser" = list("name" = "Лазерный карабин", "category" = "Стрельба", "type" = /obj/item/gun/energy/laser),
	"egun" = list("name" = "Энергетическая винтовка", "category" = "Стрельба", "type" = /obj/item/gun/energy/e_gun),
	"disabler" = list("name" = "Дизейблер", "category" = "Стрельба", "type" = /obj/item/gun/energy/disabler),
	"pistol" = list("name" = "Пистолет 10 мм", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/automatic/pistol),
	"magazine" = list("name" = "Магазин 10 мм", "category" = "Стрельба", "type" = /obj/item/ammo_box/magazine/m10mm),
	"shotgun" = list("name" = "Дробовик", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/shotgun),
	"shells" = list("name" = "Коробка картечи", "category" = "Стрельба", "type" = /obj/item/ammo_box/shotgun/loaded/buckshot),
	"vest" = list("name" = "Бронежилет", "category" = "Защита", "type" = /obj/item/clothing/suit/armor/vest),
	"helmet" = list("name" = "Шлем", "category" = "Защита", "type" = /obj/item/clothing/head/helmet),
	"riot" = list("name" = "Костюм ОМОНа", "category" = "Защита", "type" = /obj/item/clothing/suit/armor/riot),
	"riot_helmet" = list("name" = "Шлем ОМОНа", "category" = "Защита", "type" = /obj/item/clothing/head/helmet/riot),
	"mask" = list("name" = "Противогаз", "category" = "Защита", "type" = /obj/item/clothing/mask/gas),
	"suit" = list("name" = "Скафандр", "category" = "Защита", "type" = /obj/item/clothing/suit/space),
	"space_helmet" = list("name" = "Шлем скафандра", "category" = "Защита", "type" = /obj/item/clothing/head/helmet/space),
	"oxygen" = list("name" = "Кислородный баллон", "category" = "Защита", "type" = /obj/item/tank/internals/oxygen),
	"tools" = list("name" = "Пояс с инструментами", "category" = "Инструменты", "type" = /obj/item/storage/belt/utility/full),
	"welder" = list("name" = "Сварочный аппарат", "category" = "Инструменты", "type" = /obj/item/weldingtool/largetank),
	"extinguisher" = list("name" = "Огнетушитель", "category" = "Инструменты", "type" = /obj/item/extinguisher),
	"multitool" = list("name" = "Мультитул", "category" = "Инструменты", "type" = /obj/item/multitool),
	"analyzer" = list("name" = "Газоанализатор", "category" = "Инструменты", "type" = /obj/item/analyzer),
	"rcd" = list("name" = "RCD", "category" = "Инструменты", "type" = /obj/item/construction/rcd),
	"rcd_ammo" = list("name" = "Картридж RCD", "category" = "Инструменты", "type" = /obj/item/rcd_ammo),
	"firstaid" = list("name" = "Аптечка", "category" = "Медицина", "type" = /obj/item/storage/firstaid/regular),
	"health" = list("name" = "Медицинский анализатор", "category" = "Медицина", "type" = /obj/item/healthanalyzer/advanced),
	"surgery" = list("name" = "Хирургические инструменты", "category" = "Медицина", "type" = /obj/item/storage/backpack/duffelbag/med/surgery),
	"syringe" = list("name" = "Шприц", "category" = "Медицина", "type" = /obj/item/reagent_containers/syringe),
	"beaker" = list("name" = "Большой стакан", "category" = "Медицина", "type" = /obj/item/reagent_containers/glass/beaker/large),
	"steel" = list("name" = "Металл — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/metal, "amount" = 50),
	"glass" = list("name" = "Стекло — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/glass, "amount" = 50),
	"plasteel" = list("name" = "Пласталь — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/plasteel, "amount" = 50),
	"wood" = list("name" = "Дерево — 50 досок", "category" = "Материалы", "type" = /obj/item/stack/sheet/mineral/wood, "amount" = 50),
	"cable" = list("name" = "Кабель — 30 отрезков", "category" = "Материалы", "type" = /obj/item/stack/cable_coil, "amount" = 30)
))

GLOBAL_LIST_INIT(antag_training_creatures, list(
	"human" = list("name" = "Человек без брони", "type" = /mob/living/carbon/human),
	"armored" = list("name" = "Человек в бронежилете", "type" = /mob/living/carbon/human, "armored" = TRUE),
	"corpse" = list("name" = "Тело для ритуала", "type" = /mob/living/carbon/human, "dead" = TRUE),
	"carp" = list("name" = "Космический карп", "type" = /mob/living/simple_animal/hostile/carp),
	"bear" = list("name" = "Медведь", "type" = /mob/living/simple_animal/hostile/bear),
	"operative" = list("name" = "Оперативник с ножом", "type" = /mob/living/simple_animal/hostile/syndicate),
	"gunner" = list("name" = "Оперативник со стрельбой", "type" = /mob/living/simple_animal/hostile/syndicate/ranged),
	"goliath" = list("name" = "Голиаф", "type" = /mob/living/simple_animal/hostile/asteroid/goliath)
))

/datum/antag_training_arena/proc/build_zones()
	zones = list(
		"hub" = list("name" = "Безопасный центр", "desc" = "Восстановление, снаряжение и переходы.", "bounds" = list(25, 31, 25, 31), "spawn" = locate(28, 28, private_level.z_value), "target" = locate(28, 28, private_level.z_value)),
		"melee" = list("name" = "Ближний бой", "desc" = "Открытая площадка для дистанции, ударов и контроля.", "bounds" = list(3, 24, 3, 24), "spawn" = locate(20, 13, private_level.z_value), "target" = locate(10, 13, private_level.z_value)),
		"range" = list("name" = "Тир", "desc" = "Длинная дистанция, линии стрельбы и зарядная станция.", "bounds" = list(32, 53, 3, 24), "spawn" = locate(36, 13, private_level.z_value), "target" = locate(49, 13, private_level.z_value)),
		"pve" = list("name" = "Арена противников", "desc" = "Активные враги и укрытия для боевых сценариев.", "bounds" = list(32, 53, 32, 53), "spawn" = locate(36, 42, private_level.z_value), "target" = locate(48, 42, private_level.z_value)),
		"laboratory" = list("name" = "Лаборатория", "desc" = "Ритуалы, медицина и девять рабочих мест для дел пути. Каждый ряд кроватей, столов и приборов — отдельная учебная локация.", "bounds" = list(3, 24, 32, 53), "spawn" = locate(20, 42, private_level.z_value), "target" = locate(13, 42, private_level.z_value))
	)

/datum/antag_training_arena/proc/build_ground(zone_id)
	var/list/reset_bounds = zones[zone_id]?["bounds"]
	var/list/work_tiles = reset_bounds ? block(locate(reset_bounds[1], reset_bounds[3], private_level.z_value), locate(reset_bounds[2], reset_bounds[4], private_level.z_value)) : reservation.reserved_turfs
	for(var/turf/tile as anything in work_tiles)
		yield_work()
		if(finished)
			return
		if(reset_bounds && !inside_bounds(tile, reset_bounds))
			continue
		var/is_wall = tile.x <= 2 || tile.x >= 54 || tile.y <= 2 || tile.y >= 54
		var/is_door = FALSE
		for(var/other_zone in zones)
			if(other_zone == "hub")
				continue
			var/list/bounds = zones[other_zone]["bounds"]
			if(!inside_bounds(tile, bounds))
				continue
			is_wall = tile.x == bounds[1] || tile.x == bounds[2] || tile.y == bounds[3] || tile.y == bounds[4]
			var/door_x = bounds[1] < 25 ? bounds[2] : bounds[1]
			var/door_y = round((bounds[3] + bounds[4]) / 2)
			is_door = tile.x == door_x && abs(tile.y - door_y) <= 1
			break
		tile = tile.ChangeTurf(is_wall && !is_door ? /turf/closed/indestructible : /turf/open/floor/plating)
		tile.color = null
		if(isopenturf(tile))
			var/turf/open/floor = tile
			floor.air.copy_from_turf(floor)
			floor.air_update_turf(FALSE, FALSE)
		if(is_door)
			new /obj/structure/antag_training_barrier(tile, src)
	if(!zone_id || zone_id == "pve")
		for(var/column in list(40, 45))
			for(var/row in list(37, 38, 46, 47))
				var/turf/cover = locate(column, row, private_level.z_value)
				cover.ChangeTurf(/turf/closed/wall)
	if(!zone_id || zone_id == "range")
		new /obj/machinery/recharger(locate(36, 7, private_level.z_value))
		for(var/column in list(40, 45, 50))
			for(var/row in 8 to 18)
				var/turf/line = locate(column, row, private_level.z_value)
				line.color = "#97a9be"
	if(!zone_id || zone_id == "laboratory")
		for(var/column in list(5, 11, 17))
			for(var/row in list(33, 39, 45))
				yield_work()
				if(finished)
					return
				new /obj/structure/bed(locate(column, row, private_level.z_value))
				new /obj/structure/table(locate(column + 1, row, private_level.z_value))
				new /obj/machinery/light(locate(column + 2, row, private_level.z_value))
				new /obj/structure/sink(locate(column, row + 2, private_level.z_value))
				new /obj/machinery/vending/antag_training(locate(column + 1, row + 2, private_level.z_value))
				new /obj/item/radio/intercom(locate(column + 2, row + 2, private_level.z_value))
				new /obj/structure/window(locate(column + 3, row + 2, private_level.z_value))
				new /obj/machinery/door/airlock(locate(column + 4, row + 2, private_level.z_value))
				var/turf/marker = locate(column + 1, row + 1, private_level.z_value)
				marker.color = "#63858f"

/obj/machinery/vending/antag_training
	name = "training vending machine"
	desc = "Учебный автомат для проверки взаимодействий. Выдавайте предметы через пульт полигона."
	icon_state = "snack"
	products = list()
	contraband = list()
	premium = list()

/datum/antag_training_arena/proc/inside_bounds(turf/tile, list/bounds)
	return tile?.z == private_level.z_value && tile.x >= bounds[1] && tile.x <= bounds[2] && tile.y >= bounds[3] && tile.y <= bounds[4]

/datum/antag_training_arena/proc/reset_zone(zone_id)
	var/list/zone = zone_id == "all" ? list("bounds" = list(1, ANTAG_TRAINING_SIZE, 1, ANTAG_TRAINING_SIZE)) : zones[zone_id]
	if(!zone || zone_id == "hub" || finished || resetting || world.time < next_reset_at)
		return FALSE
	next_reset_at = world.time + 5 SECONDS
	resetting = TRUE
	reset_zone_id = zone_id
	for(var/datum/antag_training_session/member as anything in members)
		if(inside_bounds(get_turf(member.current_body), zone["bounds"]))
			member.current_body.forceMove(entry_turf)
	var/list/bounds = zone["bounds"]
	for(var/turf/tile as anything in block(locate(bounds[1], bounds[3], private_level.z_value), locate(bounds[2], bounds[4], private_level.z_value)))
		clear_tile(tile, TRUE)
		yield_work()
	build_ground(zone_id == "all" ? null : zone_id)
	prune_targets()
	resetting = FALSE
	reset_zone_id = null
	return TRUE

/datum/antag_training_session/proc/restart(program_type)
	if(finished || resetting || arena?.resetting || world.time < next_restart_at || !(program_type in subtypesof(/datum/antag_training_program)))
		return FALSE
	next_restart_at = world.time + ANTAG_TRAINING_RESTART_DELAY
	resetting = TRUE
	deltimer(recovery_timer)
	recovery_timer = null
	var/mob/living/previous_body = current_body
	var/datum/mind/previous_mind = avatar_mind
	var/mob/living/carbon/human/previous_avatar = avatar
	UnregisterSignal(previous_body, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING, COMSIG_MOB_GHOSTIZE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_PRE_PLAYER_CHANGE))
	UnregisterSignal(previous_mind, COMSIG_MIND_TRANSFER)
	QDEL_NULL(controls)
	QDEL_NULL(exit_action)
	QDEL_NULL(program)
	program = new program_type
	current_body = null
	if(!create_avatar())
		previous_body.transfer_ckey(avatar, FALSE)
		current_body = avatar
		finish()
	else
		previous_body.transfer_ckey(current_body, FALSE)
	qdel(previous_mind)
	discard_body(previous_body)
	if(previous_avatar != previous_body)
		discard_body(previous_avatar)
	resetting = FALSE
	return !finished

/datum/antag_training_arena/proc/prune_targets()
	for(var/mob/living/target as anything in targets.Copy())
		if(QDELETED(target))
			targets -= target
	for(var/datum/mind/soul as anything in target_minds.Copy())
		if(QDELETED(soul) || QDELETED(soul.current))
			target_minds -= soul
			for(var/datum/antag_training_session/member as anything in members)
				var/datum/antagonist/heretic/heretic = IS_HERETIC(member.current_body)
				if(heretic)
					heretic.sacrificed_minds -= soul
			qdel(soul)

/datum/antag_training_arena/proc/spawn_target(armored = FALSE, dead = FALSE)
	return spawn_creature(dead ? "corpse" : armored ? "armored" : "human", "laboratory", FALSE)

/datum/antag_training_arena/proc/spawn_creature(template_id, zone_id, active = FALSE, datum/antag_training_session/creator)
	var/list/template = GLOB.antag_training_creatures[template_id]
	var/list/zone = zones[zone_id]
	prune_targets()
	if(!template || !zone || zone_id == "hub" || finished || resetting || length(targets) >= ANTAG_TRAINING_TARGET_LIMIT)
		return null
	var/mob_type = template["type"]
	var/mob/living/target = new mob_type(zone["target"])
	if(creator)
		target.training_owner = WEAKREF(creator)
	if(ishuman(target))
		var/mob/living/carbon/human/human = target
		human.real_name = "Учебная цель [++next_target_id]"
		human.name = human.real_name
		human.mind_initialize()
		human.mind.add_antag_datum(/datum/antagonist/ghost_role/antag_training)
		target_minds += human.mind
		human.equipOutfit(/datum/outfit/antag_training)
		if(template["armored"])
			human.equip_to_slot_or_del(new /obj/item/clothing/suit/armor/vest, ITEM_SLOT_OCLOTHING)
			human.equip_to_slot_or_del(new /obj/item/clothing/head/helmet, ITEM_SLOT_HEAD)
		if(template["dead"])
			human.death()
	else if(isanimal(target))
		var/mob/living/simple_animal/animal = target
		animal.toggle_ai(active ? AI_ON : AI_OFF)
	ADD_TRAIT(target, TRAIT_NO_MIDROUND_ANTAG, REF(src))
	ADD_TRAIT(target, TRAIT_EXEMPT_HEALTH_EVENTS, REF(src))
	targets += target
	return target

/datum/antag_training_arena/proc/prune_supplies()
	for(var/datum/weakref/item_ref as anything in issued_items.Copy())
		if(!item_ref?.resolve())
			issued_items -= item_ref
	supply_count = length(issued_items)

/datum/antag_training_arena/proc/issue_item(item_type, turf/destination, amount = 1, datum/antag_training_session/creator)
	prune_supplies()
	if(finished || resetting || get_area(destination) != room || supply_count >= ANTAG_TRAINING_SUPPLY_LIMIT)
		return null
	var/obj/item
	if(ispath(item_type, /obj/item/stack))
		item = new item_type(destination, amount)
	else
		item = new item_type(destination)
	if(creator)
		for(var/atom/movable/content as anything in item.GetAllContents())
			content.training_owner = WEAKREF(creator)
	issued_items += WEAKREF(item)
	supply_count = length(issued_items)
	return item

/datum/antag_training_session/proc/issue_equipment(equipment_id, mob/user)
	var/list/equipment = GLOB.antag_training_equipment[equipment_id]
	if(!can_control(user) || !equipment || world.time < next_supply_at)
		return FALSE
	next_supply_at = world.time + 1 SECONDS
	return !!arena.issue_item(equipment["type"], get_turf(user), equipment["amount"] || 1, src)

/obj/structure/antag_training_barrier
	name = "training barrier"
	desc = "Граница сектора пропускает участников тренировки. Цели и снаряды остаются внутри."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield1"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF
	var/datum/antag_training_arena/arena

/obj/structure/antag_training_barrier/Initialize(mapload, datum/antag_training_arena/training)
	. = ..()
	arena = training

/obj/structure/antag_training_barrier/CanPass(atom/movable/mover, turf/target)
	for(var/datum/antag_training_session/member as anything in arena?.members)
		if(mover == member.current_body)
			return TRUE
	return FALSE

/obj/structure/antag_training_barrier/Destroy()
	arena = null
	return ..()

/datum/antag_training_program/free
	name = "Снаряжение и бой"

/datum/antag_training_program/free/setup(datum/antag_training_session/session)
	return TRUE


/datum/antag_training_arena/proc/participant_minds()
	var/list/souls = list()
	for(var/datum/antag_training_session/member as anything in members)
		if(!QDELETED(member.avatar_mind))
			souls += member.avatar_mind
	return souls

/datum/antag_training_arena/proc/match_zone(atom/target)
	var/turf/tile = get_turf(target)
	for(var/zone_id in zones)
		if(inside_bounds(tile, zones[zone_id]["bounds"]))
			return zone_id
	return "corridor"

/datum/antag_training_arena/proc/request_reset(datum/antag_training_session/requester, zone_id)
	if(!(requester in members) || (!zones[zone_id] && zone_id != "all") || zone_id == "hub" || !ready || finished || resetting || pending_reset_zone || world.time < next_reset_request_at || world.time < next_reset_at)
		return FALSE
	next_reset_request_at = world.time + 5 SECONDS
	pending_reset_zone = zone_id
	for(var/datum/antag_training_session/member as anything in members)
		reset_votes[member] = member == requester
		to_chat(member.current_body, span_notice("Запрошен сброс сектора «[zone_id == "all" ? "Весь полигон" : zones[zone_id]["name"]]». Подтвердите или отмените его в пульте полигона. Нужно согласие всех участников за 45 секунд."))
	reset_vote_deadline = world.time + ANTAG_TRAINING_VOTE_TIME
	reset_vote_timer = addtimer(CALLBACK(src, PROC_REF(cancel_reset)), ANTAG_TRAINING_VOTE_TIME, TIMER_STOPPABLE)
	check_reset_votes()
	return TRUE

/datum/antag_training_arena/proc/approve_reset(datum/antag_training_session/member)
	if(!pending_reset_zone || !(member in reset_votes) || world.time >= reset_vote_deadline)
		return FALSE
	reset_votes[member] = TRUE
	check_reset_votes()
	return TRUE

/datum/antag_training_arena/proc/cancel_reset()
	deltimer(reset_vote_timer)
	reset_vote_timer = null
	pending_reset_zone = null
	reset_vote_deadline = 0
	reset_votes.Cut()

/datum/antag_training_arena/proc/member_left(datum/antag_training_session/member)
	reset_votes -= member
	if(!length(members))
		cancel_reset()
	else
		check_reset_votes()

/datum/antag_training_arena/proc/check_reset_votes()
	if(!pending_reset_zone || finished || world.time >= reset_vote_deadline)
		return
	for(var/datum/antag_training_session/member as anything in members)
		if(!reset_votes[member])
			return
	var/zone_id = pending_reset_zone
	cancel_reset()
	INVOKE_ASYNC(src, PROC_REF(reset_zone), zone_id)

/datum/antag_training_session/proc/can_manage_target(mob/living/target)
	if(QDELETED(target) || !(target in arena.targets))
		return FALSE
	for(var/datum/antag_training_session/member as anything in arena.members)
		if(member.current_body == target)
			return FALSE
	var/datum/antag_training_session/creator = target.training_owner?.resolve()
	return !creator || creator == src

/datum/antag_training_session/proc/clear_personal_entities()
	if(finished || cleaning_personal || arena.finished || arena.resetting)
		return FALSE
	cleaning_personal = TRUE
	. = arena.cleanup_owner(WEAKREF(src), src)
	cleaning_personal = FALSE

/datum/antag_training_arena/proc/cleanup_owner(datum/weakref/owner_ref, datum/antag_training_session/active_owner)
	if(!owner_ref)
		return FALSE
	for(var/datum/weakref/entity_ref as anything in created_atoms.Copy())
		yield_work()
		if(finished || (active_owner && QDELETED(active_owner)))
			return FALSE
		var/atom/movable/entity = entity_ref?.resolve()
		if(!entity || entity.training_owner != owner_ref)
			continue
		var/protected = FALSE
		for(var/datum/antag_training_session/member as anything in members)
			if(entity.contains_atom(member.current_body) || (member != active_owner && member.current_body.contains_atom(entity)))
				if(!active_owner)
					entity.training_owner = WEAKREF(member)
				protected = TRUE
				break
		if(protected)
			continue
		for(var/atom/movable/content as anything in entity.GetAllContents())
			var/datum/antag_training_session/creator = content.training_owner?.resolve()
			if(creator && content.training_owner != owner_ref)
				if(!active_owner)
					entity.training_owner = content.training_owner
				protected = TRUE
				break
		if(protected)
			continue
		if(isliving(entity))
			var/mob/living/body = entity
			QDEL_NULL(body.mind)
		qdel(entity)
	prune_targets()
	prune_supplies()
	return TRUE
