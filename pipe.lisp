(in-package :musik)

(defvar *process* nil)

(defparameter +event+ 0)
(defparameter +play+ 1)
(defparameter +sync+ 2)

(defun write-long (value stream)
  (loop for n below 4 do
       (write-byte (ldb (byte 8 (* n 8)) value) stream)))

;; (defun stop ()
;;   (let ((output (sb-ext:process-input *process*)))    
;;     (write-event '(0 #xFC 0 0) output)  ;; midi reset
;;     (finish-output output)))

(defun write-event (event output)
  (write-long (nth 0 event) output)
  (write-byte +event+ output)
  (dolist (nr '(1 2 3))
    (write-byte (nth nr event) output)))

(defun write-command (command output)
  (write-long 0 output)
  (write-byte command output)
  (dolist (nr '(1 2 3))
    (write-byte 0 output)))

(defun play ()
  (let ((output (sb-ext:process-input *process*)))
    (write-command +play+ output)
    (finish-output output)))

(defun sync ()
  (if *process*
      (let ((output (sb-ext:process-input *process*))
	    (input (sb-ext:process-output *process*)))
	(write-command +sync+ output)
	(finish-output output)

	(+
	 (* (read-byte input) 1)
	 (* (read-byte input) 256)
	 (* (read-byte input) 256 256)
	 (* (read-byte input) 256 256 256)))
      0))
  
(defun send (what)
  (pipe (offset (sync) what)))

(defun reset ()
  (if *process*
      (sb-ext:process-kill *process* 5))
  (setf *process* nil))

(defun pipe (what)
;;;   (when *process*
;;;     (sb-ext:process-kill *process* 5))
  (unless *process*
    (setf *process* (sb-ext:run-program "seq" nil :output :stream :input :stream :error t :wait nil)))

  (let ((output (sb-ext:process-input *process*))
	(midi (dump-midi what)))
    (dolist (event midi)
      (write-event event output))

    (finish-output output)
    midi))