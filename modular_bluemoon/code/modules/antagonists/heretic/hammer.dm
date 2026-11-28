#define HERETIC_HAMMER_INK "#e8742a"
#define HERETIC_HAMMER_GLOW "#ffd9a0"
#define HERETIC_HAMMER_CLIMAX_INK "#a3261b"

GLOBAL_LIST_INIT(heretic_hammer_sounds, list(
	"wield" = list('modular_bluemoon/sound/heretic/hammer_wield.ogg'),
	"unwield" = list('modular_bluemoon/sound/heretic/hammer_unwield.ogg'),
	"crush" = list('modular_bluemoon/sound/heretic/hammer_crush_1.ogg', 'modular_bluemoon/sound/heretic/hammer_crush_2.ogg'),
	"windup" = list('modular_bluemoon/sound/heretic/hammer_windup.ogg'),
	"wall_slam" = list('modular_bluemoon/sound/heretic/hammer_wall_slam.ogg'),
	"ram" = list('modular_bluemoon/sound/heretic/hammer_ram.ogg'),
	"ram_smash" = list('modular_bluemoon/sound/heretic/hammer_ram_smash.ogg'),
	"quake" = list('modular_bluemoon/sound/heretic/hammer_quake.ogg'),
	"fissure" = list('modular_bluemoon/sound/heretic/hammer_fissure.ogg'),
	"anvil_fall" = list('modular_bluemoon/sound/heretic/hammer_anvil_fall.ogg'),
	"anvil_land" = list('modular_bluemoon/sound/heretic/hammer_anvil_land.ogg'),
	"anvil_break" = list('modular_bluemoon/sound/heretic/hammer_anvil_break.ogg'),
	"nail" = list('modular_bluemoon/sound/heretic/hammer_nail.ogg'),
	"nail_free" = list('modular_bluemoon/sound/heretic/hammer_nail_free.ogg'),
	"mark_ring" = list('modular_bluemoon/sound/heretic/hammer_mark_ring.ogg'),
	"mark_shatter" = list('modular_bluemoon/sound/heretic/hammer_mark_shatter.ogg'),
	"heat" = list('modular_bluemoon/sound/heretic/hammer_heat.ogg'),
	"quench" = list('modular_bluemoon/sound/heretic/hammer_quench.ogg'),
	"rage" = list('modular_bluemoon/sound/heretic/hammer_rage.ogg'),
	"brand_strike" = list('modular_bluemoon/sound/heretic/hammer_brand_strike.ogg'),
	"brand_ring" = list('modular_bluemoon/sound/heretic/hammer_brand_ring.ogg'),
	"catch" = list('modular_bluemoon/sound/heretic/hammer_catch.ogg'),
	"learn" = list('modular_bluemoon/sound/heretic/hammer_learn.ogg'),
	"toll" = list('modular_bluemoon/sound/heretic/hammer_toll.ogg'),
	"hot_anvil_land" = list('modular_bluemoon/sound/heretic/hammer_hot_anvil_land.ogg'),
))

/// Играет звук события Молота из его набора и возвращает выбранный файл.
/proc/heretic_hammer_sound(atom/source, kind, volume, vary = FALSE, extrarange = 0)
	var/list/options = GLOB.heretic_hammer_sounds[kind]
	if(!length(options))
		return null
	. = pick(options)
	if(volume > 0 && source)
		playsound(source, ., volume, vary, extrarange)

/datum/sound_effect/heretic_hammer_hit
	key = HERETIC_HAMMER_HIT_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/hammer_hit_1.ogg',
		'modular_bluemoon/sound/heretic/hammer_hit_2.ogg',
		'modular_bluemoon/sound/heretic/hammer_hit_3.ogg',
	)

/datum/sound_effect/heretic_hammer_grasp
	key = HERETIC_HAMMER_GRASP_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/hammer_grasp.ogg',
	)

/// Молот пути из рук владельца: в двух руках, если wielded.
/proc/heretic_hammer_held(mob/living/user, wielded = FALSE)
	for(var/obj/item/melee/sickly_blade/hammer/hammer in user?.held_items)
		if(!wielded || ISWIELDED(hammer))
			return hammer
	return null

