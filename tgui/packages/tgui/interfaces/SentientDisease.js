import { Fragment } from 'inferno';

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Icon,
  NoticeBox,
  ProgressBar,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const transmissionPaths = new Set([
  '/datum/disease_ability/symptom/mild/cough',
  '/datum/disease_ability/symptom/mild/sneeze',
  '/datum/disease_ability/symptom/medium/shedding',
  '/datum/disease_ability/symptom/medium/viraladaptation',
  '/datum/disease_ability/symptom/medium/viralevolution',
  '/datum/disease_ability/symptom/medium/itching',
  '/datum/disease_ability/symptom/medium/undead_adaptation',
  '/datum/disease_ability/symptom/medium/heal/weight_loss',
  '/datum/disease_ability/symptom/powerful/inorganic_adaptation',
]);

const abilityLocalization = {};

Object.assign(abilityLocalization, {
  '/datum/disease_ability/action/cough': {
    name: 'Контролируемый кашель',
    short: 'Заставляет текущего носителя кашлять и распространять инфекцию вокруг себя.',
    long: 'Форсирует сильный кашель у отслеживаемого носителя. Заражение проходит в радиусе двух метров даже при слабой заразности штамма.',
    icon: 'lungs',
  },
  '/datum/disease_ability/action/sneeze': {
    name: 'Контролируемое чихание',
    short: 'Принуждает текущего носителя чихнуть в направлении перед собой.',
    long: 'Заставляет отслеживаемого носителя чихнуть с усилением. Заражение проходит конусом до четырёх метров перед целью.',
    icon: 'wind',
  },
  '/datum/disease_ability/action/infect': {
    name: 'Заражённые выделения',
    short: 'Делает предметы и поверхности носителя временно заразными.',
    long: 'Носитель начинает выделять инфекционный материал. Одежда, пол и удерживаемые предметы становятся источником заражения примерно на полминуты.',
    icon: 'biohazard',
  },
  '/datum/disease_ability/symptom/mild/cough': {
    name: 'Непроизвольный кашель',
    short: 'Заражённые периодически кашляют.',
    long: 'Носители начинают время от времени кашлять. При достаточной заразности это помогает естественному распространению штамма.',
    icon: 'lungs',
  },
  '/datum/disease_ability/symptom/mild/sneeze': {
    name: 'Непроизвольное чихание',
    short: 'Заражённые периодически чихают.',
    long: 'Носители время от времени чихают, помогая передаче болезни и усиливая заразность ценой скрытности.',
    icon: 'wind',
  },
  '/datum/disease_ability/symptom/medium/shedding': {
    name: 'Линька',
    short: 'Заражённые начинают терять волосы и частицы кожи.',
    long: 'Штамм провоцирует сильное выпадение волос и шелушение. Это создаёт дополнительные следы заражения и делает болезнь заметнее.',
    icon: 'wind',
  },
  '/datum/disease_ability/symptom/medium/beard': {
    name: 'Гипертрофия бороды',
    short: 'У всех носителей бурно растёт борода.',
    long: 'Вирус вмешивается в рост волосяных фолликулов и быстро превращает заражённых в обладателей роскошной бороды.',
    icon: 'user',
  },
  '/datum/disease_ability/symptom/medium/hallucigen': {
    name: 'Галлюциногенез',
    short: 'Вызывает галлюцинации у заражённых.',
    long: 'Нервная система носителей начинает выдавать ложные образы и звуки. Симптом мешает ориентации, но делает штамм менее устойчивым.',
    icon: 'eye',
  },
  '/datum/disease_ability/symptom/medium/choking': {
    name: 'Удушающие спазмы',
    short: 'Провоцирует приступы удушья.',
    long: 'Носители начинают задыхаться и судорожно хватать воздух. Симптом опасен, но ухудшает общую распространяемость штамма.',
    icon: 'lungs',
  },
  '/datum/disease_ability/symptom/medium/confusion': {
    name: 'Спутанность сознания',
    short: 'Снижает ориентацию и мешает координации.',
    long: 'Болезнь нарушает работу когнитивных центров. Носители теряются, путаются в действиях и медленнее реагируют на угрозы.',
    icon: 'brain',
  },
  '/datum/disease_ability/symptom/medium/vomit': {
    name: 'Рвотный рефлекс',
    short: 'Вызывает приступы рвоты.',
    long: 'Штамм раздражает пищеварительную систему. Рвота ослабляет носителей, но дополнительно помогает распространять инфекцию.',
    icon: 'biohazard',
  },
  '/datum/disease_ability/symptom/medium/voice_change': {
    name: 'Искажение голоса',
    short: 'Меняет голос заражённых.',
    long: 'Вирус вмешивается в работу голосовых связок и дыхательной системы, из-за чего речь становится чужой и сбивает коммуникацию.',
    icon: 'comment',
  },
  '/datum/disease_ability/symptom/medium/visionloss': {
    name: 'Деградация зрения',
    short: 'Постепенно повреждает глаза и ведёт к слепоте.',
    long: 'Симптом разрушает зрительный аппарат носителя. На поздних стадиях вызывает серьёзную потерю зрения и делает болезнь крайне заметной.',
    icon: 'eye',
  },
  '/datum/disease_ability/symptom/medium/deafness': {
    name: 'Глухота',
    short: 'Лишает заражённых слуха.',
    long: 'Вирус повреждает слуховой нерв и внутреннее ухо. Носители начинают хуже слышать, а затем полностью теряют слух.',
    icon: 'bell-slash',
  },
  '/datum/disease_ability/symptom/medium/fever': {
    name: 'Лихорадка',
    short: 'Поднимает температуру тела и изматывает носителя.',
    long: 'Штамм ускоряет внутренний нагрев организма. Это ослабляет заражённых и может подготовить почву для более опасных симптомов.',
    icon: 'fire',
  },
  '/datum/disease_ability/symptom/medium/shivering': {
    name: 'Озноб',
    short: 'Вызывает сильную дрожь и потерю тепла.',
    long: 'Носители начинают дрожать и терять контроль над телом. Симптом мешает действиям и дополнительно истощает организм.',
    icon: 'snowflake',
  },
  '/datum/disease_ability/symptom/medium/headache': {
    name: 'Головная боль',
    short: 'Постоянно давит на нервную систему носителя.',
    long: 'Вирус провоцирует болезненные спазмы и давление в голове. Симптом мешает сосредоточиться и снижает общую эффективность жертвы.',
    icon: 'brain',
  },
});

const tierLabels = {
  weak: 'Слабые',
  standard: 'Основные',
  strong: 'Критические',
  support: 'Поддержка',
  support_advanced: 'Поддержка+',
  action: 'Управляемые',
};

const tierColors = {
  weak: '#f2b9c1',
  standard: '#ff7f92',
  strong: '#ff4c61',
  support: '#ffd977',
  support_advanced: '#ffe9a6',
  action: '#ff99c4',
  unknown: '#f3dce1',
};

const hexBackground = {
  backgroundImage: `
    radial-gradient(circle at 20% 18%, rgba(255, 214, 219, 0.24) 0%, rgba(255, 214, 219, 0) 25%),
    radial-gradient(circle at 82% 74%, rgba(255, 148, 165, 0.18) 0%, rgba(255, 148, 165, 0) 24%),
    repeating-linear-gradient(60deg, rgba(255, 255, 255, 0.05) 0 1px, transparent 1px 64px),
    repeating-linear-gradient(-60deg, rgba(255, 255, 255, 0.05) 0 1px, transparent 1px 64px),
    repeating-linear-gradient(0deg, rgba(255, 255, 255, 0.04) 0 1px, transparent 1px 36px),
    linear-gradient(180deg, rgba(124, 0, 18, 0.94) 0%, rgba(46, 0, 8, 0.97) 100%)
  `,
  backgroundBlendMode: 'screen, screen, normal, normal, normal, normal',
};

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
const statRatio = (value) => clamp((value + 6) / 18, 0, 1);
const healthRatio = (health, maxHealth) => {
  if (!maxHealth || maxHealth <= 0) {
    return 0;
  }
  return clamp(health / maxHealth, 0, 1);
};
const formatTime = (deciseconds) => `${Math.max(0, Math.ceil((deciseconds || 0) / 10))}с`;
const pathHasToken = (ability, token) => (ability.path || '').includes(token);
const countPurchasedAbilities = (abilities, predicate) => abilities.reduce(
  (total, ability) => total + Number(ability.purchased && predicate(ability)),
  0,
);
const hasPurchasedAbility = (abilities, predicate) => abilities.some(
  (ability) => ability.purchased && predicate(ability),
);
const profileNoise = (seed, index, offset = 0) => (
  Math.sin((seed * 0.071) + (index * 1.618) + offset) + 1
) / 2;

