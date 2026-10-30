GLOBAL_LIST_INIT(innate_features, init_innate_features())

/proc/init_innate_features()
	var/list/features = list()
	for(var/datum/innate_feature/feature_type as anything in subtypesof(/datum/innate_feature))
		if(!initial(feature_type.id))
			continue
		var/datum/innate_feature/feature = new feature_type
		features[feature.id] = feature
	return features

// Общий справочник: условия одновременно используются интерфейсом и серверной проверкой.
/datum/innate_feature
	var/name = "Innate feature"
	var/desc
	var/id
	var/display_name
	var/primary = FALSE
	var/quirk_cost = 0
	var/required_taur_type
	var/list/required_bodyparts
	var/list/required_quirks
	var/list/incompatible_quirks
	var/list/incompatible_features
	var/medical_tooltip
	var/required_taur_display_name

/datum/innate_feature/proc/requirements(datum/preferences/prefs)
	var/list/result = list()
	if(required_taur_type)
		var/datum/sprite_accessory/taur/taur = GLOB.taur_list[prefs.features["taur"]]
		var/datum/sprite_accessory/taur/required_taur = required_taur_type
		result += list(list("text" = "Тип тела: [required_taur_display_name || initial(required_taur.name)] (включая варианты)", "met" = istype(taur, required_taur_type) && !!prefs.pref_species.mutant_bodyparts["taur"]))
		result += list(list("text" = "Случайная внешность при входе отключена", "met" = !prefs.be_random_body))
	for(var/zone in required_bodyparts)
		var/list/modification = prefs.modified_limbs[zone]
		result += list(list("text" = "Естественная конечность: [ru_parse_zone(zone)]", "met" = !length(modification)))
	for(var/quirk in required_quirks)
		result += list(list("text" = "Необходим квирк: [quirk]", "met" = (quirk in prefs.all_quirks)))
	for(var/quirk in incompatible_quirks)
		result += list(list("text" = "Несовместимый квирк: [quirk]", "met" = !(quirk in prefs.all_quirks)))
	for(var/feature_id in incompatible_features)
		var/datum/innate_feature/other = GLOB.innate_features[feature_id]
		result += list(list("text" = "Несовместимая особенность: [other?.display_name]", "met" = !(feature_id in prefs.innate_features)))
	if(primary)
		var/available = TRUE
		for(var/feature_id in prefs.innate_features)
			var/datum/innate_feature/other = GLOB.innate_features[feature_id]
			if(other?.primary && other != src)
				available = FALSE
		result += list(list("text" = "Не более одной основной особенности", "met" = available))
	var/balance = prefs.quirk_balance() + ((id in prefs.innate_features) ? quirk_cost : 0)
	result += list(list("text" = "Стоимость: [quirk_cost] очк. квирков", "met" = !quirk_cost || balance >= quirk_cost))
	return result

/datum/innate_feature/proc/available(datum/preferences/prefs)
	for(var/list/requirement as anything in requirements(prefs))
		if(!requirement["met"])
			return FALSE
	return TRUE

/datum/innate_feature/proc/apply_to_human(mob/living/carbon/human/character)
	return

/datum/innate_feature/proc/remove_from_human(mob/living/carbon/human/character)
	return

/datum/innate_feature/naga_tail
	name = "Supporting tail"
	desc = "Заменяет обе ноги одним повреждаемым хвостом. Персонаж умеет передвигаться только хвостом: после переноса разума в тело с ногами сможет лишь ползать. Медик может ампутировать обе ноги нового тела и пересадить опорный хвост через пах. Обувной слот недоступен; хвост защищён от стекла и мусора, как при «Твёрдых ступнях». MOD-костюм разворачивается и включается без ботинок; модули, которым необходимы ботинки, недоступны. Критический перелом замедляет движение, но не лишает хвост опорной функции."
	id = INNATE_NAGA_TAIL
	display_name = "Опорный хвост"
	required_taur_type = /datum/sprite_accessory/taur/naga
	required_bodyparts = list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	incompatible_quirks = list(/datum/quirk/hard_soles::name)
	medical_tooltip = "У пациента отсутствуют ноги. Хирургические операции на опорном хвосте необходимо начинать в области паха. Пересадка хвоста в тело с ногами возможна после ампутации обеих ног."
	required_taur_display_name = "Змеиный хвост-туловище"

