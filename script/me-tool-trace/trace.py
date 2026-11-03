#!/usr/bin/env python

theUsage = """
Requirement:
    ### https://stackoverflow.com/questions/3160699/python-progress-bar
    pip3 install --user tqdm        ### Used show processbar,
    pip3 install --user neovim      ### Used control neovim

Usage, need two terminal:
    cd <git-top-dir>
    shell-1:
        $ mode=basic NVIM_LISTEN_ADDRESS=/tmp/nvim.trace nvim
    shell-2:
        $ traceme -a add -t trace-all

Clean:
    grep -rl "__TRACEME__" <trace-of-dir> | xargs sed -i 's/{  __TRACEME__;/{/g'
    grep -rl "__TRACEME__" daemon/wad | xargs sed -i 's/{  __TRACEME__;/{/g'
"""

import stat, sys, os, string, subprocess, time
import configparser
import argparse
import re
from collections import Counter
from pprint import pprint

import neovim
from tqdm.auto import tqdm

ign_files = {}
ign_functions = {}
ign_funcregs = {}
config = {}

class NormalReturn(Exception):
   """Base class for other exceptions"""
   pass

class NeovimNone(Exception):
   """Base class for other exceptions"""
   pass

def query_yes_no(question, default="yes"):
    """Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    """
    valid = {"yes": True, "y": True, "ye": True,
             "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("Invalid default answer: '{}'".format(default))

    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' "
                             "(or 'y' or 'n').\n")

def parse_args():
    global config
    global theUsage

    parser = argparse.ArgumentParser(description='Usage of ' + __file__)
    parser.add_argument('action', help='Action: add|clean')
    parser.add_argument('target', help='Target config dir name', nargs='?', default="wad")
    parser.add_argument('-n','--dryrun', help='Dryrun dump config', required=False, action='store_true', dest='dryrun')
    parser.add_argument('-m','--module', help='Module: wad|proxy', required=False)
    parser.add_argument('-f','--file',   help='File name match regex', required=False)
    parser.add_argument('-s','--symbol', help='Symbol function name match regex', required=False)
    parser.add_argument('-c','--client', help='Neovim client listen address', required=False)
    args = vars(parser.parse_args())

    config['target'] = 'wad'
    if 'target' in args and args['target'] is not None:
        config['target'] = args['target'];
    # The config tree lives at ~/dotwiki/config/trace.d, independently of
    # where this script is installed. ME_TRACE_CONFIG_DIR overrides it; the
    # fallback keeps the original relative layout working.
    dir_path = os.environ.get('ME_TRACE_CONFIG_DIR')
    if not dir_path:
        dir_path = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
        dir_path = os.path.join(dir_path, 'config')
    config['targetDir'] = dir_path + '/trace.d/' + config['target'] + '/'

    targetCommon = config['target']
    # setting the maxsplit parameter to 1, will return a list with 2 elements!
    targetCommon = targetCommon.split("-", 1)
    if len(targetCommon) >= 1:
        config['commonDir'] = dir_path + '/trace.d/' + targetCommon[0] + '-common/'
    else:
        config['commonDir'] = dir_path + '/trace.d/common/'

    inifile = os.path.join(config['commonDir'], 'conf.ini')
    if os.path.exists(inifile):
        # load common skip* config from common/conf.ini
        inifile = config['commonDir'] + 'conf.ini'
        conf = configparser.ConfigParser()
        conf.read(inifile)

        config['skip_file_list0'] = conf.get('config', 'skip_file_list')      .strip("  ").strip("'").strip('"')
        fpath = os.path.join(config['commonDir'], config['skip_file_list0'])
        if os.path.exists(fpath):
            config['skip_file_list0'] = os.path.abspath(fpath)
        else:
            config.pop("skip_file_list0")

        config['skip_func_list0'] = conf.get('config', 'skip_func_list')      .strip("  ").strip("'").strip('"')
        fpath = os.path.join(config['commonDir'], config['skip_func_list0'])
        if os.path.exists(fpath):
            config['skip_func_list0'] = os.path.abspath(fpath)
        else:
            config.pop("skip_func_list0")

        config['skip_func_regex_list0'] = conf.get('config', 'skip_func_regex_list')      .strip("  ").strip("'").strip('"')
        fpath = os.path.join(config['commonDir'], config['skip_func_regex_list0'])
        if os.path.exists(fpath):
            config['skip_func_regex_list0'] = os.path.abspath(fpath)
        else:
            config.pop("skip_func_regex_list0")

    # load default config from conf.ini
    inifile = os.path.join(config['targetDir'], 'conf.ini')
    if os.path.exists(inifile):
        conf = configparser.ConfigParser()
        conf.read(inifile)
        config['vim_server_addr']      = conf.get('config', 'vim_server_addr')     .strip("  ").strip("'").strip('"')
        config['action']               = conf.get('config', 'action')              .strip("  ").strip("'").strip('"')
        config['select_file_regex']    = conf.get('config', 'select_file_regex')   .strip("  ").strip("'").strip('"')
        config['select_func_regex']    = conf.get('config', 'select_func_regex')   .strip("  ").strip("'").strip('"')
        config['our_trace_tag']        = conf.get('config', 'our_trace_tag')       .strip("  ").strip("'").strip('"')

        config['patch_file']           = os.path.abspath(config['targetDir'] + conf.get('config', 'patch_file')          .strip("  ").strip("'").strip('"'))
        config['skip_file_list']       = os.path.abspath(config['targetDir'] + conf.get('config', 'skip_file_list')      .strip("  ").strip("'").strip('"'))
        config['skip_func_list']       = os.path.abspath(config['targetDir'] + conf.get('config', 'skip_func_list')      .strip("  ").strip("'").strip('"'))
        config['skip_func_regex_list'] = os.path.abspath(config['targetDir'] + conf.get('config', 'skip_func_regex_list').strip("  ").strip("'").strip('"'))
    else:
        raise ValueError("Can't find config file '{}'', exit!".format(inifile))

    # override default config from user command arguments
    if 'action' in args and args['action'] is not None:
        config['action'] = args['action']
    if 'file' in args and args['file'] is not None:
        config['select_file_regex'] = args['file']
    if 'symbol' in args and args['symbol'] is not None:
        config['select_func_regex'] = args['symbol'];
    if 'client' in args and args['client'] is not None:
        config['vim_server_addr'] = args['client'];

    print("========CONFIG==========")
    pprint(config)
    print("========End CONFIG==========")
    if 'dryrun' in args and args['dryrun']:
        raise SystemExit


