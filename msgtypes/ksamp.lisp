(in-package :musik)

;;; specialized ksamp events

(defproto =ksamp-event= (=event=)
  ((target '(#(127 0 0 1) 7000))
   (id 0)
   (path "")))

(defproto =ksamp-play= (=ksamp-event=))
(defproto =ksamp-playtrim= (=ksamp-play=))

(defreply makeosc ((event =ksamp-play=))
	  (list (object :parents (list =osc-message= event)
			:properties `((message ("/ksamp_play" ,(path event) ,(id event)))))))

(defreply makeosc :around ((event =ksamp-playtrim=))
	  (setf (id event) 3)
	  (print (list (timetag event) (len event)))
	  (nconc (call-next-reply)
		 (list (object :parents (list =osc-message= event)
			       :properties `((message ("/ksamp_stop" ,(path event) ,(id event)))
					     (len 0))))))
