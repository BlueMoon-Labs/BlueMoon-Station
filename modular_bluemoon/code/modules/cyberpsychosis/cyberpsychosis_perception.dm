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

/datum/cyberpsychosis/proc/clear_other_perception()
	if(owner && !QDELETED(owner) && owner.client && length(perception_images))
		for(var/K in perception_images)
			owner.client.images -= perception_images[K]
	perception_images.Cut()