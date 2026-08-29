

/obj/item/stack/sticky_tape
	name = "sticky tape"
	singular_name = "sticky tape"
	desc = "Used for sticking to things for sticking said things to people."
	icon = 'icons/obj/tapes.dmi'
	icon_state = "tape_w"
	var/prefix = "sticky"
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	item_flags = NOBLUDGEON
	amount = 5
	max_amount = 5
	resistance_flags = FLAMMABLE
	splint_factor = 0.8
	grind_results = list(/datum/reagent/cellulose = 5)

	var/list/conferred_embed = EMBED_HARMLESS
	var/overwrite_existing = FALSE

	var/endless = FALSE
	var/apply_time = 30
	absorption_capacity = 3
	absorption_rate = 0.2
	var/gauze_prefix = "gauze"
	var/splint_prefix = "gauze"
	var/can_splint = FALSE

/obj/item/stack/sticky_tape/afterattack(obj/item/I, mob/living/user)
	if(isliving(I))
		try_bandage(I, user)
		return
	if(!istype(I))
		return

	if(I.embedding && I.embedding == conferred_embed)
		to_chat(user, "<span class='warning'>[I] is already coated in [src]!</span>")
		return

	user.visible_message("<span class='notice'>[user] begins wrapping [I] with [src].</span>", "<span class='notice'>You begin wrapping [I] with [src].</span>")

	if(do_after(user, apply_time, target=I))
		I.embedding = conferred_embed
		I.updateEmbedding()
		to_chat(user, "<span class='notice'>You finish wrapping [I] with [src].</span>")
		if(!endless)
			use(1)
		I.name = "[prefix] [I.name]"

		if(istype(I, /obj/item/grenade))
			var/obj/item/grenade/sticky_bomb = I
			sticky_bomb.sticky = TRUE

/obj/item/stack/sticky_tape/infinite //endless tape that applies far faster, for maximum honks
	name = "endless sticky tape"
	desc = "This roll of sticky tape somehow has no end."
	endless = TRUE
	apply_time = 10

/obj/item/stack/sticky_tape/super
	name = "super sticky tape"
	singular_name = "super sticky tape"
	desc = "Quite possibly the most mischevious substance in the galaxy. Use with extreme lack of caution."
	icon_state = "tape_y"
	prefix = "super sticky"
	conferred_embed = EMBED_HARMLESS_SUPERIOR
	splint_factor = 0.6

/obj/item/stack/sticky_tape/pointy
	name = "pointy tape"
	singular_name = "pointy tape"
	desc = "Used for sticking to things for sticking said things inside people."
	icon_state = "tape_evil"
	prefix = "pointy"
	conferred_embed = EMBED_POINTY

/obj/item/stack/sticky_tape/pointy/super
	name = "super pointy tape"
	singular_name = "super pointy tape"
	desc = "You didn't know tape could look so sinister. Welcome to Space Station 13."
	icon_state = "tape_spikes"
	prefix = "super pointy"
	conferred_embed = EMBED_POINTY_SUPERIOR

/obj/item/stack/sticky_tape/surgical
	name = "surgical tape"
	singular_name = "surgical tape"
	desc = "Made for patching broken bones back together alongside bone gel, not for playing pranks."
	icon_state = "tape_spikes"
	prefix = "surgical"
	conferred_embed = list("embed_chance" = 30, "pain_mult" = 0, "jostle_pain_mult" = 0, "ignore_throwspeed_threshold" = TRUE)
	splint_factor = 0.4
	custom_price = 500

/obj/item/stack/sticky_tape/black
	name = "black sticky tape"
	singular_name = "black sticky tape"
	prefix = "black"
	desc = "Идеальна для закрытия протечек."
	icon_state = "tape_b"

GLOBAL_LIST_INIT(tape_recipes, list ( \
	new/datum/stack_recipe("Black Sticky Tape Top", /obj/item/clothing/underwear/shirt/top/black_tape, 1), \
	new/datum/stack_recipe("Black Sticky Tape Groin", /obj/item/clothing/underwear/briefs/black_tape, 1), \
	))

/obj/item/stack/sticky_tape/black/get_main_recipes()
	. = ..()
	. += GLOB.tape_recipes

/* BLUEMOON EDIT - CODE OVERRIDDEN IN 'modular_bluemoon\code\modules\vending\kinkmate.dm'
/obj/machinery/vending/kink/Initialize(mapload)
	products += list(/obj/item/stack/sticky_tape/black = 4)
	. = ..()
*/

/obj/item/stack/sticky_tape/proc/get_overlay_prefix(obj/item/bodypart/gauzed_bodypart)
	var/prefix = is_splinting(gauzed_bodypart) ? splint_prefix : gauze_prefix
	return "[prefix]_[gauzed_bodypart.body_zone]"

/obj/item/stack/sticky_tape/proc/is_splinting(obj/item/bodypart/gauzed_bodypart)
	if(!can_splint)
		return FALSE
	for(var/datum/wound/iterated_wound as anything in gauzed_bodypart.wounds)
		if(iterated_wound.wound_flags & BONE_WOUND)
			return TRUE
	return FALSE

// BLUEMOON ADD - скотч как бинт/герметик: заклейка протечек, в т.ч. у синтетиков
/obj/item/stack/sticky_tape/proc/try_bandage(mob/living/M, mob/living/user)
	var/obj/item/bodypart/limb = M.get_bodypart(check_zone(user.zone_selected))
	if(!limb)
		to_chat(user, "<span class='notice'>Нечего заклеивать!</span>")
		return
	var/has_wound = FALSE
	for(var/datum/wound/W as anything in limb.wounds)
		if(W.wound_flags & ACCEPTS_GAUZE)
			has_wound = TRUE
			break
	if(!has_wound && !limb.get_bleed_rate() && !limb.generic_bleedstacks && !limb.is_robotic_limb())
		to_chat(user, "<span class='notice'>На [limb.ru_name_v] нет ран, требующих заклейки!</span>")
		return
	if(limb.current_gauze)
		to_chat(user, "<span class='warning'>[limb.ru_name_v] уже перевязано или заклеено!</span>")
		return
	var/treatment_delay = (user == M ? apply_time : round(apply_time * 0.5))
	user.visible_message("<span class='warning'>[user] начинает заклеивать рану на [limb.ru_name_v] персонажа [M] скотчем...</span>", "<span class='warning'>Вы начинаете заклеивать раны на [user == M ? "своей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [M]"] скотчем...</span>")
	if(!do_after(user, treatment_delay, target = M))
		return
	user.visible_message("<span class='green'>[user] заклеивает раны на [limb.ru_name_v] персонажа [M] скотчем</span>", "<span class='green'>Вы заклеили раны на [user == M ? "своей конечности" : "конечности персонажа [M]"] скотчем.</span>")
	limb.apply_gauze(src)
	limb.generic_bleedstacks = 0
	limb.update_part_wound_overlay()
	limb.update_wounds(TRUE)
	if(limb.get_bleed_rate())
		user.add_mob_blood(M)
