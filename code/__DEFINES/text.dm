/// Does 4 spaces. Used as a makeshift tabulator.
#define FOURSPACES "&nbsp;&nbsp;&nbsp;&nbsp;"

/// Standard maptext
/// Prepares a text to be used for maptext. Use this so it doesn't look hideous.
#define MAPTEXT(text) {"<span class='maptext'>[##text]</span>"}

#define RODITELNI  1
#define DATELNI    2
#define VINITELNI  3
#define TVORITELNI 4
#define PREDLOZHNI 5

GLOBAL_LIST_INIT(PfemaleOneStop, 		list("б","в","г","д","ж",
											"з","й","к","л","м",
											"н","п","р","с","т",
											"ф","х","ц","ч","ш",
											"щ","ъ","ь"))
GLOBAL_LIST_INIT(POneStop, 				list("о","е","ё","э","и",
											"ы","у","ю"))
GLOBAL_LIST_INIT(PTwoStop, 				list("ия","иа","аа","оа","уа",
											"ыа","еа","юа","эа","их",
											"ых"))
GLOBAL_LIST_INIT(PfemaleOneFrom, 		list("ь"))
GLOBAL_LIST_INIT(PfemaleOneTo, 			list("и","и","ь","ю","и"))
GLOBAL_LIST_INIT(PmaleOneFrom, 			list("ь"))
GLOBAL_LIST_INIT(PmaleOneTo, 			list("я","ю","я","ем","е"))
GLOBAL_LIST_INIT(PfemaleTwoFrom, 		list("ая","на"))
GLOBAL_LIST_INIT(PfemaleTwoTo, 			list("ой","ой","ую","ой","ой",
											"ой","ой","у","ой","ой"))
GLOBAL_LIST_INIT(PfemaleThreeFrom, 		list("ска","цка"))
GLOBAL_LIST_INIT(PfemaleThreeTo, 		list("ой","ой","ую","ой","ой"))
GLOBAL_LIST_INIT(POneFrom, 				list("а","ь","я","й"))
GLOBAL_LIST_INIT(POneTo, 				list("ы","е","у","ой","е",
											"я","ю","я","ем","е",
											"и","у","ю","ей","е",
											"я","ю","я","ем","е"))
GLOBAL_LIST_INIT(POneListFrom, 			list("ц","ч","ш","щ"))
GLOBAL_LIST_INIT(POneListTo, 			list("а","у","а","ем","е"))
GLOBAL_LIST_INIT(POneListOtherFrom, 	list("б","в","г","д","ж",
											"з","к","л","м","н",
											"п","р","с","т","ф",
											"х","ц","ч"))
GLOBAL_LIST_INIT(POneListOtherTo, 		list("а","у","а","ом","е"))
GLOBAL_LIST_INIT(POneListTooFrom, 		list("в","н"))
GLOBAL_LIST_INIT(POneListTooTo, 		list("а","у","а","ым","е"))
GLOBAL_LIST_INIT(PTwoFrom, 				list("ич","ша","ия","ей","ий",
											"на","уй","ца","ай","ой",
											"ок","ец"))
GLOBAL_LIST_INIT(PTwoTo, 				list("а", "у", "а", "ем", "е",
											"и", "е", "у", "ей", "е",
											"и", "и", "ю", "ей", "и",
											"я", "ю", "я", "ем", "е",
											"я", "ю", "я", "ем", "и",
											"ы", "е", "у", "ой", "е",
											"я", "ю", "я", "ем", "е",
											"ы", "е", "у", "её", "е",
											"я", "ю", "я", "ем", "е",
											"го","му","го","ым", "м",
											"ка","ку","ка","ком","ке",
											"ца","цу","ца","цом","це"))
GLOBAL_LIST_INIT(PTwoListFrom, 			list("га","ка","ха","ча","ща",
											"жа"))
