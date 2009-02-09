(load "pipe.lisp")

(defpackage :musik (:use :cl))
(in-package :musik)

;; defines

(defvar *samplerate* 44100)
(defvar *piano* 0)
(defvar *drums* 1)
(defvar *bass* 2)

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

;; span functions
(defun span-get (span key)
  (getf span key))

(defun span-length (span)
  (- (span-get span :end) (span-get span :start)))

(defun span-set (span key what)
  (let ((new span))
    (setf (getf new key) what)
    new))
  

(defun span-shift (span func &optional func2)
  (span-set (span-set span
	     :end (funcall (or func2 func) (span-get span :end)))
	    :start (funcall func (span-get span :start))))

(defun span-midi (span)
  (list
   (list (floor (span-get span :start))
	 (+ #x90 (span-get span :channel))
	 (or (span-get span :note)) 60
	 (or (span-get span :vel) 127))
   (list (floor (span-get span :end))
	 (+ #x80 (span-get span :channel))
	 (or (span-get span :note)) 60
	 (or (span-get span :vel) 127))))

;; methods

(defmethod set-length ((set spanset))
  (reduce (lambda (x y)
	    (max x (span-get y :end)))
	  (spans set)
	  :initial-value 0))

(defmethod join (&rest list)
  "merge two sets"
  (make-spanset
   (labels ((join-r (setlist)
	      (if setlist
		  (nconc (spans (first setlist))
			 (join-r (rest setlist))))))
     (join-r (trim list)))))

(defmacro over-each (set &rest what)
  (let ((insert (subst '(first spanlist) '$over what)))
    `(labels ((over-each-r (spanlist)
		(if spanlist   
		        (cons
			      (offset (span-get (first spanlist) :start)
				           ,@insert)
			          (over-each-r (rest spanlist))))))
      (join (over-each-r (spans ,set))))))

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
   (labels ((seq-r (setlist &optional (amount 0))
	      (if setlist
		  (let ((length (set-length (first setlist))))
			(nconc (spans (offset amount (first setlist)))
			       (seq-r (rest setlist) (incf amount length)))))))
     (seq-r (trim list)))))

(defmethod add-keys (keys (set spanset))
  (on-each set (lambda (x)
		 (labels ((add-keys-r (k)
			    (if k (span-set (add-keys-r (cddr k)) (first k) (second k))
				x)))
		   (add-keys-r keys)))))

(defmethod filter (key value (set spanset))
  (make-spanset
   (loop for s in (spans set)
      when (string= (span-get s key) value) collect s)))

;; multi macro


;; (defmacro n-of (times &rest what)
;;   (labels ((n-of-r (n)
;; 	     (unless (zerop n)
;; 	       (nconc what
;; 		      (n-of-r (- n 1))))))
;;     (let ((insert (n-of-r times)))
;;       (quote what))))

;; (macroexpand-1 '(n-of 3 (make-note 1 1)))

(defmacro n-of (times &rest what)
  (let ((w (gensym)))
    `(loop for ,(gensym) below ,times
	:collect 
	  (loop for ,w in ',what
	     :collect ,w))))



(defmacro maybe (chance &rest what)
   `(if (> ,chance (random 1.0))
	,@what))

(defmacro s-of (times &rest what)
  `(seq (n-of ,times ,@what)))

;; output functions
(defmethod dump-midi ((set spanset))
  (sort
   (reduce 'nconc 
	   (map 'list (lambda (x) (span-midi x)) (spans (filter :type "note" set))))
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
  (labels ((multi-spans-r (lengths &optional (count 0))
	     (if lengths
		 (cons (add-keys `(:enum ,count) (make-span (first lengths) keys))
		       (multi-spans-r (rest lengths) (+ count 1))))))
    (multi-spans-r lengths)))

(multi-spans '(2 2 2))

(defmethod enum ((set spanset))
  (make-spanset 
   (labels ((n-r (list n)
	      (if (rest list)
		  (cons (span-set (first list) :enum n)
			(n-r (rest list) (+ n 1)))
		  (list (span-set (first list) :enum n)))))
     (n-r (spans set) 0))))

(defun make-note (length note &optional (vel 100))
  (single `(:type "note" :start 0 :end ,length :note ,note :vel ,vel)))

(defun pause (length)
  (single `(:type "pause" :start 0 :end ,length)))

;; theory

(defparameter minor '(0 2 3 5 7 8 10)) 
(defparameter major '(0 2 4 5 7 9 10))

(defun note (number context)
  (let* ((base 40)
	 (key minor)
	 (chord (+ (or (span-get context :chord) 1)
		   number -2))
	 (length (length key)))
    (+
     base
     (* 12 (floor (/ number length)))
     (nth (mod chord length) key))))

;; playground

(setf *structure* 
      (add-keys '(:type "measure" :key "Cm")
		(n
		 (seq
		  (s-of 2
			(multi-spans '(5 4 5 5)))		  
		  (make-span 5 '(:chord 3))
		  (make-span 3 '(:chord 4))
		  (make-span 3 '(:chord 6))
		  (make-span 6 '(:chord 5))))))
			      
(setf +bass '(over-each (filter :type "measure" *structure*)
	      (if (> (span-length $over) 4)
		  (seq
		   (make-note 1.5 (note 1 $over))
		   (make-note 1   (note 7 $over))
		   (make-note 1   (if (= (mod (span-get $over :enum) 4) 3)
				      (note 8 $over)
				      (note 6 $over)))
		    (make-note 1.5 (note 5 $over)))
		  (seq
		   (make-note 1.5 (note 1 $over))
		   (make-note 1   (note 7 $over))
		   (make-note 1.5 (note 5 $over))))))

(setf +piano '(over-each *structure*
	       (let ((length (span-length $over)))
		 (join
		  (make-note length (note 1 $over))
		  (if (> (random 1.0) .7)
		      (make-note length (note 2 $over))
		      (make-note length (note 3 $over)))
		  (make-note length (note 5 $over))
		  (maybe .5 (make-note length (note 7 $over)))
		  (seq
		   (pause 1.5)
		   (s-of (- length 2)
			 (let ((rnd (random 7)))
			   (maybe .5 (make-note 1 (+ 24 (note rnd $over))))
			   (maybe .5 (make-note 1 (+ 24 (note (+ rnd 3) $over)))))))))))
			   

(setf +drums '(over-each *structure*
	       (join 
		(seq
		 (join (if (zerop (span-get $over :enum))
			   (make-note 1.5 -crash))
		       (make-note 1.5 -kick))
		 (make-note 1.5 -snare))
		(seq
		 (s-of (- (span-length $over) 2)
		       (make-note 1 -hic))
		 (s-of 2
		       (join
			(make-note .5 -hic)
			(make-note .5 -rim))
		       (make-note .5 -hio))))))

;; (play (scale-bpm 140
;; 		 (s-of 2
;; 		       (join
;;   			(add-keys `(:channel ,*bass*)
;;   				  (eval +bass))
;;  			(add-keys `(:channel ,*piano*)
;;  				  (eval +piano))
;;  			(add-keys `(:channel ,*drums*)
;;  				  (eval +drums))))))
