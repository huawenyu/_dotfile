#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
# Clone from https://raw.githubusercontent.com/tldr-pages/tldr-python-client/main/tldr.py
"""
 New:
 - support multiple dirs like: (put *.md into dotfiles/tldr/linux if-os-is-linux)
   export TLDR_PAGES_SOURCE_LOCATION="https://raw.githubusercontent.com/tldr-pages/tldr/master/pages; file://$HOME/dotfiles/tldr"
"""

import sys
import os
import re
import glob
from argparse import ArgumentParser
from zipfile import ZipFile
from datetime import datetime
from io import BytesIO
import ssl
from typing import List, Optional, Tuple, Union
from urllib.parse import quote
from urllib.request import urlopen, Request
from urllib.error import HTTPError, URLError
from termcolor import colored
import colorama  # Required for Windows
import shtab
import inspect

__version__ = "3.1.0"
__client_specification__ = "1.5"

#EN_DEBUG = True
EN_DEBUG = False

REQUEST_HEADERS = {'User-Agent': 'tldr-python-client'}
PAGES_SOURCE_LOCATION = os.environ.get(
    'TLDR_PAGES_SOURCE_LOCATION',
    'https://raw.githubusercontent.com/tldr-pages/tldr/master/pages'
).rstrip('/')
DOWNLOAD_CACHE_LOCATION = os.environ.get(
    'TLDR_DOWNLOAD_CACHE_LOCATION',
    'https://tldr-pages.github.io/assets/tldr.zip'
)

USE_NETWORK = int(os.environ.get('TLDR_NETWORK_ENABLED', '1')) > 0
USE_CACHE = int(os.environ.get('TLDR_CACHE_ENABLED', '1')) > 0
MAX_CACHE_AGE = int(os.environ.get('TLDR_CACHE_MAX_AGE', 24*7))

URLOPEN_CONTEXT = None
if int(os.environ.get('TLDR_ALLOW_INSECURE', '0')) == 1:
    URLOPEN_CONTEXT = ssl.create_default_context()
    URLOPEN_CONTEXT.check_hostname = False
    URLOPEN_CONTEXT.verify_mode = ssl.CERT_NONE

OS_DIRECTORIES = {
    "linux": "linux",
    "darwin": "osx",
    "sunos": "sunos",
    "win32": "windows"
}

src_dirs = []
options = None
home_dir = os.path.expanduser('~')

class CacheNotExist(Exception):
    pass

class EntryNotExist(Exception):
    pass

class EntryDone(Exception):
    pass


class TextState:
   Null      = 'Null'
   NewEntry  = 'Entry'
   Name      = 'Name'
   Desc      = 'Desc'
   Example   = 'Example'
   Command   = 'Command'
   Parameter = 'Parameter'
   Block     = 'Block'
   Fence     = 'Fence'
   List      = 'List'
   Header    = 'Header'
   Text      = 'Text'


def get_language_code(language: str) -> str:
    language = language.split('.')[0]
    if language in ['pt_PT', 'pt_BR', 'zh_TW']:
        return language
    elif language == "pt":
        return "pt_PT"
    return language.split('_')[0]


def get_default_language() -> str:
    default_lang = get_language_code(
        os.environ.get(
            'LANG',
            'C'
        )
    )

    if default_lang == 'C' or default_lang == 'POSIX':
        default_lang = None

    return default_lang


def get_cache_dir() -> str:
    if os.environ.get('XDG_CACHE_HOME', False):
        return os.path.join(os.environ.get('XDG_CACHE_HOME'), 'tldr')
    if os.environ.get('HOME', False):
        return os.path.join(os.environ.get('HOME'), '.cache', 'tldr')
    return os.path.join(os.path.expanduser("~"), ".cache", "tldr")


def get_cache_file_path(command: str, platform: str, language: str) -> str:
    pages_dir = "pages"
    if language and language != 'en':
        pages_dir += "." + language
    return os.path.join(get_cache_dir(), pages_dir, platform, command) + ".md"


