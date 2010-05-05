(in-package :musik)
(ingen-start)
(ingen-clear)

;; This is for the control of ingen, the modular synthesizer and effect rack.
;; Unfinished, undocumented.

(progn 
  (sendnow (append
	    (loop for num from 1 to 8 :collect
		 (ingen-make-inport (format nil "audio_in_~a" num)))

	    (loop for num from 1 to 2 :collect
		 (ingen-make-outport (format nil "audio_out_~a" num)))

	    (list
	     (sheeple::make =ingen-node=
			    'path "path:/Reverb"
			    'instance-of '|http://calf.sourceforge.net/plugins/Reverb|)
	    
	     (ingen-connect "path:/audio_in_1" "path:/Reverb/in_l")
	     (ingen-connect "path:/audio_in_2" "path:/Reverb/in_r")

	     (ingen-connect "path:/Reverb/out_l" "path:/audio_out_1")
	     (ingen-connect "path:/Reverb/out_r" "path:/audio_out_2"))))

  (loop for num from 1 to 8 :collect
       (jack-connect (format nil "SuperCollider:out_~a" num)
		     (format nil "ingen:audio_in_~a" num)))
  (loop for num from 1 to 2 :collect
       (jack-connect (format nil "ingen:audio_out_~a" num)
		     (format nil "system:playback_~a" num))))