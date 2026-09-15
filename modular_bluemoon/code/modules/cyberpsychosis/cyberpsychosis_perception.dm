// Восприятие чужих при киберпсихозе. На стадиях >= MODERATE перестаёт
// различать других персонажей: вместо имени - "Unknown", а вид - тёмный
// силуэт в блюре (образец - /datum/hallucination/delusion + BM_FILTER_HARDCRIT).
// Оверлеи живут только в owner.client.images, реальные мобы не меняются.

/// Поддерживает у owner'а оверлеи "все люди = Unknown + тёмный силуэт".
/datum/cyberpsychosis/proc/update_other_perception()
	if(!owner || QDELETED(owner) || !owner.client)
		clear_other_perception()
		return
	var/list/current_anchors = list()
	for(var/mob/living/carbon/human/H in view(CYBERPSYCHOSIS_OTHER_VIEW_RANGE, owner))
		if(H == owner || H.stat == DEAD)
			continue
		current_anchors[H] = TRUE
		if(perception_images[H])
			continue
		var/image/I = image('icons/mob/human.dmi', H, "husk")
		I.name = "Unknown"
		I.color = "#777777"
		I.alpha = 175
		I.layer = MOB_LAYER
		I.override = TRUE
		perception_images[H] = I
		owner.client.images |= I
	for(var/mob/living/carbon/human/H in perception_images)
		if(!current_anchors[H] || QDELETED(H))
			owner.client.images -= perception_images[H]
			perception_images -= H

/// Убирает у owner'а все оверлеи восприятия (когда стадия упала или нет клиента).
/datum/cyberpsychosis/proc/clear_other_perception()
	if(owner && !QDELETED(owner) && owner.client && length(perception_images))
		for(var/K in perception_images)
			owner.client.images -= perception_images[K]
	perception_images.Cut()