def load_page_from_cache(command: str, platform: str, language: str) -> Optional[str]:
    try:
        with open(get_cache_file_path(
            command,
            platform,
            language), 'rb'
        ) as cache_file:
            cache_file_contents = cache_file.read()
        return cache_file_contents
    except Exception:
        pass


def store_page_to_cache(
    page: str,
    command: str,
    platform: str,
    language: str
) -> Optional[str]:
    try:
        cache_file_path = get_cache_file_path(command, platform, language)
        os.makedirs(os.path.dirname(cache_file_path), exist_ok=True)
        with open(cache_file_path, "wb") as cache_file:
            cache_file.write(page)
    except Exception:
        pass


def have_recent_cache(command: str, platform: str, language: str) -> bool:
    try:
        cache_file_path = get_cache_file_path(command, platform, language)
        last_modified = datetime.fromtimestamp(os.path.getmtime(cache_file_path))
        hours_passed = (datetime.now() - last_modified).total_seconds() / 3600
        return hours_passed <= MAX_CACHE_AGE
    except Exception:
        return False


def get_page_url(command: str, platform: str, remote: str, language: str) -> str:
    if remote is None:
        remote = PAGES_SOURCE_LOCATION

    if language is None or language == 'en':
        language = ''
    else:
        language = '.' + language

    if command.endswith('-'):
        return remote + language + "/" + platform + "/" + quote(command) + ".md", \
                remote + language + "/" + platform + "/" + quote(command) + "*.md"
    else:
        return remote + language + "/" + platform + "/" + quote(command) + ".md", \
                remote + language + "/" + platform + "/" + quote(command) + "-*.md"


def get_page_for_platform(
    command: str,
    platform: str,
    remote: str,
    language: str,
) -> None:
    global options

    data = None
    data_downloaded = False
    page_url,page_wildcard = get_page_url(command, platform, remote, language)

    # Ignore cache for local file
    if USE_CACHE and not remote.startswith('file://') and have_recent_cache(command, platform, language) :
        data = load_page_from_cache(command, platform, language)
        if EN_DEBUG:
            print("  wilson %s() get cache succ: %s,%s,%s" % (inspect.stack()[0][3], command, platform, remote))
    else:
        #print("  wilson urlopen {}-{}: {}".format(platform, language, remote))
        try:
            data = urlopen(
                Request(page_url, headers=REQUEST_HEADERS),
                context=URLOPEN_CONTEXT
            ).read()

            if EN_DEBUG:
                print("  wilson %s() get succ %s" % (inspect.stack()[0][3], page_url))
            data_downloaded = True

            # Require show the file fullpath for editor
            if options.editor and remote.startswith('file://'):
                # only remember the 1st local os-related file path
                if options.page_url_exist == '':
                    options.page_url_exist = page_url
                    raise EntryDone("Entry for {} in {} done: {}".format(command, platform, page_url))

        except Exception:
            if EN_DEBUG:
                print("  wilson get fail %s" % (page_url))

            # local file no cache needed
            if remote.startswith('file://'):
                # only remember the 1st local os-related file path
                if options.page_url_empty == '':
                    options.page_url_empty = page_url

                if EN_DEBUG:
                    print("  wilson wild %s" % (page_wildcard[len('file://'):]))
                if len(glob.glob(page_wildcard[len('file://'):])) > 0:
                    options.page_url_empty = page_wildcard

                # try next remote location
                raise
            elif USE_CACHE:
                data = load_page_from_cache(command, platform, language)
                if data is None:
                    raise
            else:
                raise

    if data_downloaded and USE_CACHE and not page_url.startswith('file://'):
        store_page_to_cache(data, command, platform, language)

    if data is None:
        raise EntryNotExist("Entry for {} in {} can't find: {}".format(command, platform, page_url))

    lines = data.splitlines()

    # Insert source URL split-line
    show_url = page_url
    if page_url.startswith('file://'):
        show_url = page_url[len('file://'):]
        if show_url.startswith(home_dir):
            options.data.append("--- ~{}".format(show_url[len(home_dir):]))
        else:
            options.data.append("--- {}".format(show_url))
        show_url = ''
    if show_url != '':
        options.data.append("--- {}".format(show_url))

    options.data.extend(lines)
    return