/datum/heretic_path/hammer
	id = PATH_HAMMER
	deed_type = /datum/heretic_deed/hammer
	innate_type = /datum/heretic_innate/hammer
	name = "Молот"
	tagline = "Кузнец изнанки: Молот в двух руках копит Накал, крошит броню и стены, вбивает в пол."
	craft_summary = "Молот в «Помощи» по стене выбивает Клеймо кузни: прошедший мимо экипаж засчитывает отдел клейма."
	capture_summary = "Молот в двух руках в «Схватить» по лежащему за 2 Накала вбивает его в пол на 12 секунд; сердце уводит."
	escape_summary = "Таран: рывок на 5 клеток сквозь шлюз, окно или стену, рвёт даже крепкую хватку; даром раз в 30 секунд."
	strength_points = list(
		"Молот в двух руках бьёт на 33, отбрасывает и лечит вас; постройки, шлюзы и мехи - втрое сильнее.",
		"Замах готовит Сокрушающий удар: +20 урона и полёт на 3 клетки, удар о стену валит с ног.",
		"Таран проламывает шлюз, окно или стену и уводит даже из крепкой хватки.",
		"Звон наковальни раскалывает броню: третий удар по меченому снимает 40 защиты на 10 секунд.",
		"В двух руках удары и снаряды ранят на 20% слабее, оглушение на 30% короче; Несокрушимого не валит толчок.",
		"Наковальня с неба - единственный дальний удар: 35 урона по клетке в 7 клетках после тени.",
	)
	weakness_points = list(
		"Вода и пена гасят Накал в ноль: огнетушитель, ведро, шланг или душ на 4 секунды не дают копить и лечиться.",
		"Одной рукой он бьёт слабее, не отбрасывает и не лечится, а для Хватки Молот надо отпустить.",
		"Удар медленный, Замах и Сотрясение видны заранее: отходите, когда Молот поднят над головой.",
		"Вбитого в пол выдёргивает ломом другой член экипажа за 3 секунды, растолкать его можно за 2.",
		"Без удара по живым Накал стынет: каждые 12 секунд передышки - минус единица.",
		"До вознесения оглушение глушит его приёмы, а дальше 7 клеток он почти ничего не может.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_hammer,
		/datum/eldritch_knowledge/spell/hammer_ram,
		/datum/eldritch_knowledge/hammer_nail,
		/datum/eldritch_knowledge/spell/hammer_quake,
		/datum/eldritch_knowledge/hammer_grasp,
		/datum/eldritch_knowledge/hammer_mark,
		/datum/eldritch_knowledge/spell/hammer_anvil,
		/datum/eldritch_knowledge/hammer_unbroken,
		/datum/eldritch_knowledge/spell/hammer_fissure,
		/datum/eldritch_knowledge/final_eldritch/hammer_final,
	)
	rune_inscription_icon = 'modular_bluemoon/icons/obj/ritual_inscriptions_extended.dmi'
	rune_cast_icon = 'modular_bluemoon/icons/obj/ritual_casts_extended.dmi'
	book_type = /obj/item/forbidden_book/hammer
	book_name = "Malleus Abyssi"
	book_title = "Наковальня без дна"
	book_subtitle = "Всё, что не выдержало удара, было ненастоящим"
	book_desc = "Тяжёлая книга в переплёте из кованого железа на заклёпках. На крышке тлеет оттиск молота, а страницы пахнут окалиной и тёплым металлом."
	book_cover = "hammer"
	book_ink = HERETIC_HAMMER_INK
	book_rune = "sigil_hammer"
	rune_inscription = "hammer_forge"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_hammer_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_hammer_page.ogg'
	learn_sound = 'modular_bluemoon/sound/heretic/hammer_learn.ogg'
	vfx_particles = /particles/heretic_ascension/hammer
	vfx_accent = HERETIC_HAMMER_GLOW
	climax_ink = HERETIC_HAMMER_CLIMAX_INK
	ascension_title = "Кузнец Последнего Удара"
	ascension_message = "Над станцией гремит кузня изнанки. Тот, кто держит Молот, больше не ищет, что разбить: всё, что не выдержит удара, было ненастоящим."
	ascension_omen = "Пол под ногами на миг вздрагивает, будто где-то внизу ударили по наковальне. В воздухе пахнет окалиной, а металл на вас теплеет."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_hammer.ogg'
	ascension_climax_sound = 'modular_bluemoon/sound/heretic/ascend_hammer_climax.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_hammer.dmi'
	ascension_aura_state = "hammer_aura"
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/hammer.dmi'
	sky_tint = "#2a140c"
	sky_dim = 150
	sky_particles = /particles/heretic_sky/hammer
	sky_texture_states = list("hammer_smoke_far", "hammer_smoke_near")
	sky_texture_drift = 140 SECONDS
	sky_texture_angle = 90
	sky_loop = 'modular_bluemoon/sound/heretic/sky/hammer_loop.ogg'
	sky_event_sound = 'modular_bluemoon/sound/heretic/sky/hammer_event.ogg'
	robe_state = "hammer_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_hammer_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_hammer_worn.dmi'
	difficulty = 1
	playstyle = list("melee")
	first_steps = list(
		"Возьмите Молот в две руки: удары по живым копят Накал, а «Замах» готовит Сокрушающий удар.",
		"Молотом в «Помощи» выбейте клеймо на стене: экипаж, прошедший мимо, засчитает в дело отдел клейма.",
		"Свалите цель и в «Схватить» вбейте её Молотом в пол: на 12 секунд она ваша, сердце уводит её.",
	)
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "Ладони в жёстких мозолях, а под ногтями чернеет окалина, будто их не отмыть от кузни."),
		list(HERETIC_EVOLUTION_HANDS = "Кисти потемнели, как прокалённое железо, по костяшкам бегут тлеющие трещины.", HERETIC_EVOLUTION_FACE = "От кожи тянет жаром горна, на шее проступает сажа."),
		list(HERETIC_EVOLUTION_ANY = "Кожа местами окалилась чёрной коркой, сквозь трещины светится жар, а каждый шаг отдаётся звоном: Молот перековывает это тело."),
	)
	combat_practice = "Возьмите Молот изнанки в руку и активируйте его, чтобы взять в две руки: только так удар бьёт на 33, быстро копит Накал и отбрасывает мишень, а на станции каждый удар по врагу ещё и лечит вас. Одной рукой Молот бьёт слабее и без отброса. Нажмите «Замах»: секунду Молот поднят над головой, затем 4 секунды следующий удар - Сокрушающий, мишень отлетает на 3 клетки, а врезавшись в стену, падает. Свалите мишень и в намерении «Схватить» ударьте её Молотом в двух руках: за 2 Накала она вбита в пол на 12 секунд, напарник выдернет её ломом за 3 секунды или растолкает за 2 секунды. «Таран» рвёт хватку напарника и проламывает окно или шлюз полигона. Пусть напарник окатит вас из огнетушителя: Накал гаснет в ноль, а удары перестают лечить. Пошагово главные приёмы ведёт кнопка «Урок Молота» среди упражнений полигона."

/datum/heretic_path
	/// Звук изучения знания в кодексе, если у пути он свой.
	var/learn_sound

/obj/item/forbidden_book/hammer
	book_path = PATH_HAMMER

/particles/heretic_ascension/hammer
	icon = 'modular_bluemoon/icons/obj/heretic_hammer_fx.dmi'
	icon_state = list("hammer_p_spark" = 3, "hammer_p_ember" = 2, "hammer_p_scale" = 1)
	velocity = generator("circle", 3, 6)
	gravity = list(0, -0.25)
	friction = 0.12
	spin = generator("num", -30, 30)
	lifespan = 1.2 SECONDS

/particles/heretic_sky/hammer
	icon = 'modular_bluemoon/icons/obj/heretic_hammer_fx.dmi'
	icon_state = list("hammer_p_ember" = 3, "hammer_p_scale" = 1)
	velocity = generator("circle", 0.05, 0.15)
	gravity = list(0, 0.02)

