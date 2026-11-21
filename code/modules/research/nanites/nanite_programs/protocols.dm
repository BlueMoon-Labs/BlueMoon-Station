//Replication Protocols
/datum/nanite_program/protocol/kickstart
	name = "Kickstart Protocol"
	desc = "Протокол репликации: наниты сосредоточиваются на раннем росте, резко ускоряя размножение на несколько минут после первоначальной имплантации, что даёт дополнительные 420 единиц объёма нанитов в первые две минуты."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/boost_duration = 1200

/datum/nanite_program/protocol/kickstart/check_conditions()
	if(!(world.time < nanites.start_time + boost_duration))
		return FALSE
	return ..()

/datum/nanite_program/protocol/kickstart/active_effect()
	nanites.adjust_nanites(null, 3.5)

/datum/nanite_program/protocol/factory
	name = "Factory Protocol"
	desc = "Протокол репликации: наниты строят внутри носителя матрицу-фабрику, постепенно увеличивая скорость размножения и давая в итоге до +2 к производству нанитов примерно через 17 минут. Фабрика разрушается, если протокол неактивен или наниты повреждены ударами током и ЭМИ."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/factory_efficiency = 0
	var/max_efficiency = 1000 //Goes up to 2 bonus regen per tick after 16 minutes and 40 seconds

/datum/nanite_program/protocol/factory/on_process()
	if(!activated || !check_conditions())
		factory_efficiency = max(0, factory_efficiency - 5)
	..()

/datum/nanite_program/protocol/factory/on_emp(severity)
	..()
	factory_efficiency = max(0, factory_efficiency - 300)

/datum/nanite_program/protocol/factory/on_shock(shock_damage)
	..()
	factory_efficiency = max(0, factory_efficiency - 200)

/datum/nanite_program/protocol/factory/on_minor_shock()
	..()
	factory_efficiency = max(0, factory_efficiency - 100)

/datum/nanite_program/protocol/factory/active_effect()
	factory_efficiency = min(factory_efficiency + 1, max_efficiency)
	nanites.adjust_nanites(null, round(0.002 * factory_efficiency, 0.1))

/datum/nanite_program/protocol/pyramid
	name = "Pyramid Protocol"
	desc = "Протокол репликации: наниты применяют альтернативный кооперативный протокол размножения, активный, пока уровень насыщения нанитами выше 80%, что даёт дополнительное производство объёма 1,2 в секунду."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/boost = 1.2

/datum/nanite_program/protocol/pyramid/check_conditions()
	if((nanites.nanite_volume / nanites.max_nanites) < 0.8)
		return FALSE

	return ..()

/datum/nanite_program/protocol/pyramid/active_effect()
	nanites.adjust_nanites(null, boost)

/datum/nanite_program/protocol/offline
	name = "Eclipse Protocol"
	desc = "Протокол репликации: пока носитель спит или находится без сознания, наниты используют меньшее противодействие для более быстрого размножения."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/boost = 3

/datum/nanite_program/protocol/offline/check_conditions()
	var/is_offline = FALSE
	if(nanites.host_mob.IsSleeping() || nanites.host_mob.IsUnconscious())
		is_offline = TRUE
	if(nanites.host_mob.stat == DEAD || HAS_TRAIT(nanites.host_mob, TRAIT_DEATHCOMA))
		is_offline = TRUE
	if(nanites.host_mob.InCritical() && !HAS_TRAIT(nanites.host_mob, TRAIT_NOSOFTCRIT))
		is_offline = TRUE
	if(nanites.host_mob.InFullCritical() && !HAS_TRAIT(nanites.host_mob, TRAIT_NOHARDCRIT))
		is_offline = TRUE
	if(!is_offline)
		return FALSE
	return ..()

/datum/nanite_program/protocol/offline/active_effect()
	nanites.adjust_nanites(null, boost)
/datum/nanite_program/protocol/synergy
	name = "Synergy Protocol"
	desc = "Протокол репликации: наниты синхронизируют свои задачи и процессы внутри носителя, увеличивая скорость размножения пропорционально текущему объёму нанитов."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/max_boost = 2 //The maximum boost this program applies to the nanite replication, multiplied with the current nanite 'saturation' percentage

