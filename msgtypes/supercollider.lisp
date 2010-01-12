(in-package :musik)

(defparameter *sc-node* 0)
(defparameter *sc-node-max* 1024)

(defun sc-nextnode ()
  (when (> *sc-node* *sc-node-max*)
    (setf *sc-node* 0))
  (incf *sc-node*))

(defproto =sc-event= (=event=)
  ((target '(#(127 0 0 1) 57110))))

;; sc-new

(defproto =sc-new= (=sc-event=)
  ((name nil)
   (id nil)))

(defreply makeosc ((event =sc-new=))
  (setf (id event) (sc-nextnode))
  (list (object :parents (list =osc-message= event)
		:properties `((message ("/s_new"
					,(or (name event) (error "sc-new needs name"))
					,(sc-nextnode)
					0 1))))))