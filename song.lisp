(in-package :musik)

(defun make-drums (&optional (group *workspace*))
  ; basic bassdrum/snare pattern
  (trim
   (loop for measure in (filter-by-tag group :type "measure")
      for m from 0
      collect
	(list
	 (loop for rhythm in (make-spans-over-type "beat" (if (evenp m) '(3 2) '(2 2)) measure)
	    for r from 0
	    collect
	      (if (evenp r)
		  (simple-hit (span-start rhythm) 55)
		  (simple-hit (span-start rhythm) 57)))
	 (if (= 0 (mod m 4))
	     (simple-hit (span-start measure) 59))))))

(progn
  (setf *workspace* nil)
  (setf *bpm* 120)

  (loop for count below 2
       do
       (setf *workspace* (append-to-group *workspace* 
					  (make-beats 30 *bpm*))))
  
  (add-to-group *workspace*
		(set-tags '(:type "measure" :label "m")
			  (make-spans-over-type "beat" '(5 4 5 5))))

  (add-to-group *workspace* (make-drums)))

