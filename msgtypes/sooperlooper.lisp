
;; message type for supercollider synthdefs

;; (in-package :musik)

;; (defclass sl-message (message) 
;;   ((target :initform '(#(127 0 0 1) 9951))))

;; (defun sl-message (&rest value)
;;   (make-instance 'sl-message 
;; 		 :value value))

;; (sendnow (seq (ass :len 4
;; 		   (sl-message :loop 0 
;; 			       :cmd "recond"
;; 			       :type "hit"))
;; 	      (sl-message :loop 0 
;; 			  :cmd "record"
;; 			  :type "record")))

;; (defmethod makeosc ((item sl-message))
;;   ; takes an item and returns a list formatted as an OSC packet
;;   (with-slots (value) item
;;     (list (concatenate 'string 
;; 		       "/sl/" (or (write-to-string (getf value :loop)) (error "sl-message requires :loop value"))
;; 		       "/"    (or (getf value :type)                   (error "sl-message requires :type value")))
;; 	  (or (getf value :cmd) (error "sl-message requires :cmd value")))))
