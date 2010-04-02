(in-package :musik)

;; helpers

(defmacro bind-sequence (varname sequence &body body)
  "takes a body list and returns a list of lists over the sequence"
  `(map 'list (lambda (x)			   
		(let ((,varname x))
		  ,@body))
	,sequence))

(defun listlen (list)
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
  (reduce (lambda (x y) (append x (mklist y)))
	  list
	  :initial-value nil))

(defun raw-seq (&rest body)
  "takes a list of lists, outputs a list"
  (apply 'raw-join
	 (let ((offset 0))
	   (map 'list (lambda (dummy &aux (item (mklist dummy)))
			;; item is a list from the list of lists 'body
			(let ((old-offset (pincf offset (listlen item))))
			  (map 'list (lambda (x)
				       (let ((clone (clone x)))
					 (incf (property-value clone 'timetag) old-offset)
					 clone))
			       item)))
		body))))

;; all the macro sugar

(defmacro seq (&body body)
  `(raw-seq ,@body))

(defmacro seq-nv (varname sequence &body body)
  `(apply 'raw-seq 
	  (bind-sequence ,varname ,sequence ,@body)))

(defmacro seq-n (sequence &body body)
  `(seq-nv ,(gensym "dummy") (sq ,sequence) ,@body))

(defmacro join-nv (varname sequence &body body)
  `(apply 'raw-join
	  (bind-sequence ,varname ,sequence ,@body)))

(defmacro join-n (sequence &body body)
  `(join-nv ,(gensym "dummy") (sq ,sequence) ,@body))

(defmacro join (&body body)
  `(raw-join ,@body))

