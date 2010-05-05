(in-package :repetition)

(defvar *ingen-process* nil)
(defvar *port-index* 0)
(defparameter *ingen-wrapper* (namestring (asdf:system-relative-pathname :repetition "ingen-wrapper.sh")))

;; events

(defproto =ingen-event= (=event=)
  ((target '(#(127 0 0 1) 16180))))

(defproto =ingen-node= (=ingen-event=)
  ((path)
   (instance-of)))

(defproto =ingen-port= (=ingen-event=)
  ((path)
   (index)
   (name)
   (port-type)))

(defproto =ingen-connect= (=ingen-event=)
  ((from)
   (to)))

(defproto =ingen-clear= (=ingen-event=))

;; the process 

(defun ingen-start ()
  (setf *ingen-process*
	(sb-ext:run-program "/bin/sh" (list *ingen-wrapper*) :input :stream :output t :error t :wait nil)))

(defun ingen-clear ()
  (sendnow (list =ingen-clear=))
  (setf *port-index* 0))

(defun ingen-get-port-index ()
  (let ((index *port-index*))
    (incf *port-index*)
    index))

(defun ingen-make-port (name port-type)
  (sheeple::make =ingen-port= 
		 'path (concatenate 'string "path:/" name)
		 'index (ingen-get-port-index)
		 'name name
		 'port-type port-type))

(defun ingen-make-inport (name)
  (ingen-make-port name '|lv2:InputPort|))

(defun ingen-make-outport (name)
  (ingen-make-port name '|lv2:OutputPort|))

;; makeosc methods

(defreply makeosc ((event =ingen-clear=))
  (list "/ingen/clear_patch" 0 "/"))

(defreply makeosc ((event =ingen-connect=))
  (list "/ingen/connect" 0 
	(from event)
	(to event)))

(defreply makeosc ((event =ingen-port=))
  (list "/ingen/put" 0
	(path event)
	"lv2:index" (index event)
	"lv2:name" (name event)
	"rdf:type" '|lv2:AudioPort|
	"rdf:type" (port-type event)))

(defreply makeosc ((event =ingen-node=))
  (list "/ingen/put" 0
	(path event)
	"rdf:instanceOf" (instance-of event)
	"rdf:type" '|ingen:Node|))

(defun ingen-connect (from to)
  (sheeple::make =ingen-connect= 'from from 'to to))
