import { useBackend } from '../backend';
import { BlockQuote, Icon, Section, Stack } from '../components';
import { Window } from '../layouts';

type Info = {
  antag_name: string;
  gang_name: string;
  gang_objective: string;
  gang_clothes: string[];
};

export const AntagInfoGangmember = (props) => {
  const { data } = useBackend<Info>();
  const {
    gang_name,
    antag_name,
  } = data;
  return (
    <Window
      width={620}
      height={500}>
      <Window.Content
        style={{
          backgroundImage: 'none',
        }}>
        <Section fill>
          <Stack vertical>
            <Stack.Item textColor="red" fontSize="20px">
              {gang_name} вперёд! Ты - {antag_name}!
            </Stack.Item>
            <Stack.Item fontSize="18px">
              Будучи членом банды, прежде всего поддерживайте свою семью!
              Помечайте Отделы с помощью баллончика, носите одежду Семьи,
              приглашайте экипаж в свою банду при помощи пакетиков
              и выполняйте свою семейную задачу.
            </Stack.Item>
            <Stack.Divider />
            <Stack.Item>
              <Stack fill>
                <Stack.Item grow basis={0}>
                  <GangClothesPrintout />
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <GangPhonePrintout />
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Divider />
            <Stack.Item grow basis={0}>
              <GangObjectivePrintout />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

const GangClothesPrintout = (props) => {
  const { data } = useBackend<Info>();
  const {
    gang_name,
    gang_clothes,
  } = data;
  return (
    <Stack vertical>
      <Stack.Item>
        <Stack>
          <Stack.Item mt={0.5} mb={1}>
            <Icon
              size={2}
              name="tshirt" />
          </Stack.Item>
          <Stack.Item bold>
            Носите это, чтобы представлять {gang_name}:
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <BlockQuote>
        {gang_clothes && gang_clothes.length ? (
          gang_clothes.map(clothes_item => (
            <Stack.Item key={clothes_item}>
              - {clothes_item}
            </Stack.Item>
          ))
        ) : (
          "- Anything!"
        )}
      </BlockQuote>
    </Stack>
  );
};

const GangPhonePrintout = () => {
  return (
    <Stack vertical>
      <Stack.Item>
        <Stack>
          <Stack.Item mt={0.5}>
            <Icon
              size={2}
              name="phone" />
          </Stack.Item>
          <Stack.Item bold>
            Вам был выдан сотовый телефон для связи!
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <BlockQuote>
          Используйте его для переговоров с членами
          своей семьи.
        </BlockQuote>
      </Stack.Item>
    </Stack>
  );
};


const GangObjectivePrintout = (props) => {
  const { data } = useBackend<Info>();
  const {
    gang_objective,
  } = data;
  return (
    <Stack vertical>
      <Stack.Item bold fontSize="16px">
        Цель Твоей Семьи:
      </Stack.Item>
      <Stack.Item>
        {gang_objective
          || "No objective set! This is a problem!"}
      </Stack.Item>
    </Stack>
  );
};
