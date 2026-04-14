/datum/ert
	var/mobtype = /mob/living/carbon/human
	var/team = /datum/team/ert
	var/opendoors = FALSE
	/// If TRUE, the admin who created the response team will be spawned in the briefing room in their preferred briefing outfit (assuming they're a ghost)
	var/spawn_admin = FALSE
	///Do we want to notify the players of this ERT?
	var/notify_players = TRUE
	var/leader_role = /datum/antagonist/ert/commander
	var/enforce_human = TRUE
	var/roles = list(/datum/antagonist/ert/security, /datum/antagonist/ert/medic, /datum/antagonist/ert/engineer) //List of possible roles to be assigned to ERT members.
	var/rename_team
	var/code
	var/mission = "защитите станцию любой ценой и докажите свою состоятельность!"
	var/teamsize = 5
	var/polldesc
	var/ertphrase = 'modular_bluemoon/sound/ert/ert_yes.ogg'

/datum/ert/New()
	if (!polldesc)
		polldesc = "a Code [code] Nanotrasen Emergency Response Team"

/datum/ert/janitor
	opendoors = FALSE
	code = "Crap"
	mission = "очистите станцию от всевозможной грязи."
	leader_role = /datum/antagonist/ert/janitor
	roles = list(/datum/antagonist/ert/janitor)

/datum/ert/green
	opendoors = FALSE
	code = "Green"
	leader_role = /datum/antagonist/ert/commander/green
	roles = list(/datum/antagonist/ert/security/green, /datum/antagonist/ert/medic/green, /datum/antagonist/ert/engineer/green)

/datum/ert/mopp
	opendoors = FALSE
	code = "MOPP"
	leader_role = /datum/antagonist/ert/commander/mopp
	roles = list(/datum/antagonist/ert/security/mopp, /datum/antagonist/ert/medic/mopp, /datum/antagonist/ert/engineer/mopp)

/datum/ert/blue
	opendoors = FALSE
	code = "Blue"

/datum/ert/amber
	code = "Amber"
	leader_role = /datum/antagonist/ert/commander/amber
	roles = list(/datum/antagonist/ert/security/amber, /datum/antagonist/ert/medic/amber, /datum/antagonist/ert/engineer/amber)

/datum/ert/red
	leader_role = /datum/antagonist/ert/commander/red
	roles = list(/datum/antagonist/ert/security/red, /datum/antagonist/ert/medic/red, /datum/antagonist/ert/engineer/red)
	opendoors = TRUE
	code = "Red"
	mission = "устраните угрозы Космической Станции. Её утеря стала бы серьёзным ударом для функционирования ПАКТ." // BLUEMOON ADD

/datum/ert/deathsquad
	roles = list(/datum/antagonist/ert/deathsquad)
	leader_role = /datum/antagonist/ert/deathsquad/leader
	opendoors = TRUE
	notify_players = FALSE
	rename_team = "Deathsquad"
	code = "EPSILON"
	mission = "уничтожить Космическую Станцию, включая активы, в том числе весь экипаж."
	polldesc = "an Elite Nanotrasen Strike Team"
	ertphrase = "modular_bluemoon/sound/ert/deathsquad_send_in.ogg"

/datum/ert/asset_protection
	roles = list(/datum/antagonist/ert/asset_protection)
	leader_role = /datum/antagonist/ert/asset_protection/leader
	rename_team = "Asset Protection Team"
	code = "LAMBDA"
	mission = "защитите Активы ПАКТ. Сотрудники ПАКТ тоже являются Активами ПАКТ."
	polldesc = "a Nanotrasen Asset Protection Team"
	ertphrase = "modular_bluemoon/sound/ert/asset_protection_send.ogg"

/datum/ert/syndiesquad
	roles = list(/datum/antagonist/ert/syndiesquad)
	leader_role = /datum/antagonist/ert/syndiesquad/leader
	opendoors = TRUE
	rename_team = "Syndicate Strike Team"
	code = "GAMMA"
	mission = "разберитесь с проблемами, достойными Дельта-Кода."
	polldesc = "an elite Syndicate Strike Team"

/datum/ert/centcom_official
	code = "Official"
	teamsize = 3
	opendoors = FALSE
	leader_role = /datum/antagonist/official
	roles = list(/datum/antagonist/ert/security, /datum/antagonist/ert/medic)
	rename_team = "CentCom Officials"
	polldesc = "a CentCom Official"

/datum/ert/centcom_official/New()
	mission = "разберитесь с проблемами на объекте \"[station_name()]\", а также проведите плановую проверку всех Отделов и Командования."

/datum/ert/inquisition
	roles = list(/datum/antagonist/ert/security/inquisitor, /datum/antagonist/ert/medic/inquisitor)
	leader_role = /datum/antagonist/ert/commander/inquisitor
	rename_team = "Inquisition"
	mission = "уничтожьте любые следы паранормальной активности на борту Космической Станции Тринадцатого Сектора."
	polldesc = "a Nanotrasen paranormal response team"
	ertphrase = 'modular_bluemoon/sound/ert/ert_inq_send.ogg'

/datum/ert/greybois
	code = "Green"
	teamsize = 5
	opendoors = FALSE
	enforce_human = FALSE
	roles = list(/datum/antagonist/greybois)
	leader_role = /datum/antagonist/greybois/greygod
	rename_team = "Emergency Assistants"
	polldesc = "an Emergency Assistant"
	ertphrase = 'modular_bluemoon/sound/ert/ert_rofl.ogg'
