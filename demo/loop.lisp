
(in-package :musik)

(defun drum (name) 
  (sc-message :name name :amp 0.3))

(setf *kick*  (drum "kick"))
(setf *snare* (drum "snare"))
(setf *hat1*  (drum "hat1"))
(setf *hat2*  (drum "hat2"))
(setf *crash* (drum "crash"))

(sendnow (join
	  (seq-n 8
					; drumtrack
	    (join	     
	     (seq-n 8 (ass :len 0.5 :amp 0.05 *hat2*))
	     (seq-n 2
	       (oneof
		 (seq *kick* *snare*)
		 (seq (ass :len 1.5  *kick*) (ass :len 0.5  *snare*))
		 (seq (ass :len 1.25 *kick*) (ass :len 0.25 *kick*) (ass :len 0.5 *snare*))))
					; looptrack
	     (sl-message 

