;;;; generic-serializer.lisp

(in-package #:generic-serializer)

(defvar *serializers* nil)
(defvar *serializer-output* t)
(defvar *default-serializer* :json "The default api serializer")
(defvar *serializer* nil)

;; Serializer api

(defun call-with-serializer (serializer function)
  (let ((*serializer* serializer))
    (serialize-toplevel serializer
                        *serializer-output*
                        function)))

(defmacro with-serializer (serializer &body body)
  "Execute body in serializer scope. Binds *serializer* to serializer.

     Example:
     (with-serializer :json
      (serialize user))"
  `(call-with-serializer ,serializer (lambda () ,@body)))

(defun call-with-serializer-output (serializer-output function)
  (let ((*serializer-output* serializer-output))
    (funcall function)))

(defmacro with-serializer-output (serializer-output &body body)
  "Defines the serializer output when executing body.

     Example:
     (with-serializer-output s
        (with-serializer :json
           (serialize user)))"

  `(call-with-serializer-output ,serializer-output (lambda () ,@body)))

;; Generic streaming serialization api

(defmacro with-object ((name
                        &key (serializer '*serializer*)
                          (stream '*serializer-output*))
                       &body body)
  "Serializes a serializing object."
  `(call-with-object ,serializer ,name (lambda () ,@body) ,stream))

(defmacro with-attribute ((name &key (serializer '*serializer*)
                                  (stream '*serializer-output*))
                          &body body)
  "Serializes an object attribute"
  `(call-with-attribute ,serializer
                        ,name
                        (lambda () ,@body)
                        ,stream))

(defmacro with-list
    ((name &key (serializer '*serializer*)
             (stream '*serializer-output*))
     &body body)
  "Serializes an list of objects"
  `(call-with-list ,serializer ,name (lambda () ,@body) ,stream))

(defmacro with-list-member ((name
                             &key (serializer '*serializer*)
                               (stream '*serializer-output*))
                            &body body)
  "Serializes a list member"
  `(call-with-list-member ,serializer ,name (lambda () ,@body) ,stream))
