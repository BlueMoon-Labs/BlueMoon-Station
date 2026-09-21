import os
import tempfile
import unittest

from .allowlist import Allowlist
from .audit import Audit
from .inventory import duplicate_groups
from .references import HOLE, DMLexer, resolve_relative


def lex(text):
    return DMLexer(text).run()


class LexerTest(unittest.TestCase):
    def test_comments_are_skipped(self):
        lexer = lex("// 'icons/a.dmi'\n/* 'icons/b.dmi' /* nested */ 'icons/c.dmi' */\nicon = 'icons/d.dmi'")
        self.assertEqual(lexer.resources, ['icons/d.dmi'])

    def test_apostrophe_in_warn_is_not_a_resource(self):
        lexer = lex("#warn It's fine\nicon = 'icons/a.dmi'")
        self.assertEqual(lexer.resources, ['icons/a.dmi'])

    def test_interpolation_becomes_hole_and_inner_strings_are_collected(self):
        lexer = lex('var/x = "sound/[pick("a", "b")]_[rand(1, 2)].ogg"')
        self.assertIn('sound/' + HOLE + '_' + HOLE + '.ogg', lexer.strings)
        self.assertIn('a', lexer.strings)

    def test_resource_inside_interpolation(self):
        lexer = lex('var/x = "[icon2html(\'icons/a.dmi\', world, "state")]"')
        self.assertEqual(lexer.resources, ['icons/a.dmi'])
        self.assertIn('state', lexer.strings)

    def test_raw_and_multiline_strings(self):
        lexer = lex('var/r = regex(@"[^\'\\s]") \nvar/q = @{"raw "quoted" ["}\nvar/m = {"line "quoted" [x]"}\nicon = \'icons/a.dmi\'')
        self.assertEqual(lexer.resources, ['icons/a.dmi'])
        self.assertIn('raw "quoted" [', lexer.strings)
        self.assertIn('line "quoted" ' + HOLE, lexer.strings)

    def test_escaped_quote(self):
        lexer = lex('var/x = "say \\"hi\\" \'icons/fake.dmi\'"\nicon = \'icons/a.dmi\'')
        self.assertEqual(lexer.resources, ['icons/a.dmi'])

    def test_resolve_prefers_source_directory(self):
        exists = {'code/mod/icons/a.dmi'}.__contains__
        self.assertEqual(resolve_relative('code/mod/x.dm', 'icons/a.dmi', exists), 'code/mod/icons/a.dmi')
        self.assertEqual(resolve_relative('code/mod/x.dm', 'icons/b.dmi', exists), 'icons/b.dmi')


class AuditTest(unittest.TestCase):
    FILES = {
        'tgstation.dme': '#include "code/used.dm"\n',
        'code/dormant.dm': "/obj/e\n\ticon = 'icons/dormant.dmi'\n\tsound = 'sound/never_ported.ogg'\n",
        'icons/dormant.dmi': b'dormant',
        'code/used.dm': (
            "/obj/a\n\ticon = 'icons/used.dmi'\n"
            "/obj/b/proc/f()\n\tplaysound(src, \"sound/voice/[phrase].ogg\")\n"
            "/obj/b/var/phrase = \"halt\"\n"
            "/obj/c/proc/g()\n\tplaysound(src, \"sound/punch[rand(1, 2)].ogg\")\n"
            "/obj/d/proc/h()\n\tfile(\"sound/missing.ogg\")\n"
            "// 'icons/commented.dmi'\n"
        ),
        'map.dmm': '"a" = (/obj{icon = \'icons/mapped.dmi\'})\n',
        'icons/used.dmi': b'used',
        'icons/mapped.dmi': b'mapped',
        'icons/commented.dmi': b'commented',
        'sound/voice/halt.ogg': b'halt',
        'sound/voice/unknown_phrase.ogg': b'unknown',
        'sound/punch1.ogg': b'punch',
        'sound/punch2.ogg': b'punch',
    }

    def setUp(self):
        self.old_cwd = os.getcwd()
        self.tmp = tempfile.TemporaryDirectory()
        os.chdir(self.tmp.name)
        for path, content in self.FILES.items():
            os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
            mode = 'wb' if isinstance(content, bytes) else 'w'
            with open(path, mode) as handle:
                handle.write(content)
        self.audit = Audit().run()

    def tearDown(self):
        os.chdir(self.old_cwd)
        self.tmp.cleanup()

    def test_unused(self):
        self.assertEqual(self.audit.unused, ['icons/commented.dmi', 'sound/voice/unknown_phrase.ogg'])

    def test_broken(self):
        self.assertEqual(self.audit.broken, {'sound/missing.ogg': 'code/used.dm'})

    def test_duplicates(self):
        self.assertEqual(duplicate_groups(self.audit.assets), [['sound/punch1.ogg', 'sound/punch2.ogg']])

    def test_allowlist(self):
        with open('allowlist.txt', 'w', encoding='utf-8') as handle:
            handle.write('unused icons/commented.dmi  # причина\nunused icons/gone.dmi\nduplicate sound/punch*.ogg\n')
        allowlist = Allowlist.load('allowlist.txt')
        self.assertTrue(allowlist.allows('unused', 'icons/commented.dmi'))
        self.assertFalse(allowlist.allows('unused', 'sound/voice/unknown_phrase.ogg'))
        self.assertTrue(allowlist.allows_group(['sound/punch1.ogg', 'sound/punch2.ogg']))
        self.assertEqual([entry.pattern for entry in allowlist.stale()], ['icons/gone.dmi'])


class PixelDuplicateTest(unittest.TestCase):
    def test_same_pixels_different_compression(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as tmp:
            image = Image.new('RGBA', (4, 4), (255, 0, 0, 255))
            first, second = os.path.join(tmp, 'a.png'), os.path.join(tmp, 'b.png')
            image.save(first, compress_level=0)
            image.save(second, compress_level=9)
            self.assertEqual(duplicate_groups([first, second]), [sorted([first, second])])


if __name__ == '__main__':
    unittest.main()
