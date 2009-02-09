(defpackage :musik (:use :cl))
(in-package :musik)

(defvar *process* nil)

(defvar *rawmidi* '((0 #x90 60 100) (0 #x91 36 100) (10000 #x91 36 90)))

(defun write-long (value stream)
  (loop for n below 4 do
       (write-byte (ldb (byte 8 (* n 8)) value) stream)))

(defun stop ()
  (let ((output (sb-ext:process-input *process*)))    
    (write-event '(0 #xFC 0 0) output)  ;; midi reset
    (finish-output output)))

(defun write-event (event output)
  (write-long (nth 0 event) output)
  (write-byte (nth 1 event) output)
  (write-byte (nth 2 event) output)
  (write-byte (nth 3 event) output))

(defun play (what)
  (when *process*
    (sb-ext:process-kill *process* 5))
  (setf *process* (sb-ext:run-program "seq" nil :output t :input :stream :wait nil))

  (let ((output (sb-ext:process-input *process*)))	
    (dolist (event (dump-midi what))
      (write-event event output))
    (finish-output output))

  (dump-midi what))