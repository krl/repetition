(in-package :repetition)

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

(defun shell-command (command)
  (let ((path #p"/tmp/repetition-tmp.sh"))
    (with-open-file (file path :direction :output :if-exists :supersede)
      (format file "~A" command))
    (sb-ext:run-program "/bin/sh" (list (namestring path)) :input :stream :output t :error t)))

(defun property(object property &optional default)
  (handler-case
      (property-value object property)
    (unbound-property () default)))

(defmacro lenlist (&body args)
  `(seq
     ,@(loop for (key val) on args by #'cddr :collect
	    `(ass ((len ,key)) ,val))))