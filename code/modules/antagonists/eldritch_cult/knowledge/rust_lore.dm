/datum/eldritch_knowledge/base_rust
	name = "История кузнеца"
	desc = "Открывает перед вами Путь Ржавчины. \
		Позволяет трансмутировать кухонный нож с любым мусорным предметом в Ржавый Клинок."
	gain_text = "\"Позвольте мне рассказать вам одну историю\", - сказал кузнец, глянув на свой ржавый клинок."
	banned_knowledge = list(/datum/eldritch_knowledge/base_ash,/datum/eldritch_knowledge/base_flesh,/datum/eldritch_knowledge/final_eldritch/ash_final,/datum/eldritch_knowledge/final_eldritch/flesh_final,/datum/eldritch_knowledge/final_eldritch/void_final,/datum/eldritch_knowledge/base_void)
	next_knowledge = list(/datum/eldritch_knowledge/rust_fist)
	required_atoms = list(
		/obj/item/kitchen/knife = 1,
		/obj/item/trash = 1,
	)
	result_atoms = list(/obj/item/melee/sickly_blade/rust)
	cost = 0
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist
	name = "Хватка Ржавчины"
	desc = "Дает вашей способности Хватка Мансуса наносить 500 ед. урона неорганической материи и \
	покрывать ржавчиной любую поверхность, к которой она прикоснется. \
		Уже заржавевшие поверхности разрушаются. ПКМ, чтобы покрыть предмет или поверхность ржавчиной."
	gain_text = "На потолке Мансуса ржавчина растет, словно мох на камне."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/rust_regen)
	var/rust_force = 500
	var/static/list/blacklisted_turfs = typecacheof(list(/turf/closed,/turf/open/space,/turf/open/lava,/turf/open/chasm,/turf/open/floor/plating/rust))
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	var/check = FALSE
	if(ismob(target))
		var/mob/living/mobster = target
		if(!(mobster.mob_biotypes & MOB_ROBOTIC))
			return FALSE
		else
			check = TRUE
	if(user.a_intent == INTENT_HARM || check)
		target.rust_heretic_act()
		return TRUE

/datum/eldritch_knowledge/rust_fist/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/datum/status_effect/eldritch/E = H.has_status_effect(/datum/status_effect/eldritch/rust) || H.has_status_effect(/datum/status_effect/eldritch/ash) || H.has_status_effect(/datum/status_effect/eldritch/flesh)  || H.has_status_effect(/datum/status_effect/eldritch/void)
		if(E)
			E.on_effect()
			H.adjustOrganLoss(pick(ORGAN_SLOT_BRAIN,ORGAN_SLOT_EARS,ORGAN_SLOT_EYES,ORGAN_SLOT_LIVER,ORGAN_SLOT_LUNGS,ORGAN_SLOT_STOMACH,ORGAN_SLOT_HEART),25)

/datum/eldritch_knowledge/spell/area_conversion
	name = "Агрессивный выброс"
	desc = "Распространяет ржавчину на ближайшие поверхности. \
		Уже заржавевшие структуры разрушаются."
	gain_text = "Все мудрые люди хорошо знают, что не стоит посещать Ржавые Холмы... Однако рассказ кузнеца был вдохновляющим."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/rust_conversion
	next_knowledge = list(/datum/eldritch_knowledge/rust_blade_upgrade,/datum/eldritch_knowledge/curse/corrosion,/datum/eldritch_knowledge/crucible,/datum/eldritch_knowledge/spell/rust_wave)
	route = PATH_RUST

/datum/eldritch_knowledge/spell/rust_wave
	name = "Досягаемость покровителя"
	desc = "Теперь вы можете послать заряд ржавчины, который разрушает ближайшую область и отравляет цель при прямом попадании."
	gain_text = "Посланцы надежды, бойтесь того, кто приносит ржавчину!"
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/aimed/rust_wave
	route = PATH_RUST

/datum/eldritch_knowledge/rust_regen
	name = "Ржавая поступь"
	desc = "Дает вам пассивное исцеление и устойчивость к электро-дубинкам, когда вы стоите на ржавчине."
	gain_text = "Скорость была неестественной, сила - беспрецедентной. Кузнец улыбался."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/rust_mark,/datum/eldritch_knowledge/armor,/datum/eldritch_knowledge/essence)
	route = PATH_RUST

/datum/eldritch_knowledge/rust_regen/on_life(mob/user)
	. = ..()
	var/turf/user_loc_turf = get_turf(user)
	if(!istype(user_loc_turf, /turf/open/floor/plating/rust) || !isliving(user))
		return
	var/mob/living/living_user = user
	living_user.adjustBruteLoss(-6, FALSE)
	living_user.adjustFireLoss(-6, FALSE)
	living_user.adjustToxLoss(-6, FALSE, TRUE)
	living_user.adjustOxyLoss(-2, FALSE)
	living_user.adjustStaminaLoss(-12)

