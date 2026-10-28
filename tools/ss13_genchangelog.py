'''
Usage:
    $ python ss13_genchangelog.py html/changelogs/

ss13_genchangelog.py - Generate changelog from YAML.

Copyright 2013 Rob "N3X15" Nelson <nexis@7chan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
'''

from __future__ import print_function
import yaml, os, glob, sys, re, time, argparse, subprocess
from datetime import datetime, date, timedelta, timezone
from time import time

today = date.today()

fileDateFormat = "%Y-%m"

opt = argparse.ArgumentParser()
opt.add_argument('ymlDir', help='The directory of YAML changelogs we will use.')

args = opt.parse_args()
archiveDir = os.path.join(args.ymlDir, 'archive')

all_changelog_entries = {}

# Do not change the order, add to the bottom of the array if necessary
validPrefixes = [
    'bugfix',
    'wip',
    'qol',
    'soundadd',
    'sounddel',
    'rscadd',
    'rscdel',
    'imageadd',
    'imagedel',
    'spellcheck',
    'experiment',
    'balance',
    'code_imp',
    'refactor',
    'config',
    'admin',
    'server',
    'sound',
    'image',
    'map',
]

def dictToTuples(inp):
    return [(k, v) for k, v in inp.items()]

old_changelog_cache = os.path.join(args.ymlDir, '.all_changelog.yml')

if os.path.isfile(old_changelog_cache):
    try:
        print('Reading old changelog cache...')
        data = {}
        with open(old_changelog_cache,encoding='utf-8') as f:
            (_, all_changelog_entries) = yaml.load_all(f, Loader=yaml.SafeLoader)

            # Categorize changes by year and month
            for _date in all_changelog_entries.keys():
                ty = type(_date).__name__
                formattedDate = _date.strftime(fileDateFormat)
                if not formattedDate in data:
                    data[formattedDate] = {}
                data[formattedDate][_date] = all_changelog_entries[_date]
            # Write files with changes by year and month
            for month in data.keys():
                print("Writing " + month + ".yml...")
                if not os.path.exists(archiveDir):
                    os.makedirs(archiveDir)
                currentFile = os.path.join(archiveDir, month + '.yml')
                with open(currentFile, 'w', encoding='utf-8') as f:
                    yaml.dump(data[month], f, default_flow_style=False, allow_unicode=True)
        # Remove the old changelog cache, as we won't use it anymore
        print("Removing old changelog cache...")
        os.remove(old_changelog_cache)
        old_changelog_html = os.path.join(args.ymlDir, '..', 'changelog.html')
        if os.path.isfile(old_changelog_html):
            print("Removing old changelog html...")
            os.remove(old_changelog_html)
    except Exception as e:
        print("Failed to read old changelog cache:")
        print(e, file=sys.stderr)

print('Reading changelogs...')
for fileName in glob.glob(os.path.join(args.ymlDir, "*.yml")):
    name, ext = os.path.splitext(os.path.basename(fileName))
    if name.startswith('.'): continue
    if name == 'example': continue
    fileName = os.path.abspath(fileName)
    formattedDate = today.strftime(fileDateFormat)
    monthFile = os.path.join(archiveDir, formattedDate + '.yml')
    print(' Reading {}...'.format(fileName))
    cl = {}
    with open(fileName, 'r',encoding='utf-8') as f:
        cl = yaml.load(f, Loader=yaml.SafeLoader)
    currentEntries = {}
    if os.path.exists(monthFile):
        with open(monthFile,'r',encoding='utf-8') as f:
            currentEntries = yaml.load(f, Loader=yaml.SafeLoader)
    if today not in currentEntries:
        currentEntries[today] = {}
    author_entries = currentEntries[today].get(cl['author'], [])
    # Номер PR из имени AutoChangeLog-pr-N.yml: окно ченджлога ставит по нему ссылку
    pr_match = re.match(r'AutoChangeLog-pr-(\d+)$', name)
    if len(cl['changes']):
        new = 0
        for change in cl['changes']:
            if pr_match:
                change = dict(change, pr=int(pr_match.group(1)))
            if change not in author_entries:
                (change_type, _) = dictToTuples(change)[0]
                if change_type not in validPrefixes:
                    print('  {0}: Invalid prefix {1}'.format(fileName, change_type), file=sys.stderr)
                author_entries += [change]
                new += 1
        currentEntries[today][cl['author']] = author_entries
        if new > 0:
            print('  Added {0} new changelog entries.'.format(new))

    if cl.get('delete-after', False):
        if os.path.isfile(fileName):
            print('  Deleting {0} (delete-after set)...'.format(fileName))
            os.remove(fileName)

    with open(monthFile, 'w', encoding='utf-8') as f:
        yaml.dump(currentEntries, f, default_flow_style=False, allow_unicode=True)


