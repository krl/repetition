(require :musik)
(in-package :musik)

(setf *chrom* (make-instance 'scale :base 60))
(setf *major* (make-instance 'major :base 60))
(setf *minor* (make-instance 'scale :base 23 :intervals '(2 1 2 2 2 1 2)))

(setf *wobb* (sc-message :name "basen"))
(setf *skrän* (sc-message :name "skren"))

(defun drum (name) 
  (sc-message :name name :amp 0.3))

(setf *kick* (drum "kick"))
(setf *snare* (drum "snare"))
(setf *crash* (drum "crash"))

(sendnow (seq-n 100
	  (let ((pitch (random 10)))
	    (join
					; phazor
	     (join-n (phase 4)
	       (ass :freq (+ (* (freq *minor* 5) (+ pitch 3)) phase)
		    :amp 0.2
		    :sustain 4
		    *skrän*))
					; wobba
	     (seq
	      (ass :freq (freq *minor* 2)
		   :wobfreq 1
		   (seq-n 3 *wobb*))
	      (ass :freq (freq *minor* pitch)
		   :wobfreq 3
		   *wobb*))
					; trum
	     (ass :amp 1
		  (seq (join *kick* (ass :amp 0.1 *crash*)) *kick* *snare*))))))