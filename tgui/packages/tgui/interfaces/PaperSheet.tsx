/**
 * @license MIT
 */

import { clamp } from 'common/math';
import { classes } from 'common/react';
import { Marked } from 'marked';
import { Component, createRef, RefObject } from 'react';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section, TextArea } from '../components';
import { Window } from '../layouts';
import { sanitizePaperMarkup } from '../sanitize';
import { PaperMarkup } from './common/PaperMarkup';

const Z_INDEX_STAMP = 1;
const Z_INDEX_STAMP_PREVIEW = 2;

const TEXTAREA_INPUT_HEIGHT = 200;

type PaperContext = {
  // ui_static_data
  user_name: string;
  raw_text_input?: PaperInput[];
  raw_field_input?: FieldInput[];
  raw_stamp_input?: StampInput[];
  max_length: number;
  max_input_field_length: number;
  paper_color: string;
  paper_name: string;
  default_pen_font: string;
  default_pen_color: string;
  signature_font: string;

  // ui_data
  held_item_details?: WritingImplement;
  can_use_advanced_html: boolean;
};

type PaperInput = {
  raw_text: string;
  font?: string;
  color?: string;
  bold?: boolean;
  advanced_html?: boolean;
};

type StampInput = {
  class: string;
  x: number;
  y: number;
  rotation: number;
};

type FieldInput = {
  field_index: string;
  field_data: PaperInput;
  is_signature: boolean;
};

type WritingImplement = {
  interaction_mode: InteractionType;
  font?: string;
  color?: string;
  use_bold?: boolean;
  stamp_icon_state?: string;
  stamp_class?: string;
};

type PaperSheetStamperState = {
  x: number;
  y: number;
  rotation: number;
  yOffset: number;
};

type PaperSheetStamperProps = {
  scrollableRef: RefObject<HTMLDivElement>;
};

type FieldCreationReturn = {
  nextCounter: number;
  fragment: DocumentFragment;
};

type StampPosition = {
  x: number;
  y: number;
  rotation: number;
  yOffset: number;
};

enum InteractionType {
  reading = 0,
  writing = 1,
  stamping = 2,
}

type PreviewViewProps = {
  scrollableRef: RefObject<HTMLDivElement>;
  handleOnScroll: (this: GlobalEventHandlers, ev: Event) => any;
  textArea: string;
};

const canEdit = (heldItemDetails?: WritingImplement): boolean => {
  if (!heldItemDetails) {
    return false;
  }

  return heldItemDetails.interaction_mode === InteractionType.writing;
};

// Regex that finds [____] fields.
const fieldRegex: RegExp = /\[((?:_+))\]/gi;

const paperMarkdown = new Marked({
  extensions: [{
    name: 'inputField',
    level: 'inline',
    start: (text) => text.indexOf('['),
    tokenizer(text) {
      const match = /^\[_+\]/.exec(text);
      if (match) {
        return { type: 'inputField', raw: match[0] };
      }
    },
    renderer: (token) => token.raw,
  }],
  breaks: true,
  gfm: true,
  walkTokens(token) {
    switch (token.type) {
      case 'url':
      case 'autolink':
      case 'reflink':
      case 'link':
      case 'image':
        token.type = 'text';
        break;
    }
  },
});

// Handles the ghost stamp when attempting to stamp paper sheets.
class PaperSheetStamper extends Component<PaperSheetStamperProps> {
  style: null;
  state: PaperSheetStamperState = { x: 0, y: 0, rotation: 0, yOffset: 0 };
  scrollableRef: RefObject<HTMLDivElement>;

  constructor(props, context) {
    super(props, context);

    this.style = null;
    this.scrollableRef = props.scrollableRef;
  }

  // Stops propagation of a given event.
  pauseEvent = (e: Event): boolean => {
    if (e.stopPropagation) {
      e.stopPropagation();
    }
    if (e.preventDefault) {
      e.preventDefault();
    }
    e.cancelBubble = true;
    e.returnValue = false;
    return false;
  };

  // The mousemove/click listeners live on the document and survive any
  // held item changes: without this gate every click on the UI (with a pen,
  // with nothing) would fire an add_stamp act at the server.
  isStamping = (): boolean => {
    const { data } = useBackend<PaperContext>();
    const { held_item_details } = data;
    return (
      held_item_details?.interaction_mode === InteractionType.stamping
      && !!held_item_details?.stamp_class
    );
  };

