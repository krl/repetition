(in-package :musik)

(defparameter *sc-node* 0)
(defparameter *sc-node-max* 1024)

(defun sc-nextnode ()
  (when (> *sc-node* *sc-node-max*)
    (setf *sc-node* 0))
  (incf *sc-node*))

(defproto =sc-event= (=event=)
  ((target '(#(127 0 0 1) 57110))
   (args nil)))

;; sc-new

(defproto =sc-new= (=sc-event=)
  ((name nil)
   (id nil)))

;; convenience messages

(defmessage sc-args (event)
  (:documentation "get arguments in sc form"))

(defreply sc-args ((event =sc-event=))
  (let ((args nil))
    (dolist (x (available-properties event))
      (when (keywordp x)
	(setf args (nconc args (list (format nil "~(~A~)" x) 
				     (property-value event x))))))
    args))

(sc-args (m =sc-new= 'test 2 :arg 2))

(defreply makeosc ((event =sc-new=))
  ;(setf (id event) (sc-nextnode))
  (list (object :parents (list =osc-message= event)
		:properties `((message ,(nconc (list "/s_new"
						     (or (name event) (error "sc-new needs name"))
						     -1
						     0 1)
					       (sc-args event)))))))