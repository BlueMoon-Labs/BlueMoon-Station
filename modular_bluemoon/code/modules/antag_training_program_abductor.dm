#define ANTAG_TRAINING_ABDUCTOR_FIRST_TEAM 1000
#define ANTAG_TRAINING_ABDUCTOR_CREDITS 10
#define ANTAG_TRAINING_ABDUCTOR_GLAND /obj/item/organ/heart/gland/ventcrawling
/// Как вживление хирургией абдукторов: железа ждёт опыта и не включается сразу.
#define ANTAG_TRAINING_ABDUCTOR_SURGERY_INSERT 2
#define ANTAG_TRAINING_ABDUCTOR_SPECIMEN_SLEEP (16 SECONDS)

/datum/antag_training_arena
	/// Учебная команда абдукторов этой арены: один корабль в отсеке макета на всех участников-абдукторов.
	var/datum/weakref/abductor_team_ref

/datum/antag_training_program/antag/abductor
	abstract_type = /datum/antag_training_program/antag/abductor
	category = "Чужаки"
	options = list("Цель с железой", "Пополнить кредиты")
	var/datum/team/abductor_team/training/joining_team

/datum/antag_training_program/antag/abductor/New()
	. = ..()
	option_hints = list(
		"Цель с железой" = "Рядом встанет учебная цель с уже вживлённой железой, из безопасного центра - в лаборатории. Доставьте её к экспериментатору в отсеке абдукторов, перетащите внутрь и запустите опыт. В раунде подопытный - живой член экипажа с игроком, а железу вживляет учёный хирургией.",
		"Пополнить кредиты" = "В консоли корабля станет [ANTAG_TRAINING_ABDUCTOR_CREDITS] кредитов на снаряжение. В раунде кредиты дают только опыты: по одному за каждую железу подопытного.",
	)

/datum/antag_training_program/antag/abductor/grant_role(datum/antag_training_session/session)
	if(!session.arena)
		return FALSE
	var/datum/team/abductor_team/training/crew = session.arena.abductor_team_ref?.resolve()
	if(QDELETED(crew))
		crew = new
		session.arena.abductor_team_ref = WEAKREF(crew)
	joining_team = crew
	. = ..()
	joining_team = null
	if(!length(crew.members))
		qdel(crew)
	if(!.)
		return
	avatar_name = session.avatar_mind.current.real_name
	INVOKE_ASYNC(src, PROC_REF(board_ship), session, TRUE)

/datum/antag_training_program/antag/abductor/apply_choice(datum/antagonist/abductor/training/role)
	role.team = joining_team

/// Ставит корабль в отсек абдукторов станционного макета, привязывает снаряжение команды и при move_body переносит участника на борт.
/datum/antag_training_program/antag/abductor/proc/board_ship(datum/antag_training_session/session, move_body)
	var/datum/antag_training_sector/station = session.arena?.sectors["station"]
	if(!station?.load() || QDELETED(session) || session.finished)
		return FALSE
	var/datum/antagonist/abductor/training/abductor = role(session)
	var/datum/team/abductor_team/training/crew = abductor?.team
	var/turf/bay = station.landmark_turf("abductor")
	if(QDELETED(crew) || !crew.deploy(bay))
		return FALSE
	if(move_body)
		session.current_body?.forceMove(bay)
	return TRUE

