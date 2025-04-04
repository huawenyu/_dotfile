#!/usr/bin/env python3
"""
Usage:
    clangme.py -a macro filename
    clangme.py --file stats_def.c

"""

import os
import json
import shutil
import argparse
import subprocess
from pathlib import Path

__version__ = "0.1.1.dev0"

class ScriptError(Exception):
    pass


def find_file_position_in_json(json_file, target_file):
    """Uses grep to find the line number where the file entry starts."""
    target_filename = Path(target_file).name
    # Use grep to find the line containing '"file": ".*target_filename"'
    cmd = [
        "grep",
        "-n",  # Show line numbers
        f'"file": ".*{target_filename}"',
        json_file
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None  # Not found

    # Extract the line number (e.g., "42: ...")
    line_num = int(result.stdout.split(":")[0])
    return line_num

def extract_json_block(json_file, start_line, out_file):
    """Extracts a single JSON block starting near `start_line`."""
    with open(json_file, 'r') as f:
        lines = f.readlines()

    # Find the start of the block (look for '{' before start_line)
    block_start = None
    for i in range(start_line - 1, max(0, start_line - 300), -1):
        if "{" in lines[i]:
            block_start = i
            break

    if block_start is None:
        return None

    # Find the end of the block (look for '}' after start_line)
    block_end = None
    skipline = 0
    jsonLines = []
    for i in range(block_start, min(len(lines), block_start + 300)):
        if i == skipline:
            continue

        #  oneline = lines[i]
        #  print(f"Lines {i}: {oneline}")
        if '"-c"' in lines[i]:
            jsonLines.append('"-v",')
            jsonLines.append('"-std=c11",')
            jsonLines.append('"-ferror-limit=4",')
            #  jsonLines.append('"-include",')
            #  jsonLines.append('"stdint.h",')
            jsonLines.append('"-Wno-microsoft-anon-tag",')
        elif ('"-g"' in lines[i] or
              '"-fno-reorder-functions"' in lines[i] or
              '"-fno-unit-at-a-time"' in lines[i] or
              '"-Wno-unused-but-set-variable"' in lines[i] or
              '"-Werror"' in lines[i] or
              '"-Wall"' in lines[i]):
            continue
        elif '"-o"' in lines[i]:
            jsonLines.append('"-o",')
            jsonLines.append(f'"{out_file}",')
            jsonLines.append('"-E",')
            jsonLines.append('"-P",')
            jsonLines.append('"-CC",')
            jsonLines.append('"-dD",')
            skipline = i + 1
        elif "}" in lines[i]:
            block_end = i
            jsonLines.append('}')
            break
        else:
            jsonLines.append(lines[i])

    if block_end is None:
        return None

    # Parse just this block as JSON: lines[block_start:block_end + 1]
    block = "".join(jsonLines)
    try:
        print(f"Json: {block}")
        return json.loads(block)
    except json.JSONDecodeError as e:
        print(f"Failed to decode JSON: {e}")
        return None

def run_clang_for_file(json_file, target_file, out_file, clang_path="clang"):
    if os.path.exists(json_file):
        """
        1. Uses grep to find the file’s position.
        2. Extracts only its JSON block.
        3. Runs the clang command.
        """
        line_num = find_file_position_in_json(json_file, target_file)
        if not line_num:
            print(f"Error: {target_file} not found in the existed {json_file}")
            return

        entry = extract_json_block(json_file, line_num, out_file)
        if not entry:
            print(f"Error: Could not parse entry for {target_file}")
            return

        # Build the command (supports both "command" and "arguments")
        if "arguments" in entry:
            args = entry["arguments"].copy()
            args[0] = clang_path
            command = args
        else:
            command = entry["command"].split()
            command[0] = clang_path

        print(f"Running in {entry['directory']}:")
        print(" ".join(command))

        subprocess.run(command, cwd=entry["directory"], check=True)
    else:
        subprocess.run([f"{clang_path}", "-Wall", '-Wno-unused-command-line-argument', "-O0", "-g", "-std=c11", "-I.", "-I./include",
                        '-lstdc++', '-lm', '-msse3',
                        '-o', f"{out_file}",
                        '-E', '-P', '-CC', '-dD',
                        target_file],
                       check=True)


def clang_safe_format(file_path, config_path):
    try:
        # clang-format -style=file:~/workref/.clang-format --assume-filename=log.c -i log.i

        if os.path.exists(config_path):
            subprocess.run(["clang-format", "-i", f"--style=file:{config_path}", "--assume-filename=log.c", file_path],
                    check=True)
        else:
            subprocess.run(["clang-format", "-i", f"--style=file", "--assume-filename=log.c", file_path],
                    check=True)
    except FileNotFoundError:
        print("clang-format executable not found")
        print(f"Install clang tools:")
        print(f"  nix-env -iA nixpkgs.clang-format")
        print(f"  nix-env -iA nixpkgs.clang-tools")
    except subprocess.CalledProcessError as e:
        print(f"clang-format failed with exit code {e.returncode}")
        if e.stderr:
            print(f"Error: {e.stderr}")


def is_tool_available(name):
    return shutil.which(name) is not None


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('--verbose', action='store_true')
    parser.add_argument('--file', required=True, help='Input file (required)')
    parser.add_argument('--config', default='.clang-format',
                        help='Configuration file')
    parser.add_argument('--action', default='macro', choices=['macro', 'compile', 'default'],
                        help='The action of clang')
    parser.add_argument('--out', default='log.i',
                        help='Output file (required)')
    args = parser.parse_args()

    try:
        validate_args(args)
    except argparse.ArgumentError as e:
        parser.error(str(e))

    #  if args.out == '-':
    #      output = sys.stdout
    #  else:
    #      output = open(args.out, 'wb')

    compile_db = "compile_commands.json"  # Large JSON file
    custom_clang = "clang"  # Specific clang version

    try:
        run_clang_for_file(compile_db, args.file, args.out, custom_clang)

        if os.path.exists(args.out):
            print(f"===\nFormatting '{args.out}', please wait ...\n")
            clang_safe_format(args.out, args.config)

    finally:
        pass

    #  output.flush()
    #  output.close()


def validate_args(args):
    if not all([args.file, args.out]):
        raise argparse.ArgumentError(None, "Both --file and --out are required")


def print_warning(e):
    print("WARNING: %s" % str(e), file=sys.stderr)


def print_error(e):
    print("ERROR: %s" % str(e), file=sys.stderr)

def cli_main():
    try:
        main()
    except IOError as e:
        import errno
        if e.errno == errno.EPIPE:
            # Exit saying we got SIGPIPE.
            sys.exit(141)
        raise
    except ScriptError as e:
        print("ERROR: %s" % str(e), file=sys.stderr)
        sys.exit(1)

# Example Usage
if __name__ == "__main__":
    cli_main()