  handleMouseMove = (e: MouseEvent): void => {
    if (!this.isStamping()) {
      return;
    }
    const pos = this.findStampPosition(e);
    if (!pos) {
      return;
    }

    this.pauseEvent(e);
    this.setState({
      x: pos.x,
      y: pos.y,
      rotation: pos.rotation,
      yOffset: pos.yOffset,
    });
  };

  handleMouseClick = (e: MouseEvent): void => {
    if (!this.isStamping()) {
      return;
    }
    const scrollable = this.scrollableRef.current;
    if (!scrollable) {
      return;
    }
    const rect = scrollable.getBoundingClientRect();
    // Ignore clicks outside the container
    if (e.clientY - rect.top <= 0) {
      return;
    }
    const { act } = useBackend<PaperContext>();

    act('add_stamp', {
      x: this.state.x,
      y: this.state.y + this.state.yOffset,
      rotation: this.state.rotation,
    });
  };

  findStampPosition(e: MouseEvent): StampPosition | void {
    let rotating;
    const scrollable = this.scrollableRef.current;

    if (!scrollable) {
      return;
    }

    const stampYOffset = scrollable.scrollTop || 0;

    const stamp = document.getElementById('stamp');
    if (!stamp) {
      return;
    }

    if (e.shiftKey) {
      rotating = true;
    }

    const stampHeight = stamp.clientHeight;
    const stampWidth = stamp.clientWidth;

    // CSS zoom on body (for DPI compensation) makes getBoundingClientRect()
    // return viewport pixels, but CSS left/top use layout pixels.
    // Divide by zoom to convert viewport → layout coordinates.
    const zoom = parseFloat(document.body.style.zoom) / 100 || 1;

    // Convert to container-relative coordinates (in layout pixels)
    const rect = scrollable.getBoundingClientRect();
    const relativeX = (e.clientX - rect.left) / zoom;
    const relativeY = (e.clientY - rect.top) / zoom;

    const currentHeight = rotating
      ? this.state.y
      : relativeY - stampHeight;
    const currentWidth = rotating
      ? this.state.x
      : relativeX - stampWidth / 2;

    const widthMin = 0;
    const heightMin = 0;

    const widthMax = scrollable.clientWidth - stampWidth;
    const heightMax = scrollable.clientHeight - stampHeight;

    const radians = Math.atan2(
      currentWidth + stampWidth / 2 - relativeX,
      currentHeight + stampHeight - relativeY
    );

    const rotate = rotating
      ? radians * (180 / Math.PI) * -1
      : this.state.rotation;

    return {
      x: clamp(currentWidth, widthMin, widthMax),
      y: clamp(currentHeight, heightMin, heightMax),
      rotation: rotate,
      yOffset: stampYOffset,
    };
  }

  componentDidMount() {
    document.addEventListener('mousemove', this.handleMouseMove);
    document.addEventListener('click', this.handleMouseClick);
  }

  componentWillUnmount() {
    document.removeEventListener('mousemove', this.handleMouseMove);
    document.removeEventListener('click', this.handleMouseClick);
  }

  render() {
    const { data } = useBackend<PaperContext>();
    const { held_item_details } = data;

    if (!held_item_details?.stamp_class) {
      return;
    }

    return (
      <Stamp
        activeStamp
        opacity={0.5}
        sprite={held_item_details.stamp_class}
        x={this.state.x}
        y={this.state.y}
        rotation={this.state.rotation}
      />
    );
  }
}

// Creates a full stamp div to render the given stamp to the preview.
export const Stamp = (props) => {
  const { activeStamp, sprite, x, y, rotation, opacity, yOffset = 0 } = props;
  const stamp_transform = {
    'left': x + 'px',
    'top': y + yOffset + 'px',
    'transform': 'rotate(' + rotation + 'deg)',
    'opacity': opacity || 1.0,
    'zIndex': activeStamp ? Z_INDEX_STAMP_PREVIEW : Z_INDEX_STAMP,
  };

  return (
    <div
      id="stamp"
      className={classes(['Paper__Stamp', sprite])}
      style={stamp_transform}
    />
  );
};

