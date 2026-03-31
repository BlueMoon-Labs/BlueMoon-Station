/**
 * Bluespace miner high-instability meteor: always reaches the miner unless the round ends.
 * Uses ignores_path_wear so walls along the path do not consume "hits" (see /obj/effect/meteor).
 * On impact with the tracked bluespace miner: debris + tunguska-scale explosion, then qdel.
 */
/obj/effect/meteor/tunguska/bsm_cataclysm
	name = "tunguska-class bluespace meteor"
	desc = "Огромный сгусток материи на блюспейс-привязке к источнику: сносит преграды и не теряет массу о стены."
	icon_state = "dark_matter"
	hits = 999
	hitpwr = EXPLODE_DEVASTATE
	heavy = TRUE
	meteorsound = 'sound/effects/bamf.ogg'
	meteordrop = list(/obj/item/stack/ore/bluespace_crystal)
	threat = 60

/obj/effect/meteor/tunguska/bsm_cataclysm/Initialize(mapload, atom/target)
	ignores_path_wear = TRUE
	. = ..()

/obj/effect/meteor/tunguska/bsm_cataclysm/Bump(atom/A)
	if(istype(A, /obj/machinery/mineral/bluespace_miner))
		forceMove(get_turf(A))
		playsound(src, meteorsound, 100, TRUE)
		make_debris()
		meteor_effect()
		qdel(src)
		return
	return ..()
