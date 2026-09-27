import { useBackend } from "../backend";
import { Flex, Icon, Section, Table } from "../components";
import { Window } from "../layouts";

const commandJobs = [
  "Captain",
  "Head of Personnel",
  "Head of Security",
  "Chief Engineer",
  "Research Director",
  "Chief Medical Officer",
  "Quartermaster",
];

const departmentNames = {
  Command: "Командование",
  Security: "Служба Безопасности",
  Engineering: "Инженерный отдел",
  Medical: "Медицинский отдел",
  Science: "Научный отдел",
  Supply: "Отдел снабжения",
  Service: "Отдел сервиса",
  Silicon: "Синтетика",
  Law: "Юридический отдел",
  Misc: "Прочее",
};

export const CrewManifest = (props) => {
  const { data: { manifest, positions } } = useBackend();

  return (
    <Window title="Манифест экипажа" width={440} height={550}>
      <Window.Content overflow="auto">
        {Object.entries(manifest).map(([department, crew]) => (
          <Section
            className={"CrewManifest--" + department}
            key={department}
            title={
              <Flex style={{ width: '100%' }}>
                <Flex.Item>
                  {departmentNames[department] || department}
                </Flex.Item>
                <Flex.Item grow textAlign="right">
                  (Открытых позиций: {positions[department]})
                </Flex.Item>
              </Flex>
            }
          >
            <Table>
              {Object.entries(crew).map(([crewIndex, crewMember]) => (
                <Table.Row key={crewIndex}>
                  <Table.Cell className={"CrewManifest__Cell"}>
                    {crewMember.name}
                  </Table.Cell>
                  <Table.Cell
                    className={
                      "CrewManifest__Cell CrewManifest__Cell--"
                      + (crewMember.department_check === "Captain" ? "Captain" : "Command")
                    }
                    collapsing
                  >
                    {commandJobs.includes(crewMember.department_check) && (
                      <Icon
                        name={
                          crewMember.department_check === "Captain" ? "star" : "chevron-up"
                        }
                      />
                    )}
                  </Table.Cell>
                  <Table.Cell
                    className={"CrewManifest__Cell"}
                    collapsing
                    color="label"
                  >
                    {crewMember.rank}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};
