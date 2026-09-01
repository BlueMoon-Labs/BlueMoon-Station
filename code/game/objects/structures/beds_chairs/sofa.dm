/// Create colored subtypes for sofas
#define COLORED_SOFA(path, color_name, sofa_color) \
path/middle/color_name {\
	color = sofa_color; \
} \
path/right/color_name {\
	color = sofa_color; \
} \
path/left/color_name {\
	color = sofa_color; \
} \
path/corner/color_name {\
	color = sofa_color; \
}

/obj/structure/chair/sofa
	name = "Old Ratty Sofa"
	icon_state = "sofamiddle"
	icon = 'icons/obj/sofa.dmi'
	buildstackamount = 1
	item_chair = null
	lone_standing = FALSE
	var/mutable_appearance/armrest

/obj/structure/chair/sofa/Initialize(mapload)
	AddElement(/datum/element/soft_landing)
	armrest = gen_armrest()
	armrest.layer = ABOVE_MOB_LAYER
	return ..()

/obj/structure/chair/sofa/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	if(same_z_layer)
		return ..()
	cut_overlay(armrest)
	QDEL_NULL(armrest)
	return ..()

/obj/structure/chair/sofa/proc/gen_armrest()
	return mutable_appearance(initial(icon), "[icon_state]_armrest")

/obj/structure/chair/sofa/post_buckle_mob(mob/living/M)
	. = ..()
	update_armrest()

/obj/structure/chair/sofa/proc/update_armrest()
	if(has_buckled_mobs())
		add_overlay(armrest)
	else
		cut_overlay(armrest)

/obj/structure/chair/sofa/post_unbuckle_mob()
	. = ..()
	update_armrest()

/obj/structure/chair/sofa/corner/handle_layer() //only the armrest/back of this chair should cover the mob.
	return

/obj/structure/chair/sofa/middle
	icon_state = "sofamiddle"

/obj/structure/chair/sofa/left
	icon_state = "sofaend_left"

/obj/structure/chair/sofa/right
	icon_state = "sofaend_right"

/obj/structure/chair/sofa/corner
	icon_state = "sofacorner"

COLORED_SOFA(/obj/structure/chair/sofa, brown, SOFA_BROWN)
COLORED_SOFA(/obj/structure/chair/sofa, maroon, SOFA_MAROON)

// Original icon ported from Eris(?) and updated to work here.
/obj/structure/chair/sofa/corp
	name = "sofa"
	desc = "Soft and cushy."
	icon_state = "corp_sofamiddle"

/obj/structure/chair/sofa/corp/right
	icon_state = "corp_sofaend_left"

/obj/structure/chair/sofa/corp/left
	icon_state = "corp_sofaend_right"

/obj/structure/chair/sofa/corp/corner
	icon_state = "corp_sofacorner"

/obj/structure/chair/sofa/corp/corner/handle_layer() //only the armrest/back of this chair should cover the mob.
	return

#undef COLORED_SOFA