def update_page_for_platform(
    command: str,
    platform: str,
    remote: str,
    language: str
) -> None:
    if remote.startswith('file://'):
        return

    page_url,page_wildcard = get_page_url(platform, command, remote, language)
    data = urlopen(
        Request(page_url, headers=REQUEST_HEADERS),
        context=URLOPEN_CONTEXT
    ).read()
    store_page_to_cache(data, command, platform, language)


def get_platform() -> str:
    for key in OS_DIRECTORIES:
        if sys.platform.startswith(key):
            return OS_DIRECTORIES[key]
    return 'linux'


def get_platform_list() -> List[str]:
    platforms = ['common'] + list(OS_DIRECTORIES.values())
    current_platform = get_platform()
    platforms.remove(current_platform)
    platforms.insert(0, current_platform)

    if EN_DEBUG:
        print("  wilson {}(): platforms={}".format(inspect.stack()[0][3], platforms))

    return platforms


def get_language_list() -> List[str]:
    tldr_language = get_language_code(os.environ.get('TLDR_LANGUAGE', ''))
    languages = os.environ.get('LANGUAGE', '').split(':')
    languages = list(map(
        get_language_code,
        filter(lambda x: not (x == 'C' or x == 'POSIX' or x == ''), languages)
    ))

    default_lang = get_default_language()

    if default_lang is None:
        languages = []
    elif default_lang not in languages:
        languages.append(default_lang)
    if tldr_language:
        # remove tldr_language if it already exists to avoid double entry
        try:
            languages.remove(tldr_language)
        except ValueError:
            pass
        languages.insert(0, tldr_language)
    if 'en' not in languages:
        languages.append('en')
    return languages


def get_page(
    command: str,
    remotes: List[str],
    platforms: Optional[List[str]] = None,
    languages: Optional[List[str]] = None
) -> Union[str, bool]:
    global options

    options.data = []
    options.page_url_empty = ''
    options.page_url_exist = ''

    if EN_DEBUG:
        print("  wilson {}(): platforms={}".format(inspect.stack()[0][3], platforms))

    if platforms is None:
        platforms = get_platform_list()
    if languages is None:
        languages = get_language_list()

    for platform in platforms:
        for language in languages:
            if platform is None:
                continue
            for remote in remotes:
                if options.include and options.include not in remote:
                    continue

                try:
                    get_page_for_platform(command, platform, remote, language)
                except EntryDone:
                    if options.editor and options.page_url_exist:
                        return options.page_url_exist
                except CacheNotExist:
                    continue
                except EntryNotExist:
                    continue
                except HTTPError as err:
                    if err.code != 404:
                        raise
                except URLError:
                    if not remote.startswith('file://'):
                        raise

    if EN_DEBUG:
        print("  wilson final data.len={}".format(len(options.data)))
    if len(options.data) > 1:
        return options.data
    if options.page_url_empty:
        return options.page_url_empty
    return False


# Option: one-color + one-background + mult-attrs
DEFAULT_COLORS = {
    'name':        'reverse bold',
    'description': '',
    'text':        '',
    'example':     'magenta bold',
    'header':      'magenta bold',
    'command':     'red',
    'parameter':   '',
    'blockdesc':   'cyan bold',
    'block':       'yellow',
    'fence':       'yellow',
    'list':        'blue',
    'list2':       'green',
    'comment':     'grey',
    'page':        'underline',
}

# See more details in the README:
# https://github.com/tldr-pages/tldr-python-client#colors
ACCEPTED_COLORS = [
    'blue', 'green', 'yellow', 'cyan', 'magenta', 'white', 'grey', 'red'
]

ACCEPTED_COLOR_BACKGROUNDS = [
    'on_blue', 'on_cyan', 'on_magenta', 'on_white',
    'on_grey', 'on_yellow', 'on_red', 'on_green'
]

ACCEPTED_COLOR_ATTRS = [
    'reverse', 'blink', 'dark', 'concealed', 'underline', 'bold'
]

