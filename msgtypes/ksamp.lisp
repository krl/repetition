
;; message type for supercollider synthdefs

(in-package :musik)

(defclass ks-message (message) 
  ((target :initform '(#(127 0 0 1) 7000))))

(defmessage ks-load ('ks-message :type "/ks_load"))
(defmessage ks-play ('ks-message :type "/ks_play"))

(defmethod makeosc ((item ks-message))
  ; takes an item and returns a list formatted as an OSC packet
  ; TODO, figure out what the "0 1" is all about..
  (with-slots (value) item
    (list (or (getf value :type) (error "ks-message requires :type value"))
	  (or (getf value :path) (error "sc-message requires :path value")))))
