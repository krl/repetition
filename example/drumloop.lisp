(use-package :repetition)
(sclang-start)

(defparameter *package-path* (namestring (asdf:system-relative-pathname :repetition "/example/samples/")))

;; Samples from altemark@freesound  http://www.freesound.org/packsViewSingle.php?id=2288
;; license: cc Sampling Plus 1.0    http://creativecommons.org/licenses/sampling+/1.0/
(load-samples =bd=    (concatenate 'string *package-path* "bd.wav")
	      =snare= (concatenate 'string *package-path* "snare.wav")
	      =side=  (concatenate 'string *package-path* "side.wav")
	      =ch=    (concatenate 'string *package-path* "ch.wav")
	      =oh=    (concatenate 'string *package-path* "oh.wav"))

(play 
 (join
   ;; kick
   (oneof (lenlist 0.5  =bd=
		   0.5  =bd=)
	  (lenlist 0.25 =bd=
		   0.75 =bd=))

   ;; snare/rim
   (ass ((pan 0.4))
     (oneof (offset 1 =snare=)
	    (offset 0.75 
	      (lenlist 0.25 =side=
		       1    =snare=))))

   ;; pan left
   (ass ((pan -0.4))    
     ;; closed hihat random pattern
     (seq-len 2
       (ass ((len (oneof 0.5 0.25))
	     (amp (+ 0.3 (random 0.4))))
	 =ch=))
     
     ;; open hihat
     (offset (oneof 1.75 1.5)
       (ass ((len 0))
	 =oh=)))))
