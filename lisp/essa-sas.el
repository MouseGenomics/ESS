;;; essa-sas.el -- ESS local customizations for SAS, part a.

;; Copyright (C) 1997--2001 Rodney Sparapani, A.J. Rossini, 
;; Martin Maechler, Kurt Hornik, and Richard M. Heiberger.

;; Author: Rodney Sparapani <rsparapa@mcw.edu>
;; Maintainer: Rodney Sparapani <rsparapa@mcw.edu>, 
;;             A.J. Rossini <rossini@u.washington.edu>
;; Created: 17 November 1999
;; Modified: $Date: 2002/01/23 21:50:05 $
;; Version: $Revision: 1.79 $
;; RCS: $Id: essa-sas.el,v 1.79 2002/01/23 21:50:05 rsparapa Exp $

;; Keywords: ESS, ess, SAS, sas, BATCH, batch 

;; This file is part of ESS

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
;;
;; In short: you may use this code any way you like, as long as you
;; don't charge money for it, remove this notice, or hold anyone liable
;; for its results.

;; Code:

;;; Table of Contents
;;; Section 1:  Variable Definitions
;;; Section 2:  Function Definitions
;;; Section 3:  Key Definitions


;;; Section 1:  Variable Definitions

(require 'ess-batch)

(defcustom ess-kermit-command "gkermit -T"
    "*Kermit command invoked by `ess-kermit-get' and `ess-kermit-send'."
    :group 'ess-sas
    :type  'string
)

(defvar ess-sas-file-path "."
    "Full path-name of the sas file to perform operations on.")

(defcustom ess-sas-data-view-libname " "
    "*SAS code to define a library for `ess-sas-data-view'."
    :group 'ess-sas
    :type  'string
)

;;(defcustom ess-sas-smart-back-tab nil
;;    "*Set to t to make C-TAB insert an end/%end; statement to close a block."
;;    :group 'ess-sas
;;)

(defcustom ess-sas-submit-command sas-program
    "*Command to invoke SAS in batch; buffer-local."
    :group 'ess-sas
    :type  'string
)

(make-variable-buffer-local 'ess-sas-submit-command)

(defcustom ess-sas-submit-command-options " "
    "*Options to pass to SAS in batch; buffer-local."
    :group 'ess-sas
    :type  'string
)

(make-variable-buffer-local 'ess-sas-submit-command-options)

(defvar ess-sas-submit-method 
  (if ess-microsoft-p 
    (if (w32-shell-dos-semantics) 'ms-dos 'sh)
    (if (equal system-type 'Apple-Macintosh) 'apple-script 'sh))
  "Method used by `ess-sas-submit'.
The default is based on the value of the emacs variable `system-type'
and, on Windows machines, the function `w32-shell-dos-semantics'.
'ms-dos           if *shell* follows MS-DOS semantics
'iESS             inferior ESS, may be local or remote
'sh               if *shell* runs sh, ksh, csh, tcsh or bash
'apple-script     *shell* unavailable, use AppleScript

Windows users running MS-DOS in *shell* will get 'ms-dos by default.

Windows users running bash in *shell* will get 'sh by default.

Unix users will get 'sh by default.

Users accessing a remote machine with `telnet', `rlogin', `ssh',
or `ESS-elsewhere' should have one of the following in ~/.emacs
   (setq-default ess-sas-submit-method 'iESS)
   (setq-default ess-sas-submit-method 'sh)")

(defcustom ess-sas-data-view-options 
    (if ess-microsoft-p "-noenhancededitor -nosysin -log NUL:"
	"-nodms -nosysin -log /dev/null")
    "*The options necessary for your enviromment and your operating system."
    :group 'ess-sas
    :type  'string
)

(defcustom ess-sas-submit-post-command 
    (if (equal ess-sas-submit-method 'sh) "-rsasuser &" 
	(if ess-microsoft-p "-rsasuser -icon"))    
    "*Command-line statement to post-modify SAS invocation, e.g. -rsasuser"
    :group 'ess-sas
    :type  'string
)

(defcustom ess-sas-submit-pre-command 
    (if (equal ess-sas-submit-method 'sh) "nohup" 
	(if ess-microsoft-p "start"))
    "*Command-line statement to pre-modify SAS invocation, e.g. start or nohup"
    :group 'ess-sas
    :type  'string
)

(defcustom ess-sas-suffix-1 "txt"
    "*The first suffix to associate with SAS."
    :group 'ess-sas
    :type  'string
)

(defcustom ess-sas-suffix-2 "csv"
    "*The second suffix to associate with SAS."
    :group 'ess-sas
    :type  'string
)

(defcustom ess-sas-suffix-regexp 
    (concat "[.]\\([sS][aA][sS]\\|[lL][oO][gG]\\|[lL][sS][tT]"
	(if ess-sas-suffix-1 (concat 
	    "\\|" (downcase ess-sas-suffix-1) "\\|" (upcase ess-sas-suffix-1)))
	(if ess-sas-suffix-2 (concat 
	    "\\|" (downcase ess-sas-suffix-2) "\\|" (upcase ess-sas-suffix-2)))
	"\\)")
    "*Regular expression for SAS suffixes."
    :group 'ess-sas
    :type  'string
)

(defcustom ess-sleep-for 5
    "*Default for ess-sas-submit-sh is to sleep for 5 seconds."
    :group 'ess-sas
    :type  'number
)

(defvar ess-sas-tab-stop-alist
 '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120)
  "List of tab stop positions used by `tab-to-tab-stop' in ESS[SAS].")

(defcustom ess-sas-temp-root "ess-temp"
    "*The root of the temporary .sas file for `ess-sas-submit-region'."
    :group 'ess-sas
    :type  'string
)


;;; Section 2:  Function Definitions

(defun ess-add-ess-process ()
  "Execute this command from within a buffer running a process to add
the process to `ess-process-name-alist' and to make it the
`ess-current-process-name'.  This command will normally be run in a
telnet buffer connected to another computer or in a shell or comint
buffer on the local computer."
  (interactive)
  (setq ess-current-process-name
	(process-name (get-buffer-process (buffer-name))))
  (add-to-list 'ess-process-name-list (list ess-current-process-name)))


(defun ess-exit-notify-sh (string)
  "Detect completion or failure of submitted job and notify the user."
  (let* ((exit-done "\\[[0-9]+\\]\\ *\\+*\\ *\\(Exit\\|Done\\).*$")
	 (beg (string-match exit-done string)))
    (if beg
	(message (substring string beg (match-end 0))))))

(defun ess-kermit-get ()
  "Get a file with Kermit.  Works so far with ssh, but not telnet."
    (interactive)

     (save-match-data 
       (let ((ess-temp-file (expand-file-name (buffer-name))))
     
	(if (and (not (string-match "[[]" ess-temp-file))
	  (string-match "]" ess-temp-file)) (progn

	  (setq ess-temp-file (substring ess-temp-file (match-end 0)))
	  (shell)
	  (insert "cd $HOME; " ess-kermit-command " -s " ess-temp-file " -a ]" ess-temp-file)
          (comint-send-input)	
;;          (insert (read-string "Press Return to connect to Kermit: " nil nil "\C-\\c"))
;;	  (comint-send-input)
;;	  (insert (read-string "Press Return when Kermit is ready to recieve: " nil nil 
;;		  (concat "receive ]" ess-sas-temp-file)))                
;;	  (comint-send-input)
;;	  (insert (read-string "Press Return when transfer is complete: " nil nil "c"))                
;;	  (comint-send-input)
          (insert (read-string "Press Return when shell is ready: "))
	  (comint-send-input)
	  (switch-to-buffer (find-buffer-visiting (concat "]" ess-temp-file)))
	  (ess-revert-wisely)
)))))

(defun ess-kermit-send ()
  "Send a file with Kermit.  Works so far with ssh, but not telnet."
    (interactive)

     (save-match-data (let ((ess-temp-file (expand-file-name (buffer-name))))
	(if (and (not (string-match "[[]" ess-temp-file))
	  (string-match "]" ess-temp-file)) (progn

	  (setq ess-temp-file (substring ess-temp-file (match-end 0)))
             (save-buffer)
	     (shell)
	     (insert "cd $HOME; " ess-kermit-command " -g ]" ess-temp-file " -a " ess-temp-file)
             (comint-send-input)	
;;	     (insert (read-string "Press Return to connect to Kermit: " nil nil "\C-\\c"))
;;	     (comint-send-input)
;;	     (insert (read-string "Press Return when Kermit is ready to send: " nil nil
;;		     (concat "send ]" ess-sas-temp-file " " ess-sas-temp-file)))                
;;	     (comint-send-input)
;;	     (insert (read-string "Press Return when transfer is complete: " nil nil "c"))              
;;           (comint-send-input)
             (insert (read-string "Press Return when shell is ready: "))
	     (comint-send-input)
	     (switch-to-buffer (find-buffer-visiting (concat "]" ess-temp-file)))
)))))


(defun ess-sas-append-log ()
    "Append ess-temp.log to the current .log file."
    (interactive)
    (ess-sas-goto "log" 'revert)
    (goto-char (point-max))
    (insert-file-contents (concat ess-sas-temp-root ".log"))
    (save-buffer))

(defun ess-sas-append-lst ()
    "Append ess-temp.lst to the current .lst file."
    (interactive)
    (ess-sas-goto "lst" 'revert)
    (goto-char (point-max))
    (insert-file-contents (concat ess-sas-temp-root ".lst"))
    (save-buffer))

(defun ess-sas-backward-delete-tab ()
  "Moves the cursor to the previous tab-stop, deleting any characters
on the way."
  (interactive)
  
  (let* (;; point of search 
	 ;;(ess-sas-search-point nil)
	 ;; column of search 
	 ;;(ess-sas-search-column nil)
	 ;; limit of search 
	 ;;(ess-sas-search-limit nil)
	 ;; text to be inserted after a back-tab, if any
	 ;;(ess-sas-end-text "end;")
	 ;; current-column
	 (ess-sas-column (current-column))
	 ;; remainder of current-column and sas-indent-width
	 (ess-sas-remainder (% ess-sas-column sas-indent-width)))

    (if (not (= ess-sas-column 0)) 
	(progn
	  (if (= ess-sas-remainder 0) 
	      (setq ess-sas-remainder sas-indent-width))
	  
	  (backward-delete-char-untabify ess-sas-remainder t)
	  (setq ess-sas-column (- ess-sas-column ess-sas-remainder))
	  (move-to-column ess-sas-column)
	  (setq left-margin ess-sas-column)
    ))
))

;; this feature was far too complicated to perfect
;;      (if ess-sas-smart-back-tab (progn
;;	  (save-excursion
;;	    (setq ess-sas-search-point	    
;;		(search-backward-regexp "end" nil t))

;;	    (if (and ess-sas-search-point
;;		(search-backward-regexp "%" (+ ess-sas-search-point -1) t))
;;		(setq ess-sas-search-point (+ ess-sas-search-point -1))
;;	    )
		
;;	    (if (and ess-sas-search-point
;;		(not (equal ess-sas-column (current-column))))
;;		(setq ess-sas-search-point nil))
;;	    )

;;	  (save-excursion
;;	    (setq ess-sas-search-point	    
;;		(search-backward-regexp "do\\|select" 
;;		    ess-sas-search-point t))

;;	    (setq ess-sas-search-column (current-column))

;;	    (if ess-sas-search-point (progn
;;		(save-excursion
;;		 (search-backward-regexp "^" nil t)
;;		 (setq ess-sas-search-limit (point))
;;		)

;;	        (if (search-backward-regexp "if.*then\\|else" ess-sas-search-limit t)
;;		    (setq ess-sas-search-point (point)))

;;	        (if (search-backward-regexp "%" ess-sas-search-limit t) (progn
;;		    (setq ess-sas-end-text "%end;")
;;		    (setq ess-sas-search-point (point))
;;		))

;;		(setq ess-sas-search-column (current-column))

;;	        (if (not (equal ess-sas-column ess-sas-search-column))
;;		   (setq ess-sas-search-point nil))
;;	  )))

;;	  (if ess-sas-search-point (insert ess-sas-end-text))
;;         ))

(defun ess-sas-data-view (&optional ess-sas-data)
  "Open a dataset for viewing with PROC FSVIEW."
    (interactive)

 (save-excursion (let ((ess-tmp-sas-data nil))
    (if ess-sas-data nil (save-match-data 
       (search-backward-regexp "[ \t=]" nil t)

       (if (or
           (search-forward-regexp 
	     "[ \t=]\\([a-zA-Z_][a-zA-Z_0-9]*[.][a-zA-Z_][a-zA-Z_0-9]*\\)[ ,()\t;]"
	     nil t)
           (search-backward-regexp 
	     "[ \t=]\\([a-zA-Z_][a-zA-Z_0-9]*[.][a-zA-Z_][a-zA-Z_0-9]*\\)[ ,()\t;]"
	     nil t)) (setq ess-tmp-sas-data (match-string 1)))

       (if (and ess-tmp-sas-data 
	  (not (string-match "^\\(first\\|last\\)[.]" ess-tmp-sas-data)))
	    (setq ess-sas-data (read-string "SAS Dataset: " ess-tmp-sas-data))
	    (setq ess-sas-data (read-string "SAS Dataset: ")))

       (if (get-buffer "*shell*") (set-buffer "*shell*") (shell))

	(insert (concat ess-sas-submit-pre-command " " ess-sas-submit-command 
	    " -initstmt \"" ess-sas-data-view-libname "; proc fsview data=" 
	    ess-sas-data "; run;\" " ess-sas-data-view-options " " 
	    ess-sas-submit-post-command))
    (comint-send-input)
)))))

(defun ess-sas-goto (suffix &optional revert)
  "Find a file associated with a SAS file by suffix and revert if necessary."
    (let ((ess-temp-regexp (concat ess-sas-suffix-regexp "\\(@.+\\)?")))
	(save-match-data 
	(if (or (string-match ess-temp-regexp (expand-file-name (buffer-name)))
	
	    (string-match ess-temp-regexp ess-sas-file-path))

	(progn
	    (ess-set-file-path)

	    (let* (
		(ess-sas-temp-file (replace-match (concat "." suffix) t t ess-sas-file-path))
		(ess-sas-temp-buff (find-buffer-visiting ess-sas-temp-file)))

	(if ess-sas-temp-buff (switch-to-buffer ess-sas-temp-buff)
	    (find-file ess-sas-temp-file))
	
	  (if revert (ess-revert-wisely))
))))))

;;(defun ess-sas-file (suffix &optional revert)
;;  "Please use `ess-sas-goto' instead."
;;  (let* ((tail (downcase (car (split-string 
;;	    (car (last (split-string (buffer-name) "[.]"))) "[<]"))))
	;;(if (fboundp 'file-name-extension) (file-name-extension (buffer-name))
	;;		 (substring (buffer-name) -3)))
;;	 (tail-in-tail-list (member tail (list "sas" "log" "lst"
;;			     ess-sas-suffix-1 ess-sas-suffix-2)))
;;	 (root (if tail-in-tail-list (expand-file-name (buffer-name))
;;		 ess-sas-file-path))
;;	 (ess-sas-arg (concat (file-name-sans-extension root) "." suffix))
;;	 (ess-sas-buf (find-buffer-visiting ess-sas-arg)))
;;    (if (equal tail suffix) (if revert (ess-revert-wisely))
;;	(if (not ess-sas-buf) (find-file ess-sas-arg)
;;	    (switch-to-buffer ess-sas-buf)
;;	    (if revert (ess-revert-wisely))))))

(defun ess-sas-file-path ()
 "Define the variable `ess-sas-file-path' to be the file in the current buffer"
  (interactive)

  (save-match-data (let ((ess-sas-temp-file (expand-file-name (buffer-name))))
    (if (string-match ess-sas-suffix-regexp ess-sas-temp-file) 
	(setq ess-sas-file-path (nth 0 (split-string ess-sas-temp-file "[<]")))))))

(defun ess-sas-goto-file-1 ()
  "Switch to ess-sas-file-1 and revert from disk."
  (interactive)
  (ess-sas-goto ess-sas-suffix-1 'revert))

(defun ess-sas-goto-file-2 ()
  "Switch to ess-sas-file-2 and revert from disk."
  (interactive)
  (ess-sas-goto ess-sas-suffix-2 'revert))

(defun ess-sas-goto-log ()
  "Switch to the .log file, revert from disk and search for error messages."
  (interactive)
  (ess-sas-goto "log" 'revert)

  (let ((ess-sas-error (concat "^ERROR [0-9]+-[0-9]+:\\|^ERROR:\\|_ERROR_=1 _\\|_ERROR_=1[ ]?$"
    "\\|NOTE: MERGE statement has more than one data set with repeats of BY values."
    "\\|NOTE: Variable .* is uninitialized."
    "\\|WARNING: Apparent symbolic reference .* not resolved."
    "\\|NOTE 485-185: Informat .* was not found or could not be loaded."
    "\\|Bus Error In Task\\|Segmentation Violation In Task")))

  (if (not (search-forward-regexp ess-sas-error nil t)) 
        (if (search-backward-regexp ess-sas-error nil t) 
            (progn
                (goto-char (point-min))
                (search-forward-regexp ess-sas-error nil t)
            )
        )
    ))
)

(defun ess-sas-goto-lst ()
  "Switch to the .lst file and revert from disk."
  (interactive)
  (ess-sas-goto "lst" 'revert))

(defun ess-sas-goto-sas (&optional revert)
  "Switch to the .sas file."
  (interactive)
  (ess-sas-goto "sas" revert))

;;
;;(defun ess-sas-goto-shell ()
;; "Set variable `ess-sas-file-path' to file in current buffer and goto *shell*"
;;  (interactive)
;;  (ess-sas-file-path)
;;  (switch-to-buffer "*shell*")
;;)

(defun ess-sas-submit ()
  "Save the .sas file and submit to shell using a function that
depends on the value of  `ess-sas-submit-method'"
  (interactive)
  (ess-set-file-path)
  (ess-sas-goto-sas)
  (save-buffer)

  ; if Local Variables are defined, a revert is necessary to update their values
  (save-excursion 
    (beginning-of-line -1)
    (save-match-data 
	(if (search-forward "End:" nil t) (revert-buffer t t))))

  (cond
   ((eq ess-sas-submit-method 'apple-script) 
	(ess-sas-submit-mac ess-sas-submit-command ess-sas-submit-command-options))
   ((eq ess-sas-submit-method 'ms-dos) 
	(ess-sas-submit-windows ess-sas-submit-command ess-sas-submit-command-options))
   ((eq ess-sas-submit-method 'iESS) 
	(ess-sas-submit-iESS ess-sas-submit-command ess-sas-submit-command-options))
   ((eq ess-sas-submit-method 'sh) 
	(ess-sas-submit-sh ess-sas-submit-command ess-sas-submit-command-options)) 
   (t (ess-sas-submit-sh ess-sas-submit-command ess-sas-submit-command-options)))
  (ess-sas-goto-sas)
)

(defun ess-sas-submit-iESS (arg1 arg2)
  "iESS
Submit a batch job in an inferior-ESS buffer.  The buffer should
(1) have telnet access and be running a shell on a remote machine
or
(2) be running a shell on the local machine.

The user can telnet to the remote computer and then declare the
*telnet-buffer* to be an inferior ESS buffer with the `ess-add-ess-process'
command.  When using a remote computer, the .sas file must live on the
remote computer and be accessed through `ange-ftp'.  When
`ess-sas-submit' saves a file, it is therefore saved on the remote
computer.  The various functions such as `ess-sas-goto-lst' retrieve
their files from the remote computer.  Local copies of the .sas .lst
.log and others may be made manually with `write-buffer'."
  (ess-force-buffer-current "Process to load into: ")
  (ess-eval-linewise (concat "cd " default-directory))
  (ess-eval-linewise (concat arg1 " " arg2 " " (buffer-name) " &")))

(defun ess-sas-submit-mac (arg1 arg2)
  "Mac
arg1 is assumed to be the AppleScript command
\"invoke SAS using program file\".  If so, then arg2, if any, is a complex string
of the form \"with options { \\\"option-1\\\", \\\"option-2\\\", etc.}\" ."
  (do-applescript (concat arg1
			  " \"" (unix-filename-to-mac default-directory)
			  (buffer-name) "\"" arg2)))

(defun ess-sas-submit-region ()
    "Write region to temporary file, and submit to SAS."
    (interactive)
    (ess-set-file-path)
    (write-region (region-beginning) (region-end) 
	(concat ess-sas-temp-root ".sas"))

    (save-excursion 
      (if (get-buffer "*shell*") (set-buffer "*shell*") (shell))

    (if (and (w32-shell-dos-semantics)
	(string-equal ":" (substring ess-sas-file-path 1 2)))
	(progn
		(insert (substring ess-sas-file-path 0 2))
		(comint-send-input)
    ))

    (insert "cd \"" (convert-standard-filename 
	(file-name-directory ess-sas-file-path)) "\"")
    (comint-send-input)

    (insert (concat ess-sas-submit-pre-command " " ess-sas-submit-command 
          " " ess-sas-temp-root " " ess-sas-submit-post-command))
    (comint-send-input)
    )
)

(defun ess-sas-submit-sh (arg1 arg2)
  "Unix or bash in the *shell* buffer.
Multiple processing is supported on this platform.
SAS may not be found in your PATH.  You can alter your PATH to include
SAS or you can specify the PATHNAME (PATHNAME can NOT contain spaces),
i.e. let arg1 be your local equivalent of
\"/usr/local/sas612/sas\"."
    (shell)
    (add-hook 'comint-output-filter-functions 'ess-exit-notify-sh) ;; 19.28
                                          ;; nil t) works for newer emacsen
    (insert "cd " (car (last (split-string (file-name-directory ess-sas-file-path) "\\(:\\|]\\)"))))
    (comint-send-input)
    (insert ess-sas-submit-pre-command " " arg1 " "  
	(file-name-sans-extension (file-name-nondirectory ess-sas-file-path)) 
	" " arg2 " " ess-sas-submit-post-command)
    (comint-send-input)
    (ess-sleep)
    (comint-send-input))

(defun ess-sas-submit-windows (arg1 arg2)
  "Windows using MS-DOS prompt in the *shell* buffer.
Multiple processing is supported on this platform.
On most Windows installations, SAS will not be found in your
PATH.  You can set `ess-sas-submit-command' to 
\"sas -icon -rsasuser\" and alter your PATH to include SAS, i.e.

SET PATH=%PATH%;C:\\Program Files\\SAS

Or you can specify the PATHNAME directly (you must escape 
spaces by enclosing the string in \\\"'s), i.e. let 
`ess-sas-submit-command' be \"\\\"C:\\Program Files\\SAS\\sas.exe\\\"\".
Keep in mind that the maximum command line length in MS-DOS is
127 characters so altering your PATH is preferable."
    (shell)
    (if (string-equal ":" (substring ess-sas-file-path 1 2)) 
	(progn
		(insert (substring ess-sas-file-path 0 2))
		(comint-send-input)
	)
    )
    (insert "cd \"" (convert-standard-filename 
	(file-name-directory ess-sas-file-path)) "\"")
    (comint-send-input)
    (insert ess-sas-submit-pre-command " " arg1 " -sysin \"" 
	(file-name-sans-extension (file-name-nondirectory ess-sas-file-path)) "\" "
	arg2 " " ess-sas-submit-post-command)
    (comint-send-input))


(defun ess-sas-tab-to-tab-stop ()
  "Tab to next tab-stop and set left margin."
  (interactive)
  (tab-to-tab-stop)
  (setq left-margin (current-column))
)
  
(defun ess-sas-toggle-sas-log-mode (&optional force)
  "Toggle SAS-log-mode for .log files."
  (interactive)

  (if force (progn
	      (setq auto-mode-alist (append '(("\\.log\\'" . SAS-log-mode)) auto-mode-alist))
	      (setq auto-mode-alist (append '(("\\.LOG\\'" . SAS-log-mode)) auto-mode-alist)))
    
    (if (or (equal (prin1-to-string (cdr (assoc "\\.log\\'" auto-mode-alist))) "SAS-log-mode")
	    (equal (prin1-to-string (cdr (assoc "\\.LOG\\'" auto-mode-alist))) "SAS-log-mode"))
	(progn (setq auto-mode-alist (delete '("\\.log\\'" . SAS-log-mode) auto-mode-alist))
	       (setq auto-mode-alist (delete '("\\.LOG\\'" . SAS-log-mode) auto-mode-alist)))
      (setq auto-mode-alist (append '(("\\.log\\'" . SAS-log-mode)) auto-mode-alist))
      (setq auto-mode-alist (append '(("\\.LOG\\'" . SAS-log-mode)) auto-mode-alist))))
  
  (if (or (equal (file-name-extension (buffer-file-name)) "log")
	  (equal (file-name-extension (buffer-file-name)) "LOG"))
    (progn (font-lock-mode 0)
	   (normal-mode)
	   (if (not (equal (prin1-to-string major-mode) "ess-mode"))
	       (ess-transcript-minor-mode 0))
	   (font-lock-mode 1))))

(defun ess-sleep ()
"Put emacs to sleep for `ess-sleep-for' seconds.
Sometimes its necessary to wait for a shell prompt."
(if (featurep 'xemacs) (sleep-for ess-sleep-for)
       (sleep-for 0 (truncate (* ess-sleep-for 1000)))
    )
)

;;; Section 3:  Key Definitions

(defvar ess-sas-edit-keys-toggle 0
  "0 to bind TAB to `sas-indent-line'.
  Positive to bind TAB to `ess-sas-tab-to-tab-stop', 
  C-TAB to `ess-sas-backward-delete-tab', and
  RET to `newline'.")

(defun ess-sas-edit-keys-toggle (&optional arg)
  "Toggle TAB key in `SAS-mode'.
If first arg is 0, TAB is `sas-indent-line'.
If first arg is positive, TAB is `ess-sas-tab-to-tab-stop', 
C-TAB is `ess-sas-backward-delete-tab' and
RET is `newline'.
Without args, toggle between these options."
  (interactive "P")
  (setq ess-sas-edit-keys-toggle
	(if (null arg) (not ess-sas-edit-keys-toggle)
	  (> (prefix-numeric-value arg) 0)))
  (if ess-sas-edit-keys-toggle
      (progn
	(if (and (equal emacs-major-version 19) (equal emacs-minor-version 28))
	       (define-key sas-mode-local-map [C-tab] 'ess-sas-backward-delete-tab)
	    ;else
	       (define-key sas-mode-local-map [(control tab)] 'ess-sas-backward-delete-tab))
	;else
        (define-key sas-mode-local-map [return] 'newline)
	(define-key sas-mode-local-map "\t" 'ess-sas-tab-to-tab-stop))
    (define-key sas-mode-local-map "\t" 'sas-indent-line)))

(defvar ess-sas-global-pc-keys nil
  "Non-nil if function keys use PC-like SAS key definitions in all modes.")
(defun ess-sas-global-pc-keys ()
  "PC-like SAS key definitions"
  (interactive)
  (global-set-key (quote [f2]) 'ess-revert-wisely)
  (global-set-key (quote [f3]) 'shell)
  (global-set-key (quote [f4]) 'ess-sas-goto-file-1)
  (global-set-key (quote [f5]) 'ess-sas-goto-sas)
  (global-set-key (quote [f6]) 'ess-sas-goto-log)
  (global-set-key [(control f6)] 'ess-sas-append-log)
  (global-set-key (quote [f7]) 'ess-sas-goto-lst)
  (global-set-key [(control f7)] 'ess-sas-append-lst)
  (global-set-key (quote [f8]) 'ess-sas-submit)
  (global-set-key [(control f8)] 'ess-sas-submit-region)
  (global-set-key (quote [f9]) 'ess-sas-data-view)
  (global-set-key (quote [f10]) 'ess-sas-toggle-sas-log-mode)
  (define-key sas-mode-local-map "\C-c\C-p" 'ess-sas-file-path))

(defvar ess-sas-global-unix-keys nil
  "Non-nil if function keys use Unix-like SAS key definitions in all modes.")
(defun ess-sas-global-unix-keys ()
  "Unix/Mainframe-like SAS key definitions"
  (interactive)
  (global-set-key (quote [f2]) 'ess-revert-wisely)
  (global-set-key (quote [f3]) 'ess-sas-submit)
  (global-set-key [(control f3)] 'ess-sas-submit-region)
  (global-set-key (quote [f4]) 'ess-sas-goto-sas)
  (global-set-key (quote [f5]) 'ess-sas-goto-log)
  (global-set-key [(control f5)] 'ess-sas-append-log)
  (global-set-key (quote [f6]) 'ess-sas-goto-lst)
  (global-set-key [(control f6)] 'ess-sas-append-lst)
  (global-set-key (quote [f7]) 'ess-sas-goto-file-1)
  (global-set-key (quote [f8]) 'shell)
  (global-set-key (quote [f9]) 'ess-sas-data-view)
  (global-set-key (quote [f10]) 'ess-sas-toggle-sas-log-mode)
  (global-set-key (quote [f11]) 'ess-sas-goto-file-2)
	(if (and ess-sas-edit-keys-toggle
	    (equal emacs-major-version 19) (equal emacs-minor-version 28))
	    (global-set-key [C-tab] 'ess-sas-backward-delete-tab)
	    ;else
	    (global-set-key [(control tab)] 'ess-sas-backward-delete-tab))
  (define-key sas-mode-local-map "\C-c\C-p" 'ess-sas-file-path))

(defvar ess-sas-local-pc-keys nil
  "Non-nil if function keys use PC-like SAS key definitions
in SAS-mode and related modes.")
(defun ess-sas-local-pc-keys ()
  "PC-like SAS key definitions."
  (interactive)
  (define-key sas-mode-local-map (quote [f2]) 'ess-revert-wisely)
  (define-key sas-mode-local-map (quote [f3]) 'shell)
  (define-key sas-mode-local-map (quote [f4]) 'ess-sas-goto-file-1)
  (define-key sas-mode-local-map (quote [f5]) 'ess-sas-goto-sas)
  (define-key sas-mode-local-map (quote [f6]) 'ess-sas-goto-log)
  (define-key sas-mode-local-map [(control f6)] 'ess-sas-append-log)
  (define-key sas-mode-local-map (quote [f7]) 'ess-sas-goto-lst)
  (define-key sas-mode-local-map [(control f7)] 'ess-sas-append-lst)
  (define-key sas-mode-local-map (quote [f8]) 'ess-sas-submit)
  (define-key sas-mode-local-map [(control f8)] 'ess-sas-submit-region)
  (define-key sas-mode-local-map (quote [f9]) 'ess-sas-data-view)
  (define-key sas-mode-local-map (quote [f10]) 'ess-sas-toggle-sas-log-mode)
  (define-key sas-mode-local-map (quote [f11]) 'ess-sas-goto-file-2)
  (define-key sas-mode-local-map "\C-c\C-p" 'ess-sas-file-path))

(defvar ess-sas-local-unix-keys nil
  "Non-nil if function keys use Unix-like SAS key definitions
in SAS-mode and related modes.")
(defun ess-sas-local-unix-keys ()
  "Unix/Mainframe-like SAS key definitions"
  (interactive)
  (define-key sas-mode-local-map (quote [f2]) 'ess-revert-wisely)
  (define-key sas-mode-local-map (quote [f3]) 'ess-sas-submit)
  (define-key sas-mode-local-map [(control f3)] 'ess-sas-submit-region)
  (define-key sas-mode-local-map (quote [f4]) 'ess-sas-goto-sas)
  (define-key sas-mode-local-map (quote [f5]) 'ess-sas-goto-log)
  (define-key sas-mode-local-map [(control f5)] 'ess-sas-append-log)
  (define-key sas-mode-local-map (quote [f6]) 'ess-sas-goto-lst)
  (define-key sas-mode-local-map [(control f6)] 'ess-sas-append-lst)
  (define-key sas-mode-local-map (quote [f7]) 'ess-sas-goto-file-1)
  (define-key sas-mode-local-map (quote [f8]) 'shell)
  (define-key sas-mode-local-map (quote [f9]) 'ess-sas-data-view)
  (define-key sas-mode-local-map (quote [f10]) 'ess-sas-toggle-sas-log-mode)
  (define-key sas-mode-local-map (quote [f11]) 'ess-sas-goto-file-2)
  (define-key sas-mode-local-map "\C-c\C-p" 'ess-sas-file-path))


(provide 'essa-sas)

 ; Local variables section

;;; This file is automatically placed in Outline minor mode.
;;; The file is structured as follows:
;;; Chapters:     ^L ;
;;; Sections:    ;;*;;
;;; Subsections: ;;;*;;;
;;; Components:  defuns, defvars, defconsts
;;;              Random code beginning with a ;;;;* comment

;;; Local variables:
;;; mode: emacs-lisp
;;; outline-minor-mode: nil
;;; mode: outline-minor
;;; outline-regexp: "\^L\\|\\`;\\|;;\\*\\|;;;\\*\\|(def[cvu]\\|(setq\\|;;;;\\*"
;;; End:

;;; essa-sas.el ends here
