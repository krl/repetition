(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets #:sheeple)
  :serial t
  :components ((:file "musik")
	       (:file "lang")
	       (:file "osc")
	       (:file "play")
	       (:file "helpers")
	       (:file "sclang")
	       (:module "msgtypes"
			:serial t
			:components
			((:file "supercollider")
			 (:file "sample")))))