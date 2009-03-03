;;; -*- Mode: Lisp; -*-

(defpackage :musik-asd
  (:use :common-lisp :asdf))
(in-package :musik-asd)

(asdf:defsystem musik
  :name "musik"
  :version "0.1"
  :maintainer "Kristoffer Ström"
  :author "Kristoffer Ström"
  :license "General Public License (GPL) Version 3 or later"
  :description "Algorithmic music language"
  :serial t
;;;   :depends-on (:common-lisp)
  :components ((:file "musik")
	       (:file "helpers")
	       (:file "pipe")
	       (:file "sets")))