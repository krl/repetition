
;; message type for supercollider synthdefs

(in-package :musik)

(defclass sc-message (message)
  nil)

(defun sc-message (&rest value)
  (make-instance 'sc-message :value value))

(sendnow (seq-n 10 (sc-message :name "kick")))

(defun next-node ()
  "keeps track of used node id:s"
  (if (= (incf *node*) *node-max*)
      (setf *node* 2))
  *node*)

(defmethod unpack ((msg sc-message))
  ; takes an item and returns a list of osc-bundles (list of one in this case)
  ; TODO, figure out what the "0 1" is all about..
  (with-slots (value) msg
    (let ((osc (list "/s_new"
		     (or (getf value :name) (error "sc-message requires :name value"))
		     (next-node) 0 1)))
      (loop for (key val) on value by #'cddr do
	   (case key
	     (:name
	      nil)
	     (t
	      (nconc osc (list (format nil "~(~a~)" (symbol-name key)) ;; lowercase..
			       val)))))
      (list osc))))