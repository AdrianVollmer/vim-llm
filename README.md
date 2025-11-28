# llm.vim

A Vim plugin that provides an interface to the
[`llm`](https://llm.datasette.io/) command-line tool for accessing Large
Language Models.

## Features

- Execute llm templates on visually selected text
- Tab completion for available templates
- Visual diff presentation of changes
- Accept or reject modifications interactively

## Requirements

- Vim 8.0+ or Neovim
- [`llm`](https://llm.datasette.io/) tool

## Installation

### Using vim-plug

```vim
Plug 'path/to/llm.vim'
```

### Using Vundle

```vim
Plugin 'path/to/llm.vim'
```

### Manual Installation

Copy or symlink this directory to your `~/.vim/pack/<plugins>/start/` directory.

## Usage

### Basic Command

```vim
:<range>Llm <template> [<prompt>...]
```

- `<range>`: Visual selection or line range (e.g., `1,10` or use visual mode)
- `<template>`: Name of an llm template (supports tab completion)
- `<prompt>`: Optional additional prompt text

### Example Workflow

1. Select text in visual mode (press `v` or `V`)
2. Execute the command:
  
```vim
   :'<,'>Llm summarize
   ```
  
or with an additional prompt:
  
```vim
   :'<,'>Llm summarize make it concise
   ```

1. A diff view opens in a new tab showing:
   - Left pane: Original text
   - Right pane: Modified text from llm

2. Review the changes and either:
   - Type `:LlmAccept` to apply the changes
   - Close the tab to discard changes

### Tab Completion

The plugin provides tab completion for template names. After typing `:Llm`,
press `<Tab>` to cycle through available templates.

To see available templates, run:

```bash
uv tool run llm templates list
```

### Creating Templates

You can create custom templates for the llm tool. Refer to the [llm
documentation](https://llm.datasette.io/en/stable/templates.html) for details on
creating templates.

Example:

```bash
llm --save fix-grammar "Fix grammar and spelling in the following text"
```

## Commands

### `:Llm`

Main command to execute llm on selected text.

**Syntax:**

```vim
:[range]Llm <template> [<prompt>...]
```

**Examples:**

```vim
:1,10Llm summarize
:'<,'>Llm fix-grammar
:'<,'>Llm translate translate to Spanish
```

### `:LlmAccept`

Accept changes shown in the diff view and apply them to the original buffer.

**Syntax:**

```vim
:LlmAccept
```

This command is only available in the diff view buffer.

## Configuration

The plugin can be customized with the following options in your `.vimrc` or `init.vim`:

### `g:llm_command`

Path or command to invoke the llm tool. Default: `'llm'`

**Example:**

```vim
" Use a specific path to llm
let g:llm_command = '/usr/local/bin/llm'

" Use llm via uv tool run
let g:llm_command = 'uv tool run llm'
```

### `g:llm_diff_wrap`

Enable line wrapping in diff view buffers. Default: `1` (enabled)

**Example:**

```vim
" Disable line wrap in diff views
let g:llm_diff_wrap = 0

" Enable line wrap in diff views (default)
let g:llm_diff_wrap = 1
```

## Troubleshooting

### Templates not showing in completion

Make sure the llm tool is properly installed:

```bash
uv tool install llm
# Or with pipx:
pipx install llm
```

### Command fails with error

Check that llm is working correctly:

```bash
echo "test" | llm -t <template>
```

### No diff showing

Ensure that the llm command produces output. Some templates may require specific
parameters or model configuration.

## License

This plugin is released into the public domain.
