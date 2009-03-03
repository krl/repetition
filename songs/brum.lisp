(require :musik)
(in-package :musik)

(defun song ()
      (add-keys '(:type "measure" :key "Cm")
		(enum
		 (seq
		  (s-of 2
			(multi-spans '(5 4 5 5)))
		  (make-span 5 '(:chord 3))
		  (make-span 3 '(:chord 4))
		  (make-span 3 '(:chord 6))
		  (make-span 6 '(:chord 5))))))

(defun song2 ()
      (add-keys '(:type "measure" :key "Cm")
		(enum
		 (s-of 4
		   (s-of (+ 1 (random 7))
		     (make-span 1 `(:chord ,(+ 1 (random 5)))))
		   (s-of 2
		     (make-span 4 '(:chord 3))
		     (make-span 3 '(:chord 4)))))))
			
(defun bass (env)
  (over-each env
   (nif (> (span-length $over) 4)
	(seq
	 (make-note 1.5 (note 1 $over))
	 (make-note 1   (note 7 $over))
	 (make-note 1   (nif (= (mod (span-get $over :enum) 4) 3)
			    (note 8 $over)
			    (note 6 $over)))
	 (make-note (- (span-length $over) 3.5) (note 5 $over)))
	(seq
	 (make-note 1.5 (note 1 $over))
	 (make-note 1   (note 7 $over))
	 (make-note 1.5 (note 5 $over))))))

(defun piano (env)
  (over-each env
    (let ((length (span-length $over)))
      (trim length
	    (join
	     (seq-space .5
			(make-note length (note 1 $over) 50)
			(maybe .7
			       (make-note length (note 3 $over) 50)
			       (make-note length (note 2 $over) 50))
			(make-note length (note 5 $over) 50)
			(maybe .5 (make-note length (note 7 $over) 50)
			       (make-note length (note 8 $over) 50)))
	     ;; melody
	     (offset .5
		     (make-note 1 (+ 24 (note 1 $over))))
	     (offset (- length 1.5)
		     (make-note 1 (+ 24 (note -1 $next)))))))))

(defun drums (env)
  (over-each env
    (join 
     (make-note 1.5 -kick) ; kick

     (nif (oddp (span-get $over :enum)) ; extra in-leading kick on every other measure
	  (seq
	   (pause (- (span-length $over) .5))
	   (make-note .5 -kick)))

     (nif (zerop (span-get $over :enum)) ; crash on number one
	  (make-note 1.5 -crash))

     (seq ; snare
      (pause 1.5)
      (make-note 1.5 -snare)
      (pause (/ (mod (span-get $over :enum) 4) 2))
      (make-note 1.5 -snare))
     
     (s-of (- (span-length $over) 2) ; hihat clickety
       (make-note 1 -hic))
     
     (seq ;; rimshot chickety
      (pause (- (span-length $over) 2))
      (s-of 2
	(join
	 (make-note .5 -hic)
	 (make-note .5 -rim))
	(make-note .5 -hio))))))

(let ((env (song)))
  (reset)
  (send (scale-bpm 140
		   (seq
		    (pause 2)
		    (s-of 5
			  (join
			   (add-keys `(:channel ,*bass*)
				     (bass env))
			   (add-keys `(:channel ,*piano*)
				     (piano env))
			   (add-keys `(:channel ,*drums*)
				     (drums env))))
		    )))
  (play))