// Overarching component that holds the primary view for papercode.
export class PrimaryView extends Component {
  // Reference that gets passed to the <Section> holding the main preview.
  // Eventually gets filled with a reference to the section's scroll bar
  // funtionality.
  scrollableRef: RefObject<HTMLDivElement>;

  // The last recorded distance the scrollbar was from the bottom.
  // Used to implement "text scrolls up instead of down" behaviour.
  lastDistanceFromBottom: number;

  // Event handler for the onscroll event. Also gets passed to the <Section>
  // holding the main preview. Updates lastDistanceFromBottom.
  onScrollHandler: (this: GlobalEventHandlers, ev: Event) => any;

  constructor(props, context) {
    super(props, context);
    this.scrollableRef = createRef();
    this.lastDistanceFromBottom = 0;

    this.onScrollHandler = (ev: Event) => {
      const scrollable = ev.currentTarget as HTMLDivElement;
      if (scrollable) {
        this.lastDistanceFromBottom
          = scrollable.scrollHeight - scrollable.scrollTop;
      }
    };
  }

  render() {
    const { act, data } = useBackend<PaperContext>();
    const {
      raw_text_input,
      raw_field_input,
      default_pen_font,
      default_pen_color,
      paper_color,
      held_item_details,
      max_length,
    } = data;

    const useFont = held_item_details?.font || default_pen_font;
    const useColor = held_item_details?.color || default_pen_color;
    const useBold = held_item_details?.use_bold || false;

    const [inputFieldData, setInputFieldData] = useLocalState('inputFieldData',
      {}
    );

    const [textAreaText, setTextAreaText] = useLocalState('textAreaText',
      ''
    );

    const interactMode
      = held_item_details?.interaction_mode || InteractionType.reading;

    const savableData
      = textAreaText.length || Object.keys(inputFieldData).length;

    const dmCharacters
      = raw_text_input?.reduce((lhs: number, rhs: PaperInput) => {
        return lhs + rhs.raw_text.length;
      }, 0) || 0;

    const usedCharacters = dmCharacters + textAreaText.length;

    const tooManyCharacters = usedCharacters > max_length;

    return (
      <>
        <PaperSheetStamper scrollableRef={this.scrollableRef} />
        <Flex direction="column" fillPositionedParent>
          <Flex.Item grow={3} basis={1}>
            <PreviewView
              key={`${raw_field_input?.length || 0}_
              ${raw_text_input?.length || 0}`}
              scrollableRef={this.scrollableRef}
              handleOnScroll={this.onScrollHandler}
              textArea={textAreaText}
            />
          </Flex.Item>
          {interactMode === InteractionType.writing && (
            <Flex.Item shrink={1} height={TEXTAREA_INPUT_HEIGHT + 'px'}>
              <Section
                title="Insert Text"
                fitted
                fill
                buttons={
                  <>
                    <Box
                      inline
                      pr={'5px'}
                      color={tooManyCharacters ? 'bad' : 'default'}>
                      {`${usedCharacters} / ${max_length}`}
                    </Box>
                    <Button.Confirm
                      disabled={!savableData || tooManyCharacters}
                      content="Save"
                      color="good"
                      onClick={() => {
                        const payload: Record<string, any> = {};
                        if (textAreaText.length) {
                          payload.text = textAreaText;
                        }
                        if (Object.keys(inputFieldData).length) {
                          payload.field_data = inputFieldData;
                        }
                        if (Object.keys(payload).length) {
                          act('save', payload);
                        }
                        setTextAreaText('');
                        setInputFieldData({});
                      }}
                    />
                  </>
                }>
                <TextArea
                  scrollbar
                  noborder
                  value={textAreaText}
                  textColor={useColor}
                  fontFamily={useFont}
                  bold={useBold}
                  height={'100%'}
                  backgroundColor={paper_color}
                  onInput={(e, text) => {
                    setTextAreaText(text);

                    // setTextAreaText re-renders asynchronously in React;
                    // measure the preview only after the new text committed.
                    requestAnimationFrame(() => {
                      if (this.scrollableRef.current) {
                        let thisDistFromBottom
                          = this.scrollableRef.current.scrollHeight
                          - this.scrollableRef.current.scrollTop;
                        this.scrollableRef.current.scrollTop
                          += thisDistFromBottom - this.lastDistanceFromBottom;
                      }
                    });
                  }}
                />
              </Section>
            </Flex.Item>
          )}
        </Flex>
      </>
    );
  }
}

