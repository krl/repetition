(require :osc)
(require :sb-bsd-sockets)

(defpackage :musik
  (:use :cl :sb-bsd-sockets :osc))

(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets)
  :components ((:file "osc")
	       (:module "msgtypes" :depends-on ("osc")
			:components
			((:file "supercollider")
			 (:file "ksamp")
			 (:file "sooperlooper")))
	       (:file "theory")
	       (:file "lang")
	       (:file "loop")))

