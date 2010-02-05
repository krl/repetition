(asdf:defsystem #:musik
  :depends-on (#:osc #:sb-bsd-sockets #:sheeple)
  :components ((:file "musik")
	       (:file "osc"     :depends-on ("musik"))
	       (:file "lang"    :depends-on ("osc"))
	       (:file "play"    :depends-on ("lang"))
	       (:file "helpers" :depends-on ("lang"))
	       (:file "sclang"  :depends-on ("helpers"))
	       (:module "msgtypes"
			:depends-on ("helpers")
			:components
			((:file "supercollider")
			 (:file "sample" :depends-on ("supercollider"))))))