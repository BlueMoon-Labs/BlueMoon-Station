/**
 *
 * МАГАЗИНЫ
 *
 */

/datum/mail_pattern/shop/plushes
	name = "Плюшевые игрушки"
	description = "Подарок от магазина плюшевых игрушек. Содержит три случайные плюшки."

	weight = MAIL_WEIGHT_DEFAULT

	envelope_type = MAIL_TYPE_PACKAGE

	sender = "Магазин плюшевых игрушек"

	letter_title = "Преданному клиенту"
	letter_html = {"Благодарим Вас за покупки в нашем магазине! В качестве признательности, в рамках нашей недавней акции,
					 мы присылаем вам несколько игрушек бесплатно! Приятного дня!"}

	initial_contents = list(
		/obj/item/toy/plush/random,
		/obj/item/toy/plush/random,
		/obj/item/toy/plush/random,
	)

/datum/mail_pattern/shop/plushes/apply(mob/living/carbon/human/recipient)
	sender = pick("Плюшевые игрушки для всей семьи(тм)", "Мягкие друзья", "Детский мир")
	. = ..()

/datum/mail_pattern/shop/bakery
	name = "Пекарня"
	description = "Подарок от пекарни. Содержит два случайных пирога."

	weight = MAIL_WEIGHT_DEFAULT

	envelope_type = MAIL_TYPE_PACKAGE

	blacklisted_species = MAIL_RECIPIENT_SYNTH

	sender = "Пекарня"

	letter_title = "Преданному клиенту"
	letter_html = {"Благодарим Вас за преданность продукции нашей пекарни! В качестве признательности, в рамках нашей недавней акции,
					 мы присылаем вам целых ДВА пирога бесплатно! Приятного дня!"}

	initial_contents = list(
		/obj/item/reagent_containers/food/snacks/pie/meatpie,
		/obj/item/reagent_containers/food/snacks/pie/applepie
	)

/datum/mail_pattern/shop/bakery/apply(mob/living/carbon/human/recipient)
	sender = pick("Пекарня 'У Боба'", "НТПродукт")
	. = ..()

/datum/mail_pattern/shop/battery
	name = "Батарейки для синтов"
	description = "Подарок от магазина батареек. Содержит две блюспейс батареи."

	weight = MAIL_WEIGHT_DEFAULT

	envelope_type = MAIL_TYPE_PACKAGE

	whitelisted_species = MAIL_RECIPIENT_SYNTH

	sender = "Аккумуляторный завод 'Энергичный'"

	letter_title = "Батарейки на все случаи жизни"
	letter_html = {"С сожалением сообщаем всем клиентам, что на одной из наших космических фабрик по производству батареек произошёл
					 сбой по питанию, и множество синтетических сотрудников пострадали от недостатка электричества. Верховный суд ПАКТа
					 обязал нас пожертвовать часть продукции на помощь с обеспечением энергией синтетическим сотрудникам ПАКТа, чтобы искупить вину."}
	initial_contents = list(
		/obj/item/stock_parts/cell/bluespace,
		/obj/item/stock_parts/cell/bluespace
	)

/datum/mail_pattern/shop/knives
	name = "Ножи"
	description = "Подарок от магазина ножей. Содержит три боевых ножа"

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	sender = "Магазин 'Всё для охотника'"

	letter_title = "Ножи на все случаи жизни"
	letter_html = {"Поздравляем! Вы попали в десятку счастливчиков, которые получат набор ножей от нашего магазина АБСОЛЮТНО БЕСПЛАТНО!
					 Закупайте оборудования для охоты только в магазине 'Всё для охотника', чтобы мы и дальше могли радовать вас такими замечательными подарками!"}
	initial_contents = list(
		/obj/item/kitchen/knife/combat,
		/obj/item/kitchen/knife/combat,
		/obj/item/kitchen/knife/combat
	)

/datum/mail_pattern/shop/maid_costume
	name = "Костюм мейдочки"
	description = "Подарок от магазина одежды. Содержит fancy maid costume."

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	sender = "Холдинг 'Работящая фелинидочка'"

	letter_title = "Подарок"
	letter_html = {"Ваше милашное личико в списке работников пакта привлекло внимание ваших менеджеров! Согласно нашим сверхточным
					 расчётам, вы идеально подходите на роль горничной! Оформляйте заявку на нашем сайте в голонете, чтобы пройти
					 бесплатную стажировку, а чтобы вы точно поверили в себя, высылаем вам вашу будущую рабочую одежду! <3"}
	initial_contents = list(
		/obj/item/storage/box/fancy_maid_kit
	)

/datum/mail_pattern/shop/maid_costume/regenerate_weight(mob/living/carbon/human/recipient)
	. = ..()
	if(.)
		if(is_species(recipient, /datum/species/human/felinid))
			. *= 2

