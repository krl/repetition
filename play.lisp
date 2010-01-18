(in-package :musik)

(defvar *latency* 1)
(defvar *latest* 0)
(defvar *playing* nil)
(defvar *loopthread* nil)

(defun stop ()
  (setf *loopthread* nil
	*playing* nil))

(defmacro play (what)
  (eval what) ; catch errors here
  (setf *playing* what)
  `(progn
     (unless *loopthread*
       (setf *loopthread* (sb-thread:make-thread 'loopthread)))))

(defun loopthread ()
  (loop
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
	    (format t "playing: ~a~%" *playing*)
	    (let ((evaluated (makeosc (eval *playing*))))
	      (sendraw *latest* evaluated)
	      (incf *latest* (osclen evaluated)))))
		 
     (sleep (* *latency* 0.1))))