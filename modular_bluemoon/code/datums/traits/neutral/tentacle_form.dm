// #define TRAIT_TENTACLE_FORM		"tentacle_form"

// //QUIRK

// /datum/quirk/tentacle_form
// 	name = "Проклятая форма"
// 	desc = "Или из-за запрещённых экспериментов, из-за космической аномалии, либо же с рождения, но вы получили возможность принимать форму массы извивающихся щупалец! <b>Предупреждение: Это может создать некоторые проблемы с навыком 'Оборотень' из-за того же функционала.</b>"
// 	value = 0
// 	mob_trait = TRAIT_TENTACLE_FORM
// 	gain_text = span_notice("Вы чувствуете себя... склизко.")
// 	lose_text = span_notice("Вы больше не чувствуете слизь на коже.")
// 	medical_record_text = "Субъект имеет аномальное строение тела, требуется наблюдение."

// /datum/quirk/tentacle_form/post_add()
// 	var/obj/effect/proc_holder/spell/targeted/shapeshift/tentacle_form/B = new
// 	quirk_holder.AddSpell(B)

// /datum/quirk/tentacle_form/remove()
// 	var/obj/effect/proc_holder/spell/targeted/shapeshift/tentacle_form/B = locate() in quirk_holder.mob_spell_list
// 	quirk_holder.RemoveSpell(B)

// /obj/effect/proc_holder/spell/targeted/shapeshift/tentacle_form
// 	name = "Tentacle Form"
// 	desc = "Transform in or out of your tentacle form."
// 	invocation_type = "none"
// 	charge_max = 50
// 	cooldown_min = 50
// 	action_icon = 'icons/mob/actions/actions_xeno.dmi'
// 	action_icon_state = "alien_resin"
// 	shapeshift_type = /mob/living/simple_animal/hostile/tentacles

// /obj/effect/proc_holder/spell/targeted/shapeshift/tentacle_form/Shapeshift(mob/living/caster)
// 	var/obj/shapeshift_holder/H = locate() in caster
// 	if(H)
// 		to_chat(caster, "<span class='warning'>You're already shapeshifted!</span>")
// 		return

// 	if(!ishuman(caster))
// 		to_chat(caster, "<span class='warning'>You need to be humanoid to be able to do this!</span>")
// 		return

// 	var/mob/living/carbon/human/action_owner = caster
// 	var/toggle_message = ("[caster] suddenly loses their shape, falling in on themselves! All that is left of them is a mass of writhing tentacles!")

// 	caster.visible_message(span_danger(toggle_message))

// 	caster.shake_animation(2)
// 	caster.Stun(30)

// 	playsound(caster, 'sound/effects/splat.ogg', 50, 0)

// 	sleep(30)

// 	var/has_clothes_to_rip = FALSE

// 	for(var/obj/item/I in caster)
// 		if(!istype(I, /obj/item/storage))
// 			has_clothes_to_rip = TRUE
// 			caster.dropItemToGround(I, TRUE)
// 	var/mob/living/shape = new shapeshift_type(caster.loc)
// 	H = new(shape, src, action_owner)
// 	var/mob/living/simple_animal/hostile/tentacles/tentacle = shape
// 	tentacle.AIStatus = AI_OFF //BLUEMOON ADD шейпы не двигаются и не пытаются кого-то убить если выйти
// 	tentacle.wander = FALSE //BLUEMOON ADD END
// 	tentacle.name = "suspicious tentacles"
// 	tentacle.gender = NEUTER
// 	tentacle.update_icon()

// 	if(has_clothes_to_rip)
// 		playsound(caster, 'modular_sand/sound/interactions/bang6.ogg', 50, 1)


// 	clothes_req = NONE
// 	mobs_whitelist = null
// 	mobs_blacklist = null

// /obj/effect/proc_holder/spell/targeted/shapeshift/tentacle_form/Restore(mob/living/shape)
// 	var/toggle_message = ("[shape] suddenly regains their humanoid form!")
// 	shape.visible_message(span_danger(toggle_message))
// 	..()


// /obj/effect/proc_holder/spell/targeted/shapeshift/tentacle_form/cast(list/targets, mob/user = usr)
// 	if(!(locate(/obj/shapeshift_holder) in targets[1]))
// 		if(!ishuman(user))
// 			to_chat(user, "<span class='warning'>You need to be humanoid to be able to do this!</span>")
// 			return
// 	var/mob/living/carbon/human/HUMAN = user
// 	if(!CHECK_MOBILITY(HUMAN, MOBILITY_USE))
// 		HUMAN.visible_message(span_warning("You cannot transform while restrained!"))
// 		return

// 	HUMAN.UseStaminaBuffer(50, TRUE)
// 	return ..()