GLOBAL_LIST_INIT(PTwoListTo, 			list("и","е","у","ой","е"))
GLOBAL_LIST_INIT(PTwoListOtherFrom, 	list("ян","ан","йн","ах","ив"))
GLOBAL_LIST_INIT(PTwoListOtherTo, 		list("а","у","а","ом","е"))
GLOBAL_LIST_INIT(PThreeFrom, 			list("рих"))
GLOBAL_LIST_INIT(PThreeTo, 				list("а","у","а","ом","е"))
GLOBAL_LIST_INIT(PThreeListFrom, 		list("ова","ева"))
GLOBAL_LIST_INIT(PThreeListTo, 			list("ой","ой","у","ой","ой"))
GLOBAL_LIST_INIT(PThreeListOtherFrom, 	list("гой","кой"))
GLOBAL_LIST_INIT(PThreeListOtherTo, 	list("го","му","го","им","м"))
GLOBAL_LIST_INIT(PThreeListTooFrom,		list("ший","щий","жий","ний"))
GLOBAL_LIST_INIT(PThreeListTooTo, 		list("его","ему","его","м","ем"))
GLOBAL_LIST_INIT(POtherListTo, 			list("ого","ому","ого","м","ом"))
GLOBAL_LIST_INIT(PFourFrom, 			list("ская"))
GLOBAL_LIST_INIT(PFourTo, 				list("ой","ой","ую","ой","ой"))
GLOBAL_LIST_INIT(PFourOtherFrom, 		list("иной"))
GLOBAL_LIST_INIT(PFourOtherTo, 			list("я","ю","я","ем","е"))
GLOBAL_LIST_INIT(PFourListFrom, 		list("ынец","обец"))
GLOBAL_LIST_INIT(PFourListTo, 			list("ца","цу","ца","цем","це"))
GLOBAL_LIST_INIT(PFourListOtherFrom, 	list("онец","овец"))
GLOBAL_LIST_INIT(PFourListOtherTo, 		list("ца","цу","ца","цом","це"))

GLOBAL_LIST_INIT(rus_unicode_conversion,list(
	"А" = "1040", "а" = "1072",
	"Б" = "1041", "б" = "1073",
	"В" = "1042", "в" = "1074",
	"Г" = "1043", "г" = "1075",
	"Д" = "1044", "д" = "1076",
	"Е" = "1045", "е" = "1077",
	"Ж" = "1046", "ж" = "1078",
	"З" = "1047", "з" = "1079",
	"И" = "1048", "и" = "1080",
	"Й" = "1049", "й" = "1081",
	"К" = "1050", "к" = "1082",
	"Л" = "1051", "л" = "1083",
	"М" = "1052", "м" = "1084",
	"Н" = "1053", "н" = "1085",
	"О" = "1054", "о" = "1086",
	"П" = "1055", "п" = "1087",
	"Р" = "1056", "р" = "1088",
	"С" = "1057", "с" = "1089",
	"Т" = "1058", "т" = "1090",
	"У" = "1059", "у" = "1091",
	"Ф" = "1060", "ф" = "1092",
	"Х" = "1061", "х" = "1093",
	"Ц" = "1062", "ц" = "1094",
	"Ч" = "1063", "ч" = "1095",
	"Ш" = "1064", "ш" = "1096",
	"Щ" = "1065", "щ" = "1097",
	"Ъ" = "1066", "ъ" = "1098",
	"Ы" = "1067", "ы" = "1099",
	"Ь" = "1068", "ь" = "1100",
	"Э" = "1069", "э" = "1101",
	"Ю" = "1070", "ю" = "1102",
	"Я" = "1071", "я" = "1103",

	"Ё" = "1025", "ё" = "1105"
	))

GLOBAL_LIST_INIT(rus_unicode_conversion_hex,list(
	"А" = "0410", "а" = "0430",
	"Б" = "0411", "б" = "0431",
	"В" = "0412", "в" = "0432",
	"Г" = "0413", "г" = "0433",
	"Д" = "0414", "д" = "0434",
	"Е" = "0415", "е" = "0435",
	"Ж" = "0416", "ж" = "0436",
	"З" = "0417", "з" = "0437",
	"И" = "0418", "и" = "0438",
	"Й" = "0419", "й" = "0439",
	"К" = "041a", "к" = "043a",
	"Л" = "041b", "л" = "043b",
	"М" = "041c", "м" = "043c",
	"Н" = "041d", "н" = "043d",
	"О" = "041e", "о" = "043e",
	"П" = "041f", "п" = "043f",
	"Р" = "0420", "р" = "0440",
	"С" = "0421", "с" = "0441",
	"Т" = "0422", "т" = "0442",
	"У" = "0423", "у" = "0443",
	"Ф" = "0424", "ф" = "0444",
	"Х" = "0425", "х" = "0445",
	"Ц" = "0426", "ц" = "0446",
	"Ч" = "0427", "ч" = "0447",
	"Ш" = "0428", "ш" = "0448",
	"Щ" = "0429", "щ" = "0449",
	"Ъ" = "042a", "ъ" = "044a",
	"Ы" = "042b", "ы" = "044b",
	"Ь" = "042c", "ь" = "044c",
	"Э" = "042d", "э" = "044d",
	"Ю" = "042e", "ю" = "044e",
	"Я" = "042f", "я" = "044f",

	"Ё" = "0401", "ё" = "0451"
	))

