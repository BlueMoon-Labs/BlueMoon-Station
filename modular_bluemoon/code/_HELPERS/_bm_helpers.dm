/// Возвращает clothing, покрыващую конкретную часть тела
/// Проверяет по флагам body_parts_covered
/proc/get_bodypart_protecting_clothing_by_coverage(mob/living/carbon/human/H, obj/item/bodypart/body_part)
	if(!H || !body_part)
		return FALSE

	// Здесь важен порядок, чтобы цикл проверил сначала сьют (ЕВА, скафандры), потом остальное.
	var/list/clothes = list(
		H.wear_suit,
		H.w_uniform,
		H.head,
		H.gloves,
		H.shoes
	)

	for(var/obj/item/clothing/C in clothes)
		if(!C)
			continue

		var/list/covered_zones = body_parts_covered2organ_names(C.body_parts_covered)
		if(!covered_zones)
			continue

		var/target_zone = body_part.body_zone
		if(target_zone in covered_zones)
			return C

	return FALSE

//////////////////////////////////////////////////////////
