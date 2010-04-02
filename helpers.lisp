(in-package :musik)

(defun 1rand (x)
  (+ 1 (random x)))

(defun oneof (&rest alternatives)
  (nth (random (length alternatives)) alternatives))

;; for the object system
(defun m (parents &rest args)
  (object :parents (if (listp parents) parents (list parents))
	  :properties (loop for (key val) on args by #'cddr :collect (list key val))))

(defun sq (number)
  (loop for x from 0 below number :collect x))

(defun sq1 (number)
  (loop for x from 1 to number :collect x))

(defmacro offset (amount &body body)
  `(ass ((timetag (lambda (x) (+ ,amount (timetag x)))))
	,@body))