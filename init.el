;;; -*- lexical-binding: t; -*-

;; Bootstrap the package manager.
(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))

(use-package emacs
  :custom
  (tool-bar-mode nil)
  (menu-bar-mode nil)
  (scroll-bar-mode nil)
  (inhibit-splash-screen t)
  (electric-pair-mode t)
  (fringe-mode 25)
  (line-spacing 0.25)
  (sentence-end-double-space nil)
  (enable-recursive-minibuffers t)
  (disabled-command-function nil)
  (tab-always-indent 'complete)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (text-mode-ispell-word-completion nil)
  (modus-themes-mixed-fonts t)
  (custom-file "/dev/null")
  (view-read-only t)
  :bind
  ("C-h" . delete-backward-char)
  ("<down>" . scroll-up-line)
  ("<up>" . scroll-down-line)
  :config
  ;; (load-theme 'modus-operandi)
  (defun init--update-scratch-message ()
    (let ((cod-quotes '(";; There are three states of being. Not knowing, action and completion."
			";; Accept that everything is a draft. It helps to get it done."
			";; There is no editing stage."
			";; Pretending you know what you’re doing is almost the\n;; same as knowing what you are doing, so just accept\n;; that you know what you’re doing even if you don’t and\n;; do it."
			";; Banish procrastination. If you wait more than a week\n;; to get an idea done, abandon it."
			";; The point of being done is not to finish but to get\n;; other things done."
			";; Once you're done you can throw it away."
			";; Laugh at perfection. It’s boring and keeps you from\n;; being done."
			";; People without dirty hands are wrong. Doing\n;; something makes you right."
			";; Failure counts as done. So do mistakes."
			";; Destruction is a variant of done."
			";; If you have an idea and publish it on the internet, that\n;; counts as a ghost of done."
			";; Done is the engine of more.")))
      (setq initial-scratch-message (nth (random 12) cod-quotes))))
  (advice-add 'get-scratch-buffer-create :before #'init--update-scratch-message)
  (init--update-scratch-message)

  (defun insert-time-stamp ()
	(interactive)
	(insert (format-time-string "%Y%m%dT%H%M")))
  (global-set-key (kbd "C-x t s") 'insert-time-stamp))

(use-package files
  :hook
  (before-save . delete-trailing-whitespace)
  :custom
  (require-final-newline t)
  ;; backup settings
  (backup-by-copying t)
  (backup-directory-alist
   `((".*" . ,(locate-user-emacs-file "backups"))))
  (delete-old-versions t)
  (kept-new-versions 6)
  (kept-old-versions 2)
  (version-control t))

(use-package faces
  :custom-face
  (default ((t (:family "Ubuntu Mono" :height 165))))
  (variable-pitch ((t (:family "Ubuntu" :hegiht 165)))))

(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("M-." . embark-dwim)
   :map help-map
   ("B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)
  ;; Show the Embark target at point via Eldoc.
  (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package marginalia
  :ensure t
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  :init
  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

(use-package consult
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (:map mode-specific-map
        ("M-x" . consult-mode-command)
        ("h" . consult-history)
        ("k" . consult-kmacro)
        ("m" . consult-man)
        ("i" . consult-info)
        ([remap info-search] . consult-info)
	:map ctl-x-map
        ([remap repeat-complex-command] . consult-complex-command)
        ([remap switch-to-buffer] . consult-buffer)
        ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
        ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
        ([remap switch-to-buffer-other-tab] . consult-buffer-other-tab)
        ([remap bookmark-jump] . consult-bookmark)
        ([remap project-switch-to-buffer] . consult-project-buffer)
        ;; Custom M-# bindings for fast register access
        ("M-#" . consult-register-load)
        ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
        ("C-M-#" . consult-register)
        ;; Other custom bindings
        ([remap yank-pop] . consult-yank-pop)
        :map goto-map
        ("e" . consult-compile-error)
	;; TODO: replace to consult-flycheck after fixing it
        ("f" . consult-flymake)                   ;; Alternative: consult-flymake
        ([remap goto-line] . consult-goto-line)
        ("o" . consult-outline)                   ;; Alternative: consult-org-heading
        ("m" . consult-mark)
        ("k" . consult-global-mark)
        ("i" . consult-imenu)
        ("I" . consult-imenu-multi)
        :map search-map
        ("d" . consult-find)                      ;; Alternative: consult-fd
        ("c" . consult-locate)
        ("g" . consult-grep)
        ("G" . consult-git-grep)
        ("r" . consult-ripgrep)
        ("l" . consult-line)
        ("L" . consult-line-multi)
        ("k" . consult-keep-lines)
        ("u" . consult-focus-lines)
        ;; Isearch integration
        ("e" . consult-isearch-history)
        :map isearch-mode-map
        ([remap isearch-edit-string] . consult-isearch-history)
        ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
        ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
        ;; Minibuffer history
        :map minibuffer-local-map
        ([remap next-matching-history-element] . consult-history)
        ([remap previous-matching-history-element] . consult-history))

  ;; Enable automatic preview at point in the *Completions* buffer.
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init
  ;; This improves the register preview for `consult-register',
  ;; `consult-register-load', `consult-register-store' and the Emacs
  ;; built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))
  (setq consult-narrow-key "<"))


(use-package embark-consult
  :ensure t ; only need to install it, embark loads it after consult if found
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :ensure t
  :custom
  (vertico-cycle t)
  (vertico-multiform-mode t)

  ;; Use a buffer with indices for imenu.
  (setq vertico-multiform-commands
	'((consult-imenu buffer indexed)))

  ;; Use the grid display for files and a buffer
  ;; for the consult-grep commands.
  (setq vertico-multiform-categories
	'((file grid)
          (consult-grep buffer)))

  :init (vertico-mode))

(use-package corfu
  :ensure t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-separator ?\s)
  (corfu-preview-current nil)

  ;; Corfu is enabled globally since Dabbrev can be used globally
  ;; (M-/). See also the customization variable `global-corfu-modes'
  ;; to exclude certain modes.
  :init
  (global-corfu-mode))

(use-package cape
  :ensure t
  :bind (("C-c p" . cape-prefix-map)
	 ("M-p"   . cape-prefix-map))

  :init
  ;; The order of the functions matters, the first function returning
  ;; a result wins. Note that the list of buffer-local completion
  ;; functions takes precedence over the global list.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history))

(use-package popper
  :ensure
	;; TODO: change binds here 'cause my keeb 2 smol
  :bind (("M-`"   . popper-toggle)
         ("C-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
	  "\\*Warnings\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          help-mode
          compilation-mode))
  (popper-mode t)
  (popper-echo-mode t))