LEADING_SPACES_NUM = 2

COMMAND_SPLIT_REGEX = re.compile(r'(?P<param>{{.+?}*}})')
PARAM_REGEX = re.compile(r'(?:{{)(?P<param>.+?)(?:}})')


def get_commands(platforms: Optional[List[str]] = None) -> List[str]:
    global options

    if platforms is None:
        platforms = get_platform_list()

    commands = []
    local_dirs = options.src_local
    local_dirs.append(get_cache_dir())
    for one_dir in local_dirs:
        if os.path.exists(one_dir):
            for platform in platforms:
                # Include the dir-style: ~/dotfiles/tldr/pages/linux/test1.md
                path = os.path.join(one_dir, 'pages', platform)
                if os.path.exists(path):
                    commands += [file[:-3] for file in os.listdir(path) if file.endswith(".md")]

                # Also include the dir-style: ~/dotfiles/tldr/linux/test1.md
                path = os.path.join(one_dir, platform)
                if os.path.exists(path):
                    commands += [file[:-3] for file in os.listdir(path) if file.endswith(".md")]
    return commands


def colors_of(key: str) -> Tuple[str, str, List[str]]:
    env_key = 'TLDR_COLOR_%s' % key.upper()
    values = os.environ.get(env_key, DEFAULT_COLORS[key]).strip().split()
    color = None
    on_color = None
    attrs = []
    for value in values:
        if value in ACCEPTED_COLORS:
            color = value
        elif value in ACCEPTED_COLOR_BACKGROUNDS:
            on_color = value
        elif value in ACCEPTED_COLOR_ATTRS:
            attrs.append(value)
    return (color, on_color, attrs)


