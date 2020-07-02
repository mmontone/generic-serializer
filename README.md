# GENERIC-SERIALIZER

Serialize to different format (JSON, XML) using a common api.

This library is used in CL-REST-SERVER.

## Example

```lisp
(with-output-to-string (s)
  (with-serializer-output s
    (with-serializer :json
      (with-object ("user")
        (set-attribute "id" 22)
        (with-attribute ("realname")
          (serialize "Mike"))
        (with-attribute ("groups")
          (with-list ("groups")
            (with-list-member ("group")
              (with-object ("group")
                (set-attribute "id" 33)
                (set-attribute "title" "My group")))))))))
```

## Functions

### add-list-member

```lisp
(name value &key (serializer *serializer*) (stream *serializer-output*))
```

Serializes a list member





### attribute

```lisp
(name value &optional type formatter)
```

Build an object attribute to be serialized





### object

```lisp
(name &rest attributes)
```

Build an object to be serialized





### objects

```lisp
(name &rest objects)
```

Build a list of objects to be serialized





### set-attribute

```lisp
(name value &rest args &key (serializer *serializer*)
      (stream *serializer-output*) &allow-other-keys)
```

Serializes an object attribute and value





## Macros
### with-attribute

```lisp
((name &key (serializer) (stream)) &body body)
```

Serializes an object attribute





### with-list

```lisp
((name &key (serializer) (stream)) &body body)
```

Serializes an list of objects





### with-list-member

```lisp
((name &key (serializer) (stream)) &body body)
```

Serializes a list member





### with-object

```lisp
((name &key (serializer) (stream)) &body body)
```

Serializes a serializing object.





### with-serializer

```lisp
(serializer &body body)
```

Execute body in serializer scope. Binds *serializer* to serializer.



Example:
     (with-serializer :json
      (serialize user))

### with-serializer-output

```lisp
(serializer-output &body body)
```

Defines the serializer output when executing body.



Example:
     (with-serializer-output s
        (with-serializer :json
           (serialize user)))

## Generic-Functions
### serialize
Main serialization function. Takes the object to serialize, the serializer and the output stream

## Slot-Accessors
## Variables
### \*default-serializer\*
The default api serializer

## Classs
### attribute
Serializer intermediate representation object attribute class

### object
Serializer intermediate representation object class

## Conditions
## Constants
