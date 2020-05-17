(in-package :generic-serializer)

;; Intermediate representation

(defclass object ()
  ((name :initarg :name
         :accessor name
         :initform (error "Provide a name for the object"))
   (attributes :initarg :attributes
               :accessor attributes
               :initform nil))
  (:documentation "Serializer intermediate representation object class"))

(defclass attribute ()
  ((name :initarg :name
         :accessor name
         :initform (error "Provide the attribute name"))
   (value :initarg :value
          :accessor value
          :initform (error "Provide the attribute value"))
   (type :initarg :type
         :accessor attr-type
         :initform nil
         :documentation "The attribute type")
   (formatter :initarg :formatter
              :accessor attribute-formatter
              :initform nil
              :documentation "Attribute formatter"))
  (:documentation "Serializer intermediate representation object attribute class"))

(defclass objects-list ()
  ((name :initarg :name
         :accessor name
         :initform (error "Provide the list name"))
   (objects :initarg :objects
            :accessor list-objects
            :initform nil))
  (:documentation "Serializer intermediate representation list of objects class"))

(defun object (name &rest attributes)
  "Build an object to be serialized"
  (make-instance 'object
                 :name name
                 :attributes attributes))

(defun attribute (name value &optional type formatter)
  "Build an object attribute to be serialized"
  (make-instance 'attribute
                 :name name
                 :value value
                 :type type
                 :formatter formatter))

(defun objects (name &rest objects)
  "Build a list of objects to be serialized"
  (make-instance 'objects-list
                 :name name
                 :objects objects))

(defmethod serialize-toplevel ((serializer t) stream function)
  (funcall function))

(defmethod serialize-toplevel ((serializer (eql :xml)) stream function)
  (cxml:with-xml-output (cxml:make-character-stream-sink
                         stream
                         :indentation nil
                         :omit-xml-declaration-p t)
    (funcall function)))

(defmethod serialize-toplevel ((serialize (eql :html)) stream function)
  (let ((cl-who::*html-mode* :html5))
    (format stream "<!DOCTYPE html>")
    (cl-who:with-html-output (html stream :prologue nil)
      (funcall function))))

;; Serializer format plug

(defgeneric serialize (object &optional serializer stream &rest args)
  (:documentation "Main serialization function. Takes the object to serialize, the serializer and the output stream"))

(defmethod serialize ((object object) &optional (serializer *serializer*) (stream *serializer-output*) &rest args)
  (declare (ignore args))
  (serialize-object serializer object stream))

(defmethod serialize ((objects-list objects-list) &optional (serializer *serializer*) (stream *serializer-output*) &rest args)
  (declare (ignore args))
  (serialize-objects-list serializer objects-list stream))

(defmethod serialize ((attribute attribute) &optional (serializer *serializer*) (stream *serializer-output*) &rest args)
  (declare (ignore args))
  (serialize-attribute serializer attribute stream))

