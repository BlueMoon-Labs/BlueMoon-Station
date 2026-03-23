#define TRAIT_BEASTSPIRIT		"BeastSpirit"

//MOB

/mob/living/simple_animal/hostile/beastspirit
	name = "beast spirit"
	desc = "Feral, probably abnormal, animal."
	icon = 'modular_bluemoon/icons/mob/beast_spirit.dmi'
	icon_state = "male"
	icon_living = "male"
	icon_dead = "male-dead"
	gender = MALE
	mob_biotypes = MOB_BEAST
	stat_attack = UNCONSCIOUS
	speak_emote = list("growls", "roars")
	emote_hear = list("grumbles.","grawls.")
	emote_taunt = list("stares ferociously", "stomps")
	speak_chance = 0
	taunt_chance = 25
	speed = 0
	see_in_dark = 8
	attack_verb_continuous = "claws"
	maxHealth = 200
	health = 200
	obj_damage = 20
	armour_penetration = 0
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_sound = 'sound/weapons/bladeslice.ogg'
	faction = list("spirit")
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 10
	gold_core_spawnable = NO_SPAWN
	has_butt = TRUE
	pixel_w = -8
	var/based_icon = "male"
	var/pose = FALSE
	var/horny = FALSE
	var/eyecolor
	var/beast_type = ""

/mob/living/simple_animal/hostile/beastspirit/ComponentInitialize()
	. = ..()

	//AddElement(/datum/element/flavor_text, _name = "OOC Notes", _addendum = "Put information on ERP/vore/lewd-related preferences here. THIS SHOULD NOT CONTAIN REGULAR FLAVORTEXT!!", _save_key = "ooc_notes", _examine_no_preview = TRUE)

/mob/living/simple_animal/hostile/beastspirit/Initialize()
	. = ..()
	add_movespeed_modifier(/datum/movespeed_modifier/beastspirit_main)

/mob/living/simple_animal/hostile/beastspirit/update_icon()
	. = ..()
	icon_living = "[beast_type][horny ? "h_" : ""][based_icon][pose ? "-crouch" : ""]"
	icon_dead = "[beast_type][based_icon]-dead"
	if(stat != DEAD)
		icon_state = icon_living
	else
		icon_state = icon_dead

/datum/action/innate/beastchange
	name = "Change Appearance"
	desc = "Change your feral appearance."
	icon_icon = 'modular_bluemoon/icons/mob/actions/traits_actions.dmi'
	button_icon_state = "change"
	var/beastskin = ""
	var/beastsound = 'modular_bluemoon/sound/creatures/wolf.ogg'

/datum/action/innate/beastchange/Activate()
	. = ..()
	var/appearances = list("Default", "Black", "White", "Skull", "Aiko", "Werecat", "Panther", "Garfield", "Mouse")
	var/skin = input(owner, "Pick appearance for your beast", "Change Appearance") as null|anything in appearances
	switch(skin)
		if("Default")
			beastskin = ""
			beastsound = 'modular_bluemoon/sound/creatures/wolf.ogg'
		if("Black")
			beastskin = "black_"
			beastsound = 'modular_bluemoon/sound/creatures/wolf.ogg'
		if("White")
			beastskin = "white_"
			beastsound = 'modular_bluemoon/sound/creatures/wolf.ogg'
		if("Skull")
			beastskin = "skull_"
			beastsound = 'modular_bluemoon/sound/creatures/wolf.ogg'
		if("Aiko")
			beastskin = "aiko_"
			beastsound = 'modular_bluemoon/sound/creatures/wolf.ogg'
		if("Werecat")
			beastskin = "werecat_"
			beastsound = 'modular_bluemoon/sound/creatures/cat.ogg'
		if("Panther")
			beastskin = "panther_"
			beastsound = 'modular_bluemoon/sound/creatures/cat.ogg'
		if("Garfield")
			beastskin = "garfield_"
			beastsound = 'modular_bluemoon/sound/creatures/cat.ogg'
		if("Mouse")
			beastskin = "mouse_"
			beastsound = 'sound/effects/mousesqueek.ogg'
	if(skin)
		to_chat(owner, "<span class='notice'>Your inner Beast's skin now will be [skin].</span>")