/datum/eldritch_knowledge/rust_mark
	name = "Метка Ржавчины"
	desc = "Ваша Хватка Мансуса теперь накладывает Метку ржавчины при попадании. \
	Атакуйте пораженного своим клинком, чтобы активировать метку. \
		При срабатывании, органы и оборудование жертвы имеют 75% шанс получить повреждения и могут быть уничтожены."
	gain_text = "Кузнец смотрит вдаль. На давно потерянное место. \"Ржавые холмы помогают тем, кто в этом нуждается... за определенную цену.\""
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/area_conversion)
	banned_knowledge = list(/datum/eldritch_knowledge/ash_mark,/datum/eldritch_knowledge/flesh_mark,/datum/eldritch_knowledge/void_mark)
	route = PATH_RUST

/datum/eldritch_knowledge/rust_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(isliving(target))
		. = TRUE
		var/mob/living/living_target = target
		living_target.apply_status_effect(/datum/status_effect/eldritch/rust)

/datum/eldritch_knowledge/rust_blade_upgrade
	name = "Токсичный Клинок"
	desc = "Ваш Ржавый Клинок теперь отравляет врагов при атаке."
	gain_text = "Кузнец протягивает вам его клинок. \"Острие проведет вас через плоть, если вы позволите ему это сделать.\" \
		Ржавчина утяжеляет его. Вы пристально осматриваете его. Ржавые холмы зовут тебя."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/entropic_plume)
	banned_knowledge = list(/datum/eldritch_knowledge/ash_blade_upgrade,/datum/eldritch_knowledge/flesh_blade_upgrade,/datum/eldritch_knowledge/void_blade_upgrade)
	route = PATH_RUST

/datum/eldritch_knowledge/rust_blade_upgrade/on_eldritch_blade(mob/target,user,proximity_flag,click_parameters)
	. = ..()
	if(!IS_HERETIC(target))
		if(iscarbon(target))
			var/mob/living/carbon/carbon_target = target
			carbon_target.reagents.add_reagent(/datum/reagent/eldritch, 5)

/datum/eldritch_knowledge/spell/entropic_plume
	name = "Энтропийный шлейф"
	desc = "Дарует вам Энтропийный шлейф, заклинание, выпускающее волну ржавчины. \
		Ослепляет, отравляет и накладывает 'Амок'  на всех язычников, в которых попадает, заставляя их неистово бить \
		всех, кто находится рядом. Также покрывает поверхности ржавчиной и уничтожает их."
	gain_text = "Коррозия была неостановима, ржавчина неумолима. \
		Кузнец ушел, и вы держите его клинок. Язычники, Посланник Ржавчины близок!"
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/cone/staggered/entropic_plume
	next_knowledge = list(/datum/eldritch_knowledge/rust_fist_upgrade,/datum/eldritch_knowledge/spell/cleave,/datum/eldritch_knowledge/summon/rusty)
	route = PATH_RUST

/datum/eldritch_knowledge/armor
	name = "Ритуал оружейника"
	desc = "Теперь вы можете создать жуткую броню, используя стол и противогаз."
	gain_text = "Ржавые холмы приветствовали Кузнеца своей щедростью."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/rust_regen,/datum/eldritch_knowledge/cold_snap)
	required_atoms = list(/obj/structure/table,/obj/item/clothing/mask/gas)
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/eldritch)

/datum/eldritch_knowledge/essence
	name = "Ритуал священника"
	desc = "Теперь вы можете превратить емкость с водой и осколок стекла в бутылку с необычной водой."
	gain_text = "Это старый рецепт. Сова шепнула мне его на ухо."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/rust_regen,/datum/eldritch_knowledge/spell/ashen_shift)
	required_atoms = list(/obj/structure/reagent_dispensers/watertank,/obj/item/shard)
	result_atoms = list(/obj/item/reagent_containers/glass/beaker/eldritch)

/datum/eldritch_knowledge/rust_fist_upgrade
	name = "Мерзкая хватка"
	desc = "Еще больше усиливает вашу хватку, вызывая тошноту у ваших врагов а так-же рвоту и увеличивает скорость, с которой ваша рука разлагает предметы."
	gain_text = "Его прикосновения мерзкие, ужасные и в то же время такие ужасно манящие..."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/grasp_of_decay)
	var/rust_force = 750
	var/static/list/blacklisted_turfs = typecacheof(list(/turf/closed,/turf/open/space,/turf/open/lava,/turf/open/chasm,/turf/open/floor/plating/rust))
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist_upgrade/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.set_disgust(25)
	return TRUE

