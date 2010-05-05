(asdf:defsystem #:repetition
  :version "0.1"
  :description "Algorithmic Sequencing using OSC"
  :author "Kristoffer Ström <first name at rymdkoloni.se>"
  :licence "GPLv3 or later"
  :depends-on (#:sb-bsd-sockets #:kosc #:sheeple #:cl-ppcre)
  :serial t
  :components ((:file "repetition")
	       (:file "event")
	       (:file "lang")
	       (:file "filters")
	       (:file "osc")
	       (:file "play")
	       (:file "helpers")
	       (:file "theory")
	       ;; processes
	       (:file "sclang")
	       (:file "ingen")

	       (:module "msgtypes"
			:serial t
			:components
			((:file "supercollider")
			 (:file "sample")))))