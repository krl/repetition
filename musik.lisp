;;{{{ package
(require 'asdf)
(require 'cl-who)
(require 'hunchentoot)

(defpackage :musik (:use :cl :cl-who :hunchentoot :cl-ppcre :sb-bsd-sockets))

(in-package :musik)

;;}}}

(defvar *workspace* nil)
(defvar *samplerate* 44100)

;;{{{ datastructures

(defstruct span
  start
  end
  tags)

(defun span-length (span)
  (- (span-end span)
     (span-start span)))

(defun span-tag (span tag)
  (getf (span-tags span) tag))

;;{{{ span manipulation

(defun span-set-tags (span tags)
  (setf (span-tags span)
	(append (span-tags span) tags))
  span)

(defun simple-span (start end &optional tags)
  (make-span :start start :end end :tags tags))

(defun simple-hit (start note)
  (make-span :start start :end start :tags `(:type "note" :note ,note)))

(defun set-tags (tags spans)
  (loop for s in spans
       collect
       (simple-span (span-start s) (span-end s) tags)))

;;}}}
;;{{{ misc helper functions

(defun rotate-list (list)
  (append (rest list) (list (first list))))

(defun note-from-name (name)
  (cond ((string= name "kick") 36)
	((string= name "rim") 37)
	((string= name "snare") 38)
	((string= name "hi c") 42)
	((string= name "hi o") 46)
	((string= name "ride") 51)
	((string= name "crash") 57)
	(t (error "illegal name"))))

(defun perc (time name vel)
  (simple-span time time `(:type "note"
				 :note ,(note-from-name name)
				 :channel 1
				 :vel ,vel)))

(defun fracspan (span fraction)
  (+ (span-start span)
     (* (span-length span) fraction)))

(defun clean (group)
  (loop for s in group
       when s collect it))

(defun trim (what)
  (clean (flatten what)))

(defun flatten (tree &rest rest)
  (if rest 
      (flatten (list tree rest))
      (if (atom tree)
	  (list tree)
	  (nconc (flatten (car tree))
		 (if (cdr tree) (flatten (cdr tree)))))))

(defmacro add-to-group (group what)
  `(setf ,group (nconc ,group ,(if (listp what) what (list what)))))

(defun normalize (group)
  (offset group (- (span-start (group-fullspan group)))))
 
(defun listify (what)
  (if (listp what)
      what
      (list what)))
	   
(defun append-to-group (group what)
  (let ((result  (loop for w in (flatten what)
		    collect 
		      (offset w (get-end group)))))
    (flatten (if group
		 (list group result)
		 result))))	     


;;}}}

;;{{{ generators

(defun make-beats (howmany &optional (bpm 120))
  (let ((offset 0)
	(length (/ (* *samplerate* 60) bpm)))
    (loop :while (>= (decf howmany) 0) 
       :collect
	 (make-span :start offset :end (incf offset length) :tags `(:type "beat")))))

(defun make-span-over-type (type count &optional (inspan (group-fullspan *workspace*)))
  (let ((list (sort-by-start (filter-by-tag 
			      (within-span *workspace* inspan) 
			      :type type))))
    (let ((endspan (nth (- count 1) list)))
      (simple-span (span-start (first list))
		   (if endspan
		       (span-end endspan)
		       (span-end inspan))))))

(defun make-spans-over-type (type distribution &optional (inspan (group-fullspan *workspace*)))
  (when (> (span-length inspan) 0)
    (let ((span (make-span-over-type type (first distribution) inspan)))
      (append (list span)
	      (make-spans-over-type type (rotate-list distribution) (simple-span (+ (span-start inspan) (span-length span)) (span-end inspan)))))))

;;}}}

;;{{{ sorters/filters

(defun group-fullspan (group)
  (if (listp group)
      (make-span :start (span-start (first (sort-by-start group)))
		 :end (span-end (first (sort-by-end group))))

      (make-span :start (span-start group)
		 :end (span-end group))))

(defun sort-by-tag (group tag)
  (if (listp group)
      (sort group (lambda (x y)
		    (string> (span-tag x tag)
			     (span-tag y tag))))
      group))

(defun sort-by-start (group)
  (if (listp group)
      (sort (copy-list group) (lambda (x y) (< (span-start x) (span-start y))))
      group))

(defun sort-by-end (group)
  (if (listp group)
      (sort (copy-list group) (lambda (x y) (> (span-end x) (span-end y))))
      group))

(defun filter-by-tag (group tag shouldbe)
  (loop for span in group
     if (equal (span-tag span tag) shouldbe)
       collect span))

(defun within-span (group within)
  (loop for span in group
     if (and (>= (span-start span)
		 (span-start within))
	     (<  (span-start span)
 		 (span-end within)))
       collect span))
	    
;;}}}

;;{{{ change group's

(defun offset (what by)
  (if (listp what)
      (loop for span in what
	 collect (offset span by))
      (make-span :start (+ (span-start what) by)
		 :end (+ (span-end what) by)
		 :tags (span-tags what))))

;;}}}
;;{{{ get-info group

(defun get-end (group)
  (if group
      (span-end
       (first
	(sort (copy-list group) (lambda (x y)
		      (> (span-end x) (span-end y))))))
      0))

;;;(defun get-end (group)
;;;   (let ((largest 0))
;;;     (cond ((not what)
;;; 	   (setf largest 0))
;;; 	  ((listp what)
;;; 	   (loop for span in what do
;;; 		(let ((test (span-end span)))
;;; 		  (if (> test largest)
;;; 		      (setf largest test)))))
;;; 	  (t (setf largest (span-end what))))
;;;     largest))

;;}}}

;;{{{ get-info span

(defun spanning-this (group what)
  (remove-if-not (lambda (x)		
		   (and (not (eq x what)) ;; not itself
			(or 			     
			 (and ;; cleanly within
			  (< (span-start x) (span-start what))
			  (> (span-end x) (span-start what)))
			 (and ;; same-start but bigger (or equal size)
			  (= (span-start x) (span-start what))
			  (or 
			   (> (span-end x) (span-end what))
			   (and 
			    (= (span-end x) (span-end what))
			    (string> (span-tag x :label) (span-tag what :label))))))))
		 group))

;;}}}