// Собирает содержимое бумаги и предпросмотр из проверенных узлов.
export class PreviewView extends Component<PreviewViewProps> {
  // State checking variables. Used to determine whether or not to use cache.
  lastReadOnly: boolean = true;
  lastDMInput?: PaperInput[];
  lastFieldCount: number = 0;
  lastFieldInput?: FieldInput[];
  lastTextArea?: string;
  lastPreviewFieldCount?: number;
  lastAdvancedHtml?: boolean;

  // Cache variables for fully parsed text. Workaround for marked.js not being
  // super fast on the BYOND/IE js engine.
  parsedDMCache = document.createDocumentFragment();
  parsedTextBoxCache?: DocumentFragment;

  // Extracts the paper field "counter" from a full ID.
  getHeaderID = (header: string): string => {
    return header.replace('paperfield_', '');
  };

  // Сохраняет введённый текст полей при смене режима чтения и записи.
  onInputHandler = (ev: Event): void => {
    const input = ev.target;
    if (!(input instanceof HTMLInputElement) || !input.closest('.paper-text')) {
      return;
    }

    const [inputFieldData, setInputFieldData] = useLocalState('inputFieldData',
      {}
    );

    const { data } = useBackend<PaperContext>();
    const { default_pen_font, default_pen_color, held_item_details } = data;

    const newFieldData = { ...inputFieldData };
    if (input.value.length) {
      newFieldData[this.getHeaderID(input.id)] = input.value;
    } else {
      delete newFieldData[this.getHeaderID(input.id)];
    }
    setInputFieldData(newFieldData);
    input.style.fontFamily = held_item_details?.font || default_pen_font;
    input.style.color = held_item_details?.color || default_pen_color;
  };

  componentDidMount() {
    document.addEventListener('input', this.onInputHandler);
  }

  componentWillUnmount() {
    document.removeEventListener('input', this.onInputHandler);
  }

  // Creates the partial inline HTML for previewing or reading the paper from
  // only static_ui_data from DM.
  createPreviewFromDM = (): FieldCreationReturn => {
    const { data } = useBackend<PaperContext>();
    const {
      raw_field_input,
      raw_text_input,
      default_pen_font,
      default_pen_color,
      paper_color,
      held_item_details,
    } = data;

    const readOnly = !canEdit(held_item_details);

    // Сохраняем поля в DOM между обновлениями, пока содержимое бумаги не изменилось.
    if (
      this.lastReadOnly === readOnly
      && this.lastDMInput === raw_text_input
      && this.lastFieldInput === raw_field_input
    ) {
      return { fragment: this.parsedDMCache, nextCounter: this.lastFieldCount };
    }

    this.lastReadOnly = readOnly;
    const output = document.createDocumentFragment();
    let fieldCount = 0;

    raw_text_input?.forEach((value) => {
      let rawText = value.raw_text.trim();
      if (!rawText.length) {
        return;
      }

      const fontColor = value.color || default_pen_color;
      const fontFace = value.font || default_pen_font;
      const fontBold = value.bold || false;
      const advancedHtml = value.advanced_html || false;

      let processingOutput = this.formatAndProcessRawText(
        rawText,
        fontFace,
        fontColor,
        paper_color,
        fontBold,
        fieldCount,
        readOnly,
        advancedHtml
      );

      output.appendChild(processingOutput.fragment);

      fieldCount = processingOutput.nextCounter;
    });

    this.lastDMInput = raw_text_input;
    this.lastFieldInput = raw_field_input;
    this.lastFieldCount = fieldCount;
    this.parsedDMCache = output;

    return { fragment: output, nextCounter: fieldCount };
  };

