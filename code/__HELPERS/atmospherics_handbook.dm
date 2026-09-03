GLOBAL_LIST_EMPTY(reaction_handbook)
GLOBAL_LIST_EMPTY(gas_handbook)
GLOBAL_LIST_EMPTY(atmos_topic_handbook)

/// Русские подписи факторов, которые не являются газом. Сам ключ приходит из
/// factor-списка реакции и служит идентификатором, поэтому переводится только
/// подпись, а ключ остаётся английским.
GLOBAL_LIST_INIT(atmos_handbook_factor_names, list(
	"Temperature" = "Температура",
	"Pressure" = "Давление",
	"Energy" = "Энергия",
	"Radiation" = "Радиация",
	"Location" = "Где идёт",
))

/// Подсказки к тем же факторам. Лежат рядом с подписями, а не в интерфейсе:
/// текст для игрока в этой подсистеме держится на стороне DM целиком.
GLOBAL_LIST_INIT(atmos_handbook_factor_tooltips, list(
	"Temperature" = "На реакцию влияет температура смеси там, где реакция идёт.",
	"Pressure" = "На реакцию влияет давление смеси там, где реакция идёт.",
	"Energy" = "Энергия, которую реакция выделяет или поглощает. Насколько при этом изменится температура, зависит от теплоёмкости смеси и от того, какие ещё газы в ней есть.",
	"Radiation" = "Реакция излучает опасную радиацию. Нужна защита или расстояние.",
	"Location" = "На открытом турфе у реакции своё поведение, отличное от того, что происходит в трубе или машине.",
))

/// Builds factor metadata for the atmos handbook from a reaction's factor list.
/proc/atmos_handbook_parse_factors(list/factors, list/momentary_gas_list, reaction_id, reaction_name, list/reaction_info)
	for(var/factor in factors)
		var/list/factor_info = list()
		factor_info["desc"] = factors[factor]

		var/list/gas_info = momentary_gas_list[factor]
		if(gas_info)
			gas_info["reactions"][reaction_id] = reaction_name
			factor_info["factor_id"] = gas_info["id"]
			factor_info["factor_type"] = "gas"
			factor_info["factor_name"] = gas_info["name"]
		else
			factor_info["factor_name"] = GLOB.atmos_handbook_factor_names[factor] || factor
			factor_info["factor_type"] = "misc"
			var/tooltip = GLOB.atmos_handbook_factor_tooltips[factor]
			if(tooltip)
				factor_info["tooltip"] = tooltip

		reaction_info["factors"] += list(factor_info)

/// Собирает разделы справочника сверх газов и реакций: инструменты, методы,
/// безопасность, давление в трубах.
/proc/atmos_handbook_topics_init()
	GLOB.atmos_topic_handbook = list()

	var/list/by_category = list()
	for(var/topic_path in subtypesof(/datum/atmos_handbook_topic))
		var/datum/atmos_handbook_topic/topic = new topic_path
		if(!topic.category || !topic.title || !length(topic.paragraphs))
			qdel(topic)
			continue
		// Дописываем прямо по ключу, а не через локальную ссылку на список:
		// так результат не зависит от того, приписывает ли += к списку на месте
		// или собирает новый.
		if(!by_category[topic.category])
			by_category[topic.category] = list()
		by_category[topic.category] += topic

	for(var/category in GLOB.atmos_handbook_categories)
		var/list/bucket = by_category[category]
		if(!length(bucket))
			continue
		sortTim(bucket, GLOBAL_PROC_REF(cmp_atmos_handbook_topic_asc))
		var/list/topics = list()
		for(var/datum/atmos_handbook_topic/topic as anything in bucket)
			// Копия, а не сам список: датум сразу после этого умирает, и
			// справочник не должен зависеть от того, что делает его Destroy.
			topics += list(list(
				"title" = topic.title,
				"paragraphs" = topic.paragraphs.Copy(),
			))
		GLOB.atmos_topic_handbook += list(list(
			"category" = category,
			"topics" = topics,
		))

	for(var/category in by_category)
		var/list/bucket = by_category[category]
		for(var/datum/atmos_handbook_topic/topic as anything in bucket)
			qdel(topic)

/// Populates GLOB.gas_handbook and GLOB.reaction_handbook for UIs (AtmoZphere handbook tab).
/proc/atmos_handbooks_init()
	GLOB.reaction_handbook = list()
	GLOB.gas_handbook = list()

	var/list/momentary_gas_list = list()
	for(var/gas_path in subtypesof(/datum/gas))
		var/datum/gas/gas = new gas_path
		var/list/gas_info = list()
		gas_info["id"] = gas.id
		gas_info["name"] = gas.name
		gas_info["description"] = gas.description
		gas_info["specific_heat"] = gas.specific_heat
		// Уровень и цена идут в справочник, чтобы лестница "сложнее сделать -
		// дороже" была видна в игре, а не только в исходниках и на вики.
		gas_info["tier"] = gas.tier
		gas_info["price"] = gas.price
		gas_info["reactions"] = list()
		momentary_gas_list[gas_path] = gas_info
		momentary_gas_list[gas.id] = gas_info

	for(var/reaction_path in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = new reaction_path
		if(reaction.exclude && reaction.id == "condense")
			qdel(reaction)
			continue
		var/list/reaction_info = list()
		reaction_info["id"] = reaction.id
		reaction_info["name"] = reaction.name
		reaction_info["description"] = reaction.desc
		if(reaction.exclude)
			reaction_info["disabled"] = TRUE
		reaction_info["factors"] = list()
		atmos_handbook_parse_factors(reaction.factor, momentary_gas_list, reaction.id, reaction.name, reaction_info)
		GLOB.reaction_handbook += list(reaction_info)
		qdel(reaction)

	for(var/reaction_path in subtypesof(/datum/electrolyzer_reaction))
		var/datum/electrolyzer_reaction/reaction = new reaction_path
		var/list/reaction_info = list()
		reaction_info["id"] = reaction.id
		reaction_info["name"] = reaction.name
		reaction_info["description"] = reaction.desc
		reaction_info["factors"] = list()
		atmos_handbook_parse_factors(reaction.factor, momentary_gas_list, reaction.id, reaction.name, reaction_info)
		GLOB.reaction_handbook += list(reaction_info)
		qdel(reaction)

	for(var/gas_path in momentary_gas_list)
		if(!ispath(gas_path, /datum/gas))
			continue
		GLOB.gas_handbook += list(momentary_gas_list[gas_path])

	atmos_handbook_topics_init()

/// Returns handbook data for TGUI static payloads.
/proc/return_atmos_handbooks()
	return list(
		"gasInfo" = GLOB.gas_handbook,
		"reactionInfo" = GLOB.reaction_handbook,
		"topicInfo" = GLOB.atmos_topic_handbook,
	)
