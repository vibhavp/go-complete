;;; go-complete.el --- Native code completion for Go
;; Copyright (C) 2015 Vibhav Pant

;; Author: Vibhav Pant <vibhavp@gmail.com>
;; Version: 1.0
;; Package-Requires: ((go-mode "0"))
;; Keywords: go, golang, completion
;; URL: https://github.com/vibhavp/go-complete

;;; Commentary:
;; This package provides native code completion for the Go Programming
;; Language.
;; To enable, put:

;;; Code:
(eval-when-compile
  (require 'cl))

(defcustom go-complete-gocode-command "gocode"
  "The command to invoke `gocode'."
  :group 'go-completion
  :type 'string)

(defun make-gocode-args ()
  (if (buffer-modified-p)
      (format "-f=emacs autocomplete %d" (point))
    (format "-f=emacs --in=%s autcomplete %d" buffer-file-name (point))))

(defun get-gocode-output ()
  (let ((temp-buffer (generate-new-buffer "*gocode*")))
    (if (buffer-modified-p)
	(call-process-region (point-min)
			     (point-max)
			     go-complete-gocode-command
			     nil
			     temp-buffer
			     nil
			     "-f=emacs"
			     "autocomplete"
			     (concat "c" (int-to-string (-  (point) 1))))
      (call-process-region
       (point-min)
       (point-min)
       "gocode"
       nil
       temp-buffer
       nil
       "-f=emacs"
       (format "--in=%s" buffer-file-name)
       "autocomplete"
       (concat "c" (int-to-string (- (point) 1)))))
    temp-buffer))

(defun args-commas (string)
  (let ((index (string-match ",,func(" string))
	(args 0))
    (unless (or (eq index nil) (string= (substring string index (+ index 1)) ")"))
      (cl-incf index 2)
      (while (not (eq index (- (length string) 1)))
	(when (string= (substring string index (+ index 1)) ",")
	  (cl-incf args))
	(cl-incf index))
      (format "(%s)" (make-string args ?,)))))

(defun make-completion (string)
  (format "%s%s"
	  (substring string 0 (string-match "," string))
	  (if (string-match ",,func(" string) (args-commas string) "")))

(defun make-gocode-completion-list (buffer)
  (with-current-buffer buffer
    (goto-char (point-min))
    (let ((completion-list '()))
      (while (not (eq (point) (point-max)))
	(setq completion-list
	      (append completion-list (list (make-completion
					     (buffer-substring
					      (line-beginning-position)
					      (line-end-position))))))
	(forward-line))
      (kill-buffer buffer)
      completion-list)))

(defun go-complete-at-point ()
  "Complete go expression at point."
  (interactive)
  (when (derived-mode-p 'go-mode)
    (let ((token (current-word t))
	  (completing-field (string= "." (buffer-substring
					  (- (point) 1) (point)))))
      (when (or token completing-field)
	(list
	 (if completing-field
	     (point)
	   (save-excursion (left-word) (point)))
	 (point)
	 (make-gocode-completion-list (get-gocode-output))
	 .
	 nil)))))

(provide 'go-complete)
;;; go-complete.el ends here
