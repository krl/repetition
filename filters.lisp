(in-package :musik)

;; assignment filter

(defun raw-ass (varlist body)
  "body is a list of events to be assigned values"
  (map 'list (lambda (obj &aux clone (clone obj))
	       (reduce (lambda (x y)
			 (let* ((evaled (eval (second y)))
				(value (if (functionp evaled)
					   ;; value from function with the clone as argument
					   (funcall evaled clone)
					   ;; direct value
					   evaled)))
			   (setf (property-value clone (first y)) value)
			   clone))
		       varlist
		       :initial-value nil))
       (mklist body)))

;; language version

(defmacro ass (varlist &rest body)
  (let ((evaled `(list ,@(map 'list (lambda (x)
				    (assert (= (length x) 2))
				    `(list ',(first x) ,(second x)))
			    varlist))))
    `(raw-ass ,evaled (apply 'raw-seq (list ,@body)))))


;; over filter

(defmacro over (form &body function)
  (assert (= 1 (length function)))
  `(let ((result ,form))
     (raw-join result (funcall ,(first function) result))))


;; trim

(defun raw-trim (length list)
  (reduce (lambda (x y)
	    (append x
		    (if (< (timetag y) length)
			(if (< (+ (timetag y) (len y)) length)
			    (list y)
			    (ass ((len (- length (timetag y)))) y))
			nil)))
	  list
	  :initial-value nil))

(defmacro trim (length &body list)
  (assert (= 1 (length list)))
  `(raw-trim ,length ,(first list)))
