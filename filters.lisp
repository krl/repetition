(in-package :repetition)

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

(defmacro ass (varlist &body body)
  "Takes a form like (ass ((property1 value1) (property2 value2)) body) and assigns the properties to each body event. The value can be either a standard lisp value or a function. if a function, the value gets set by calling the function with the actual event being assigned as argument."
  (let ((evaled `(list ,@(map 'list (lambda (x)
				    (assert (= (length x) 2))
				    `(list ',(first x) ,(second x)))
			    varlist))))
    `(raw-ass ,evaled (apply 'raw-join (list ,@body)))))

;; over filter

(defmacro over (form &body function)
  "Executes the 'form form and calls function with the result. Returns a join of form and function values"
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
  "Takes a form like (ass ((property1 value1) (property2 value2)) body) and assigns the properties to each body event. The value can be either a standard lisp value or a function. if a function, the value gets set by calling the function with the actual event being assigned as argument."
  (assert (= 1 (length list)))
  `(raw-trim ,length ,(first list)))

;; scale

(defun raw-scale (factor list)
  (map 'list (lambda (event)
	       (first 
		(ass ((len     (lambda (x) (* (len x) factor)))
		      (timetag (lambda (x) (* (timetag x) factor))))
		     event)))
       list))

(defmacro scale (factor &body list)
  (assert (= 1 (length list)))
  `(raw-scale ,factor ,(first list)))