(use-package ghelp
  :after embark
  :ensure (ghelp :host github :repo "https://github.com/casouri/ghelp/")
  :bind
  (:map help-map
	("g" . nil) ;; orig. describe-gnu-project
	("g g" . ghelp-describe)
	("g k" . ghelp-describe-key)
	:map embark-identifier-map
	("g" . ghelp-describe)))

(use-package dired
  :custom
  (dired-kill-when-opening-new-dired-buffer t))

(use-package tramp
  :config
  ;; Forbid TRAMP from making backups where it pleases.
  (add-to-list 'backup-directory-alist
               (cons tramp-file-name-regexp nil)))

(use-package magit
  :ensure t)

;; TODO: Fix flycheck
;; Problem is that it doesn't see cargo project and so it considers
;; every dependency unadded even if everything compiles
;; (use-package flycheck
;;   :ensure t
;;   :init
;;   (global-flycheck-mode t))

(use-package rustic
  :ensure t
  :custom
  (rustic-lsp-client 'eglot)
  (rustic-format-on-save t)
  :config
  ;; turn off flymake
  ;; (add-hook 'eglot--managed-mode-hook (lambda () (flymake-mode -1)))
  ;; (push 'rustic-clippy flycheck-checkers)
  ;; TODO: fix above two lines after fixing flycheck

  ;; A few things to remember:
  ;; C-c C-c prefix for rustic features
  ;; eglot-code-actions
)

(use-package nix-mode
  :ensure t)

(use-package go-mode
  :ensure t
  :hook (go-mode . eglot))

(use-package geiser
  :ensure t)

(use-package geiser-chicken
  :ensure t)

(use-package elfeed
  :ensure t
  :custom
  (elfeed-feeds '("https://news.ycombinator.com/rss"
		  "https://xkcd.com/rss.xml"
		  "https://readrust.net/all/feed.rss"
		  "https://math.stackexchange.com/feeds"
		  "https://fasterthanli.me/index.xml"
		  "https://karthinks.com/index.xml"
		  "https://forum.merveilles.town/rss.xml"
		  "https://100r.co/links/rss.xml"))
  :bind
  (:map ctl-x-map
	("F" . 'elfeed)))

(use-package doom-themes
  :ensure t
  :config
  (load-theme 'doom-tokyo-night t))

(use-package sly
  :ensure t)


;; I haven't updated to emacs with native treesitter yet :(
(elpaca (typst-mode :host github :repo "Ziqi-Yang/typst-mode.el"))
;; (elpaca (typst-ts-mode :host codeberg :repo "meow_king/typst-ts-mode"))

;;; note-taking
;; NOTE: The setup is a clusterfuck right now, as I'm still figuring
;; things out, but eventually it'll get there.

;; TODO: This sucks but maybe I just need to configure it differently
;; (use-package org-download
;;   :ensure t
;;   :hook
;;   (org-mode-hook . org-download-enable)
;;   :config
;;   (setq-default org-download-image-dir "~/Pictures"))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/Documents/notes/")
  (org-roam-complete-everywhere t)
  :bind (:map mode-specific-map
	      ("n j" . org-roam-dailies-capture-today)
	      ("n f" . org-roam-node-find)
	      ("n i" . org-roam-node-insert)
	      ("n l" . org-roam-buffer-toggle))
  :config
  ;; (add-hook 'org-roam-mode-hook (setq org-download-image-dir "~/Documents/notes/img"))
  (org-roam-setup))

(use-package deft
  :ensure t
  :after org
  :bind
  (:map mode-specific-map
	("n d" . deft)
	:map deft-mode-map
	("C-h" . deft-filter-decrement))
  :custom
  (deft-strip-summary-regexp
   (concat "\\("
	   "[\n\t]" ;; blank
	   "\\|^#\\+[[:alpha:]_]+:.*$" ;; org-mode metadata
	   "\\|^:PROPERTIES:\n\\(.+\n\\)+:END:\n"
	   "\\)"))
  (deft-recursive t)
  (deft-use-filter-string-for-filename t)
  (deft-default-extension "org")
  (deft-directory org-roam-directory)
  :config
  (defun init--deft-parse-title (file contents)
    "Parse the given FILE and CONTENTS and determine the title.
  If `deft-use-filename-as-title' is nil, the title is taken to
  be the first non-empty line of the FILE.  Else the base name of the FILE is
  used as title."
    (let ((begin (string-match "^#\\+[tT][iI][tT][lL][eE]: .*$" contents)))
      (if begin
	  (string-trim (substring contents begin (match-end 0)) "#\\+[tT][iI][tT][lL][eE]: *" "[\n\t ]+")
	(deft-base-filename file))))

  (advice-add 'deft-parse-title :override #'init--deft-parse-title))

(use-package org-roam-ui
  :ensure t
  :after org-roam
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-update-on-save t)
  (org-roam-ui-open-on-start t))

;; TODO: read-only-mode tweaks (automatic pager-mode, quitting on q, etc.)
;; TODO: corfu acts like shit in shells (and generally?)
;; TODO: paren editing
;; TODO: do something about the Nix Way™ of managing dev environments
;;       and how emacs doesn't play nice with it
;; TODO: customize org-mode so that :PROPERTIES: blocks don't get
;;       shown and headings are big and starless.
;; TODO: variable-pitch faces in org-mode and such
