(in-package :repetition)

;; macros

(defmacro bind-sequence (varname sequence &body body)
  "takes a body list and returns a list of lists over the sequence"
  `(apply #'append 
	  (map 'list 
	       ,(if varname
		    `(lambda (x)	       
		       (let ((,varname x)) (list ,@body)))
		    `(lambda (x)
		       (declare (ignore x))
		       (list ,@body)))
	       ,sequence)))

(defmacro seq-len (length &body body)
  `(trim ,length
	 (let ((list ,@body))
	   (loop while (< (len list) ,length) :do
		(setf list (raw-seq list ,@body)))
	   list)))

(defreply len ((list =list=))
  (apply 'max
	 ;; the maximum timetag + length
	 (map 'list (lambda (x) (+ (timetag x) (len x)))
	      list)))

(defmacro pincf (place delta)
  "small helper macro for post-incr"
  `(let ((old ,place))
     (incf ,place ,delta)
     old))

(defun mklist (smth)
  (if (listp smth) smth (list smth)))

;; raw functions

(defun raw-join (&rest list)
  (reduce (lambda (x y) (append x (map 'list #'clone (mklist y))))
	  list
	  :initial-value nil))

(defun raw-seq (&rest body)
  "takes a list of lists, outputs a list"
  (apply 'raw-join
	 (let ((offset 0))
	   (map 'list (lambda (dummy &aux (item (mklist dummy)))
			;; item is a list from the list of lists 'body
			(let ((old-offset (pincf offset (len item))))
			  (map 'list (lambda (x)
				       (let ((clone (clone x)))
					 (incf (property-value clone 'timetag) old-offset)
					 clone))
			       item)))
		body))))

;; sweet macro sugar

(defmacro seq (&body body)
  `(raw-seq ,@body))

(defmacro seq-length (length &body body)
  `(raw-seq ,@body))

(defmacro seq-nv (varname sequence &body body)
  `(apply 'raw-seq 
	  (bind-sequence ,varname ,sequence ,@body)))

(defmacro seq-n (sequence &body body)
  `(seq-nv nil (sq ,sequence) ,@body))

(defmacro join-nv (varname sequence &body body)
  `(apply 'raw-join
	  (bind-sequence ,varname ,sequence ,@body)))

(defmacro join-n (sequence &body body)
  `(join-nv nil (sq ,sequence) ,@body))

(defmacro join (&body body)
  `(raw-join ,@body))
