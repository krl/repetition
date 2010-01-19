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
  (map 'list (lambda (x) (if (keywordp x) (format nil "~(~A~)" x) x)) (args event)))

(defmessage sc-create (event)
  (:documentation "convenience message for making sc-objects with arguments"))

(defreply sc-create ((event =sc-new=) &rest args)
  (let ((sc-args (copy-list (args event)))
	(properties nil))
    (loop for (key val) on args by #'cddr :do
	 (cond ((keywordp key)
		(setf (getf sc-args key) val))
	       ((symbolp key)
		(setf properties (nconc properties (list (list key val)))))
	       (t (error "Malformed sc-create arglist"))))

    (object :parents (list event)
	    :properties (nconc (list (list 'args sc-args))
			       properties))))
  
(defreply makeosc ((event =sc-new=))
  (setf (id event) (sc-nextnode))
  (list (object :parents (list =osc-message= event)
		:properties `((message ,(nconc (list "/s_new"
						     (or (name event) (error "sc-new needs name"))
						     (sc-nextnode)
						     0 1)
					       (sc-args event)))))))