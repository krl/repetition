
;; message type for supercollider synthdefs

(in-package :musik)

(defclass sc-message (message) 
  ((target :initform '(#(127 0 0 1) 57110))))

(defun sc-message (&rest value)
  (make-instance 'sc-message 
		 :value value))

(defvar *sc-node* 2)
(defvar *sc-node-max* 1024)

(defun next-node ()
  "keeps track of used node id:s"
  (if (= (incf *sc-node*) *sc-node-max*)
      (setf *sc-node* 2))
  *sc-node*)

(defmethod makeosc ((item sc-message))
  ; takes an item and returns a list formatted as an OSC packet
  ; TODO, figure out what the "0 1" is all about..
  (with-slots (value) item
    (let ((osc (list "/s_new"
  		     (or (getf value :name) (error "sc-message requires :name value"))
  		     (next-node) 0 1)))
      (loop for (key val) on value by #'cddr 
	 :do (case key
	       (:name
		nil)
	       (t
		(nconc osc (list (format nil "~(~a~)" (symbol-name key)) ;; lowercase..
				 val)))))
      osc)))
