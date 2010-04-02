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
   (argref nil)))

(defreply makeosc ((event =sc-new=))
  (append (list "/s_new"
		(or (name event) (error "sc-new needs name")) -1 0 1)
	  (reduce (lambda (x y)
		    (append x (list (format nil "~(~a~)" y)
				    (property-value event y))))
		  (argref event)
		  :initial-value nil)))

(defmacro synthdef (name args &body body)
  (let (;; convert arg without default to (arg nil)
	(args (map 'list (lambda (x) (if (listp x) x (list x nil))) args))
	(body (if (= (length body) 1) 
		  (first body) 
		  (error "synthdef takes exactly one body form"))))
    ;; create actual event object)
    (send-sc-command-cached name (format nil "(SynthDef('~(~a~)', {|~:{~(~a~)~@[ = ~a~]~:^, ~} | ~a})).send(s)" name args body))
    `(defproto ,name (=sc-new=)
       ,(nconc `((name ,(format nil "~(~a~)" name))
    		 (argref ',(map 'list 'first args)))
    	       args))))
