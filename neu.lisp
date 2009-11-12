(require :musik)
(in-package :musik)

(setf *chrom* (make-instance 'scale :base 60))
(setf *major* (make-instance 'major :base 60))
(setf *minor* (make-instance 'scale :base 23 :intervals '(2 1 2 2 2 1 2)))

(setf *wobb* (message
	      '(:type "/s_new"
		:name "basen"
		:amp 0.5)))

(setf *skrän* (message
	       '(:type "/s_new"
		 :name "skren"
		 :amp 0.3)))

(defun drum (name) 
  (message
   `(:type "/s_new"
     :name ,name
     :amp 0.3)))

(setf *kick* (drum "kick"))
(setf *snare* (drum "snare"))
(setf *crash* (drum "crash"))

(setf *snare* (message
	       '(:type "/s_new"
		 :name "snare"
		 :amp 0.3)))

(sendnow (seq-n 16
	   (join
	    ; phazor
	    (join-n (phase 4)
	      (ass :freq (+ (* (freq *minor* 3) 3) phase)
		   :amp 0.2
		   :sustain 4
		   *skrän*))
	    ; wobba
	    (seq
	     (ass :freq (freq *minor* 2)
	    	  :wobfreq 1
	    	  (seq-n 3 *wobb*))
	     (ass :freq (freq *minor* (random 10))
	    	  :wobfreq 3
	    	  *wobb*))
	    ; trommen
	    (seq (join *kick* *crash*) *kick* *snare*))))