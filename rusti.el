;;; rusti --- Rust interactive mode -*- lexical-binding: t -*-

;; Copyright (C) 2013 Rüdiger Sonderfeld

;; Author: Rüdiger Sonderfeld <ruediger@c-plusplus.de>
;; Created: 10 Aug 2013
;; Keywords: rust languages
;; URL: https://github.com/ruediger/rusti.el

;;; Commentary:

;; Run the rust REPL (rusti) in comint mode.

;;; Code:

(require 'comint)

(defgroup rusti nil
  "Rust interactive mode"
  :link '(url-link "https://github.com/ruediger/rusti-mode")
  :prefix "rusti-"
  :group 'languages)

(defcustom rusti-program (executable-find "rusti")
  "Program invoked by `rusti'."
  :group 'rusti
  :type 'file)

(defcustom rusti-args nil
  "Command line arguments for `rusti-program'."
  :group 'rusti
  :type '(repeat string))

(defcustom rusti-buffer "*Rusti*"
  "Name of buffer for rusti."
  :group 'rusti
  :type 'string)

(defcustom rusti-startup-file (locate-user-emacs-file "init_rusti.rs"
                                                      ".emacs-rusti.rs")
  "Startup file for `rusti'."
  :group 'rusti
  :type 'file)

(defcustom rusti-prompt-regexp "^rusti\\(>\\||\\) "
  "Regexp to match prompts for rusti."
  :group 'rusti
  :type 'regexp)

(defcustom rusti-prompt-read-only t
  "Make the prompt read only.
See `comint-prompt-read-only' for details."
  :group 'rusti
  :type 'boolean)

(defun rusti-is-running? ()
  "Return non-nil if rusti is running."
  (comint-check-proc rusti-buffer))
(defalias 'rusti-is-running-p #'rusti-is-running?)

;;;###autoload
(defun rusti (&optional arg)
  "Run rusti.

Unless ARG is non-nil, switch to the buffer."
  (interactive "P")
  (let ((buffer (get-buffer-create rusti-buffer)))
    (unless arg
      (pop-to-buffer buffer))
    (unless (rusti-is-running?)
      (with-current-buffer buffer
        (rusti-startup)
        (rusti-mode)))
    buffer))

;;;###autoload
(defalias 'run-rust #'rusti)
;;;###autoload
(defalias 'inferior-rust #'rusti)

(defun rusti-startup ()
  "Start rusti."
  (comint-exec rusti-buffer
               "Rusti"
               rusti-program
               (when (file-exists-p rusti-startup-file)
                 rusti-startup-file)
               rusti-args))

(define-derived-mode rusti-mode comint-mode "Rusti"
  "Major mode for rusti."
  (setq comint-prompt-regexp rusti-prompt-regexp
        comint-use-prompt-regexp t)
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comint-prompt-read-only rusti-prompt-read-only))

(defun rusti-eval-region (begin end)
  "Evaluate region between BEGIN and END."
  (interactive "r")
  (rusti t)
  (comint-send-region rusti-buffer begin end)
  (comint-send-string rusti-buffer "\n"))

(defun rusti-eval-buffer ()
  "Evaluate complete buffer."
  (interactive)
  (rusti-eval-region (point-min) (point-max)))

(defun rusti-eval-line (&optional arg)
  "Evaluate current line.

If ARG is a positive prefix then evaluate ARG number of lines starting with the
current one."
  (interactive "P")
  (unless arg
    (setq arg 1))
  (when (> arg 0)
    (rusti-eval-region
     (line-beginning-position)
     (line-end-position arg))))

(defvar rusti-minor-mode-map
  (let ((map (make-sparse-keymap)))
    ; (define-key map "\C-x\C-e" #'rusti-eval-last-sexp)
    (define-key map "\C-c\C-c" #'rusti-eval-buffer)
    (define-key map "\C-c\C-r" #'rusti-eval-region)
    (define-key map "\C-c\C-l" #'rusti-eval-line)
    map)
  "Mode map for `rusti-minor-mode'.")

(defcustom rusti-minor-mode-lighter " Rusti"
  "Text displayed in the mode line (Lighter) if `rusti-minor-mode' is active."
  :group 'rusti
  :type 'string)

(easy-menu-define rusti-minor-mode rusti-minor-mode-map
  "Menu for Rusti Minor Mode."
  '("Rusti"
    ["Eval Buffer" rusti-eval-buffer :help "Evaluate buffer with Rusti"]
    ["Eval Region" rusti-eval-region :help "Evaluate selected region with Rusti"]
    ["Eval Line" rusti-eval-line :help "Evaluate current line with Rusti"]))

;;;###autoload
(define-minor-mode rusti-minor-mode
  "Add keys and a menu to provide easy access to `rusti' support.
Usage:
  (add-hook 'rust-mode-hook #'rusti-minor-mode)"
  :group 'rusti
  :lighter rusti-minor-mode-lighter
  :keymap rusti-minor-mode-map)

(provide 'rusti)

;;; rusti.el ends here
