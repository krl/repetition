(in-package :repetition)

(defun 1rand (x)
  (+ 1 (random x)))

(defun oneof (&rest alternatives)
  "Randomly returns one of the items in 'alternatives."
  (nth (random (length alternatives)) alternatives))

;; for the object system
(defun m (parents &rest args)
  (object :parents (if (listp parents) parents (list parents))
	  :properties (loop for (key val) on args by #'cddr :collect (list key val))))

(defun sq (n)
  "Returns a n-length list of increasing numbers starting at 0."
  (loop for x from 0 below n :collect x))

(defun sq1 (n)
  "Returns a n-length list of increasing numbers starting at 1."
  (loop for x from 1 to n :collect x))

(defmacro offset (amount &body body)
  "Offsets the timetag of events in 'body by 'amount"
  `(ass ((timetag (lambda (x) (+ ,amount (timetag x)))))
	,@body))

(defun shell-command (command)
  (let ((path #p"/tmp/repetition-tmp.sh"))
    (with-open-file (file path :direction :output :if-exists :supersede)
      (format file "~A" command))
    (sb-ext:run-program "/bin/sh" (list (namestring path)) :input :stream :output t :error t)))

(defun property (object property &optional default)
  "Gets the property of an event, or if unset returns the 'default argument."
  (handler-case
      (property-value object property)
    (unbound-property () default)))

(defmacro lenlist (&body args)
  "Takes a form the format of (length event length event...) and outputs a sequence of the events with applied lengths."
  `(seq
     ,@(loop for (key val) on args by #'cddr :collect
	    `(ass ((len ,key)) ,val))))