/datum/nanite_program/protocol/synergy/active_effect()
	nanites.adjust_nanites(null, round(max_boost * (nanites.nanite_volume / nanites.max_nanites), 0.1))

/datum/nanite_program/protocol/hive
	name = "Hive Protocol"
	desc = "Протокол хранения: наниты используют более эффективную решётчатую укладку для хранения объёма, увеличивая максимум до 750."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_STORAGE
	var/extra_volume = 250

/datum/nanite_program/protocol/hive/enable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites + extra_volume)

/datum/nanite_program/protocol/hive/disable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites - extra_volume)

/datum/nanite_program/protocol/zip
	name = "Zip Protocol"
	desc = "Протокол хранения: наниты разбираются и уплотняются в неактивном состоянии, увеличивая максимальный объём до 1000. Однако процесс немного замедляет скорость размножения."
	use_rate = 0.2
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_STORAGE
	var/extra_volume = 500

/datum/nanite_program/protocol/zip/enable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites + extra_volume)

/datum/nanite_program/protocol/zip/disable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites - extra_volume)

/datum/nanite_program/protocol/free_range
	name = "Free-range Protocol"
	desc = "Протокол хранения: наниты отказываются от стандартных протоколов хранения в пользу более дешёвого и органичного подхода. Максимальный объём снижается до 250, но скорость размножения растёт на 0,5."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_STORAGE
	var/boost = 0.5
	var/extra_volume = -250

/datum/nanite_program/protocol/free_range/enable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites + extra_volume)

/datum/nanite_program/protocol/free_range/disable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites - extra_volume)

/datum/nanite_program/protocol/free_range/active_effect()
	nanites.adjust_nanites(null, boost)

/datum/nanite_program/protocol/unsafe_storage
	name = "S.L.O. Protocol"
	desc = "Протокол хранения: «S.L.O.P.» — протокол переопределения уровня хранения — полностью отключает обычные для нанитов меры безопасности, позволяя им достигать максимального объёма целых 2000, но с риском нанести урон носителю при концентрации нанитов выше стандартного предела в 500."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_STORAGE
	var/extra_volume = 1500
	var/next_warning = 0
	var/min_warning_cooldown = 120
	var/max_warning_cooldown = 350
	var/volume_warnings_stage_1 = list("You feel a dull pain in your abdomen.",
									"You feel a tickling sensation in your abdomen.")
	var/volume_warnings_stage_2 = list("You feel a dull pain in your stomach.",
									"You feel a dull pain when breathing.",
									"Your stomach grumbles.",
									"You feel a tickling sensation in your throat.",
									"You feel a tickling sensation in your lungs.",
									"You feel a tickling sensation in your stomach.",
									"Your lungs feel stiff.")
	var/volume_warnings_stage_3 = list("You feel a dull pain in your chest.",
									"You hear a faint buzzing coming from nowhere.",
									"You hear a faint buzzing inside your head.",
									"Your head aches.")
	var/volume_warnings_stage_4 = list("You feel a dull pain in your ears.",
									"You feel a dull pain behind your eyes.",
									"You hear a loud, echoing buzz inside your ears.",
									"You feel dizzy.",
									"You feel an itch coming from behind your eyes.",
									"Your eardrums itch.",
									"You see tiny grey motes drifting in your field of view.")
	var/volume_warnings_stage_5 = list("You feel sick.",
									"You feel a dull pain from every part of your body.",
									"You feel nauseous.")
	var/volume_warnings_stage_6 = list("Your skin itches and burns.",
									"Your muscles ache.",
									"You feel tired.",
									"You feel something skittering under your skin.",)

/datum/nanite_program/protocol/unsafe_storage/enable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites + extra_volume)

/datum/nanite_program/protocol/unsafe_storage/disable_passive_effect()
	. = ..()
	nanites.set_max_volume(null, nanites.max_nanites - extra_volume)

