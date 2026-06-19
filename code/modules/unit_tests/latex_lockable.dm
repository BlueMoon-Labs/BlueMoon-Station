/// Латексный замок (/datum/component/latex_lockable): запирание латексной
/// кинк-одежды латексным ключом. Заперто -> TRAIT_NODROP, снять нельзя.
/// Запереть чужой надетый предмет можно только с согласия (VERB_CONSENT).
/datum/unit_test/latex_lockable/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	var/obj/item/key/latex/key = allocate(/obj/item/key/latex)
	var/obj/item/clothing/under/latex/suit = allocate(/obj/item/clothing/under/latex)

	TEST_ASSERT(suit.GetComponent(/datum/component/latex_lockable), "latex jumpsuit is missing the latex_lockable component")

	// Надеваем - незаперто, снимается.
	TEST_ASSERT(wearer.equip_to_slot_or_del(suit, ITEM_SLOT_ICLOTHING, TRUE), "failed to equip latex jumpsuit")
	TEST_ASSERT(!HAS_TRAIT(suit, TRAIT_NODROP), "unlocked latex item must not have TRAIT_NODROP")
	TEST_ASSERT(wearer.canUnEquip(suit), "unlocked latex item must be removable")

	// Запираем своим ключом - вешается NODROP, снять нельзя.
	suit.attackby(key, wearer)
	TEST_ASSERT(HAS_TRAIT(suit, TRAIT_NODROP), "locking a worn latex item must apply TRAIT_NODROP")
	TEST_ASSERT(!wearer.canUnEquip(suit), "locked latex item must not be removable")

	// Отпираем - NODROP снят, снимается.
	suit.attackby(key, wearer)
	TEST_ASSERT(!HAS_TRAIT(suit, TRAIT_NODROP), "unlocking must remove TRAIT_NODROP")
	TEST_ASSERT(wearer.canUnEquip(suit), "unlocked latex item must be removable again")

	// Состояние замка переживает снятие: заперт -> уронили (NODROP ушёл) -> надели (NODROP вернулся).
	suit.attackby(key, wearer)
	TEST_ASSERT(HAS_TRAIT(suit, TRAIT_NODROP), "re-locking should set NODROP")
	wearer.dropItemToGround(suit, TRUE)
	TEST_ASSERT(!HAS_TRAIT(suit, TRAIT_NODROP), "a dropped latex item must lose NODROP")
	TEST_ASSERT(wearer.equip_to_slot_or_del(suit, ITEM_SLOT_ICLOTHING, TRUE), "failed to re-equip latex jumpsuit")
	TEST_ASSERT(HAS_TRAIT(suit, TRAIT_NODROP), "re-equipping a still-locked latex item must restore NODROP")

	// Чистим состояние для проверки согласия.
	suit.attackby(key, wearer)
	TEST_ASSERT(!HAS_TRAIT(suit, TRAIT_NODROP), "cleanup unlock failed")

	// Согласие: другой игрок не может запереть наш надетый латекс без VERB_CONSENT.
	// У allocate()'нутых мобов нет client -> нет согласия -> запирание отклоняется.
	suit.attackby(key, other)
	TEST_ASSERT(!HAS_TRAIT(suit, TRAIT_NODROP), "locking another's worn latex without consent must be refused")

/// Каждый кинк-латексный предмет должен получить компонент латексного замка.
/// Ловит опечатки и пропущенные AddComponent при добавлении новых вещей.
/datum/unit_test/latex_lockable_coverage/Run()
	var/static/list/latex_types = list(
		/obj/item/clothing/under/misc/latex_catsuit,
		/obj/item/clothing/gloves/latex_gloves,
		/obj/item/clothing/shoes/latexheels,
		/obj/item/clothing/shoes/latex_socks,
		/obj/item/clothing/head/helmet/space/deprivation_helmet,
		/obj/item/clothing/neck/mind_collar,
		/obj/item/clothing/mask/muzzle,
		/obj/item/clothing/mask/muzzle/ballgag,
		/obj/item/clothing/gloves/latexsleeves,
		/obj/item/clothing/gloves/latexsleeves/security,
		/obj/item/clothing/under/latex,
		/obj/item/clothing/under/latex/half,
		/obj/item/clothing/under/latex_bodysuit,
	)
	for(var/item_type in latex_types)
		var/obj/item/item = allocate(item_type)
		TEST_ASSERT(item.GetComponent(/datum/component/latex_lockable), "[item_type] is missing the latex_lockable component")
