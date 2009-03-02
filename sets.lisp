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
     (join-r (flatten list)))))


;; this is a bit hairy, might have to rethink...
(defmacro over-each (set &body what) 
  (let ((insert (subst '(first spanlist) '$over 
		       (subst '(second spanlist) '$next
			      (subst 'prev '$prev what)))))
    `(labels ((over-each-r (spanlist &optional prev)
		(if spanlist   
		        (cons
			 (offset (span-get (first spanlist) :start)
				 ,@insert)
			 (over-each-r (rest spanlist) (first spanlist))))))
      (join (over-each-r (spans ,set))))))

(defmethod on-each ((set spanset) func)
  (make-spanset
   (remove nil
	   (map 'list (lambda (x)
			(funcall func x))
		(spans set)))))

(defmethod offset (amount (set spanset))
  (on-each set (lambda (x) (span-shift x (lambda (x) (+ x amount))))))

(defmethod trim (length (set spanset))
  (on-each set (lambda (x)
		 (if (< (span-get x :start) length)
		     (if (> (span-get x :end) length)
			 (span-set x :end length)
			 x)))))

(defmethod scale (amount (set spanset))
  (on-each set (lambda (x) (span-shift x (lambda (x) (* x amount))))))

(defmacro scale-bpm (bpm spanset)
  `(scale ,(/ (* 44100 60) bpm) ,spanset))

(defun seq (&rest list)
  (make-spanset
   (labels ((seq-r (setlist &optional (amount 0))
	      (if setlist
		  (let ((length (set-length (first setlist))))
			(nconc (spans (offset amount (first setlist)))
			       (seq-r (rest setlist) (incf amount length)))))))
     (seq-r (flatten list)))))

(defun seq-space (space &rest list)
  (make-spanset
   (labels ((seq-r (setlist &optional (n 0))
	      (if setlist
		  (nconc (spans (offset (* n space) (first setlist)))
			 (seq-r (rest setlist) (+ n 1))))))
     (seq-r (flatten list)))))

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

(defmacro n (times &body what) 
  `(labels ((n-of-r (n)
	      (nconc (list ,@what)
		    (if (> n 1) (n-of-r (- n 1))))))
     (n-of-r ,times)))

(defmacro n-of (times &body what) 
  `(join (n ,times ,@what)))

(defmacro s-of (times &body what) 
  `(seq (n ,times ,@what)))


(defmacro maybe (chance &body body)
  `(nif (> ,chance (random 1.0)) ,@body))

(defmacro nif (criteria &body body)
   `(or (if ,criteria
		    ,@body)
	    (nop)))

(defun nop ()
  (make-span 0 '(:type "nop")))

;; output functions
(defmethod dump-midi ((set spanset))
  (sort
   (reduce 'nconc 
	   (map 'list (lambda (x) (span-midi x)) (spans (filter :type "note" set))))
   (lambda (x y) (< (first x) (first y)))))

; helpers

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