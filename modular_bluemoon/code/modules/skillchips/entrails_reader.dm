// TRAIT_ENTRAILS_READER (skillchip "Coroner's Reading") lets you inspect what kind of person a liver came from.
/obj/item/organ/liver/examine(mob/user)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_ENTRAILS_READER) && !isobserver(user))
		return
	var/mob/living/carbon/liver_owner = owner
	if(!liver_owner)
		. += span_info("Орган явно покинул своего владельца, но по состоянию тканей можно многое сказать о его прошлом.")
		return
	if(HAS_TRAIT(liver_owner, TRAIT_LAW_ENFORCEMENT_METABOLISM))
		. += span_info("Жировые отложения и следы сахарной пудры говорят о том, что это печень сотрудника <em>службы безопасности</em>.")
	if(HAS_TRAIT(liver_owner, TRAIT_CULINARY_METABOLISM))
		. += span_info("Высокое содержание железа и лёгкий запах чеснока говорят о том, что это печень <em>повара</em>.")
	if(HAS_TRAIT(liver_owner, TRAIT_COMEDY_METABOLISM))
		. += span_info("Запах бананов, скользкая плёнка и [span_clown("гудок")] при надавливании — это печень <em>клоуна</em>.")
	if(HAS_TRAIT(liver_owner, TRAIT_MEDICAL_METABOLISM))
		. += span_info("Следы стресса и слабый запах медицинского спирта говорят о том, что это печень <em>судмедэксперта</em>.")
	if(HAS_TRAIT(liver_owner, TRAIT_ENGINEER_METABOLISM))
		. += span_info("Признаки радиационного облучения и адаптации к космосу говорят о том, что это печень <em>инженера</em>.")