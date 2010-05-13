(in-package :repetition)

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
  "Sets up and sends a synth definition to the sclang process. Named 'name and with assignable arguments 'args. Body is the supercollider code for the synthdef in string form. Should be used with the ! reader macro."
  (let (;; arg     => (arg nil)
	;; (arg x) => (arg x)
	(args (map 'list (lambda (x) (if (listp x) x (list x nil))) args))
	(body (if (= (length body) 1) 
		  (first body) 
		  (error "synthdef takes exactly one body form"))))
    `(progn
       ;; create actual event object)
       (defproto ,name (=sc-new=)
	 ,(nconc `((name ,(format nil "~(~a~)" name))
		   (argref ',(map 'list 'first args)))
		 args))
       ;; send the code to supercollider
       (send-sc-command-cached ,name (format nil "(SynthDef('~(~a~)', {|~:{~(~a~)~@[ = ~a~]~:^, ~} | ~a})).send(s)" ',name ',args ,body))
       ,name)))