const deriveVirusVisualProfile = (abilities = [], stats = {}) => {
  const resistanceLevel = statRatio(stats.resistance || 0);
  const stealthLevel = statRatio(stats.stealth || 0);
  const stageLevel = statRatio(stats.stage_speed || 0);
  const transmissionLevel = statRatio(stats.transmission || 0);
  const purchasedCount = countPurchasedAbilities(abilities, () => true);

  const transmissionMutations = countPurchasedAbilities(abilities, (ability) => (
    ability.viewTab === 'transmission'
  ));
  const supportMutations = countPurchasedAbilities(abilities, (ability) => (
    ability.tier === 'support'
    || ability.tier === 'support_advanced'
    || pathHasToken(ability, '/heal/')
  ));
  const aggressiveMutations = countPurchasedAbilities(abilities, (ability) => (
    ability.tier === 'strong'
    || pathHasToken(ability, 'fire')
    || pathHasToken(ability, 'flesh_')
    || pathHasToken(ability, 'asphyxiation')
    || pathHasToken(ability, 'alkali')
  ));
  const healingMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, '/heal/')
    || pathHasToken(ability, 'youth')
    || pathHasToken(ability, 'nano_boost')
  ));
  const stealthMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, 'viraladaptation')
    || pathHasToken(ability, 'disfiguration')
    || pathHasToken(ability, 'polyvitiligo')
    || pathHasToken(ability, 'voice_change')
  ));
  const biotechMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, 'nano_')
    || pathHasToken(ability, 'inorganic_adaptation')
  ));
  const chaoticMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, 'genetic_mutation')
    || pathHasToken(ability, 'monkey_transform')
  ));
  const necroticMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, 'flesh_')
    || pathHasToken(ability, 'asphyxiation')
    || pathHasToken(ability, 'alkali')
    || pathHasToken(ability, 'undead_adaptation')
  ));
  const undeadMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, 'undead_adaptation')
  ));
  const adaptiveMutations = countPurchasedAbilities(abilities, (ability) => (
    pathHasToken(ability, 'viralevolution')
    || pathHasToken(ability, 'viraladaptation')
    || pathHasToken(ability, 'genetic_mutation')
  ));

  const seed = abilities.reduce((sum, ability, index) => (
    sum + (((ability.path || '').length + index + 3) * (ability.purchased ? 3 : 1))
  ), 73);

  const shellLayers = clamp(
    2 + Math.round(resistanceLevel * 2.2) + Math.min(1, biotechMutations),
    2,
    5,
  );
  const armorSegments = clamp(
    5 + Math.round(resistanceLevel * 8) + (biotechMutations * 2),
    5,
    18,
  );
  const spikeCount = clamp(
    6 + Math.round(transmissionLevel * 10) + (transmissionMutations * 2) + aggressiveMutations,
    6,
    26,
  );
  const spikeLength = 14 + (transmissionLevel * 18) + (aggressiveMutations * 2) - (stealthLevel * 4);
  const tendrilCount = clamp(
    Math.round((stageLevel * 5) + (transmissionMutations * 0.7) + chaoticMutations + undeadMutations),
    0,
    10,
  );
  const nodeCount = clamp(
    3 + Math.round(stageLevel * 3.5) + supportMutations + healingMutations,
    3,
    12,
  );
  const haloStrength = clamp(
    0.18 + (stealthLevel * 0.34) + (supportMutations * 0.025) + (healingMutations * 0.03),
    0.18,
    0.76,
  );
  const necrosis = clamp((necroticMutations * 0.16) + (aggressiveMutations * 0.04), 0, 1);
  const supportBloom = clamp((healingMutations * 0.12) + (supportMutations * 0.08), 0, 1);
  const stealthField = clamp((stealthLevel * 0.85) + (stealthMutations * 0.08), 0, 1);
  const biotech = clamp(
    (biotechMutations * 0.2)
    + (hasPurchasedAbility(abilities, (ability) => pathHasToken(ability, 'inorganic_adaptation')) ? 0.25 : 0),
    0,
    1,
  );
  const chaos = clamp((chaoticMutations * 0.2) + (adaptiveMutations * 0.08), 0, 1);

  let signature = 'адаптивная сигнатура';
  if (necrosis > 0.42) {
    signature = 'некротическая сигнатура';
  } else if (biotech > 0.35) {
    signature = 'техносимбиотическая сигнатура';
  } else if (stealthField > 0.62) {
    signature = 'латентная сигнатура';
  } else if (supportBloom > 0.42) {
    signature = 'регенеративная сигнатура';
  } else if (chaos > 0.4) {
    signature = 'хаотическая сигнатура';
  }

  return {
    seed,
    purchasedCount,
    transmissionLevel,
    resistanceLevel,
    stealthLevel,
    stageLevel,
    shellLayers,
    armorSegments,
    spikeCount,
    spikeLength,
    tendrilCount,
    nodeCount,
    haloStrength,
    necrosis,
    supportBloom,
    stealthField,
    biotech,
    chaos,
    membraneRadius: 58 + (resistanceLevel * 10) + aggressiveMutations,
    coreRadius: 24 + (stageLevel * 7) + (supportBloom * 5) - (stealthLevel * 4),
    elongation: 1 + ((stageLevel - resistanceLevel) * 0.18) + (chaos * 0.06),
    rotation: ((biotech - necrosis) * 16) + (chaos * 12),
    signature,
    shellLabel: resistanceLevel > 0.72
      ? 'бронекапсула'
      : (resistanceLevel > 0.48 ? 'слоистая' : 'тонкая'),
    spikeLabel: spikeCount > 18
      ? 'рой шипов'
      : (spikeCount > 12 ? 'плотные шипы' : 'редкие шипы'),
    coreLabel: stageLevel > 0.68
      ? 'ускоренное'
      : (supportBloom > 0.35 ? 'стабильное' : 'спокойное'),
  };
};

Object.assign(abilityLocalization, {
  '/datum/disease_ability/symptom/medium/nano_boost': {
    name: 'Нанитная подпитка',
    short: 'Помогает существующим нанитам носителя.',
    long: 'Штамм синергирует с нанитами внутри организма и частично усиливает их полезные эффекты. Это поддерживающая ветка развития.',
    icon: 'bolt',
  },
  '/datum/disease_ability/symptom/medium/nano_destroy': {
    name: 'Нанитное разрушение',
    short: 'Нарушает работу нанитов у заражённых.',
    long: 'Вирус начинает конфликтовать с нанитами в крови и повреждает их поведение. Хорошо против технологически усиленных целей.',
    icon: 'bolt',
  },
  '/datum/disease_ability/symptom/medium/viraladaptation': {
    name: 'Вирусная самоадаптация',
    short: 'Повышает скрытность и стойкость штамма ценой темпа.',
    long: 'Вирус мимикрирует под обычные клетки организма. Его труднее заметить и уничтожить, но скорость развития стадий снижается.',
    icon: 'dna',
  },
  '/datum/disease_ability/symptom/medium/viralevolution': {
    name: 'Эволюционное ускорение',
    short: 'Разгоняет скорость стадий и передачу ценой скрытности.',
    long: 'Штамм жертвует маскировкой ради максимальной скорости эволюции и передачи между носителями. Подходит для агрессивного распространения.',
    icon: 'dna',
  },
  '/datum/disease_ability/symptom/medium/polyvitiligo': {
    name: 'Поливитилиго',
    short: 'Меняет пигментацию кожи заражённых.',
    long: 'Кожа носителей резко меняет цвет и покрывается пятнами. Симптом в первую очередь демаскирует инфекцию.',
    icon: 'user',
  },
  '/datum/disease_ability/symptom/medium/disfiguration': {
    name: 'Обезображивание',
    short: 'Сильно меняет внешность заражённых.',
    long: 'Вирус вмешивается в структуру тканей лица и кожи, делая носителей труднее узнаваемыми и заметно уродуя их.',
    icon: 'user',
  },
  '/datum/disease_ability/symptom/medium/itching': {
    name: 'Зуд',
    short: 'Провоцирует постоянное раздражение кожи.',
    long: 'Заражённые начинают расчёсывать кожу. Симптом повышает почти все параметры штамма, кроме скрытности.',
    icon: 'hand-paper',
  },
  '/datum/disease_ability/symptom/medium/dizzy': {
    name: 'Головокружение',
    short: 'Шатает носителя и ухудшает восприятие.',
    long: 'Вестибулярная система начинает сбоить. Носители видят мир неустойчиво и теряют контроль над движением.',
    icon: 'compass',
  },
  '/datum/disease_ability/symptom/medium/alkali': {
    name: 'Щелочное возгорание',
    short: 'Может поджечь носителя химической реакцией.',
    long: 'Ткани заражённого становятся химически нестабильными и вспыхивают при развитии симптома. Очень агрессивная ветка.',
    icon: 'fire',
  },
  '/datum/disease_ability/symptom/medium/asphyxiation': {
    name: 'Асфиксия',
    short: 'Медленно душит носителя и может убить его.',
    long: 'Сильный дыхательный коллапс вызывает удушье вплоть до летального исхода на поздних стадиях развития болезни.',
    icon: 'skull',
  },
  '/datum/disease_ability/symptom/medium/undead_adaptation': {
    name: 'Адаптация к нежити',
    short: 'Позволяет работать внутри мёртвых тел и заражать нежить.',
    long: 'Штамм перестраивается так, чтобы сохранять активность в трупах и захватывать носителей, которые обычно неподходящи для обычной инфекции.',
    icon: 'skull',
  },
  '/datum/disease_ability/symptom/medium/heal/weight_loss': {
    name: 'Истощение',
    short: 'Снижает массу тела и мешает восстановлению питания.',
    long: 'Носитель стремительно худеет и почти перестаёт получать нормальную пользу от еды. Ослабленные цели легче распространяют болезнь.',
    icon: 'weight',
  },
  '/datum/disease_ability/symptom/medium/heal/sensory_restoration': {
    name: 'Восстановление чувств',
    short: 'Регенерирует глаза и уши носителя.',
    long: 'Поддерживающий путь развития. Штамм постепенно чинит органы чувств, возвращая зрение и слух заражённым.',
    icon: 'eye',
  },
  '/datum/disease_ability/symptom/medium/heal/mind_restoration': {
    name: 'Восстановление разума',
    short: 'Стабилизирует психику и травмы мозга.',
    long: 'Инфекция начинает работать как грубая нейрорегенерация. Подходит для мирного или маскирующего штамма поддержки.',
    icon: 'brain',
  },
  '/datum/disease_ability/symptom/powerful/fire': {
    name: 'Пирогенная вспышка',
    short: 'Сильно нагревает носителя и поджигает его.',
    long: 'Мощный пирогенный каскад превращает заражённых в источник открытого огня. Симптом очень заметный и крайне опасный.',
    icon: 'fire',
  },
  '/datum/disease_ability/symptom/powerful/flesh_eating': {
    name: 'Пожирание плоти',
    short: 'Разрушает ткани и наносит тяжёлый урон.',
    long: 'Штамм начинает буквально разъедать плоть изнутри. Носители быстро теряют здоровье и нуждаются в срочном лечении.',
    icon: 'skull',
  },
  '/datum/disease_ability/symptom/powerful/flesh_death': {
    name: 'Некроз тканей',
    short: 'Вызывает тяжёлое гниение плоти и может убить носителя.',
    long: 'На поздних стадиях болезнь переводит ткани в некротическое состояние. Один из самых смертельных и заметных симптомов.',
    icon: 'skull',
  },
});

