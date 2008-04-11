;;; essd-jags.el -- ESS[JAGS] dialect

;; Copyright (C) 2006-2008 Rodney Sparapani

;; Original Author: Rodney Sparapani <rsparapa@mcw.edu>
;; Created: 16 August 2006
;; Maintainers: ESS-help <ess-help@stat.math.ethz.ch>

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

(require 'essl-bugs)
(require 'ess-utils)
(require 'ess-inf)

(setq auto-mode-alist 
    (delete '("\\.[bB][uU][gG]\\'" . ess-bugs-mode) auto-mode-alist))

(setq auto-mode-alist 
    (append '(("\\.[bB][uU][gG]\\'" . ess-jags-mode)) auto-mode-alist))

(defvar ess-jags-command "jags")
(make-local-variable 'ess-jags-command)

(defvar ess-jags-monitor '(""))
(make-local-variable 'ess-jags-monitor)

(defvar ess-jags-thin 1)
(make-local-variable 'ess-jags-thin)

(defvar ess-jags-chains 1)
(make-local-variable 'ess-jags-chains)

(defvar ess-jags-global-monitor nil)

(defvar ess-jags-global-chains nil)

(defvar ess-jags-font-lock-keywords
    (list
	;; .bug files
	(cons "#.*\n"			font-lock-comment-face)

	(cons "^[ \t]*\\(model\\|var\\)\\>"
					font-lock-keyword-face)

	(cons (concat "\\<d\\(bern\\|beta\\|bin\\|cat\\|chisq\\|"
		"dexp\\|dirch\\|exp\\|\\(gen[.]\\)?gamma\\|hyper\\|"
		"interval\\|lnorm\\|logis\\|mnorm\\|mt\\|multi\\|"
		"negbin\\|norm\\(mix\\)?\\|par\\|pois\\|sum\\|t\\|"
		"unif\\|weib\\|wish\\)[ \t\n]*(")
					font-lock-reference-face)

	(cons (concat "\\<\\(abs\\|cos\\|dim\\|\\(i\\)?cloglog\\|equals\\|"
		"exp\\|for\\|inprod\\|interp[.]line\\|inverse\\|length\\|"
		"\\(i\\)?logit\\|logdet\\|logfact\\|loggam\\|max\\|mean\\|"
		"mexp\\|min\\|phi\\|pow\\|probit\\|prod\\|rank\\|round\\|"
		"sd\\|sin\\|sort\\|sqrt\\|step\\|sum\\|t\\|trunc\\|T\\)[ \t\n]*(")
					font-lock-function-name-face)

	;; .jmd files
	(cons (concat "\\<\\(adapt\\|cd\\|clear\\|coda\\|data\\|dir\\|"
		"exit\\|in\\(itialize\\)?\\|load\\|model\\|monitors\\|parameters\\|"
		"pwd\\|run\\|samplers\\|to\\|update\\)[ \t\n]")
					font-lock-keyword-face)

	(cons "\\<\\(compile\\|monitor\\)[, \t\n]"
					font-lock-keyword-face)

	(cons "[, \t\n]\\(by\\|chain\\|nchains\\|stem\\|thin\\|type\\)[ \t\n]*("
					font-lock-function-name-face)
    )
    "ESS[JAGS]: Font lock keywords."
)

(defun ess-jags-switch-to-suffix (suffix)
   "ESS[JAGS]: Switch to file with suffix."
   (find-file (concat ess-bugs-file-dir ess-bugs-file-root suffix))

   (if (equal 0 (buffer-size)) (progn
	(if (equal ".bug" suffix) (progn
	    (insert "var ;\n")
	    (insert "model {\n")
            (insert "    for (i in 1:N) {\n    \n")
            (insert "    }\n")
            (insert "}\n")
	    (insert "#Local Variables" ":\n")
	    (insert "#ess-jags-chains:1\n")
	    (insert "#ess-jags-monitor:(\"\")\n")
	    (insert "#ess-jags-thin:1\n")
	    (insert "#End:\n")
	))

	(if (equal ".jmd" suffix) (progn
	    (insert "model in \"" ess-bugs-file-root ".bug\"\n")
	    (insert "data in \"" ess-bugs-file-root ".txt\"\n")
	    (insert (ess-replace-in-string ess-jags-global-chains "##" "in"))
	    (insert "initialize\n")
	    (insert "update " ess-bugs-default-burn-in "\n")
	    (insert ess-jags-global-monitor)
	    (insert "update " ess-bugs-default-update "\n")
	    (insert (ess-replace-in-string 
		(ess-replace-in-string ess-jags-global-chains 
		    "compile, nchains([0-9]+)" "#") "##" "to"))
	    (insert "coda " 
		(if ess-microsoft-p (if (w32-shell-dos-semantics) "*" "\\*") "\\*") 
		", stem(\"" ess-bugs-file-root "\")\n")
	    (insert "exit\n")
	    (insert "Local Variables" ":\n")
	    ;(insert "ess-jags-chains:" (format "%d" ess-jags-chains) "\n")
	    (insert "ess-jags-command:\"jags\"\n")
	    (insert "End:\n")
	))
    ))
)

(defun ess-bugs-next-action ()
   "ESS[JAGS]: Perform the appropriate next action."
   (interactive)
   (ess-bugs-file)

   (if (equal ".bug" ess-bugs-file-suffix) (ess-jags-na-bug))
   ;;else
   (if (equal ".jmd" ess-bugs-file-suffix) (progn
	(ess-save-and-set-local-variables)
	(ess-jags-na-jmd ess-jags-command)))
)

(defun ess-jags-na-jmd (jags-command)
    "ESS[JAGS]: Perform the Next-Action for .jmd."
    ;(ess-save-and-set-local-variables)
(if (equal 0 (buffer-size)) (ess-jags-switch-to-suffix ".jmd") 
    (shell)

    (if (w32-shell-dos-semantics)
	(if (string-equal ":" (substring ess-bugs-file 1 2))
	    (progn
		(insert (substring ess-bugs-file 0 2))
		(comint-send-input)
	    )
	)
    )

	(insert "cd \"" ess-bugs-file-dir "\"")
	(comint-send-input)

	(insert ess-bugs-batch-pre-command " " jags-command " "
		ess-bugs-file-root ".jmd "  

		(if (or (equal shell-file-name "/bin/csh") 
			(equal shell-file-name "/bin/tcsh")
			(equal shell-file-name "/bin/zsh")) 
			    (concat ">& " ess-bugs-file-root ".out ")
		;else
			    "> " ess-bugs-file-root ".out 2>&1 ") 

		;.txt not recognized by BOA and impractical to over-ride
		"&& (if [ -f " ess-bugs-file-root "index.ind ]; then "
		"rm -f " ess-bugs-file-root "index.ind; fi; "
		"ln -s " ess-bugs-file-root "index.txt " ess-bugs-file-root "index.ind) "
		"&& (for i in 1 2 3 4 5 6 7 8 9; do; "
		"if [ -f " ess-bugs-file-root "chain$i.txt ]; then "
		"if [ -f " ess-bugs-file-root "chain$i.out ]; then "
		"rm -f " ess-bugs-file-root "chain$i.out; fi; "
		"ln -s " ess-bugs-file-root "chain$i.txt " ess-bugs-file-root "chain$i.out; "
		"fi; done)"
	    
		;(while (< 0 ess-jags-chains)
		;    (concat "&& ln -s " ess-bugs-file-root "chain" 
		;	(format "%d" ess-jags-chains) ".txt " 
		;	ess-bugs-file-root "chain"
		;	(format "%d" ess-jags-chains) ".out ")
		;    (setq ess-jags-chains (- ess-jags-chains 1)))

		ess-bugs-batch-post-command)

	(comint-send-input)
))

(defun ess-jags-na-bug ()
    "ESS[JAGS]: Perform Next-Action for .bug"

	(if (equal 0 (buffer-size)) (ess-jags-switch-to-suffix ".bug")
	;else
	    (ess-save-and-set-local-variables)
   
	    (setq ess-jags-global-chains 
		(concat "compile, nchains(" (format "%d" ess-jags-chains) ")\n"))

	    (while (< 0 ess-jags-chains)
		(setq ess-jags-global-chains 
		    (concat ess-jags-global-chains
			"parameters ## \"" ess-bugs-file-root 
			".##" (format "%d" ess-jags-chains) "\", chain("
			(format "%d" ess-jags-chains) ")\n"))
		(setq ess-jags-chains (- ess-jags-chains 1)))
 
	    (setq ess-jags-global-monitor nil)

		(while (and (listp ess-jags-monitor) (consp ess-jags-monitor))
		    (setq ess-jags-global-monitor 
			(concat ess-jags-global-monitor 
			    "monitor " (car ess-jags-monitor) 
			    ", thin(" (format "%d" ess-jags-thin) ")\n"))
		    (setq ess-jags-monitor (cdr ess-jags-monitor)))

	    (ess-jags-switch-to-suffix ".jmd"))
)

(defun ess-jags-mode ()
   "ESS[JAGS]: Major mode for JAGS."
   (interactive)
   (kill-all-local-variables)
   (setq major-mode 'ess-jags-mode)
   (setq mode-name "ESS[JAGS]")
   (use-local-map ess-bugs-mode-map)
   (setq font-lock-auto-fontify t)
   (make-local-variable 'font-lock-defaults)
   (setq font-lock-defaults '(ess-jags-font-lock-keywords nil t))
   (run-hooks 'ess-bugs-mode-hook)

   (if (not (w32-shell-dos-semantics))
	(add-hook 'comint-output-filter-functions 'ess-bugs-exit-notify-sh))
)

(setq features (delete 'essd-bugs features))
(provide 'essd-jags)
