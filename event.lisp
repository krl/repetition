(in-package :repetition)

(defproto =event= ()
  ((timetag 0)
   (len 1)))

(defproto =nil= (=event=)
  ((timetag 0)
   (len 0)))