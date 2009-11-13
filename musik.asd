(require :osc)
(require :sb-bsd-sockets)

(defpackage :musik
  (:use :cl :sb-bsd-sockets :osc))

(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets)
  :components ((:file "osc")
	       (:file "supercollider")
	       (:file "theory")
	       (:file "lang")))
