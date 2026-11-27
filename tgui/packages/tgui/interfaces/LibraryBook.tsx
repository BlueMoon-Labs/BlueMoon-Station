import { useBackend } from '../backend';
import { Box } from '../components';
import { Window } from '../layouts';
import { PaperHtml } from './common/PaperMarkup';

type BookData = {
  title: string;
  author?: string;
  content: string;
};

export const LibraryBook = () => {
  const { data } = useBackend<BookData>();
  const { title, author, content } = data;

  return (
    <Window title={title} width={600} height={560}>
      <Window.Content scrollable>
        <Box p={2} backgroundColor="#dddddd" color="#161616">
          {author && <Box italic mb={1}>Автор: {author}</Box>}
          <PaperHtml text={content} />
        </Box>
      </Window.Content>
    </Window>
  );
};
