;;;; Matrix library
;;; matrix.lisp

(in-package #:mx)

(defclass matrix ()
   ((data-array
     :initarg :data-array
     :initform (error "DATA-ARRAY must be supplied.")
     :reader data-array
     :documentation "Two-dimensional array that holds the data of the matrix")
    (size
     :initarg :size
     :initform '(0 0)
     :reader size
     :documentation "The size of the matrix (height width)")))
     
(defgeneric (setf data-array) (data matrix))

(defmethod (setf data-array) (data (mat matrix))
  (setf (slot-value mat 'data-array) data)
  (setf (slot-value mat 'size) (list (height data) (width data)))
)
      
(defmethod print-object ((object matrix) stream)
  (print-unreadable-object (object stream :type t)
    (with-slots (data-array size) object
      (format stream "SIZE: ~a" size)
      (format-array data-array))))
            
(defun create-matrix (&key (initial-contents nil ic-supplied-p)
                           (dimensions nil d-supplied-p)
                           (initial-element 0))
     "Create a matrix."
     (let ((data-array
            (cond ((and ic-supplied-p (listp initial-contents)) (list-to-array initial-contents))
                  ((and ic-supplied-p (arrayp initial-contents)) initial-contents)
                  (d-supplied-p
                    (if (= (length dimensions) 2)
                        (make-array dimensions :initial-element initial-element)
                        (error "DIMENSIONS must be a list of 2 values")))
                  (t (error "INITIAL-CONTENTS or DIMENSIONS must be specified")))))
           (make-instance 'matrix :data-array data-array :size (list (height data-array) (width data-array)))))
      
(defun mheight (matrix)
    "Get the height of MATRIX (number of rows)"
    (car (slot-value matrix 'size)))
      
(defun mwidth (matrix)
    "Get the width of MATRIX (number of columns)"
    (cadr (slot-value matrix 'size)))
      
(defun zeros (height width)
    "Create a zero-filled 2-dimensional matrix."
    (create-matrix :dimensions (list height width) :initial-element 0))
    
(defun ones (height width)
    "Create a 2-dimensional matrix filled with 1's."
    (create-matrix :dimensions (list height width) :initial-element 1))
    
(defun ref (matrix height width)
    "Get a value from MATRIX at row HEIGHT and column WIDTH."
    (aref (slot-value matrix 'data-array) (1- height) (1- width)))
    
(defun set-value (matrix height width value)
    "Set a value from MATRIX at row HEIGHT and column WIDTH."
    (setf (aref (slot-value matrix 'data-array) (1- height) (1- width)) value))
    
(defun eye (height width)
    "Create an identity matrix."
    (let ((matrix (zeros height width)))
         (loop for col from 1 to (min height width) do
            (set-value matrix col col 1))
         matrix))
         
(defun add-matrices (matrix-1 matrix-2)
    "Add two matrices together."
    (create-matrix :initial-contents (add-arrays (slot-value matrix-1 'data-array) (slot-value matrix-2 'data-array))))
    
(defun add-scalar (matrix scalar)
    "Add scalar to a matrix."
    (let ((data (slot-value matrix 'data-array)))
        (create-matrix :initial-contents (scalar+ data scalar))))
    
(defun multiply-scalar (matrix scalar)
    "Multiply matrix by a scalar."
    (let ((data (slot-value matrix 'data-array)))
        (create-matrix :initial-contents (scalar* data scalar))))

(defun extract-row-as-list (matrix row)
    (loop for col from 1 to (mwidth matrix) collect
        (ref matrix row col)))
            
(defun extract-row-as-vector (matrix row)
    (list-to-array (extract-row-as-list matrix row)))
    
(defun extract-column-as-list (matrix col)
    (loop for row from 1 to (mheight matrix) collect
        (ref matrix row col)))
    
(defun is-square (matrix)
    "Determine if the matrix is a square matrix."
    (= (mwidth matrix) (mheight matrix)))

;; The following 4 functions are used for calculating determinants
(defun remove-elt-from-list (list elt)
    (append (subseq list 0 elt) (nthcdr (1+ elt) list)))

(defun remove-first-row (matrix)
    (let ((data (slot-value matrix 'data-array)))
         (create-matrix :initial-contents (cdr (mx-array:array-to-list data)))))

(defun remove-column (matrix col-num)
    (let ((data-list (mx-array:array-to-list (slot-value matrix 'data-array))))
         (create-matrix :initial-contents
            (mapcar #'(lambda (list) (remove-elt-from-list list (1- col-num))) data-list))))
            
(defun det (matrix)
    "Calculate determinant of a square matrix."
    (let ((w (mwidth matrix)))
        (if (is-square matrix)
            (cond ((= w 1) (ref matrix 1 1))
                  ((= w 2) (- (* (ref matrix 1 1) (ref matrix 2 2))
                              (* (ref matrix 1 2) (ref matrix 2 1))))
                  ((= w 3) (+ (- (* (ref matrix 1 1) (det (remove-column (remove-first-row matrix) 1)))
                                 (* (ref matrix 1 2) (det (remove-column (remove-first-row matrix) 2))))
                              (* (ref matrix 1 3) (det (remove-column (remove-first-row matrix) 3)))))
                  (t t))
            (error "Matrix dimensions do not match."))))

(defun r*c (matrix-1 matrix-2 row col)
    (apply #'+
        (mapcar #'*
            (extract-row-as-list matrix-1 row)
            (extract-column-as-list matrix-2 col))))

(defun multiply-matrices (matrix-1 matrix-2)
    "Multiply matrices."
    (let ((w1 (mwidth matrix-1))
          (h1 (mheight matrix-1))
          (w2 (mwidth matrix-2))
          (h2 (mheight matrix-2)))
         (if (= w1 h2)
             (create-matrix :initial-contents
                (loop for row from 1 to h1 collect
                    (loop for col from 1 to w2 collect
                        (r*c matrix-1 matrix-2 row col))))
             "cannot multiply: dimensions do not match")))
             
