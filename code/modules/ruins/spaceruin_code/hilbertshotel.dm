//Space Ruin stuff
/area/ruin/space/has_grav/hilbertresearchfacility
	name = "Hilbert Research Facility"

/obj/item/analyzer/hilbertsanalyzer
	name = "custom rigged analyzer"
	desc = "A hand-held environmental scanner which reports current gas levels. This one seems custom rigged to additionally be able to analyze some sort of bluespace device."
	icon_state = "hilbertsanalyzer"

/obj/item/analyzer/hilbertsanalyzer/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(istype(target, /obj/item/hilbertshotel))
		if(!proximity)
			to_chat(user, "<span class='warning'>It's to far away to scan!</span>")
			return
		var/obj/item/hilbertshotel/sphere = target
		if(sphere.activeRooms.len)
			to_chat(user, "Currently Occupied Rooms:")
			for(var/roomnumber in sphere.activeRooms)
				to_chat(user, roomnumber)
		else
			to_chat(user, "No currenty occupied rooms.")
		if(sphere.storedRooms.len)
			to_chat(user, "Vacated Rooms:")
			for(var/roomnumber in sphere.storedRooms)
				to_chat(user, roomnumber)
		else
			to_chat(user, "No vacated rooms.")

/obj/effect/mob_spawn/human/doctorhilbert
	name = "Doctor Hilbert"
	mob_name = "Doctor Hilbert"
	mob_gender = "male"
	assignedrole = null
	ghost_usable = FALSE
	oxy_damage = 500
	mob_species = /datum/species/skeleton
	id_job = "Head Researcher"
	id_access = ACCESS_RESEARCH
	id_access_list = list(ACCESS_AWAY_GENERIC3, ACCESS_RESEARCH)
	instant = TRUE
	id = /obj/item/card/id/silver
	uniform = /obj/item/clothing/under/rank/rnd/research_director
	shoes = /obj/item/clothing/shoes/sneakers/brown
	back = /obj/item/storage/backpack/satchel/leather
	suit = /obj/item/clothing/suit/toggle/labcoat

/obj/item/hilbertshotel/researchfacility
	ruinSpawned = TRUE

/obj/item/hilbertshotel/Initialize(mapload)
	. = ..()
	SShilbertshotel.lore_room_spawned = TRUE

/obj/item/paper/crumpled/docslogs
	name = "Research Logs"

