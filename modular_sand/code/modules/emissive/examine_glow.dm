/mob/proc/has_active_emissive()
	return FALSE

/mob/living/carbon/human/has_active_emissive()
	return emissives_allowed(dna) && length(dna?.features?["emissive_parts"])

/mob/living/carbon/human/proc/has_emissive_bodypart(part)
	return has_emissive_part(dna?.features, part)

/// Deregulated examine verb: lets a player examine a glow-enabled (emissive) character in total
/// darkness, even beyond normal `see_in_dark` / `view()` range. Unlike the base /mob/verb/examinate
/// it has NO `in view(client.view, src)` engine clause, which is what blocks examining emissive
/// characters we can only see by their glow. Normal (non-glow) dark tiles/atoms are NOT affected:
/// this verb refuses to run on anything that isn't a glowing mob, so default dark unclickability stays.
/mob/verb/examinate_glowing(atom/A as mob)
	set name = "Осмотреть светящегося"
	set category = "IC"
	set hidden = TRUE

	if(!ismob(A))
		return
	var/mob/target = A
	if(!target.has_active_emissive())
		return
	if(get_dist(src, target) > EXAMINE_GLOW_MAX_RANGE)
		to_chat(src, "<span class='warning'>Слишком далеко, чтобы рассмотреть этого персонажа.</span>")
		return
	DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(run_examinate), A))
