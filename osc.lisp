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

(defun send (timetag message)
  (dolist (x (makeosc message))
    (let* ((offset (if timetag
		       (+ timetag (or (timetag x) 0))))
	   (bundle (encode-bundle (message x) offset)))
      (socket-send *socket* bundle
		   (length bundle)
		   :address (target x)))))

(defun sendnow (messages)
  (let ((time (now 0.5)))
    (send time messages)
    time))

(defproto =osc-message= ()
  ((message nil)))