GLOBAL_LIST_INIT(ddlc_chars, list(
	"¡", "¢", "£", "¤", "¥", "¦", "§",
	"¨", "©", "ª", "«", "¬", "®", "¯",
	"°", "±", "²", "³", "´", "µ", "¶",
	"·", "¸", "¹", "º", "»", "¼", "½",
	"¾", "¿", "À", "Á", "Â", "Ã", "Ä",
	"Å", "Æ", "Ç", "È", "É", "Ê", "Ë",
	"Ì", "Í", "Î", "Ï", "Ð", "Ñ", "Ò",
	"Ó", "Ô", "Õ", "Ö", "×", "Ø", "Ù",
	"Ú", "Û", "Ü", "Ý", "Þ", "ß", "à",
	"á", "â", "ã", "ä", "å", "æ", "ç",
	"è", "é", "ê", "ë", "ì", "í", "î",
	"ï", "ð", "ñ", "ò", "ó", "ô", "õ",
	"ö", "÷", "ø", "ù", "ú", "û", "ü",
	"ý", "þ", "ÿ", "Ā", "ā", "Ă", "ă",
	"Ą", "ą", "Ć", "ć", "Ĉ", "ĉ", "Ċ",
	"ċ", "Č", "č", "Ď", "ď", "Đ", "đ",
	"Ē", "ē", "Ĕ", "ĕ", "Ė", "ė", "Ę",
	"ę", "Ě", "ě", "Ĝ", "ĝ", "Ğ", "ğ",
	"Ġ", "ġ", "Ģ", "ģ", "Ĥ", "ĥ", "Ħ",
	"ħ", "Ĩ", "ĩ", "Ī", "ī", "Ĭ", "ĭ",
	"Į", "į", "İ", "ı", "Ĳ", "ĳ", "Ĵ",
	"ĵ", "Ķ", "ķ", "ĸ", "Ĺ", "ĺ", "Ļ",
	"ļ", "Ľ", "ľ", "Ŀ", "ŀ", "Ł", "ł",
	"Ń", "ń", "Ņ", "ņ", "Ň", "ň", "ŉ",
	"Ŋ", "ŋ", "Ō", "ō", "Ŏ", "ŏ", "Ő",
	"ő", "Œ", "œ", "Ŕ", "ŕ", "Ŗ", "ŗ",
	"Ř", "ř", "Ś", "ś", "Ŝ", "ŝ", "Ş",
	"ş", "Š", "š", "Ţ", "ţ", "Ť", "ť",
	"Ŧ", "ŧ", "Ũ", "ũ", "Ū", "ū", "Ŭ",
	"ŭ", "Ů", "ů", "Ű", "ű", "Ų", "ų",
	"Ŵ", "ŵ", "Ŷ", "ŷ", "Ÿ", "Ź", "ź",
	"Ż", "ż", "Ž", "ž"))
/**
 * Pixel-perfect scaled fonts for use in the MAP element as defined in skin.dmf
 *
 * Four sizes to choose from, use the sizes as mentioned below.
 * Between the variations and a step there should be an option that fits your use case.
 * BYOND uses pt sizing, different than px used in TGUI. Using px will make it look blurry due to poor antialiasing.
 *
 * Default sizes are prefilled in the macro for ease of use and a consistent visual look.
 * To use a step other than the default in the macro, specify it in a span style.
 * For example: MAPTEXT_PIXELLARI("<span style='font-size: 24pt'>Some large maptext here</span>")
 */
/// Large size (ie: context tooltips) - Size options: 12pt 24pt.
#define MAPTEXT_PIXELLARI(text) {"<span style='font-family: \"Pixellari\"; font-size: 12pt; -dm-text-outline: 1px black'>[##text]</span>"}

/// Standard size (ie: normal runechat) - Size options: 6pt 12pt 18pt.
#define MAPTEXT_GRAND9K(text) {"<span style='font-family: \"Grand9K Pixel\"; font-size: 6pt; -dm-text-outline: 1px black'>[##text]</span>"}

/// Small size. (ie: context subtooltips, spell delays) - Size options: 12pt 24pt.
#define MAPTEXT_TINY_UNICODE(text) {"<span style='font-family: \"TinyUnicode\"; font-size: 12pt; line-height: 0.75; -dm-text-outline: 1px black'>[##text]</span>"}

/// Smallest size. (ie: whisper runechat) - Size options: 6pt 12pt 18pt.
#define MAPTEXT_SPESSFONT(text) {"<span style='font-family: \"Spess Font\"; font-size: 6pt; line-height: 1.4; -dm-text-outline: 1px black'>[##text]</span>"}

/**
 * Prepares a text to be used for maptext, using a variable size font.
 *
 * More flexible but doesn't scale pixel perfect to BYOND icon resolutions.
 * (May be blurry.) Can use any size in pt or px.
 *
 * You MUST Specify the size when using the macro
 * For example: MAPTEXT_VCR_OSD_MONO("<span style='font-size: 24pt'>Some large maptext here</span>")
 */
