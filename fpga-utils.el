;;; fpga-utils.el --- FPGA & ASIC Utils  -*- lexical-binding: t -*-

;; Copyright (C) 2022-2023 Gonzalo Larumbe

;; Author: Gonzalo Larumbe <gonzalomlarumbe@gmail.com>
;; URL: https://github.com/gmlarumbe/fpga
;; Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; FPGA/ASIC Common Utils

;;; Code:

(require 'compile)
(require 'ggtags)
(require 'company)


;;;; Custom
(defcustom fpga-utils-source-extension-re (concat "\\." (regexp-opt '("sv" "svh" "v" "vh" "vhd" "vhdl")) "$")
  "FPGA source file extension regexp."
  :type 'string
  :group 'fpga)

(defcustom fpga-utils-tags-creation-fn #'ggtags-create-tags
  "Function to use to create tags."
  :type 'function
  :group 'fpga)

(defcustom fpga-utils-completion-use-company-p t
  "Wheter to use `company-mode' for completion in shells."
  :type 'function
  :group 'fpga)


;;;; Faces
(defconst fpga-utils-compilation-msg-code-face 'fpga-utils-compilation-msg-code-face)
(defface fpga-utils-compilation-msg-code-face
  '((t (:foreground "gray55")))
  "Face for compilation message codes."
  :group 'fpga)

(defconst fpga-utils-compilation-bin-face 'fpga-utils-compilation-bin-face)
(defface fpga-utils-compilation-bin-face
  '((t (:foreground "goldenrod")))
  "Face for compilation binaries."
  :group 'fpga)

(defvar fpga-utils-brackets-face 'fpga-utils-brackets-face)
(defface fpga-utils-brackets-face
  '((t (:foreground "goldenrod")))
  "Face for brackets []."
  :group 'fpga)

(defvar fpga-utils-parenthesis-face 'fpga-utils-parenthesis-face)
(defface fpga-utils-parenthesis-face
  '((t (:foreground "dark goldenrod")))
  "Face for parenthesis ()."
  :group 'fpga)

(defvar fpga-utils-curly-braces-face 'fpga-utils-curly-braces-face)
(defface fpga-utils-curly-braces-face
  '((t (:foreground "DarkGoldenrod2")))
  "Face for curly braces {}."
  :group 'fpga)

(defvar fpga-utils-braces-content-face 'fpga-utils-braces-content-face)
(defface fpga-utils-braces-content-face
  '((t (:foreground "yellow green")))
  "Face for content between braces: arrays, bit vector width and indexing."
  :group 'fpga)

(defvar fpga-utils-punctuation-face 'fpga-utils-punctuation-face)
(defface fpga-utils-punctuation-face
  '((t (:foreground "burlywood")))
  "Face for punctuation symbols, e.g:
!,;:?'=<>*"
  :group 'fpga)


;;;; Constants
(defconst fpga-utils-brackets-re "\\(\\[\\|\\]\\)")
(defconst fpga-utils-parenthesis-re "[()]")
(defconst fpga-utils-curly-braces-re "[{}]")
(defconst fpga-utils-braces-content-re "\\[\\(?1:[0-9]+\\)\\]")
(defconst fpga-utils-punctuation-re "\\([!,;:?'=<>&^~%\+-]\\|\\*\\|\\.\\|\\/\\|\|\\)")


;;;; Functions
(defun fpga-utils-write-file-from-filelist (outfile filelist)
  "Create OUTFILE with one file of FILELIST per line."
  (with-temp-file outfile
    (dolist (line filelist)
      (insert line "\n"))))

(defun fpga-utils-tags-create (out-dir in-file file-list-fn)
  "Generate tags from filelist.

Tags will be generated in OUT-DIR from the project file of IN-FILE (xpr/qsf).

Third parameter FILE-LIST-FN is the used function to create gtags.files from
IN-FILE."
  (interactive "DOutput dir: \nFInput file: ")
  (let* ((gtags-file-name "gtags.files")
         (gtags-file-path (file-name-concat out-dir gtags-file-name)))
    (fpga-utils-write-file-from-filelist gtags-file-path (funcall file-list-fn in-file))
    (funcall fpga-utils-tags-creation-fn out-dir)))

(defun fpga-utils-shell-delchar-or-maybe-eof (num-chars)
  "Delete character or exit shell.
With `prefix-arg', delete NUM-CHARS characters."
  (interactive "p")
  (let ((proc (get-buffer-process (current-buffer))))
    (if (and (eobp)
             (save-excursion
               (skip-chars-backward " ")
               (member (preceding-char) '(?% ?>))))
        (comint-send-string proc "exit\n")
      (delete-char num-chars))))

(defmacro fpga-utils-define-compilation-mode (name &rest args)
  "Macro to define a compilation derived mode for a FPGA error regexp.
NAME is the name of the created function.
ARGS is a property list with :desc, :docstring, :compile-re and :buf-name."
  (declare (indent 1) (debug 1))
  (let ((desc (plist-get args :desc))
        (docstring (plist-get args :docstring))
        (compile-re (plist-get args :compile-re))
        (buf-name (plist-get args :buf-name)))
    `(define-compilation-mode ,name ,desc ,docstring
       (setq-local compilation-error-regexp-alist (mapcar #'car ,compile-re))
       (setq-local compilation-error-regexp-alist-alist ,compile-re)
       (rename-buffer ,buf-name)
       (setq truncate-lines t)
       (goto-char (point-max)))))

(defmacro fpga-utils-define-compile-fn (name &rest args)
  "Macro to define a function to compile with error regexp highlighting.
Function will be callable by NAME.
ARGS is a property list."
  (declare (indent 1) (debug 1))
  (let ((docstring (plist-get args :docstring))
        (buf (plist-get args :buf))
        (comp-mode (plist-get args :comp-mode)))
    `(defun ,name (command)
       ,docstring
       (when (get-buffer ,buf)
         (if (y-or-n-p (format "Buffer %s is in use, kill its process and start new compilation?" ,buf))
             (kill-buffer ,buf)
           (user-error "Aborted")))
       (compile command)
       (,comp-mode))))

(defmacro fpga-utils-define-shell-mode (name &rest args)
  "Define shell mode.
NAME is the name of the created function.
ARGS is a property list."
  (declare (indent 1) (debug 1))
  (let (;; Keyword args
        (bin (plist-get args :bin))
        (base-cmd (plist-get args :base-cmd))
        (shell-commands (plist-get args :shell-commands))
        (compile-re (plist-get args :compile-re))
        (buf (plist-get args :buf))
        (font-lock-kwds (plist-get args :font-lock-kwds))
        ;; Internal args
        (mode-fn (intern (concat (symbol-name name) "-mode")))
        (capf-fn (intern (concat (symbol-name name) "-capf")))
        (mode-map (intern (concat (symbol-name name) "-mode-map")))
        (send-line-or-region-fn (intern (concat (symbol-name name) "-send-line-or-region-and-step")))
        (mode-hook (intern (concat (symbol-name name) "-mode-hook"))))

    ;; First define a function for `completion-at-point-functions'
    `(progn
       (defun ,capf-fn ()
         "Completion at point for shell mode."
         (let* ((b (save-excursion (skip-chars-backward "a-zA-Z0-9_-") (point)))
                (e (save-excursion (skip-chars-forward "a-zA-Z0-9_-") (point)))
                (str (buffer-substring b e))
                (allcomp (all-completions str ,shell-commands)))
           (list b e allcomp)))

       ;; Define mode-map
       (defvar ,mode-map
         (let ((map (make-sparse-keymap)))
           (define-key map (kbd "C-d") 'fpga-utils-shell-delchar-or-maybe-eof)
           map)
         "Keymap.")

       ;; Define minor mode for shell
       (define-minor-mode ,mode-fn
         "Shell mode."
         :global nil
         (setq-local compilation-error-regexp-alist (mapcar #'car ,compile-re))
         (setq-local compilation-error-regexp-alist-alist ,compile-re)
         (rename-buffer ,buf)
         (setq truncate-lines t)
         (goto-char (point-max))
         ;; If `company' is present, remove `comint-filename-completion' and try to rely on `company-files':
         ;; - `comint-filename-completion' has a bug, causing an issue with CAPF. It
         ;;   returns non-nil even though there is no proper file completion,
         ;;   e.g. trying to complete "syn", would cause comint detecting a potential
         ;;   file with results from `comint--complete-file-name-data', while there is
         ;;   no actual file.  If this function is before capf-fn in the
         ;;   `comint-dynamic-complete-functions' hook, it will never execute.
         (when fpga-utils-completion-use-company-p
           (setq-local comint-dynamic-complete-functions '(comint-c-a-p-replace-by-expanded-history))
           (setq-local company-backends '(company-files company-capf))
           (company-mode 1))
         (add-hook 'comint-dynamic-complete-functions #',capf-fn :local))

       ;; Defin shell function
       (defun ,name ()
         "Spawn an improved shell.
Enables auto-completion and syntax highlighting."
         (interactive)
         (unless ,bin
           (error ,(concat "Could not find " (symbol-name bin) " in $PATH.'")))
         (when (get-buffer ,buf)
           (if (y-or-n-p (format "Buffer %s is in use, kill process and start new shell?" ,buf))
               (kill-buffer ,buf)
             (user-error "Aborted")))
         (let* ((cmd ,base-cmd)
                buf)
           (setq buf (compile cmd t))
           (with-current-buffer buf
             (,mode-fn))))

       ;; Define a shell send line function, meant to be used in tcl buffers
       (defun ,send-line-or-region-fn ()
         "Send the current line to the its shell and step to the next line.
When the region is active, send the region instead."
         (interactive)
         (let (from to end (proc (get-buffer-process ,buf)))
           (if (use-region-p)
               (setq from (region-beginning)
                     to (region-end)
                     end to)
             (setq from (line-beginning-position)
                   to (line-end-position)
                   end (1+ to)))
           (comint-send-string proc (buffer-substring-no-properties from to))
           (comint-send-string proc "\n")
           (goto-char end)))

       ;; Add font-lock keywords for extra syntax highlighting
       (when ,font-lock-kwds
         (add-hook ',mode-hook (lambda () (font-lock-add-keywords nil ,font-lock-kwds 'append)))))))


;;;; Compilation-re
(defvar fpga-utils-compilation-uvm-re
  '((uvm-fatal    "^\\(?1:UVM_FATAL\\) \\(?2:[a-zA-Z0-9\./_-]+\\)(\\(?3:[0-9]+\\))"   2 3 nil 2 nil (1 compilation-error-face))
    (uvm-fatal2   "^\\(?1:UVM_FATAL\\) @"   1 nil nil 2 nil)
    (uvm-error    "^\\(?1:UVM_ERROR\\) \\(?2:[a-zA-Z0-9\./_-]+\\)(\\(?3:[0-9]+\\))"   2 3 nil 2 nil (1 compilation-error-face))
    (uvm-error2   "^\\(?1:UVM_ERROR\\) @"   1 nil nil 2 nil)
    (uvm-warning  "^\\(?1:UVM_WARNING\\) \\(?2:[a-zA-Z0-9\./_-]+\\)(\\(?3:[0-9]+\\))" 2 3 nil 1 nil (1 compilation-warning-face))
    (uvm-warning2 "^\\(?1:UVM_WARNING\\) @" 1 nil nil 1 nil)
    (uvm-info     "^\\(?1:UVM_INFO\\) \\(?2:[a-zA-Z0-9\./_-]+\\)(\\(?3:[0-9]+\\))"    2 3 nil 0 nil (1 compilation-info-face))
    (uvm-info2    "^\\(?1:UVM_INFO\\) @"    1 nil nil 0 nil)))

(defvar fpga-utils-compilation-ovm-re
  '((ovm-fatal    "^\\(?1:OVM_FATAL\\) @ \\(?2:[0-9]+\\): "   1 nil nil 2 nil (2 compilation-line-face))
    (ovm-error    "^\\(?1:OVM_ERROR\\) @ \\(?2:[0-9]+\\): "   1 nil nil 2 nil (2 compilation-line-face))
    (ovm-warning  "^\\(?1:OVM_WARNING\\) @ \\(?2:[0-9]+\\): " 1 nil nil 1 nil (2 compilation-line-face))
    (ovm-info     "^\\(?1:OVM_INFO\\) @ \\(?2:[0-9]+\\): "    1 nil nil 0 nil (2 compilation-line-face))))

(defconst fpga-utils-shell-switch-re "\\_<\\(?1:-\\)\\(?2:[a-zA-Z0-9_]+\\)\\_>")



(provide 'fpga-utils)

;;; fpga-utils.el ends here
