(in-package :musik)

(defvar *socket*)

(setf *socket* (make-instance 'inet-socket 
			      :protocol :udp 
			      :type :datagram))

(defun subsecs ()
  (second (multiple-value-list (floor (/ (get-internal-real-time) internal-time-units-per-second)))))

(defun now (&optional future)
  (+ 0.0d0
     (get-universal-time)
     (subsecs)
     (or future 0)))

(defun sendraw (timetag messages)
  (dolist (x messages)
    (let* ((offset (when timetag
		     (+ timetag (or (timetag x) 0))))
	   (oscmsg (makeosc x))
	   (bundle (if oscmsg (encode-bundle oscmsg offset) nil)))		       
      ;xo(format t "~a ~%" (- offset (or timetag 0)))
      (when bundle
	(socket-send *socket* bundle
		     (length bundle)
		   :address (target x))))))

(defun send (timetag message)
  (format t "~a" (list 'send timetag message))
  (sendraw timetag (flatten message)))

(defun sendnow (message)
  (format t "~a" (list 'sendnow message))
  (send nil message))

(defmessage makeosc (event)
  ;; default heißt error!
  (:reply ((event =event=))
	  (error "no makeosc for ~a" event))

  (:reply ((event =nil=))
	  nil))