(in-package :repetition)

;; supercollider samples

(defparameter *sc-buffer-max* 1024)
(defparameter *samplerate* 44100)
(defvar *sc-buffer* 0)
(defvar *sample-initialized* nil)
(defvar *path-buffer-cache* (make-hash-table :test 'equal))

(defun sc-nextbuffer ()
  (when (> *sc-buffer* *sc-buffer-max*)
    (setf *sc-buffer* 0))
  (incf *sc-buffer*))

(defun sc-get-buffer (path)
  (let ((buffer 
	 (gethash path *path-buffer-cache*)))
    (or buffer 
	(setf (gethash path *path-buffer-cache*) (sc-nextbuffer)))))

(synthdef =sample= ((outbus 0) (buffer nil) (pan 0) (amp 0.5) (rate 1))
  !(Out.ar
    outbus (* (Pan2.ar (PlayBuf.ar 1 buffer rate :doneAction 2)
		       pan)
	      amp)))

(defproto =sample-read= (=sample=))
(defproto =sample-allocate= (=sample=))
(defproto =sample-record= (=sample=))

(defreply makeosc ((event =sample-read=))
  (list "/b_allocRead" (buffer event) (or (path event) (error "sample needs path"))))

(defreply makeosc ((event =sample-allocate=))
  (list "/b_alloc" (buffer event) (* (buffer-length event) *samplerate*) (buffer-channels event)))

;; conveniance macro
(defmacro load-samples (&body args)
  "Takes a list of (object path object path...) and creates corresponding sample event objects."
  (cons 'progn
	(loop for (key val) on args by #'cddr :collect
	     `(make-sample ,key ,val))))

(defmacro make-sample (name path)
  `(progn
     (defproto ,name (=sample=)
       ((path ,path)
	(buffer (sc-get-buffer ,path))))
       ;; read the file into supercollider
     (sendnow (list (sheeple::object :parents (list =sample-read= ,name))))
     ,name))

(defmacro allocate (name channels length)
  `(progn (defproto ,name (=sample=)
	    ((buffer (sc-nextbuffer))
	     (buffer-channels ,channels)
	     (buffer-length ,length)))
	  (sendnow (list (m (list =sample-allocate= ,name))))
	  ,name))
	  
(defun record (sample)
  (m (list =sample-record= sample)))

;; multisamples

(defproto =multisample= ()
  ((sample-list nil)))

(defvar *note-values* '(("C" 0) ("D" 2) ("E" 4) ("F" 5) ("G" 7) ("A" 9) ("B" 11)))

(defun guess-note (path &optional (regexp "([A-G])(#?)([0-9])"))
  (multiple-value-bind (match vector)      
      (scan-to-strings regexp path)
    (declare (ignore match))
    (let ((list (coerce vector 'list)))
    (+
     ;; octave
     (* 12 (+ 1 (read-from-string (third list))))
     ;; #?
     (if (string= "" (second list)) 0 1)
     (cdr (assoc (string-upcase (first list)) *note-values* :test 'string=))))))

(defun multisample (paths)
  (let ((multisample (sheeple::make =multisample=)))
    (dolist (number-path (sort (map 'list (lambda (x) (list (guess-note x) x)) paths) 
			       (lambda (x y) (< (first x) (first y)))))
      ;; create sample object and send read command
      (setf (getf (sample-list multisample) (first number-path))
	    (make-sample nil (second number-path))))
    multisample))