def load_from_file(res, fn, info):
    print(("{}: {} ...".format(info, fn)))
    if os.path.isfile(fn):
        res = set(line.strip() for line in open(fn))
    return res

def load_ignores():
    global ign_files
    global ign_functions
    global ign_funcregs

    ign_files = load_from_file(ign_files, config['skip_file_list'], 'filter-out ignore files')
    if "skip_file_list0" in config:
        res0 = {}
        res0 = load_from_file(res0, config['skip_file_list0'], 'filter-out ignore common files')
        ign_files.update(res0)

    ign_functions = load_from_file(ign_functions, config['skip_func_list'], 'filter-out ignore functions')
    if "skip_func_list0" in config:
        res0 = {}
        res0 = load_from_file(res0, config['skip_func_list0'], 'filter-out ignore common functions')
        ign_functions.update(res0)

    ign_funcregs = load_from_file(ign_funcregs, config['skip_func_regex_list'], 'filter-out ignore func-regex')
    if "skip_func_regex_list0" in config:
        res0 = {}
        res0 = load_from_file(res0, config['skip_func_regex_list0'], 'filter-out ignore common func-regex')
        ign_funcregs.update(res0)
    res0 = {}

def parse_taglist():
    global config

    if not os.path.isfile('.tagx'):
        raise ValueError("No tagx file, please `tagme` first.")

    matcher = '$2 == "function"'
    if config['select_func_regex']:
        matcher += ' && $2~/' + config['select_func_regex'] + '/'
    if config['select_file_regex']:
        matcher += ' && $4~/' + config['select_file_regex'] + '/'

    # Generate config.type function file
    os.system("echo '[function]' > /tmp/vim.taglist")
    # function = file:line
    awk_cmdstr = "awk '(" + matcher + "){print $4\"+\"$3\" = \"$1}' .tagx >> /tmp/vim.taglist"
    print(awk_cmdstr)
    os.system(awk_cmdstr)

# @return bool
def filterout_trace_functions(file_line, func_name, filterout_files):
    global ign_files
    global ign_functions
    global ign_funcregs

    if func_name in ign_functions:
        return True;

    is_ign_func = False
    for ign_func in ign_funcregs:
        if not ign_func:
            continue
        if ign_func.startswith('#'):
            continue
        if re.search(ign_func, func_name):
            is_ign_func = True
            continue
    if is_ign_func:
        return True

    is_ign_file = False
    for ign_file in ign_files:
        if not ign_file:
            continue
        if ign_file.startswith('#'):
            continue
        if re.search(ign_file, file_line[0]):
            if file_line[0] not in filterout_files:
                filterout_files.add(file_line[0])
                #print(("ign_files: pattern={} file={}".format(ign_file, file_line[0])))
            is_ign_file = True
            continue
    if is_ign_file:
        return True
    return False