def output(page: str, plain: bool = False) -> None:
    global options

    #if not plain:
    #    print()

    # the local full path, used for editor
    if isinstance(page, str) and page.startswith('file://'):
        is_temp_file = False
        fname = page[len('file://'):]
        if not os.path.exists(fname) and not '*' in fname:
            is_temp_file = True
            if EN_DEBUG:
                print("  wilson create template {}".format(fname))

            cmdName = os.path.basename(fname)
            cmdName = os.path.splitext(cmdName)[0]
            with open(fname, 'w') as f:
                f.write(""                                                          \
                    "# {command}: will-delete-if-no-change\n"                       \
                    "\n"                                                            \
                    "> Description.\n"                                              \
                    "> [More information](https://url-to-upstream.tld).\n"          \
                    "\n"                                                            \
                    "# Example description:\n"                                      \
                    "\n"                                                            \
                    "	# The `$_` is a special parameter that holds the last argument of the previous command.\n" \
                    "	command --option1 --option2 {{arg_value}}\n"                \
                    "\n"                                                            \
                    "# Features:\n"                                                 \
                    "! [This is hidden comment](https://github.com/huawenyu/dotfiles/script/tldr)\n" \
                    "- The feature list:\n"                                         \
                    "  - support multiple page sources\n"                           \
                    "  - support edit(vi) mode by option `-e`\n"                    \
                    "  - support mutiple syntax: block, fence, list, comment\n"     \
                    "\n".format(command = cmdName)                                  \
                    )

        os.system("{editor} -p {fname}".format(editor = "vi", fname=fname))
        if is_temp_file:
            theFirstLine = os.popen("head -n 1 {fname}".format(fname=fname)).read()
            if "will-delete-if-no-change" in theFirstLine:
                if EN_DEBUG:
                    print("  wilson delete the template {}".format(fname))
                os.remove(fname)
        return

    state = TextState.Null
    listIndent = 0
    listModeIdx = 0
    listModes = ['list', 'list2']
    hadNewline = False
    is_local = True
    if EN_DEBUG:
        print("  wilson new-page")
    for line in page:
        newLine = '' if hadNewline else '\n'
        m1 = None
        if EN_DEBUG and not hadNewline:
            print("  wilson {}(state={} newLine={})".format(inspect.stack()[0][3], state, newLine == '\n'))

        if not isinstance(line, str):
            line = line.rstrip().decode('utf-8')

        if line.startswith('```'):
            if state == TextState.Fence:
                print()
                state = TextState.Null
                continue
            state = TextState.Fence
            continue
        elif state == TextState.Fence:
            if re.match(r'[ \t]{1,}##', line):
                line = colored(line, *colors_of('comment')) + '\n'
                hadNewline = True
            else:
                line = colored(line, *colors_of('fence')) + '\n'
                hadNewline = True
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
            continue

        if plain:
            print(line)
            continue
        elif len(line) == 0:
            if not hadNewline:
                hadNewline = True
                if EN_DEBUG:
                    print("  wilson {} add-Newline by emptyline(state={} newLine={})".format(inspect.stack()[0][3], state, newLine == ''))
                else:
                    print()
            continue
        elif line[0] == '!':
            # comment
            continue

        # So don't let the skipped emptyline reset it
        hadNewline = False

        if line.startswith('--- '):
            state = TextState.NewEntry

            is_local = True
            if line[4:].startswith('http'):
                is_local = False
            if EN_DEBUG:
                print("  wilson is_local={}: {}".format(is_local, line[4:]))

            hadNewline = True
            line = newLine + ' ' * LEADING_SPACES_NUM * 6 + \
                    colored(line[4:], *colors_of('page')) + '\n'

            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
        elif line[0] == '#':
            if state == TextState.NewEntry:
                state = TextState.Name
                line = colored(line[1:], *colors_of('name')) + '\n'
                hadNewline = True
            else:
                state = TextState.Header
                line = newLine + colored(line.replace('#', '∙'), *colors_of('header')) + '\n'
                hadNewline = True
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
        elif line[0] == '>':
            state = TextState.Desc
            line = ' ' * (LEADING_SPACES_NUM - 1) + \
                colored(
                    line.replace('>', '').replace('<', ''),
                    *colors_of('description')
            )
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
        elif line[0] == '-':
            state = TextState.Example
            line = newLine + colored(line[1:].strip(), *colors_of('example'))
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
        elif line[0] == '`':
            state = TextState.Parameter
            line = line[1:-1]  # need to actually parse ``
            elements = [' ' * 2 * LEADING_SPACES_NUM]
            for item in COMMAND_SPLIT_REGEX.split(line):
                item, replaced = PARAM_REGEX.subn(
                    lambda x: colored(
                        x.group('param'), *colors_of('parameter')),
                    item)
                if not replaced:
                    item = colored(item, *colors_of('command'))
                elements.append(item)
            sys.stdout.buffer.write(''.join(elements).encode('utf-8'))
        elif (line[0] == '\t'
              or re.match(r'([ ]{4,})[^-*+]', line)
              or (state == TextState.Block
                   and re.match(r'([ ]{4,})[-*+]', line))
              ):
            if state == TextState.Block:
                if re.match(r'[ \t]{1,}##', line):
                    line = ' ' * LEADING_SPACES_NUM * 2 + \
                            colored(line[1:], *colors_of('blockdesc'))
                else:
                    line = ' ' * LEADING_SPACES_NUM * 2 + \
                            colored(line[1:], *colors_of('block'))
            else:
                if re.match(r'[ \t]{1,}##', line):
                    line = newLine + ' ' * LEADING_SPACES_NUM * 2 + \
                            colored(line[1:], *colors_of('blockdesc'))
                else:
                    line = newLine + ' ' * LEADING_SPACES_NUM * 2 + \
                            colored(line[1:], *colors_of('block'))
            state = TextState.Block
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
        elif (line[0] == '*'
              or (m1 := re.match(r'([ ]{2,})[-*+]', line))
              ):

            newIndent = listIndent
            if line[0] == '*':
                newIndent = 0
            elif m1:
                newIndent = len(m1.group(1))

            if listIndent != newIndent:
                listModeIdx += 1
                listIndent = newIndent

            if state == TextState.List:
                line = ' ' * LEADING_SPACES_NUM + \
                        colored(line, *colors_of(listModes[listModeIdx % len(listModes)]))
            else:
                line = newLine + ' ' * LEADING_SPACES_NUM + \
                        colored(line, *colors_of(listModes[listModeIdx % len(listModes)]))
            state = TextState.List
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
        else:
            state = TextState.Text
            line = ' ' * LEADING_SPACES_NUM + \
                    colored(line, *colors_of('text'))
            sys.stdout.buffer.write((state + line if options.verbose else line).encode('utf-8'))
            continue

        if is_local:
            if EN_DEBUG:
                print("  wilson add-newline by inner")
            else:
                print()

    if EN_DEBUG:
        print("  wilson add-newline by outter")
    else:
        print()


