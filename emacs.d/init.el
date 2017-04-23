;; Everything's in one file to make it easier to find.
;; Remember that you can always add a .dir-locals.el file to any directory to override vars for a project.
;; TODO: slim this down for console!


;; ###### Platform detection #######

;; Are we on a mac (windowed)?
(defconst is-mac (memq window-system '(mac ns)))

;; ###### Bytecode Compiling #######

;; Always load the newer file, even if the bytecode file exists, so we
;; never end up loading an out-of-date bytecode file.
(setq load-prefer-newer t)

;; ###### Package Management (ELPA) #######

(require 'package)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")))
;; TODO: melpa-stable instead of melpa?? melpa is "HEAD" versions
(package-initialize)

;; Bootstrap `use-package': https://github.com/jwiegley/use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; use-package will automatically install missing packages
(require 'use-package)
(setq use-package-always-ensure t)
;; To manually manage packages: M-x package-list-packages

;; Auto-compile elisp to bytecode. This should be as early as possible.
(use-package auto-compile
  :init
  (auto-compile-on-load-mode)
  (auto-compile-on-save-mode))


;; ######## Configure general packages #######

;; Use-package:
;; :init runs before require, :config runs after (lazy) loading.
;; :bind, :defer, :commands, :mode, :interpreter all cause lazy loading.

;; Get PATH from shell on OSX, for when we launched from the dock
(use-package exec-path-from-shell
  :if is-mac
  :config
  ;; Don't whine about my environment
  (setq-default exec-path-from-shell-check-startup-file nil)
  (add-to-list 'exec-path-from-shell-variables "GEM_PATH")
  (add-to-list 'exec-path-from-shell-variables "GEM_HOME")
  (add-to-list 'exec-path-from-shell-variables "PYTHONPATH")
  (exec-path-from-shell-initialize))

;; package.el will automatically create and require autoloads files
;; for packages. Many of these have package autoloads that
;; sufficiently configure them. State them here so they get
;; auto-installed (and to make future configuration easier). We could
;; restate the autoloads here, but why bother?

;; Draw a thin line down the side of the buffer at a certain column.
(use-package fill-column-indicator
  :commands fci-mode
  :init
  (setq-default fci-rule-column 79)
  (add-hook 'prog-mode-hook 'fci-mode))

;; Do all your git tasks from emacs. Never use git CLI again.
;; http://daemianmack.com/magit-cheatsheet.html
(use-package magit
  :init
  ;; Turn off smartscan in magit
  (mapc (lambda (hook)
          (add-hook hook (lambda () (smartscan-mode -1))))
        '(git-rebase-mode-hook
          magit-mode-hook
          magit-popup-mode-hook))
  ;; Turn off auto revert since I use global auto revert mode
  (setq magit-auto-revert-mode nil)
  (setq magit-completing-read-function 'helm--completing-read-default)
  (setq magit-branch-prefer-remote-upstream '("master" "dev"))
  (add-hook 'git-commit-mode-hook 'comment-auto-fill)
  :config
  (advice-add 'magit-popup-mode-display-buffer :around
              'magit-popup-mode-display-buffer--split-window-sensibly)
  (defun magit-popup-mode-display-buffer--split-window-sensibly (fn buffer mode)
    (let ((split-window-preferred-function 'split-window-sensibly))
      (funcall fn buffer mode)))
  (global-magit-file-mode)
  :bind
  (("C-x g" . magit-status)
  ("C-x M-g" . magit-dispatch-popup)))

;; Helm is a crazy search interface that replaces ido: http://tuhdo.github.io/helm-intro.html
;; An important thing to remember is that helm finds stuff *first*, then decides what to do!
;; For example, find files with C-x C-f, then once selected C-x o to open it in other window.
(use-package helm
  :diminish helm-mode
  :defines helm-find-files-map
  :init
  (setq helm-split-window-in-side-p t)
  (setq helm-autoresize-mode t)
  ;; TODO: Apparently this crashes emacs 24.5 - don't want to mess with emacs from Homebrew yet.
  ;; https://github.com/bbatsov/projectile/issues/600
  ;;  (setq helm-buffers-fuzzy-matching t)
  ;;  (setq helm-M-x-fuzzy-match t)
  ;;  (setq helm-recentf-fuzzy-match t)
  (when (executable-find "curl")
    (setq-default helm-net-prefer-curl t))
  :config
  (require 'helm-config)
  (define-key helm-map (kbd "C-]") 'helm-keyboard-quit)
  (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to run persistent action (open, etc)
  (define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB works in terminal
  (define-key helm-map (kbd "C-z") 'helm-select-action) ; list alternate actions using C-z
  (require 'helm-files)
  (define-key helm-find-files-map (kbd "C-<backspace>") 'backward-kill-word) ; Override C-backspace to not toggle whatever
  ;; Allow digging into directories with <return>
  (defun helm-find-files-into-directories ()
    (interactive)
    (if (file-directory-p (helm-get-selection))
        (helm-execute-persistent-action)
      (helm-maybe-exit-minibuffer)))
  (define-key helm-find-files-map (kbd "<return>") 'helm-find-files-into-directories)
  (helm-mode 1)
  :bind
  (("M-x" . helm-M-x) ; Searchable functions
   ("M-y" . helm-show-kill-ring) ; Search and browse kill ring
   ("C-x C-f" . helm-find-files)
   ("C-x b" . helm-mini) ; helm buffer switch
   ("M-i" . helm-semantic-or-imenu) ; bounce to function/method defs
   ("S-F" . helm-occur) ; Find occurences in buffer (cmd-shift-F)
   ;; C-x c a: helm-apropos
   )
)

;; Project awareness
;; http://tuhdo.github.io/helm-projectile.html
;; Get into it with C-c p p and C-c p h
(use-package projectile
  :init
  (setq projectile-mode-line '(:eval (format " [%s]" (projectile-project-name))))
  :config
  (use-package helm-projectile)
  (projectile-mode)
  (setq projectile-completion-system 'helm)
  (helm-projectile-on)
  (setq projectile-switch-project-action 'helm-projectile)
  ;; Use ripgrep instead of ag instead of ack
  (setq helm-grep-ag-command "/usr/local/bin/rg --smart-case --no-heading --line-number %s %s %s")
  :bind
  ;; Bind some "override" or shift-modified versions of familiar
  ;; commands to project-oriented versions
  (("C-x C-b" . helm-projectile)
   ("C-x F" . helm-projectile-find-file-dwim)
   ;; C-c p b: switch buffers
   ;; C-c p a: find other file
   ;; C-c p k: kill open buffers for project
  ))

;; Really we'll use ripgrep which is a faster ag which is a faster ack
(use-package helm-ag
  :defer t
  :init
  (setq helm-ag-base-command "/usr/local/bin/rg --smart-case --vimgrep --no-heading")
  :bind
  (("C-x a" . helm-do-ag-project-root)
   ("C-x C-a" . helm-do-ag)
   ))


;; Show syntax errors and warnings inline, on the fly. Add
;; backends to support more languages
(use-package flycheck
  :config
  (define-key flycheck-mode-map [remap next-error] 'flycheck-next-error)
  (define-key flycheck-mode-map [remap previous-error] 'flycheck-previous-error)
  ;; I don't like these checkers, they're noisy
  (setq-default flycheck-disabled-checkers
                '(emacs-lisp-checkdoc
                  ruby-rubocop
                  javascript-jscs
                  javascript-jshint))
  (setq flycheck-global-modes '(not text-mode))
  (global-flycheck-mode))
;; TODO: hotkey for show all errors in other window (C-c ! l right now)

;; Popup autocompletion as you type, a la Eclipse
(use-package company
  :demand t
  :diminish company-mode
  :init
  ;; Disable company in some places where it might be annoying
  (setq company-global-modes '(not text-mode git-commit-mode))
  :config
  ;; Add popup documentation for completions
  (use-package company-quickhelp
    :config
    (company-quickhelp-mode 1))
  (global-company-mode)
  ;; Fuzzy matching and frecency sorting for company autocompletion
  (use-package company-flx
    :config
    (company-flx-mode +1))
  :bind
  ("M-<tab>" . company-complete)
  ;; C-w in the menu to see source code!
  ;; C-g to dismiss popup
  )

;; Use M-<arrows> to navigate among windows
(use-package windmove
  :config
  (windmove-default-keybindings 'meta))

;; Move buffers around with M-Shift-<arrows>
(use-package buffer-move
  :bind
  (("<M-S-up>" . buf-move-up)
   ("<M-S-down>" . buf-move-down)
   ("<M-S-left>" . buf-move-left)
   ("<M-S-right>" . buf-move-right)))

;; Increase/decrease font size for all of emacs using C-x C-+/-
(use-package zoom-frm
  :bind
  (("C-x C-=" . zoom-frm-in)
   ("C-x C--" . zoom-frm-out)
   ("C-x C-0" . zoom-frm-unzoom)))

;; super-up/down to semantically expand/contract selection
(use-package expand-region
  :bind
  (("<s-up>" . er/expand-region)
   ("<s-down>" . er/contract-region)))

;; Turn annoying windows like *help* into popup windows that can be
;; closed with q or C-g!
(use-package popwin
  :config
  ;; Hey, I like full side-by-side compile buffers, so leave 'em alone
  (delete '(compilation-mode :noselect t) popwin:special-display-config)
  (popwin-mode 1))

;; Simple REST client / HTTP explorer
;; https://github.com/pashky/restclient.el
(use-package restclient :defer t)

;; Quickly look stuff up in Dash (only on OSX)
;; https://kapeli.com/dash
(use-package dash-at-point
  :if is-mac
  :bind
  (("C-c d" . dash-at-point)
   ("C-c e" . dash-at-point-with-docset)))

;; A help menu available for some packages - press ? in dired
(use-package discover
  :config
  (global-discover-mode 1))

;; Show keybindings for major and minor modes
(use-package discover-my-major
  :bind
  (("C-h C-m" . discover-my-major)
   ("C-h M-m" . discover-my-mode)))

;; Popup help after prefixes, like an automatic discover.el
;; https://github.com/kai2nenobu/guide-key
(use-package guide-key
  :diminish guide-key-mode
  :config
  (setq guide-key/popup-window-position 'bottom)
  (setq guide-key/idle-delay 0.5)
  ;; Help out with projectile and helm and smerge
  (setq guide-key/guide-key-sequence '("C-c p" "C-x c" "C-c ^" "C-c @"))
  (guide-key-mode 1))

;; Quickly jump to next/previous occurrences of the symbol under the
;; cursor using M-n and M-p.
(use-package smartscan
  :config
  (global-smartscan-mode 1))

;; Turn on inline help in the minibuffer for all programming modes
(use-package eldoc
  :commands eldoc-mode
  :diminish eldoc-mode
  :init
  (add-hook 'prog-mode-hook 'eldoc-mode))

;; Enable semantic parsing where applicable
;; https://www.gnu.org/software/emacs/manual/html_node/semantic/Semantic-mode.html#Semantic-mode
;; (use-package semantic
;;   :commands semantic-mode
;;   :init
;;   TODO: set this up with proper minor modes
;;   (add-hook 'prog-mode-hook 'semantic-mode))

;; Highlight and auto-clean bad whitespace
(use-package whitespace
  :diminish (global-whitespace-mode whitespace-mode)
  :init
  ;; THIS MACHINE KILLS TRAILING WHITESPACE
  ;; automatically clean up bad whitespace
  (setq whitespace-action '(auto-cleanup))
  ;; only show bad whitespace
  (setq whitespace-style '(face trailing space-before-tab indentation space-after-tab))
  :config
  (global-whitespace-mode))

(use-package ediff
  :defer t
  :config
  (setq ediff-split-window-function 'split-window-horizontally)
  (setq ediff-window-setup-function 'ediff-setup-windows-plain))

;; In programming modes, auto-fill comments, but nothing else.
(defun comment-auto-fill ()
  "Automatically fill comments, but nothing else"
  ;;(auto-fill-mode 1)
  (setq-local comment-auto-fill-only-comments t)
  (turn-off-auto-fill)
  (setq truncate-lines nil)
  (diminish 'auto-fill-function)) ; Unfortunately auto-fill-mode doesn't follow conventions
(add-hook 'prog-mode-hook 'comment-auto-fill)

;; No tabs, two spaces by default
;; TODO: set this mode-by-mode in use-package
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq-default c-basic-offset 2)

;; Highlight the current column in indentation-sensitive languages
(use-package highlight-indentation
  :commands highlight-indentation-current-column-mode
  :diminish highlight-indentation-current-column-mode
  :init
  (mapc (lambda (hook)
          (add-hook hook 'highlight-indentation-current-column-mode))
        '(coffee-mode-hook
          python-mode-hook
          haml-mode-hook
          web-mode-hook
          sass-mode-hook))
  :config
  ;; Just a bit lighter than the background
  (require 'color)
  (set-face-background 'highlight-indentation-current-column-face
                       (color-lighten-name
                        (face-attribute 'default :background) 2)))

;; Edit strings in a separate buffer with string-edit-at-point,
;; C-c C-c to send them back!
(use-package string-edit :defer t)

;; A tiny scroll handle that appears when needed
(use-package yascroll
  :init
  ;; https://github.com/m2ym/yascroll-el/pull/17
  (defcustom yascroll:enabled-window-systems
    '(nil x w32 ns pc mac)
    "A list of `window-system's where yascroll can work."
    :type '(repeat (choice (const :tag "Termcap" nil)
                           (const :tag "X window" x)
                           (const :tag "MS-Windows" w32)
                           (const :tag "Macintosh Cocoa" ns)
                           (const :tag "Macintosh Emacs Port" mac)
                           (const :tag "MS-DOS" pc)))
    :group 'yascroll)
  :config
  (set-face-background 'yascroll:thumb-fringe "#666")
  (set-face-foreground 'yascroll:thumb-fringe "#666")
  (global-yascroll-bar-mode 1))

(use-package compile
  :init
  ;; Scroll compilation
  (setq compilation-scroll-output t)
  ;; Shut up compile saves
  (setq compilation-ask-about-save nil)
  ;; Don't save *anything*
  (setq compilation-save-buffers-predicate '(lambda () nil))
  :config
  ;; Add NodeJS error format
  (setq compilation-error-regexp-alist-alist
        ;; Tip: M-x re-builder to test this out
        (cons '(node "^[  ]+at \\(?:[^\(\n]+ \(\\)?\\([a-zA-Z\.0-9_/-]+\\):\\([0-9]+\\):\\([0-9]+\\)\)?$"
                           1 ;; file
                           2 ;; line
                           3 ;; column
                           )
              compilation-error-regexp-alist-alist))
  (setq compilation-error-regexp-alist
        (cons 'node compilation-error-regexp-alist))

  ;; Allow color in compilation buffers
  (require 'ansi-color)
  (defun colorize-compilation-buffer ()
    (read-only-mode 1)
    (ansi-color-apply-on-region compilation-filter-start (point))
    (read-only-mode -1))
  (add-hook 'compilation-filter-hook 'colorize-compilation-buffer)
  :bind
  (("C-c C-c" . compile)
   ("C-c C-r" . recompile)))

;; C-c r to rotate among lists of text tokens
(use-package rotate-text
  :load-path "lisp/"
  :ensure nil
  :init
  (setq rotate-text-rotations
        '(("true" "false")
          ("yes" "no")
          ("YES" "NO")
          ("on" "off")
          ("ON" "OFF")
          ("nil" "t")
          ("none" "block")
          ("height" "width")))
  :bind
  ;; "toggle"
  (("C-c t" . rotate-word-at-point)))

;; Toggle case (snake, camel, etc)
(use-package string-inflection
  :bind
  (("C-c i" . string-inflection-cycle)
   ("C-c C" . string-inflection-lower-camelcase)
   ("C-c U" . string-inflection-underscore)))

;; Turn on subword-mode for all programming modes. This lets you
;; navigate between words in CamelCase, etc.
(use-package subword
  :diminish subword-mode
  :config
  (add-hook 'prog-mode-hook
            (lambda ()
              (subword-mode 1))))


;; GNU Global Tags - search for code
;; M-. to find tag
;;    brew install global --with-ctags --with-pygments
(use-package ggtags
  :defer t
  :bind
  ;; Cmd-O like in IntelliJ
  ("s-o" . ggtags-find-tag-dwim))
  ;; :init
  ;; (add-hook 'c-mode-common-hook
  ;;           (lambda ()
  ;;             (when (derived-mode-p 'c-mode 'c++-mode 'java-mode)
  ;;               (ggtags-mode 1))))

;; Google-this command
;; https://github.com/Malabarba/emacs-google-this
(use-package google-this
  :diminish google-this-mode
  :init
  (google-this-mode 1))

;; TODO: re-run last command http://stackoverflow.com/questions/275842/is-there-a-repeat-last-command-in-emacs

;; Highlight symbol under point (and provide ways of replacing or navigating them.
;; TODO: https://github.com/nschum/highlight-symbol.el
;; TODO: better version of this that uses semantic info?
(use-package highlight-symbol
  :diminish highlight-symbol-mode
  :init
  (setq highlight-symbol-idle-delay .25)
  (setq highlight-symbol-highlight-single-occurrence nil)
  :config
  (add-hook 'prog-mode-hook
            (lambda ()
              (highlight-symbol-mode)
              (set-face-attribute 'highlight-symbol-face nil :background "gray20")
              ))
  :bind
  (("s-R" . highlight-symbol-query-replace)))


;; ################## Specific programming language modes #################


(use-package crontab-mode
  :mode ("\\.cron\\(tab\\)?\\'" "cron\\(tab\\)?\\."))
(use-package php-mode :defer t)
(use-package yaml-mode :defer t)
(use-package csharp-mode :defer t)
(use-package markdown-mode :defer t)
(use-package apache-mode :defer t)


;; ###### Web, templating #######

;; http://web-mode.org/
(use-package web-mode
  :init
  (setq-default web-mode-markup-indent-offset 2)
  (setq-default web-mode-css-indent-offset 2)
  (setq-default web-mode-code-indent-offset 2)
  (setq-default web-mode-enable-current-element-highlight t)
  :config
  ;; fci-mode appears to mess up web-mode indentation
  (add-hook 'web-mode-hook
            (lambda ()
              (turn-off-fci-mode)))
  :mode
  ("\\.erb\\'"
   "\\.html?\\'"))

;; Haml is a better HTML
(use-package haml-mode :defer t)


;; ###### Ruby #######

;; TODO: https://github.com/flycheck/flycheck/issues/288
;; TODO: rvm mode?
;; TODO: https://github.com/purcell/emacs.d/blob/master/lisp/init-ruby-mode.el

;; Enhanced ruby-mode uses Ripper to parse Ruby instead of regexps
(use-package enh-ruby-mode
  :init
  (setq enh-ruby-bounce-deep-indent t)
  (setq enh-ruby-hanging-brace-indent-level 2)
  (setq enh-ruby-use-ruby-mode-show-parens-config t)
  :config
  ;; Run all ruby-mode-hooks when using enh-ruby-mode
  (add-hook 'enh-ruby-mode-hook
            (lambda ()
              ;; Unless enh-ruby-mode has decided to inherit from ruby-mode
              (unless (derived-mode-p 'ruby-mode)
                (run-hooks 'ruby-mode-hook))
              ;; Let flycheck handle error highlighting with squiggle underlines
              (custom-set-faces
               '(erm-syn-warnline ((t (:underline (:style wave :color "orange")))))
               '(erm-syn-errline ((t (:underline (:style wave :color "red")))))
               '(enh-ruby-op-face ((t (:foreground nil :inherit 'default))))
              )
            ))
  :mode
  ("\\.\\(?:cap\\|gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'"
   "\\(?:Brewfile\\|Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'")
  :interpreter "ruby")

;; Inferior ruby console - lets you load a Ruby session and send stuff to it
;; M-x inf-ruby-console-auto, then C-c C-r to send region to the console
(use-package inf-ruby
  :init
  (add-hook 'ruby-mode-hook 'inf-ruby-minor-mode)
  :commands inf-ruby-minor-mode
  :bind
  (("C-c C-s" . inf-ruby-console-auto)))

;; Autocompletion and doc lookup in ruby: https://github.com/dgutov/robe
;; Requires "pry" to be in your Gemfile, and M-x robe-start or another
;; robe command to be run.
(use-package robe
  :init
  (add-hook 'ruby-mode-hook 'robe-mode)
  (with-eval-after-load 'company
    (push 'company-robe company-backends))
  :diminish robe-mode
  :commands (robe-mode company-robe)
  ;;  - M-. to jump to the definition
  ;;  - M-, to jump back
  ;;  - C-c C-d to see the documentation
  ;;  - C-c C-k to refresh Rails environment
  ;;  - C-M-i to complete the symbol at point
)

;; Projectile integration for Rails project.
;; TODO: this conflicts with the inf-ruby shortcuts though
(use-package projectile-rails
  :init
  (add-hook 'projectile-mode-hook 'projectile-rails-on)
  :commands projectile-rails-on)

;; Provide a command for switching between old and new hash syntax.
(use-package ruby-hash-syntax
  :commands ruby-toggle-hash-syntax)

;; Support YARD documentation syntax
(use-package yard-mode
  :commands yard-mode
  :diminish yard-mode
  :init
  (add-hook 'ruby-mode-hook 'yard-mode))

;; Edit Cucumber features
(use-package feature-mode
  :init
  (add-hook 'feature-mode-hook
            (lambda ()
              (guide-key/add-local-guide-key-sequence "C-c ,")))
  :commands feature-mode)
;; Keybinding	Description
;; TODO: contribute a discover menu for this?
;; C-c ,v	Verify all scenarios in the current buffer file.
;; C-c ,s	Verify the scenario under the point in the current buffer.
;; C-c ,f	Verify all features in project. (Available in feature and ruby files)
;; C-c ,r	Repeat the last verification process.
;; C-c ,g	Go to step-definition under point (requires ruby_parser gem >= 2.0.5)


;; ###### Java #######

;; Java in emacs is never great. I'll probably stick to IntelliJ/Eclipse.

;; TODO: https://github.com/senny/emacs-eclim
;; TODO: https://github.com/m0smith/malabar-mode
;; TODO: https://github.com/skeeto/ant-project-mode
;; TODO: https://github.com/skeeto/javadoc-lookup
;; TODO: javap mode

(use-package groovy-mode :defer t)
(use-package gradle-mode :defer t)


;; ###### JavaScript #######

;; TODO: https://github.com/purcell/emacs.d/blob/master/lisp/init-javascript.el
;; TODO: I'd expect company to work here with dabbrev

;; A better JavaScript mode, with JSX support
(use-package js2-mode
  :init
  (setq js2-skip-preprocessor-directives t) ; Allow shebangs!
  (setq js-indent-level 2)
  (setq js2-basic-offset 2)
  (add-hook 'js2-mode-hook (lambda () (setq mode-name "JS2")))
  :config
  :mode (("\\.js$" . js2-mode)
   ("\\.jsx$" . js2-jsx-mode))
  :interpreter ("node" . js2-mode))
;; TODO: non-conflicting jump to definition key

;; Tern provides JS autocomplete, function args and other tooling
;; http://ternjs.net/
;; Must be installed: npm install -g tern
(use-package tern
  :commands tern-mode
  :diminish tern-mode
  :init
  (add-hook 'js2-mode-hook 'tern-mode)
  )
;; Tern bindings:
;; M-. : go to definition
;; C-c C-r : rename symbol

;; Use tern for autocomplete
(use-package company-tern
  :commands company-tern
  :init
  (setq company-tern-property-marker " .")
  (add-to-list 'company-backends 'company-tern))

;; Run NodeJS in an inferior process window
(use-package nodejs-repl :defer t)

;; TODO: normalize compile and REPL commands across langs
;; use remap rather than synchronizing everything

;; Coffeescript is a friendlier JavaScript
(use-package coffee-mode
  :defer t
  :config
  (define-key coffee-mode-map (kbd "C-c r") 'coffee-compile-region))


;; ###### CSS #######

;; Sass is a better CSS
(use-package sass-mode :defer t)
(use-package scss-mode :defer t)

;; Eldoc (inline documentation) support for CSS
(use-package css-eldoc
  :commands turn-on-css-eldoc
  :init
  (add-hook 'css-mode-hook 'turn-on-css-eldoc))

;; Colorize color names and #ABCs with their actual colors.
(use-package rainbow-mode
  :commands rainbow-turn-on
  :init
  (mapc (lambda (hook)
          (add-hook hook 'rainbow-turn-on))
        '(css-mode-hook
          sass-mode-hook
          scss-mode-hook
          emacs-lisp-mode-hook)))


;; ###### Python #######

;; Python stuff, from Prelude
;; TODO: try Elpy as well (or parts of it), especially importmagic
;; TODO: anaconda-mode doesn't work without invoking run-python?
;; TODO: mess with this stuff once I learn how people like to set up python
;; TODO: have to point all this stuff to the Homebrew version of python? need virtualenv?
;; TODO: python inferior mode should be cool!
(use-package python-mode
  :disabled t
  :commands python-mode
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode)
  :config
  (use-package anaconda-mode
    :config
    (use-package company-anaconda
      :after company
      :config
      (add-to-list 'company-backends 'company-anaconda)))
  (add-hook 'python-mode-hook
            (lambda ()
              (subword-mode +1)
              (anaconda-mode 1))))


;; ###### C/C++ #######

;; TODO: cc-mode
;; TODO: http://www.emacswiki.org/emacs/CcMode
;; TODO: http://tuhdo.github.io/c-ide.html
;; TODO: https://github.com/abo-abo/function-args
;; TODO: https://github.com/ahyatt/code-imports
;; TODO: https://github.com/syohex/emacs-cpp-auto-include

(defvar c-default-style '((c++-mode . "bsd")
  (c-mode . "bsd")
  (java-mode . "java")
  (other . "gnu")))


;; ###### Obj-C #######

;; TODO: compile command via xcodebuild

(add-hook 'objc-mode-hook
          (lambda ()
            (setq c-basic-offset 4)))


;; ###### Rust #######

;; TODO: https://github.com/racer-rust/emacs-racer
;; TODO: http://julienblanchard.com/2016/fancy-rust-development-with-emacs/
(use-package rust-mode :defer t)

(use-package cargo
  :commands cargo-minor-mode
  :init
  (add-hook 'rust-mode-hook 'cargo-minor-mode))

(use-package flycheck-rust
  :commands flycheck-rust-setup
  :init
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

(use-package racer
  :commands racer-mode
  :diminish racer-mode
  :init
  (setq racer-rust-src-path "<path-to-rust-srcdir>/src/")
  (add-hook 'rust-mode-hook #'racer-mode)
  (add-hook 'racer-mode-hook #'eldoc-mode))


;; ###### Perl #######

;; I hope I don't have to write Perl anymore...
(use-package cperl-mode
  :init
  (defalias 'perl-mode 'cperl-mode)
  (setq cperl-continued-statement-offset 4)
  (setq cperl-indent-level 4)
  (setq cperl-tab-always-indent t)
  (setq cperl-indent-parens-as-block t)
  (setq cperl-close-paren-offset (- cperl-indent-level))
  (setq cperl-mode-hook
  '(lambda ()
     (margin-mode 1)
     (setq tab-width 4)))
  :mode ("\\.cgi$" . cperl-mode))


;; ###### Protobuf #######

(use-package protobuf-mode
  :defer t
  :config
  (add-hook 'protobuf-mode-hook
            (lambda ()
              ;; Protobuf isn't a programming mode
              (highlight-todos)
              (fci-mode)
              (eldoc-mode)
              (subword-mode +1))))


;; ###### Shell Scripting #######

;; Open zsh files in sh-mode
(add-to-list 'auto-mode-alist '("\\.zsh\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.zshrc\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("zshrc'" . sh-mode))



;; ################## Other Preferences! #################

;; Stop Emacs from losing undo information by
;; setting very high limits for undo buffers
(setq undo-limit 20000000)
(setq undo-strong-limit 40000000)

;; Where and what to auto-save. Save them all somewhere else instead of in-place
(defconst auto-save-directory "~/.emacs.d/auto-save-list/")
(setq backup-directory-alist `((".*" . ,auto-save-directory))); prefix for backup files
(setq auto-save-list-file-prefix "~/.emacs.d/auto-save-list/.saves-"); set prefix for auto-saves
(setq auto-save-file-name-transforms `((".*" ,auto-save-directory t))); location for all auto-save files
(setq tramp-auto-save-directory auto-save-directory); auto-save tramp files in local directory

;; Use the system clipboard for selections.
(setq x-select-enable-clipboard t)

;; Default font
(add-to-list 'default-frame-alist '(font .  "Hack-13" ))
(set-face-attribute 'default t :font "Hack-13" )
(set-face-attribute 'default t :height 100 )

;; Save open buffers between sessions
(desktop-save-mode 1)

;; Reload files that have changed on disk
(global-auto-revert-mode t)
(diminish 'auto-revert-mode)

;; I generally hate auto-fill-mode in text
(remove-hook 'text-mode-hook #'turn-on-auto-fill)

;; Slim down the fringe
(set-fringe-mode '(1 . 1))

;; No scroll bars
(scroll-bar-mode -1)

;; Never show the splash screen
(setq inhibit-startup-message t)
(tool-bar-mode 0)

;; Make sure to show line and column numbers
(line-number-mode 1)
(column-number-mode 1)

;; Make useful frame titles
(setq frame-title-format "%b <emacs>")

(setq user-full-name "Ben Hollis")
(setq user-mail-address "ben@benhollis.net")

;; Never minimize
(when (display-graphic-p)
  (put 'suspend-frame 'disabled t))

;; Highlight current line
(global-hl-line-mode 1)
(set-face-background 'hl-line "gray13")

;; Highlight searched text
(setq search-highlight t)

;; wrap the line in the display if it is wider than the window.
;; It's still one 'line' in the file.
(setq truncate-partial-width-windows nil)
(setq-default truncate-lines nil)
(toggle-truncate-lines -1)

;;  mode line format
(setq-default mode-line-modified '("%*%* "))
(setq-default mode-line-buffer-identification '("%b"))

;; Don't tell me about mail (you can't read GMail anyway)
(setq-default display-time-mail-file -1)
;; Don't tell me about system load, either. I have lots of cores.
(setq-default display-time-default-load-average nil)
;; Show the time in the mode line.
(display-time-mode)
;; Show battery level in the mode line.
(display-battery-mode)

;; Show matching parens/braces
(show-paren-mode 1)

;; TODO: Mac options. Copy/paste still doesn't work quite right either.
(setq mac-command-modifier 'super)
(setq mac-option-modifier 'meta)
;;(setq mac-command-key-is-meta t) ; yikes, not sure if I can deal with this

;; Turn on or off a "visible" bell
(setq visible-bell nil)

(setq select-enable-clipboard t)

;; replace "yes" and "no" with "y" and "n"
(fset 'yes-or-no-p 'y-or-n-p)

;; Typing over a region replaces the region, like in normal text
;; fields. This is required to work with js2-refactor.
(delete-selection-mode)

;; Uniquify buffer names by adding parent directories
(toggle-uniquify-buffer-names)

;; Bright-red TODOs (from Casey)
(make-face 'font-lock-fixme-face)
(make-face 'font-lock-note-face)
(defun highlight-todos ()
  "Highlight TODOs and other note tags."
  (interactive)
  (font-lock-add-keywords nil
   '(("\\<\\(TODO\\)" 1 'font-lock-fixme-face t)
     ("\\<\\(NOTE\\)" 1 'font-lock-note-face t)
     ("\\<\\(HACK\\)" 1 'font-lock-note-face t))))
(modify-face 'font-lock-fixme-face "Red" nil nil t nil t nil nil)
(modify-face 'font-lock-note-face "Light Green" nil nil t nil t nil nil)
(add-hook 'prog-mode-hook 'highlight-todos)

;; I got this from Casey - it prevents Emacs from ever sub-splitting a
;; window, preserving my side-by-side windows no matter what. I could
;; also consider winner-mode which lets you save and restore layouts.
(defun never-split-a-window nil)
(setq split-window-preferred-function 'never-split-a-window)



;; ############### Global Key bindings ####################

;; Use describe-keybindings and describe-personal-keybindings
;; TODO: build my own keyboard shortcuts sheet

;; Defaults (I've overridden these, but I should consider going back
;; to them or adding them to the arrow keys (vs my window-movement
;; stuff?)

;; C-f forward-char
;; M-f forward-word
;; C-M-f forward-sentence/expression

;; C-b backward-char
;; M-b backward-word
;; C-M-b backward-sentence/expression

;; C-x for global, C-c for mode-specific
;; http://ergoemacs.org/emacs/emacs_keybinding_overview.html

;; F10 is the menu in console mode

;; M-^ : Join lines upward
;; TODO: join-lines below shortcut

;; TODO: some way of remembering cursor history so I can go back to point I just left

;; TODO: open .cpp/.h in other frame
;; TODO: other casey commands
;; TODO: next/prev TODO

;; M-; is comment-dwim, which comments or uncomments code
;; C-g is "quit", like C-]

;; always indent to the right column when inserting newlines
(global-set-key "\C-m" 'newline-and-indent) ; C-m == RET

;; windowing and display functions
(global-set-key "\C-z" (quote undo))
(global-set-key "\C-x\C-z" (quote undo))
;(global-set-key (kbd "<mouse-2>") 'x-clipboard-yank) ; Middle mouse pastes from the clipboard

;; and general navigation/editing keys.
(global-set-key [end] 'end-of-line)
(global-set-key [home] 'beginning-of-line)

;; Kill words forward
(global-set-key [M-delete] 'kill-word)

;; Navigate by word
(global-set-key [C-right] 'forward-word)
(global-set-key [C-left] 'backward-word)
(global-set-key [C-up] 'previous-blank-line)
(global-set-key [C-down] 'next-blank-line)

;; Indent a whole region
;; TODO: indent-sexp/defun when no region
(global-set-key (kbd "<C-tab>") 'indent-region)

;; TODO: learn C-M (move):
;; C-M-f is forward-sexp
;; C-M-b is backward-sexp
;; C-M-k is kill-sexp
;; C-M-@ is mark-sexp
;; C-M-a is beginning-of-defun
;; C-M-e is end-of-defun

;; TODO: learn M-% (query replace)
;; TODO: memorize C-w for kill-region, M-w for copy region

(global-set-key "\C-c\C-g" 'goto-line) ; not sure why I like this
(global-set-key "\C-x\C-i" 'indent-whole-buffer)
(global-set-key "\C-x\C-v" 'reopen-current-file-from-disk)
(global-set-key "\C-xo" 'other-window-all-frames)
(global-set-key "\M-s" 'send-invisible)
(global-set-key (kbd "s-/") 'dabbrev-expand) ; redundant with M-/, but I fat-finger them

;; Macro-recording
(global-set-key "\e[" 'start-kbd-macro)
(global-set-key "\e]" 'end-kbd-macro)
(global-set-key "\e'" 'call-last-kbd-macro)

;; Remove keybindings
(global-unset-key "\C-t") ;; usually transpose-characters, I fat-finger it too often with C-y
(global-unset-key "\C-l") ;; usually recenter-top-bottom, which I hate
(global-unset-key (kbd "C-/")) ;; usually undo, but I fat-finger with M-/ and I use C-z for undo
(global-unset-key (kbd "s-n")) ;; Cmd-N for new frame, do not want
(global-unset-key (kbd "s-o")) ;; Mac open file
(global-unset-key (kbd "s-p")) ;; Mac print
(global-unset-key (kbd "s-q")) ;; Quit
(global-unset-key (kbd "s-t")) ;; Fonts?

;; Typical Mac bindings
(when is-mac
  (global-set-key [(super a)] 'mark-whole-buffer)
  (global-set-key [(super v)] 'yank)
  (global-set-key [(super c)] 'kill-ring-save)
  (global-set-key [(super s)] 'save-buffer)
  (global-set-key [(super l)] 'goto-line)
  (global-set-key [(super z)] 'undo))

;; other stuff...
(global-set-key "\C-c\C-s" 'new-shell)

;; Compilation mode stuff.
(global-set-key (kbd "C-q") 'next-error)
(global-set-key (kbd "C-S-q") 'previous-error)

;; TODO: the keypad insert key is <help> (like F1)! Nice!

(global-set-key "\C-v" 'yank)

;; Esc-t to load TODO, Esc-l to load journal
(global-set-key (kbd "<escape> t") 'load-todo)
(global-set-key (kbd "<escape> l") 'load-log)



;; ################## Functions #############

;; Neat functions stolen from Casey!

(defvar bhollis-todo-file "/Users/brh/Dropbox/Notes/todo.txt")
(defun load-todo ()
  "Load the TODO file."
  (interactive)
  (find-file bhollis-todo-file))

(defvar bhollis-log-file "/Users/brh/Dropbox/Notes/log.txt")
(defun insert-timeofday ()
  "Insert the time of day at the current point, with a separator."
   (interactive "*")
   (insert (format-time-string "---------------- %a, %d %b %y: %I:%M%p")))
(defun load-log ()
  "Load the log file and add a new entry."
  (interactive)
  (find-file bhollis-log-file)
  (goto-char (point-max))
  (newline-and-indent)
  (insert-timeofday)
  (newline-and-indent)
  (newline-and-indent)
  (goto-char (point-max)))

; Navigation
(defun previous-blank-line ()
  "Moves to the previous line containing nothing but whitespace."
  (interactive)
  (search-backward-regexp "^[ \t]*\n"))

(defun next-blank-line ()
  "Moves to the next line containing nothing but whitespace."
  (interactive)
  (forward-line)
  (search-forward-regexp "^[ \t]*\n")
  (forward-line -1))

(defun new-shell ()
  "Create a new shell buffer with a unique name."
  (interactive)
  (shell)
  (rename-uniquely))

(defun indent-whole-buffer ()
  "Reindent the entire buffer"
  (interactive)
  (indent-region (point-min) (point-max) nil))

(defun reopen-current-file-from-disk ()
  "Reopen the file from disk without confirming."
  (interactive)
  (revert-buffer 1 1 1))

(defun kill-buffers-matching (regexp)
  "Kill all buffers matching a regex."
  (interactive "Kill buffers matching: ")
  (dolist (i (buffer-list))
    (when (string-match regexp (buffer-name i))
      (kill-buffer i))))

(defun other-window-all-frames (arg)
  "Select the other window, even if it is in another frame."
  (interactive "p")
  (other-window arg t)
  (select-frame-set-input-focus (window-frame (selected-window))))

(global-set-key (kbd "C-c m") 'fc-calculate-region)
(defun fc-calculate-region (start end &optional prefix)
  "Evaluate the mathematical expression within the region, and
replace it with its result.

With a prefix arg, do not replace the region, but instead put the
result into the kill ring."
  (interactive "r\nP")
  (let* ((expr (buffer-substring start end))
         (result (fc-bc-calculate-expression expr))
         (ends-with-newline (string-match "\n$" expr)))
    (if prefix
        (progn
          (kill-new result)
          (message "%s" result))
      (delete-region start end)
      (insert result)
      (when ends-with-newline
        (insert "\n")))))

(defun fc-bc-calculate-expression (expr)
  "Evaluate `expr' as a mathematical expression, and return its result.

This actually pipes `expr' through bc(1), replacing newlines with
spaces first. If bc(1) encounters an error, an error is
signalled."
  (with-temp-buffer
    (insert expr)
    (goto-char (point-min))
    (while (search-forward "\n" nil t)
      (replace-match " " nil t))
    (goto-char (point-max))
    (insert "\n")
    (call-process-region (point-min)
                          (point-max)
                         "bc" t t nil "-lq")
    (goto-char (point-min))
    (when (search-forward "error" nil t)
      (error "Bad expression"))
    (while (search-forward "\n" nil t)
      (replace-match "" nil t))
    (buffer-string)))

;; http://emacsredux.com/blog/2013/05/22/smarter-navigation-to-the-beginning-of-a-line/
(defun smarter-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.

Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.

If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

;; remap C-a to `smarter-move-beginning-of-line'
(global-set-key [remap move-beginning-of-line]
                'smarter-move-beginning-of-line)

;; ################## Org Mode ###########################

;; Org mode is a whole other thing

;; TODO: http://stackoverflow.com/questions/21195327/emacs-force-org-mode-capture-buffer-to-open-in-a-new-window
;; TODO: Move vars around
;; TODO: http://cestdiego.github.io/blog/2015/08/19/org-protocol/
;; TODO: http://orgmode.org/manual/Capture-templates.html
;; TODO: bind helm-org-in-buffer-headings (M-i?)
(use-package org
  :defer t
  :config
  (setq org-default-notes-file bhollis-todo-file)
  (setq org-refile-targets '((nil :maxlevel . 2)
                             ;; all top-level headlines in the
                             ;; current buffer are used (first) as a
                             ;; refile target
                             (org-agenda-files :maxlevel . 2)))
  ;(setq org-refile-use-outline-path 'file)
  :bind
  ;; Esc-PrintScrn
  ("<escape> <f13>" . org-capture))



;; ######## Customize variables #########

;; TODO: Move these out into here
(setq custom-file "~/.emacs.d/lisp/my_emacs_customizations.el")
(load custom-file 'noerror)



;; ######## Color Theme options #########

(use-package color-theme-sanityinc-tomorrow
  :config
  (load-theme 'sanityinc-tomorrow-night t)
  ;; I need the selection to stand out more
  (set-face-attribute 'region nil :background "#6281d0"))

;; Finally, load a local file to override anything done above on a per-host basis.
;; TODO: figure out short hostname here
(if (file-exists-p "~/.emacs.local")
  (load-file "~/.emacs.local")
)

;; Remember 'bs-mode'
(split-window-horizontally)

;; Allow access from emacsclient (but only start server in windowed mode)
(if (display-graphic-p)
    (progn
      (require 'server)
      (unless (server-running-p)
        (server-start))))