def changelog_sources(since):
    '''AutoChangeLog-pr-N.yml, созданные в git начиная с since: (дата создания, номер PR, автор, изменения).'''
    log = subprocess.run(
        ['git', 'log', '--full-history', '--diff-filter=A', '--since=' + since.isoformat(), '--format=@@%H %ct', '--name-only', '--', 'html/changelogs/AutoChangeLog-pr-*.yml'],
        check=True, capture_output=True).stdout.decode('utf-8')
    sources = []
    sha = created = None
    for line in log.splitlines():
        if line.startswith('@@'):
            sha, stamp = line[2:].split()
            created = datetime.fromtimestamp(int(stamp), timezone.utc).date()
            continue
        match = re.search(r'AutoChangeLog-pr-(\d+)\.yml$', line.strip())
        if not match:
            continue
        shown = subprocess.run(['git', 'cat-file', 'blob', '{0}:{1}'.format(sha, line.strip())], capture_output=True)
        try:
            cl = yaml.load(shown.stdout.decode('utf-8'), Loader=yaml.SafeLoader)
        except yaml.YAMLError:
            continue
        if isinstance(cl, dict) and cl.get('changes'):
            sources.append((created, int(match.group(1)), str(cl.get('author')), cl['changes']))
    return sources


def repair_month(entries, sources):
    '''Дописывает номер PR записям без него и убирает повторную компиляцию того же PR.'''
    changed = False
    seen = set()
    for day in sorted(entries.keys()):
        for author in list(entries[day].keys()):
            kept = []
            for change in entries[day][author]:
                if 'pr' not in change:
                    matches = sorted(
                        (created, pr) for created, pr, cl_author, cl_changes in sources
                        if cl_author == str(author) and change in cl_changes and created <= day)
                    if matches:
                        change = dict(change, pr=matches[-1][1])
                        changed = True
                if 'pr' in change:
                    key = (str(author), tuple(sorted((k, str(v)) for k, v in change.items())))
                    if key in seen:
                        changed = True
                        continue
                    seen.add(key)
                kept.append(change)
            if kept:
                entries[day][author] = kept
            else:
                del entries[day][author]
        if not entries[day]:
            del entries[day]
    return changed


# Записи, скомпилированные без номера PR (старым генератором или до слияния ветки),
# получают его здесь; текущий и прошлый месяц, чтобы пережить смену месяца.
first_of_month = today.replace(day=1)
previous_month = (first_of_month - timedelta(days=1)).replace(day=1)
try:
    sources = changelog_sources(previous_month - timedelta(days=31))
except (OSError, subprocess.CalledProcessError) as e:
    print('Skipping PR number repair: {0}'.format(e), file=sys.stderr)
    sources = None
if sources is not None:
    for month in (previous_month, first_of_month):
        monthFile = os.path.join(archiveDir, month.strftime(fileDateFormat) + '.yml')
        if not os.path.exists(monthFile):
            continue
        with open(monthFile, 'r', encoding='utf-8') as f:
            entries = yaml.load(f, Loader=yaml.SafeLoader) or {}
        if repair_month(entries, sources):
            print('Repaired PR numbers in {0}'.format(monthFile))
            with open(monthFile, 'w', encoding='utf-8') as f:
                yaml.dump(entries, f, default_flow_style=False, allow_unicode=True)
