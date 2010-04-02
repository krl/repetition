(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets #:sheeple)
  :serial t
  :components ((:file "musik")
	       (:file "event")
	       (:file "lang")
	       (:file "filters")
	       (:file "osc")
	       (:file "play")
	       (:file "helpers")
	       (:file "theory")
	       (:file "sclang")
	       (:module "msgtypes"
			:serial t
			:components
			((:file "supercollider")
			 (:file "sample")))))