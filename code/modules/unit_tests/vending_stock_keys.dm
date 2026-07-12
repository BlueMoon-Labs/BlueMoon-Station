// Regression test: ui_data() stock must key records uniquely. Product names are not unique
// (translated items and duplicates across products/contraband share display names), so a
// name-keyed stock map let one record overwrite another's amount - the count in the UI froze
// on the shadowing record's value until the real one said "sold out".

/datum/unit_test/vending_stock_keys/Run()
	var/obj/machinery/vending/machine = allocate(/obj/machinery/vending/assist)
	var/mob/user = allocate(/mob)

	// Two different products that share one display name, plus a contraband twin.
	var/datum/data/vending_product/first = new
	first.name = "тестовый товар"
	first.product_path = /obj/item/pen
	first.amount = 5

	var/datum/data/vending_product/second = new
	second.name = "тестовый товар"
	second.product_path = /obj/item/pen/red
	second.amount = 3

	var/datum/data/vending_product/hidden = new
	hidden.name = "тестовый товар"
	hidden.product_path = /obj/item/pen/blue
	hidden.amount = 7

	machine.product_records = list(first, second)
	machine.coin_records = list()
	machine.hidden_records = list(hidden)

	var/list/data = machine.ui_data(user)
	var/list/stock = data["stock"]
	TEST_ASSERT_EQUAL(length(stock), 3, "every record must get its own stock entry even with duplicate names")

	// Each record must be resolvable by the same key the client reads from static data (REF).
	var/list/expected = list(first, second, hidden)
	for(var/datum/data/vending_product/record as anything in expected)
		var/list/entry = stock[REF(record)]
		TEST_ASSERT_NOTNULL(entry, "stock entry for [record.product_path] must be keyed by its REF")
		TEST_ASSERT_EQUAL(entry["amount"], record.amount, "stock amount for [record.product_path] must come from its own record")

	// A purchase must be visible through the same key immediately.
	second.amount--
	data = machine.ui_data(user)
	stock = data["stock"]
	var/list/entry = stock[REF(second)]
	TEST_ASSERT_EQUAL(entry["amount"], 2, "a decremented record must report its new amount under its own key")