/datum/antag_training_program/antag/abductor/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/abductor/training/abductor = role(session)
	if(!abductor)
		to_chat(user, span_warning("Роль абдуктора снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	if(option == "Цель с железой")
		place_specimen(session, user)
		return TRUE
	var/datum/team/abductor_team/training/crew = abductor.team
	var/obj/machinery/abductor/console/training/console = crew?.console
	if(QDELETED(console) || !console.experiment)
		to_chat(user, span_warning("Корабля нет в отсеке абдукторов: станционный макет был выгружен. Корабль возвращается в отсек, нажмите кнопку снова через несколько секунд."))
		INVOKE_ASYNC(src, PROC_REF(board_ship), session, FALSE)
		return FALSE
	if(option == "Пополнить кредиты")
		console.experiment.credits = max(console.experiment.credits, ANTAG_TRAINING_ABDUCTOR_CREDITS)
		to_chat(user, span_notice("В консоли корабля [console.experiment.credits] кредитов."))
	return TRUE

/datum/antag_training_program/antag/abductor/proc/place_specimen(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = place_practice_dummy(session, user)
	if(!dummy)
		return null
	var/obj/item/organ/heart/gland/gland = new ANTAG_TRAINING_ABDUCTOR_GLAND
	gland.Insert(dummy, ANTAG_TRAINING_ABDUCTOR_SURGERY_INSERT, FALSE)
	to_chat(user, span_notice("[dummy.real_name] встал[dummy.ru_a()] в зоне «[dummy_zone_name(session, dummy)]», в груди - железа. Перетащите [dummy.ru_ego()] в экспериментатор корабля и запустите опыт."))
	return dummy

/datum/antag_training_program/antag/abductor/agent
	name = "Абдуктор-агент"
	desc = "Агент корабля абдукторов в отсеке станционного макета: жилет с маскировкой, дубинка, консоль со снаряжением за кредиты, телепад, камера наблюдения и опыт над учебной целью с железой."
	icon = "eye"
	color = "violet"
	learn = "Жилет с маскировкой и дубинка|Снаряжение с консоли за кредиты|Телепад и камера наблюдения|Доставка цели на опыт"
	difficulty = 2
	antag_type = /datum/antagonist/abductor/training/agent

/datum/antag_training_program/antag/abductor/scientist
	name = "Абдуктор-учёный"
	desc = "Учёный корабля абдукторов в отсеке станционного макета: инструмент учёного, имплант возврата, экспериментатор с учебной целью с железой и консоль со снаряжением за кредиты."
	icon = "flask"
	color = "violet"
	learn = "Инструмент учёного и имплант возврата|Опыт над целью и установка железы|Экспериментатор корабля|Снаряжение с консоли за кредиты"
	difficulty = 2
	antag_type = /datum/antagonist/abductor/training/scientist

/datum/antagonist/abductor/training
	name = "Учебный абдуктор"
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
	silent = TRUE
	var/datum/antag_training_session/training
	var/role_title
	var/role_briefing

/datum/antagonist/abductor/training/on_gain()
	. = ..()
	greet()

/datum/antagonist/abductor/training/on_removal()
	if(owner.current)
		update_abductor_icons_removed(owner)
	return ..()

/datum/antagonist/abductor/training/threat()
	return 0

/datum/antagonist/abductor/training/finalize_abductor()
	var/mob/living/carbon/human/body = owner.current
	body.set_species(/datum/species/abductor)
	var/obj/item/organ/tongue/abductor/tongue = body.getorganslot(ORGAN_SLOT_TONGUE)
	if(istype(tongue))
		tongue.mothership = "[team.name]"
	body.real_name = "[team.name] [sub_role]"
	body.equipOutfit(outfit)
	update_abductor_icons_added(owner, "abductor")

/datum/antagonist/abductor/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/abductor/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/abductor/training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка абдуктора: [role_title] корабля «[team.name]», он стоит в отсеке абдукторов станционного макета."),
		span_notice(role_briefing),
		span_notice("Консоль продаёт снаряжение за кредиты и управляет жилетом и телепадом, камера наблюдения смотрит через учебные камеры макета, экспериментатор принимает подопытных."),
		span_notice("Телепатия корабля доходит только до абдукторов этого корабля на полигоне. В раунде её слышат и все мёртвые."),
		span_notice("Подопытный на полигоне - манекен без игрока: опыт засчитывается, но целей похищенного он не получает. После опыта подопытный уходит в точку высадки, а без неё остаётся у машины; в раунде без точки высадки его уносит в прибытие. Телепад без точки высадки отправляет в случайное место макета, в раунде - в случайный отсек станции."),
		span_notice("«Пульт полигона», раздел «Моя роль»: учебная цель с железой и пополнение кредитов консоли до [ANTAG_TRAINING_ABDUCTOR_CREDITS]."),
	), "<br>")

/datum/antagonist/abductor/training/Destroy()
	training = null
	. = ..()
	team = null

/datum/antagonist/abductor/training/agent
	name = "Учебный абдуктор-агент"
	sub_role = "Agent"
	role_title = "агент"
	outfit = /datum/outfit/abductor/agent
	skill_modifiers = list(/datum/skill_modifier/job/level/wiring)
	role_briefing = "Жилет переключается между маскировкой и боем, дубинка оглушает, усыпляет, сковывает и прощупывает. Ваша работа - доставить подопытного учёному."

/datum/antagonist/abductor/training/scientist
	name = "Учебный абдуктор-учёный"
	sub_role = "Scientist"
	role_title = "учёный"
	outfit = /datum/outfit/abductor/scientist/training
	skill_modifiers = list(/datum/skill_modifier/job/affinity/surgery)
	role_briefing = "Инструмент учёного снимает облики для маскировки агента и помечает подопытного, чтобы консоль вернула его на телепад. Имплант возврата переносит вас на телепад корабля. Хранилища желёз на полигоне нет: «Цель с железой» ставит подопытного с готовой железой."

/datum/antagonist/abductor/training/scientist/on_gain()
	ADD_TRAIT(owner, TRAIT_ABDUCTOR_SCIENTIST_TRAINING, ABDUCTOR_ANTAGONIST)
	ADD_TRAIT(owner, TRAIT_SURGEON, ABDUCTOR_ANTAGONIST)
	return ..()

/datum/antagonist/abductor/training/scientist/on_removal()
	REMOVE_TRAIT(owner, TRAIT_ABDUCTOR_SCIENTIST_TRAINING, ABDUCTOR_ANTAGONIST)
	REMOVE_TRAIT(owner, TRAIT_SURGEON, ABDUCTOR_ANTAGONIST)
	return ..()

/datum/outfit/abductor/scientist/training
	name = "Training Abductor Scientist"
	backpack_contents = list(/obj/item/abductor/gizmo/training = 1)

/datum/outfit/abductor/scientist/training/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	return

/// Команда учебного корабля: не входит в счёт команд раунда и его отчёт, номер из своего диапазона.
/datum/team/abductor_team/training
	member_name = "training abductor"
	show_roundend_report = FALSE
	var/obj/machinery/abductor/console/training/console
	var/datum/objective/antag_training/experiment_objective
	var/static/training_teams = 0
	var/static/list/kit_layout = list(
		/obj/machinery/abductor/pad/training = list(-2, -2),
		/obj/machinery/abductor/experiment/training = list(3, 0),
		/obj/machinery/computer/camera_advanced/abductor/training = list(1, 2),
		/obj/machinery/abductor/console/training = list(-1, 2),
	)

/datum/team/abductor_team/training/New(starting_members)
	var/round_teams = team_count
	. = ..()
	team_count = round_teams
	GLOB.antagonist_teams -= src
	team_number = ANTAG_TRAINING_ABDUCTOR_FIRST_TEAM + training_teams++
	name = "Training Mothership [team_number - ANTAG_TRAINING_ABDUCTOR_FIRST_TEAM + 1]"
	QDEL_LIST(objectives)
	experiment_objective = new
	experiment_objective.explanation_text = "Учебный опыт: доставьте подопытного с железой в экспериментатор корабля и проведите опыт."
	add_objective(experiment_objective)

/datum/team/abductor_team/training/roundend_report()
	return ""

/datum/team/abductor_team/training/remove_member(datum/mind/member)
	. = ..()
	if(!length(members) && !QDELETED(src))
		qdel(src)

/// Ставит машины корабля вокруг метки отсека, если их нет, и привязывает к ним снаряжение команды.
/datum/team/abductor_team/training/proc/deploy(turf/bay)
	if(!bay)
		return FALSE
	if(QDELETED(console))
		console = null
		var/list/pieces = list()
		for(var/piece_type in kit_layout)
			var/list/offset = kit_layout[piece_type]
			pieces += new piece_type(locate(bay.x + offset[1], bay.y + offset[2], bay.z))
		console = locate() in pieces
		console.team = src
		console.link_kit(team_number, pieces)
	for(var/datum/mind/member as anything in members)
		link_member(member.current)
	return TRUE

/datum/team/abductor_team/training/proc/link_member(mob/living/carbon/human/body)
	if(!ishuman(body) || QDELETED(console))
		return
	var/obj/item/clothing/suit/armor/abductor/vest/vest = locate() in body
	if(vest && console.AddVest(vest))
		ADD_TRAIT(vest, TRAIT_NODROP, ABDUCTOR_VEST_TRAIT)
	for(var/obj/item/abductor/gizmo/gizmo in body.GetAllContents())
		console.AddGizmo(gizmo)
	if(!body.mind?.has_antag_datum(/datum/antagonist/abductor/training/scientist))
		return
	var/obj/item/implant/abductor/training/beacon = locate() in body.implants
	if(!beacon)
		beacon = new
		if(!beacon.implant(body, null, TRUE))
			qdel(beacon)
			return
	beacon.set_home(console.pad)

/datum/team/abductor_team/training/Destroy(force)
	experiment_objective = null
	QDEL_LIST(objectives)
	if(console)
		console.team = null
	QDEL_NULL(console)
	members.Cut()
	abductees.Cut()
	return ..()

/obj/machinery/abductor/console/training
	var/datum/team/abductor_team/training/team
	var/static/list/training_supplies = list(
		/obj/item/abductor/gizmo = /obj/item/abductor/gizmo/training,
		/obj/item/abductor_machine_beacon/chem_dispenser = /obj/item/abductor_machine_beacon/chem_dispenser/training,
	)

/obj/machinery/abductor/console/training/proc/link_kit(number, list/pieces)
	team_number = number
	for(var/obj/machinery/piece as anything in pieces)
		if(istype(piece, /obj/machinery/abductor/pad))
			pad = piece
			pad.team_number = number
		else if(istype(piece, /obj/machinery/abductor/experiment))
			experiment = piece
			experiment.team_number = number
			experiment.console = src
		else if(istype(piece, /obj/machinery/computer/camera_advanced/abductor))
			camera = piece
			camera.team_number = number
			camera.console = src

/obj/machinery/abductor/console/training/Dispense(item, cost = 1)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena || !experiment || experiment.credits < cost)
		return ..()
	item = training_supplies[item] || item
	var/datum/antag_training_session/buyer = usr?.ckey ? GLOB.antag_training_sessions[usr.ckey] : null
	if(!arena.issue_item(item, get_turf(pad || src), 1, buyer?.arena == arena ? buyer : null))
		to_chat(usr, span_warning("Достигнут лимит выданных предметов полигона: кредиты не списаны. Уберите лишнее очисткой своих объектов в пульте."))
		return
	experiment.credits -= cost
	say("Incoming supply!")
	if(pad)
		flick("alien-pad", pad)

