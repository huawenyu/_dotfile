# me — Deploy Instructions

## Setup

### 1. Install the dispatcher and subcommands

`me` and `me-*` files are already in `~/script/`. Ensure `~/script` is on your PATH:

```bash
export PATH="$HOME/script:$PATH"
# Add to ~/.bashrc or ~/.zshrc for permanence
```

### 2. Enable shell completions

#### Bash

```bash
# Current session
source <(me completion bash)

# Permanent (appends to ~/.bashrc)
echo 'source <(me completion bash)' >> ~/.bashrc
```

#### Zsh

```bash
# Create completions directory if needed
mkdir -p ~/.zsh/completions

# Install completion
me completion zsh > ~/.zsh/completions/_me

# Ensure compinit runs (add to ~/.zshrc if not present)
autoload -Uz compinit && compinit
```

#### Fish

```bash
me completion fish > ~/.config/fish/completions/me.fish
```

## Usage

```bash
me help              # List all subcommands
me help <subcmd>     # Help for specific subcommand
me completion bash   # Print bash completion script
me completion zsh    # Print zsh completion script
me completion fish   # Print fish completion script
```

### Subcommand Hierarchy

```
me              # Top-level commands
├── ai          # AI helpers (log)
├── clang       # Clang-related helpers
├── config      # Configuration (dut, gitvan)
├── fgt         # FortiGate tools (addr2line, craddr, eco, pcap)
├── ssh         # Mount remote directory via SSHFS
├── sync        # Sync files
├── tag         # Tag management
├── tmux        # Tmux helpers
├── tool        # Miscellaneous tools (addr2line, craddr)
├── trace       # Trace utilities
└── update      # Update utilities (dot, nvim, repo, wiki)
```

## Adding New Subcommands

### Decision: Wrapper vs Direct Modification

| Approach | When to Use | Pattern |
|----------|-------------|---------|
| **Direct** | Shell scripts you own, simple logic | Add me API directly to script |
| **Flat+Dir** | Non-shell scripts (Python, Ruby, Perl), third-party scripts, complex scripts | Create `me-cmd/_main_` wrapper |

### Decision Examples

| Script Type | Approach |
|------------|----------|
| `new_genco.sh` (shell) | Direct modification |
| `me-update-work.sh` (shell) | Direct modification |
| `craddr.pl` (Perl) | Flat+Dir with `_main_` wrapper |
| `fgt2eth.pl` (Perl) | Flat+Dir with `_main_` wrapper |
| `addrmapsearch.rb` (Ruby) | Flat+Dir with `_main_` wrapper |

### Direct Modification Pattern

Add me API at the top of the shell script:

```bash
#!/usr/bin/env bash
# Usage: me parent child [options]
# Summary: One-line description

case "${1:-}" in
    --summary) echo "One-line description"; exit 0 ;;
    --complete|__complete)
        printf '%s\n' --help -h arg1 arg2
        exit 0 ;;
    -h|--help)
        echo "Usage: me parent child [arg1|arg2]"
        echo ""
        echo "Script: ${BASH_SOURCE[0]}"
        exit 0 ;;
esac

# Original script content starts here...
```

### Flat+Dir Pattern

Create directory with `_main_` wrapper:

```
me-cmd/
├── _main_      # Bash wrapper with me API
└── script.py   # Original implementation
```

```bash
#!/usr/bin/env bash
# Usage: me cmd [options]
# Summary: Description

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
    --summary) echo "Description"; exit 0 ;;
    --complete|__complete)
        printf '%s\n' --help -h -- opt1 opt2
        exit 0 ;;
    -h|--help)
        echo "Usage: me cmd [opt1|opt2]"
        echo ""
        echo "Script: ${BASH_SOURCE[0]}"
        exit 0 ;;
esac

exec "$DIR/script.py" "$@"
```

Each subcommand must support `--summary`, `--help`, `--complete`, and `__complete` flags.