/datum/eldritch_knowledge/base_hammer
	name = "Тяжесть в руках"
	summary = "Молот в двух руках копит Накал и отбрасывает; Замах готовит Сокрушающий удар; клеймо на стене - дело пути."
	details = list(
		"Ящик с инструментами и лист железа дают Молот изнанки; кнопка «Расколоть молот» - побег, как у клинка.",
		"Молот в руке активируйте, чтобы взять в две руки: 33 урона, пробой брони, отброс на клетку, постройки - втрое.",
		"Одной рукой Молот бьёт на 18 без отброса и вдвое слабее пробивает броню; в двух руках удар на четверть медленнее.",
		"«Замах»: секунда с поднятым Молотом, затем 4 секунды удар - Сокрушающий: +20 урона и полёт на 3 клетки.",
		"Сокрушённый, врезавшись в стену, преграду или другого, падает на 1,5 секунды и получает ещё 12 урона.",
		"Молот в «Помощи» по стене выбивает Клеймо кузни, до 6; мимо идёт экипаж - клеймо гудит, отдел в деле.",
		"Стойка в двух руках: удары и снаряды ранят на 20% слабее, оглушение на 30% короче, удар по врагу лечит на 4.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Я поднял его, и руки сами вспомнили вес. Где-то внизу, под полом мира, ударили по наковальне - в ответ."
	route = PATH_HAMMER
	required_atoms = list(/obj/item/storage/toolbox, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/hammer)
	combat_resource = HERETIC_HAMMER_START
	combat_resource_max = HERETIC_HAMMER_CAPACITY
	combat_resource_name = "Накал"
	resource_rules = list(
		"Начальный запас 3 из 8; смерть обнуляет Накал.",
		"Удар Молотом в двух руках по живому врагу - единица, не чаще раза в секунду; одной рукой - раз в 2 секунды.",
		"Сокрушающий удар - ещё единица, Хватка по врагу - 2.",
		"Без удара по живому врагу Накал стынет: минус единица за каждые 12 секунд.",
		"Вода и пена на теле - огнетушитель, ведро, шланг, душ - гасят Накал в ноль и 4 секунды не дают копить.",
		"Цены: Таран 2 или даром раз в 30 секунд, Вбить в пол 2, Сотрясение и Наковальня с неба 3, Раскол 4.",
		"После вознесения Накал копится до 12 и не стынет.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_hammer/swing
	grasp_visual = /obj/effect/temp_visual/heretic_hammer/grasp
	grasp_sound = HERETIC_HAMMER_GRASP_SFX
	grasp_catchphrase = "MAL'LEUS AB'YSSI"
	var/mob/living/hammer_body
	var/quenched_until = 0
	var/cool_at = 0
	var/ascension_active = FALSE
	/// Стоит хоть одна Раскалённая наковальня вознесения.
	var/anvils_hot = FALSE
	var/list/obj/effect/heretic_hammer_brand/brands = list()
	var/list/datum/status_effect/heretic_hammer_nailed/nailed = list()
	var/list/datum/status_effect/eldritch/hammer/marks = list()
	/// Молот, который сейчас в двух руках у тела: от него держится Несокрушимый.
	var/obj/item/melee/sickly_blade/hammer/braced_hammer
	var/braced = FALSE
	/// Стойка сама заново накладывает укороченное оглушение и не должна укорачивать его второй раз.
	var/shortening = FALSE
	COOLDOWN_DECLARE(hit_gain)
	COOLDOWN_DECLARE(free_ram)
	COOLDOWN_DECLARE(rage)
	COOLDOWN_DECLARE(quench_notice)

/datum/eldritch_knowledge/base_hammer/on_gain(mob/user)
	. = ..()
	heretic_path_lesson_notice(user, "hammer")

/datum/eldritch_knowledge/base_hammer/on_body_gain(mob/living/user)
	if(!user?.mind || hammer_body == user)
		return
	if(hammer_body)
		on_body_lose(hammer_body)
	hammer_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_body_exposed))
	RegisterSignal(user, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_body_washed))
	RegisterSignal(user, COMSIG_LIVING_EXTINGUISHED, PROC_REF(on_body_extinguished))
	RegisterSignal(user, COMSIG_LIVING_STATUS_KNOCKDOWN, PROC_REF(on_body_knocked_down))
	RegisterSignal(user, COMSIG_LIVING_STATUS_PARALYZE, PROC_REF(on_body_paralyzed))
	RegisterSignal(user, COMSIG_LIVING_STATUS_STUN, PROC_REF(on_body_stun))
	RegisterSignal(user, COMSIG_LIVING_RESTING, PROC_REF(on_body_rested))
	RegisterSignal(user, COMSIG_LIVING_RUN_BLOCK, PROC_REF(on_body_block))
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	grant_combat_power(user)
	var/obj/item/melee/sickly_blade/hammer/held = heretic_hammer_held(user, TRUE)
	if(held)
		on_hammer_wield(held, user)
	notify_resource_changed()

/datum/eldritch_knowledge/base_hammer/on_body_lose(mob/living/user)
	if(hammer_body)
		UnregisterSignal(hammer_body, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_EXPOSE_REAGENTS, COMSIG_COMPONENT_CLEAN_ACT, COMSIG_LIVING_EXTINGUISHED, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_RESTING, COMSIG_LIVING_RUN_BLOCK))
		hammer_body.remove_status_effect(/datum/status_effect/heretic_hammer_swing)
		hammer_body.remove_status_effect(/datum/status_effect/heretic_hammer_catch)
	unbrace()
	hammer_body = null
	ascension_active = FALSE
	remove_combat_power()
	clear_hammer()

/datum/eldritch_knowledge/base_hammer/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(hammer_body)

/datum/eldritch_knowledge/base_hammer/on_death(mob/user)
	clear_hammer()
	if(hammer_body)
		hammer_body.remove_status_effect(/datum/status_effect/heretic_hammer_swing)
		hammer_body.remove_status_effect(/datum/status_effect/heretic_hammer_catch)
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_hammer/on_lose(mob/user)
	. = ..()
	clear_brands()

/datum/eldritch_knowledge/base_hammer/Destroy()
	on_body_lose(hammer_body)
	clear_brands()
	return ..()

/datum/eldritch_knowledge/base_hammer/proc/clear_hammer()
	QDEL_LIST(nailed)
	QDEL_LIST(marks)

/datum/eldritch_knowledge/base_hammer/proc/clear_brands()
	for(var/obj/effect/heretic_hammer_brand/brand as anything in brands.Copy())
		qdel(brand)
	brands.Cut()

/datum/eldritch_knowledge/base_hammer/proc/can_use(mob/living/user, ignore_grab = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(QDELETED(src) || !isliving(user) || user != hammer_body || !isturf(user.loc) || heretic?.selected_path != PATH_HAMMER || heretic.role_removed || heretic.get_knowledge(type) != src)
		return FALSE
	return !heretic_incapacitated(user, ignore_grab)

/datum/eldritch_knowledge/base_hammer/proc/owner_heretic()
	RETURN_TYPE(/datum/antagonist/heretic)
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	if(QDELETED(heretic) || heretic.role_removed || heretic.get_knowledge(type) != src)
		return null
	return heretic

/datum/eldritch_knowledge/base_hammer/proc/knows(knowledge_type)
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/known = heretic?.get_knowledge(knowledge_type)
	return !QDELETED(known)

/datum/eldritch_knowledge/base_hammer/combat_resource_state()
	. = "Клейм кузни: [length(brands)] из [HERETIC_HAMMER_BRAND_LIMIT]."
	if(quenched_until > world.time)
		. += " Молот остужен: Накал не копится ещё [heretic_capture_seconds_left(quenched_until)] с."
	if(hammer_body && !braced_hammer)
		. += " Молот не в двух руках: удары копят Накал вдвое реже и не отбрасывают."
	if(COOLDOWN_FINISHED(src, free_ram))
		. += " Таран сейчас даром."
	if(anvils_hot)
		. += " Раскалённые наковальни стоят."

/datum/eldritch_knowledge/base_hammer/gain_combat_resource(amount = 1)
	if(amount > 0 && quenched_until > world.time)
		return
	combat_resource_max = ascension_active ? HERETIC_HAMMER_ASCENDED_CAPACITY : HERETIC_HAMMER_CAPACITY
	return ..()

/datum/eldritch_knowledge/base_hammer/on_mark_detonated(mob/living/user, mob/living/target)
	return

/datum/eldritch_knowledge/base_hammer/on_life(mob/user)
	if(user != hammer_body)
		return
	if(locate(/obj/effect/particle_effect/foam/firefighting) in get_turf(user))
		quench("пена")
	if(ascension_active || world.time < cool_at)
		return
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	if(combat_resource > 0)
		gain_combat_resource(-1)

/// Вода или пена гасят Накал: огнетушитель, ведро, шланг, пена и брызги.
/datum/eldritch_knowledge/base_hammer/proc/on_body_exposed(atom/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message, from_gas)
	SIGNAL_HANDLER
	if(from_gas || (method != TOUCH && method != VAPOR))
		return
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			quench("вода")
			return

/// Из всего, что отмывает тело, гасит только включённый душ: мыло, язык и уборщики не в счёт.
/datum/eldritch_knowledge/base_hammer/proc/on_body_washed(mob/living/source, clean_types)
	SIGNAL_HANDLER
	for(var/obj/machinery/shower/shower in get_turf(source))
		if(shower.on)
			quench("вода")
			return

/datum/eldritch_knowledge/base_hammer/proc/on_body_extinguished(mob/living/source)
	SIGNAL_HANDLER
	if(locate(/obj/effect/particle_effect/foam) in get_turf(source))
		quench("пена")

/datum/eldritch_knowledge/base_hammer/proc/quench(what)
	var/mob/living/body = hammer_body
	if(!body || body.stat == DEAD)
		return FALSE
	var/had = combat_resource
	quenched_until = world.time + HERETIC_HAMMER_QUENCH_TIME
	combat_resource = 0
	notify_resource_changed()
	lesson_event("quench", body, had)
	if(!COOLDOWN_FINISHED(src, quench_notice))
		return TRUE
	COOLDOWN_START(src, quench_notice, HERETIC_HAMMER_QUENCH_TIME)
	heretic_hammer_sound(body, "quench", 50, TRUE)
	new /obj/effect/temp_visual/heretic_hammer/quench(get_turf(body))
	if(had)
		body.visible_message(span_notice("От [body] с шипением поднимается пар."), span_userdanger("[capitalize(what)] гасит жар в руках: Накал остыл до нуля и [HERETIC_HAMMER_QUENCH_TIME / (1 SECONDS)] секунды не будет копиться."))
	return TRUE

/// Удар Молотом в двух руках: Накал, отброс, Сокрушающий удар.
/datum/eldritch_knowledge/base_hammer/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	var/datum/status_effect/eldritch/hammer/mark = target.has_status_effect(/datum/status_effect/eldritch/hammer)
	mark?.striker_ref = WEAKREF(user)
	var/datum/status_effect/heretic_hammer_nailed/nail = target.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
	nail?.struck()
	var/obj/item/melee/sickly_blade/hammer/hammer = heretic_hammer_held(user)
	if(!hammer || !can_use(user) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE) || target.stat == DEAD)
		return
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	var/wielded = ISWIELDED(hammer)
	if(COOLDOWN_FINISHED(src, hit_gain))
		COOLDOWN_START(src, hit_gain, wielded ? HERETIC_HAMMER_HIT_GAIN_GAP : HERETIC_HAMMER_ONEHAND_GAIN_GAP)
		gain_combat_resource()
		if(wielded)
			forge_heal(user, target)
	if(!wielded)
		return
	lesson_event("hit", target)
	if(take_crush(user))
		crush(user, target, hammer)
		return
	shove_away(user, target)
	if(hammer.great)
		hammer.shockwave(user, target)

