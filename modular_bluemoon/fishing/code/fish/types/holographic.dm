
/obj/item/fish/holo
	name = "holographic goldfish"
	fish_id = "hologoldfish"
	desc = "Голограмма обычной золотой рыбки, медленно мерцающая вдали от родного голо-обиталища."
	icon_state = /obj/item/fish/goldfish::icon_state
	fish_flags = parent_type::fish_flags & ~(FISH_FLAG_SHOW_IN_CATALOG|FISH_FLAG_EXPERIMENT_SCANNABLE)
	random_case_rarity = FISH_RARITY_NOPE
	dedicated_in_aquarium_icon_state = /obj/item/fish/goldfish::dedicated_in_aquarium_icon_state
	aquarium_vc_color = /obj/item/fish/goldfish::aquarium_vc_color
	sprite_width = /obj/item/fish/goldfish::sprite_width
	sprite_height = /obj/item/fish/goldfish::sprite_height
	stable_population = 1
	average_size = /obj/item/fish/goldfish::average_size
	average_weight = /obj/item/fish/goldfish::average_weight
	required_fluid_type = AQUARIUM_FLUID_ANADROMOUS
	fillet_type = null
	death_text = "%SRC тихо исчезает."
	fish_traits = list(/datum/fish_trait/no_mating) //просто на всякий случай, они не должны размножаться
	beauty = /obj/item/fish/goldfish::beauty

/obj/item/fish/holo/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	var/area/station/holodeck/holo_area = get_area(src)
	if(!istype(holo_area))
		addtimer(CALLBACK(src, PROC_REF(set_status), FISH_DEAD), 1 MINUTES)
		return
	holo_area.linked.add_to_spawned(src)

/obj/item/fish/holo/make_edible(weight_val)
	return

/obj/item/fish/holo/set_status(new_status, silent = FALSE)
	. = ..()
	if(status == FISH_DEAD)
		animate(src, alpha = 0, 3 SECONDS, easing = SINE_EASING)
		QDEL_IN(src, 3 SECONDS)

/obj/item/fish/holo/suicide_act(mob/living/user)
	visible_message(span_suicide("[user] проглатывает [src] целиком! Похоже, [user] пытается стереть себя из реальности!"))
	var/area/station/holodeck/holo_area = get_area(src)
	if(!istype(holo_area))
		user.dust(just_ash = TRUE, drop_items = TRUE)
		return MANUAL_SUICIDE
	holo_area.linked.add_to_spawned(user) // ой
	return MANUAL_SUICIDE_NONLETHAL

/obj/item/fish/holo/crab
	name = "holographic crab"
	fish_id = "holocrab"
	desc = "Голограмма душераздирающе бездушного краба. Смотрит на вас пустыми бусинами глаз."
	icon_state = "crab"
	dedicated_in_aquarium_icon_state = null
	aquarium_vc_color = null
	average_size = 30
	average_weight = 1000
	sprite_height = 6
	sprite_width = 10
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/holo/puffer
	name = "holographic pufferfish"
	fish_id = "holopufferfish"
	desc = "Голограмма абсолютно безопасной фугу... если бы голограммы вообще можно было есть."
	icon_state = /obj/item/fish/pufferfish::icon_state
	dedicated_in_aquarium_icon_state = /obj/item/fish/pufferfish::dedicated_in_aquarium_icon_state
	aquarium_vc_color = /obj/item/fish/pufferfish::aquarium_vc_color
	average_size = /obj/item/fish/pufferfish::average_size
	average_weight = /obj/item/fish/pufferfish::average_weight
	sprite_height = /obj/item/fish/pufferfish::sprite_height
	sprite_width = /obj/item/fish/pufferfish::sprite_width
	beauty = /obj/item/fish/pufferfish::beauty

/obj/item/fish/holo/angel
	name = "holographic angelfish"
	fish_id = "holoangelfish"
	desc = "Голограмма скалярии. Даже сказать по этому поводу нечего."
	icon_state = /obj/item/fish/angelfish::icon_state
	dedicated_in_aquarium_icon_state = /obj/item/fish/angelfish::dedicated_in_aquarium_icon_state
	aquarium_vc_color = /obj/item/fish/angelfish::aquarium_vc_color
	average_size = /obj/item/fish/angelfish::average_size
	average_weight = /obj/item/fish/angelfish::average_weight
	sprite_height = /obj/item/fish/angelfish::sprite_height
	sprite_width = /obj/item/fish/angelfish::sprite_width
	beauty = /obj/item/fish/angelfish::beauty

/obj/item/fish/holo/clown
	name = "holographic clownfish"
	fish_id = "holoclownfish"
	icon_state = "holo_clownfish"
	desc = "Голограмма рыбы-клоуна. Или того, как она выглядела пять веков назад."
	dedicated_in_aquarium_icon_state = null
	aquarium_vc_color = /obj/item/fish/clownfish::aquarium_vc_color
	average_size = /obj/item/fish/clownfish::average_size
	average_weight = /obj/item/fish/clownfish::average_weight
	sprite_height = /obj/item/fish/clownfish::sprite_height
	sprite_width = /obj/item/fish/clownfish::sprite_width
	required_fluid_type = /obj/item/fish/clownfish::required_fluid_type
	beauty = /obj/item/fish/clownfish::beauty

/obj/item/fish/holo/checkered
	name = "unrendered holographic fish"
	fish_id = "checkered"
	desc = "Шахматный силуэт ослепительно-фиолетового и чёрного цвета, будто разрыв в реальности. Смотреть больно."
	icon_state = "checkered" //это меташутка, дружище.
	dedicated_in_aquarium_icon_state = null
	aquarium_vc_color = null
	average_size = 30
	average_weight = 500
	sprite_width = 4
	sprite_height = 3
	beauty = FISH_BEAUTY_NULL

/obj/item/fish/holo/checkered/suicide_act(mob/living/carbon/user)
	if(!iscarbon(user))
		return ..()

	for(var/obj/item/bodypart/limb in user.bodyparts)
		limb.add_color_override(COLOR_WHITE, LIMB_COLOR_CS_SOURCE_SUICIDE)
		limb.add_bodypart_overlay(new /datum/bodypart_overlay/texture/checkered())

	var/obj/item/bodypart/head/head = user.get_bodypart(BODY_ZONE_HEAD)
	if(!isnull(head))
		head.head_flags &= ~HEAD_EYESPRITES
	user.update_body()
	return ..()

/obj/item/fish/holo/halffish
	name = "holographic half-fish"
	fish_id = "halffish"
	desc = "Голограмма рыбы, от которой остались только кости и голова. Она вообще должна быть мёртвой? Голо-мёртвой?"
	icon_state = "half_fish"
	dedicated_in_aquarium_icon_state = null
	aquarium_vc_color = null
	sprite_height = 4
	sprite_width = 10
	average_size = 50
	average_weight = 500
	beauty = FISH_BEAUTY_UGLY
