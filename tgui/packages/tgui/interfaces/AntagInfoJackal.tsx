import { useBackend } from '../backend';
import { Section, Stack } from '../components';
import { Window } from '../layouts';
import { type Objective, ObjectivePrintout } from './AntagInfoInteQ';

type Info = {
  antag_name: string;
  objectives: Objective[];
};

export const AntagInfoJackal = (props) => {
  const { data } = useBackend<Info>();
  const { antag_name, objectives } = data;
  return (
    <Window width={620} height={500}>
      <Window.Content>
        <Section fill scrollable>
          <Stack vertical>
            <Stack.Item fontSize="20px" textColor="red">
              You are the {antag_name}!
            </Stack.Item>
            <Stack.Item>
              <ObjectivePrintout objectives={objectives} />
            </Stack.Item>
            <Stack.Item>
              <Section fill>
                Ты — <span style={{ color: '#ff0000', fontWeight: 'bold' }}>Безымянный Ликвидатор</span>. Твое имя стерто из баз данных
                Солнечной Федерации, а твое прошлое давно сгорело в пепле грязных контрактов.
                <br />Твоя кровь кипит от чудовищной дозы боевых стимуляторов, а реальность давно превратилась в психоделический кошмар.
                Окружающие люди для тебя — не более чем мишени, глупый и бесполезный шум в твоей раскалывающейся голове.
                <br />У тебя осталась лишь одна цель: <span style={{ color: '#ff0000', fontWeight: 'bold' }}>
                  закрыть этот финальный контракт, выкосив станцию подчистую
                </span>, и красиво сгореть в неоновой вспышке собственной смерти под аплодисменты воображаемого друга.
                <br /><br />Твои особые сигареты лечат тебя. Если в крови не останется алкоголя, Omnizine или стимуляторов, тело начнет постепенно разрушаться.
                <br />В холстере лежат два stimpack medipen, три эпипена и один боевой нож. Эпипены почти не лечат, зато останавливают кровотечение.
                <br />Казнь выполняется выстрелом из револьвера по критованной цели. После пяти казней твой револьвер становится куда более кровожадным, уменьшая отдачу и увеличивая темп стрельбы.
                <br /><br /><span style={{ color: '#ff0000', fontWeight: 'bold' }}>Докуривай сигарету — и погнали</span>
              </Section>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
