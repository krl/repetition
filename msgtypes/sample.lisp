(in-package :musik)

;; supercollider samples

(defparameter *sc-buffer* 0)
(defparameter *sc-buffer-max* 1024)

(defun sc-nextbuffer ()
  (when (> *sc-buffer* *sc-buffer-max*)
    (setf *sc-buffer* 0))
  (incf *sc-buffer*))

(defproto =sample= (=sc-new=)
  ((name "playbuf")
   (buffer nil)
   (path nil)))

(defproto =sample-read= (=sample=))

(defreply makeosc ((event =sample-read=))  
  (let ((msg (list "/b_allocRead" (buffer event) (or (path event) (error "sample needs path")))))
    (list
     (object :parents (list =osc-message= event)
	     :properties `((message ,msg))))))

(defreply makeosc ((event =sample=))
  (call-next-reply (m event :buffer (buffer event))))

;; conveniance macros
(defmacro samples (&body args)
  (cons 'progn
	(loop for (key val) on args by #'cddr :collect
	     `(progn (defproto ,key (=sample=)
		       ((path ,val)
			(buffer (sc-nextbuffer))))
		     ;; read the file into supercollider
		     (sendnow (defobject (=sample-read= ,key)))))))
