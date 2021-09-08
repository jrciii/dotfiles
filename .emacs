;;; .emacs --- My .emacs file
;;; Commentary:
;;; Code:
(defvar inferior-lisp-program)
(defvar projectile-mode-map)
(defvar epa-pinentry-mode)
(defvar org-babel-shell-command)
(defvar erc-sasl-server-regexp-list)
(defvar org-map-continue-from)
(defvar lsp-completion-provider)
(defvar lsp-prefer-flymake)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(setq inferior-lisp-program "~/nyquist/ny")
(setq gc-cons-threshold 10000000)
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
;; and `package-pinned-packages`. Most users will not need or want to do this.
;;(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

(add-to-list 'exec-path "~/.local/bin")
(add-to-list 'load-path "~/lisp")
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(helm-mode 1)
(projectile-mode +1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
(helm-projectile-on)
(global-set-key "\C-s" 'swiper-helm)
(require 'bookmark+ nil 'noerror)
(require 'ob-scala nil 'noerror)
(require 'ob-shell nil 'noerror)
(require 'ob-python nil 'noerror)
(setq epa-pinentry-mode 'loopback)
(display-time)
(setq org-babel-shell-command "bash")
;(add-hook 'exwm-mode-hook
;          (lambda () (local-set-key (kbd "C-c C-l") 'exwm-input-grab-keyboard)))

;(add-hook 'exwm-mode-hook
;          (lambda () (local-set-key (kbd "C-c C-c") 'exwm-input-release-keyboard)))

(winner-mode 1)
(require 'festival nil 'noerror)
(require 'erc)
(require 'erc-sasl nil 'noerror)
(add-to-list 'erc-sasl-server-regexp-list "irc\\.freenode\\.net")

(ednc-mode)
(declare-function ednc-format-notification "ednc")
(declare-function ednc-notifications "ednc")
(declare-function ednc-notification-app-name "ednc")
(defun list-notifications ()
  "List format for EDNC notifications."
  (mapconcat #'ednc-format-notification (ednc-notifications) ""))

(defun stack-notifications (&optional hide)
  "Stack format for EDNC notifications.  HIDE: List of apps to hide."
  (mapconcat (lambda (notification)
               (let ((app-name (ednc-notification-app-name notification)))
                 (unless (member app-name hide)
                   (push app-name hide)
                   (ednc-format-notification notification))))
             (ednc-notifications) ""))

(nconc global-mode-string '((:eval (list-notifications))))  ; or stack

(add-hook 'ednc-notification-presentation-functions
(lambda (&rest _) (force-mode-line-update t)))

(declare-function org-map-entries "org")
(declare-function org-archive-subtree "org")
(declare-function org-element-property "org")
(declare-function org-element-at-point "org")
(defun org-archive-done-tasks ()
  "Archive done org tasks."
  (interactive)
  (org-map-entries
   (lambda ()
     (org-archive-subtree)
     (setq org-map-continue-from (org-element-property :begin (org-element-at-point))))
   "/DONE" 'tree))

(declare-function erc-sasl-use-sasl-p "erc-sasl")
(defun erc-login ()
  "Perform user authentication at the IRC server.  (PATCHED)."
  (erc-log (format "login: nick: %s, user: %s %s %s :%s"
           (erc-current-nick)
           (user-login-name)
           (or erc-system-name (system-name))
           erc-session-server
           erc-session-user-full-name))
  (if erc-session-password
      (erc-server-send (format "PASS %s" erc-session-password))
    (message "Logging in without password"))
  (when (and (featurep 'erc-sasl) (erc-sasl-use-sasl-p))
    (erc-server-send "CAP REQ :sasl"))
  (erc-server-send (format "NICK %s" (erc-current-nick)))
  (erc-server-send
   (format "USER %s %s %s :%s"
       ;; hacked - S.B.
       (if erc-anonymous-login erc-email-userid (user-login-name))
       "0" "*"
       erc-session-user-full-name))
  (erc-update-mode-line))

(require 'emms-setup)
(emms-all)
(emms-default-players)

(global-set-key (kbd "C-x RET C-d") 'dmenu)

;(require 'exwm)
;(require 'exwm-config)
;(require 'exwm-systemtray)
;(exwm-systemtray-enable)
;(exwm-config-default)

(load-theme 'tsdh-dark)

(defun dup-disp ()
  "Duplicate my display on HDMI."
  (interactive)
  (shell-command "xrandr --output HDMI-0 --auto")
  (shell-command "xrandr --output DVI-I-1 --same-as HDMI-0"))

(defun no-tv ()
  "Stop duplicating display on HDMI."
  (interactive)
  (shell-command "xrandr --output HDMI-0 --off"))

(global-auto-revert-mode t)

(use-package elpy
  :ensure t
  :init
  (elpy-enable))

;; Install use-package if not already installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

;; Enable defer and ensure by default for use-package
;; Keep auto-save/backup files separate from source code:  https://github.com/scalameta/metals/issues/1027
(setq use-package-always-defer t
      use-package-always-ensure t
      backup-directory-alist `((".*" . ,temporary-file-directory))
      auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; Enable scala-mode for highlighting, indentation and motion commands
(use-package scala-mode
  :interpreter
    ("scala" . scala-mode))

;; Enable sbt mode for executing sbt commands
(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
   ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
   (setq sbt:program-options '("-Dsbt.supershell=false"))
)

;; Enable nice rendering of diagnostics like compile errors.
(use-package flycheck
  :init (global-flycheck-mode))

(use-package lsp-mode
  ;; Optional - enable lsp-mode automatically in scala files
  :hook  (scala-mode . lsp)
         (lsp-mode . lsp-lens-mode)
  :config
  ;; Uncomment following section if you would like to tune lsp-mode performance according to
  ;; https://emacs-lsp.github.io/lsp-mode/page/performance/
  ;;       (setq gc-cons-threshold 100000000) ;; 100mb
  ;;       (setq read-process-output-max (* 1024 1024)) ;; 1mb
  ;;       (setq lsp-idle-delay 0.500)
  ;;       (setq lsp-log-io nil)
  ;;       (setq lsp-completion-provider :capf)
  (setq lsp-prefer-flymake nil))

;; Add metals backend for lsp-mode
(use-package lsp-metals
  :config
  (setq lsp-metals-java-home "/usr/lib/jvm/java-11-openjdk"))

;; Enable nice rendering of documentation on hover
;;   Warning: on some systems this package can reduce your emacs responsiveness significally.
;;   (See: https://emacs-lsp.github.io/lsp-mode/page/performance/)
;;   In that case you have to not only disable this but also remove from the packages since
;;   lsp-mode can activate it automatically.
(use-package lsp-ui)

;; lsp-mode supports snippets, but in order for them to work you need to use yasnippet
;; If you don't want to use snippets set lsp-enable-snippet to nil in your lsp-mode settings
;;   to avoid odd behavior with snippets and indentation
(use-package yasnippet)

;; Use company-capf as a completion provider.
;;
;; To Company-lsp users:
;;   Company-lsp is no longer maintained and has been removed from MELPA.
;;   Please migrate to company-capf.
(use-package company
  :hook (scala-mode . company-mode)
  :config
  (setq lsp-completion-provider :capf))

;; Use the Debug Adapter Protocol for running tests and debugging
(use-package posframe
  ;; Posframe is a pop-up tool that must be manually installed for dap-mode
  )
(use-package dap-mode
  :hook
  (lsp-mode . dap-mode)
  (lsp-mode . dap-ui-mode)
  )

(defun setup-scala-mode-env ()
  "Use JDK 11 for scala-mode."
  (make-local-variable 'process-environment)
  (add-to-list 'process-environment
	"JAVA_HOME=/usr/lib/jvm/java-11-openjdk"))
(add-hook 'scala-mode 'scala-mode-env)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auth-source-save-behavior nil)
 '(helm-completion-style 'emacs)
 '(org-agenda-files
   '("~/org/finra.org" "~/org/lucidadept.org" "~/org/skills/piano.org" "~/org/skills/guitar.org" "~/org/Jibba Todo.org"))
 '(package-selected-packages
   '(geiser-racket slime smartparens geiser-guile geiser-mit lsp-ui lsp-metals lsp-mode sbt-mode scala-mode elpy use-package ednc swiper-helm helm-projectile helm unfill ## speed-type markdown-mode projectile magit soundcloud emms-soundcloud emms spray circe haskell-mode dmenu exwm)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(provide '.emacs)
;;; .emacs ends here