def update_cache(language: Optional[List[str]] = None) -> None:
    if language is None:
        tldr_language = os.environ.get("TLDR_LANGUAGE", get_default_language())
        language = tldr_language if tldr_language else 'en'
    elif isinstance(language, list):
        language = language[0]
    try:
        pages_dir = "pages"
        if language and language != 'en':
            pages_dir += "." + language
        req = urlopen(Request(
            DOWNLOAD_CACHE_LOCATION,
            headers=REQUEST_HEADERS
        ), context=URLOPEN_CONTEXT)
        zipfile = ZipFile(BytesIO(req.read()))
        pattern = re.compile(r"{}/(.+)/(.+)\.md".format(pages_dir))
        cached = 0
        for entry in zipfile.namelist():
            match = pattern.match(entry)
            if match:
                store_page_to_cache(
                    zipfile.read(entry),
                    match.group(2),
                    match.group(1),
                    language
                )
                cached += 1
        print("Updated cache for {:d} entries".format(cached))
    except Exception:
        sys.exit("Error: Unable to update cache from " + DOWNLOAD_CACHE_LOCATION)


def create_parser() -> ArgumentParser:
    parser = ArgumentParser(
        prog="tldr",
        usage="tldr command [options]",
        description="Python command line client for tldr"
    )
    parser.add_argument(
        '-v', '--version',
        action='version',
        version='%(prog)s {} (Client Specification {})'.format(
            __version__,
            __client_specification__
        )
    )

    parser.add_argument("--search",
                        metavar='"KEYWORDS"',
                        type=str,
                        help="Search for a specific command from a query")

    parser.add_argument('-u', '--update_cache',
                        action='store_true',
                        help="Update the local cache of pages and exit")

    parser.add_argument(
        '-p', '--platform',
        nargs='+',
        default=None,
        type=str,
        choices=['common', 'linux', 'osx', 'sunos', 'windows'],
        metavar='PLATFORM',
        help="Override the operating system [common, linux, osx, sunos, windows]"
    )

    parser.add_argument('-V', '--verbose',
                        default=False,
                        action='store_true',
                        help="Show all text state name")

    parser.add_argument('-l', '--list',
                        default=False,
                        action='store_true',
                        help="List all available commands for operating system")

    parser.add_argument('-a', '--urls',
                        default=False,
                        action='store_true',
                        help="List all available page source")

    parser.add_argument('-s', '--source',
                        default=PAGES_SOURCE_LOCATION,
                        type=str,
                        help="Override the default page source")

    parser.add_argument('-i', '--include',
                        default='',
                        type=str,
                        help="Only include page source contain <text>")

    parser.add_argument('-e', '--editor',
                        default=False,
                        action='store_true',
                        help="Edit the local entry")

    parser.add_argument('-c', '--color',
                        default=None,
                        action='store_const',
                        const=False,
                        help="Override color stripping")

    parser.add_argument('-r', '--render',
                        default=False,
                        action='store_true',
                        help='Render local markdown files'
                        )

    parser.add_argument('-L', '--language',
                        nargs=1,
                        default=None,
                        type=str,
                        help='Override the default language')

    parser.add_argument('-m', '--markdown',
                        default=False,
                        action='store_true',
                        help='Just print the plain page file.')

    parser.add_argument(
        'command', type=str, nargs='*', help="command to lookup", metavar='command'
    ).complete = {"bash": "shtab_tldr_cmd_list", "zsh": "shtab_tldr_cmd_list"}

    shtab.add_argument_to(parser, preamble={
        'bash': r'''shtab_tldr_cmd_list(){{
          compgen -W "$("{py}" -m tldr --list | sed 's/\W/ /g')" -- "$1"
        }}'''.format(py=sys.executable),
        'zsh': r'''shtab_tldr_cmd_list(){{
          _describe 'command' "($("{py}" -m tldr --list | sed 's/\W/ /g'))"
        }}'''.format(py=sys.executable)
    })

    return parser


