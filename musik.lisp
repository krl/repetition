(defpackage :musik
  (:documentation "A graphical roguelike game engine for Common Lisp.")  
  (:use :cl) 
  (:export *samplerate*
	   make-note
	   make-span
	   multi-spans))
(in-package :musik)