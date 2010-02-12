(in-package :musik)

;;; basic building blocks

(defproto =event= ()
  ((timetag 0)
   (len 1)))
	  
(defproto =collection= (=event=)
  ((children '())))

(defproto =join= (=collection=))
(defproto =seq= (=collection=))

(defproto =filter= (=event=)
  ((transform nil)
   (source nil)))
	  
;;; message handling

(defmessage flatten (event)
  (:documentation "flatten should return a list of osc-events")
  
  (:reply ((event =event=))
	  ;; most general, returns itself only
	  (list event))

  (:reply ((event =seq=))
	  (let ((offset 0))
	    (reduce (lambda (x y)
		      ;; depth-first reduce, this is to be able
		      ;; to calculate the length of the sub-elements
		      ;; correctly. length is not neccesarily the same 
		      ;; on each flatten-call
		      (let* ((osclist (flatten y))
			     (len (flatlen osclist))
			     (result 
			      ;; offset each element inside by the accumulated offset
			      (map 'list
				   (lambda (e)
				     (m e 'timetag (+ (timetag e) offset)))
				   osclist)))
			(incf offset len)
			(nconc x result)))
		    (children event)
		    :initial-value '())))

  (:reply ((event =collection=))
	  (reduce (lambda (x y)
		    (nconc x (flatten y)))
		  (children event)
		  :initial-value '())))

;;; DSL functions

(defun flatlen (list)
  (reduce (lambda (x y)	    
	    (max x (+ (len y) (timetag y))))
	  list
	  :initial-value 0))

(defun collection (kind arglist)
  (object :parents (list kind)
	  :properties `((children ,arglist))))

(defun seq (&rest arglist)
  (collection =seq= arglist))

(defun join (&rest arglist)
  (collection =join= arglist))

(defun n (iter method arglist)
  (let ((i (gensym)))
    `(apply ',method
	    (loop for ,i from 0 below ,iter :collect
		 (funcall 'seq ,@arglist)))))

(defmacro join-n (number &body arglist)  
  (n number 'join arglist))

(defmacro seq-n (number &body arglist)
  (n number 'seq arglist))

(defmacro seqlet (args &body body)
  `(let ,args (seq ,@body)))

(defmacro joinlet (args &body body)
  `(let ,args (join ,@body)))

(defmacro ass (assignments &body body)
  `(m =filter= 
      'source (seq ,@body)
      'transform (lambda (list)
		   (map 'list (lambda (x)
				(object :parents (list x)
					:properties (quote ,assignments)))
			list))))

;; filters 

(defmacro deffilter (name arg &body body)
  (unless (symbolp (first arg)) (error "must provide one argument"))
  `(defun ,name (&rest source)
	  (m =filter=
	     'source (apply 'seq source)
	     'transform (lambda ,arg
			  ,@body))))

(defreply flatten ((event =filter=))
  (funcall (transform event) (flatten (source event))))
