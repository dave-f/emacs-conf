# Emacs configuration

My personal Emacs configuration: a single `init.el`, used with Emacs 31 on Windows.

## Layout

- **`init.el`**: everything shared. Each package has its own `use-package` block, and `use-package-always-ensure` installs anything missing from GNU ELPA or MELPA on first start.
- **`local.el`** (not in this repo): machine-specific settings such as file paths, work tooling and personal key bindings. `init.el` loads it if it exists.
- **`custom.el`** (not in this repo): Emacs' own Customize output, including the theme. `init.el` loads it last.

The `.gitignore` is a whitelist, so nothing else in `.emacs.d` (packages, history, caches) ends up in the repo.

## Highlights

- **Completion:** vertico, orderless, marginalia, consult and embark, with nerd-icons in the minibuffer.
- **Org:** org-modern, plus agenda and refile setup.
- **Git:** magit, and a consult picker for tracked files on `C-x f`.
- **Terminal:** ghostel for full-screen terminal programs, and eshell for everything else.
- **LaTeX:** AUCTeX, viewing PDFs in SumatraPDF with SyncTeX forward search.

## Requirements

- Emacs 30 or later. which-key and completion-preview are built in from Emacs 30.
- A Nerd Font for the icons. On Windows the font is set to FiraCode Nerd Font Mono.
- On Windows: Segoe UI Emoji and Segoe UI Symbol (both included with Windows) for emoji and media symbols, and ripgrep for `rg` and `consult-ripgrep`.
