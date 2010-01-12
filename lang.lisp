(in-package :musik)

;;; basic building blocks

(defproto =event= ()
  ((timetag 0)
   (len 1)))
	  
(defproto =collection= (=event=)
  ((children '())))

(defproto =join= (=collection=))
(defproto =seq= (=collection=))

;;; message handling

(defmessage makeosc (event)
  (:documentation "makeosc should return a list of osc-events")
  
  (:reply ((event =seq=))
	  (let ((offset 0))
	    (reduce (lambda (x y)
		      ;; depth-first reduce, this is to be able
		      ;; to calculate the length of the sub-elements
		      ;; correctly. length is not neccesarily the same 
		      ;; on each makeosc-call
		      (let* ((osclist (makeosc y))
			     (len (osclen osclist))
			     (result 
			      ;; offset each element inside by the accumulated offset
			      (map 'list
				   (lambda (e)
				     (create e 'timetag (+ (timetag e) offset)))
				   osclist)))
			(incf offset len)
			(nconc x result)))
		    (children event)
		    :initial-value '())))

  (:reply ((event =collection=))
	  (reduce (lambda (x y)
		    (nconc x (makeosc y)))
		  (children event)
		  :initial-value '())))

;;; DSL functions

(defun osclen (list)
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