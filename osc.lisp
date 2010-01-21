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
    (let* ((offset (if timetag
		       (+ timetag (or (timetag x) 0))))
	   (bundle (encode-bundle (message x) offset)))
      (socket-send *socket* bundle
		   (length bundle)
		   :address (target x)))))

(defun send (timetag message)
  (sendraw timetag (makeosc message)))

(defun sendnow (message)
  (send nil message))

(defproto =osc-message= ()
  ((message nil)))