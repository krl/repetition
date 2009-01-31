(require :cffi)
(defpackage :musik (:use :cl :cffi))
(in-package :musik)

(setf *random-state* (make-random-state t))

;; variables
(defvar +jack-default-midi-type+ "8 bit raw midi")
(defvar +thread-timeout+ 2)

(defvar *jack-client* nil)
(defvar *jack-midi-out* nil)
(defvar *jack-active* nil)
(defvar *client-name* nil)
(defvar *midibuffer* nil)

(define-foreign-library libjack
  (:unix "libjack.so")
  (t (:default "libjack")))

(use-foreign-library libjack)

(defcfun jack-client-new :pointer
  (name :string))

(defcfun jack-activate :int
  (jack-client :pointer))

(defcfun jack-deactivate :int
  (jack-client :pointer))

(defcfun jack-cpu-load :float 
  (jack-client :pointer))

(defcfun jack-get-client-name :string
  (jack-client :pointer))

(defcfun jack-port-register :pointer ; returns C type jack_port_t * 
  (jack-client :pointer)
  (port-name   :string)
  (port-type   :string)
  (flags       :int)
  (buffer-size :int))

(defcfun jack-connect :int 
  (jack-client :pointer)
  (source-port :string)
  (dest-port   :string))

(defcfun jack-set-process-callback :void
  (jack-client :pointer)
  (callback :pointer)
  (arg :int))

(defcfun jack-on-shutdown :void
  (jack-client :pointer)
  (callback :pointer)
  (arg :int))

(defcfun jack-set-sample-rate-callback :void
  (jack-client :pointer)
  (callback :pointer)
  (arg :int))

(defcfun jack-port-get-buffer :pointer
  (jack-port :pointer)
  (nframes :int))

(defcfun jack-midi-clear-buffer :void
  (jack-port :pointer))

(defcfun jack-midi-event-write :int
  (port-buffer :pointer)
  (time        :long)
  (data        :pointer)
  (size        :int))

(defcfun jack-set-error-function :void
  (callback :pointer))
   
;;;;;;;;;;;;; callbacks

(defcallback error-cb :int ((err :string))
  (format t "ERROR: ~a~%" err)
  0)

(defcallback samplerate-cb :int ((nframes :int) (arg :pointer))
  (declare (ignore arg))
  (format t "samplerate ~a~%" nframes)
  0)

(defcallback shutdown-cb :void ((arg :pointer))
  (declare (ignore arg))
  (setf *jack-active* nil)
  (format t "got shutdown signal"))


(defcallback process-cb :void ((nframes :int) (arg :pointer))
  (declare (ignore arg))
  (declare (fixnum nframes))

    (let ((out (jack-port-get-buffer *jack-midi-out* nframes)))
      (when (not (cffi:null-pointer-p out))
	(jack-midi-clear-buffer out)

	(when (zerop (random 10))
	  (setf (mem-aref *midibuffer* :unsigned-char 0) #x90 ; noteon first channel
		(mem-aref *midibuffer* :unsigned-char 1) (+ 40 (* 2 (random 24)))
		(mem-aref *midibuffer* :unsigned-char 2) 100)

	  (jack-midi-event-write out 0 *midibuffer* 3))))
  0)

;;;;;;;;;;;;;; init

(defvar *count* 0)

(if (cffi:null-pointer-p (setf *jack-client* (jack-client-new (setf *client-name* (format nil "lisp~a" (random 1000))))))
    (format t "could not connect to jack~%")
    (sb-sys:without-gcing 
    	
      (format t "starting client ~a~%" *client-name*)

      (setf *jack-active* t)
      (setf *last-callback* (get-universal-time))

      ;; alloc foreign midi buffer
      (setf *midibuffer* (foreign-alloc :unsigned-char :count 3))

      (jack-on-shutdown *jack-client* (callback shutdown-cb) 0)
      (jack-set-error-function (callback error-cb))
      (jack-set-process-callback *jack-client* (callback process-cb) 0)

      (setf *jack-midi-out* (jack-port-register *jack-client* "midi_out" +jack-default-midi-type+ 2 0))
      (jack-activate *jack-client*)
      (jack-connect *jack-client* (format nil "~a:midi_out" *client-name*) "specimen:midi_input")

      (let ((name (jack-get-client-name *jack-client*)))
	(loop
	   (sleep 1)
	   (format t "name ~a~%" name)))
      
					;      (jack-deactivate *jack-client*)

      (format t "disconnected??~%")

      ;; last free the memory

      (foreign-free *midibuffer*)))