def main() -> None:
    global src_dirs
    global options

    parser = create_parser()

    options = parser.parse_args()

    colorama.init(strip=options.color)

    src_dirs = options.source
    if src_dirs.find('; '):
        src_dirs = src_dirs.split("; ")
    elif src_dirs.find(', '):
        src_dirs = src_dirs.split(", ")
    elif src_dirs.find(';'):
        src_dirs = src_dirs.split(";")
    elif src_dirs.find(','):
        src_dirs = src_dirs.split(",")
    else:
        src_dirs = src_dirs.split(" ")
    # change from str to List[str]
    options.source = []
    options.src_local = []
    src_file_idx = 0
    options.has_local = False
    options.has_remote = False

    # Last show local
    for src_location in src_dirs:
        if src_location.startswith('file://'):
            the_dir = src_location[len('file://'):]
            if os.path.exists(the_dir):
                options.has_local = True
                options.src_local.append(the_dir)
                options.source.append(src_location)
        elif not options.editor:
            options.has_remote = True
            options.source.insert(src_file_idx, src_location)
            src_file_idx += 1

    if options.urls:
        options.source.insert(0, "Pages list:")
        print("\n  ".join(options.source))
        return
    if options.update_cache:
        update_cache(language=options.language)
        return
    elif len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    options.platform.remove('common')
    options.platform.insert(0, 'common')
    if EN_DEBUG:
        print("  wilson {}(): platforms={}".format(inspect.stack()[0][3], options.platform))

    if options.list:
        print(*get_commands(options.platform), sep='\n')
    elif options.render:
        for command in options.command:
            if os.path.exists(command):
                with open(command, encoding='utf-8') as open_file:
                    output(open_file.read().encode('utf-8').splitlines(),
                           plain=options.markdown)
    elif options.search:
        command = '-'.join(options.command)
        page = None
        maxprob = 0
        searchquery = options.search.split(' ')

        platforms = get_platform_list()
        for i in get_commands(platforms):
            if i.startswith(command):
                for p in platforms:
                    result = load_page_from_cache(i, p, options.language)
                    if result is not None and have_recent_cache(i, p, options.language):
                        break
                if result is None:
                    raise SystemExit("Please update cache")
                result = result.decode("utf-8")
                result = result.split()
                for word in searchquery:
                    prob = 0
                    for line in result:
                        line = line.lower()
                        if word in line:
                            prob += 1
                            if line.startswith("#"):
                                prob += 7
                            elif line.startswith(">"):
                                prob += 5
                            elif line.startswith("-"):
                                prob += 2
                    if prob > maxprob:
                        maxprob = prob
                        page = i

        if page:
            result = get_page(page, options.source, options.platform, options.language)
            output(result, plain=options.markdown)
        else:
            print("No results found")

    else:
        try:
            command = '-'.join(options.command).lower()
            result = get_page(
                command,
                options.source,
                options.platform,
                options.language
            )
            if not result:
                sys.exit((
                    "`{cmd}` documentation is not available.\n"
                    "If you want to contribute it, feel free to"
                    " send a pull request to: https://github.com/tldr-pages/tldr"
                ).format(cmd=command))
            else:
                output(result, plain=options.markdown)
        except URLError as e:
            sys.exit("Error fetching from tldr: {}".format(e))


def cli() -> None:
    try:
        main()
    except KeyboardInterrupt:
        print("\nExited on keyboard interrupt.")


if __name__ == "__main__":
    cli()

# vim: set ft=python