# @return f_cnt, tag_cnt, {file:{line:function, }, }
def parse_trace_functions():
    global config

    if not os.path.isfile('/tmp/vim.taglist'):
        raise ValueError("No taglist /tmp/vim.taglist, please `tagme` first.")

    filterout_files = set()
    dict_result = {}
    item_cnt = 0
    file_cnt = 0
    with open('/tmp/vim.taglist') as fp:
        confParser = configparser.RawConfigParser(allow_no_value=True)
        confParser.read_file(fp)
        for sec in confParser.sections():
            for (_file_line, func_name) in confParser.items(sec):
                file_line = _file_line.split("+")
                if len(file_line) < 2:
                    print(("len not enough: str={} len={}".format(str(file_line), len(file_line))))
                    continue

                if config['action'] == 'add' and filterout_trace_functions(file_line, func_name, filterout_files):
                    continue

                if file_line[0] not in dict_result:
                    dict_result[file_line[0]] = {}
                    file_cnt += 1
                line_func = dict_result[file_line[0]]
                line_func[file_line[1]] = func_name
                item_cnt += 1
    return file_cnt, item_cnt, dict_result

def get_nvim_instance(vim_server_addr):
    try:
        # Embed neovim into your python application instead of binding to a running neovim instance.
        #nvim = neovim.attach('child', argv=["/bin/env", "nvim", "--embed"])

        # Create a python API session attached to unix domain socket created above:
        path = vim_server_addr
        print("Attach path={}".format(vim_server_addr))
        nvim = neovim.attach('socket', path=vim_server_addr)
        print("nvim={}".format(nvim))
        return path, nvim
    except Exception as e:
        pass
    return path, None

# f_cnt, tag_cnt, {file:{line:function, }, }
def add_trace_nvim(file_cnt, item_cnt, dict_result):
    global config

    path, nvim = get_nvim_instance(config['vim_server_addr'])
    print("Working on nvim={}".format(nvim))
    if nvim is None:
        os.system('rm -fr ' + path)
        path, nvim = get_nvim_instance(config['vim_server_addr'])
    if nvim is None:
        raise NeovimNone

    have_repstr = False
    for (k_file, v_line_func) in tqdm(dict_result.items(), desc='Files'):
        nvim.command('e ' + k_file)
        nvim.command("w")
        if config['action'] == 'add':
            for (k_line, v_func) in tqdm(v_line_func.items(), desc='Functions', leave=False):
                nvim.command(k_line)
                nvim.command("call search('{', 'cW')")
                if not have_repstr:
                    nvim.command("s/{/{" + config['our_trace_tag'] + "/e")
                else:
                    nvim.command("&")
        elif config['action'] == 'clean':
            nvim.command("%s/{" + config['our_trace_tag'] + "/{/ge")
        nvim.command("w")

def patch_trace_implement(reverse):
    global config

    f_patch = config['patch_file']
    if not os.path.isfile(f_patch):
        return
    if reverse:
        os.system('patch -R -p0 < ' + f_patch)
    else:
        cmdstr = 'if ! patch -Rf -p0 -r - < ' + f_patch + '; then ' \
            'patch -p0 < ' + f_patch + '; fi'
        print(cmdstr)
        os.system(cmdstr)

def main():
    global config

    try:
        parse_args()
        patch_trace_implement(config['action'] == 'clean')

        question = "Are you sure the tag is latest and updated with 'tagme'?"
        choice = query_yes_no(question, default="yes")
        if not choice:
            return

        start_time = time.time()
        parse_taglist()
        if not os.path.isfile('/tmp/vim.taglist'):
            raise ValueError("No taglist /tmp/vim.taglist, please `tagme` first.")

        load_ignores()

        # {file:{line:function, }, }
        file_cnt, item_cnt, dict_result = parse_trace_functions()
        print(("Add trace functions number {} ...".format(item_cnt)))
        add_trace_nvim(file_cnt, item_cnt, dict_result)

        end_time = time.time()
        print(("Time {} sec".format(int(end_time - start_time))))

    except NormalReturn:
        print("Done!")
    except NeovimNone:
        print(("Should existed neovim instance by" \
              "\n    NVIM_PYTHON_LOG_FILE=/tmp/nvim.log NVIM_PYTHON_LOG_LEVEL=DEBUG nvim"\
              "\n    NVIM_LISTEN_ADDRESS={} nvim".format(config['vim_server_addr'])))

    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print((exc_type, fname, exc_tb.tb_lineno))
        print(("  : " + str(e)))


if  __name__ =='__main__':
    main()