/datum/nanite_program/protocol/unsafe_storage/active_effect()
	if(!iscarbon(host_mob))
		if(prob(10))
			host_mob.adjustBruteLoss(((max(nanites.nanite_volume - 450, 0) / 450) ** 2 ) * 0.5) // 0.5 -> 2 -> 4.5 -> 8 damage per successful tick
		return

	var/mob/living/carbon/C = host_mob

	if(nanites.nanite_volume < 500)
		return

	var/current_stage = 0
	if(nanites.nanite_volume > 500) //Liver is the main hub of nanite replication and the first to be threatened by excess volume
		if(prob(10))
			var/obj/item/organ/liver/liver = C.getorganslot(ORGAN_SLOT_LIVER)
			if(liver)
				liver.applyOrganDamage(0.6)
		current_stage++
	if(nanites.nanite_volume > 750) //Extra volume spills out in other central organs
		if(prob(10))
			var/obj/item/organ/stomach/stomach = C.getorganslot(ORGAN_SLOT_STOMACH)
			if(stomach)
				stomach.applyOrganDamage(0.75)
		if(prob(10))
			var/obj/item/organ/lungs/lungs = C.getorganslot(ORGAN_SLOT_LUNGS)
			if(lungs)
				lungs.applyOrganDamage(0.75)
		current_stage++
	if(nanites.nanite_volume > 1000) //Extra volume spills out in more critical organs
		if(prob(10))
			var/obj/item/organ/heart/heart = C.getorganslot(ORGAN_SLOT_HEART)
			if(heart)
				heart.applyOrganDamage(0.75)
		if(prob(10))
			var/obj/item/organ/brain/brain = C.getorganslot(ORGAN_SLOT_BRAIN)
			if(brain)
				brain.applyOrganDamage(0.75)
		current_stage++
	if(nanites.nanite_volume > 1250) //Excess nanites start invading smaller organs for more space, including sensory organs
		if(prob(13))
			var/obj/item/organ/eyes/eyes = C.getorganslot(ORGAN_SLOT_EYES)
			if(eyes)
				eyes.applyOrganDamage(0.75)
		if(prob(13))
			var/obj/item/organ/ears/ears = C.getorganslot(ORGAN_SLOT_EARS)
			if(ears)
				ears.applyOrganDamage(0.75)
		current_stage++
	if(nanites.nanite_volume > 1500) //Nanites start spilling into the bloodstream, causing toxicity
		if(prob(15))
			C.adjustToxLoss(0.5, TRUE, forced = TRUE) //Not healthy for slimepeople either
		current_stage++
	if(nanites.nanite_volume > 1750) //Nanites have almost reached their physical limit, and the pressure itself starts causing tissue damage
		if(prob(15))
			C.adjustBruteLoss(0.75, TRUE)
		current_stage++

	volume_warning(current_stage)

/datum/nanite_program/protocol/unsafe_storage/proc/volume_warning(tier)
	if(world.time < next_warning)
		return

	var/list/main_warnings
	var/list/extra_warnings

	switch(tier)
		if(1)
			main_warnings = volume_warnings_stage_1
			extra_warnings = null
		if(2)
			main_warnings = volume_warnings_stage_2
			extra_warnings = volume_warnings_stage_1
		if(3)
			main_warnings = volume_warnings_stage_3
			extra_warnings = volume_warnings_stage_1 + volume_warnings_stage_2
		if(4)
			main_warnings = volume_warnings_stage_4
			extra_warnings = volume_warnings_stage_1 + volume_warnings_stage_2 + volume_warnings_stage_3
		if(5)
			main_warnings = volume_warnings_stage_5
			extra_warnings = volume_warnings_stage_1 + volume_warnings_stage_2 + volume_warnings_stage_3 + volume_warnings_stage_4
		if(6)
			main_warnings = volume_warnings_stage_6
			extra_warnings = volume_warnings_stage_1 + volume_warnings_stage_2 + volume_warnings_stage_3 + volume_warnings_stage_4 + volume_warnings_stage_5

	if(prob(35))
		to_chat(host_mob, "<span class='warning'>[pick(main_warnings)]</span>")
		next_warning = world.time + rand(min_warning_cooldown, max_warning_cooldown)
	else if(islist(extra_warnings))
		to_chat(host_mob, "<span class='warning'>[pick(extra_warnings)]</span>")
		next_warning = world.time + rand(min_warning_cooldown, max_warning_cooldown)