/// Prepares a text to be used for maptext, using a variable size font.
/// Variable size font. More flexible but doesn't scale pixel perfect to BYOND icon resolutions. (May be blurry.) Can use any size in pt or px.
#define MAPTEXT_VCR_OSD_MONO(text) {"<span style='font-family: \"VCR OSD Mono\"'>[##text]</span>"}

/// Macro from Lummox used to get height from a MeasureText proc.
/// resolves the MeasureText() return value once, then resolves the height, then sets return_var to that.
#define WXH_TO_HEIGHT(measurement, return_var) \
	do { \
		var/_measurement = measurement; \
		return_var = text2num(copytext(_measurement, findtextEx(_measurement, "x") + 1)); \
	} while(FALSE);

/// Lines the bubblegum hallucinatoin uses when it pops up
#define BUBBLEGUM_HALLUCINATION_LINES list( \
		span_colossus("Я БЕССМЕРТНЫЙ!"), \
		span_colossus("Я ЗАХВАЧУ ВЕСЬ МИР!!"), \
		span_colossus("Я ВИЖУ ТЕБЯ!"), \
		span_colossus("НИКТО МЕНЯ НЕ ОСТАНОВИТ!"), \
		span_colossus("ТЫ НЕ СМОЖЕШЬ БЕЖАТЬ ВЕЧНО!!!"), \
	)

/// Лист-словарь для examine string'а материалов в именительном падеже
GLOBAL_LIST_INIT(mat_ru_nominative, list(
    "iron" = "железо",
    "glass" = "стекло",
    "plasma" = "плазма",
    "gold" = "золото",
    "silver" = "серебро",
    "diamond" = "алмазы",
    "uranium" = "уран",
    "titanium" = "титан",
    "plasma glass" = "плазменное стекло",
    "reinforced glass" = "закалённое стекло",
    "bluespace crystal" = "блюспейс-кристаллы",
    "bananium" = "бананиум",
	"runite" = "рунит",
	"plastic" = "пластик",
	"biomass" = "биомасса",
	"wood" = "дерево",
	"adamantine" = "адамантин",
	"mythril" = "мифрил",
	"sand" = "песк",
	"sandstone" = "песчаник",
	"snow" = "снег",
	"runed metal" = "рунный металл",
	"brass" = "латунь",
	"bronze" = "бронза",
	"paper" = "бумага",
	"cardboard" = "картон",
	"bone" = "кость",
	"bamboo" = "бамбук",
	"rigid material" = "твёрдый материал",
))

/// Лист-словарь для examine string'а материалов в родительном падеже
GLOBAL_LIST_INIT(mat_ru_genitive, list(
    "iron" = "железа",
    "glass" = "стекла",
    "plasma" = "плазмы",
    "gold" = "золота",
    "silver" = "серебра",
    "diamond" = "алмазов",
    "uranium" = "урана",
    "titanium" = "титана",
    "plasma glass" = "плазменного стекла",
    "reinforced glass" = "закалённого стекла",
    "bluespace crystal" = "блюспейс-кристаллов",
    "bananium" = "бананиума",
	"runite" = "рунита",
	"plastic" = "пластика",
	"biomass" = "биомассы",
	"wood" = "дерева",
	"adamantine" = "адамантина",
	"mythril" = "мифрила",
	"sand" = "песка",
	"sandstone" = "песчаника",
	"snow" = "снега",
	"runed metal" = "рунного металла",
	"brass" = "латуни",
	"bronze" = "бронзы",
	"paper" = "бумаги",
	"cardboard" = "картона",
	"bone" = "кости",
	"bamboo" = "бамбука",
	"rigid material" = "твёрдого материала",
))

/// Лист-словарь для examine string'а бюджетов

GLOBAL_LIST_INIT(budget_ru_nominative, list(
	"civil budget" = "Гражданский бюджет",
	"engineering budget" = "Бюджет инженерного отдела",
	"scientific budget" = "Бюджет научного отдела",
	"medical budget" = "Бюджет медицинского отдела",
	"service budget" = "Бюджет отдела сервиса",
	"cargo budget" = "Бюджет отдела карго",
	"defense budget" = "Бюджет службы безопасности",
))

GLOBAL_LIST_INIT(budget_ru_genitive, list(
	"civil budget" = "гражданского отдела",
	"engineering budget" = "инженерного отдела",
	"scientific budget" = "научного отдела",
	"medical budget" = "медицинского отдела",
	"service budget" = "отдела сервиса",
	"cargo budget" = "отдела карго",
	"defense budget" = "отдела службы безопасности",
))
