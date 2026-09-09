import { Section, Stack } from '../components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { type Objective, ObjectivePrintout } from './AntagInfoInteQ';

type Info = {
  antag_name: string;
  objectives: Objective[];
  shotgun: boolean;
  pistols: boolean;
};

// SKYRAT EDIT increase height from 250 to 500
export const AntagInfoHatred = (props) => {
  const { data } = useBackend<Info>();
  const { antag_name, objectives } = data;
  return (
    <Window width={620} height={500}>
      <Window.Content>
        <Section scrollable fill>
          <Stack vertical>
            <Stack.Item textColor="red" fontSize="20px">
              You are the {antag_name}!
            </Stack.Item>
            <Stack.Item>
              <ObjectivePrintout objectives={objectives} />
            </Stack.Item>
            <Stack.Item>
              <Section fill>
                Ты - <span style={{color: '#ff0000', fontWeight: 'bold'}}>Безымянный Массшутер</span>.
                Твое имя совершенно неважно. Твое прошлое даже если и было, оно было незавидным.
	              <br />Ты испытываешь непреодолимую ненависть, отвращение и презрение ко всем окружающим.
	              <br />У тебя лишь две цели: <u>убивать</u> и <u>умереть славной смертью</u>.
	              <br /><br /><span style={{color: '#ff0000', fontWeight: 'bold'}}>Не торопись и
                познакомься со своими инструментами геноцида. В бою у тебя не будет такой возможности.
                Соберись с мыслями и отправляйся на станцию когда будешь готов.</span>
                <br /><br />Твое проклятое снаряжение неразлучно с тобою и подстегивает тебя продолжать
                соврешать геноцид беззащитных гражданских.
	              <br />Твоё <span style={{color: '#ff0000'}}>Оружие Ненависти</span> и неутолимая жажда
                убивать вознаграждают тебя, ибо завершающий выстрел в упор в голову (рот) исцеляет твои
                раны и даёт прилив сил, нож добивает быстрее и надежнее.
	              <br /><br /><span style={{color: '#ff0000'}}>Обычная медицина не лечит раны и ожоги!</span>
                <ShotgunInfo />
                <PistolsInfo />
	              <br /><br /><span style={{color: '#ff0000', fontWeight: 'bold'}}>Время убивать. Время умирать.</span> И
                пусть ни одна мразь не доживёт до завтра. Ибо никто сегодня не защищен от твоей Ненависти.
              </Section>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

const PistolsInfo = (props) => {
  const { data } = useBackend<Info>();
  const { pistols } = data;
  if (pistols) {
    return (
      <Section fill>
        <span style={{color: '#ff0000'}}>Стрелять с двух рук - HARM INTENT.</span>
      </Section>
    );
  }
};

const ShotgunInfo = (props) => {
  const { data } = useBackend<Info>();
  const { shotgun } = data;
  if (shotgun) {
    return (
      <Section fill>
        Акимбо: Ты можешь стрелять из оружия одной рукой, даже если вторая занята, но
        забудь про автоматическую стрельбу. С твоим дробовиком это только бонус.
        <br />На твоем поясе висит <span style={{color: '#ff0000'}}>запасная двустволка</span> для
        быстрой стрельбы другим типом боеприпасов. Заряжена выбивающими двери и окна патронами.
      </Section>
    );
  }
};
