#define CRYSTALLIZER_CRYSTALS_DMI 'icons/obj/crystallizer_crystals.dmi'

/obj/item/hypernoblium_crystal
	name = "Hypernoblium Crystal"
	desc = "Crystallized oxygen and hypernoblium stored in a bottle to pressure-proof your clothes or stop reactions occurring in portable atmospheric devices."
	icon = CRYSTALLIZER_CRYSTALS_DMI
	icon_state = "hypernoblium_crystal"
	var/uses = 1

/obj/item/hypernoblium_crystal/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

/obj/item/hypernoblium_crystal/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !uses)
		return
	var/obj/item/clothing/worn_item = target
	if(istype(target, /obj/machinery/portable_atmospherics))
		to_chat(user, span_notice("You could insert the crystal into [target], but this device does not support hypernoblium crystals."))
		return
	if(istype(worn_item))
		if(istype(worn_item, /obj/item/clothing/suit/space))
			to_chat(user, span_warning("The [worn_item] is already pressure-resistant!"))
			return
		if(worn_item.min_cold_protection_temperature == SPACE_SUIT_MIN_TEMP_PROTECT && worn_item.clothing_flags & STOPSPRESSUREDAMAGE)
			to_chat(user, span_warning("[worn_item] is already pressure-resistant!"))
			return
		to_chat(user, span_notice("You see how the [worn_item] changes color, it's now pressure proof."))
		worn_item.name = "pressure-resistant [worn_item.name]"
		worn_item.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		worn_item.add_atom_colour("#00fff7", FIXED_COLOUR_PRIORITY)
		worn_item.min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
		worn_item.cold_protection = worn_item.body_parts_covered
		worn_item.clothing_flags |= STOPSPRESSUREDAMAGE
		uses--
		if(uses <= 0)
			qdel(src)
		return
	to_chat(user, span_warning("The crystal can only be used on clothing!"))

/obj/item/nitrium_crystal
	desc = "A weird brown crystal, it smokes when broken"
	name = "nitrium crystal"
	icon = 'icons/obj/nitrium_crystal.dmi'
	icon_state = "nitrium_crystal"
	var/cloud_size = 1

/obj/item/nitrium_crystal/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

/obj/item/nitrium_crystal/attack_self(mob/user)
	. = ..()
	var/datum/effect_system/smoke_spread/smoke = new
	var/turf/location = get_turf(src)
	smoke.set_up(cloud_size, location)
	smoke.attach(location)
	smoke.start()
	qdel(src)
