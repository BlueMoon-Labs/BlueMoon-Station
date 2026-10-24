import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  Input,
  Section,
  Stack,
} from '../../../components';
import { TabDataMissing, TextAreaRow } from '../components';

interface BackgroundData {
  flavorText: string;
  nakedFlavorText: string;
  siliconFlavorText: string;
  tasteText: string;
  smellText: string;
  speciesLore: string;
  oocNotes: string;
  deathgasp: string;
  securityRecords: string;
  medicalRecords: string;
  headshots: (string | null)[];
  nakedHeadshots: (string | null)[];
  headshotMaxLen: number;
  assPhoto: string;
  flavorMaxLen: number;
  tasteMaxLen: number;
  deathgaspMaxLen: number;
}

interface BackgroundContext {
  background: BackgroundData;
}

const FORMAT_HINT =
  'Поддерживается форматирование: *курсив* !жирный! -=цвет=-, '
  + '## заголовок, ((скобки)), [спойлер]';

export const BackgroundTab = () => {
  const { act, data } = useBackend<BackgroundContext>();
  const background = data.background;

  if (!background) {
    return <TabDataMissing title="Предыстория" />;
  }

  const flavorLen = background.flavorMaxLen || 4096;
  const tasteLen = background.tasteMaxLen || 4096;

  return (
    <Stack fill>
      <Stack.Item grow basis={0} pr={2}>
        <Section fill scrollable title="Описания">
          <Button
            icon="question"
            content="Формат описания"
            mb={1}
            tooltip={FORMAT_HINT}
            onClick={() => act('format_help')}
          />
          <TextAreaRow
            label="Описание при осмотре"
            tooltip={FORMAT_HINT}
            value={background.flavorText}
            action="set_flavor_text"
            maxLength={flavorLen}
            height="150px"
            placeholder="Что видно, когда на персонажа смотрят"
            editField="flavor_text"
          />
          <TextAreaRow
            label="Описание без одежды"
            tooltip={FORMAT_HINT}
            value={background.nakedFlavorText}
            action="set_naked_flavor_text"
            maxLength={flavorLen}
            placeholder="Текст поверх обнажённого персонажа"
            editField="naked_flavor_text"
          />
          <TextAreaRow
            label="Описание силикона"
            tooltip={FORMAT_HINT}
            value={background.siliconFlavorText}
            action="set_silicon_flavor_text"
            maxLength={flavorLen}
            placeholder="Особенности корпуса борга"
            editField="silicon_flavor_text"
          />
          <TextAreaRow
            label="Описание вкуса"
            value={background.tasteText}
            action="set_taste"
            maxLength={tasteLen}
            placeholder="На вкус персонаж похож на... (узнаётся при облизывании *lick)"
            editField="taste"
          />
          <TextAreaRow
            label="Описание запаха"
            value={background.smellText}
            action="set_smell"
            maxLength={tasteLen}
            placeholder="Запах персонажа... (узнаётся при обнюхивании *sniff)"
            editField="smell"
          />
          <TextAreaRow
            label="Охранные записи"
            tooltip={FORMAT_HINT}
            value={background.securityRecords}
            action="set_security_records"
            maxLength={flavorLen}
            height="90px"
            placeholder="Что найдёт служба безопасности"
            editField="security_records"
          />
          <TextAreaRow
            label="Медицинские записи"
            tooltip={FORMAT_HINT}
            value={background.medicalRecords}
            action="set_medical_records"
            maxLength={flavorLen}
            height="90px"
            placeholder="Что найдёт медслужба"
            editField="medical_records"
          />
        </Section>
      </Stack.Item>

      <Stack.Item grow basis={0} pr={2}>
        <Section fill scrollable title="Предыстория и смерть">
          <Button
            icon="question"
            content="Формат описания"
            mb={1}
            tooltip={FORMAT_HINT}
            onClick={() => act('format_help')}
          />
          <TextAreaRow
            label="Предыстория вида"
            tooltip={FORMAT_HINT}
            value={background.speciesLore}
            action="set_species_lore"
            maxLength={flavorLen}
            placeholder="История и культура вашего вида"
            editField="species_lore"
          />
          <TextAreaRow
            label="OOC-заметки"
            tooltip={FORMAT_HINT}
            value={background.oocNotes}
            action="set_ooc_notes"
            maxLength={flavorLen}
            placeholder="Всегда видимые заметки о предпочтениях"
            editField="ooc_notes"
          />
          <TextAreaRow
            label="Эмоут смерти"
            tooltip={FORMAT_HINT}
            value={background.deathgasp}
            action="set_deathgasp"
            maxLength={background.deathgaspMaxLen || 1024}
            height="80px"
            placeholder="Что произойдёт при смерти"
            editField="deathgasp"
          />
        </Section>
      </Stack.Item>

      <Stack.Item grow basis={0}>
        <Section fill scrollable title="Фотографии">
          <HeadshotGrid
            title="Фотографии"
            listKind="regular"
            slots={background.headshots}
            maxLength={background.headshotMaxLen || 400}
          />
          <HeadshotGrid
            title="Фотографии (NSFW)"
            listKind="naked"
            slots={background.nakedHeadshots}
            maxLength={background.headshotMaxLen || 400}
          />
          <HeadshotGrid
            title="Ass Shot"
            listKind="ass"
            single
            slots={[background.assPhoto || null]}
            maxLength={background.headshotMaxLen || 400}
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const HeadshotGrid = (props: {
  title: string;
  listKind: 'regular' | 'naked' | 'ass';
  slots: (string | null)[];
  maxLength: number;
  single?: boolean;
}) => {
  const { act } = useBackend<any>();
  const { title, listKind, slots, maxLength, single } = props;

  return (
    <Section title={title} mt={1}>
      <Stack wrap>
        {(slots || []).map((link, index) => (
          <Stack.Item
            key={index}
            style={{ width: '100%', marginBottom: '0.5em' }}
          >
            {link ? (
              <Box
                style={{
                  display: 'flex',
                  width: '100%',
                  aspectRatio: '1',
                  alignItems: 'center',
                  justifyContent: 'center',
                  overflow: 'hidden',
                  border: '1px solid rgba(255, 255, 255, 0.12)',
                  borderRadius: '3px',
                  backgroundColor: 'rgba(0, 0, 0, 0.35)',
                }}
              >
                <Box
                  as="img"
                  src={link}
                  style={{
                    maxWidth: '100%',
                    maxHeight: '100%',
                    objectFit: 'contain',
                  }}
                />
              </Box>
            ) : null}
            <Stack align="center" mt={link ? 1 : 0}>
              <Stack.Item grow>
                <Input
                  fluid
                  maxLength={maxLength}
                  placeholder={single ? 'Ссылка' : `Ссылка ${index + 1}`}
                  value={link || ''}
                  onChange={(e, value) =>
                    act('set_headshot', {
                      list: listKind,
                      slot: index + 1,
                      url: value,
                    })
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="times"
                  color="bad"
                  tooltip="Убрать фото"
                  disabled={!link}
                  onClick={() =>
                    act('set_headshot', {
                      list: listKind,
                      slot: index + 1,
                      url: '',
                    })
                  }
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};
