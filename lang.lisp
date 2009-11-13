(in-package :musik)

(defun random-elt (choices)
  "Choose an element from a list at random."
  (elt choices (random (length choices))))

(defclass message ()
  ((value :initarg :value)))

(defun message (&optional message)
  (make-instance 'message :value message))

(defclass collection ()
  ((items :initarg :items)))

(defclass join (collection) nil)
(defclass seq (collection) nil)

(defun join (&rest items)
  (make-instance 'join :items items))

(defun seq (&rest items)
  (make-instance 'seq :items items))

(defmacro n (number item)
  (let ((counter (gensym)))
    (if (listp number)
	`(loop for ,counter from 0 below ,(second number)
	  :collect (let ((,(first number) ,counter))
		     ,item))
      `(loop for ,counter from 0 below ,number
	  :collect ,item))))

(defmacro seq-n (number &body item)
  (if (= (length item) 1)
      `(apply 'seq (n ,number ,(first item)))
      (error "one argument only")))
  
(defmacro join-n (number &body item)
  (if (= (length item) 1)
      `(apply 'join (n ,number ,(first item)))
      (error "one argument only")))

(defmacro ++i (place amount)
  (multiple-value-bind (temps values store writeform readform) (get-setf-expansion place)
    `(let ,(loop for temp in temps for value in values :collect (list temp value))
       (let* ((old ,readform)
	      (,(first store) (+ old ,amount)))
	 ,writeform
	 old))))

(defgeneric copy-instance (item)
  (:method ((item message))
    (make-instance (class-of item) :value (copy-list (slot-value item 'value)))))

(defgeneric getval (item value)
  (:method ((item message) key)
    (getf (slot-value item 'value) key)))

(defun ass (&rest args)
  (if (evenp (length args))
      (error "odd amount required"))	     
  (let ((temp-item (first (last args))))
    (loop for (key val) on (butlast args) by #'cddr do
	 (setf temp-item (setval key val temp-item)))
    temp-item))

(defgeneric setval (key value item)
  (:method (key value (item collection))
    (setf (slot-value item 'items)
	  (map 'list (lambda (x) (setval key value x)) (slot-value item 'items)))
    item)
  (:method (key value (item message))
    (let ((copy (copy-instance item)))
      (if (functionp value)
	  (setf (getf (slot-value copy 'value) key) 
		(funcall value (getf (slot-value copy 'value) key)))
	  (setf (getf (slot-value copy 'value) key) value))
      copy)))

(defgeneric len (item)
  (:method ((item message))
    (or (eval (getval item :length)) 1))
  (:method ((item join))
    (apply 'max (map 'list (lambda (x) (len x)) (slot-value item 'items))))
  (:method ((item seq))
    (reduce (lambda (x y) (+ x (len y))) (slot-value item 'items) :initial-value 0)))