/// Жар горна: ушибы и ожоги поровну из того, что есть; остуженный Молот не лечит.
/datum/eldritch_knowledge/base_hammer/proc/forge_heal(mob/living/user, mob/living/target)
	if(target == user || !target.mind || quenched_until > world.time)
		return 0
	var/heal_brute = min(user.getBruteLoss(), max(HERETIC_HAMMER_FORGE_HEAL / 2, HERETIC_HAMMER_FORGE_HEAL - user.getFireLoss()))
	var/heal_burn = min(user.getFireLoss(), HERETIC_HAMMER_FORGE_HEAL - heal_brute)
	if(heal_brute + heal_burn <= 0)
		return 0
	user.heal_overall_damage(heal_brute, heal_burn, only_organic = FALSE)
	return heal_brute + heal_burn

/datum/eldritch_knowledge/base_hammer/proc/take_crush(mob/living/user)
	var/datum/status_effect/heretic_hammer_swing/swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
	if(swing?.ready)
		qdel(swing)
		return TRUE
	var/datum/status_effect/heretic_hammer_catch/catching = user.has_status_effect(/datum/status_effect/heretic_hammer_catch)
	if(catching?.primed)
		qdel(catching)
		return TRUE
	return FALSE

/proc/heretic_hammer_movable(mob/living/target, force = MOVE_FORCE_STRONG)
	return isliving(target) && !target.anchored && !target.buckled && target.mob_size < MOB_SIZE_LARGE && target.move_resist < force

/// Волну удара держат закрытые двери, окна и фальшстены, как стены; решётка и открытая дверь пропускают.
/proc/heretic_hammer_wave_stopper(obj/thing)
	if(!thing.density)
		return FALSE
	return istype(thing, /obj/machinery/door) || istype(thing, /obj/structure/window) || istype(thing, /obj/structure/falsewall) || istype(thing, /obj/structure/mineral_door)

/// Между соседними по оси клетками стоит стена или то, что держит волну; краевое держит только своей стороной.
/proc/heretic_hammer_edge_blocked(turf/from_turf, turf/to_turf)
	if(!to_turf || to_turf.density)
		return TRUE
	var/direction = get_dir(from_turf, to_turf)
	for(var/obj/thing in from_turf)
		if((thing.flags_1 & ON_BORDER_1) && (thing.dir & direction) && heretic_hammer_wave_stopper(thing))
			return TRUE
	for(var/obj/thing in to_turf)
		if(heretic_hammer_wave_stopper(thing) && (!(thing.flags_1 & ON_BORDER_1) || (thing.dir & turn(direction, 180))))
			return TRUE
	return FALSE

/// Удар Молота по площади доходит до цели, только если по прямой ничего не держит волну, а диагональ открыта хотя бы с одной стороны.
/proc/heretic_hammer_reaches(atom/center, atom/victim)
	var/turf/start = get_turf(center)
	var/turf/finish = get_turf(victim)
	if(!start || !finish || start.z != finish.z)
		return FALSE
	var/turf/previous = start
	for(var/turf/step as anything in getline(start, finish))
		var/direction = get_dir(previous, step)
		if(!direction)
			continue
		if(ISDIAGONALDIR(direction))
			var/turf/side_a = get_step(previous, direction & (NORTH|SOUTH))
			var/turf/side_b = get_step(previous, direction & (EAST|WEST))
			if((heretic_hammer_edge_blocked(previous, side_a) || heretic_hammer_edge_blocked(side_a, step)) && (heretic_hammer_edge_blocked(previous, side_b) || heretic_hammer_edge_blocked(side_b, step)))
				return FALSE
		else if(heretic_hammer_edge_blocked(previous, step))
			return FALSE
		previous = step
	return TRUE

/// Сторона удара по клику: ближайшее к линии клика направление по оси, 0 - клик по своей клетке.
/proc/heretic_hammer_aim_dir(atom/user, atom/target)
	var/turf/start = get_turf(user)
	var/turf/finish = get_turf(target)
	if(!start || !finish || start == finish)
		return 0
	return angle2dir_cardinal(Get_Angle(start, finish))

/datum/eldritch_knowledge/base_hammer/proc/shove_away(mob/living/user, mob/living/target)
	if(!heretic_hammer_movable(target) || target.has_status_effect(/datum/status_effect/heretic_hammer_nailed))
		return FALSE
	var/turf/next = get_step(target, get_dir(user, target))
	return next && target.Move(next, get_dir(user, target))

