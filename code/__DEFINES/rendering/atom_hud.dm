// for secHUDs and medHUDs and variants. The number is the location of the image on the list hud_list
// note: if you add more HUDs, even for non-human atoms, make sure to use unique numbers for the defines!
// /datum/atom_hud expects these to be unique
// these need to be strings in order to make them associative lists
#define HEALTH_HUD		"1" // dead, alive, sick, health status
#define STATUS_HUD		"2" // a simple line rounding the mob's number health
#define ID_HUD			"3" // the job asigned to your ID
#define WANTED_HUD		"4" // wanted, released, parroled, security status
#define IMPLOYAL_HUD	"5" // loyality implant
#define IMPCHEM_HUD		"6" // chemical implant
#define IMPTRACK_HUD	"7" // tracking implant
#define DIAG_STAT_HUD	"8" // Silicon/Mech/Circuit Status
#define DIAG_HUD		"9" // Silicon health bar
#define DIAG_BATT_HUD	"10"// Borg/Mech/Circutry power meter
#define DIAG_MECH_HUD	"11"// Mech health bar
#define DIAG_BOT_HUD	"12"// Bot HUDs
#define DIAG_CIRCUIT_HUD "13"// Circuit assembly health bar
#define DIAG_TRACK_HUD	"14"// Mech/Silicon tracking beacon, Circutry long range icon
#define DIAG_AIRLOCK_HUD "15"//Airlock shock overlay
#define DIAG_PATH_HUD "16"//Bot path indicators
#define GLAND_HUD "17"//Gland indicators for abductors
#define SENTIENT_DISEASE_HUD	"18"
#define AI_DETECT_HUD	"19"
#define NANITE_HUD "20"
#define DIAG_NANITE_FULL_HUD "21"
#define RAD_HUD			"22"	//radation alerts for medical huds
#define DIAG_LAUNCHPAD_HUD "23" //Displays launchpads' targeting reticle
//for antag huds. these are used at the /mob level
#define ANTAG_HUD		"24"
#define ANTAGTARGET_HUD "25" // Which players consent via their game settings to be a target for antagonists

//by default everything in the hud_list of an atom is an image
//a value in hud_list with one of these will change that behavior
#define HUD_LIST_LIST 1

//data HUD (medhud, sechud) defines
//Don't forget to update human/New() if you change these!
#define DATA_HUD_SECURITY_BASIC			1
#define DATA_HUD_SECURITY_ADVANCED		2
#define DATA_HUD_MEDICAL_BASIC			3
#define DATA_HUD_MEDICAL_ADVANCED		4
#define DATA_HUD_DIAGNOSTIC_BASIC		5
#define DATA_HUD_DIAGNOSTIC_ADVANCED	6
#define DATA_HUD_ABDUCTOR				7
#define DATA_HUD_SENTIENT_DISEASE		8
#define DATA_HUD_AI_DETECT				9

//antag HUD defines
#define ANTAG_HUD_CULT			10
#define ANTAG_HUD_REV			11
#define ANTAG_HUD_OPS			12
#define ANTAG_HUD_WIZ			13
#define ANTAG_HUD_SHADOW    	14
#define ANTAG_HUD_TRAITOR 		15
#define ANTAG_HUD_NINJA 		16
#define ANTAG_HUD_CHANGELING 	17
#define ANTAG_HUD_ABDUCTOR 		18
#define ANTAG_HUD_DEVIL			19
#define ANTAG_HUD_SINTOUCHED	20
#define ANTAG_HUD_SOULLESS		21
#define ANTAG_HUD_CLOCKWORK		22
#define ANTAG_HUD_BROTHER		23
#define ANTAG_HUD_BLOODSUCKER   24
#define ANTAG_HUD_FUGITIVE		25
#define ANTAG_HUD_HERETIC		26
#define ANTAG_HUD_SPACECOP		27
#define ANTAG_HUD_GANGSTER		28
#define ANTAG_HUD_SLAVER		29

// Which players consent via their game settings to be a target for antagonists
#define DATA_HUD_ANTAGTARGET	30

#define ADD_HUD_TO_COOLDOWN 20 //cooldown for being shown the images for any particular data hud

// Security HUD icon_state defines

#define SECHUD_NO_ID "hudno_id"
#define SECHUD_UNKNOWN "hudunknown"
#define SECHUD_CENTCOM "hudcentcom"
#define SECHUD_SYNDICATE "hudsyndicate"

