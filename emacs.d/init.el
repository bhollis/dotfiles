;; Everything's in one file to make it easier to find.
;; Remember that you can always add a .dir-locals.el file to any directory to override vars for a project.
;; TODO: slim this down for console!


;; ###### Platform detection #######

;; Are we on a mac (windowed)?
(defconst is-mac (memq window-system '(mac ns)))



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



;; ######## Configure general packages #######

;; Use-package:
;; :init runs before require, :config runs after (lazy) loading.
;; :bind, :defer, :commands, :mode, :interpreter all cause lazy loading.

;; Get PATH from shell on OSX, for when we launched from the dock
(when is-mac
  (use-package exec-path-from-shell
    :config
    (add-to-list 'exec-path-from-shell-variables "GEM_PATH")
    (add-to-list 'exec-path-from-shell-variables "GEM_HOME")
    (add-to-list 'exec-path-from-shell-variables "PYTHONPATH")
    (exec-path-from-shell-initialize)))

;; package.el will automatically create and require autoloads files
;; for packages. Many of these have package autoloads that
;; sufficiently configure them. State them here so they get
;; auto-installed (and to make future configuration easier). We could
;; restate the autoloads here, but why bother?

;; TODO: sort/organize these by theme

;; Draw a thin line down the side of the buffer at a certain column.
(use-package fill-column-indicator
  :commands fci-mode
  :init
  (setq-default fci-rule-column 79)
  (add-hook 'prog-mode-hook 'fci-mode))

;; Color color names and #ABCs with their actual colors.
(use-package rainbow-mode
  :commands rainbow-turn-on
  :init
  (add-hook 'css-mode-hook 'rainbow-turn-on)
  (add-hook 'sass-mode-hook 'rainbow-turn-on))

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
  (setq magit-completing-read-function 'helm--completing-read-default)
  (setq magit-branch-prefer-remote-upstream '("master" "dev"))
  :config
  (global-magit-file-mode)
  :bind
  (("C-x g" . magit-status)
  ("C-x M-g" . magit-dispatch-popup)))
;; Include pull request info in magit
(use-package magit-gh-pulls
  :commands turn-on-magit-gh-pulls
  :init
  (add-hook 'magit-mode-hook 'turn-on-magit-gh-pulls))

;; Helm is a crazy search interface that replaces ido: http://tuhdo.github.io/helm-intro.html
;; An important thing to remember is that helm finds stuff *first*, then decides what to do!
;; For example, find files with C-x C-f, then once selected C-x o to open it in other window.
(use-package helm
  :defines helm-find-files-map
  :diminish helm-mode
  :init
  (setq helm-split-window-in-side-p t)
  (setq helm-autoresize-mode t)
  ;; TODO: Apparently this crashes emacs 24.5 - don't want to mess with emacs from Homebrew yet.
  ;; https://github.com/bbatsov/projectile/issues/600
;  (setq helm-buffers-fuzzy-matching t)
;  (setq helm-M-x-fuzzy-match t)
;  (setq helm-recentf-fuzzy-match t)
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
  ;; TODO: bind with keymaps: https://github.com/jwiegley/use-package/issues/121
  :bind
  (("M-x" . helm-M-x) ; Searchable functions
   ("M-y" . helm-show-kill-ring) ; Search and browse kill ring
   ("C-x C-f" . helm-find-files)
   ("C-x b" . helm-mini) ; helm buffer switch
   ("M-i" . helm-semantic-or-imenu) ; bounce to function/method defs
   ("C-x c o" . helm-occur) ; Find occurences in buffer
   ;; C-x c a: helm-apropos
   )
)
;; TODO: helm flx? helm persistent history?

;; Project awareness
;; http://tuhdo.github.io/helm-projectile.html
;; Get into it with C-c p p and C-c p h
(use-package projectile
  :init
  (setq projectile-mode-line '(:eval (format " [%s]" (projectile-project-name))))
  :config
  (use-package helm-projectile)
  (projectile-global-mode)
  (setq projectile-completion-system 'helm)
  (helm-projectile-on)
  (setq projectile-switch-project-action 'helm-projectile)
  :bind
  ;; Bind some "override" or shift-modified versions of familiar
  ;; commands to project-oriented versions
  (("C-x C-b" . helm-projectile)
   ("C-x F" . helm-projectile-find-file-dwim)
   ;; C-c p b: switch buffers
   ;; C-c p a: find other file
   ;; C-c p k: kill open buffers for project
   ("C-x a" . helm-projectile-ack)) ; Search project with ack
)

;; Show syntax errors and warnings inline, on the fly. Add
;; backends to support more languages
(use-package flycheck
  :config
  ;; I don't like these checkers, they're noisy
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc ruby-rubocop))
  (setq flycheck-global-modes '(not text-mode))
  (global-flycheck-mode))
;; TODO: hotkey for show all errors in other window (C-c ! l right now)

;; Snippet insertion - type a snippet abbreviation and hit tab to
;; expand, or C-c y to bring up a company-mode list of available
;; snippets. Install snippets from yasnippet-snippets as a submodule,
;; or add your own!
(use-package yasnippet
  :diminish yas-minor-mode
  :init
  (setq yas-snippet-dirs
  '("~/.emacs.d/snippets" ;; Personal snippets
    "~/.emacs.d/yasnippets" ;; https://github.com/AndreaCrotti/yasnippet-snippets
    ))
  :config
  ;; Use C-; for expand instead of tab
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil)
  (define-key yas-minor-mode-map (kbd "C-;") 'yas-expand)
  ;; Can restrict to certain modes with:
  ;; (yas-reload-all)
  ;; (add-hook 'prog-mode-hook #'yas-minor-mode)
  (yas-global-mode 1))

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
  ("C-c y" . company-yasnippet) ; offer completions for yasnippet
  ;; C-w in the menu to see source code!
  ;; C-g to dismiss popup
  )
;; TODO: to prevent completion in comments, you might want to remove company-dabbrev from company-backends altogether

;; Try out hippie-exp in place of completion/dabbrev
;; TODO: might be too much
;(use-package hippie-exp
;  :bind ("M-/" . hippie-expand))

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
(use-package restclient)

;; Quickly look stuff up in Dash (only on OSX)
;; https://kapeli.com/dash
(when is-mac
  (use-package dash-at-point
    :bind
    (("C-c d" . dash-at-point)
     ("C-c e" . dash-at-point-with-docset))))

;; A help menu available for some packages - press ? in dired
(use-package discover
  :config
  (global-discover-mode 1))

;; TODO: Consider discover-my-major as well?

;; Popup help after prefixes, like an automatic discover.el
;; https://github.com/kai2nenobu/guide-key
(use-package guide-key
  :diminish guide-key-mode
  :config
  (setq guide-key/popup-window-position 'bottom)
  (setq guide-key/idle-delay 0.5)
  ;; Help out with projectile and helm
  (setq guide-key/guide-key-sequence '("C-c p" "C-x c"))
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
;; (use-package semantic
;;   :commands semantic-mode
;;   :init
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

;; TODO: Multiple cursors: https://github.com/magnars/multiple-cursors.el

;; In programming modes, auto-fill comments, but nothing else.
(defun comment-auto-fill ()
  "Automatically fill comments, but nothing else"
  (setq-local comment-auto-fill-only-comments t)
  (auto-fill-mode 1)
  (diminish 'auto-fill-function)) ; Unfortunately auto-fill-mode doesn't follow conventions
(add-hook 'prog-mode-hook 'comment-auto-fill)

;; No tabs, two spaces by default
;; TODO: set this mode-by-mode in use-package
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq-default c-basic-offset 2)

;; Highlight the current column in indentation-sensitive languages
(use-package highlight-indentation
  :defer t
  :init
  (mapc (lambda (hook)
          (add-hook hook 'highlight-indentation-current-column-mode))
        '(coffee-mode-hook
          python-mode-hook
          haml-mode-hook
          sass-mode-hook))
  :config
  ;; Just a bit lighter than the background
  (require 'color)
  (set-face-background 'highlight-indentation-current-column-face
                       (color-lighten-name
                        (face-attribute 'default :background) 2)))

;; Edit strings in a separate buffer with string-edit-at-point,
;; C-c C-c to send them back!
(use-package string-edit)

(use-package yascroll
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

;; TODO: look at Casey/work dotfiles to make compile better
;; TODO: re-run last command http://stackoverflow.com/questions/275842/is-there-a-repeat-last-command-in-emacs
;;(global-set-key (kbd "C-c C-c") 'compile)
;;(global-set-key "\C-B" 'recompile)
;;global-set-key "\C-x\C-c" 'switch-to-most-recent-compile-buffer)



;; TODO: https://github.com/nschum/highlight-symbol.el



;; ################## Specific programming language modes #################

;; TODO: dig deeper into specific programming languages when I use them

(use-package crontab-mode)
(use-package php-mode)
(use-package yaml-mode)
(use-package csharp-mode)
(use-package markdown-mode)
;; TODO: clojure?


;; ###### Ruby #######

;; TODO: https://github.com/flycheck/flycheck/issues/288
;; TODO: enhanced ruby mode
;; TODO: rvm mode?
;; TODO: https://github.com/purcell/emacs.d/blob/master/lisp/init-ruby-mode.el

;; Enhanced ruby-mode uses Ripper to parse Ruby instead of regexps
(use-package enh-ruby-mode
  :config
  ;; Run all ruby-mode-hooks when using enh-ruby-mode
  (add-hook 'enh-ruby-mode-hook
            (lambda ()
              ;; Let flycheck handle error highlighting with squiggle underlines
              (set-face-attribute 'erm-syn-errline nil :box nil)
              (set-face-attribute 'erm-syn-warnline nil :box nil)
              ;; Unless enh-ruby-mode has decided to inherit from ruby-mode
              (unless (derived-mode-p 'ruby-mode)
                (run-hooks 'ruby-mode-hook))))
  :mode
  ("\\.\\(?:cap\\|gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'"
   "\\(?:Brewfile\\|Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'")
  :interpreter "ruby")

;; Inferior ruby console - lets you load a Ruby session and send stuff to it
;; M-x inf-ruby-console-auto, then C-c C-r to send region to the console
(use-package inf-ruby
  :init
  (add-hook 'ruby-mode-hook 'inf-ruby-minor-mode)
  :commands inf-ruby-minor-mode)

;; Autocompletion and doc lookup in ruby: https://github.com/dgutov/robe
;; Requires "pry" to be in your Gemfile
(use-package robe
  :init
  (add-hook 'ruby-mode-hook 'robe-mode)
  (eval-after-load 'company
    '(push 'company-robe company-backends))
  :diminish robe-mode
  :commands (robe-mode company-robe))

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
;; TODO: groovy/gradle modes?
;; TODO: javap mode

(use-package groovy-mode)
(use-package gradle-mode)

;; ###### JavaScript #######

;; TODO: https://github.com/purcell/emacs.d/blob/master/lisp/init-javascript.el
;; TODO: I'd expect company to work here with dabbrev

;; A better JavaScript mode, with JSX support
(use-package js2-mode
  :init
  (setq js-indent-level 2)
  (setq js2-basic-offset 2)
  (add-hook 'js2-mode-hook (lambda () (setq mode-name "JS2")))
  :config
  :mode (("\\.js$" . js2-mode)
   ("\\.jsx$" . js2-jsx-mode))
  :interpreter ("node" . js2-mode))

;; JavaScript refactoring. C-c C-r
(use-package js2-refactor
  :disabled t ; TODO: this didn't work very well for me
  :init
  (add-hook 'js2-mode-hook 'js2-refactor-mode)
  :config
  ;; Discover menu support, refactor has a ton of commands
  (use-package discover-js2-refactor
    :disabled t ; This doesn't actually work
    )
  (js2r-add-keybindings-with-prefix "C-c C-r"))

;; Tern provides JS autocomplete, function args and other tooling
;; http://ternjs.net/
;; Must be installed: npm install -g tern
(use-package tern
  :diminish tern-mode
  :init
  (add-hook 'js2-mode-hook 'tern-mode)
  :config
  ;; Let js2-refactor do refactorings
  ;; (define-key tern-mode-keymap (kbd "C-c C-r") nil)
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

;; Run NodeJS in an inferior process window TODO: keybindings for repl common
;; across JS, coffee, etc.
(use-package nodejs-repl)

;; TODO: normalize compile and REPL commands across langs
;; use remap rather than synchronizing everything

;; Coffeescript is a friendlier JavaScript
(use-package coffee-mode
  :config
  ;; TODO: this should be some other binding
  (define-key coffee-mode-map (kbd "C-c r") 'coffee-compile-region))

;; ###### HTML #######

;; Type Haml-like CSS selectors and hit C-j to expand into full HTML tags
;; https://github.com/smihica/emmet-mode
;; html:5 for template?
(use-package emmet-mode
  :commands emmet-mode
  :init
  (add-hook 'sgml-mode-hook 'emmet-mode) ;; Auto-start on any markup modes
  (add-hook 'css-mode-hook  'emmet-mode)) ;; enable Emmet's css abbreviation.
;; TODO: helm-emmet, company-emmet

;; Haml is a better HTML
(use-package haml-mode)


;; ###### CSS #######

;; Sass is a better CSS
(use-package sass-mode)

;; Eldoc (inline documentation) support for CSS
(use-package css-eldoc
  :commands turn-on-css-eldoc
  :init
  (add-hook 'css-mode-hook 'turn-on-css-eldoc))


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
(set-face-background 'hl-line "gray17")

;; Highlight searched text
(setq search-highlight t)

;; wrap the line in the display if it is wider than the window.
;; It's still one 'line' in the file.
(setq truncate-partial-width-windows 50)
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
;;(setq mac-command-modifier 'meta)
;;(setq mac-command-key-is-meta t) ; yikes, not sure if I can deal with this

;; Turn on or off a "visible" bell
(setq visible-bell nil)

(setq x-select-enable-clipboard t)

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



;; ################## Org Mode ###########################

;; Org mode is a whole other thing

;; TODO: http://stackoverflow.com/questions/21195327/emacs-force-org-mode-capture-buffer-to-open-in-a-new-window
;; TODO: Move vars around
;; TODO: http://cestdiego.github.io/blog/2015/08/19/org-protocol/
;; TODO: http://orgmode.org/manual/Capture-templates.html
;; TODO: bind helm-org-in-buffer-headings (M-i?)
(use-package org
  :config
  (setq org-default-notes-file bhollis-todo-file)
  :bind
  ;; Esc-PrintScrn
  ("<escape> <f13>" . org-capture))



;; ######## Customize variables #########

;; TODO: Move these out into here
(setq custom-file "~/.emacs.d/lisp/my_emacs_customizations.el")
(load custom-file 'noerror)



;; ######## Color Theme options #########

;;(use-package ample-theme
;;  :config
;;  (load-theme 'ample)
;;  (load-theme 'ample-flat)
;;)
;;(require 'deep-blue) (load-theme 'deep-blue t)
(use-package color-theme-sanityinc-tomorrow
  :config
  (load-theme 'sanityinc-tomorrow-night t)
  ;; I need the selection to stand out more
  (set-face-attribute 'region nil :background "#6281d0"))
;;(load-theme 'sanityinc-tomorrow-eighties t)
;;(load-theme 'solarized-dark t)
;;(load-theme 'monokai t)
;;(load-theme 'tango-dark t)
;;(load-theme 'deeper-blue t)
;;(load-theme 'misterioso t)
;;(load-theme 'wombat t)


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
