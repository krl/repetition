(in-package :musik)

(defvar *socket*)
(defvar *node* 2)
(defvar *node-max* 1024)

(defvar *port* 57110)
(setf *port* 57110)
;(setf *port* 7000)

(defmacro nlet (n letargs &body body)
  `(labels ((,n ,(mapcar #'car letargs)
              ,@body))
     (,n ,@(mapcar #'cadr letargs))))

(defun next-node ()
  (if (= (incf *node*) *node-max*)
      (setf *node* 2))
  *node*)
      
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
  (dolist (x (unpack message))
    (let* ((offset (if timetag
		       (+ timetag (or (getf x :offset) 0))))
	   (bundle (encode-bundle (makeosc x) offset)))
      (socket-send *socket* bundle
		   (length bundle)
		   :address `(#(127 0 0 1) ,*port*)))))

(defun sendnow (messages)
  (send (now 0.5) messages))

(defun makeosc (msg)
  (let ((list (list (getf msg :type)
		    (eval (getf msg :name))
		    (next-node) 0 1)))
    (nlet deplist ((plist msg))
	  (case (first plist)
	    ((:type :name)
	     nil)
	    (t
	     (nconc list (list (format nil "~(~a~)" (symbol-name (first plist))) ;; lowercase..
			       (eval (second plist))))))
	  (if (cddr plist)
	      (deplist (cddr plist))))
	list))