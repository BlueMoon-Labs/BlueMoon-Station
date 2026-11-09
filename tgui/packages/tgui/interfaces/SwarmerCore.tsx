import { useState } from 'react';
import {
  Button,
  ImageButton,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type SwarmerCoreData = {
  classes: Class[];
  organic_resources: number;
  metallic_resources: number;
  organic_goal: number;
  metal_reference: number;
  cheaper_swap: boolean;
  current_class_path: string;
};

type Class = {
  name: string;
  desc: string;
  path: string;
  icon: string;
  additional_info: string;
  cost: number;
};

const SwarmerGoalProgressBar = (props: unknown) => {
  const { data } = useBackend<SwarmerCoreData>();
  const { organic_goal = 0, organic_resources = 0 } = data;

  return (
    <Stack.Item>
      <Section title="Органические ресурсы">
        <Stack fill>
          <Stack.Item grow>
            <ProgressBar
              fontSize="small"
              color={organic_resources >= organic_goal ? 'good' : 'average'}
              value={organic_resources}
              minValue={0}
              maxValue={organic_goal}
            >
              {organic_resources} / {organic_goal}
            </ProgressBar>
          </Stack.Item>
        </Stack>
      </Section>
    </Stack.Item>
  );
};

export const SwarmerCore = (_props: unknown) => {
  const { act, data } = useBackend<SwarmerCoreData>();
  const {
    classes,
    cheaper_swap,
    current_class_path,
    metallic_resources,
    metal_reference,
  } = data;
  const [selectedInfo, setSelectedInfo] = useState<string>('');
  const [selectedClass, setSelectedClass] = useState<Class | null>(null);
  const classCost = selectedClass
    ? cheaper_swap
      ? Math.round(selectedClass.cost / 2)
      : selectedClass.cost
    : null;

  const handleClassSelect = (classInfo: Class) => {
    setSelectedInfo(classInfo.additional_info);
    setSelectedClass(classInfo);
  };

  const handleConfirm = () => {
    if (selectedClass) {
      act('select_class', {
        class: selectedClass.path,
      });
    }
  };

  return (
    <Window width={800} height={600}>
      <Window.Content>
        <Stack fill vertical>
          <SwarmerGoalProgressBar />
          <Stack.Item>
            <Section title="Металлические ресурсы">
              <ProgressBar
                fontSize="small"
                color={
                  classCost !== null && metallic_resources < classCost
                    ? 'bad'
                    : 'blue'
                }
                value={metallic_resources}
                minValue={0}
                maxValue={classCost ?? metal_reference}
              >
                {metallic_resources.toLocaleString('ru-RU', {
                  maximumFractionDigits: 2,
                })}{' '}
                ед.{classCost !== null && ` / ${classCost} за корпус`}
              </ProgressBar>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item width={20}>
                <Section textAlign="center" title="Классы" fill scrollable>
                  <Stack vertical fill>
                    {classes.map((classInfo) =>
                      current_class_path === classInfo.path ? null : (
                        <Stack.Item textAlign="center" key={classInfo.path}>
                          <ImageButton
                            color={'blue'}
                            imageSrc={classInfo.icon}
                            imageSize={90}
                            tooltip={
                              <>
                                <b>{classInfo.name}</b>
                                <br />
                                {classInfo.desc}
                              </>
                            }
                            onClick={() => handleClassSelect(classInfo)}
                            aria-pressed={selectedClass?.path === classInfo.path}
                            aria-label={classInfo.name}
                          />
                        </Stack.Item>
                      ),
                    )}
                  </Stack>
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Stack fill vertical>
                  <Stack.Item grow>
                    <Section
                      title="Дополнительная информация"
                      fill
                      scrollable
                      px={2}
                    >
                      <pre
                        style={{
                          fontFamily: 'inherit',
                          margin: 5,
                          fontSize: '15px',
                          whiteSpace: 'pre-wrap',
                          wordWrap: 'break-word',
                        }}
                      >
                        {selectedInfo ||
                          'Выберите класс для просмотра информации'}
                      </pre>
                    </Section>
                  </Stack.Item>
                  <Stack.Item>
                    <Section>
                      <Button
                        fluid
                        textAlign="center"
                        lineHeight="35px"
                        fontSize="1.2em"
                        height="40px"
                        disabled={!selectedClass}
                        onClick={handleConfirm}
                        color={selectedClass ? 'green' : 'grey'}
                      >
                        {selectedClass
                          ? `Стоимость: ${classCost} металла. Подтвердить выбор: ${selectedClass.name}`
                          : 'Выберите класс'}
                      </Button>
                    </Section>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