/datum/action/innate/beastsex
	name = "Toggle Aroused"
	desc = "Switch between horny and not horny."
	icon_icon = 'modular_bluemoon/icons/mob/actions/traits_actions.dmi'
	button_icon_state = "sex"

/datum/action/innate/beastsex/Activate()
	. = ..()
	var/mob/living/simple_animal/hostile/beastspirit/B = owner
	B.horny = !B.horny
	B.update_icon()

/datum/movespeed_modifier/beastspirit
	multiplicative_slowdown = -0.5
	priority = 500
	complex_calculation = TRUE
	absolute_max_tiles_per_second = 7

/datum/movespeed_modifier/beastspirit_main
	multiplicative_slowdown = 0.5
	priority = 500
	complex_calculation = TRUE
	absolute_max_tiles_per_second = 7

/datum/action/innate/beastpose
	name = "Toggle Pose"
	desc = "Switch between poses."
	icon_icon = 'modular_bluemoon/icons/mob/actions/traits_actions.dmi'
	button_icon_state = "pose"

/datum/action/innate/beastpose/Activate()
	. = ..()
	var/mob/living/simple_animal/hostile/beastspirit/B = owner
	B.pose = !B.pose
	if(B.pose)
		B.add_movespeed_modifier(/datum/movespeed_modifier/beastspirit)
	else
		B.remove_movespeed_modifier(/datum/movespeed_modifier/beastspirit)
	B.update_icon()

/mob/living/simple_animal/hostile/beastspirit/Initialize()
	. = ..()
	var/datum/action/innate/beastsex/sex = new
	var/datum/action/innate/beastpose/pose = new
	pose.Grant(src)
	pose.owner = src
	sex.Grant(src)
	sex.owner = src

//QUIRK

/datum/quirk/beastspirit
	name = "Звериный Дух"
	desc = "Ваша душа теперь находится под контролем вашего звериного покровителя. Не позволяйте гневу высвободить вашего внутреннего зверя. <b>Предупреждение: Это может создать некоторые проблемы с навыком 'Оборотень' из-за того же функционала.</b>"
	value = 2
	mob_trait = TRAIT_BEASTSPIRIT
	gain_text = span_notice("Вы приняли своего внутреннего зверя..")
	lose_text = span_notice("Вы больше не чувствуете внутреннего зверя.")
	medical_record_text = "У субъекта наблюдалась сильная психологическая нестабильность, которая включает в себя животное поведение и резкое увеличение в габаритах от психоактивности."

/datum/quirk/beastspirit/post_add()
	var/obj/effect/proc_holder/spell/targeted/shapeshift/beast/B = new
	quirk_holder.AddSpell(B)
	var/datum/action/innate/beastchange/change = new
	change.Grant(quirk_holder)
	change.owner = quirk_holder

/datum/quirk/beastspirit/remove()
	if(!quirk_holder)
		return
	var/obj/effect/proc_holder/spell/targeted/shapeshift/beast/B = locate() in quirk_holder.mob_spell_list
	quirk_holder.RemoveSpell(B)

/obj/effect/proc_holder/spell/targeted/shapeshift/beast
	name = "Beast Form"
	desc = "Transform in or out of your feral form."
	invocation_type = "none"
	charge_max = 50
	cooldown_min = 50
	action_icon = 'modular_bluemoon/icons/mob/actions/traits_actions.dmi'
	action_icon_state = "beast"
	shapeshift_type = /mob/living/simple_animal/hostile/beastspirit
	die_with_shapeshifted_form = FALSE
	var/beast_gender = "male"
	var/beast_type = ""
	var/beast_sound = 'modular_bluemoon/sound/creatures/wolf.ogg'

