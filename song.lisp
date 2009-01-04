(in-package :musik)

(defun make-drums (&optional (group *workspace*))
  ; basic bassdrum/snare pattern
  (flatten
   (loop for measure in (filter-by-tag group :type "measure")
      for i from 0
      collect
	(list 
	 (simple-hit (span-start measure) '(:type "note"
					    :note 55))
	 (simple-hit (+ 1000 (span-start measure)) '(:type "note"
						  :note 57))))))

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

;;;   (midi-reset)
;;;   (midi-play-group *workspace*)
