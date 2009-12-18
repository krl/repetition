(in-package :musik)

;; (defmacro playloop (what)
;;   (let ((unpacked (gensym))
;; 	(looplen (gensym)))
;;     `(progn
;;        (setf *playing* ',what)
;;        (let* ((,unpacked (unpack ,what))
;; 	      (,looplen  (unpackedlen unpacked)))

(defvar *latency* 1)
(defvar *latest* 0)
(defvar *playing* nil)
(defvar *loopthread* nil)

(defmacro defpart (name &body body)
  `(progn
     (unpack ,@body)
     (setf ,name (quote ,@body))))

(defun stoploop ()
  (setf *loopthread* nil
	*playing* nil))

(defmacro playloop (what)
  (eval what) ; catch errors here
  (setf *playing* what)
  `(progn
     (unless *loopthread*
       (setf *loopthread* (sb-thread:make-thread 'loopthread)))))

(defun loopthread ()
  (loop
     (format t "loopin~%")
     (unless *playing*
       (progn
	 (format t "loop thread quit~%")
	 (setf *loopthread* nil)
	 (return)))
     (let ((time (now)))
       ;; latest is already passed	       
       (when (< *latest* time)
	 (setf *latest* (+ time 1)))

       ;; latest within latency buffer
       (loop while (> time (- *latest* *latency*))
	    :do 
	 ;; time to add more
	 (let* ((evaluated (unpack (eval (eval *playing*))))
		(length    (unpackedlen evaluated)))
	   (map 'list (lambda (x) (send *latest* x)) evaluated)
	   (incf *latest* length)
	   (format t "latest: ~a~%length: ~a~%" *latest* length))))
		 
     (sleep (* *latency* 0.1))))