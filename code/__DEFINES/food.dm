#define MEAT 		(1<<0)
#define VEGETABLES 	(1<<1)
#define RAW 		(1<<2)
#define JUNKFOOD 	(1<<3)
#define GRAIN 		(1<<4)
#define FRUIT 		(1<<5)
#define DAIRY 		(1<<6)
#define FRIED 		(1<<7)
#define ALCOHOL 	(1<<8)
#define SUGAR 		(1<<9)
#define GROSS 		(1<<10)
#define TOXIC 		(1<<11)
#define PINEAPPLE	(1<<12)
#define BREAKFAST	(1<<13)
#define ANTITOXIC 	(1<<14)
#define SEAFOOD 	(1<<15) //BLUEMOON ADD
#define NUTS 		(1<<16) //BLUEMOON ADD
#define SAUCE 		(1<<17) //BLUEMOON ADD

#define DRINK_NICE	1
#define DRINK_GOOD	2
#define DRINK_VERYGOOD	3
#define DRINK_FANTASTIC	4
#define FOOD_AMAZING 5
#define RACE_DRINK 6

#define FOOD_IN_CONTAINER (1<<0)

#define STOP_SERVING_BREAKFAST (15 MINUTES)

///Venue reagent requirement
#define VENUE_BAR_MINIMUM_REAGENTS 10

#define IS_EDIBLE(O) (O.GetComponent(/datum/component/edible) || istype(O, /obj/item/reagent_containers/food/snacks))

///Food trash flags
#define FOOD_TRASH_POPABLE (1<<0)
#define FOOD_TRASH_OPENABLE (1<<1)

///Amount of reagents you start with on crafted food excluding the used parts
#define CRAFTED_FOOD_BASE_REAGENT_MODIFIER 0.7
///Modifier of reagents you get when crafting food from the parts used
#define CRAFTED_FOOD_INGREDIENT_REAGENT_MODIFIER 0.5

#define BLACKBOX_LOG_FOOD_MADE(food) SSblackbox.record_feedback("tally", "food_made", 1, food)

