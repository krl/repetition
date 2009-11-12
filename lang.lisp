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

(defmacro seq-n (number item)
  `(apply 'seq (n ,number ,item)))

(defmacro join-n (number item)
  `(apply 'join (n ,number ,item)))

(defmacro ++i (val amount)
  `(let ((old ,val))
     (incf ,val ,amount)
     old))

(defgeneric copy-instance (instance)
  (:method ((item message))
    (message (copy-list (slot-value item 'value)))))

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

(defgeneric unpack (item)
  (:method ((item message))
    (list (slot-value item 'value)))
  (:method ((item collection))
    (reduce (lambda (x y)
	      (nconc x (unpack y)))
	    (slot-value item 'items)
	    :initial-value nil))
  (:method ((item seq))
    (setf (slot-value item 'items)      
	  (let ((offset 0))
	    (map 'list (lambda (a)
			 (let ((off (++i offset (len a))))
			   ;; this is to evaluate ++i only once as opposed to
			   ;; once per lambda-evaluation
			   (setval :offset (lambda (x) (+ (or x 0) off)) a)))
		 (slot-value item 'items))))
    (call-next-method)))