Object.assign(abilityLocalization, {
  '/datum/disease_ability/symptom/powerful/genetic_mutation': {
    name: 'Генетическая мутация',
    short: 'Вызывает случайные мутации у носителей.',
    long: 'Инфекция вмешивается в генетический код и заставляет организм непредсказуемо меняться. Хорошо подходит для хаотичных штаммов.',
    icon: 'dna',
  },
  '/datum/disease_ability/symptom/powerful/monkey_transform': {
    name: 'Обезьяний штамм',
    short: 'На финальной стадии превращает людей в обезьян.',
    long: 'Классическое, но очень дорогое направление. На последней стадии человеческие носители полностью трансформируются в обезьян.',
    icon: 'paw',
  },
  '/datum/disease_ability/symptom/powerful/inorganic_adaptation': {
    name: 'Неорганическая адаптация',
    short: 'Помогает инфицировать необычные и неорганические цели.',
    long: 'Штамм учится существовать в менее привычных биологических условиях и расширяет диапазон пригодных носителей.',
    icon: 'cog',
  },
  '/datum/disease_ability/symptom/powerful/narcolepsy': {
    name: 'Нарколепсия',
    short: 'Резко усыпляет носителей.',
    long: 'Инфекция вмешивается в циклы бодрствования и может неожиданно отправить носителя в сон в самый неподходящий момент.',
    icon: 'moon',
  },
  '/datum/disease_ability/symptom/powerful/youth': {
    name: 'Вечная юность',
    short: 'Омолаживает носителей и усиливает некоторые параметры болезни.',
    long: 'Необычный поддерживающий симптом. Штамм омолаживает тело, улучшая большинство своих характеристик, кроме передачи.',
    icon: 'sun',
  },
  '/datum/disease_ability/symptom/powerful/heal/starlight': {
    name: 'Конденсация звёздного света',
    short: 'Лечит носителей под прямым звёздным светом.',
    long: 'Вирус перерабатывает звёздный свет в регенеративные химические вещества. Лучше всего снимает токсический урон и помогает выживать в космосе.',
    icon: 'sun',
  },
  '/datum/disease_ability/symptom/powerful/heal/oxygen': {
    name: 'Кислородная переработка',
    short: 'Помогает носителю обходиться с нехваткой воздуха.',
    long: 'Поддерживающий симптом, который снижает зависимость организма от нормального дыхания и помогает переживать кислородное голодание.',
    icon: 'wind',
  },
  '/datum/disease_ability/symptom/powerful/heal/chem': {
    name: 'Токсолиз',
    short: 'Быстро разрушает химикаты в крови носителя.',
    long: 'Штамм начинает агрессивно перерабатывать реагенты в кровотоке. Полезен для самоочищения, но может мешать лечению препаратами.',
    icon: 'flask',
  },
  '/datum/disease_ability/symptom/powerful/heal/metabolism': {
    name: 'Метаболический разгон',
    short: 'Ускоряет обмен веществ и переработку химикатов.',
    long: 'Организм носителя начинает работать на повышенных оборотах. Химикаты усваиваются быстрее, но голод приходит заметно раньше.',
    icon: 'heart',
  },
  '/datum/disease_ability/symptom/powerful/heal/dark': {
    name: 'Ночная регенерация',
    short: 'В темноте восстанавливает тело носителя.',
    long: 'Штамм использует низкую освещённость для быстрого ремонта тканей. Особенно эффективен против физического урона.',
    icon: 'moon',
  },
  '/datum/disease_ability/symptom/powerful/heal/water': {
    name: 'Гидрорегенерация',
    short: 'Лечит носителя во влажной среде или рядом с водой.',
    long: 'Вирус использует воду как катализатор восстановления и помогает телу выживать там, где есть достаточная влажность.',
    icon: 'tint',
  },
  '/datum/disease_ability/symptom/powerful/heal/plasma': {
    name: 'Плазменное питание',
    short: 'Позволяет использовать плазму для восстановления.',
    long: 'Редкая и рискованная адаптация. Штамм начинает перерабатывать плазму в ресурс для выживания и регенерации носителя.',
    icon: 'bolt',
  },
  '/datum/disease_ability/symptom/powerful/heal/radiation': {
    name: 'Радиационная регенерация',
    short: 'Использует радиацию для лечения носителя.',
    long: 'Вирус начинает обращать радиационный фон себе на пользу. Чем опаснее среда, тем лучше поддерживается организм носителя.',
    icon: 'radiation',
  },
  '/datum/disease_ability/symptom/powerful/heal/coma': {
    name: 'Исцеляющая кома',
    short: 'Погружает тяжело раненых носителей в лечебную кому.',
    long: 'При серьёзных повреждениях носитель может впасть в кому, во время которой болезнь переводит силы организма на экстренное восстановление.',
    icon: 'moon',
  },
});

const localizeAbility = (ability) => {
  const localized = abilityLocalization[ability.path] || {};
  return {
    ...ability,
    displayName: localized.name || ability.name,
    shortDesc: localized.short || ability.short_desc || 'Нет описания.',
    longDesc: localized.long || ability.long_desc || localized.short || ability.short_desc || 'Нет описания.',
    icon: localized.icon || 'virus',
    viewTab: ability.tier === 'action' || transmissionPaths.has(ability.path)
      ? 'transmission'
      : 'symptoms',
  };
};

const sortAbilities = (a, b) => (
  Number(b.purchased) - Number(a.purchased)
  || a.unlock - b.unlock
  || a.cost - b.cost
  || a.displayName.localeCompare(b.displayName)
);

const panelStyle = {
  border: '1px solid rgba(255, 48, 76, 0.65)',
  background: 'linear-gradient(180deg, rgba(74, 0, 12, 0.88) 0%, rgba(32, 0, 8, 0.92) 100%)',
  boxShadow: 'inset 0 0 0 1px rgba(255, 194, 204, 0.08), 0 0 28px rgba(120, 0, 18, 0.35)',
};

const Frame = (props) => {
  const { title, children, style } = props;
  return (
    <Box
      p={1}
      style={{
        ...panelStyle,
        ...style,
      }}>
      {!!title && (
        <Box
          mb={1}
          px={1}
          py={0.4}
          bold
          style={{
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            color: '#fff1f4',
            borderBottom: '1px solid rgba(255, 76, 102, 0.45)',
            background: 'linear-gradient(90deg, rgba(255, 72, 98, 0.12), rgba(255, 72, 98, 0))',
          }}>
          {title}
        </Box>
      )}
      {children}
    </Box>
  );
};

