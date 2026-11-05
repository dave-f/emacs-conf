;;; init.el --- Personal Emacs configuration  -*- lexical-binding: t -*-

;;; ==================================================================
;;; Bootstrap.  Every package has a use-package block below, and
;;; use-package-always-ensure installs any that are missing at startup.
;;; ==================================================================

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; setopt is setq for user options: it type-checks the value and runs the
;; option's setter.  It's only used here, for the two settings needed
;; before any use-package runs; everything else is in use-package :custom.
(setopt use-package-always-ensure t)

;; Custom gets its own file so it stops appending to this one, and so a
;; broken form here can never strand the settings below it.
(setopt custom-file (expand-file-name "custom.el" user-emacs-directory))

;;; ==================================================================
;;; Completion
;;; ==================================================================

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  ;; Lets ~/d/my-p expand to ~/Dev/my-project, and keeps TRAMP paths working.
  (completion-category-overrides '((file (styles partial-completion)))))

;; Persist minibuffer history, which vertico uses to rank candidates.
(use-package savehist
  :ensure nil
  :config
  (savehist-mode 1))

(use-package vertico
  :config
  (vertico-mode 1))

;; Ships inside the vertico package.  In file prompts DEL removes a whole
;; path component, and typing ~/ or / after a path discards what precedes it.
(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
         ("RET"   . vertico-directory-enter)
         ("DEL"   . vertico-directory-delete-char)
         ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;; Icons in the minibuffer, next to marginalia's annotations.
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; Annotations beside minibuffer candidates (sizes, docstrings, ...).
;; Must come after nerd-icons-completion: turning the mode on runs the
;; hook that block adds, which is what puts the icons in.
(use-package marginalia
  :config
  (marginalia-mode 1))

;; nerd-icons gives a "<>" icon to any folder whose name merely contains
;; "code" (e.g. "Transcoder"), plus src and workspace.  Nearly every
;; folder here holds code, so drop those rules and keep the plain folder.
(use-package nerd-icons
  :defer t
  :config
  (setq nerd-icons-dir-icon-alist
        (seq-remove (lambda (rule) (equal (nth 2 rule) "nf-oct-code"))
                    nerd-icons-dir-icon-alist)))

(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g o"   . consult-outline)
         ("C-x C-r" . consult-recent-file)
         ("M-s l"   . consult-line)
         ("M-s r"   . consult-ripgrep)
         ("C-<f5>"  . consult-ripgrep)))

(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;; ==================================================================
;;; Languages.  Modes for file types Emacs has no built-in mode for;
;;; each loads when a matching file is opened.
;;; ==================================================================

(use-package lua-mode :defer t)
(use-package markdown-mode :defer t)

;;; ==================================================================
;;; Language servers.  eglot is built in and stays idle until started
;;; with M-x eglot, or by a mode hook calling eglot-ensure.
;;; ==================================================================

(use-package eglot
  :custom
  (eglot-autoshutdown t)          ; stop the server with its last buffer
  (eglot-events-buffer-size 0)    ; no protocol log; faster
  :bind (:map eglot-mode-map
         ("C-c r" . eglot-rename)
         ("C-c a" . eglot-code-actions)
         ("C-c f" . eglot-format-buffer)))

;;; ==================================================================
;;; Terminal.  ghostel is a real terminal (libghostty) for full-screen
;;; programs eshell can't run.  On trial: start it with M-x ghostel;
;;; the first run offers to download the prebuilt native module.
;;; ==================================================================

;; Keys Emacs keeps (C-x, C-c, C-u, C-h, M-x ...) never reach the program,
;; so Claude Code's C-x commands (agents view etc.) are lost.  Fixes:
;;   C-c M-d      char mode: every key, C-x included, goes to the terminal
;;   M-RET        leave char mode (the only way out), back to Emacs keys
;;   C-c C-q C-x  send just one C-x without switching mode
;; Also handy: C-c C-e read-only Emacs view of the output (q to return),
;; C-c C-c sends Ctrl-C, C-c M-p / C-c M-n jump between prompts.
;;
;; Git for Windows' less (git's pager) rejects TERM=xterm-ghostty with
;; "unknown terminal type", so advertise a generic xterm instead.
(use-package ghostel
  :defer t
  :custom
  (ghostel-term "xterm-256color"))

;; eshell (C-x x) prompt with git status; set once eshell loads.
(use-package eshell-git-prompt
  :after eshell
  :config
  (eshell-git-prompt-use-theme 'robbyrussell))

;;; ==================================================================
;;; Platform
;;; ==================================================================

(when (memq system-type '(ms-dos windows-nt))
  (add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font Mono 10"))
  ;; No font is assigned to emoji by default, so they show as boxes.
  ;; Segoe UI Emoji ships with Windows and draws in colour via DirectWrite.
  (set-fontset-font t 'emoji (font-spec :family "Segoe UI Emoji") nil 'prepend)
  ;; Media symbols (play, pause, stop: U+23F4..U+23FA) aren't emoji and no
  ;; other font has them; Claude Code shows "auto mode on" with two plays.
  (set-fontset-font t '(#x23F4 . #x23FA) (font-spec :family "Segoe UI Symbol")
                    nil 'prepend)
  ;; Misc Mathematical Symbols-B (U+2980..U+29FF) isn't in FiraCode either;
  ;; Claude Code's footer marks an open artifact with U+29C9 (two joined squares).
  (set-fontset-font t '(#x2980 . #x29FF) (font-spec :family "Segoe UI Symbol")
                    nil 'prepend))

;;; ==================================================================
;;; Org
;;; ==================================================================

;; Capture templates are machine-specific (file paths), so live in local.el.
(use-package org
  :ensure nil
  :bind ("C-c c" . org-capture)
  :custom
  (org-startup-indented t)
  (org-hide-emphasis-markers t)
  (org-log-done 'time)
  (org-tags-column -100)
  ;; toggle this with C-c C-x C-t in an org buffer
  (org-time-stamp-custom-formats '("<%d/%m/%Y %a>" . "<%d/%m/%Y %a %H:%M>"))
  ;; Refile to headings up to level 2, picked as one "Parent/Child" path.
  (org-refile-targets '((nil :maxlevel . 2)))
  (org-refile-use-outline-path t)
  (org-outline-path-complete-in-steps nil))

(use-package org-agenda
  :ensure nil
  :bind ("C-c a" . org-agenda)
  :custom
  (org-agenda-tags-column -100)
  (org-agenda-custom-commands
   '(("n" "Agenda/tickets"
      ((agenda "")
       ;(tags-todo "ticket")
       ;(tags-todo "-ticket-home-xmas-cloud")
       ;(tags-todo "home")))))
       (todo "TODO"))))))

(use-package ox
  :ensure nil
  :defer t
  :custom
  (org-export-date-timestamp-format "%d/%m/%Y"))

;; Bootstrap-styled HTML export, offered in the export menu (C-c C-e).
(use-package ox-twbs
  :after ox)

;; The default fold stars use glyphs (e.g. U+2BC8 at level 3) that no
;; installed font has.  FiraCode has these two; indentation shows the level.
(use-package org-modern
  :custom
  ;; Character codes, not literal glyphs, so the file stays ASCII and its
  ;; encoding can't matter.  Black right- and down-pointing triangles.
  (org-modern-fold-stars (list (cons (string #x25B6) (string #x25BC))))
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

;; Remove \emsp from clock-mode tables, see:
;; http://emacs.stackexchange.com/questions/9528/is-it-possible-to-remove-emsp-from-clock-report-but-preserve-indentation
(defun my-org-clocktable-indent-string (level)
  "Indent a clocktable headline of LEVEL with underscores, not \\emsp.
Overrides `org-clocktable-indent-string'."
  (if (= level 1)
      ""
    (let ((str "\\"))
      (while (> level 2)
        (setq level (1- level)
              str (concat str "__")))
      (concat str "__ "))))

(advice-add 'org-clocktable-indent-string
            :override #'my-org-clocktable-indent-string)

;;; ==================================================================
;;; LaTeX
;;; On Windows this needs MikTeX, the auctex package, and SumatraPDF.
;;; ==================================================================

;; The package is auctex but the library is tex, hence :ensure auctex.
(use-package tex
  :ensure auctex
  :defer t
  :custom
  (TeX-PDF-mode t)
  (TeX-source-correlate-mode t)
  (TeX-source-correlate-method 'synctex)
  (TeX-view-program-list
   `(("Sumatra PDF" (,(concat "\"" (expand-file-name "SumatraPDF/SumatraPDF.exe"
                                                     (getenv "LOCALAPPDATA"))
                              "\" -reuse-instance")
                     (mode-io-correlate " -forward-search %b %n ") " %o"))))
  :config
  (setf (alist-get 'output-pdf TeX-view-program-selection) '("Sumatra PDF")))

;;; ==================================================================
;;; Utilities
;;; ==================================================================

(defmacro measure-time (&rest body)
  "Measure the time it takes to evaluate BODY."
  `(let ((time (current-time)))
     ,@body
     (message "%.06f" (float-time (time-since time)))))

;; Pick from a list of files in the repo.  Should probably fall back to
;; vanilla `find-file' if not in a git repo?
(defun my-consult-git-ls-files ()
  "Use `consult' to select from git tracked files."
  (interactive)
  ;; consult--read isn't autoloaded, and consult otherwise only loads
  ;; when one of its bound commands is first used.
  (require 'consult)
  (let ((git-files (split-string
                    (shell-command-to-string (concat "git ls-files " (vc-root-dir)))
                    "\n" t))
        (case-fold-search t))
    (if (string-match-p "not a git repository" (or (car git-files) ""))
        (error "Not in a Git repository")
      (find-file
       (consult--read git-files
                      :prompt "Find file in repo: "
                      :sort nil
                      :require-match t
                      :category 'file
                      :state (consult--file-preview))))))

;; Used to easily visit a file in hex
(defun dired-do-hexl-find-file ()
  "Visit file at point in a hexl buffer."
  (interactive)
  (let ((file-name (dired-get-filename)))
    (hexl-find-file file-name)))

(defun xml-pretty ()
  "Break a single-line XML document onto one tag per line and indent it."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (search-forward "><" nil t)
      (replace-match ">\n<"))
    (indent-region (point-min) (point-max))))

(defun my-make (arg)
  "Run make in the current directory; prefix ARG picks the target.
With one \\[universal-argument] run \"make tags\"; with two or more,
\"make gfx\"."
  (interactive "P")
  (compile (cond ((not (consp arg)) "make")
                 ((> (prefix-numeric-value arg) 4) "make gfx")
                 (t "make tags"))))

(defun my-make-run ()
  "Run \"make run\" in the current directory."
  (interactive)
  (compile "make run"))

(defun my-revert-buffer-no-confirm ()
  "Revert the current buffer from its file without asking."
  (interactive)
  (revert-buffer nil t))

(defun my-ibuffer ()
  "Show ibuffer in another window, named *Buffer List*, without selecting it."
  (interactive)
  (ibuffer t "*Buffer List*" nil t t))

(defun my-eshell-toggle (arg)
  "Switch to eshell, or back to the previous buffer if already there.
ARG is passed on to `eshell': with \\[universal-argument] start a new
eshell, with a number N switch to *eshell*<N>."
  (interactive "P")
  (if (string= (buffer-name) "*eshell*")
      (switch-to-prev-buffer)
    (eshell arg)))

(defun my-dired-touch ()
  "Update the modification time of the file at point, then refresh Dired."
  (interactive)
  (set-file-times (dired-get-filename))   ; no time given means now
  (revert-buffer))

(defun my-dired-sha1 ()
  "Show the SHA-1 hash of the file at point in the echo area."
  (interactive)
  (let ((file (dired-get-filename)))
    (with-temp-buffer
      (set-buffer-multibyte nil)          ; hash the raw bytes
      (insert-file-contents-literally file)
      (message "sha1 %s" (secure-hash 'sha1 (current-buffer))))))

;;; ==================================================================
;;; Key bindings
;;; ==================================================================

;; Package-specific keys live in each package's use-package :bind.
;; keymap-global-set validates its key string, so a typo is an error at
;; startup rather than a silently wrong binding.  Modifiers go outside
;; the angle brackets: "C-<f5>", not "<C-f5>".

(keymap-global-set "<f7>"    #'my-make)
(keymap-global-set "C-<f7>"  #'my-make-run)
(keymap-global-set "<f10>"   #'my-revert-buffer-no-confirm)
(keymap-global-set "<f12>"   #'calculator)
(keymap-global-set "M-<f12>" #'quick-calc)
(keymap-global-set "C-<f12>" #'quick-calc)
(keymap-global-set "C-x C-b" #'my-ibuffer)
(keymap-global-set "C-x i"   #'overwrite-mode)
(keymap-global-set "C-x f"   #'my-consult-git-ls-files)
(keymap-global-set "C-x w w" #'whitespace-mode)
(keymap-global-set "C-x x"   #'my-eshell-toggle)

;;; ==================================================================
;;; Display
;;; ==================================================================

(use-package time
  :ensure nil
  :custom
  ;; To make the time display in its own colour.
  ;; The third arg to format-time-string is the zone; t means UTC.
  (display-time-string-forms
   '((propertize (format-time-string "%d %b %Y  %H:%M" now) 'face 'org-agenda-date)
     (propertize (format-time-string " (%H:%M UTC) " now t) 'face 'org-agenda-date)))
  ;; see this for setting time zones:
  ;; http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  (display-time-world-list '(("GMT0" "UTC")
                             ("GMT0BST" "London")
                             ("UCT-8" "Singapore")
                             ("EST5EDT" "New York")
                             ("PST8PDT" "Las Vegas")))
  (display-time-24hr-format t)
  (display-time-day-and-date t)
  :config
  ;; The clock borrows org-agenda-date's colour.  Org itself now loads on
  ;; first use, so define just its faces (about 0.05s, not 0.5s for org).
  (require 'org-faces)
  (display-time-mode 1))

(use-package doom-modeline
  :config
  (doom-modeline-mode 1))

;; The theme itself is switched on by custom.el (custom-enabled-themes);
;; this block only makes sure the package is installed.
(use-package sendai-theme :defer t)

;; Built-in global modes and plain settings.  :custom sets default
;; values, so it covers buffer-local options like tab-width too.
(use-package emacs
  :ensure nil
  :hook (prog-mode . display-line-numbers-mode)
  :custom
  (inhibit-splash-screen t)
  (split-width-threshold nil)
  (visible-bell t)
  (make-backup-files nil)
  (auto-save-default nil)
  (tab-width 4)
  (indent-tabs-mode nil)
  :config
  ;; which-key and completion-preview are built in from Emacs 30.
  (which-key-mode 1)
  (global-completion-preview-mode 1)
  (recentf-mode 1)
  (menu-bar-mode 0)
  (column-number-mode 1)
  (tool-bar-mode 0)
  (show-paren-mode 1)
  (scroll-bar-mode 0)
  (display-battery-mode 1)
  (global-auto-revert-mode 1)
  (pixel-scroll-precision-mode 1)
  (size-indication-mode 1)
  (electric-indent-mode -1)
  (windmove-default-keybindings)
  (setq ruler-mode-show-tab-stops t)
  (setq frame-title-format
        '("emacs " emacs-version " ("
          (:eval (or buffer-file-name
                     (and (derived-mode-p 'dired-mode) (expand-file-name default-directory))
                     (buffer-name)))
          ")"))
  (put 'narrow-to-region 'disabled nil)
  (put 'set-goal-column 'disabled nil)
  (put 'upcase-region 'disabled nil)
  (put 'downcase-region 'disabled nil))

;; Offsets on top of the style, set per buffer after the style applies.
(defun my-c-offsets ()
  "Apply personal indentation offsets in a CC Mode buffer."
  (c-set-offset 'access-label -3)
  (c-set-offset 'inline-open 0))

(use-package cc-mode
  :ensure nil
  :mode ("\\.h\\'" . c++-mode)
  :hook (c-mode-common . my-c-offsets)
  :custom
  (c-default-style
   '((java-mode . "java") (awk-mode . "awk") (other . "stroustrup"))))

(use-package grep
  :ensure nil
  :if (memq system-type '(ms-dos windows-nt))
  :defer t
  :custom
  (grep-command "rg -nH --no-heading -e "))

;; Don't error if a server is already running in another Emacs.
(use-package server
  :ensure nil
  :config
  (unless (server-running-p)
    (server-start)))

;;; ==================================================================
;;; Modes.  Keys go in :bind (:map ...), which binds them once when the
;;; package loads, rather than on every buffer from inside a hook.
;;; ==================================================================

;; asm-mode gives each buffer its own local map with ; bound to
;; asm-comment, so that one key has to be unset per buffer, from the hook.
(defun my-asm-plain-semicolon ()
  "Make ; self-insert in this asm buffer instead of running `asm-comment'."
  (keymap-local-unset ";"))

(use-package asm-mode
  :ensure nil
  :bind (:map asm-mode-map
         ("RET"   . newline)
         ("C-c ." . org-time-stamp))
  :hook ((asm-mode . my-asm-plain-semicolon)
         (asm-mode . ruler-mode)))

(use-package package
  :ensure nil
  :hook (package-menu-mode . hl-line-mode))

(use-package dired
  :ensure nil
  :bind (:map dired-mode-map
         ("M-RET" . dired-do-hexl-find-file)
         ("T"     . my-dired-touch)
         ("c"     . my-dired-sha1))
  :hook (dired-mode . hl-line-mode)
  :custom
  (dired-dwim-target t)
  (dired-auto-revert-buffer t)
  (dired-dnd-protocol-alist nil))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package restclient
  :bind (:map restclient-mode-map
         ("C-c C-v" . restclient-send-current-stay-in-window)))

(use-package magit
  :bind ("C-x g" . magit-status)
  :config
  (magit-add-section-hook 'magit-status-sections-hook
                          #'magit-insert-worktrees
                          nil t))

(use-package rg
  :bind ("<f5>" . rg))

;;; ==================================================================
;;; Local.  Machine- and work-specific settings (hard-coded paths,
;;; internal tooling, employer-specific libraries) live in local.el
;;; next to this file, which is not published.  Missing is fine.
;;; ==================================================================

;; local.el defines transient menus as it loads.
(require 'transient)
(load (expand-file-name "local.el" user-emacs-directory) t)

;;; ==================================================================
;;; Custom.  Loaded last: it sets the theme, which needs the theme
;;; package to be installed already.
;;; ==================================================================

(load custom-file t)

;;; init.el ends here
