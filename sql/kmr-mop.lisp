;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-
;;;; *************************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          kmr-mop.lisp
;;;; Purpose:       MOP support for multiple-implementions
;;;; Programmer:    Kevin M. Rosenberg
;;;; Date Started:  Apr 2003
;;;;
;;;; $Id$
;;;;
;;;; This file imports MOP symbols into the CLSQL-MOP package and then
;;;; re-exports into CLSQL-SYS them to hide differences in
;;;; MOP implementations.
;;;;
;;;; This file was extracted from the KMRCL utilities
;;;; *************************************************************************

(in-package #:clsql-sys)

#+lispworks
(defun intern-eql-specializer (slot)
  `(eql ,slot))

(defmacro process-class-option (metaclass slot-name &optional required)
  #+lispworks
  `(defmethod clos:process-a-class-option ((class ,metaclass)
					   (name (eql ,slot-name))
					   value)
    (when (and ,required (null value))
      (error "metaclass ~A class slot ~A must have a value" (quote ,metaclass) name))
    (list name `',value))
  #-lispworks
    (declare (ignore metaclass slot-name required))
    )

(defmacro process-slot-option (metaclass slot-name)
  #+lispworks
  `(defmethod clos:process-a-slot-option ((class ,metaclass)
					  (option (eql ,slot-name))
					  value
					  already-processed-options
					  slot)
    (list* option `',value already-processed-options))
  #-lispworks
  (declare (ignore metaclass slot-name))
  )

(defun ordered-class-slots (class)
  #+(or cmu sbcl) (class-slots class)
  #-(or cmu sbcl) (reverse (class-slots class)))