const FooterStat = (props) => {
  const { label, value, color, content } = props;
  return (
    <Box
      p={0.8}
      style={{
        ...panelStyle,
        minWidth: '170px',
      }}>
      <Box
        mb={0.5}
        style={{
          textTransform: 'uppercase',
          letterSpacing: '0.08em',
          color: '#ffe0e6',
          fontSize: '0.82rem',
        }}>
        {label}
      </Box>
      {content || (
        <ProgressBar
          value={value}
          color={color}
          style={{
            background: 'rgba(255, 255, 255, 0.06)',
          }}
        />
      )}
    </Box>
  );
};

const HexAbilityCard = (props) => {
  const {
    ability,
    selected,
    onSelect,
    onBuy,
    onRefund,
  } = props;
  const color = tierColors[ability.tier] || tierColors.unknown;
  const actionText = ability.purchased
    ? (ability.can_refund ? 'Вернуть' : 'Установлено')
    : (ability.can_buy ? 'Развить' : 'Заблокировано');

  return (
    <div
      onClick={onSelect}
      style={{
        position: 'relative',
        minHeight: '178px',
        padding: '14px 14px 12px',
        clipPath: 'polygon(24% 0%, 76% 0%, 100% 50%, 76% 100%, 24% 100%, 0% 50%)',
        border: `1px solid ${selected ? '#ffdbe1' : color}`,
        background: ability.purchased
          ? 'linear-gradient(180deg, rgba(255, 88, 110, 0.42) 0%, rgba(124, 0, 18, 0.84) 100%)'
          : 'linear-gradient(180deg, rgba(255, 210, 219, 0.22) 0%, rgba(62, 0, 11, 0.82) 100%)',
        boxShadow: selected
          ? '0 0 0 1px rgba(255, 245, 247, 0.55), 0 0 26px rgba(255, 96, 124, 0.45)'
          : 'inset 0 0 18px rgba(255, 255, 255, 0.08)',
        cursor: 'pointer',
      }}>
      <Box
        textAlign="center"
        mb={0.5}
        style={{
          color,
        }}>
        <Icon name={ability.icon} size={2.3} />
      </Box>
      <Box
        textAlign="center"
        bold
        mb={0.4}
        style={{
          color: '#fff4f6',
          fontSize: '0.93rem',
          lineHeight: 1.2,
          minHeight: '2.3rem',
        }}>
        {ability.displayName}
      </Box>
      <Box
        textAlign="center"
        mb={0.5}
        style={{
          color: '#ffd7df',
          fontSize: '0.77rem',
          minHeight: '2.4rem',
          lineHeight: 1.2,
        }}>
        {ability.shortDesc}
      </Box>
      <Box
        textAlign="center"
        mb={0.6}
        style={{
          color: '#fff0c4',
          fontSize: '0.74rem',
          textTransform: 'uppercase',
          letterSpacing: '0.06em',
        }}>
        {tierLabels[ability.tier] || 'Мутация'} / ДНК {ability.cost} / Порог {ability.unlock}
      </Box>
      <Button
        fluid
        color={ability.purchased ? 'average' : 'bad'}
        disabled={ability.purchased ? !ability.can_refund : !ability.can_buy}
        onClick={(event) => {
          event.stopPropagation();
          if (ability.purchased) {
            onRefund();
          } else {
            onBuy();
          }
        }}>
        {actionText}
      </Button>
    </div>
  );
};

const AbilityDetailPanel = (props) => {
  const { ability, onBuy, onRefund } = props;

  if (!ability) {
    return (
      <Frame title="Выбранная мутация" style={{ minHeight: '360px' }}>
        <NoticeBox>Выберите адаптацию в центральной панели.</NoticeBox>
      </Frame>
    );
  }

  return (
    <Frame title="Выбранная мутация" style={{ minHeight: '360px', marginTop: '12px' }}>
      <Box
        mb={1.2}
        p={1}
        textAlign="center"
        style={{
          border: '1px solid rgba(255, 110, 134, 0.35)',
          background: `
            radial-gradient(circle at center, rgba(255, 217, 224, 0.9) 0%, rgba(255, 149, 166, 0.4) 26%, rgba(98, 0, 14, 0.94) 76%),
            linear-gradient(180deg, rgba(255, 255, 255, 0.06), rgba(255, 255, 255, 0))
          `,
          boxShadow: 'inset 0 0 24px rgba(255, 255, 255, 0.08), 0 0 18px rgba(116, 0, 17, 0.28)',
        }}>
        <Box
          mb={0.3}
          style={{
            color: tierColors[ability.tier] || '#ffdbe1',
          }}>
          <Icon name={ability.icon} size={4} />
        </Box>
        <Box
          bold
          style={{
            color: '#fff8fa',
            fontSize: '1.12rem',
          }}>
          {ability.displayName}
        </Box>
        <Box
          mt={0.3}
          style={{
            color: '#ffe2e7',
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            fontSize: '0.78rem',
          }}>
          {tierLabels[ability.tier] || 'Мутация'}
        </Box>
      </Box>

      <Box
        mb={1}
        style={{
          color: '#ffd8df',
          lineHeight: 1.45,
        }}>
        {ability.longDesc}
      </Box>

      <Stack mb={1}>
        <Stack.Item grow>
          <FooterStat
            label="Стоимость"
            content={<Box bold color="average">{ability.cost} ДНК</Box>}
          />
        </Stack.Item>
        <Stack.Item grow>
          <FooterStat
            label="Порог"
            content={<Box bold color="average">{ability.unlock} заражений</Box>}
          />
        </Stack.Item>
      </Stack>

      <Box mb={0.7} color="label">Влияние на штамм</Box>
      <Box mb={0.5}>
        <Box color="label">Стойкость: {ability.resistance}</Box>
        <ProgressBar value={statRatio(ability.resistance)} color="average" />
      </Box>
      <Box mb={0.5}>
        <Box color="label">Скрытность: {ability.stealth}</Box>
        <ProgressBar value={statRatio(ability.stealth)} color="average" />
      </Box>
      <Box mb={0.5}>
        <Box color="label">Скорость стадий: {ability.stage_speed}</Box>
        <ProgressBar value={statRatio(ability.stage_speed)} color="average" />
      </Box>
      <Box mb={1}>
        <Box color="label">Заразность: {ability.transmission}</Box>
        <ProgressBar value={statRatio(ability.transmission)} color="average" />
      </Box>

      <Button
        fluid
        color={ability.purchased ? 'average' : 'bad'}
        disabled={ability.purchased ? !ability.can_refund : !ability.can_buy}
        onClick={() => (ability.purchased ? onRefund() : onBuy())}>
        {ability.purchased
          ? (ability.can_refund ? 'Вернуть мутацию' : 'Мутация установлена')
          : (ability.can_buy ? 'Развить мутацию' : 'Порог не достигнут')}
      </Button>
    </Frame>
  );
};

