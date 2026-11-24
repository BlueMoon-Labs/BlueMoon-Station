import { useBackend } from '../backend';
import { Box, Icon, Section, Stack } from '../components';
import { Window } from '../layouts';

type Data = {
  help_text: string;
};

const DEFAULT_HELP = `Информация недоступна! При необходимости обратитесь за помощью.`;

const boxHelp = [
  {
    color: 'purple',
    text: 'Изучите местность и сделайте всё необходимое, чтобы найти ящик. Внимательно читайте информацию о домене и подсказки.',
    icon: 'search-location',
    title: 'Поиск',
  },
  {
    color: 'green',
    text: 'Доставьте ящик в назначенное место отправки в сейфхаусе. Оно может выглядеть неуместно — осмотрите сейфхаус.',
    icon: 'boxes',
    title: 'Доставка',
  },
  {
    color: 'blue',
    text: 'Лестница — самый безопасный способ отключиться до получения кэша. Если связь оборвётся, нетпод даст ограниченную реанимацию.',
    icon: 'plug',
    title: 'Отключение',
  },
  {
    color: 'yellow',
    text: 'Подключение частично защищает от окружающей среды и вторжений, но не полностью. Следите за уведомлениями.',
    icon: 'id-badge',
    title: 'Безопасность',
  },
  {
    color: 'gold',
    text: 'Создание аватаров расходует много пропускной способности. Не тратьте их зря.',
    icon: 'coins',
    title: 'Ограниченные попытки',
  },
  {
    color: 'red',
    text: 'Помните: вы физически связаны с аватаром. Вы чужеродное тело во враждебной среде, и она попытается выбросить вас силой.',
    icon: 'skull-crossbones',
    title: 'Реальная опасность',
  },
] as const;

export const AvatarHelp = (props) => {
  const { data } = useBackend<Data>();
  const { help_text = DEFAULT_HELP } = data;

  return (
    <Window title="Информация о домене" width={700} height={700}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item grow={2} basis={0} minHeight={9}>
            <Section
              color="good"
              fill
              scrollable
              title="Добро пожаловать в виртуальный домен."
            >
              {help_text}
            </Section>
          </Stack.Item>
          <Stack.Item grow={5} basis={0}>
            <Stack fill vertical>
              <Stack.Item grow basis={0}>
                <Stack fill>
                  {[0, 1].map((i) => (
                    <BoxHelp index={i} key={i} />
                  ))}
                </Stack>
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <Stack fill>
                  {[2, 3].map((i) => (
                    <BoxHelp index={i} key={i} />
                  ))}
                </Stack>
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <Stack fill>
                  {[4, 5].map((i) => (
                    <BoxHelp index={i} key={i} />
                  ))}
                </Stack>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const BoxHelp = (props: { index: number }) => {
  const { index } = props;

  return (
    <Stack.Item grow basis={0}>
      <Section
        color="label"
        fill
        minHeight={9}
        title={
          <Stack align="center">
            <Icon
              color={boxHelp[index].color}
              mr={1}
              name={boxHelp[index].icon}
            />
            <Box>{boxHelp[index].title}</Box>
          </Stack>
        }
      >
        {boxHelp[index].text}
      </Section>
    </Stack.Item>
  );
};