  // Creates the partial inline HTML for previewing or reading the paper from
  // the text input area.
  createPreviewFromTextArea = (fieldCount: number): DocumentFragment => {
    const { data } = useBackend<PaperContext>();
    const {
      default_pen_font,
      default_pen_color,
      paper_color,
      held_item_details,
      can_use_advanced_html,
    } = data;
    const { textArea } = this.props;

    if (
      this.parsedTextBoxCache
      && this.lastTextArea === textArea
      && this.lastPreviewFieldCount === fieldCount
      && this.lastAdvancedHtml === can_use_advanced_html
    ) {
      return this.parsedTextBoxCache;
    }

    const readOnly = true;

    const fontColor = held_item_details?.color || default_pen_color;
    const fontFace = held_item_details?.font || default_pen_font;
    const fontBold = held_item_details?.use_bold || false;

    let processingOutput = this.formatAndProcessRawText(
      textArea,
      fontFace,
      fontColor,
      paper_color,
      fontBold,
      fieldCount,
      readOnly,
      can_use_advanced_html
    );

    this.lastTextArea = textArea;
    this.lastPreviewFieldCount = fieldCount;
    this.lastAdvancedHtml = can_use_advanced_html;
    this.parsedTextBoxCache = processingOutput.fragment;
    return processingOutput.fragment;
  };

  // Fully formats, sanitises and parses the provided raw text and wraps it
  // as necessary.
  formatAndProcessRawText = (
    rawText: string,
    font: string,
    color: string,
    paperColor: string,
    bold: boolean,
    fieldCounter: number = 0,
    forceReadonlyFields: boolean = false,
    advanced_html: boolean = false
  ): FieldCreationReturn => {
    const fragment = sanitizePaperMarkup(
      paperMarkdown.parse(rawText + '\n\n', { async: false }),
      advanced_html
    );
    const nextCounter = this.createFields(
      fragment,
      font,
      12,
      color,
      paperColor,
      forceReadonlyFields,
      fieldCounter
    );

    const writing = document.createElement('span');
    writing.style.fontFamily = font;
    writing.style.color = color;
    if (bold) {
      writing.style.fontWeight = 'bold';
    }
    writing.appendChild(fragment);
    fragment.appendChild(writing);
    return { fragment, nextCounter };
  };

  // Builds a paper field ID from a number or string.
  createIDHeader = (index: number | string): string => {
    return 'paperfield_' + index;
  };

  // Returns the width the text with
  // the provided attributes would take up in px.
  textWidth = (text: string, font: string, fontsize: number): number => {
    const c = document.createElement('canvas');
    const ctx = c.getContext('2d');

    if (!ctx) {
      return -1;
    }

    ctx.font = `${fontsize}px ${font}`;
    return ctx.measureText(text).width;
  };