const VirusMorphologyPanel = (props) => {
  const {
    abilities = [],
    stats = {},
    host,
  } = props;
  const profile = deriveVirusVisualProfile(abilities, stats);
  const shellRx = profile.membraneRadius * (1.08 + (profile.chaos * 0.05));
  const shellRy = shellRx * (0.74 + (profile.elongation * 0.16));
  const coreRx = profile.coreRadius * (1.18 + (profile.chaos * 0.05));
  const coreRy = coreRx * (0.68 + (profile.elongation * 0.18));
  const signatureAccent = profile.necrosis > 0.42
    ? '#ff9b9b'
    : (profile.supportBloom > 0.42
      ? '#ffe4ab'
      : (profile.stealthField > 0.62 ? '#ffeef2' : '#ffc6d0'));
  const summaryText = profile.purchasedCount
    ? `${profile.signature} / активных мутаций: ${profile.purchasedCount}`
    : 'базовая морфология без развитых мутаций';
  const driftDuration = `${clamp(8.8 - (profile.stageLevel * 3.2), 4.2, 8.8).toFixed(1)}s`;
  const pulseDuration = `${clamp(5.6 - (profile.stageLevel * 1.8), 2.4, 5.6).toFixed(1)}s`;
  const orbitDuration = `${clamp(19 - (profile.transmissionLevel * 7), 9, 19).toFixed(1)}s`;
  const scannerDuration = `${clamp(16 - (profile.stealthField * 4), 8, 16).toFixed(1)}s`;
  const flickerDuration = `${clamp(4.6 - (profile.necrosis * 1.6), 2.2, 4.6).toFixed(1)}s`;
  const wobbleAngle = (3 + (profile.chaos * 7)).toFixed(1);
  const metrics = [
    { label: 'Капсула', value: profile.shellLabel, accent: '#ffe4ab' },
    { label: 'Шипы', value: profile.spikeLabel, accent: '#ffb3c2' },
    { label: 'Ядро', value: profile.coreLabel, accent: '#ffd7df' },
    { label: 'Сигнатура', value: profile.signature, accent: signatureAccent },
  ];

  return (
    <Box
      mb={1}
      p={0.7}
      style={{
        border: '1px solid rgba(255, 110, 134, 0.3)',
        background: 'linear-gradient(180deg, rgba(132, 0, 21, 0.26), rgba(45, 0, 9, 0.48))',
      }}>
      <Box
        mb={0.6}
        px={0.7}
        py={0.5}
        style={{
          border: '1px solid rgba(255, 120, 143, 0.18)',
          background: 'linear-gradient(90deg, rgba(255, 108, 129, 0.14), rgba(255, 108, 129, 0))',
        }}>
        <Box
          bold
          style={{
            color: '#fff6f8',
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
          }}>
          Биоскан штамма
        </Box>
        <Box mt={0.2} color="label">
          {host ? `Фокус наблюдения: ${host.name}` : 'Фокус наблюдения: автономный профиль'}
        </Box>
        <Box mt={0.15} style={{ color: '#ffd9e0' }}>
          {summaryText}
        </Box>
      </Box>

      <Box
        p={0.5}
        style={{
          border: '1px solid rgba(255, 112, 136, 0.34)',
          background: `
            radial-gradient(circle at center, rgba(255, 225, 231, 0.22) 0%, rgba(128, 0, 21, 0.3) 30%, rgba(58, 0, 10, 0.9) 76%),
            linear-gradient(180deg, rgba(255, 255, 255, 0.04), rgba(255, 255, 255, 0))
          `,
        }}>
        <svg
          viewBox="0 0 320 320"
          width="100%"
          height="312"
          preserveAspectRatio="xMidYMid meet">
          <defs>
            <radialGradient id="virusScannerBg" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#ffdfe6" stopOpacity="0.28" />
              <stop offset="38%" stopColor="#b60d28" stopOpacity="0.22" />
              <stop offset="72%" stopColor="#5a0510" stopOpacity="0.92" />
              <stop offset="100%" stopColor="#210007" stopOpacity="1" />
            </radialGradient>
            <radialGradient id="virusHalo" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#fff4f6" stopOpacity={0.22 + (profile.haloStrength * 0.35)} />
              <stop offset="58%" stopColor="#ff8ca0" stopOpacity={0.08 + (profile.stealthField * 0.18)} />
              <stop offset="100%" stopColor="#ff6c84" stopOpacity="0" />
            </radialGradient>
            <radialGradient id="virusMembrane" cx="45%" cy="38%" r="65%">
              <stop offset="0%" stopColor="#ffd7df" stopOpacity={0.55 - (profile.stealthField * 0.15)} />
              <stop offset="38%" stopColor="#ff7b93" stopOpacity="0.82" />
              <stop offset="100%" stopColor="#8a0b22" stopOpacity="0.96" />
            </radialGradient>
            <radialGradient id="virusCore" cx="42%" cy="36%" r="70%">
              <stop offset="0%" stopColor="#fff5f7" stopOpacity={0.72 - (profile.necrosis * 0.18)} />
              <stop offset="32%" stopColor="#ff9aab" stopOpacity="0.88" />
              <stop offset="100%" stopColor="#b60d28" stopOpacity="0.98" />
            </radialGradient>
            <radialGradient id="virusNode" cx="50%" cy="50%" r="60%">
              <stop offset="0%" stopColor="#fff6dc" stopOpacity={0.62 + (profile.supportBloom * 0.14)} />
              <stop offset="100%" stopColor="#ff9dad" stopOpacity="0.9" />
            </radialGradient>
            <linearGradient id="virusSpike" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ffd7df" stopOpacity="0.82" />
              <stop offset="100%" stopColor="#c1122f" stopOpacity="0.94" />
            </linearGradient>
          </defs>

          <rect
            x="6"
            y="6"
            width="308"
            height="308"
            rx="18"
            fill="url(#virusScannerBg)"
            stroke="#ff5f78"
            strokeOpacity="0.22"
          />

          {[46, 78, 110, 142, 174, 206, 238, 270].map((position) => (
            <Fragment key={`grid-${position}`}>
              <line
                x1="20"
                y1={position}
                x2="300"
                y2={position}
                stroke="#ff92a5"
                strokeOpacity="0.06"
              />
              <line
                x1={position}
                y1="20"
                x2={position}
                y2="300"
                stroke="#ff92a5"
                strokeOpacity="0.05"
              />
            </Fragment>
          ))}

          <circle cx="160" cy="160" r="112" fill="url(#virusHalo)">
            <animate
              attributeName="r"
              values={`112;${116 + (profile.haloStrength * 10)};112`}
              dur={pulseDuration}
              repeatCount="indefinite"
            />
            <animate
              attributeName="opacity"
              values={`${0.62 + (profile.haloStrength * 0.18)};${0.84 + (profile.haloStrength * 0.12)};${0.62 + (profile.haloStrength * 0.18)}`}
              dur={pulseDuration}
              repeatCount="indefinite"
            />
          </circle>
          <circle cx="160" cy="160" r="108" fill="none" stroke="#ff748c" strokeOpacity="0.16">
            <animateTransform
              attributeName="transform"
              type="rotate"
              values={`0 160 160;360 160 160`}
              dur={scannerDuration}
              repeatCount="indefinite"
            />
          </circle>
          <circle
            cx="160"
            cy="160"
            r={90 + (profile.haloStrength * 12)}
            fill="none"
            stroke="#ff95a7"
            strokeOpacity={0.18 + (profile.stealthField * 0.1)}
            strokeDasharray={`${10 + Math.round(profile.stealthField * 8)} 12`}>
            <animateTransform
              attributeName="transform"
              type="rotate"
              values={`0 160 160;360 160 160`}
              dur={orbitDuration}
              repeatCount="indefinite"
            />
            <animate
              attributeName="stroke-opacity"
              values={`${0.14 + (profile.stealthField * 0.08)};${0.28 + (profile.stealthField * 0.12)};${0.14 + (profile.stealthField * 0.08)}`}
              dur={pulseDuration}
              repeatCount="indefinite"
            />
          </circle>
          <circle
            cx="160"
            cy="160"
            r={58 + (profile.resistanceLevel * 22)}
            fill="none"
            stroke="#ff7089"
            strokeOpacity="0.18"
            strokeDasharray={`${20 + Math.round(profile.armorSegments * 1.4)} ${10 + Math.round(profile.armorSegments * 0.8)}`}>
            <animateTransform
              attributeName="transform"
              type="rotate"
              values={`360 160 160;0 160 160`}
              dur={`${(Number(orbitDuration.replace('s', '')) * 1.2).toFixed(1)}s`}
              repeatCount="indefinite"
            />
          </circle>
          <line x1="30" y1="160" x2="94" y2="160" stroke="#ffd7df" strokeOpacity="0.18" />
          <line x1="226" y1="160" x2="290" y2="160" stroke="#ffd7df" strokeOpacity="0.18" />
          <line x1="160" y1="30" x2="160" y2="94" stroke="#ffd7df" strokeOpacity="0.14" />
          <line x1="160" y1="226" x2="160" y2="290" stroke="#ffd7df" strokeOpacity="0.14" />

          <g>
            <animateTransform
              attributeName="transform"
              type="translate"
              values={`0 0;1.4 -1.8;-1.2 1.4;0 0`}
              dur={driftDuration}
              repeatCount="indefinite"
            />
            <g>
              <animateTransform
                attributeName="transform"
                type="rotate"
                values={`0 160 160;${wobbleAngle} 160 160;0 160 160;-${wobbleAngle} 160 160;0 160 160`}
                dur={`${(Number(driftDuration.replace('s', '')) * 1.35).toFixed(1)}s`}
                repeatCount="indefinite"
              />
          <g transform={`rotate(${profile.rotation} 160 160)`}>
            {Array.from({ length: profile.tendrilCount }, (_, index) => {
              const angle = ((Math.PI * 2) / Math.max(profile.tendrilCount, 1)) * index;
              const variance = (profileNoise(profile.seed, index, 0.4) - 0.5) * 0.32;
              const radius = shellRx - 6 + (profileNoise(profile.seed, index, 0.9) * 4);
              const startX = 160 + (Math.cos(angle + variance) * radius);
              const startY = 160 + (Math.sin(angle + variance) * shellRy * 0.92);
              const controlX = 160 + (Math.cos(angle + variance + 0.22) * (radius + 16 + (profile.chaos * 10)));
              const controlY = 160 + (Math.sin(angle + variance - 0.14) * (shellRy + 18 + (profile.chaos * 12)));
              const endX = 160 + (Math.cos(angle + variance - 0.1) * (radius + 34 + (profile.transmissionLevel * 18)));
              const endY = 160 + (Math.sin(angle + variance - 0.18) * (shellRy + 26 + (profile.transmissionLevel * 22)));
              return (
                <path
                  key={`tendril-${index}`}
                  d={`M ${startX} ${startY} Q ${controlX} ${controlY} ${endX} ${endY}`}
                  fill="none"
                  stroke="#ff9dad"
                  strokeOpacity={0.24 + (profile.stealthField * 0.16)}
                  strokeWidth={1.2 + (profileNoise(profile.seed, index, 1.2) * 1.6)}
                  strokeLinecap="round">
                  <animate
                    attributeName="stroke-opacity"
                    values={`${0.12 + (profile.stealthField * 0.08)};${0.34 + (profile.stealthField * 0.18)};${0.12 + (profile.stealthField * 0.08)}`}
                    dur={`${(Number(pulseDuration.replace('s', '')) + (index * 0.18)).toFixed(1)}s`}
                    begin={`${(index * 0.22).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                </path>
              );
            })}

            {Array.from({ length: profile.spikeCount }, (_, index) => {
              const angle = ((Math.PI * 2) / profile.spikeCount) * index;
              const variance = (profileNoise(profile.seed, index, 1.6) - 0.5) * 0.22;
              const radius = shellRx - 5 + (profileNoise(profile.seed, index, 0.6) * 4);
              const outerRadius = radius + profile.spikeLength + (profileNoise(profile.seed, index, 2.1) * 10);
              const spread = 0.11 + (profileNoise(profile.seed, index, 2.7) * 0.08);
              const points = [
                [
                  160 + (Math.cos(angle + variance - spread) * radius),
                  160 + (Math.sin(angle + variance - spread) * shellRy * 0.92),
                ],
                [
                  160 + (Math.cos(angle + variance) * outerRadius),
                  160 + (Math.sin(angle + variance) * (shellRy + (profile.spikeLength * 0.35))),
                ],
                [
                  160 + (Math.cos(angle + variance + spread) * radius),
                  160 + (Math.sin(angle + variance + spread) * shellRy * 0.92),
                ],
              ].map((point) => point.join(',')).join(' ');
              return (
                <polygon
                  key={`spike-${index}`}
                  points={points}
                  fill="url(#virusSpike)"
                  opacity={0.5 + (profile.transmissionLevel * 0.34)}>
                  <animate
                    attributeName="opacity"
                    values={`${0.36 + (profile.transmissionLevel * 0.18)};${0.72 + (profile.transmissionLevel * 0.22)};${0.36 + (profile.transmissionLevel * 0.18)}`}
                    dur={`${(Number(pulseDuration.replace('s', '')) + (index * 0.07)).toFixed(1)}s`}
                    begin={`${(index * 0.09).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                </polygon>
              );
            })}

            {Array.from({ length: profile.shellLayers }, (_, index) => {
              const ratio = index / Math.max(profile.shellLayers - 1, 1);
              const layerRx = shellRx - (index * 8);
              const layerRy = shellRy - (index * 6);
              return (
                <ellipse
                  key={`shell-${index}`}
                  cx="160"
                  cy="160"
                  rx={layerRx}
                  ry={layerRy}
                  fill={index === profile.shellLayers - 1 ? 'url(#virusMembrane)' : 'none'}
                  stroke="#ffd6de"
                  strokeOpacity={0.26 - (ratio * 0.08) + (profile.resistanceLevel * 0.08)}
                  strokeWidth={1.3 + (ratio * 0.9)}>
                  <animate
                    attributeName="rx"
                    values={`${layerRx};${layerRx + 2 + (profile.stageLevel * 2.4)};${layerRx}`}
                    dur={`${(Number(pulseDuration.replace('s', '')) + (ratio * 0.8)).toFixed(1)}s`}
                    begin={`${(index * 0.25).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                  <animate
                    attributeName="ry"
                    values={`${layerRy};${layerRy + 1.5 + (profile.stageLevel * 2)};${layerRy}`}
                    dur={`${(Number(pulseDuration.replace('s', '')) + (ratio * 0.8)).toFixed(1)}s`}
                    begin={`${(index * 0.25).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                </ellipse>
              );
            })}

            {profile.biotech > 0.22 && Array.from({
              length: Math.max(3, Math.round(profile.armorSegments / 3)),
            }, (_, index) => {
              const angle = ((Math.PI * 2) / Math.max(3, Math.round(profile.armorSegments / 3))) * index;
              const radius = shellRx - 12;
              const centerX = 160 + (Math.cos(angle) * radius);
              const centerY = 160 + (Math.sin(angle) * shellRy * 0.9);
              const size = 6 + (profile.biotech * 4);
              const hexPoints = Array.from({ length: 6 }, (_, pointIndex) => {
                const pointAngle = ((Math.PI * 2) / 6) * pointIndex;
                return [
                  centerX + (Math.cos(pointAngle) * size),
                  centerY + (Math.sin(pointAngle) * size),
                ].join(',');
              }).join(' ');
              return (
                <polygon
                  key={`tech-${index}`}
                  points={hexPoints}
                  fill="none"
                  stroke="#ffe1e6"
                  strokeOpacity="0.28">
                  <animateTransform
                    attributeName="transform"
                    type="rotate"
                    values={`0 ${centerX} ${centerY};360 ${centerX} ${centerY}`}
                    dur={`${(10 + (index * 0.8)).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                </polygon>
              );
            })}

            {profile.stealthField > 0.28 && (
              <ellipse
                cx="160"
                cy="160"
                rx={shellRx + 9 + (profile.stealthField * 8)}
                ry={shellRy + 7 + (profile.stealthField * 6)}
                fill="none"
                stroke="#fff4f7"
                strokeOpacity={0.12 + (profile.stealthField * 0.12)}
                strokeDasharray="7 9">
                <animateTransform
                  attributeName="transform"
                  type="rotate"
                  values={`0 160 160;-360 160 160`}
                  dur={`${(Number(orbitDuration.replace('s', '')) * 1.4).toFixed(1)}s`}
                  repeatCount="indefinite"
                />
              </ellipse>
            )}

            {Array.from({ length: profile.nodeCount }, (_, index) => {
              const angle = ((Math.PI * 2) / profile.nodeCount) * index;
              const orbit = 20 + (profileNoise(profile.seed, index, 1.9) * 18) + (profile.supportBloom * 10);
              const x = 160 + (Math.cos(angle + 0.2) * orbit);
              const y = 160 + (Math.sin(angle - 0.18) * orbit * 0.82);
              const radius = 3.2 + (profileNoise(profile.seed, index, 2.4) * 3.8);
              return (
                <Fragment key={`node-${index}`}>
                  <line
                    x1="160"
                    y1="160"
                    x2={x}
                    y2={y}
                    stroke="#ffd7df"
                    strokeOpacity="0.12"
                  />
                  <circle cx={x} cy={y} r={radius} fill="url(#virusNode)">
                    <animate
                      attributeName="r"
                      values={`${radius};${(radius + 1.2 + (profile.supportBloom * 1.4)).toFixed(2)};${radius}`}
                      dur={`${(Number(pulseDuration.replace('s', '')) + (index * 0.15)).toFixed(1)}s`}
                      begin={`${(index * 0.17).toFixed(1)}s`}
                      repeatCount="indefinite"
                    />
                    <animateTransform
                      attributeName="transform"
                      type="translate"
                      values={`0 0;${(profileNoise(profile.seed, index, 6.2) * 2.4 - 1.2).toFixed(2)} ${(profileNoise(profile.seed, index, 6.9) * 2.4 - 1.2).toFixed(2)};0 0`}
                      dur={`${(Number(driftDuration.replace('s', '')) + (index * 0.11)).toFixed(1)}s`}
                      begin={`${(index * 0.13).toFixed(1)}s`}
                      repeatCount="indefinite"
                    />
                  </circle>
                </Fragment>
              );
            })}

            <ellipse
              cx="160"
              cy="160"
              rx={coreRx + (profile.supportBloom * 4)}
              ry={coreRy + (profile.supportBloom * 3)}
              fill="url(#virusCore)"
              opacity={0.94 - (profile.stealthField * 0.12)}>
              <animate
                attributeName="rx"
                values={`${(coreRx + (profile.supportBloom * 4)).toFixed(2)};${(coreRx + (profile.supportBloom * 7) + (profile.stageLevel * 3)).toFixed(2)};${(coreRx + (profile.supportBloom * 4)).toFixed(2)}`}
                dur={pulseDuration}
                repeatCount="indefinite"
              />
              <animate
                attributeName="ry"
                values={`${(coreRy + (profile.supportBloom * 3)).toFixed(2)};${(coreRy + (profile.supportBloom * 5) + (profile.stageLevel * 2.5)).toFixed(2)};${(coreRy + (profile.supportBloom * 3)).toFixed(2)}`}
                dur={pulseDuration}
                repeatCount="indefinite"
              />
              <animate
                attributeName="opacity"
                values={`${0.82 - (profile.stealthField * 0.1)};1;${0.82 - (profile.stealthField * 0.1)}`}
                dur={pulseDuration}
                repeatCount="indefinite"
              />
            </ellipse>

            {Array.from({ length: Math.max(3, Math.round(profile.nodeCount / 2)) }, (_, index) => {
              const angle = ((Math.PI * 2) / Math.max(3, Math.round(profile.nodeCount / 2))) * index;
              const orbit = 8 + (profileNoise(profile.seed, index, 3.4) * 12);
              const vesicleX = 160 + (Math.cos(angle + 0.35) * orbit);
              const vesicleY = 160 + (Math.sin(angle - 0.25) * orbit * 0.8);
              return (
                <ellipse
                  key={`vesicle-${index}`}
                  cx={vesicleX}
                  cy={vesicleY}
                  rx={4 + (profileNoise(profile.seed, index, 4.1) * 3)}
                  ry={2.8 + (profileNoise(profile.seed, index, 4.6) * 2.2)}
                  fill="#fff4f7"
                  fillOpacity={0.32 + (profile.supportBloom * 0.1)}>
                  <animateTransform
                    attributeName="transform"
                    type="translate"
                    values={`0 0;${(profileNoise(profile.seed, index, 7.4) * 3.4 - 1.7).toFixed(2)} ${(profileNoise(profile.seed, index, 8.1) * 3.4 - 1.7).toFixed(2)};0 0`}
                    dur={`${(Number(driftDuration.replace('s', '')) + 0.6 + (index * 0.14)).toFixed(1)}s`}
                    begin={`${(index * 0.21).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                </ellipse>
              );
            })}

            {profile.necrosis > 0.18 && Array.from({
              length: 2 + Math.round(profile.necrosis * 4),
            }, (_, index) => {
              const angle = ((Math.PI * 2) / Math.max(2, 2 + Math.round(profile.necrosis * 4))) * index;
              const startRadius = 6 + (profileNoise(profile.seed, index, 5.2) * 10);
              const endRadius = 18 + (profileNoise(profile.seed, index, 5.7) * 18);
              const midRadius = (startRadius + endRadius) / 2;
              const startX = 160 + (Math.cos(angle) * startRadius);
              const startY = 160 + (Math.sin(angle) * startRadius * 0.82);
              const midX = 160 + (Math.cos(angle + 0.18) * midRadius);
              const midY = 160 + (Math.sin(angle - 0.12) * midRadius * 0.84);
              const endX = 160 + (Math.cos(angle - 0.14) * endRadius);
              const endY = 160 + (Math.sin(angle - 0.22) * endRadius * 0.86);
              return (
                <path
                  key={`crack-${index}`}
                  d={`M ${startX} ${startY} L ${midX} ${midY} L ${endX} ${endY}`}
                  fill="none"
                  stroke="#2d0007"
                  strokeOpacity={0.26 + (profile.necrosis * 0.24)}
                  strokeWidth={1.2 + (profile.necrosis * 0.8)}
                  strokeLinecap="round">
                  <animate
                    attributeName="stroke-opacity"
                    values={`${0.18 + (profile.necrosis * 0.18)};${0.42 + (profile.necrosis * 0.26)};${0.18 + (profile.necrosis * 0.18)}`}
                    dur={flickerDuration}
                    begin={`${(index * 0.27).toFixed(1)}s`}
                    repeatCount="indefinite"
                  />
                </path>
              );
            })}
            </g>
          </g>
          </g>

          <text
            x="24"
            y="34"
            fill="#ffe5ea"
            fontSize="11"
            letterSpacing="0.12em">
            МОРФОЛОГИЯ
          </text>
          <text
            x="24"
            y="50"
            fill="#ffb7c4"
            fontSize="9"
            letterSpacing="0.08em">
            ПЕРЕДАЧА / СТОЙКОСТЬ / СКРЫТНОСТЬ / ТЕМП
          </text>
        </svg>
      </Box>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
          gap: '8px',
          marginTop: '8px',
        }}>
        {metrics.map((metric) => (
          <Box
            key={metric.label}
            p={0.55}
            style={{
              border: '1px solid rgba(255, 112, 136, 0.22)',
              background: 'linear-gradient(180deg, rgba(255, 107, 129, 0.12), rgba(255, 107, 129, 0.03))',
            }}>
            <Box
              style={{
                color: '#ffd6de',
                textTransform: 'uppercase',
                letterSpacing: '0.08em',
                fontSize: '0.7rem',
              }}>
              {metric.label}
            </Box>
            <Box mt={0.2} bold style={{ color: metric.accent }}>
              {metric.value}
            </Box>
          </Box>
        ))}
      </div>
    </Box>
  );
};

const CurrentHostPanel = (props) => {
  const { host, abilities, stats } = props;

  return (
    <Frame title="Текущий носитель">
      <VirusMorphologyPanel abilities={abilities} stats={stats} host={host} />
      {host ? (
        <>
          <Box bold color="#fff7f9">{host.name}</Box>
          <Box mb={0.8} color="label">{host.status}</Box>
          <Box color="label">Здоровье</Box>
          <ProgressBar
            value={healthRatio(host.health, host.maxHealth)}
            ranges={{
              good: [0.65, Infinity],
              average: [0.3, 0.65],
              bad: [-Infinity, 0.3],
            }}
          />
          <Box mt={0.4} color="label">
            {host.health} / {host.maxHealth}
          </Box>
        </>
      ) : (
        <NoticeBox>Сейчас нет выбранного носителя.</NoticeBox>
      )}
    </Frame>
  );
};

const HostsPanel = (props) => {
  const { hosts, onFollow } = props;

  return (
    <Frame title="Сеть носителей" style={{ marginTop: '12px' }}>
      {!hosts.length ? (
        <NoticeBox>Инфицированные носители отсутствуют.</NoticeBox>
      ) : (
        <Stack vertical>
          {hosts.map(host => (
            <Stack.Item key={host.ref}>
              <Box
                p={0.8}
                style={{
                  border: host.is_following
                    ? '1px solid rgba(255, 225, 230, 0.75)'
                    : '1px solid rgba(255, 94, 120, 0.26)',
                  background: host.is_following
                    ? 'linear-gradient(90deg, rgba(255, 96, 120, 0.24), rgba(255, 96, 120, 0.06))'
                    : 'linear-gradient(90deg, rgba(255, 255, 255, 0.04), rgba(255, 255, 255, 0))',
                }}>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold color="#fff4f6">{host.name}</Box>
                    <Box color="label">{host.status}</Box>
                    <ProgressBar
                      value={healthRatio(host.health, host.maxHealth)}
                      mt={0.35}
                      ranges={{
                        good: [0.65, Infinity],
                        average: [0.3, 0.65],
                        bad: [-Infinity, 0.3],
                      }}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color={host.is_following ? 'average' : 'bad'}
                      onClick={() => onFollow(host.ref)}>
                      {host.is_following ? 'Ведущий' : 'Следовать'}
                    </Button>
                  </Stack.Item>
                </Stack>
              </Box>
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Frame>
  );
};

const OverviewTab = (props) => {
  const { data, abilities, setSelectedAbility } = props;
  const purchased = abilities.filter(ability => ability.purchased).slice(0, 6);
  const stats = data.stats || {};

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Frame title="Сводка генома">
          <Box color="#ffe1e7" mb={0.8}>
            Заражайте как можно больше живых целей одновременно, чтобы накапливать очки ДНК и открывать новые ветви адаптации.
          </Box>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
              gap: '12px',
            }}>
            <FooterStat label="Стойкость" value={statRatio(stats.resistance || 0)} color="average" />
            <FooterStat label="Скрытность" value={statRatio(stats.stealth || 0)} color="average" />
            <FooterStat label="Скорость стадий" value={statRatio(stats.stage_speed || 0)} color="average" />
            <FooterStat label="Заразность" value={statRatio(stats.transmission || 0)} color="average" />
          </div>
          <Box mt={1} color="label">
            Предполагаемое лекарство: <span style={{ color: '#fff3c7' }}>{data.cure || 'Не определено'}</span>
          </Box>
        </Frame>
      </Stack.Item>
      <Stack.Item grow>
        <Frame title="Активные адаптации" style={{ height: '100%', marginTop: '12px' }}>
          {!purchased.length ? (
            <NoticeBox>Пока не приобретено ни одной дополнительной мутации.</NoticeBox>
          ) : (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                gap: '12px',
              }}>
              {purchased.map(ability => (
                <div
                  key={ability.id}
                  onClick={() => setSelectedAbility(ability.id)}
                  style={{
                    cursor: 'pointer',
                    padding: '14px',
                    border: '1px solid rgba(255, 105, 131, 0.34)',
                    background: 'linear-gradient(180deg, rgba(255, 91, 114, 0.18), rgba(255, 91, 114, 0.04))',
                  }}>
                  <Box color={tierColors[ability.tier] || '#ffe0e6'}>
                    <Icon name={ability.icon} />
                  </Box>
                  <Box mt={0.4} bold color="#fff7f8">{ability.displayName}</Box>
                  <Box mt={0.3} color="label">{ability.shortDesc}</Box>
                </div>
              ))}
            </div>
          )}
        </Frame>
      </Stack.Item>
    </Stack>
  );
};

const AbilityGridTab = (props) => {
  const { title, abilities, selectedAbilityId, setSelectedAbility, act } = props;

  return (
    <Frame title={title} style={{ height: '100%' }}>
      {!abilities.length ? (
        <NoticeBox>Подходящие мутации пока отсутствуют.</NoticeBox>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
            gap: '14px',
          }}>
          {abilities.map(ability => (
            <HexAbilityCard
              key={ability.id}
              ability={ability}
              selected={selectedAbilityId === ability.id}
              onSelect={() => setSelectedAbility(ability.id)}
              onBuy={() => act('buy_ability', { ability: ability.id })}
              onRefund={() => act('refund_ability', { ability: ability.id })}
            />
          ))}
        </div>
      )}
    </Frame>
  );
};

const HostsTab = (props) => {
  const { hosts, purchasedAbilities, onFollow, setSelectedAbility } = props;

  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Frame title="Инфицированные носители" style={{ height: '100%' }}>
          {!hosts.length ? (
            <NoticeBox>Активные носители отсутствуют.</NoticeBox>
          ) : (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
                gap: '12px',
              }}>
              {hosts.map(host => (
                <Box
                  key={host.ref}
                  p={1}
                  style={{
                    border: host.is_following
                      ? '1px solid rgba(255, 224, 230, 0.8)'
                      : '1px solid rgba(255, 96, 120, 0.26)',
                    background: 'linear-gradient(180deg, rgba(255, 102, 126, 0.16), rgba(255, 102, 126, 0.04))',
                  }}>
                  <Box bold color="#fff7f9">{host.name}</Box>
                  <Box color="label">{host.status}</Box>
                  <ProgressBar
                    value={healthRatio(host.health, host.maxHealth)}
                    mt={0.55}
                    ranges={{
                      good: [0.65, Infinity],
                      average: [0.3, 0.65],
                      bad: [-Infinity, 0.3],
                    }}
                  />
                  <Box mt={0.4} color="label">
                    {host.health} / {host.maxHealth}
                  </Box>
                  <Button
                    fluid
                    mt={0.7}
                    color={host.is_following ? 'average' : 'bad'}
                    onClick={() => onFollow(host.ref)}>
                    {host.is_following ? 'Текущий носитель' : 'Переключиться'}
                  </Button>
                </Box>
              ))}
            </div>
          )}
        </Frame>
      </Stack.Item>
      <Stack.Item>
        <Frame title="Освоенные адаптации" style={{ marginTop: '12px' }}>
          {!purchasedAbilities.length ? (
            <NoticeBox>Геном пока не получил дополнительных мутаций.</NoticeBox>
          ) : (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                gap: '10px',
              }}>
              {purchasedAbilities.map(ability => (
                <Box
                  key={ability.id}
                  p={0.8}
                  onClick={() => setSelectedAbility(ability.id)}
                  style={{
                    cursor: 'pointer',
                    border: '1px solid rgba(255, 112, 136, 0.3)',
                    background: 'linear-gradient(180deg, rgba(255, 95, 119, 0.18), rgba(255, 95, 119, 0.05))',
                  }}>
                  <Box color={tierColors[ability.tier] || '#ffe0e6'}>
                    <Icon name={ability.icon} />
                  </Box>
                  <Box mt={0.3} bold color="#fff4f6">{ability.displayName}</Box>
                </Box>
              ))}
            </div>
          )}
        </Frame>
      </Stack.Item>
    </Stack>
  );
};

