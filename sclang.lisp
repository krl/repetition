(in-package :musik)

;; parameters

(defparameter *sclang-process* nil)
(defparameter *sclang-keywords* nil)
(defparameter *sclang-converters* (make-hash-table :test 'equal))
(defparameter *sclang-cache* (make-hash-table))

;; case sensitive reader macro

(set-macro-character #\!
		     #'(lambda (stream char)
			 (convert
			  (let ((*readtable* (copy-readtable)))
			    (setf (readtable-case *readtable*) :preserve)
			    (read stream t nil t)))))

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
  (sb-ext:run-program "/bin/sh" '("/home/krille/hax/musik/wrapper.sh") :input :stream :output t :error t :wait nil)
  (sleep 2)
  (send-sc-command "s.reboot")
  (sleep 10)
  (maphash (lambda (x y) 
	     (send-sc-command y)) *sclang-cache*))

(when nil (sclang-start))

(defun send-sc-command-cached (index command)
  (setf (gethash index *sclang-cache*) command)
  (send-sc-command command))

(defun send-sc-command (command)
  (format t "Sending command:~%~a~%" command)
  (with-open-file (foo "/tmp/sclangfifo" 
		       :direction :output 
		       :if-exists :append
		       :if-does-not-exist nil)
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
	  (or (gethash (format nil "~(~a~)" (first form)) *sclang-converters*)
	      (lambda (&rest args)
		;; convert to fun(arg, arg, arg)
		(flatstr (format nil "~a" (first form)) "(" (commasep args) ")")))
	  (loop for x in (rest form) :collect (convert x))))
	((keywordp form)
	 (format nil "~a:" form))
	((or (numberp form) (symbolp form))
	 (format nil "~a" form))))

(defmacro defconverter (symbol args &body body)
  `(setf (gethash (format nil "~(~a~)" ',symbol) *sclang-converters*)
	 (lambda ,args
	   ,@body)))

(defconverter list (&rest args)
    (flatstr "[" (commasep args) "]"))

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
  (defconverter list (&rest args)
    (flatstr "[" (commasep args) "]")))
