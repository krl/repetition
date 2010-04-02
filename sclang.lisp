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

(defun convert (form)
  (print (list 'convert form))
  (cond ((listp form)
	 (let ((converter (gethash (format nil "~(~a~)" (first form)) *sclang-converters*)))
	   (if converter
	       (apply converter (rest form))
	       (flatstr (format nil "~a" (first form)) 
			"(" 
			(commasep (map 'list #'convert (rest form))) 
			")"))))
	((keywordp form)
	 (format nil "~a:" form))
	((or (numberp form) (symbolp form))
	 (format nil "~a" form))))

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

(defun scprogn (&rest bodies)
  (map 'list (lambda (x) (flatstr (convert x) "; ")) bodies))

(defmacro defconverter (symbol args &body body)
  `(setf (gethash (format nil "~(~a~)" ',symbol) *sclang-converters*)
	 (lambda ,args
	   ,@body)))

(defmacro definfix (symbol)
  `(defconverter ,symbol (&rest args)
     (let ((args (map 'list #'convert args)))
       (flatstr "(" (first args)
		(map 'list (lambda (x) (flatstr (format nil " ~A " (quote ,symbol)) x)) 
		     (rest args))
		")"))))

;; basic language definitions

(defconverter list (&rest args)
  (flatstr "[" (commasep (map 'list #'convert args)) "]"))

(defconverter let (args &rest body)
  (flatstr
   (reduce (lambda (x y) (flatstr x "var " (convert (first y)) " = " (convert (second y)) "; "))
	   args
	   :initial-value nil)
   (apply #'scprogn body)))

(progn
  ; standard arithmetic
  (definfix +)
  (definfix -)
  (definfix *)
  (definfix /))

