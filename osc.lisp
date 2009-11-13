(in-package :musik)

(defvar *socket*)
(defvar *node* 2)
(defvar *node-max* 1024)

(defvar *port* 57110)
(setf *port* 57110)
;(setf *port* 7000)
      
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
		       (+ timetag (or (hack x "offset") 0))))
	   (bundle (encode-bundle x offset)))
      (socket-send *socket* bundle
		   (length bundle)
		   :address `(#(127 0 0 1) ,*port*)))))

(defun sendnow (messages)
  (send (now 0.5) messages))

(defgeneric unpack (item)
  ; takes an item and returns a list of osc-messages
  (:method ((item collection))
    (reduce (lambda (x y)
	      (nconc x (unpack y)))
	    (slot-value item 'items)
	    :initial-value nil))
  (:method ((item seq))
    (setf (slot-value item 'items)      
	  (let ((offset 0))
	    (map 'list (lambda (a)
			 (let ((off (++i offset (len a))))
			   ;; this is to evaluate ++i only once as opposed to
			   ;; once per lambda-evaluation
			   (setval :offset (lambda (x) (+ (or x 0) off)) a)))
		 (slot-value item 'items))))
    (call-next-method)))