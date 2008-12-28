;; use (uint x)

(defpackage :midibridge
  (:use :cl :sb-bsd-sockets))

(in-package :midibridge)

(defparameter *reset* '((0 1)))

(defun make-note (channel note vel time)
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

(progn 
  (setq *socket* (make-instance 'inet-socket :type :datagram :protocol (get-protocol-by-name "udp")))
    (socket-connect *socket* #(127 0 0 1) 1288)) 

(defun send-data (note-data)
  (let ((byte-array (byte-array-from-data note-data)))
    (socket-send *socket* byte-array (array-total-size byte-array))))

(defvar *beat-length* 10000)

(defun beat (nr)
  (round (* nr *beat-length*)))

(defstruct item start length elist)

(setf *song* (list 
	      (make-item :start 0 :length 19 :elist '((:key (c minor))
						       (:tempo 100)
						       (:mode 1)))
	      (make-item :start 0 :length 19 :elist '((:chord (1 3 5 7))))
	      (make-item :start 0 :length 5 :elist '((:measure 1)))
	      (make-item :start 5 :length 5 :elist '((:measure 2))) 
	      (make-item :start 10 :length 5 :elist '((:measure 3)))
	      (make-item :start 15 :length 4 :elist '((:mode 7)))
	      (make-item :start 15 :length 4 :elist '((:measure last)))))

(defun play-on-channel (channel data)
  (let ((time 2))
    (loop for item in data do
	 (loop for event in (item-elist item) do
	      (send-data (make-note channel 60 100 (beat (incf time .4))))))))

(defun play-neu (channel data)

(progn
  (send-data *reset*)
  (play-on-channel 1 (bas *song*)))


(defun loop-phrase (times list)
  (if (> times 0)
      (append list (loop-phrase (- times 1) list))
      nil))

(defun chord ()
  (mapcar #'(lambda (x)
	      (+ x *key*))
	  (list (first *mode*) (third *mode*) (fifth scale))))

(defun mode (mode scale)
  (nthcdr mode scale))


;; (defun drummer (measures &optional (done 0))
;;   (if (> measures done)
;;       (let ((length 0)
;; 	    (addition 
;; 	     (if (= done (- measures 1))
;; 		 (list (list .5 snare hic)
;; 		       (list .5 snare))
;; 		 (if (oddp done)
;; 		     (list (list 1 snare hic))
;; 		     (list (list 1 kick (if (or (= measures 4) (= done 0)) crash hio)))))))
;; 	(append addition (drummer measures (+ done 1))))))


;; (defun bass (measures &optional (done 0))
;;   (if (> measures done)
;;       (let ((length 0)
;; 	    (addition 
;; 	     (if (= done (- measures 1))
;; 		 (list (list .5 41)
;; 		       (list .5 41))
;; 		 (if (oddp done)
;; 		     (list (list 1 41))
;; 		     (list (list 1 40 (if (or (= measures 4) (= done 0)) crash hio)))))))
;; 	(append addition (drummer measures (+ done 1))))))

;;;   (loop for i from 0 below measures collect
;;;        (if (= i (- measures 1))
;;; 	   `((.5 ,snare ,hic) (.5 ,snare))
;;; 	   (if (oddp i)
;;; 	       `(1 ,snare ,hic)
;;; 	       `(1 ,kick ,hio)))))

;; (defmacro x (number &rest body)
;;   (let ((list nil))
;;     (loop for i from 1 to number do
;;        (setq list (append list body)))
;;     list)) ;; ja ja...


;((duration) (happenings))

;(play time, eventlist)

(defparameter minor '(0 2 3 5 7 8 10))

;; final processed version draft:
;; this structure allows for overlapping events

;; song -> item -> elist -> event (dumt dumt) KISS för fan

(defun get-most-specific-key (song time key))

(defun contains-event (event eventlist)
  (find event (first eventlist)))

(defun sort-items (items)
  (sort items (lambda (x y)
		(< (item-start x) (item-start y)))))

(defun get-items-with-event (event song)
  (let ((items nil))
    (loop for item in song
       collect (loop for e in (item-elist item)
		  when (find event e)
		  do (push (make-item :start (item-start item) 
				      :length (item-length item) 
				      :elist e) items)))
    (sort-items items)))

(get-items-with-event :measure *song*)

(defun bas (song)
  (let ((items nil))
    (dolist (item (get-items-with-event :measure *song*))
      (let ((measure (second (item-elist item)))
	    (start (item-start item))
	    (length (item-length item)))
	(cond ((eq measure 'last)
	       (progn 
		 (push (make-item :start start
				  :length (- length 1)
				  :elist '(:note 40)) items)
		 (push (make-item :start (- length 1)
				  :length 1
				  :elist '(:note 47)) items)))
	      ((not (oddp measure))
	       (progn
		 (push (make-item :start start
				  :length 2
				  :elist '(:note 40)) items)
		 (push (make-item :start (+ 2 start)
				  :length (- length 3)
				  :elist '(:note 47)) items)))

	      (t (push (make-item :start start
				  :length (- length 1)
				  :elist '(:note 40)) items)))))
    (sort-items items)))

(get-items-with-event :measure *song*)

(play-on-channel 0 (bas *song*))

;; det här kan bli sjuknajs alltså.. fniss. :) :) :( :)
  
;; (defun key-scope-as-subsong) så kan basen bara bry sig om sin lille
;; del i det hele till exempel med key :basenspelarhärffs
;; måste ta i konsideration typ större scopes som key etc.

;; time based scope somehow? ya. done lätt kirrat fixat!

;; chord måste lista ut hur länge den tar genom att kolla tiden på sina
;; barnjävlar tror jag. ??? mm men detta blir nivån över.


;; typ modifiers. första sätter key typ +60 på allt. sen konceptet skala?


