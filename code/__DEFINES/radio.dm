// Radios use a large variety of predefined frequencies.

//say based modes like binary are in living/say.dm

#define RADIO_CHANNEL_COMMON "Common"
#define RADIO_KEY_COMMON ";"

#define RADIO_CHANNEL_SECURITY "Security"
#define RADIO_KEY_SECURITY "s"
#define RADIO_TOKEN_SECURITY ":s"

#define RADIO_CHANNEL_ENGINEERING "Engineering"
#define RADIO_KEY_ENGINEERING "e"
#define RADIO_TOKEN_ENGINEERING ":e"

#define RADIO_CHANNEL_COMMAND "Command"
#define RADIO_KEY_COMMAND "c"
#define RADIO_TOKEN_COMMAND ":c"

#define RADIO_CHANNEL_SCIENCE "Science"
#define RADIO_KEY_SCIENCE "n"
#define RADIO_TOKEN_SCIENCE ":n"

#define RADIO_CHANNEL_MEDICAL "Medical"
#define RADIO_KEY_MEDICAL "m"
#define RADIO_TOKEN_MEDICAL ":m"

#define RADIO_CHANNEL_SUPPLY "Supply"
#define RADIO_KEY_SUPPLY "u"
#define RADIO_TOKEN_SUPPLY ":u"

#define RADIO_CHANNEL_SERVICE "Service"
#define RADIO_KEY_SERVICE "v"
#define RADIO_TOKEN_SERVICE ":v"

#define RADIO_CHANNEL_AI_PRIVATE "AI Private"
#define RADIO_KEY_AI_PRIVATE "o"
#define RADIO_TOKEN_AI_PRIVATE ":o"


#define RADIO_CHANNEL_SYNDICATE "Syndicate"
#define RADIO_KEY_SYNDICATE "t"
#define RADIO_TOKEN_SYNDICATE ":t"

#define RADIO_CHANNEL_CENTCOM "CentCom"
#define RADIO_KEY_CENTCOM "y"
#define RADIO_TOKEN_CENTCOM ":y"

#define RADIO_CHANNEL_CTF_RED "Red Team"
#define RADIO_CHANNEL_CTF_BLUE "Blue Team"


#define MIN_FREE_FREQ 1201 // -------------------------------------------------
// Frequencies are always odd numbers and range from 1201 to 1599.

#define FREQ_SYNDICATE 1213  // Nuke op comms frequency, dark brown
#define FREQ_CTF_RED 1215  // CTF red team comms frequency, red
#define FREQ_CTF_BLUE 1217  // CTF blue team comms frequency, blue
#define FREQ_CENTCOM 1337  // CentCom comms frequency, gray
#define FREQ_SUPPLY 1347  // Supply comms frequency, light brown
#define FREQ_SERVICE 1349  // Service comms frequency, green
#define FREQ_SCIENCE 1351  // Science comms frequency, plum
#define FREQ_COMMAND 1353  // Command comms frequency, gold
#define FREQ_MEDICAL 1355  // Medical comms frequency, soft blue
#define FREQ_ENGINEERING 1357  // Engineering comms frequency, orange
#define FREQ_SECURITY 1359  // Security comms frequency, red

#define FREQ_HOLOGRID_SOLUTION 1433
#define FREQ_STATUS_DISPLAYS 1435
#define FREQ_ATMOS_ALARMS 1437  // air alarms <-> alert computers
#define FREQ_ATMOS_CONTROL 1439  // air alarms <-> vents and scrubbers

#define MIN_FREQ 1441 // ------------------------------------------------------
// Only the 1441 to 1489 range is freely available for general conversation.
// This represents 1/8th of the available spectrum.

#define FREQ_ATMOS_STORAGE 1441
#define FREQ_NAV_BEACON 1445
#define FREQ_AI_PRIVATE 1447  // AI private comms frequency, magenta
#define FREQ_PRESSURE_PLATE 1447
#define FREQ_AIRLOCK_CONTROL 1449
#define FREQ_ELECTROPACK 1449
#define FREQ_MAGNETS 1449
#define FREQ_LOCATOR_IMPLANT 1451
#define FREQ_SIGNALER 1457  // the default for new signalers
#define FREQ_COMMON 1459  // Common comms frequency, dark green

#define MAX_FREQ 1489 // ------------------------------------------------------

#define MAX_FREE_FREQ 1599 // -------------------------------------------------

// Transmission types.
#define TRANSMISSION_WIRE 0  // some sort of wired connection, not used
#define TRANSMISSION_RADIO 1  // electromagnetic radiation (default)
#define TRANSMISSION_SUBSPACE 2  // subspace transmission (headsets only)
#define TRANSMISSION_SUPERSPACE 3  // reaches independent (CentCom) radios only

// Filter types, used as an optimization to avoid unnecessary proc calls.
#define RADIO_TO_AIRALARM "to_airalarm"
#define RADIO_FROM_AIRALARM "from_airalarm"
#define RADIO_SIGNALER "signaler"
#define RADIO_ATMOSIA "atmosia"
#define RADIO_AIRLOCK "airlock"
#define RADIO_MAGNETS "magnets"

#define DEFAULT_SIGNALER_CODE 30

#define RADIO_CHANNEL_TARKOFF "Tarkov"
#define RADIO_KEY_TARKOFF "k"
#define RADIO_TOKEN_TARKOFF ":k"
#define FREQ_TARKOFF 1243

#define RADIO_CHANNEL_DS1 "DS-1"
#define RADIO_KEY_DS1 "q"
#define RADIO_TOKEN_DS1 ":q"
#define FREQ_DS1 1209

#define RADIO_CHANNEL_DS2 "DS-2"
#define RADIO_KEY_DS2 "w"
#define RADIO_TOKEN_DS2 ":w"
#define FREQ_DS2 1210

#define RADIO_CHANNEL_PIRATE "Illegal"
#define RADIO_KEY_PIRATE "z"
#define RADIO_TOKEN_PIRATE ":z"
#define FREQ_PIRATE 1208

#define RADIO_CHANNEL_INTEQ "InteQ"
#define RADIO_KEY_INTEQ "i"
#define RADIO_TOKEN_INTEQ ":i"
#define FREQ_INTEQ 1207

#define RADIO_CHANNEL_GHOST_INTEQ "KK-28"
#define FREQ_GHOST_INTEQ 1219  // Рация оперативников с Забытого Корабля ИнтеКью.

// BlueMoon Kovac added
#define RADIO_CHANNEL_SOL "Sol"
#define RADIO_KEY_SOL "x"
#define RADIO_TOKEN_SOL ":x"
#define FREQ_SOL 1244

#define RADIO_CHANNEL_NRI "Rus"
#define RADIO_KEY_NRI "r"
#define RADIO_TOKEN_NRI ":r"
#define FREQ_NRI 1222

#define RADIO_CHANNEL_HOTEL "Hotel"
#define RADIO_KEY_HOTEL "q"
#define RADIO_TOKEN_HOTEL ":q"
#define FREQ_HOTEL 1281

// BlueMoon Fink added
#define RADIO_CHANNEL_LAW "Law"
#define RADIO_KEY_LAW "l"
#define RADIO_TOKEN_LAW ":l"
#define FREQ_LAW 1415
