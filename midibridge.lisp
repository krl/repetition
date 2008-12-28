;; use (uint x)
(in-package :musik)

(progn 
  (setq *socket* (make-instance 'inet-socket :type :datagram :protocol (get-protocol-by-name "udp")))
  (socket-connect *socket* #(127 0 0 1) 1288))

(defparameter *reset* '((0 1)))

(defun noteon (channel note vel time)
  `((1 1)
    (,(+ #x90 channel) 1)
    (,note 1)
    (,vel 1)
    (,time 4)))

(defun to-n-bytes (value bytes)
  (loop for i from 0 below bytes collect
       (ldb (byte 8 (* 8 i)) value)))
   
(defun byte-array-from-data (note-data)
  (let ((list nil))
    (mapcar #'(lambda (note-data)
		(setq list 
		      (append list (to-n-bytes (first note-data)
					       (second note-data)))))
	    note-data)
    (make-array (length list) :element-type '(unsigned-byte 8)
	      :initial-contents list)))


(defun send-data (note-data)
  (let ((byte-array (byte-array-from-data note-data)))
    (socket-send *socket* byte-array (array-total-size byte-array))))

(progn
  (send-data (make-note 1 57 100 100)))

(defun midi-reset ()
  (send-data *reset*))

(defun midi-play-group (group)
  (loop for span in group do
       (cond ((string= "note" (span-tag span :type))
	      (send-data (make-note (span-tag span :channel)
				    (span-tag span :note)
				    (span-tag span :vel)
				    (+ 10000 (round (* 14000 (span-start span))))))))))