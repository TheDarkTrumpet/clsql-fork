;;;; -*- Mode: LISP; Syntax: ANSI-Common-Lisp; Base: 10 -*-
;;;; *************************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          clsql-oracle.asd
;;;; Purpose:       ASDF definition file for CLSQL Oracle backend
;;;; Programmer:    Kevin M. Rosenberg
;;;; Date Started:  Aug 2002
;;;;
;;;; $Id$
;;;;
;;;; This file is part of CLSQL.
;;;;
;;;; CLSQL users are granted the rights to distribute and use this software
;;;; as governed by the terms of the Lisp Lesser GNU Public License
;;;; (http://opensource.franz.com/preamble.html), also known as the LLGPL.
;;;; *************************************************************************

(defpackage #:clsql-oracle-system (:use #:asdf #:cl))
(in-package #:clsql-oracle-system)

(eval-when (:compile-toplevel :load-toplevel :execute)
  #+common-lisp-controller (require 'uffi)
  #-common-lisp-controller (asdf:operate 'asdf:load-op 'uffi))

(defvar *library-file-dir* (append (pathname-directory *load-truename*)
				   (list "db-oracle")))

(defclass clsql-oracle-source-file (c-source-file)
  ())

(defmethod output-files ((o compile-op) (c clsql-oracle-source-file))
  (let* ((library-file-type
	  (funcall (intern (symbol-name'#:default-foreign-library-type)
			   (symbol-name '#:uffi))))
         (found (some #'(lambda (dir)
			    (probe-file (make-pathname :directory dir
						       :name (component-name c)
						       :type library-file-type)))
			'((:absolute "usr" "lib" "clsql"))))) 
    (list (if found
	      found
	      (make-pathname :name (component-name c)
			     :type library-file-type
			     :directory *library-file-dir*)))))

(defmethod perform ((o load-op) (c clsql-oracle-source-file))
  t)

(defmethod operation-done-p ((o load-op) (c clsql-oracle-source-file))
  (and (symbol-function (intern (symbol-name '#:oracle-get-client-info)
				(find-package '#:oracle)))
       t)) 

(defmethod perform ((o compile-op) (c clsql-oracle-source-file))
  (unless (operation-done-p o c)
    #-(or win32 mswindows)
    (unless (zerop (run-shell-command
		    #-freebsd "cd ~A; make"
		    #+freebsd "cd ~A; gmake"
		    (namestring (make-pathname :name nil
					       :type nil
					       :directory *library-file-dir*))))
      (error 'operation-error :component c :operation o))))

(defmethod operation-done-p ((o compile-op) (c clsql-oracle-source-file))
  (or (and (probe-file #p"/usr/lib/clsql/oracle.so") t)
      (let ((lib (make-pathname :defaults (component-pathname c)
				:type (uffi:default-foreign-library-type))))
	(and (probe-file lib)
	     (> (file-write-date lib) (file-write-date (component-pathname c)))))))


;;; System definition

(defsystem clsql-oracle
  :name "clsql-oracle"
  :author "Kevin M. Rosenberg <kmr@debian.org>"
  :maintainer "Kevin M. Rosenberg <kmr@debian.org>"
  :licence "Lessor Lisp General Public License"
  :description "Common Lisp SQL Oracle Driver"
  :long-description "cl-sql-oracle package provides a database driver to the Oracle database system."

  :depends-on (clsql-uffi)
  :components
    ((:module :db-oracle
	      :components
	      ((:file "oracle-package")
	       (:file "oracle-loader" :depends-on ("oracle-package"))
	       (:file "foreign-resources" :depends-on ("oracle-package"))
	       (:file "oracle-constants" :depends-on ("oracle-package"))
	       (:file "oracle-api" :depends-on ("oracle-constants" "oracle-loader"))
	       (:file "oracle-sql" :depends-on ("oracle-api" "foreign-resources"))
	       (:file "oracle-objects" :depends-on ("oracle-sql"))))))
