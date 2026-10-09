/// Одинаковые пачки в обоих карманах аутфита сливаются в одну, и в слоте кармана не остаётся удалённой пачки.
/datum/unit_test/outfit_same_stacks_in_pockets/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/datum/outfit/cash = new
	cash.uniform = /obj/item/clothing/under/color/grey
	cash.l_pocket = /obj/item/stack/spacecash/c1000
	cash.r_pocket = /obj/item/stack/spacecash/c1000
	wearer.equipOutfit(cash)

	var/bills = 0
	for(var/obj/item/stack/spacecash/stack in list(wearer.l_store, wearer.r_store))
		TEST_ASSERT(!QDELETED(stack), "В кармане осталась удалённая пачка денег")
		bills += stack.amount
	TEST_ASSERT_EQUAL(bills, 2, "Пачки из двух карманов не сложились в одну")