/datum/innate_feature/naga_tail/apply_to_human(mob/living/carbon/human/character)
	character.sync_naga_anatomy()

/datum/innate_feature/naga_tail/remove_from_human(mob/living/carbon/human/character)
	character.sync_naga_anatomy()

// Навык принадлежит личности; изменение анатомии тела само по себе его не переписывает.
/datum/mind/proc/set_naga_locomotion(enabled, update_mobility = TRUE)
	var/previous = HAS_TRAIT(src, TRAIT_NAGA_LOCOMOTION)
	if(enabled)
		ADD_TRAIT(src, TRAIT_NAGA_LOCOMOTION, INNATE_NAGA_TAIL)
	else
		REMOVE_TRAIT(src, TRAIT_NAGA_LOCOMOTION, INNATE_NAGA_TAIL)
	. = previous != HAS_TRAIT(src, TRAIT_NAGA_LOCOMOTION)
	if(update_mobility && isliving(current) && .)
		current?.update_mobility()

/mob/living/carbon/human
	var/list/applied_innate_features

/mob/living/carbon/human/proc/sync_innate_features()
	if(!dna?.species)
		return
	var/list/selected = dna.features["innate_features"]
	for(var/feature_id in applied_innate_features)
		if(islist(selected) && (feature_id in selected))
			continue
		var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
		feature?.remove_from_human(src)
	applied_innate_features = list()
	if(islist(selected))
		for(var/feature_id in selected)
			var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
			if(!feature)
				continue
			feature.apply_to_human(src)
			applied_innate_features |= feature_id

/datum/preferences
	var/list/innate_features = list()

/datum/preferences/proc/innate_features_cost()
	. = 0
	for(var/feature_id in innate_features)
		var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
		if(feature)
			. += feature.quirk_cost

// Сохраняем только известные уникальные идентификаторы; недоступный выбор виден в редакторе, но не применяется.
/datum/preferences/proc/sanitize_innate_features()
	var/list/sanitized = list()
	var/has_primary = FALSE
	if(islist(innate_features))
		for(var/feature_id in innate_features)
			if(!istext(feature_id))
				continue
			var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
			if(!feature || (feature.primary && has_primary))
				continue
			sanitized |= feature_id
			has_primary ||= feature.primary
	innate_features = sanitized

/datum/preferences/proc/valid_innate_features()
	var/list/selected = list()
	for(var/feature_id in innate_features)
		var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
		if(feature?.available(src))
			selected += feature_id
	return selected

/datum/preferences/proc/apply_innate_features(mob/living/carbon/human/character)
	character.dna.features["innate_features"] = valid_innate_features()
	// Настройки меняют навык и тело вместе, без промежуточного падения из-за несовпадения моторики.
	var/motor_changed = character.mind?.set_naga_locomotion(INNATE_NAGA_TAIL in character.dna.features["innate_features"], update_mobility = FALSE)
	character.sync_innate_features()
	if(motor_changed)
		character.update_mobility()

/datum/character_setup/proc/build_innate_data()
	var/list/items = list()
	for(var/feature_id in GLOB.innate_features)
		var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
		items += list(list(
			"id" = feature.id,
			"name" = feature.display_name,
			"desc" = feature.desc,
			"primary" = feature.primary,
			"selected" = (feature_id in prefs.innate_features),
			"available" = feature.available(prefs),
			"requirements" = feature.requirements(prefs),
		))
	return list("items" = items, "balance" = prefs.quirk_balance())

/datum/character_setup/proc/toggle_innate_feature(feature_id)
	if(!istext(feature_id))
		return
	var/datum/innate_feature/feature = GLOB.innate_features[feature_id]
	if(!feature)
		return
	if(feature_id in prefs.innate_features)
		if(prefs.quirk_balance() + feature.quirk_cost < min(0, prefs.quirk_balance()))
			return
		prefs.innate_features -= feature_id
	else if(feature.available(prefs))
		prefs.innate_features += feature_id
	preview_dirty = TRUE
