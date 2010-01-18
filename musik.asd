(require :osc)
(require :sb-bsd-sockets)
(require :sheeple)

(defpackage :musik
  (:use :cl :sb-bsd-sockets :osc :sheeple))

(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets #:sheeple)
  :components ((:file "osc")	       
	       (:file "lang"    :depends-on ("osc"))
	       (:file "play"    :depends-on ("lang"))
	       (:file "helpers" :depends-on ("lang"))
	       (:module "msgtypes"
			:components
			((:file "ksamp")
			 (:file "supercollider")))))
