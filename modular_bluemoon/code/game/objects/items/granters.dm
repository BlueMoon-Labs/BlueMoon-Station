/obj/item/book/granter/spell/smoke/crocin
	spell = /obj/effect/proc_holder/spell/targeted/smoke
	spellname = "crocin smoke"
	icon_state ="booksmoke"
	desc = "This book is overflowing with the lewd arts."
	remarks = list("Crocin Bomb! Heh...", "Crocin bomb would do just fine too...", "Wait, there's a machine that does the same thing in chemistry?", "This book smells awful...", "Why all these horny jokes? Just tell me how to cast it...", "Wind will ruin the whole spell, good thing we're in space... Right?", "So this is how the kinkmate does it...")
	spell = /obj/effect/proc_holder/spell/targeted/smoke/lesser

/obj/item/book/granter/spell/smoke/crocin/onlearned(mob/user)
	if(oneuse)
		used = TRUE

/obj/effect/proc_holder/spell/targeted/smoke/lesser //Chaplain smoke book
	name = "Crocin Smoke"
	desc = "This ability spawns a small cloud of crocin smoke at your location."
	action_icon_state = "crocin_smoke"
	charge_max = 36 SECONDS
	smoke_type = /datum/effect_system/smoke_spread/aphrodisiac
	smoke_amt = 1
