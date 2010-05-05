(in-package :repetition)

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
  ;; bundle them by target and timetag.
  (let (targets)
    (dolist (x  messages)
      (push x (getf (getf targets (target x)) (timetag x))))

    (loop for (target groups) on targets by #'cddr :do
	 (loop for (group-offset msglist) on groups by #'cddr :do
	      (let* ((offset (when timetag
			       (+ timetag group-offset)))
		     (messages (map 'list #'makeosc msglist))
		     (bundle (encode-bundle messages offset)))
		
		(when bundle
		  ;(format t "~a: sending ~a~%" offset messages)
		  (socket-send *socket* bundle
			       (length bundle)
			       :address target)))))))

(defun send (timetag message)
  (format t "~a" (list 'send timetag message))
  (sendraw timetag message))

(defun sendnow (message)
  (format t "~a" (list 'sendnow message))
  (send nil message))

(defmessage makeosc (event)
  ;; default heißt error!
  (:reply ((event =event=))
	  (error "no makeosc for ~a" event))

  (:reply ((event =nil=))
	  nil))