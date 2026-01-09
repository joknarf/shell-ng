[![Joknarf Tools](https://img.shields.io/badge/Joknarf%20Tools-Visit-darkgreen?logo=github)](https://joknarf.github.io/joknarf-tools)
[![Shell](https://img.shields.io/badge/shell-bash%20|%20zsh%20|%20(ksh)%20-blue.svg)]()
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://shields.io/)

# shell-ng
Shell next-gen plugin, the new shell experience (for bash/zsh/ksh) in native shell.

## features

All-in-one plugin optimized with joknarf shell command line customizations, includes:

| Plugin                                                | Short description                                       | Basic key binding                     |
|-------------------------------------------------------|---------------------------------------------------------|---------------------------------------|
| [selector](https://github.com/joknarf/selector)       | Interactive menu used in joknarf plugins (bash/zsh/ksh) |                                       |
| [nerdp](https://github.com/joknarf/nerdp)             | Nerd shell prompt (bash/zsh/ksh)                        |                                       |
| [redo](https://github.com/joknarf/redo)               | Command history interactive menu (bash/zsh)             | <kbd>Shit</kbd>-<kbd>Tab</kbd>        |
| [seedee](https://github.com/joknarf/seedee)           | Directory history interactive menu (bash/zsh/ksh)       | <kbd>Shift</kbd>-<kbd>▼</kbd>         |
| [complete-ng](https://github.com/joknarf/complete-ng) | Auto-completion interactive menu (bash/zsh)             | <kbd>Tab</kbd>                        |

## Demo

![shell-ng3](https://github.com/user-attachments/assets/431d6d71-0d0a-4fbc-bcb8-738cb1832880)

## Pre-requisites
* shell-ng is using Nerd Font glyphs, you should install Nerd font on your favorite terminal manager, or it should manage Nerd glyphs
* Basic standard gnu utilities (sed/awk/grep/tar/gzip)

## Install

Use a plugin manager like the famous [thefly](https://github.com/joknarf/thefly) (multi shell plugins/dotfiles manager and teleporter) :
```
fly add joknarf/shell-ng
```
thefly will allow to keep all your plugins available when connecting to remote servers through ssh, and even changing shell and user with sudo.

Or manually source the plugin for your shell :  
```
git clone https://github.com/joknarf/shell-ng
source shell-ng/shell-ng.plugin.${SHELL#*/}
```
