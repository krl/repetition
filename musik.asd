(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets #:sheeple)
  :components ((:file "musik")
	       (:file "osc")
	       (:file "lang"    :depends-on ("osc"))
	       (:file "play"    :depends-on ("lang"))
	       (:file "helpers" :depends-on ("lang"))
	       (:module "msgtypes"
			:components
			((:file "ksamp")
			 (:file "supercollider")))))