export const SentientDisease = (props, context) => {
  const { act, data } = useBackend(context);
  const [tab, setTab] = useLocalState(context, 'tab', 'overview');

  const abilities = (data.abilities || [])
    .map(localizeAbility)
    .sort(sortAbilities);
  const purchasedAbilities = abilities.filter(ability => ability.purchased);
  const selectedFallback = purchasedAbilities[0] || abilities[0] || null;
  const [selectedAbilityId, setSelectedAbility] = useLocalState(
    context,
    'selected_ability',
    selectedFallback?.id || null,
  );

  const selectedAbility = abilities.find(ability => ability.id === selectedAbilityId)
    || selectedFallback;
  const transmissionAbilities = abilities.filter(ability => ability.viewTab === 'transmission');
  const symptomAbilities = abilities.filter(ability => ability.viewTab === 'symptoms');
  const hosts = data.hosts || [];
  const followingHost = data.following_host;
  const stats = data.stats || {};

  return (
    <Window
      width={1200}
      height={760}
      title={data.disease_name || 'Разумный вирус'}
      theme="syndicate"
      resizable>
      <Window.Content
        fitted
        overflow="auto"
        style={{
          ...hexBackground,
          padding: '14px',
        }}>
        <Box
          style={{
            minWidth: '1260px',
            minHeight: '820px',
          }}>
          <Stack vertical fill>
          <Stack.Item>
            <Box
              px={2}
              py={1}
              style={{
                ...panelStyle,
                background: 'linear-gradient(180deg, rgba(92, 0, 14, 0.96) 0%, rgba(48, 0, 8, 0.98) 100%)',
                textAlign: 'center',
                textTransform: 'uppercase',
                letterSpacing: '0.08em',
                color: '#fff8fa',
              }}>
              <Box bold fontSize={2}>
                {data.disease_name || 'Разумный вирус'}
              </Box>
              <Box mt={0.3} color="#ffd7df">
                Сеть носителей: {data.host_count || 0} / Доступно ДНК: {data.points || 0}/{data.total_points || 0}
              </Box>
            </Box>
          </Stack.Item>

          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab selected={tab === 'overview'} onClick={() => setTab('overview')}>
                Обзор
              </Tabs.Tab>
              <Tabs.Tab selected={tab === 'transmission'} onClick={() => setTab('transmission')}>
                Пути передачи
              </Tabs.Tab>
              <Tabs.Tab selected={tab === 'symptoms'} onClick={() => setTab('symptoms')}>
                Симптомы
              </Tabs.Tab>
              <Tabs.Tab selected={tab === 'hosts'} onClick={() => setTab('hosts')}>
                Носители
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item grow basis={0}>
                <Box
                  pr={1}
                  style={{
                    height: '100%',
                    overflow: 'auto',
                  }}>
                  {tab === 'overview' && (
                    <OverviewTab
                      data={data}
                      abilities={abilities}
                      setSelectedAbility={setSelectedAbility}
                    />
                  )}
                  {tab === 'transmission' && (
                    <AbilityGridTab
                      title="Контроль распространения"
                      abilities={transmissionAbilities}
                      selectedAbilityId={selectedAbility?.id}
                      setSelectedAbility={setSelectedAbility}
                      act={act}
                    />
                  )}
                  {tab === 'symptoms' && (
                    <AbilityGridTab
                      title="Каталог симптомов"
                      abilities={symptomAbilities}
                      selectedAbilityId={selectedAbility?.id}
                      setSelectedAbility={setSelectedAbility}
                      act={act}
                    />
                  )}
                  {tab === 'hosts' && (
                    <HostsTab
                      hosts={hosts}
                      purchasedAbilities={purchasedAbilities}
                      onFollow={(host) => act('follow_host', { host })}
                      setSelectedAbility={setSelectedAbility}
                    />
                  )}
                </Box>
              </Stack.Item>

              <Stack.Item basis="320px">
                <Box
                  style={{
                    height: '100%',
                    overflow: 'auto',
                  }}>
                  <CurrentHostPanel
                    host={followingHost}
                    abilities={abilities}
                    stats={stats}
                  />
                  {tab !== 'hosts' && (
                    <AbilityDetailPanel
                      ability={selectedAbility}
                      onBuy={() => selectedAbility && act('buy_ability', { ability: selectedAbility.id })}
                      onRefund={() => selectedAbility && act('refund_ability', { ability: selectedAbility.id })}
                    />
                  )}
                  <HostsPanel
                    hosts={hosts}
                    onFollow={(host) => act('follow_host', { host })}
                  />
                </Box>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(5, minmax(180px, 1fr))',
                gap: '10px',
              }}>
              <FooterStat
                label="ДНК"
                content={(
                  <Fragment>
                    <ProgressBar
                      value={data.total_points ? clamp((data.points || 0) / data.total_points, 0, 1) : 0}
                      color="average"
                    />
                    <Box mt={0.35} bold color="#fff7f9">
                      {data.points || 0} / {data.total_points || 0}
                    </Box>
                  </Fragment>
                )}
              />
              <FooterStat label="Заразность" value={statRatio(stats.transmission || 0)} color="bad" />
              <FooterStat label="Скрытность" value={statRatio(stats.stealth || 0)} color="average" />
              <FooterStat label="Стойкость" value={statRatio(stats.resistance || 0)} color="average" />
              <FooterStat
                label="Мутация"
                content={(
                  <Fragment>
                    <ProgressBar
                      value={data.can_adapt ? 1 : 0}
                      color={data.can_adapt ? 'good' : 'bad'}
                    />
                    <Box mt={0.35} bold color="#fff7f9">
                      {data.can_adapt ? 'Готово' : formatTime(data.adaptation_ready_in)}
                    </Box>
                  </Fragment>
                )}
              />
            </div>
          </Stack.Item>
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};
