(in-package :musik)

;;{{{ webserver

(if (not (boundp '*server*))
    (setq *server* (start-server :port 1777)))

(push (create-prefix-dispatcher "/musik.svg" 'visualize) *dispatch-table*)
(setf *DEFAULT-CONTENT-TYPE* "image/svg+xml")

(setq *catch-errors-p* nil)

;;}}}

;;{{{ visualization

(defun drawing-pass (span)
  (let ((type (span-tag span :type)))
    (cond 
	((string= type "beat")    0)
	((string= type "measure") 1)
	((string= type "note")    2)
	(t 9000))))

(defun visualize (&optional 
		  (group *workspace*)
		  (width 600)
		  (height 400)
		  (top-key 60)
		  (show-keys 25)
		  (show-beats 4))

  (declare (optimize (debug 3)))

  (let* ((space-x (/ width 100))
	 (space-y (/ height 100))
	 (beats (get-end group))
	 (beat-width (/ width (if (not (= 0 beats)) beats 1) 1.0))
	 (span-height (/ height show-keys 1.0))
	 (group (sort (copy-list group) (lambda (x y) 
				      (< (drawing-pass x)
					 (drawing-pass y))))))

    (with-html-output-to-string (*standard-output*)
      (:svg :xmlns  "http://www.w3.org/2000/svg" :version "1.1"
	    :width  (+ width 50)
	    :height (+ height 40)

	    ;; keyroll

	    (:g :rx 10 :stroke "black" :stroke-width "1px"
		:transform "translate (10,40)"		   
		(loop 
		   for count below show-keys
		   collect 
		     (let ((key-num (- top-key count)))
		       (htm			
			(:rect :x 0 :y (* span-height count) :width 40 :height span-height :fill "#fff")
			(:text :color "#fff" :x 2 :y (- (* span-height (+ count 1)) 3) :width 0
			       (fmt "~A" key-num))))))
		     

	    ;; main group
	    (:g :rx 10 :stroke "black" :stroke-width "1px"
		:transform "translate (50,40)"
		;; first draw container rectangle
		(:rect :x 0 :y 0 :width width :height height :fill "#fcf" :stroke-width 0)
		;; paint the workspace objects
		(loop 
		   for span in group
		   for count from 0
		   collect 
		     (let ((span-x (* (span-start span) beat-width))
			   (span-y (* span-height (length (spanning-this group span))))
			   (type (span-tag span :type))
			   (width (* (span-length span) beat-width)))
		       (cond 
			 ;; is of special type 'beat 'measure
			 ((string= type "beat")
			      (if (oddp count)
				  (htm
				   (:rect :fill "#fff"
					  :style "fill-opacity:0.5;"
					  :stroke-width 0
					  :x span-x :width width 
					  :height height))))
			 ;; is 'endless'
			 ((= (span-start span) (span-end span))
			  (htm
			   (:circle :fill "#f7f" :cx span-x :r (/ span-height 3)
				    :cy (+ (* (- top-key (span-tag span :note)) 
					      span-height)
					   (/ span-height 2)))))
			 ;; otherwise it's a marking span i guess.
			 (t
			  (htm					
			   (:rect :fill "#f7f" :x span-x :y (- (- span-y) span-height) :width width :height span-height)
			   (:text :color "#fff" :x (+ span-x space-x) :y (- (- span-y) 3) :width 0
				  (fmt "~A" (span-tag span :label)))))))))))))

;;}}}