(in-package :musik)

(defvar *socket*)
(defvar *node* 2)
(defvar *node-max* 1024)

(defvar *port* 57110)
(setf *port* 57110)
;(setf *port* 7000)

(defclass target ()
  ((url  :initarg :url)
   (port :initarg :port)))

(defun target (url port)
  (make-instance 'target :url url :port port))

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

(defun hack (message value)
  "hack to get offset part from message.. FIXME"
  (let ((pos (position value message :test 'equal)))
    (if pos
	(nth (+ pos 1) message)
	0)))

(defun send (timetag message)
  (dolist (x (unpack message))
    (let* ((offset (if timetag
		       (+ timetag (or (getval x :offset) 0))))
	   (bundle (encode-bundle (makeosc x) offset)))
      (socket-send *socket* bundle
		   (length bundle)
		   :address (slot-value x 'target)))))

(defun sendnow (messages)
  (send (now 0.5) messages))

(defgeneric makeosc (item)
  ; takes an item and returns a list formatted as an OSC packet
  ; TODO, figure out what the "0 1" is all about..
  )