/obj/machinery/abductor/console/training/Destroy()
	if(team?.console == src)
		team.console = null
	team = null
	gizmo?.console = null
	gizmo = null
	vest = null
	if(experiment)
		experiment.console = null
	if(camera)
		camera.console = null
	QDEL_NULL(pad)
	QDEL_NULL(experiment)
	QDEL_NULL(camera)
	return ..()

/obj/machinery/abductor/pad/training

/obj/machinery/abductor/pad/training/Send()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!teleport_target || !arena?.owns_area(get_area(teleport_target)))
		teleport_target = arena?.teleport_turf("station")
	if(!teleport_target)
		return
	return ..()

/obj/machinery/abductor/experiment/training
	var/list/datum/weakref/examined

/obj/machinery/abductor/experiment/training/experiment(mob/occupant, type, mob/user)
	var/mob/living/carbon/human/specimen = occupant
	if(!user.mind?.has_antag_datum(/datum/antagonist/abductor))
		return "Authorization failure. Contact mothership immediately."
	if(!istype(specimen))
		return "Invalid or missing specimen."
	if(WEAKREF(specimen) in examined)
		return "Specimen already in database."
	if(specimen.stat == DEAD)
		say("Specimen deceased - please provide fresh sample.")
		return "Specimen deceased."
	if(!(locate(/obj/item/organ/heart/gland) in specimen.internal_organs))
		say("Experimental dissection not detected!")
		return "No glands detected!"
	if(!specimen.mind)
		say("Brain activity nonexistent - disposing sample...")
		open_machine()
		send_back(specimen)
		return "Specimen braindead - disposed."
	say("Processing specimen...")
	sleep(0.5 SECONDS)
	switch(text2num(type))
		if(1)
			to_chat(specimen, span_warning("Вас бесцеремонно ощупывают."))
		if(2)
			to_chat(specimen, span_warning("Вас будто разрезают на части и собирают заново."))
		if(3)
			to_chat(specimen, span_warning("За вами пристально наблюдают."))
	sleep(0.5 SECONDS)
	if(QDELETED(specimen) || specimen.loc != src)
		return "Specimen lost."
	LAZYADD(examined, WEAKREF(specimen))
	var/point_reward = 0
	for(var/obj/item/organ/heart/gland/gland in specimen.internal_organs)
		gland.Start()
		point_reward++
	if(!point_reward)
		playsound(loc, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		return "Experiment failed! No replacement organ detected."
	open_machine()
	send_back(specimen)
	playsound(loc, 'sound/machines/ding.ogg', 50, TRUE)
	points += point_reward
	credits += point_reward
	var/obj/machinery/abductor/console/training/ship_console = console
	var/datum/team/abductor_team/training/crew = istype(ship_console) ? ship_console.team : null
	if(crew?.experiment_objective)
		crew.experiment_objective.completed = TRUE
	return "Experiment successful! [point_reward] new data-points collected."

/obj/machinery/abductor/experiment/training/send_back(mob/living/carbon/human/specimen)
	specimen.Sleeping(ANTAG_TRAINING_ABDUCTOR_SPECIMEN_SLEEP)
	specimen.uncuff()
	var/turf/release = console?.pad?.teleport_target
	if(release)
		specimen.forceMove(release)

/obj/machinery/abductor/experiment/training/Destroy()
	examined = null
	if(console?.experiment == src)
		console.experiment = null
	console = null
	return ..()

/obj/machinery/computer/camera_advanced/abductor/training
	networks = list("training")
	lock_override = NONE

/obj/machinery/computer/camera_advanced/abductor/training/Initialize(mapload)
	. = ..()
	z_lock = list(z)

/obj/machinery/computer/camera_advanced/abductor/training/CreateEye()
	. = ..()
	eyeobj.training_origin = training_origin

/obj/machinery/computer/camera_advanced/abductor/training/Destroy()
	if(console?.camera == src)
		console.camera = null
	console = null
	return ..()

/obj/item/abductor/gizmo/training

/obj/item/abductor/gizmo/training/mark(atom/target, mob/living/user)
	var/mob/living/previous = marked
	. = ..()
	if(marked == previous)
		return
	if(previous)
		UnregisterSignal(previous, COMSIG_PARENT_QDELETING)
	if(marked)
		RegisterSignal(marked, COMSIG_PARENT_QDELETING, PROC_REF(forget_marked))

/obj/item/abductor/gizmo/training/proc/forget_marked(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	if(marked == source)
		marked = null

/obj/item/abductor/gizmo/training/Destroy()
	if(marked)
		UnregisterSignal(marked, COMSIG_PARENT_QDELETING)
	marked = null
	return ..()

/// Синтезатор, поставленный маяком, считается в лимите выданных предметов вместо маяка.
/obj/item/abductor_machine_beacon/chem_dispenser/training

/obj/item/abductor_machine_beacon/chem_dispenser/training/try_spawn_machine()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/datum/antag_training_session/owner = training_owner?.resolve()
	var/turf/spot = loc
	. = ..()
	if(!QDELETED(src) || !arena || !isturf(spot))
		return
	var/obj/machinery/built = locate(spawned_machine) in spot
	if(built)
		arena.track_supply(built, owner)

/obj/item/implant/abductor/training

/obj/item/implant/abductor/training/activate()
	if(QDELETED(home))
		to_chat(imp_in, span_warning("Телепада корабля нет: станционный макет был выгружен. Нажмите в пульте любую кнопку роли - корабль вернётся в отсек."))
		return
	return ..()

/obj/item/implant/abductor/training/proc/set_home(obj/machinery/abductor/pad/new_home)
	if(home)
		UnregisterSignal(home, COMSIG_PARENT_QDELETING)
	home = new_home
	if(home)
		RegisterSignal(home, COMSIG_PARENT_QDELETING, PROC_REF(home_lost))

/obj/item/implant/abductor/training/proc/home_lost(datum/source)
	SIGNAL_HANDLER
	set_home(null)

/obj/item/implant/abductor/training/Destroy()
	set_home(null)
	return ..()

#undef ANTAG_TRAINING_ABDUCTOR_FIRST_TEAM
#undef ANTAG_TRAINING_ABDUCTOR_CREDITS
#undef ANTAG_TRAINING_ABDUCTOR_GLAND
#undef ANTAG_TRAINING_ABDUCTOR_SURGERY_INSERT
#undef ANTAG_TRAINING_ABDUCTOR_SPECIMEN_SLEEP
