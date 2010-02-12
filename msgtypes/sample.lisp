(in-package :musik)

;; supercollider samples

(defparameter *sc-buffer* 0)
(defparameter *sc-buffer-max* 1024)

(defun sc-nextbuffer ()
  (when (> *sc-buffer* *sc-buffer-max*)
    (setf *sc-buffer* 0))
  (incf *sc-buffer*))

(synthdef =sample= ((buffer nil) (path nil) (pan 0) (amp 0.5))
  !(Out.ar
    0 (* (Pan2.ar (PlayBuf.ar 1 buffer :doneAction 2)
		  pan)
	 amp)))

(defproto =sample-read= (=sample=))

(defreply makeosc ((event =sample-read=))  
  (list "/b_allocRead" (buffer event) (or (path event) (error "sample needs path"))))

;; conveniance macro
(defmacro samples (&body args)
  (cons 'progn
	(loop for (key val) on args by #'cddr :collect
	     `(progn (defproto ,key (=sample=)
		       ((path ,val)
			(buffer (sc-nextbuffer))))
		     ;; read the file into supercollider
		     (sendnow (m (list =sample-read= ,key)))))))
