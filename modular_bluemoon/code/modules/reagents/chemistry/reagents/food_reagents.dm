/datum/reagent/consumable/nutriment/protein
	name = "Protein"
	description = "A natural polyamide made up of amino acids. An essential constituent of mosts known forms of life."
	nutriment_factor = 9 //45% as calorie dense as oil.
	brute_heal = 0.8 //Rewards the player for eating a balanced diet.
	// chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	color = "#305a66" // rgb: 30, 67, 66

/datum/reagent/consumable/bonito
	name = "bonito flakes"
	description = "Also known as \"Katsuobushi\", apparently!"
	color = "#fce2c7"
	taste_description = "Umami"
	taste_mult = 1.5

/datum/reagent/water/salt
	name = "Saltwater"
	description = "Water, but salty. Smells like... the station infirmary?"
	color = "#aaaaaa9d" // rgb: 170, 170, 170, 77 (alpha)
	// chemical_flags = REAGENT_CAN_BE_SYNTHESIZED | REAGENT_CLEANS
	glass_desc = "the sea"
	cooling_temperature = 3

/datum/reagent/consumable/red_bay
	name = "Red Bay Seasoning"
	description = "A secret blend of herbs and spices that goes well with anything- according to Martians, at least."
	color = "#8E4C00"
	glass_desc = "spice"
	// chemical_flags = REAGENT_CAN_BE_SYNTHESIZED // Нету такого флага

/datum/reagent/consumable/worcestershire
	name = "Worcestershire Sauce"
	description = "That's \"Woostershire\" sauce, by the way."
	nutriment_factor = 2 * REAGENTS_METABOLISM
	color = "#572b26"
	glass_desc = "sweet fish"

/datum/reagent/consumable/sugar/syrup
	name = "Syrup"
	description = "In cooking, syrup is a condiment that is a thick, viscous liquid consisting primarily of a solution of sugar in water, containing a large amount of dissolved sugars but showing little tendency to deposit crystals."
	reagent_state = SOLID
	color = "#B18867" // rgb: 255, 255, 255
	taste_description = "sweetness"
	value = REAGENT_VALUE_NONE

/datum/reagent/consumable/sugar/syrup/banana
	name = "Banana Syrup"
	description = "Banana syrup is a simple syrup with a delicious banana flavor. Like all simple syrup, it's mainly made of sugar and water, then flavored with ripe bananas."
	color = "#E6C601"
	taste_description = "sweetness and banana"

/datum/reagent/consumable/sugar/syrup/caramel
	name = "Caramel Syrup"
	description = "It is surprisingly easy to make caramel syrup from scratch, calling for just sugar, water, vanilla extract, and a pinch of salt. It adds a rich sweetness to drinks, including your morning coffee or evening cocktails."
	color = "#D7520D"
	taste_description = "sweetness and caramel"

/datum/reagent/consumable/sugar/syrup/chili
	name = "Chili Syrup"
	description = "Sweet and spicy chili simple syrup is made by soaking chili peppers in a simple syrup.  The simple syrup becomes infused with the chili peppers creating a slightly spicy, sultry, amber colored simple syrup that is truly addicting."
	color = "#CFB77B"
	taste_description = "sweetness and spiciness"

/datum/reagent/drug/aphrodisiac/syrup
	name = "Crocin Syrup"
	description = "Naturally found in the crocus and gardenia flowers, this drug acts as a natural and safe aphrodisiac. Now turned into a syrup!"
	taste_description = "sweetness and strawberries"
	color = "#FFADFF"

/datum/reagent/consumable/semen/syrup
	name = "Semen Syrup"
	description = "Sperm turned into syrup. Succubi love those!"
	taste_description = "sweetness and something salty"
	color = "#FFFFFF"

/datum/reagent/consumable/sugar/syrup/grape
	name = "Grape Syrup"
	description = "Grape syrup is a condiment made with concentrated grape juice. It is thick and sweet because of its high ratio of sugar to water. Grape syrup is made by boiling grapes, removing their skins, squeezing them through a sieve to extract the juice."
	color = "#1C2C56"
	taste_description = "sweetness and grapes"

/datum/reagent/consumable/sugar/syrup/cactus
	name = "Cactus Syrup"
	description = "Cactus Syrup expertly recreates the exciting taste of this world-famous plant. With a floral nose and flavour, this syrup makes a fantastic addition to cocktails, mocktails, sodas and more. Be adventurous and give this one a try!"
	color = "#8AC006"
	taste_description = "sweetness and cactus"

/datum/reagent/consumable/sugar/syrup/mint
	name = "Mint Syrup"
	description = "This mint simple syrup is made with fresh mint leaves, sugar, and water to create a minty fresh sweet syrup to add a refreshing lift to cocktails, mocktails, pastry glazes, and frozen desserts."
	color = "#CBB112"
	taste_description = "sweetness and mint"

/datum/reagent/consumable/sugar/syrup/orange
	name = "Orange Syrup"
	description = "This Orange Syrup tastes exactly like it sounds – sweet, silky  orange syrup – the perfect amount of citrus, the perfect amount of sugar and the perfect kiss of butter."
	color = "#F88800"
	taste_description = "sweetness and oranges"

/datum/reagent/consumable/sugar/syrup/saltcaramel
	name = "Saltcaramel Syrup"
	description = "The decadence of caramel combined with the complement of salt makes for a surprising flavor pairing. Salted Caramel adds delicious salty sweetness to specialty cocktails, hot and cold lattes, cappuccinos and coffee beverages."
	color = "#C6A750"
	taste_description = "sweetness, caramel and saltiness"

/datum/reagent/consumable/sugar/syrup/vanilla
	name = "Vanilla Syrup"
	description = "Nothing beats the original. Inspired by premium vanilla flavor, it’s clean, pure and creamy. And that spells delicious every time you add it."
	color = "#FAF2DF"
	taste_description = "sweetness and vanilla"

/datum/reagent/consumable/sugar/syrup/watermelon
	name = "Watermelon Syrup"
	description = "Succulent and sweet, watermelon is a summertime picnic favorite that is now available year round. Use our Watermelon Syrup to freshen up your sodas, slushes, teas and exotic cocktails."
	color = "#EB011C"
	taste_description = "sweetness and watermelon"

/datum/reagent/consumable/choccyshake/lactose_free
	description = "Milkshake without milk!"
	glass_icon_state = "strawberryshake_alt"

/datum/reagent/consumable/milkshake_strawberry/lactose_free
	description = "Milkshake without milk!"
	glass_icon_state = "strawberryshake_alt"

/datum/reagent/consumable/milkshake_banana/lactose_free
	description = "Milkshake without milk!"
	glass_icon_state = "bananashake_alt"

/datum/reagent/consumable/non_alcoholic_beer
	name = "Citrus Beer"
	description = "A non-alcoholic alternative to regular beer. It smells like citrus."
	color = "#664300" // rgb: 102, 67, 0
	nutriment_factor = 1 * REAGENTS_METABOLISM
	taste_description = "citrus water"
	glass_name = "glass of citrus beer"
	glass_desc = "A freezing pint of citrus beer."
	glass_icon_state = "non_alcoholic_beer"
