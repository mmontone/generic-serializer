;;;; generic-serializer.asd

(asdf:defsystem #:generic-serializer
  :description "Generic api for object serialization"
  :author "Mariano Montone <marianomontone@gmail.com>"
  :license  "MIT"
  :version "0.0.1"
  :serial t
  :depends-on (:cxml :cl-who :cl-json)
  :components ((:file "package")
               (:file "generic-serializer")
               (:file "serializer")))