  // Заменяем метки полей только в текстовых узлах, сохраняя атрибуты разметки.
  createFields = (
    fragment: DocumentFragment,
    font: string,
    fontSize: number,
    color: string,
    paperColor: string,
    forceReadonlyFields: boolean,
    counter: number = 0
  ): number => {
    const { data } = useBackend<PaperContext>();
    const { raw_field_input } = data;

    const walker = document.createTreeWalker(fragment, NodeFilter.SHOW_TEXT);
    const textNodes: Text[] = [];
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      textNodes.push(node as Text);
    }
    for (const node of textNodes) {
      const text = node.data;
      if (!text.includes('[_')) {
        continue;
      }
      const fields = document.createDocumentFragment();
      let end = 0;
      for (const { 0: match, 1: blank, index } of text.matchAll(fieldRegex)) {
        const width = this.textWidth(match, font, fontSize);
        const matchingData = raw_field_input?.find(
          (e) => e.field_index === `${counter}`
        );
        const id = this.createIDHeader(counter++);
        const input = matchingData
          ? this.createFilledInputField(
            matchingData,
            blank.length,
            width,
            font,
            fontSize,
            color,
            paperColor,
            id
          )
          : this.createInputField(
            blank.length,
            width,
            font,
            fontSize,
            color,
            id,
            forceReadonlyFields
          );
        fields.append(text.slice(end, index) + '[', input, ']');
        end = index! + match.length;
      }
      if (end) {
        fields.append(text.slice(end));
        node.replaceWith(fields);
      }
    }
    return counter;
  };

  // Builds an <input> field from the supplied props.
  createInputField = (
    length: number,
    width: number,
    font: string,
    fontSize: number,
    color: string,
    id: string,
    readOnly: boolean
  ): HTMLInputElement => {
    // This are fields that may potentially be fillable, so we'll use the
    // currently held item's stats for them if possible.
    const { data } = useBackend<PaperContext>();
    const { held_item_details, max_input_field_length } = data;

    const fontColor = held_item_details?.color || color;
    const fontFace = held_item_details?.font || font;

    const input = document.createElement('input');
    input.id = id;
    input.setAttribute('type', 'text');
    input.style.fontSize = `${fontSize}px`;
    input.style.fontFamily = fontFace;
    input.style.color = fontColor;
    input.style.minWidth = `${width}px`;
    input.style.maxWidth = `${width}px`;

    input.maxLength = Math.min(max_input_field_length, length);
    input.size = length;
    input.disabled = readOnly;

    // Restore unsaved text typed into this field earlier: rebuilds of the
    // preview HTML (mode flips, new DM data) recreate the DOM from scratch,
    // but the typed values live on in the store until saved.
    const [inputFieldData] = useLocalState('inputFieldData', {});
    const storedValue = inputFieldData[this.getHeaderID(id)];
    if (storedValue) {
      input.defaultValue = storedValue;
    }

    return input;
  };

  // Builds an <input> field from the supplied props, pre-filled with a value
  // and disabled.
  // We never need to track these because they are always disabled, so we're
  // just using it as a convenient way to build the HTML output.
  createFilledInputField = (
    field: FieldInput,
    length: number,
    width: number,
    font: string,
    fontSize: number,
    color: string,
    paperColor: string,
    id: string
  ): HTMLInputElement => {
    const { data } = useBackend<PaperContext>();
    const { max_input_field_length } = data;

    const fieldData = field.field_data;

    let input = document.createElement('input');
    input.setAttribute('type', 'text');

    input.style.fontSize = field.is_signature ? '18px' : `${fontSize}px`;
    input.style.fontFamily = fieldData.font || font;
    input.style.fontStyle = field.is_signature ? 'italic' : 'normal';
    input.style.fontWeight = 'bold';
    input.style.color = fieldData.color || color;
    input.style.minWidth = `${width}px`;
    input.style.maxWidth = `${width}px`;
    input.style.backgroundColor = paperColor;
    input.id = id;
    input.maxLength = Math.min(max_input_field_length, length);
    input.size = length;
    input.defaultValue = fieldData.raw_text;
    input.disabled = true;

    return input;
  };

  render() {
    const { data } = useBackend<PaperContext>();
    const { paper_color, held_item_details } = data;
    const interactMode
      = held_item_details?.interaction_mode || InteractionType.reading;

    const dmTextPreviewData = this.createPreviewFromDM();

    const textAreaPreview = interactMode === InteractionType.writing
      ? this.createPreviewFromTextArea(dmTextPreviewData.nextCounter)
      : null;

    const { scrollableRef, handleOnScroll } = this.props;

    // Предпросмотр не пересоздаёт редактируемые поля основного текста.
    return (
      <Section
        fill
        fitted
        scrollable
        scrollableRef={scrollableRef}
        onScroll={handleOnScroll}>
        <Box
          fillPositionedParent
          position="relative"
          bottom={'100%'}
          minHeight="100%"
          backgroundColor={paper_color}
          className="Paper__Page"
          p="10px">
          <PaperMarkup className="paper-text" fragment={dmTextPreviewData.fragment} />
          {textAreaPreview !== null && (
            <PaperMarkup className="paper-text" fragment={textAreaPreview} />
          )}
        </Box>
        <StampView />
      </Section>
    );
  }
}

// Renders all the stamp components for every valid stamp.
export const StampView = (props) => {
  const { data } = useBackend<PaperContext>();

  const { raw_stamp_input = [] } = data;

  const { stampYOffset } = props;

  return (
    <>
      {raw_stamp_input.map((stamp, index) => {
        return (
          <Stamp
            key={index}
            x={stamp.x}
            y={stamp.y}
            rotation={stamp.rotation}
            sprite={stamp.class}
            yOffset={stampYOffset}
          />
        );
      })}
    </>
  );
};

export const PaperSheet = (props) => {
  const { data } = useBackend<PaperContext>();
  const { paper_color, paper_name, held_item_details } = data;

  const writeMode = canEdit(held_item_details);

  return (
    <Window
      title={paper_name}
      theme="paper"
      width={600}
      height={775 + (writeMode ? TEXTAREA_INPUT_HEIGHT : 0)}>
      <Window.Content backgroundColor={paper_color}>
        <PrimaryView />
      </Window.Content>
    </Window>
  );
};
