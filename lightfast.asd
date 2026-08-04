(asdf:defsystem #:lightfast
  :description "Small, direct Common Lisp bindings for FLTK 1.4."
  :author "Lukas Hozda"
  :license "MIT"
  :depends-on (#:cffi)
  :serial t
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "package")
     (:file "bridge")
     (:file "core")
     (:file "runtime")
     (:file "geometry")
     (:module "constructors"
      :serial t
      :components
      ((:file "basics")
       (:file "buttons")
       (:file "text")
       (:file "choices")
       (:file "values")))
     (:file "tables")
     (:file "layout")
     (:file "dialogs")))))
