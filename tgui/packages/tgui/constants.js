/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

// UI states, which are mirrored from the BYOND code.
export const UI_INTERACTIVE = 2;
export const UI_UPDATE = 1;
export const UI_DISABLED = 0;
export const UI_CLOSE = -1;

// All game related colors are stored here
export const COLORS = {
  // Department colors
  department: {
    captain: '#c06616',
    security: '#e74c3c',
    medbay: '#3498db',
    science: '#9b59b6',
    engineering: '#f1c40f',
    cargo: '#f39c12',
    centcom: '#00c100',
    other: '#c38312',
  },
  // Damage type colors
  damageType: {
    oxy: '#3498db',
    toxin: '#2ecc71',
    burn: '#e67e22',
    brute: '#e74c3c',
  },
  // reagent / chemistry related colours
  reagent: {
    acidicbuffer: "#fbc314",
    basicbuffer: "#3853a4",
  },
};

// Colors defined in CSS
export const CSS_COLORS = [
  'black',
  'white',
  'red',
  'orange',
  'yellow',
  'olive',
  'green',
  'teal',
  'blue',
  'violet',
  'purple',
  'pink',
  'brown',
  'grey',
  'good',
  'average',
  'bad',
  'label',
];

/* IF YOU CHANGE THIS KEEP IT IN SYNC WITH CHAT CSS */
export const RADIO_CHANNELS = [
  {
    name: 'Syndicate',
    freq: 1213,
    color: '#8f4a4b',
  },
  {
    name: 'InteQ',
    freq: 1207,
    color: '#e58200',
  },
  {
    name: 'Illegal',
    freq: 1208,
    color: '#30300',
  },
  {
    name: 'Solar Federation',
    freq: 1244,
    color: '#3434fd',
  },
  {
    name: 'New Russian Empire',
    freq: 1222,
    color: '#ff4444',
  },
  {
    name: 'Tarkoff',
    freq: 1243,
    color: '#8f4a4b',
  },
  {
    name: 'Syndicate DS-1',
    freq: 1209,
    color: '#8f4a4b',
  },
  {
    name: 'Syndicate DS-2',
    freq: 1210,
    color: '#8f4a4b',
  },
  {
    name: 'Red Team',
    freq: 1215,
    color: '#ff4444',
  },
  {
    name: 'Blue Team',
    freq: 1217,
    color: '#3434fd',
  },
  {
    name: 'Green Team',
    freq: 1219,
    color: '#34fd34',
  },
  {
    name: 'Yellow Team',
    freq: 1221,
    color: '#fdfd34',
  },
  {
    name: 'CentCom',
    freq: 1337,
    color: '#2681a5',
  },
  {
    name: 'Supply',
    freq: 1347,
    color: '#b88646',
  },
  {
    name: 'Service',
    freq: 1349,
    color: '#6ca729',
  },
  {
    name: 'Science',
    freq: 1351,
    color: '#c68cfa',
  },
  {
    name: 'Command',
    freq: 1353,
    color: '#fcdf03',
  },
  {
    name: 'Law',
    freq: 1415,
    color: '#ff69d7',
  },
  {
    name: 'Medical',
    freq: 1355,
    color: '#57b8f0',
  },
  {
    name: 'Engineering',
    freq: 1357,
    color: '#f37746',
  },
  {
    name: 'Security',
    freq: 1359,
    color: '#dd3535',
  },
  {
    name: 'AI Private',
    freq: 1447,
    color: '#d65d95',
  },
  {
    name: 'Common',
    freq: 1459,
    color: '#1ecc43',
  },
];

