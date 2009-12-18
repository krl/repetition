(require :musik)
(in-package :musik)

(setf *chrom* (make-instance 'scale :base 60))
(setf *major* (make-instance 'major :base 60))
(setf *minor* (make-instance 'scale :base 20 :intervals '(2 1 2 2 2 1 2)))

(defmessage wobb  ('sc-message :name "basen" :amp 0.2))
(defmessage skrän ('sc-message :name "skren" :amp 0.2))

(defmessage kick  ('sc-message :name "kick"))
(defmessage snare ('sc-message :name "snare"))
(defmessage hat1  ('sc-message :name "hat1"))
(defmessage hat2  ('sc-message :name "hat2"))
(defmessage crash ('sc-message :name "crash"))

;; (sendnow (seq-n (y 40)
;; 	   (seq-n (x (random 5))
;; 	     (ass :sustain 0.05 :len 0.05
;; 		  (seq (ass :freq (freq *minor* (+ 5 y (* x 4))) *skrän*))))))

(sendnow 
 (seq-n 16
   (ass :sustain (lambda (x) (getval x :len))
	:wobfreq (lambda (x) (or (getval x :wobfreq) (/ 1.0 (or (getval x :len) 1))))
	:freq    (lambda (x) (freq *minor* (or (getval x :note) 0)))
	(scale 0.7
	  (join 
	   (seq-n (y 5)	     
	     (join
	      (let ((l (oneof 1.5 0.5)))
		(join-n (x 4)
		  (seq
		   (wobb :len 1   :amp (/ 1.0 (+ x 1)) :note (+ 6 (* x 10) (* y 3)))
		   (wobb :len l   :amp (/ 1.0 (+ x 1)) :note (+ 2 (* x 10) (* y 2)))
		   (wobb :len 0.5 :amp (/ 1.0 (+ x 1)) :note (+ 1 (* x 10) (* y 4))))))
	      (seq (seq-n 2 (kick :len 0.5)) (snare))))
	     (crash))))))
	  
(sendnow (seq-n 100
	  (let ((pitch (random 10)))
	    (join
					; phazor
	     (join-n (phase 4)
	       (skrän :freq (+ (* (freq *minor* 5) (+ pitch 3)) phase)
		      :amp 0.04
		      :sustain 4))
					; wobba
	      (seq	     
	       (seq-n 3
		 (wobb :freq (freq *minor* 2)
		       :wobfreq 1))
	       (wobb :freq (freq *minor* pitch)
		     :wobfreq 3))
					; trum
	      (seq (join (kick) (crash :amp 0.3)) (kick) (snare))))))

(sendnow (kick))

(sendnow (with-len len
	   (seq (kick) (kick))
	   (seq-n len
	     (kick :len 0.5))))

(makeosc (third (unpack (with-len len
			  (seq (kick) (kick :len 4))
			  
			  (seq-n 2 (kick))))))

(unpack (apply 'join (UNPACK (SEQ (KICK) (KICK)))))

(setf *break-on-signals* nil)