/obj/effect/proc_holder/spell/targeted/shapeshift/beast/Shapeshift(mob/living/caster)
	var/obj/shapeshift_holder/H = locate() in caster
	if(H)
		to_chat(caster, "<span class='warning'>You're already shapeshifted!</span>")
		return

	if(!ishuman(caster))
		to_chat(caster, "<span class='warning'>You need to be humanoid to be able to do this!</span>")
		return

	var/mob/living/carbon/human/action_owner = caster

	var/datum/action/innate/beastchange/B = locate() in caster.actions
	if(B)
		beast_type = B.beastskin
		beast_sound = B.beastsound

	var/obj/item/organ/genital/penis/organ_penis = action_owner.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/organ/genital/breasts/organ_breasts = action_owner.getorganslot(ORGAN_SLOT_BREASTS)
	var/obj/item/organ/genital/vagina/organ_vagina = action_owner.getorganslot(ORGAN_SLOT_VAGINA)
	if(organ_penis)
		beast_gender = "male"
		if(organ_breasts)
			beast_gender = "futa"
	else if(organ_vagina)
		beast_gender = "female"

	var/toggle_message = ("[caster] shivers with flesh bursting a sudden growth of thick mass as features contort to that of a beast, fully transforming [caster.ru_na()] into an animal!")

	caster.visible_message(span_danger(toggle_message))

	caster.shake_animation(2)
	caster.Stun(30)

	playsound(caster, beast_sound, 50, 0)

	sleep(30)

	var/has_clothes_to_rip = FALSE

	for(var/obj/item/I in caster)
		if(!istype(I, /obj/item/storage))
			has_clothes_to_rip = TRUE
			caster.dropItemToGround(I, TRUE)
	var/mob/living/shape = new shapeshift_type(caster.loc)
	H = new(shape, src, action_owner)
	var/mob/living/simple_animal/hostile/beastspirit/BEAST = shape
	BEAST.AIStatus = AI_OFF //BLUEMOON ADD шейпы не двигаются и не пытаются кого-то убить если выйти
	BEAST.wander = FALSE //BLUEMOON ADD END
	BEAST.name = action_owner.name
	BEAST.beast_type = beast_type
	BEAST.gender = action_owner.gender
	BEAST.based_icon = beast_gender
	BEAST.eyecolor = "#[action_owner.left_eye_color]"
	BEAST.update_icon()
	var/icon/M = new(BEAST.icon)
	M.SwapColor("#ffffff",BEAST.eyecolor)
	BEAST.icon = M

	if(has_clothes_to_rip)
		playsound(caster, 'modular_bluemoon/sound/effects/transform.ogg', 50, 1)

	switch(beast_gender)
		if("male")
			BEAST.has_penis = TRUE
		if("female")
			BEAST.has_breasts = TRUE
			BEAST.has_vagina = TRUE
		if("futa")
			if(organ_vagina)
				BEAST.has_vagina = TRUE
			BEAST.has_breasts = TRUE
			BEAST.has_penis = TRUE


	clothes_req = NONE
	mobs_whitelist = null
	mobs_blacklist = null

/obj/effect/proc_holder/spell/targeted/shapeshift/beast/Restore(mob/living/shape)
	var/toggle_message = ("[shape] shrinks with feral features quickly receding.")
	shape.visible_message(span_danger(toggle_message))
	..()


/obj/effect/proc_holder/spell/targeted/shapeshift/beast/cast(list/targets, mob/user = usr)
	if(!(locate(/obj/shapeshift_holder) in targets[1]))
		if(!ishuman(user))
			to_chat(user, "<span class='warning'>You need to be humanoid to be able to do this!</span>")
			return
	var/mob/living/carbon/human/HUMAN = user
	if(!CHECK_MOBILITY(HUMAN, MOBILITY_USE))
		HUMAN.visible_message(span_warning("You cannot transform while restrained!"))
		return

	HUMAN.UseStaminaBuffer(50, TRUE)
	return ..()
