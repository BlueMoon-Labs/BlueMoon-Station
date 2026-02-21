import { useBackend } from '../backend';
import { Box, Button, Divider, Section, Stack } from '../components';
import { Window } from '../layouts';

const buttonWidth = 2;

const goodstyle = {
  color: 'lightgreen',
  fontWeight: 'bold',
};

const badstyle = {
  color: 'red',
  fontWeight: 'bold',
};

const partstyle = {
  color: 'yellow',
  fontWeight: 'bold',
};

const fuelstyle = {
  color: 'olive',
  fontWeight: 'bold',
};

const variousButtonIcons = {
  "Restore Hull": "wrench",
  "Fix Engine": "rocket",
  "Repair Electronics": "server",
  "Wait": "clock",
  "Continue": "arrow-right",
  "Explore Ship": "door-open",
  "Leave the Derelict": "arrow-right",
  "Welcome aboard.": "user-plus",
  "Where did you go?!": "user-minus",
  "A good find.": "box-open",
  "Continue travels.": "arrow-right",
  "Keep Speed": "tachometer-alt",
  "Slow Down": "arrow-left",
  "Speed Past": "tachometer-alt",
  "Go Around": "redo",
  "Oh...": "circle",
  "Dock": "dollar-sign",
};

const buttonTranslations = {
  "Restore Hull": "Починить обшивку",
  "Fix Engine": "Починить двигатель",
  "Repair Electronics": "Починить электронику",
  "Wait": "Ждать",
  "Continue": "Продолжить",
  "Explore Ship": "Исследовать корабль",
  "Leave the Derelict": "Покинуть обломки",
  "Welcome aboard.": "Добро пожаловать на борт.",
  "Where did you go?!": "Куда вы делись?!",
  "A good find.": "Хорошая находка.",
  "Continue travels.": "Продолжить путь.",
  "Keep Speed": "Держать скорость",
  "Slow Down": "Замедлиться",
  "Speed Past": "Промчаться мимо",
  "Go Around": "Облететь",
  "Oh...": "Ох...",
  "Dock": "Причалить",
};

const STATUS2COMPONENT = [
  { component: () => ORION_STATUS_START },
  { component: () => ORION_STATUS_INSTRUCTIONS },
  { component: () => ORION_STATUS_NORMAL },
  { component: () => ORION_STATUS_GAMEOVER },
  { component: () => ORION_STATUS_MARKET },
];

const locationInfo = [
  {
    title: "Плутон",
    blurb: "Плутон, давно оснащённый дальнобойными сенсорами и сканерами, неустанно продолжает зондировать дальние рубежи галактики.",
  },
  {
    title: "Пояс астероидов",
    blurb: "На краю системы Сол лежит коварный пояс астероидов. Многие были раздавлены шальными астероидами и ошибочными решениями.",
  },
  {
    title: "Проксима Центавра",
    blurb: "Ближайшая к Солу звёздная система. В прошлом она напоминала о пределах досветовых путешествий, а ныне стала малонаселённым пристанищем для искателей приключений и торговцев.",
  },
  {
    title: "Мёртвый космос",
    blurb: "Этот регион космоса особенно лишён материи. Подобные разреженные области встречаются, однако его бескрайность поражает воображение.",
  },
  {
    title: "Ригель Прайм",
    blurb: "Ригель Прайм, центр системы Ригель, пылает жаром, окутывая свои планеты теплом и радиацией.",
  },
  {
    title: "Тау Кита Бета",
    blurb: "Тау Кита Бета недавно стала перевалочным пунктом для колонистов, направляющихся к Ориону. В окрестностях множество кораблей и самодельных станций.",
  },
  {
    title: "Космические жуки",
    blurb: "Вы видите космических жуков за иллюминатором. Они извиваются, искривляя реальность, и от этого вас тошнит. Вы знаете, что Галактический Устав обязывает сообщать обо всех встречах с космическими жуками.",
  },
  {
    title: "Космический форпост Бета-9",
    blurb: "Вы приблизились к первому рукотворному строению в этом регионе космоса. Оно возведено не путешественниками из Сола, а колонистами с Ориона. Форпост стоит как памятник успеху колонистов.",
  },
  {
    title: "Орион Прайм",
    blurb: "Вы добрались до Ориона! Поздравляем! Ваш экипаж — один из немногих, заложивших новый оплот человечества!",
  },
];

