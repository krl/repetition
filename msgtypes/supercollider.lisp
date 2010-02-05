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
  (list (m (list =osc-message= event)
	   'message (nconc (list "/s_new"
				 (or (name event) (error "sc-new needs name"))
				 -1
				 0 1)))))

(defmacro synthdef (name args &body body)
  (when (not (= (length body) 1)) (error "synthdef takes exactly one body form"))
  (let* ((namestring (format nil "~(~A~)" name))
	 (sclang (flatstr
		  "(SynthDef('" namestring "', {|"
		  (loop for x in args for i from 0 :collect (format nil "~A~(~A~) = ~A" (if (zerop i) "" ", ") (first x) (second x)))
		  "|"
		  (convert (first body))
		  "})).send(s)")))
    ;; send the definition
    ;; (sendnow (m =sc-synthdef= 'definition sclang))
    (send-sc-command sclang)
    ;; create actual event object
    `(progn 
       (defproto ,name (=sc-new=)
	 ,args)
       (defreply makeosc ((event ,name))
	 (let ((next-reply (call-next-reply)))
	   ;; modify message
	   (nconc (message (first next-reply)) 
		  (reduce (lambda (x y)
			    (let ((symbol (if (listp y) (first y) y)))
			      (nconc x (list
					(format nil "~(~a~)" symbol)
				      (or (property-value event symbol) (second y))))))
			  (quote ,(nconc args `((name ,namestring))))
			  :initial-value nil))
	   next-reply)))))