/datum/eldritch_knowledge/base_hammer/proc/crush(mob/living/user, mob/living/target, obj/item/melee/sickly_blade/hammer/hammer)
	var/zone = check_zone(user.zone_selected)
	target.apply_damage(HERETIC_HAMMER_CRUSH_DAMAGE, BRUTE, zone, target.run_armor_check(zone, MELEE, armour_penetration = hammer.armour_penetration, silent = TRUE))
	gain_combat_resource()
	heretic_hammer_sound(target, "crush", 70, TRUE, 2)
	new /obj/effect/temp_visual/heretic_hammer/crush_ring(get_turf(target))
	shake_camera(user, 2, 1)
	shake_camera(target, 3, 2)
	target.visible_message(span_danger("[user] обрушивает Молот на [target] со всего замаха!"), span_userdanger("[user] обрушивает на вас Молот со всего замаха!"))
	log_combat(user, target, "наносит Сокрушающий удар Молотом", hammer)
	var/datum/antagonist/heretic/heretic = owner_heretic()
	heretic?.advance_combat_deed(target, PATH_HAMMER)
	lesson_event("crush", target)
	if(hammer.great)
		hammer.shockwave(user, target)
	if(target.has_status_effect(/datum/status_effect/heretic_hammer_nailed) || !heretic_hammer_movable(target))
		return
	var/turf/landing = get_ranged_target_turf(target, get_dir(user, target), HERETIC_HAMMER_CRUSH_THROW)
	RegisterSignal(target, COMSIG_MOVABLE_IMPACT, PROC_REF(on_crush_impact), TRUE)
	if(!target.safe_throw_at(landing, HERETIC_HAMMER_CRUSH_THROW, 2, user, FALSE, callback = CALLBACK(src, PROC_REF(crush_landed), target)))
		UnregisterSignal(target, COMSIG_MOVABLE_IMPACT)

/// Брошенный человек сам получает урон удара о стену или о другого человека в carbon/throw_impact().
/proc/heretic_hammer_engine_slam(mob/living/source, atom/hit_atom)
	if(!iscarbon(source) || source.GetComponent(/datum/component/tackler))
		return FALSE
	if(isturf(hit_atom))
		return hit_atom.density
	var/mob/living/carbon/other = hit_atom
	return iscarbon(other) && other != source && !(other.movement_type & FLYING)

/// Урон удара, который carbon/throw_impact() даёт сам: лёгкому меньше, тяжёлому больше.
/proc/heretic_hammer_engine_slam_damage(mob/living/carbon/source, datum/thrownthing/throwingdatum)
	var/extra_speed = 0
	if(throwingdatum && throwingdatum.thrower != source)
		extra_speed = min(max(0, throwingdatum.speed - initial(source.throw_speed)), 3)
	return max(0, 10 + (source.mob_weight - MOB_WEIGHT_NORMAL) * 25) + 5 * extra_speed

/// Сколько урона добавить к удару о преграду, чтобы вышло не меньше HERETIC_HAMMER_SLAM_DAMAGE.
/proc/heretic_hammer_slam_extra(mob/living/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!heretic_hammer_engine_slam(source, hit_atom))
		return HERETIC_HAMMER_SLAM_DAMAGE
	return max(0, HERETIC_HAMMER_SLAM_DAMAGE - heretic_hammer_engine_slam_damage(source, throwingdatum))

/// Новый бросок перебивает прежний без его callback: удар о стену считает только тот, чей это бросок.
/proc/heretic_hammer_own_throw(datum/owner, datum/thrownthing/throwingdatum)
	return throwingdatum?.callback?.object == owner

/datum/eldritch_knowledge/base_hammer/proc/crush_landed(mob/living/target)
	if(!QDELETED(target))
		UnregisterSignal(target, COMSIG_MOVABLE_IMPACT)

/// Сокрушённый врезался в стену, плотную преграду или в другого.
/datum/eldritch_knowledge/base_hammer/proc/on_crush_impact(mob/living/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!heretic_hammer_own_throw(src, throwingdatum))
		UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)
		return
	if(!hit_atom.density && !isliving(hit_atom))
		return
	UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)
	var/extra = heretic_hammer_slam_extra(source, hit_atom, throwingdatum)
	if(extra)
		source.apply_damage(extra, BRUTE)
	source.Knockdown(HERETIC_HAMMER_SLAM_KNOCKDOWN)
	shake_camera(source, 3, 2)
	heretic_hammer_sound(source, "wall_slam", 60, TRUE)
	new /obj/effect/temp_visual/heretic_hammer/wall_impact(get_turf(source))
	if(isliving(hit_atom) && hit_atom != hammer_body)
		var/mob/living/other = hit_atom
		other.Knockdown(HERETIC_HAMMER_SLAM_OTHER_KNOCKDOWN)
		shake_camera(other, 2, 1)
	lesson_event("slam", source, hit_atom)

/datum/eldritch_knowledge/base_hammer/proc/on_hammer_wield(obj/item/melee/sickly_blade/hammer/hammer, mob/living/user)
	if(user != hammer_body)
		return
	var/datum/status_effect/heretic_hammer_catch/catching = user.has_status_effect(/datum/status_effect/heretic_hammer_catch)
	catching?.prime()
	lesson_event("wield", hammer)
	brace(hammer)
	notify_resource_changed()

/datum/eldritch_knowledge/base_hammer/proc/on_hammer_unwield(obj/item/melee/sickly_blade/hammer/hammer, mob/living/user)
	if(user != hammer_body)
		return
	var/datum/status_effect/heretic_hammer_swing/swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
	if(swing && !swing.ready)
		swing.cancel("Молот опущен: замах сорван.")
	if(braced_hammer == hammer)
		unbrace()
	if(user.is_holding(hammer) && (!CHECK_MOBILITY(user, MOBILITY_HOLD) || user.restrained(ignore_grab = TRUE)))
		user.dropItemToGround(hammer)
	notify_resource_changed()

/// Несокрушимый держится, пока Молот в двух руках.
/datum/eldritch_knowledge/base_hammer/proc/brace(obj/item/melee/sickly_blade/hammer/hammer)
	if(braced_hammer && braced_hammer != hammer)
		unbrace()
	braced_hammer = hammer
	if(braced || !knows(/datum/eldritch_knowledge/hammer_unbroken) || !ishuman(hammer_body))
		return
	braced = TRUE
	var/mob/living/carbon/human/body = hammer_body
	ADD_TRAIT(body, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED, REF(src))
	ADD_TRAIT(hammer, TRAIT_NODROP, REF(src))
	body.physiology.heretic_stamina_mod *= 1 - HERETIC_HAMMER_STAMINA_CUT / 100

/datum/eldritch_knowledge/base_hammer/proc/unbrace()
	if(braced)
		braced = FALSE
		if(ishuman(hammer_body))
			var/mob/living/carbon/human/body = hammer_body
			REMOVE_TRAIT(body, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED, REF(src))
			body.physiology.heretic_stamina_mod /= 1 - HERETIC_HAMMER_STAMINA_CUT / 100
		if(braced_hammer)
			REMOVE_TRAIT(braced_hammer, TRAIT_NODROP, REF(src))
	braced_hammer = null

/// Во сколько раз стойка укорачивает оглушение; вознёсшемуся хватает своего.
/datum/eldritch_knowledge/base_hammer/proc/stance_stun_mod(mob/living/source)
	if(!braced_hammer || !heretic_hammer_held(source, TRUE) || HAS_TRAIT(source, TRAIT_HERETIC_ASCENDED))
		return 1
	return 1 - (braced ? HERETIC_HAMMER_UNBROKEN_STUN_CUT : HERETIC_HAMMER_STANCE_STUN_CUT) / 100