const AdventureStatus = (props, context) => {
  const { data, act } = useBackend(context);
  const {
    lings_suspected,
    eventname,
    settlers,
    settlermoods,
    hull,
    electronics,
    engine,
    food,
    fuel,
  } = data;
  return (
    <Section
      title="Статус экспедиции"
      fill
      buttons={(
        !!lings_suspected && (
          <Button
            fluid
            color="black"
            textAlign="center"
            icon="skull"
            content="СЛУЧАЙНОЕ УБИЙСТВО"
            disabled={eventname}
            onClick={() => act('random_kill')} />
        )
      )} >
      <Stack mb={-1} fill>
        <Stack.Item grow mb={-0.5}>
          {settlers?.map(settler => (
            <Stack key={settler}>
              <Stack.Item grow mt={0.9}>
                {settler}
              </Stack.Item>
              <Stack.Item mt={0.9}>
                <Button
                  fluid
                  color="red"
                  textAlign="center"
                  icon="skull"
                  content="УБИТЬ"
                  disabled={lings_suspected || eventname}
                  onClick={() => act('target_kill', {
                    who: settler,
                  })} />
              </Stack.Item>
              <Stack.Item mr={0}>
                <Box className={'moods32x32 mood' + (settlermoods[settler] + 1)} />
              </Stack.Item>
            </Stack>
          ))}
        </Stack.Item>
        <Divider vertical />
        <Stack.Item>
          <Stack vertical fill>
            <Stack.Item>
              <Button
                fluid
                icon="hamburger"
                content={"Еда: " + food}
                color="green" />
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="gas-pump"
                content={"Топливо: " + fuel}
                color="olive" />
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="wrench"
                content={"Обшивка: "+hull}
                color="average" />
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="server"
                content={"Электроника: "+electronics}
                color="blue" />
            </Stack.Item>
            <Stack.Item mb={1}>
              <Button
                fluid
                icon="rocket"
                content={"Двигатель: "+engine}
                color="violet" />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ORION_STATUS_START = (props, context) => {
  const { data, act } = useBackend(context);
  const {
    gamename,
  } = data;
  return (
    <Section fill>
      <Stack vertical textAlign="center" fill>
        <Stack.Item grow={1} />
        <Stack.Item fontSize="32px">
          {gamename}
        </Stack.Item>
        <Stack.Item grow fontSize="15px" color="label">
          {"\"Испытайте путешествие своих предков!\""}
        </Stack.Item>
        <Stack.Item fontSize="15px">
          <Button
            lineHeight={2}
            fluid
            icon="play"
            content="Начать игру"
            onClick={() => act('start_game')} />
        </Stack.Item>
        <Stack.Item fontSize="15px">
          <Button
            lineHeight={2}
            fluid
            icon="info"
            content="Инструкции"
            onClick={() => act('instructions')} />
        </Stack.Item>
        <Stack.Item grow={3} />
      </Stack>
    </Section>
  );
};

const ORION_STATUS_INSTRUCTIONS = (props, context) => {
  const { act } = useBackend(context);
  const fake_settlers = ["John", "William", "Alice", "Tom"];
  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section
          color="label"
          title="Цель"
          fill
          buttons={(
            <Button
              content="В главное меню"
              onClick={() => act('back_to_menu')} />
          )}>
          <Box fontSize="11px">
            В 2200-х годах Орионская тропа была проложена как опасный,
            но многообещающий путь через космос для тех, кто готов рискнуть.
            Многие первопроходцы, искавшие новую жизнь на галактическом
            фронтире, находили именно то, что искали... или погибали в пути.
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Пример статуса" fill>
          <Stack mb={-1} fill>
            <Stack.Item basis={70} grow mb={-0.5}>
              {fake_settlers?.map(settler => (
                <Stack key={settler}>
                  <Stack.Item grow mt={0.9}>
                    {settler}
                  </Stack.Item>
                  <Stack.Item mt={0.9}>
                    <Button
                      fluid
                      color="red"
                      textAlign="center"
                      icon="skull"
                      content="УБИТЬ" />
                  </Stack.Item>
                  <Stack.Item mr={0}>
                    <Box className={'moods32x32 mood5'} />
                  </Stack.Item>
                </Stack>
              ))}
            </Stack.Item>
            <Divider vertical />
            <Stack.Item grow>
              Это панель статуса ваших первопроходцев. Каждый потребляет
              1 единицу еды при каждом перемещении
              к <span style={goodstyle}>Ориону</span>.
              Вы можете найти новых членов экипажа в пути и потерять их
              так же быстро, как нашли.
              <br /><br />
              Если закончится еда или экипаж —
              для вас наступит <span style={badstyle}>КОНЕЦ ИГРЫ</span>!
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill title="Ресурсы">
          <Stack fill>
            <Stack.Item grow mt={-1}>
              Чтобы добраться до <span style={goodstyle}>Ориона</span>,
              вам нужно управлять своими ресурсами:
              <br />
              <span style={goodstyle}>Еда</span>: Её потребляет ваш экипаж.
              Больше людей — быстрее расход!
              <br />
              <span style={fuelstyle}>Топливо</span>: Каждое перемещение
              расходует 5 ед. Не дайте ему закончиться.
              <br />
              <span style={partstyle}>Запчасти</span>: Нужны для ремонта поломок.
              Никто не любит тратить время на починку!
            </Stack.Item>
            <Divider vertical />
            <Stack.Item>
              <Stack vertical fill>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="hamburger"
                    content={"Еда: 80"}
                    color="green" />
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="gas-pump"
                    content={"Топливо: 60"}
                    color="olive" />
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="wrench"
                    content={"Обшивка: 1"}
                    color="average" />
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="server"
                    content={"Электроника: 1"}
                    color="blue" />
                </Stack.Item>
                <Stack.Item mb={-0.3} grow>
                  <Button
                    fluid
                    icon="rocket"
                    content={"Двигатель: 1"}
                    color="violet" />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const ORION_STATUS_NORMAL = (props, context) => {
  const { data, act } = useBackend(context);
  const {
    settlers,
    settlermoods,
    hull,
    electronics,
    engine,
    food,
    fuel,
    turns,
    eventname,
    eventtext,
    buttons,
  } = data;
  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section title={!!eventname && "Событие" || "Местоположение"} fill>
          <Stack fill textAlign="center" vertical>
            <Stack.Item grow >
              <Box bold fontSize="15px">
                {!!eventname && eventname || locationInfo[turns-1].title}
              </Box>
              <br />
              <Box fontSize="15px">
                {!!eventtext && eventtext || locationInfo[turns-1].blurb}
              </Box>
            </Stack.Item>
            <Stack.Item>
              {!!buttons && (
                buttons.map(button => (
                  <Stack.Item key={button}>
                    <Button
                      mb={1}
                      lineHeight={3}
                      width={16}
                      icon={variousButtonIcons[button]}
                      content={buttonTranslations[button] || button}
                      onClick={() => act(button)} />
                  </Stack.Item>
                ))
              ) || (
                <Button
                  mb={1}
                  lineHeight={3}
                  width={16}
                  icon="arrow-right"
                  content="Продолжить"
                  onClick={() => act('continue')} />
              )}
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <AdventureStatus />
      </Stack.Item>
    </Stack>
  );
};

const ORION_STATUS_GAMEOVER = (props, context) => {
  const { data, act } = useBackend(context);
  const {
    reason,
  } = data;
  return (
    <Section fill>
      <Stack vertical textAlign="center" fill>
        <Stack.Item grow={1} />
        <Stack.Item color="red" fontSize="32px">
          {"Конец игры"}
        </Stack.Item>
        <Stack.Item grow fontSize="15px" color="label">
          {reason}
        </Stack.Item>
        <Stack.Item fontSize="15px">
          <Button
            lineHeight={2}
            fluid
            icon="arrow-left"
            content="Главное меню"
            onClick={() => act('back_to_menu')} />
        </Stack.Item>
        <Stack.Item grow={3} />
      </Stack>
    </Section>
  );
};

const marketButtonSpacing = 0.8;

const ORION_STATUS_MARKET = (props, context) => {
  const { data, act } = useBackend(context);
  const {
    turns,
    spaceport_raided,
  } = data;
  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section
          title="Рынок"
          fill
          buttons={(
            <>
              <Button
                content="Налёт"
                icon="skull"
                color="black"
                disabled={spaceport_raided}
                onClick={() => act('raid_spaceport')} />
              <Button
                content="Покинуть"
                icon="arrow-right"
                onClick={() => act('leave_spaceport')} />
            </>
          )}>
          <Stack fill textAlign="center" vertical>
            <Stack.Item grow >
              <Box mb={-2} bold fontSize="15px">
                {turns === 4 && "Тау Кита Бета" || "Малый космопорт"}
              </Box>
              <br />
              <Box fontSize="14px">
                {spaceport_raided && (
                  <Box color="red">
                    Вам повезло унести ноги. Попытка причалить
                    снова будет верной смертью.
                  </Box>
                ) || (
                  "Привет, первопроходец! У нас есть припасы для вашего \
                  путешествия к Ориону. Но бесплатно не отдадим!"
                )}
              </Box>
            </Stack.Item>
            {spaceport_raided && (
              <>
                <Stack.Item>
                  Порт под усиленной охраной. Возможность
                  купить что-либо давно упущена.
                </Stack.Item>
                <Stack.Item grow />
              </>
            ) || (
              <>
                <Stack.Item>
                  Общий рынок:
                </Stack.Item>
                <Stack.Item>
                  <Stack mb={-1} fill>
                    <Stack.Item grow basis={0}>
                      <Stack vertical>
                        <Stack.Item>
                          <Button
                            fluid
                            icon="gas-pump"
                            content={"5 еды → 5 топлива"}
                            color="green"
                            onClick={() => act('trade', {
                              what: 2,
                            })} />
                        </Stack.Item>
                        <Divider />
                        <Stack.Item mt={0}>
                          Ангар порта:
                        </Stack.Item>
                        <Stack.Item mb={marketButtonSpacing}>
                          <Button
                            fluid
                            icon="wrench"
                            content={"Обшивка за 5 топлива"}
                            color="average"
                            onClick={() => act('buyparts', {
                              part: 2,
                            })} />
                        </Stack.Item>
                        <Stack.Item mb={marketButtonSpacing}>
                          <Button
                            fluid
                            icon="server"
                            content={"Электроника за 5 топлива"}
                            color="blue"
                            onClick={() => act('buyparts', {
                              part: 3,
                            })} />
                        </Stack.Item>
                        <Stack.Item mb={marketButtonSpacing}>
                          <Button
                            fluid
                            icon="rocket"
                            content={"Двигатель за 5 топлива"}
                            color="violet"
                            onClick={() => act('buyparts', {
                              part: 1,
                            })} />
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>
                    <Stack.Item grow basis={0}>
                      <Stack vertical>
                        <Stack.Item>
                          <Button
                            fluid
                            icon="hamburger"
                            content={"5 топлива → 5 еды"}
                            color="olive"
                            onClick={() => act('trade', {
                              what: 1,
                            })} />
                        </Stack.Item>
                        <Divider />
                        <Stack.Item mt={0}>
                          Бар порта:
                        </Stack.Item>
                        <Stack.Item mb={marketButtonSpacing}>
                          <Button
                            fluid
                            icon="user-plus"
                            content={"Экипаж за 10 еды, 10 топлива"}
                            color="white"
                            onClick={() => act('buycrew')} />
                        </Stack.Item>
                        <Stack.Item mb={marketButtonSpacing}>
                          <Button
                            fluid
                            icon="user-minus"
                            content={"Продать экипаж: 7 еды, 7 топлива"}
                            color="black"
                            onClick={() => act('sellcrew')} />
                        </Stack.Item>
                        <Stack.Item mb={marketButtonSpacing}>
                          <Button
                            fluid
                            icon="meteor"
                            content={"Странный экипаж (та же цена)"}
                            color="purple"
                            onClick={() => act('buycrew', {
                              odd: 1,
                            })} />
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </>
            )}

          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <AdventureStatus />
      </Stack.Item>
    </Stack>
  );
};

export const OrionGame = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    gamestatus,
    gamename,
    eventname,
  } = data;
  const GameStatusComponent = STATUS2COMPONENT[gamestatus].component();
  const MarketRaid = STATUS2COMPONENT[2].component();
  return (
    <Window
      title={gamename}
      width={400}
      height={500}>
      <Window.Content>
        {eventname === "Space Port Raid" && (
          <MarketRaid />
        ) || (
          <GameStatusComponent />
        )}
      </Window.Content>
    </Window>
  );
};
