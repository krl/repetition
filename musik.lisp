(require :osc)
(require :sb-bsd-sockets)

(in-package :sb-bsd-sockets)

(defvar *socket*)
(defvar *node* 2)
(defvar *node-max* 1024)


(defun flatten (tree)
  (let ((result '()))
    (labels ((scan (item)
               (if (listp (first item))
		   (map nil #'scan item)
		   (push item result))))
      (scan tree))
    (nreverse result)))

(defmacro nlet (n letargs &body body)
  `(labels ((,n ,(mapcar #'car letargs)
              ,@body))
     (,n ,@(mapcar #'cadr letargs))))

(defun next-node ()
  (if (= (incf *node*) *node-max*)
      (setf *node* 2))
  *node*)
      
(setf *socket* (make-instance 'inet-socket 
			      :protocol :udp 
			      :type :datagram))

(defun subsecs ()
  (second (multiple-value-list (floor (/ (get-internal-real-time) internal-time-units-per-second)))))

(defun now (&optional future)
  (+ 0.0d0
     (get-universal-time)
     (subsecs)
     (or future 0)))

(defmacro on-all (list &body function)
  `(map 'list ,@function (flatten ,list)))

(defun send (timetag &rest messages)
  (on-all messages
    (lambda (x)
      (let* ((offset (if timetag
		       (+ timetag (or (getf x :offset) 0))))
	 (bundle (osc:encode-bundle (makeosc x) offset)))
    (socket-send *socket* bundle
		 (length bundle)
		 :address '(#(127 0 0 1) 57110))))))

(defun sendnow (&rest messages)
  (send (now 0.5) messages))

(defun makeosc (msg)
  (let ((list (list (getf msg :type)
		    (getf msg :name)
		    (next-node) 0 1)))
	(nlet deplist ((plist msg))
	  (case (first plist)
	    ((:type :name)
	     nil)
	    (t
	     (nconc list (list (format nil "~(~a~)" (symbol-name (first plist))) ;; lowercase..
			       (eval (second plist))))))
	  (if (cddr plist)
	      (deplist (cddr plist))))
	list))

(defun add (values &rest to)
  (on-all to 
    (lambda (x)
      (let ((copy (copy-list x)))
	(nlet setvals ((plist values))
	  (when plist
	    (setf (getf copy (first plist))
		  (second plist))
	    (setvals (cddr plist))))
	copy))))

(defun drum (which &optional values)
  (append (list :type "/s_new"
		:name which)
	  values))

(setf -kick  (drum "kick"))
(setf -snare (drum "snare"))
(setf -hat1  (drum "hat1"))
(setf -hat2  (drum "hat2"))
(setf -nop (list :type "nop"
		 :name "nop"))

(setf *test*
      '(:type "/s_new"
	:name "test"
	:pan (- 1 (random 2.0))
	:amp 1
	:sustain 0.2
	:freq (* 44 (+ 1 (random 2)))))

(defun len (&rest seq)
  (nlet maxlen ((s (flatten seq)))
    (max (+ (or (getf (first s) :offset) 0)
	    (or (getf (first s) :length) 0))
	 (if (second s) (maxlen (rest s)) 0))))

(defun s (seq)
  (let ((offset 0))
    (on-all seq
      (lambda (x)	
	(let ((new (add (list :offset offset) x)))
	  (incf offset (len x))
	  new))))) ;; workaround for this??

;; (defun scale (seq)
;;   (on-all seq
;;     (lambda (x)
      
(nconc nil (list 1))

(defmacro n (n &body body)
  `(flatten
    (let ((list nil))
      (loop for i from 0 below ,n collect
	   (list ,@body)))))

;; (d 2 -kick)

(defun wowowo (howlong)
  (n howlong
    (add '(:length 0.1
	   :freq   40)
	 *test*)))

(defun weu (howlong)
  (add (list :length  (* 0.1 howlong)
	     :freq    80
	     :wobfreq howlong)
       *test*))

(sendnow 
 (s
  (n 4
    (wowowo 8)
    (weu    3)
    (weu    3)
    (weu    2))))

(len (bassthing))

(sendnow
 (s
  (sleep (len (bassthing))
 (s
  (n 8
    (add '(:length 0.1)
	 -kick  -snare
	 -kick  -nop
	 -snare -nop
	 -hat1  -hat2
	 -hat1  -hat2
	 -kick  -nop
	 -snare -nop
	 -kick  -hat2))))

;; Around! :offset 3 -> :offset (+ 1 3)

;; när :key values evalueras kan de kolla upp saker. t.ex en 
;; global lista som mappar tider mot cutoff etc.. och har då tillgång till hela trädet!! :)

