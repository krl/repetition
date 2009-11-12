(in-package :musik)

(defclass scale ()
  ((base :initarg :base
	 :initform 60)
   (intervals :initarg :intervals
	      :initform '(1))))

(defclass major (scale)
  ((intervals :initarg :intervals
	     :initform '(2 2 1 2 2 2 1))))

(defun shift (list &optional backwards)
  (if backwards
      (concatenate 'list (last list) (butlast list))
      (concatenate 'list (rest list) (list (first list)))))

(defun offset (n intervals &optional (count 0))
  (format t "~a ~a ~a~%" n intervals count)
  (if (zerop n) count
      (if (> 0 n)
	  (offset (+ n 1) (shift intervals t) (- count (first (last intervals))))
	  (offset (- n 1) (shift intervals  ) (+ count (first intervals))))))

(defun scale (&optional (base 60))
  (make-instance 'scale :base 60))

(defgeneric freq (scale num &optional mod)
  (:method ((scale scale) num &optional mod)
    (let ((scaletone (offset num (slot-value scale 'intervals))))
      (* 440 (expt 2 (/ (- (+ (slot-value scale 'base) scaletone) 69) 12))))))