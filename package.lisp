;;;; package.lisp

(defpackage #:generic-serializer
  (:use #:cl)
  (:export
   #:with-serializer
   #:with-serializer-output
   #:accept-serializer
   #:object
   #:attribute
   #:objects
   #:serialize
   #:with-object
   #:with-attribute
   #:with-list
   #:with-list-member
   #:add-list-member
   #:set-attribute
   #:name
   #:attributes
   #:value
   #:boolean-value
   #:list-value
   #:serialize-value
   #:serialization
   #:unserialization
   #:*default-serializer*))
