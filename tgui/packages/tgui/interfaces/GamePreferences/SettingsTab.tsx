import { Button, Section, Stack } from '../../components';
import { AdminSection } from './AdminSection';
import { ChatSection } from './sections/ChatSection';
import { ContentSection } from './sections/ContentSection';
import { GameplaySection } from './sections/GameplaySection';
import { GraphicsSection } from './sections/GraphicsSection';
import { SoundsSection } from './sections/SoundsSection';

const BASE_CATEGORIES = [
  { key: 'sounds', label: 'Звуки', section: SoundsSection },
  { key: 'graphics', label: 'Графика', section: GraphicsSection },
  { key: 'chat', label: 'Чат', section: ChatSection },
  { key: 'gameplay', label: 'Геймплей', section: GameplaySection },
  { key: 'content', label: 'Контент', section: ContentSection },
];

const scrollToCategory = (key: string) => {
  document.getElementById(`prefs-${key}`)?.scrollIntoView({
    behavior: 'smooth',
    block: 'start',
  });
};

export const SettingsTab = (props) => {
  const { has_admin } = props;

  const categories = has_admin
    ? [...BASE_CATEGORIES, { key: 'admin', label: 'Админ', section: AdminSection }]
    : BASE_CATEGORIES;

  return (
    <Stack vertical fill className="GamePreferences__settings">
      <Stack.Item>
        <Section fitted className="GamePreferences__nav">
          <Stack fill px={1}>
            {categories.map(({ key, label }) => (
              <Stack.Item key={key} grow basis="content">
                <Button
                  align="center"
                  fluid
                  color="transparent"
                  className="GamePreferences__navButton"
                  onClick={() => scrollToCategory(key)}
                >
                  {label}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Section fill scrollable className="GamePreferences__scroll">
          <Stack vertical px={1} py={1}>
            {categories.map(({ key, label, section: SectionComponent }) => (
              <div
                key={key}
                id={`prefs-${key}`}
                className="GamePreferences__category"
              >
                <Section
                  title={label}
                  className="GamePreferences__categorySection"
                >
                  <SectionComponent />
                </Section>
              </div>
            ))}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
