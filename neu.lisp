(load "pipe.lisp")

(defpackage :musik (:use :cl))
(in-package :musik)

;; defines

(defvar *samplerate* 44100)
(defvar *piano* 0)
(defvar *drums* 1)

(defparameter -kick 36)
(defparameter -rim 37)
(defparameter -snare 38)
(defparameter -hic 42)
(defparameter -hio 46)
(defparameter -ride 51)
(defparameter -crash 57)

;; datastruct

(defclass spanset ()
  ((spans :accessor spans
	  :initform '()
	  :initarg :spans)))

(defun make-spanset (form)
  (make-instance 'spanset :spans form))

;; internal functions
(defun span-shift (span func &optional func2)
	    (let ((new (copy-list span)))
	      (setf (getf new :start) (funcall func (getf new :start)))
	      (setf (getf new :end) (funcall (or func2 func) (getf new :end)))
	      new))

(defun span-midi (span)
  (list 
   (list (floor (getf span :start))
	 (+ #x90 (getf span :channel))
	 (or (getf span :note)) 60
	 (or (getf span :vel) 127))
   (list (floor (getf span :end))
	 (+ #x80 (getf span :channel))
	 (or (getf span :note)) 60
	 (or (getf span :vel) 127))))

;; methods

(defmethod set-length ((set spanset))
  (reduce (lambda (x y)
	    (max x (getf y :end)))
	  (spans set)
	  :initial-value 0))

(defmethod join (&rest list)
  "merge two sets"
  (make-spanset
   (labels ((get-spans (setlist)
	      (if setlist
		  (nconc (spans (first setlist))
			 (get-spans (rest setlist))))))
     (get-spans (trim list)))))

(defmethod on-each ((set spanset) func)
  (make-spanset 
   (map 'list (lambda (x)
		(funcall func x))
	(spans set))))

(defmethod offset (amount (set spanset))
  (on-each set (lambda (x) (span-shift x (lambda (x) (+ x amount))))))

(defmethod scale (amount (set spanset))
  (on-each set (lambda (x) (span-shift x (lambda (x) (* x amount))))))

(defmacro scale-bpm (bpm spanset)
  `(scale ,(/ (* *samplerate* 60) bpm) ,spanset))

(defun seq (&rest list)
  (make-spanset
   (labels ((seq-sets (setlist &optional (amount 0))
	      (if setlist
		  (let ((length (set-length (first setlist))))
			(nconc (spans (offset amount (first setlist)))
			       (seq-sets (rest setlist) (incf amount length)))))))
     (seq-sets (trim list)))))

(defmethod add-keys (keys (set spanset))
  (declare (indent defun))
  (on-each set (lambda (x)
		 (let ((span (copy-list x)))
		   (loop for (key val) on keys by #'cddr
		      :do (setf (getf span key) val))
		   span))))

;; multi macro

(defmacro n-of (times &rest what)
  (let ((w (gensym)))
    `(loop for ,(gensym) below ,times
	:collect 
	  (loop for ,w in ',what
	     :collect (eval ,w)))))

(defmacro maybe (chance &rest what)
  (let ((w (gensym)))
    `(if (> ,chance (random 1.0))
	 (loop for ,w in ',what
	    :collect (eval ,w)))))

(defmacro s-of (times &rest what)
  `(seq (n-of ,times ,@what)))

;; output functions
(defmethod dump-midi ((set spanset))
  (sort
   (reduce 'nconc 
	   (map 'list (lambda (x) (span-midi x)) (spans set)))
   (lambda (x y) (< (first x) (first y)))))

; helpers

(defun clean (list)
  (loop for s in list
       when s collect it))

(defun trim (list)
  (clean (flatten list)))

(defun flatten (tree &rest rest)
  (if rest 
      (flatten (list tree rest))
      (if (atom tree)
	  (list tree)
	  (nconc (flatten (car tree))
		 (if (cdr tree) (flatten (cdr tree)))))))

; standard types
(defun single (spanform)
  (make-spanset (list spanform)))

(defun make-span (length &optional keys)
  (add-keys keys
	    (single `(:start 0 :end ,length))))

(defun multi-spans (lengths &optional keys)
  (labels ((multi (lengths)
	     (if lengths
		 (cons (make-span (first lengths) keys)
		       (multi (rest lengths))))))
    (multi lengths)))


(defun make-note (length note &optional (vel 100))
  (single `(:type "note" :start 0 :end ,length :note ,note :vel ,vel)))

(setf +songstructure
 '(add-keys '(:type "measure" :key "C")
	   (seq
	    (n-of 4
		     (seq 
		      (multi-spans '(5 4 5 5)))))))

(spans (eval +songstructure))

(setf +drumbeat 
      '(seq
	(join
	 (make-note 1 -kick)
	 (maybe .7 (make-note 1 -crash)))
	(make-note 1 -kick)
	(make-note 1 -snare)
	(seq 
	 (s-of (+ 1 (random 3))
	  (make-note .5 -hio)
	  (make-note .5 -rim))
	 (maybe .5 (s-of 2 (make-note .5 -snare))))))

(setf +piano '(seq
	       (maybe .9
		(join
		 (make-note 1 43)
		 (make-note 1 47)))
	       (join
		(make-note (+ (random 2) 2) (+ (random 4) 45))
		(make-note (+ (random 2) 2) 40))))

;; ehu ehu ehu

(play (scale-bpm 120
	     (join
	      (add-keys `(:channel ,*piano*)
			(s-of 16 (eval +piano)))
	      (add-keys `(:channel ,*drums*)
			(s-of 12 (eval +drumbeat))))))