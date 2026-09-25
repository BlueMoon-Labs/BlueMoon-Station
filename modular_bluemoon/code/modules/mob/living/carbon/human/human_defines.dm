/mob/living/carbon/human
	/// Когда тело последний раз ранили или ударили по выносливости; бег и замахи не в счёт.
	var/last_hurt_at
	var/self_gulp_size = 5 // количество выпиваемого за раз при самоличном потреблении
	var/dirtyness_maker = TRUE // оставляет-ли своим хождением грязь на полу
	var/laugh_override
