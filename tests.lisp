(in-package :repetition)

(defmacro unit-test (expr result)
  `(if (equal ,expr ,result) 
       (progn
	 (format t "Unit test passed: ~A => ~A~%" ',expr ,result)
	 t)
       (error (format 'nil "Unit test failed: ~A => ~A (should be ~A)" ',expr ,expr ,result))))

;; simple event tests
(unit-test (len =event=) 1)
(unit-test (len =nil=) 0)

;; assignment
(let ((event (ass ((test 2)) 
	       =event=)))
  (unit-test (property (first event) 'test) 2))

(let ((event (ass ((test #'len))
	       =event=)))
  (unit-test (property (first event) 'test) (len =event=)))

(let ((event (ass ((test 2)
		   (pest (lambda (x) (property x 'test))))	       
	       =event=)))
  (unit-test (property (first event) 'test)
	     (property (first event) 'pest)))

;; sequences and joins
(let ((simple-join (join =event= =event=)))
  (unit-test (len simple-join) 1)
  (unit-test (length simple-join) 2))

(let ((simple-seq (seq =event= =event=)))
  (unit-test (len simple-seq) 2)
  (unit-test (length simple-seq) 2))

(let ((join-n (join-n 4 =event=)))
  (unit-test (len join-n) 1)
  (unit-test (length join-n) 4))

(let ((seq-n (seq-n 4 =event=)))
  (unit-test (len seq-n) 4)
  (unit-test (length seq-n) 4))

(let ((join-join 
       (join-n 2 =event= =event=)))
  (unit-test (len join-join) 1)
  (unit-test (length join-join) 4))

(let ((seq-seq
       (seq-n 2 =event= =event=)))
  (unit-test (len seq-seq) 4)
  (unit-test (length seq-seq) 4))

(let ((join-seq
       (join-n 2 (seq =event= =event=))))
  (unit-test (len join-seq) 2)
  (unit-test (length join-seq) 4))

(let ((seq-join
       (seq-n 2 (join =event= =event=))))
  (unit-test (len seq-join) 2)
  (unit-test (length seq-join) 4))

;; nv variant

(let* ((sequence '(3 45 5 3))
       (seq-nv (seq-nv x sequence
		 (ass ((test x))
		   =event=))))
  (unit-test (map 'list (lambda (x) (property x 'test)) seq-nv)
	     sequence))

(let* ((sequence '(3 45 5 3))
       (join-nv (join-nv x sequence
		 (ass ((test x))
		   =event=))))
  (unit-test (map 'list (lambda (x) (property x 'test)) join-nv)
	     sequence))