// Все статические газы игры (/datum/gas в code/modules/atmospherics/auxgm).
// Идентификаторы совпадают с #define GAS_* из code/__DEFINES/atmospherics.dm.
// `color` — имя класса из CSS_COLORS, произвольный CSS сюда класть нельзя.
const GASES = [
  {
    'id': 'o2',
    'name': 'Oxygen',
    'label': 'O₂',
    'label_ru': 'Кислород',
    'color': 'blue',
  },
  {
    'id': 'n2',
    'name': 'Nitrogen',
    'label': 'N₂',
    'label_ru': 'Азот',
    'color': 'red',
  },
  {
    'id': 'co2',
    'name': 'Carbon Dioxide',
    'label': 'CO₂',
    'label_ru': 'Углекислота',
    'color': 'grey',
  },
  {
    'id': 'plasma',
    'name': 'Plasma',
    'label': 'Plasma',
    'label_ru': 'Плазма',
    'color': 'pink',
  },
  {
    'id': 'water_vapor',
    'name': 'Water Vapor',
    'label': 'H₂O',
    'label_ru': 'Водяной пар',
    'color': 'grey',
  },
  {
    'id': 'nob',
    'name': 'Hyper-noblium',
    'label': 'Hyper-nob',
    'label_ru': 'Гипер-ноблий',
    'color': 'teal',
  },
  {
    'id': 'n2o',
    'name': 'Nitrous Oxide',
    'label': 'N₂O',
    'label_ru': 'Веселящий газ',
    'color': 'red',
  },
  {
    'id': 'no',
    'name': 'Nitric Oxide',
    'label': 'NO',
    'label_ru': 'Оксид азота',
    'color': 'orange',
  },
  {
    'id': 'no2',
    'name': 'Nitryl',
    'label': 'NO₂',
    'label_ru': 'Нитрил',
    'color': 'brown',
  },
  {
    'id': 'tritium',
    'name': 'Tritium',
    'label': 'Tritium',
    'label_ru': 'Тритий',
    'color': 'green',
  },
  {
    'id': 'bz',
    'name': 'BZ',
    'label': 'BZ',
    'label_ru': 'БЗ',
    'color': 'purple',
  },
  {
    'id': 'stim',
    'name': 'Stimulum',
    'label': 'Stimulum',
    'label_ru': 'Стимулум',
    'color': 'average',
  },
  {
    'id': 'pluox',
    'name': 'Pluoxium',
    'label': 'Pluoxium',
    'label_ru': 'Плюоксий',
    'color': 'label',
  },
  {
    'id': 'miasma',
    'name': 'Miasma',
    'label': 'Miasma',
    'label_ru': 'Миазма',
    'color': 'olive',
  },
  {
    'id': 'hydrogen',
    'name': 'Hydrogen',
    'label': 'H₂',
    'label_ru': 'Водород',
    'color': 'white',
  },
  {
    'id': 'methane',
    'name': 'Methane',
    'label': 'CH₄',
    'label_ru': 'Метан',
    'color': 'grey',
  },
  {
    'id': 'methyl_bromide',
    'name': 'Methyl Bromide',
    'label': 'CH₃Br',
    'label_ru': 'Бромистый метил',
    'color': 'brown',
  },
  {
    'id': 'qcd',
    'name': 'Quark Matter',
    'label': 'QGP',
    'label_ru': 'Кварковая материя',
    'color': 'violet',
  },
  {
    'id': 'bromine',
    'name': 'Bromine',
    'label': 'Br₂',
    'label_ru': 'Бром',
    'color': 'brown',
  },
  {
    'id': 'ammonia',
    'name': 'Ammonia',
    'label': 'NH₃',
    'label_ru': 'Аммиак',
    'color': 'yellow',
  },
  {
    'id': 'helium',
    'name': 'Helium',
    'label': 'He',
    'label_ru': 'Гелий',
    'color': 'label',
  },
  {
    'id': 'freon',
    'name': 'Freon',
    'label': 'Freon',
    'label_ru': 'Фреон',
    'color': 'teal',
  },
  {
    'id': 'halon',
    'name': 'Halon',
    'label': 'Halon',
    'label_ru': 'Галон',
    'color': 'green',
  },
  {
    'id': 'antinoblium',
    'name': 'Antinoblium',
    'label': 'Anti-nob',
    'label_ru': 'Антиноблий',
    'color': 'violet',
  },
  {
    'id': 'proto_nitrate',
    'name': 'Proto Nitrate',
    'label': 'Proto-nitrate',
    'label_ru': 'Прото-нитрат',
    'color': 'orange',
  },
  {
    'id': 'zauker',
    'name': 'Zauker',
    'label': 'Zauker',
    'label_ru': 'Заукер',
    'color': 'good',
  },
  {
    'id': 'healium',
    'name': 'Healium',
    'label': 'Healium',
    'label_ru': 'Хилий',
    'color': 'pink',
  },
  {
    'id': 'nitrium',
    'name': 'Nitrium',
    'label': 'Nitrium',
    'label_ru': 'Нитрий',
    'color': 'purple',
  },
  {
    'id': 'pyronite',
    'name': 'Pyronite',
    'label': 'Pyronite',
    'label_ru': 'Пиронит',
    'color': 'bad',
  },
  {
    'id': 'fluxin',
    'name': 'Fluxin',
    'label': 'Fluxin',
    'label_ru': 'Флюксин',
    'color': 'teal',
  },
];

export const getGasFromId = gasId => {
  const gasSearchString = String(gasId).toLowerCase();
  return GASES.find(gas => gas.id === gasSearchString
    || gas.name.toLowerCase() === gasSearchString);
};

export const getGasLabel = (gasId, fallbackValue) => {
  const gas = getGasFromId(gasId);
  return gas && gas.label
    || fallbackValue
    || gasId;
};

/** Словесное название газа на языке интерфейса. */
export const getGasName = (gasId, fallbackValue) => {
  const gas = getGasFromId(gasId);
  return gas && gas.label_ru
    || fallbackValue
    || gasId;
};

export const getGasColor = gasId => {
  const gas = getGasFromId(gasId);
  return gas && gas.color;
};
