(in-package :musik)

;; parameters

(defconstant +token-print-cmd-line+ #\Esc)

(defparameter *sclang-process* nil)
(defparameter *sclang-keywords* nil)
(defparameter *sclang-converters* nil)

;; case sensitive reader macro

(set-macro-character #\!
		     #'(lambda (stream char)
			 (let ((*readtable* (copy-readtable)))
			   (setf (readtable-case *readtable*) :preserve)
			   (read stream t nil t))))

;; helper functions

(defun flatstr (&rest items)
  "concatenate a tree of strings"
  (let ((res ""))
    (dolist (x items)
      (setf res (concatenate 'string res
			     (if (listp x) (apply 'flatstr x) x))))
    res))

;; process

(defun sclang-start ()
  (sb-ext:run-program "/bin/sh" '("wrapper.sh") :input :stream :output t :error t :wait nil)
  (sleep 10)
  (send-sc-command "s.reboot"))

(when nil (sclang-start))

(defun send-sc-command (command)
  (format t "sending command: ~a~%" command)
  (with-open-file (foo "/tmp/sclangfifo" 
		       :direction :output 
		       :if-exists :append)
    (write-line command foo)))

;; converters

(defun commasep (args)
  "comma separate a list of strings"
  (reduce (lambda (x y) 
	    (flatstr x
		     ;; hack. if last char of string is a colon
		     ;; it's a keyword, thus no comma...
		     (if (and x (eq (elt x (- (length x) 1)) #\:)) " " ", ")
		     y))
	  args))

(defun convert (form)
  (cond ((listp form)
	 (apply
	  (or (getf *sclang-converters* (first form))
	      (lambda (&rest args)
		(print args)
		;; convert to fun(arg, arg, arg)
		(flatstr (format nil "~a" (first form)) "(" (commasep args) ")")))
	  (loop for x in (rest form) :collect (convert x))))
	((keywordp form)
	 (format nil "~a:" form))
	((or (numberp form) (symbolp form))
	 (format nil "~a" form))))

(defmacro sclang (form)
  "to aviod having to manually quote lists"
  (if (listp form)
      `(convert (quote ,form))
      `(convert ,form)))

(defmacro defconverter (symbol args &body body)
  `(setf (getf *sclang-converters* (quote ,symbol))
	 (lambda ,args
	   ,@body)))

(defmacro definfix (symbol)
  `(defconverter ,symbol (&rest args)
     (flatstr "(" (first args)
	      (map 'list (lambda (x) (flatstr (format nil " ~A " (quote ,symbol)) x)) (rest args))
	      ")")))

;; basic language definitions

(progn
  ; standard arithmetic
  (definfix +)
  (definfix -)
  (definfix *)
  (definfix /)
  (defconverter !list (&rest args)
    (flatstr "[" (commasep args) "]")))
