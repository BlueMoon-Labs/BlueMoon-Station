//pronoun procs, for getting pronouns without using the text macros that only work in certain positions
//datums don't have gender, but most of their subtypes do!
// #Склонения #Склонятор #Род
/datum/proc/ru_who(capitalized, temp_gender)
	. = "он"
	if(capitalized)
		. = capitalize(.)

/datum/proc/ru_ego(capitalized, temp_gender)
	. = "его"
	if(capitalized)
		. = capitalize(.)

/datum/proc/ru_nego(capitalized, temp_gender)
	. = "него"
	if(capitalized)
		. = capitalize(.)

/datum/proc/ru_do(temp_gender)
	. = "делает"

/datum/proc/ru_na(temp_gender)
	. = "нём"

/datum/proc/ru_emu(temp_gender)
	. = "ему"

/datum/proc/ru_a(temp_gender)
	. = ""

/datum/proc/ru_aya(temp_gender)
	. = "ый"

/datum/proc/ru_aya_iy(capitalized, temp_gender)
	. = "ий"

/datum/proc/ru_sya(temp_gender = null, include_l = FALSE)
	. = "ся"
	if(include_l)
		. = "л" + .

/datum/proc/ru_en(temp_gender = null)
	. = "ен"

/datum/proc/ru_aya_oy(temp_gender)
	. = "ой"


//like clients, which do have gender.
/client/ru_who(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "он"
	switch(temp_gender)
		if(FEMALE)
			. = "она"
		if(MALE)
			. = "он"
	if(capitalized)
		. = capitalize(.)

/client/ru_ego(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "его"
	switch(temp_gender)
		if(FEMALE)
			. = "её"
		if(MALE)
			. = "его"
	if(capitalized)
		. = capitalize(.)

/client/ru_na(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "нём"
	switch(temp_gender)
		if(FEMALE)
			. = "ней"
		if(MALE)
			. = "нём"
	if(capitalized)
		. = capitalize(.)

/client/ru_emu(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "ему"
	switch(temp_gender)
		if(FEMALE)
			. = "ей"
		if(MALE)
			. = "ему"
	if(capitalized)
		. = capitalize(.)

/client/ru_a(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = ""
	switch(temp_gender)
		if(FEMALE)
			. = "а"
		if(MALE)
			. = ""
	if(capitalized)
		. = capitalize(.)

/atom/ru_aya(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "ый"
	switch(temp_gender)
		if(FEMALE)
			. = "ая"
		if(MALE)
			. = "ый"
	if(capitalized)
		. = capitalize(.)

/atom/ru_aya_iy(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "ий"
	switch(temp_gender)
		if(FEMALE)
			. = "ая"
		if(MALE)
			. = "ий"
	if(capitalized)
		. = capitalize(.)

/atom/ru_aya_oy(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "ой"
	switch(temp_gender)
		if(FEMALE)
			. = "ая"
		if(MALE)
			. = "ой"
	if(capitalized)
		. = capitalize(.)

//mobs(and atoms but atoms don't really matter write your own proc overrides) also have gender!
/atom/ru_who(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "он"
	switch(temp_gender)
		if(FEMALE)
			. = "она"
		if(MALE)
			. = "он"
	if(capitalized)
		. = capitalize(.)

/atom/ru_ego(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "его"
	switch(temp_gender)
		if(FEMALE)
			. = "её"
		if(MALE)
			. = "его"
	if(capitalized)
		. = capitalize(.)

/atom/ru_nego(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "него"
	switch(temp_gender)
		if(FEMALE)
			. = "неё"
		if(MALE)
			. = "него"
	if(capitalized)
		. = capitalize(.)

/atom/ru_na(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "нём"
	switch(temp_gender)
		if(FEMALE)
			. = "ней"
		if(MALE)
			. = "нём"
	if(capitalized)
		. = capitalize(.)

/atom/ru_emu(capitalized, temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "ему"
	switch(temp_gender)
		if(FEMALE)
			. = "ей"
		if(MALE)
			. = "ему"
	if(capitalized)
		. = capitalize(.)

/atom/ru_a(temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = ""
	switch(temp_gender)
		if(FEMALE)
			. = "а"
		if(MALE)
			. = ""

/atom/ru_sya(temp_gender = null)
	if(!temp_gender)
		temp_gender = gender

	. = "лось"
	switch(temp_gender)
		if(FEMALE)
			. = "лась"
		if(MALE)
			. = "лся"

/atom/ru_en(temp_gender = null)
	if(!temp_gender)
		temp_gender = gender

	if(temp_gender == FEMALE)
		. = "ена"
	else
		. = "ен"

//humans need special handling, because they can have their gender hidden
/mob/living/carbon/human/ru_who(capitalized, temp_gender)
	var/list/obscured = check_obscured_slots()
	var/skipface = (wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE))
	if((ITEM_SLOT_OCLOTHING in obscured) && skipface)
		temp_gender = PLURAL
	return ..()

/mob/living/carbon/human/ru_ego(capitalized, temp_gender)
	var/list/obscured = check_obscured_slots()
	var/skipface = (wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE))
	if((ITEM_SLOT_OCLOTHING in obscured) && skipface)
		temp_gender = PLURAL
	return ..()

/mob/living/carbon/human/ru_a(capitalized, temp_gender)
	var/list/obscured = check_obscured_slots()
	var/skipface = (wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE))
	if((ITEM_SLOT_OCLOTHING in obscured) && skipface)
		temp_gender = PLURAL
	return ..()