#define SECHUD_ASSISTANT "hudassistant"
#define SECHUD_ATMOSPHERIC_TECHNICIAN "hudatmospherictechnician"
#define SECHUD_BARTENDER "hudbartender"
#define SECHUD_BOTANIST "hudbotanist"
#define SECHUD_BOUNCER "hudbouncer"
#define SECHUD_ETERTAINER "hudentertainer" // BLUEMOON ADD
#define SECHUD_CAPTAIN "hudcaptain"
#define SECHUD_CARGO_TECHNICIAN "hudcargotechnician"
#define SECHUD_CHAPLAIN "hudchaplain"
#define SECHUD_CHEMIST "hudchemist"
#define SECHUD_CHIEF_ENGINEER "hudchiefengineer"
#define SECHUD_CHIEF_MEDICAL_OFFICER "hudchiefmedicalofficer"
#define SECHUD_CLOWN "hudclown"
#define SECHUD_COOK "hudcook"
#define SECHUD_CURATOR "hudcurator"
#define SECHUD_DETECTIVE "huddetective"
#define SECHUD_GENETICIST "hudgeneticist"
#define SECHUD_HEAD_OF_PERSONNEL "hudheadofpersonnel"
#define SECHUD_HEAD_OF_SECURITY "hudheadofsecurity"
#define SECHUD_JANITOR "hudjanitor"
#define SECHUD_LAWYER "hudlawyer"
#define SECHUD_NTR "hudnanotrasenrepresentative"
#define SECHUD_MEDICAL_DOCTOR "hudmedicaldoctor"
#define SECHUD_MIME "hudmime"
#define SECHUD_PARAMEDIC "hudparamedic"
#define SECHUD_PRISONER "hudprisoner"
#define SECHUD_PSYCHOLOGIST "hudpsychologist"
#define SECHUD_QUARTERMASTER "hudquartermaster"
#define SECHUD_RESEARCH_DIRECTOR "hudresearchdirector"
#define SECHUD_ROBOTICIST "hudroboticist"
#define SECHUD_SECURITY_OFFICER "hudsecurityofficer"
#define SECHUD_SCIENTIST "hudscientist"
#define SECHUD_SHAFT_MINER "hudshaftminer"
#define SECHUD_STATION_ENGINEER "hudstationengineer"
#define SECHUD_VIROLOGIST "hudvirologist"
#define SECHUD_WARDEN "hudwarden"

#define SECHUD_CHEF "hudchef"

#define SECHUD_DEATH_COMMANDO "huddeathcommando"

#define SECHUD_NRI "hudnri"
#define SECHUD_SOL "hudsol"
#define SECHUD_BM  "hudbmland"
#define SECHUD_HERESY  "hudheresy"
#define SECHUD_LUST  "hudlust"
#define SECHUD_AGONY  "hudagony"
#define SECHUD_MUCK  "hudmuck"

// Hotel HUDs
#define SECHUD_HOTEL_STAFF "hudhotelstaff"
#define SECHUD_HOTEL_SECURITY "hudhotelsecurity"
#define SECHUD_HOTEL_MANAGER "hudhotelmanager"
#define SECHUD_HOTEL_TOURIST "hudhoteltourist"

#define SECHUD_EMERGENCY_RESPONSE_TEAM_COMMANDER "hudemergencyresponseteamcommander"
#define SECHUD_SECURITY_RESPONSE_OFFICER "hudsecurityresponseofficer"
#define SECHUD_ENGINEERING_RESPONSE_OFFICER "hudengineeringresponseofficer"
#define SECHUD_MEDICAL_RESPONSE_OFFICER "hudmedicalresponseofficer"
#define SECHUD_RELIGIOUS_RESPONSE_OFFICER "hudreligiousresponseofficer"
#define SECHUD_JANITORIAL_RESPONSE_OFFICER "hudjanitorialresponseofficer"
#define SECHUD_ENTERTAINMENT_RESPONSE_OFFICER "hudentertainmentresponseofficer"

//SR DS2
#define SECHUD_DS2_DOCTOR "hudds2medicalofficer"
#define SECHUD_DS2_RESEARCHER "hudds2researcher"
#define SECHUD_DS2_ENGINETECHNICIAN "hudds2enginetechnician"
#define SECHUD_DS2_CORPLIAISON "hudds2corporateliaison"
#define SECHUD_DS2_ADMIRAL "hudds2admiral"
#define SECHUD_DS2_MASTERATARMS "hudds2masteratarms"
#define SECHUD_DS2_BRIGOFFICER "hudds2brigofficer"
#define SECHUD_DS2_MININGOFFICER "hudds2miningofficer"
#define SECHUD_DS2_GENSTAFF "hudds2generalstaff"
#define SECHUD_DS2_PRISONER "hudds2hostage"

//SR DS 1
#define SECHUD_DS1_NUKETECH "hudds1nuketech"
