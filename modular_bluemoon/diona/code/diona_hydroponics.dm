/obj/item/seeds/nymph
	name = "pack of diona nymph seeds"
	desc = "Из этих семян вырастают дионы-нимфы."
	icon_state = "seed-replicapod"
	species = "replicapod"
	plantname = "Nymph Pod"
	product = /obj/item/reagent_containers/food/snacks/grown/nymph_pod
	lifespan = 50
	endurance = 8
	maturation = 10
	production = 1
	yield = 1
	reagents_add = list(/datum/reagent/consumable/nutriment = 0.1)

/obj/item/reagent_containers/food/snacks/grown/nymph_pod
	seed = /obj/item/seeds/nymph
	name = "nymph pod"
	desc = "Странный шевелящийся стручок, внутри которого выросла нимфа. Расколи его, чтобы выпустить нимфу."
	icon_state = "mushy"
	bitesize_mod = 2
	foodtype = VEGETABLES
	tastes = list("кора" = 1, "сок" = 1)

/obj/item/reagent_containers/food/snacks/grown/nymph_pod/attack_self(mob/user)
	if(user.incapacitated())
		return
	new /mob/living/simple_animal/diona_nymph(get_turf(user))
	to_chat(user, span_notice("Ты вскрываешь [src], выпуская нимфу на волю."))
	user.temporarilyRemoveItemFromInventory(src)
	qdel(src)