/obj/item/paper/crumpled/docslogs/Initialize(mapload)
	. = ..()
	if(!SShilbertshotel.hhMysteryroom_number)
		SShilbertshotel.hhMysteryroom_number = rand(1, SHORT_REAL_LIMIT)
	default_raw_text = {"
###  Research Logs
I might just be onto something here!
The strange space-warping properties of bluespace have been known about for awhile now, but I might be on the verge of discovering a new way of harnessing it.
It's too soon to say for sure, but this might be the start of something quite important!
I'll be sure to log any major future breakthroughs. This might be a lot more than I can manage on my own, perhaps I should hire that secretary after all...
###  Breakthrough!
I can't believe it, but I did it! Just when I was certain it couldn't be done, I made the final necessary breakthrough.
Exploiting the effects of space dilation caused by specific bluespace structures combined with a precise use of geometric calculus, I've discovered a way to correlate an infinite amount of space within a finite area!
While the potential applications are endless, I utilized it in quite a nifty way so far by designing a system that recursively constructs subspace rooms and spatially links them to any of the infinite infinitesimally distinct points on the spheres surface.
I call it: Hilbert's Hotel!
<h4>Goodbye</h4>
I can't take this anymore. I know what happens next, and the fear of what is coming leaves me unable to continue working.
Any fool in my field has heard the stories. It's not that I didn't believe them, it's just... I guess I underestimated the importance of my own research...
Robert has reported a further increase in frequency of the strange, prying visitors who ask questions they have no business asking. I've requested him to keep everything on strict lockdown and have permanently dismissed all other assistants.
I've also instructed him to use the encryption method we discussed for any important quantitative data. The poor lad... I don't think he truly understands what he's gotten himself into...
It's clear what happens now. One day they'll show up uninvited, and claim my research as their own, leaving me as nothing more than a bullet ridden corpse floating in space.
I can't stick around to the let that happen.
I'm escaping into the very thing that brought all this trouble to my doorstep in the first place - my hotel.
I'll be in <u>[uppertext(num2hex(SShilbertshotel.hhMysteryroom_number, 0))]</u> (That will make sense to anyone who should know)
I'm sorry that I must go like this. Maybe one day things will be different and it will be safe to return... maybe...
Goodbye
     _Doctor Hilbert_"}

/obj/item/paper/crumpled/robertsworkjournal
	name = "Work Journal"
	default_raw_text = {"<h4>First Week!</h4>
	First week on the new job. It's a secretarial position, but hey, whatever pays the bills. Plus it seems like some interesting stuff goes on here.<br>
	Doc says its best that I don't openly talk about his research with others, I guess he doesn't want it getting out or something. I've caught myself slipping a few times when talking to others, it's hard not to brag about something this cool!<br>
	I'm not really sure why I'm choosing to journal this. Doc seems to log everything. He says it's incase he discovers anything important.<br>
	I guess that's why I'm doing it too, I've always wanted to be a part of something important.<br>
	Here's to a new job and to becoming a part of something important!<br>
	<h4>Weird times...</h4>
	Things are starting to get a little strange around here. Just weeks after Doc's amazing breakthrough, weird visitors have began showing up unannounced, asking strange things about Doc's work.<br>
	I knew Doc wasn't a big fan of company, but even he seemed strangely unnerved when I told him about the visitors.<br>
	He said it's important that from here on out we keep tight security on everything, even other staff members.<br>
	He also said something about securing data, something about hexes. What's that mean? Some sort of curse? Doc never struck me as the magic type...<br>
	He often uses a lot of big sciencey words that I don't really understand, but I kinda dig it, it makes me feel like I'm witnessing something big.<br>
	I hope things go back to normal soon, but I guess that's the price you pay for being a part of something important.<br>
	<h4>Last day I guess?</h4>
	Things are officially starting to get too strange for me.<br>
	The visitors have been coming a lot more often, and they all seem increasingly aggressive and nosey. I'm starting to see why they made Doc so nervous, they're certainly starting to creep me out too.<br>
	Awhile ago Doc started having me keep the place on strict lockdown and requested I refuse entry to anyone else, including previous staff.<br>
	But the weirdest part?<br>
	I haven't seen Doc in days. It's not unusual for him to work continuously for long periods of time in the lab, but when I took a peak in their yesterday - he was nowhere to be seen! I didn't risk prying much further, Doc had a habit of leaving the defense systems on these last few weeks.<br>
	I'm thinking it might be time to call it quits. Can't work much without a boss, plus things are starting to get kind of shady. I wanted to be a part of something important, but you gotta know when to play it safe.<br>
	As my dad always said, "The smart get famous, but the wise survive..."<br>
	<br>
	<i>Robert P.</i>"}

/obj/item/paper/crumpled/bloody/docsdeathnote
	name = "note"
	default_raw_text = {"
This is it isn't it?
No one's coming to help, that much has become clear.
Sure, it's lonely, but do I have much choice? At least I brought the analyzer with me, they shouldn't be able to find me without it.
Who knows who's waiting for me out there. Its either die out there in their hands, or die a slower, slightly more comfortable death in here.
Everyday I can feel myself slipping away more and more, both physically and mentally. Who knows what happens now...
Heh, so it's true then, this must be the inescapable path of all great minds... so be it then.
_Choose a room, and enter the sphere
Lay your head to rest, it soon becomes clear
There's always more room around every bend
Not all that's countable has an end..._
"}