/datum/eldritch_knowledge/spell/grasp_of_decay
	name = "Хватка распада"
	desc = "Примените свои знания о ржавчине к человеческому телу, знания, которые могут разлагать ваших врагов изнутри, приводя к отказу органов, рвоте или, в конечном счете, к смерти в результате отслаивания гниющей плоти."
	gain_text = "Ржавчина, разложение - все это одно и то же. Остается только применять их вместе."
	cost = 2
	sacs_needed = 3
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay
	next_knowledge = list(/datum/eldritch_knowledge/final_eldritch/rust_final)
	route = PATH_RUST

/datum/eldritch_knowledge/spell/grasp_of_decay/on_gain(mob/user)
	. = ..()
	priority_announce("Внимание, [station_name()]. [user.real_name] излучает пространственную нестабильность, в связи с которой дует ржавый ветер... пол скрипит, сдавливаясь под приближающейся угрозой!", sound = 'sound/misc/notice1.ogg')

/datum/eldritch_knowledge/final_eldritch/rust_final
	name = "Клятва Посланника Ржавчины"
	desc = "Ритуал вознесения пути Ржавчины. \
		Принесите 3 трупа к руне трансмутации на мостик станции, чтобы совершить ритуал. \
		Когда ритуал будет завершен, руна будет бесконечно распространять ржавчину на любую поверхность, не останавливаясь ни перед чем. \
		Кроме того, вы станете чрезвычайно живучими на ржавчине, исцеляясь в три раза быстрее \
		и получите иммунитет ко многим эффектам и опасностям."
	gain_text = "Чемпион ржавчины. Разрушитель стали. Бойся темноты, ибо пришел Посланник Ржавчины! \
		Кузнец идет вперед! Ржавые холмы, зовут меня по имени! НАБЛЮДАЙТЕ ЗА МОИМ ВОЗНЕСЕНИЕМ!"
	cost = 5
	sacs_needed = 5
	required_atoms = list(/mob/living/carbon/human)
	route = PATH_RUST

/datum/eldritch_knowledge/final_eldritch/rust_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/mob/living/carbon/human/H = user
	H.physiology.brute_mod *= 0.5
	H.physiology.burn_mod *= 0.5
	H.client?.give_award(/datum/award/achievement/misc/rust_ascension, H)
	priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Бойтесь разложения, что несёт Ржавый Всадник, [user.real_name], возносясь над вами! Никто не избежит от коррозии! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'modular_bluemoon/kovac_shitcode/sound/eldritch/rust_lore.ogg')
	new /datum/rust_spread(loc)
	var/datum/antagonist/heretic/ascension = H.mind.has_antag_datum(/datum/antagonist/heretic)
	ascension.ascended = TRUE
	return ..()

/datum/eldritch_knowledge/final_eldritch/rust_final/on_life(mob/user)
	. = ..()
	if(!finished)
		return
	var/mob/living/carbon/human/human_user = user
	human_user.adjustBruteLoss(-12, FALSE)
	human_user.adjustFireLoss(-12, FALSE)
	human_user.adjustToxLoss(-12, FALSE, TRUE)
	human_user.adjustOxyLoss(-12, FALSE)
	human_user.adjustStaminaLoss(-40)


/**
  * #Rust spread datum
  *
  * Simple datum that automatically spreads rust around it
  *
  * Simple implementation of automatically growing entity
  */
/datum/rust_spread
	var/list/edge_turfs = list()
	var/list/turfs = list()
	var/static/list/blacklisted_turfs = typecacheof(list(/turf/open/indestructible,/turf/closed/indestructible,/turf/open/space,/turf/open/lava,/turf/open/chasm))
	var/spread_per_tick = 6


/datum/rust_spread/New(loc)
	. = ..()
	var/turf/turf_loc = get_turf(loc)
	turf_loc.rust_heretic_act()
	turfs += turf_loc
	START_PROCESSING(SSprocessing,src)


/datum/rust_spread/Destroy(force, ...)
	STOP_PROCESSING(SSprocessing,src)
	return ..()

/datum/rust_spread/process()
	compile_turfs()
	var/turf/T
	for(var/i in 0 to spread_per_tick)
		T = pick(edge_turfs)
		T.rust_heretic_act()
		turfs += get_turf(T)

/**
  * Compile turfs
  *
  * Recreates all edge_turfs as well as normal turfs.
  */
/datum/rust_spread/proc/compile_turfs()
	edge_turfs = list()
	for(var/X in turfs)
		if(!istype(X,/turf/closed/wall/rust) && !istype(X,/turf/closed/wall/r_wall/rust) && !istype(X,/turf/open/floor/plating/rust))
			turfs -=X
			continue
		for(var/turf/T in range(1,X))
			if(T in turfs)
				continue
			if(is_type_in_typecache(T,blacklisted_turfs))
				continue
			edge_turfs += T