/datum/eldritch_knowledge/base_hammer/proc/on_body_knocked_down(mob/living/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(shortening || amount <= 0)
		return NONE
	. = on_body_stunned(source, amount)
	var/mod = stance_stun_mod(source)
	if(. || mod >= 1)
		return
	shortening = TRUE
	source.Knockdown(amount * mod, updating, ignore_canstun)
	shortening = FALSE
	return COMPONENT_NO_STUN

/datum/eldritch_knowledge/base_hammer/proc/on_body_paralyzed(mob/living/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(shortening || amount <= 0)
		return NONE
	. = on_body_stunned(source, amount)
	var/mod = stance_stun_mod(source)
	if(. || mod >= 1)
		return
	shortening = TRUE
	source.Paralyze(amount * mod, updating, ignore_canstun)
	shortening = FALSE
	return COMPONENT_NO_STUN

/// Stun() человека учитывает stun_mod до сигнала, поэтому срок ставится напрямую.
/datum/eldritch_knowledge/base_hammer/proc/on_body_stun(mob/living/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	var/mod = stance_stun_mod(source)
	if(shortening || amount <= 0 || mod >= 1)
		return NONE
	shortening = TRUE
	source.SetStun(max(source.AmountStun(), amount * mod), updating, ignore_canstun)
	shortening = FALSE
	return COMPONENT_NO_STUN

/// Ярость кузни: долгое падение или паралич сокращаются до секунды и дают Накал.
/datum/eldritch_knowledge/base_hammer/proc/on_body_stunned(mob/living/source, amount)
	if(!braced)
		return NONE
	if(tackled_now(source))
		return COMPONENT_NO_STUN
	if(amount <= HERETIC_HAMMER_RAGE_LIMIT || !COOLDOWN_FINISHED(src, rage))
		return NONE
	var/datum/eldritch_knowledge/hammer_unbroken/unbroken = owner_heretic()?.get_knowledge(/datum/eldritch_knowledge/hammer_unbroken)
	if(!unbroken)
		return NONE
	COOLDOWN_START(src, rage, unbroken.rage_cooldown())
	INVOKE_ASYNC(src, PROC_REF(rage), source)
	return COMPONENT_NO_STUN

/datum/eldritch_knowledge/base_hammer/proc/rage(mob/living/source)
	shortening = TRUE
	source.Knockdown(HERETIC_HAMMER_RAGE_LIMIT, TRUE, TRUE)
	shortening = FALSE
	gain_combat_resource(HERETIC_HAMMER_RAGE_HEAT)
	heretic_hammer_sound(source, "rage", 70, TRUE)
	new /obj/effect/temp_visual/heretic_hammer/rage(get_turf(source))
	source.visible_message(span_danger("[source] падает на колено и тут же поднимается, раскалённый от ярости!"), span_notice("Ярость кузни: вы падаете лишь на [HERETIC_HAMMER_RAGE_LIMIT / (1 SECONDS)] секунду и получаете [HERETIC_HAMMER_RAGE_HEAT] Накала."))
	lesson_event("rage", source)

/// Подкат 3+ кладёт через KnockToFloor() мимо сигналов оглушения: Несокрушимый тут же встаёт, захват остаётся.
/datum/eldritch_knowledge/base_hammer/proc/on_body_rested(mob/living/source)
	SIGNAL_HANDLER
	if(braced && tackled_now(source))
		source.set_resting(FALSE, TRUE)

/// Подкат сносит только тех, кто не держит Молот в двух руках; к удару throwing подкатывающего уже сброшен, бросок помнит компонент.
/datum/eldritch_knowledge/base_hammer/proc/tackled_now(mob/living/source)
	for(var/mob/living/carbon/sacker in range(1, source))
		var/datum/component/tackler/tackler = sacker.GetComponent(/datum/component/tackler)
		if(sacker != source && tackler?.tackle?.thrownthing == sacker)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_hammer/proc/on_body_block(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!real_attack || !return_list || return_list[HERETIC_BLOCK_ABSORBED] || damage <= 0 || source.stat == DEAD || !heretic_hammer_held(source, TRUE))
		return BLOCK_NONE
	var/cut = 0
	var/damage_type = return_list[BLOCK_CONTEXT_DAMAGE_TYPE] || heretic_hammer_hit_damage_type(object)
	if((attack_type & (ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_PROJECTILE)) && (damage_type == BRUTE || damage_type == BURN))
		cut = HERETIC_HAMMER_STANCE_CUT
	if(ascension_active && (attack_type & ATTACK_TYPE_PROJECTILE))
		cut = min(HERETIC_HAMMER_PROJECTILE_CUT_CAP, 100 - (100 - cut) * (100 - HERETIC_HAMMER_GREAT_PROJECTILE_CUT) / 100)
	if(!cut)
		return BLOCK_NONE
	var/final_damage = block_calculate_resultant_damage(damage, return_list) * (1 - cut / 100)
	return_list[BLOCK_RETURN_SET_DAMAGE_TO] = final_damage
	return_list[BLOCK_RETURN_MITIGATION_PERCENT] = max(0, 100 * (1 - final_damage / damage))
	return BLOCK_SHOULD_CHANGE_DAMAGE

/proc/heretic_hammer_hit_damage_type(atom/object)
	if(istype(object, /obj/item/projectile))
		var/obj/item/projectile/projectile = object
		return projectile.damage_type
	if(isitem(object))
		var/obj/item/item = object
		return item.damtype
	if(isanimal(object))
		var/mob/living/simple_animal/animal = object
		return animal.melee_damage_type
	return BRUTE

/datum/eldritch_knowledge/base_hammer/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !isliving(target) || !can_use(user))
		return FALSE
	var/mob/living/victim = target
	if(victim.stat == DEAD || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return FALSE
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	gain_combat_resource(HERETIC_HAMMER_GRASP_HEAT)
	lesson_event("grasp", victim)
	return TRUE

/datum/eldritch_knowledge/base_hammer/proc/swing_block_reason(mob/living/user)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	if(!heretic_hammer_held(user, TRUE))
		return "Замах - только Молотом изнанки в двух руках: возьмите его и активируйте в руке."
	if(user.has_status_effect(/datum/status_effect/heretic_hammer_swing))
		return "Молот уже занесён."
	return null

/datum/eldritch_knowledge/base_hammer/proc/swing(mob/living/user)
	if(swing_block_reason(user))
		return FALSE
	user.apply_status_effect(/datum/status_effect/heretic_hammer_swing, src)
	lesson_event("swing", user)
	return TRUE

/datum/eldritch_knowledge/base_hammer/proc/brand_wall_valid(turf/closed/wall/wall)
	return istype(wall) && !istype(wall, /turf/closed/wall/r_wall) && !(locate(/obj/effect/heretic_hammer_brand) in wall)

/// Молот в «Помощи» по стене: Клейм держится HERETIC_HAMMER_BRAND_LIMIT, новое вытесняет старейшее.
/datum/eldritch_knowledge/base_hammer/proc/brand(mob/living/user, turf/closed/wall/wall)
	if(!can_use(user))
		return FALSE
	if(!brand_wall_valid(wall))
		to_chat(user, span_warning("Клеймо ложится только на обычную стену, где его ещё нет."))
		return FALSE
	while(length(brands) >= HERETIC_HAMMER_BRAND_LIMIT)
		var/obj/effect/heretic_hammer_brand/oldest = brands[1]
		brands -= oldest
		qdel(oldest)
	var/obj/effect/heretic_hammer_brand/fresh = new(wall, src)
	user.do_attack_animation(wall)
	user.changeNext_move(CLICK_CD_MELEE)
	shake_camera(user, 1, 1)
	heretic_hammer_sound(wall, "brand_strike", 50, TRUE)
	var/away = is_station_level(wall.z) ? "" : " Клеймо вне станции дело пути не продвинет."
	to_chat(user, span_eldritch("Молот оставляет в стене вмятину, и на дне её тлеет оттиск: стена запомнит каждого, кто пройдёт мимо. Клейм: [length(brands)] из [HERETIC_HAMMER_BRAND_LIMIT].[away]"))
	log_game("[key_name(user)] выбивает Клеймо кузни в [AREACOORD(wall)].")
	notify_resource_changed()
	lesson_event("brand", fresh)
	return TRUE

/datum/eldritch_knowledge/base_hammer/proc/on_brand_removed(obj/effect/heretic_hammer_brand/brand)
	if(!(brand in brands))
		return
	brands -= brand
	if(hammer_body && hammer_body.stat != DEAD)
		to_chat(hammer_body, span_warning("Клеймо кузни стёрто - [get_area_name(brand, TRUE)]. Клейм: [length(brands)] из [HERETIC_HAMMER_BRAND_LIMIT]."))
	notify_resource_changed()

/// Прохожий, которого клеймо слышит: живой человек с разумом, не еретик и не его слуга.
/proc/heretic_hammer_brand_hears(mob/living/passerby)
	return ishuman(passerby) && passerby.mind && passerby.stat != DEAD && !IS_HERETIC(passerby) && !IS_HERETIC_MONSTER(passerby)

/// Клеймо загудело на прохожем: игрок, идущий сам, засчитывает отдел клейма.
/datum/eldritch_knowledge/base_hammer/proc/on_brand_hum(obj/effect/heretic_hammer_brand/brand, mob/living/passerby)
	var/turf/place = get_turf(brand)
	var/datum/antagonist/heretic/heretic = owner_heretic()
	if(!heretic || !heretic_hammer_brand_hears(passerby))
		return FALSE
	lesson_event("brand_hum", passerby)
	var/credited = FALSE
	var/mob/living/heretic_body = heretic.owner?.current
	var/walks_free = GET_CLIENT(passerby) && passerby.stat == CONSCIOUS && !passerby.pulledby && !passerby.buckled && !passerby.restrained(ignore_grab = TRUE)
	if(heretic_body && heretic_body.stat != DEAD && walks_free && place && is_station_level(place.z))
		var/deed_key = heretic.deed_key_for(place)
		if(!heretic.deed_wait_reason(deed_key))
			credited = heretic.advance_deed(deed_key, place, silent = TRUE)
	if(!hammer_body || hammer_body.stat == DEAD || (!credited && !COOLDOWN_FINISHED(brand, owner_notice)))
		return credited
	COOLDOWN_START(brand, owner_notice, HERETIC_HAMMER_BRAND_NOTICE_GAP)
	to_chat(hammer_body, span_notice("Клеймо кузни гудит: мимо прошёл [passerby.name] - [get_area_name(place, TRUE)].[credited ? " Отдел засчитан в дело." : ""]"))
	return credited

/datum/eldritch_knowledge/base_hammer/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в пол", "text" = "Пол под [victim] проламывается, и кузня изнанки тянет вбитого вниз.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/datum/eldritch_knowledge/base_hammer/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	var/datum/status_effect/heretic_hammer_nailed/nail = victim.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
	return nail?.hammer_ref?.resolve() == src

/obj/item/melee/sickly_blade/hammer
	name = "hammer of the abyss"
	desc = "Тяжёлый кузнечный молот: боёк из чёрного железа в окалине, по граням бегут тлеющие швы, а рукоять обмотана цепью. Поднять его можно и одной рукой, но бить им по-настоящему - только двумя, а чужак, перехватив его второй рукой, лишь расколет боёк."
	icon = 'modular_bluemoon/icons/obj/heretic_hammer.dmi'
	icon_state = "hammer_blade"
	item_state = "hammer_blade"
	hitsound = HERETIC_HAMMER_HIT_SFX
	attack_verb = list("smashed", "bashed", "crushed", "hammered", "pounded")
	sharpness = SHARP_NONE
	w_class = WEIGHT_CLASS_BULKY
	force = HERETIC_HAMMER_FORCE
	armour_penetration = HERETIC_HAMMER_ONEHAND_AP
	wound_bonus = 0
	bare_wound_bonus = 5
	actions_types = list(/datum/action/item_action/heretic_escape/hammer)
	route = PATH_HAMMER
	mark_type = /datum/status_effect/eldritch/hammer
	escape_noun = "Молот"
	escape_verb = "расколоть"
	var/base_state = "hammer_blade"
	var/wielded_state = "hammer_blade_wielded"
	var/great = FALSE

/obj/item/melee/sickly_blade/hammer/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded = HERETIC_HAMMER_FORCE, force_wielded = HERETIC_HAMMER_WIELDED_FORCE)
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/melee/sickly_blade/hammer/update_icon_state()
	. = ..()
	icon_state = (ISWIELDED(src) && wielded_state) ? wielded_state : base_state

/// В две руки Молот берут только еретики и их слуги; чужак, перехватывая его, раскалывает Молот, как обычный клинок пути.
/obj/item/melee/sickly_blade/hammer/attack_self(mob/user)
	if(!(IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		shatter_escape(user)
		return
	SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SELF, user)

/obj/item/melee/sickly_blade/hammer/ui_action_click(mob/user, actiontype)
	shatter_escape(user)

/obj/item/melee/sickly_blade/hammer/proc/base_of(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)

/obj/item/melee/sickly_blade/hammer/proc/on_wield(obj/item/source, mob/living/user)
	SIGNAL_HANDLER
	armour_penetration = HERETIC_HAMMER_WIELDED_AP
	bare_wound_bonus = HERETIC_HAMMER_WIELDED_WOUND_BONUS
	attack_speed = HERETIC_HAMMER_ATTACK_SPEED
	item_state = "[base_state]_wielded"
	heretic_hammer_sound(user, "wield", 40, TRUE)
	var/datum/eldritch_knowledge/base_hammer/hammer_knowledge = base_of(user)
	hammer_knowledge?.on_hammer_wield(src, user)

/obj/item/melee/sickly_blade/hammer/proc/on_unwield(obj/item/source, mob/living/user)
	SIGNAL_HANDLER
	armour_penetration = initial(armour_penetration)
	bare_wound_bonus = initial(bare_wound_bonus)
	attack_speed = initial(attack_speed)
	item_state = base_state
	heretic_hammer_sound(user, "unwield", 30, TRUE)
	var/datum/eldritch_knowledge/base_hammer/hammer_knowledge = base_of(user)
	hammer_knowledge?.on_hammer_unwield(src, user)

/obj/item/melee/sickly_blade/hammer/get_damage_to_obj(obj/target, mob/living/user)
	. = ..()
	if(!ISWIELDED(src) || !(IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		return
	. *= (great && istype(target, /obj/vehicle/sealed/mecha)) ? HERETIC_HAMMER_GREAT_MACHINE_MULT : HERETIC_HAMMER_OBJECT_MULT

/obj/item/melee/sickly_blade/hammer/attack(mob/living/target, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	var/datum/eldritch_knowledge/base_hammer/hammer_knowledge = base_of(user)
	if(hammer_knowledge && user.a_intent == INTENT_GRAB && ISWIELDED(src))
		var/datum/eldritch_knowledge/hammer_nail/nail = hammer_knowledge.owner_heretic()?.get_knowledge(/datum/eldritch_knowledge/hammer_nail)
		if(nail?.try_nail(user, target, hammer_knowledge, src))
			return
	if(great && ISWIELDED(src) && iscyborg(target))
		damage_multiplier *= HERETIC_HAMMER_GREAT_MACHINE_MULT
	return ..()

/obj/item/melee/sickly_blade/hammer/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	var/atom/wall = istype(target, /obj/effect/heretic_hammer_brand) ? target.loc : target
	if(user.a_intent == INTENT_HELP && iswallturf(wall))
		var/datum/eldritch_knowledge/base_hammer/hammer_knowledge = base_of(user)
		if(hammer_knowledge)
			hammer_knowledge.brand(user, wall)
			return STOP_ATTACK_PROC_CHAIN
	return ..()

/// Ударная волна Великого Молота: соседей цели отбрасывает на клетку.
/obj/item/melee/sickly_blade/hammer/proc/shockwave(mob/living/user, mob/living/target)
	var/turf/center = get_turf(target)
	if(!center)
		return
	heretic_vfx_shockwave(center, HERETIC_HAMMER_INK, 2, 0.5 SECONDS)
	for(var/mob/living/nearby in orange(1, center))
		if(nearby == user || nearby.stat == DEAD || !heretic_hammer_reaches(center, nearby) || !heretic_can_affect(user, nearby, chargecost = 0, notify = FALSE))
			continue
		nearby.apply_damage(HERETIC_HAMMER_SHOCKWAVE_DAMAGE, BRUTE)
		if(heretic_hammer_movable(nearby) && !nearby.has_status_effect(/datum/status_effect/heretic_hammer_nailed))
			var/turf/next = get_step(nearby, get_dir(center, nearby))
			if(next)
				nearby.Move(next, get_dir(center, nearby))

/obj/item/melee/sickly_blade/hammer/escape_examine()
	return "Нажмите на кнопку Молота «Расколоть молот»: Молот раскалывается, а вы переместитесь в случайное безопасное место станции, потеряв оружие. Активация в руке берёт Молот в две руки или отпускает его. Успейте до оглушения или потери сознания. Следующий побег возможен только через [DisplayTimeText(HERETIC_BLADE_ESCAPE_COOLDOWN)]. Одновременно у вас держится не больше [HERETIC_BLADE_LIMIT] клинков пути, Молот в их числе. Наручники, смирительная рубашка и щит разума не дают расколоть Молот. После вознесения побег закрыт. При неудаче Молот сохранится."

/obj/item/melee/sickly_blade/hammer/examine(mob/user)
	. = ..()
	if(!(IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		return
	. += span_notice("Одной рукой Молот бьёт на [HERETIC_HAMMER_FORCE] без отброса, в двух руках - на [HERETIC_HAMMER_WIELDED_FORCE], отбрасывает цель и бьёт постройки в [HERETIC_HAMMER_OBJECT_MULT] раза сильнее.")
	. += span_notice("Стойка кузнеца: пока Молот в двух руках, ушибы и ожоги от ударов и снарядов по вам слабее на [HERETIC_HAMMER_STANCE_CUT]%, оглушение короче на [HERETIC_HAMMER_STANCE_STUN_CUT]%, а удар по врагу лечит вас на [HERETIC_HAMMER_FORGE_HEAL], пока Молот не остужен.")
	if(great)
		. += span_notice("Великий Молот: в двух руках каждый удар бьёт соседей цели на [HERETIC_HAMMER_SHOCKWAVE_DAMAGE] урона и отбрасывает их, снаряды ранят вас на [HERETIC_HAMMER_GREAT_PROJECTILE_CUT]% слабее, мехи и борги получают в [HERETIC_HAMMER_GREAT_MACHINE_MULT] раза больше.")

/datum/action/item_action/heretic_escape/hammer
	name = "Расколоть молот"
	desc = "Расколите Молот изнанки в руке, чтобы перенестись в случайное безопасное место станции. Молот будет потерян. Применяйте до оглушения или потери сознания. Запрет телепортации, наручники, смирительная рубашка и щит разума мешают побегу. Вознёсшемуся побег закрыт."

/datum/heretic_deed/hammer
	name = "Клеймо кузни"
	next_step = "Ударьте Молотом в намерении «Помощь» по обычной стене и дождитесь, когда мимо клейма пройдёт член экипажа в ещё не зачтённом отделе."
	desc = "Выбивайте Молотом изнанки в намерении «Помощь» клейма на обычных стенах станции. Дело продвигает член экипажа, прошедший в двух клетках от клейма: засчитывается отдел, где оно выбито, каждый отдел один раз."
	craft_wait = "клеймо загудит, но в дело не пойдёт"
	craft_wait_place = "в ещё не зачтённом отделе"
	hint = "Держатся шесть клейм, новое вытесняет старейшее. Коридоры у входа в отделы и проходные залы - хорошие места. На стене остаётся вмятина с тлеющим оттиском, а сварка за 2 секунды или нулевой жезл стирают её."
	trace_name = "hot rivet"
	trace_desc = "На полу лежит раскалённая заклёпка, хотя рядом нечего клепать. Она ещё тёплая."
	trace_state = "trace_hammer"
	combat_hint = "Поразите назначенную цель Сокрушающим ударом или вбейте её в пол."

/datum/heretic_innate/hammer
	name = "Привычка к весу"
	desc = "Тела и ящики вы тащите без замедления, а громоздкие вещи в руках вас не замедляют."

/datum/heretic_innate/hammer/bind(mob/living/user)
	. = ..()
	if(!body)
		return
	ADD_TRAIT(body, TRAIT_HERETIC_HAMMER_HEFT, REF(src))
	body.add_movespeed_mod_immunities(REF(src), list(/datum/movespeed_modifier/pull_slowdown, /datum/movespeed_modifier/bulky_drag, /datum/movespeed_modifier/heavy_mob_drag))
	body.update_equipment_speed_mods()

/datum/heretic_innate/hammer/unbind()
	if(body)
		REMOVE_TRAIT(body, TRAIT_HERETIC_HAMMER_HEFT, REF(src))
		body.remove_movespeed_mod_immunities(REF(src), list(/datum/movespeed_modifier/pull_slowdown, /datum/movespeed_modifier/bulky_drag, /datum/movespeed_modifier/heavy_mob_drag))
		body.update_equipment_speed_mods()
	return ..()

#undef HERETIC_HAMMER_INK
#undef HERETIC_HAMMER_GLOW
#undef HERETIC_HAMMER_CLIMAX_INK
