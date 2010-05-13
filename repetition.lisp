(defpackage :repetition
  (:use :cl :sb-bsd-sockets :kosc :sheeple :cl-ppcre)
  (:export
   ;; objects
   #:=event=
   #:=nil=

   ;; language
   #:join
   #:join-n
   #:join-nv
   #:seq
   #:seq-n
   #:seq-nv
   #:seq-len

   ;; helpers
   #:oneof
   #:lenlist
   #:offset

   ;; properties
   #:ass
   #:property

   ;; filters
   #:trim
   #:over

   ;; sequence helpers
   #:sq
   #:sq1

   ;; special properties
   #:amp
   #:len
   #:pan
   #:outbus
   #:buffer
   #:rate
   #:timetag

   ;; supercollider
   #:sclang-start
   #:synthdef

   ;; samples
   #:load-samples

   ;; sequencer control
   #:play
   #:stop))
