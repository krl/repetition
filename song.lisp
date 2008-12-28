(in-package :musik)

(defun make-drums (&optional (inspan (group-fullspan *workspace*)))
   (reduce 'append
	   (loop for span in (filter-by-tag (within-span *workspace* inspan) :type "measure")
	      for i from 0
	      collect
		(within-span (clean ;; removes nil's
			      (list
			       (loop for s in (make-spans-over-type "beat" '(3 2) span)
				  for j from 0
				  collect
				    (if (oddp j)
					(perc (span-start s) "kick" 100)
					(perc (span-start s) "snare" 100)))))
			     span))))


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

  (add-to-group *workspace* (make-drums))

  (midi-reset)
  (midi-play-group *workspace*))