(defmethod serialize ((value t) &optional (serializer *serializer*) (stream *serializer-output*) &rest args)
  (apply #'serialize-value serializer value stream args))

(defun boolean-value (boolean &optional (serializer *serializer*)
                                (stream *serializer-output*))
  (serialize-value serializer boolean stream :type :boolean))

(defun list-value (list &optional (serializer *serializer*)
                          (stream *serializer-output*))
  (assert (listp list) nil "Should be a list")
  (serialize-value serializer list stream :type :list))

(defmethod serializer-content-type ((serializer (eql :html)))
  "text/html")

;; Json serializer

(defmethod serializer-content-type ((serializer (eql :json)))
  "application/json")

(defmethod serialize-object ((serializer (eql :json)) object stream)
  (json:with-object (stream)
    (loop for attribute in (attributes object)
          do
             (serialize attribute serializer stream))))

(defmethod serialize-objects-list ((serializer (eql :json)) objects-list stream)
  (json:with-array (stream)
    (loop for object in (list-objects objects-list)
          do
             (json:as-array-member (stream)
               (serialize object serializer stream)))))

(defmethod serialize-attribute ((serializer (eql :json)) attribute stream)
  (json:as-object-member ((name attribute) stream)
    (serialize (value attribute) serializer stream
               :type (attr-type attribute)
               :formatter (attribute-formatter attribute))))

(defmethod serialize-value ((serializer (eql :json)) value stream &key type formatter &allow-other-keys)
  (let ((formatted-value (or (and formatter (funcall formatter value))
                             value)))
    (case type
      (:list (json:with-array (stream)
               (loop for elem in value
                     do
                        (json:as-array-member (stream)
                          (serialize elem serializer stream)))))
      (:boolean (if value
                    (json:encode-json t stream)
                    (json:encode-json :false stream)))
      (t (json:encode-json formatted-value stream)))))

;; XML serializer

(defmethod serializer-content-type ((serializer (eql :xml)))
  "application/xml")

(defmethod serialize-object ((serializer (eql :xml)) object stream)
  (cxml:with-element (name object)
    (loop for attribute in (attributes object)
          do (serialize attribute serializer stream))))

(defmethod serialize-objects-list ((serializer (eql :xml)) objects-list stream)
  (loop for object in (list-objects objects-list)
        do
           (serialize object serializer stream)))

(defmethod serialize-attribute ((serializer (eql :xml)) attribute stream)
  (cxml:with-element (name attribute)
    (serialize (value attribute) serializer stream
               :type (attr-type attribute)
               :formatter (attribute-formatter attribute))))

(defmethod serialize-value ((serializer (eql :xml)) value stream &key type formatter &allow-other-keys)
  (declare (ignore type formatter))
  (cxml:text (prin1-to-string value)))

;; SEXP serializer

(defmethod serializer-content-type ((serializer (eql :sexp)))
  "text/lisp")

(defmethod serialize-object ((serializer (eql :sexp)) object stream)
  (format stream "(~s (" (name object))
  (loop for attribute in (attributes object)
        do (serialize attribute serializer stream))
  (format stream "))"))

(defmethod serialize-objects-list ((serializer (eql :sexp)) objects-list stream)
  (format stream "(")
  (loop for object in (list-objects objects-list)
        do
           (serialize object serializer stream)
           (format stream " "))
  (format stream ")"))

(defmethod serialize-attribute ((serializer (eql :sexp)) attribute stream)
  (format stream "(~S . " (name attribute))
  (serialize (value attribute) serializer stream
             :type (attr-type attribute)
             :formatter (attribute-formatter attribute))
  (format stream ")"))

(defmethod serialize-value ((serializer (eql :sexp)) value stream &key type formatter &allow-other-keys)
  (declare (ignore type formatter))
  (prin1 value stream))

;; HTML serializer

(defmethod serialize-object ((serializer (eql :html)) object stream)
  (cl-who:with-html-output (html stream)
    (:div :class "object"
          (:h1 (cl-who:str (name object)))
          (:div :class "attributes"
                (mapcar (lambda (attribute)
                          (cl-who:htm
                           (serialize attribute serializer stream)))
                        (attributes object))))))

(defmethod serialize-objects-list ((serializer (eql :html)) objects-list stream)
  (cl-who:with-html-output (html stream)
                                        ;(:ol :class "objects"
    (format stream "<ol class=\"objects\">")
    (loop for object in (list-objects objects-list)
          do
             (cl-who:htm
              (:li (serialize object serializer stream))))
    (format stream "</ol>")))

(defmethod serialize-attribute ((serializer (eql :html)) attribute stream)
  (cl-who:with-html-output (html stream)
    (:div :class "attribute-name"
          (cl-who:str (name attribute)))
    (:div :class "attribute-value"
          (cl-who:str (serialize (value attribute) serializer stream
                                 :type (attr-type attribute)
                                 :formatter (attribute-formatter attribute))))))

(defmethod serialize-value ((serializer (eql :html)) value stream &key type formatter &allow-other-keys)
  (declare (ignore type formatter))
  (cl-who:with-html-output (html stream)
    (cl-who:fmt "~A" value)))

;; Streaming api implementation

(defgeneric call-with-object (serializer name body stream)
  (:method (serializer name body stream)
    (error "Unknown serializer: ~A. If NIL, remember to wrap with with-serializer."
           serializer)))

(defmethod call-with-object ((serializer (eql :json)) name body stream)
  (declare (ignore name))
  (json:with-object (stream)
    (funcall body)))

(defmethod call-with-object ((serializer (eql :xml)) name body stream)
  (declare (ignore stream))
  (cxml:with-element (coerce name 'runes:simple-rod)
    (funcall body)))

(defmethod call-with-object ((serializer (eql :html)) name body stream)
  (cl-who:with-html-output (html stream)
    (:div :class "object"
          (:h1 (cl-who:str name))
          (:div :class "attributes"
                (funcall body)))))

(defmethod call-with-object ((serializer (eql :sexp)) name body stream)
  (format stream "(~s (" name)
  (funcall body)
  (format stream "))"))

(defmethod call-with-attribute ((serializer (eql :json)) name body stream)
  (json:as-object-member (name stream)
    (funcall body)))

(defmethod call-with-attribute ((serializer (eql :xml)) name body stream)
  (declare (ignore stream))
  (cxml:with-element (coerce (string name) 'runes:simple-rod)
    (funcall body)))

(defmethod call-with-attribute ((serializer (eql :html)) name body stream)
  (cl-who:with-html-output (html stream)
    (:div :class "attribute-name"
          (cl-who:str name))
    (:div :class "attribute-value"
          (funcall body))))

(defmethod call-with-attribute ((serializer (eql :sexp)) name body stream)
  (format stream "(~S . " name)
  (funcall body)
  (format stream ")"))

(defun set-attribute (name value &rest args
                      &key
                        (serializer *serializer*)
                        (stream *serializer-output*) &allow-other-keys)
  "Serializes an object attribute and value"
  (with-attribute (name :serializer serializer
                        :stream stream)
    (apply #'serialize value serializer stream args)))

(defmethod call-with-list ((serializer (eql :json)) name body stream)
  (declare (ignore name))
  (json:with-array (stream)
    (funcall body)))

(defmethod call-with-list ((serializer (eql :xml)) name body stream)
  (declare (ignore name stream))
  (funcall body))

(defmethod call-with-list ((serializer (eql :html)) name body stream)
  (cl-who:with-html-output (html stream)
    (:ol (funcall body))))

(defmethod call-with-list ((serializer (eql :sexp)) name body stream)
  (format stream "(")
  (funcall body)
  (format stream ")"))

(defmethod call-with-list-member ((serializer (eql :json)) name body stream)
  (declare (ignore name))
  (json:as-array-member (stream)
    (funcall body)))

(defmethod call-with-list-member ((serializer (eql :xml)) name body stream)
  (with-object (name :serializer serializer
                     :stream stream)
    (funcall body)))

(defmethod call-with-list-member ((serializer (eql :html)) name body stream)
  (declare (ignore name))
  (cl-who:with-html-output (html stream)
    (:li
     (funcall body))))

(defmethod call-with-list-member ((serializer (eql :sexp)) name body stream)
  (declare (ignore name))
  (funcall body)
  (format stream " "))

(defun add-list-member (name value &key (serializer *serializer*)
                                     (stream *serializer-output*))
  "Serializes a list member"
  (with-list-member (name :serializer serializer
                          :stream stream)
    (serialize value serializer stream)))
