(in-package #:lightfast)

;;; Table column normalization, record binding, and table constructors.

(defvar *table-record-registry* (make-hash-table))

(defstruct (table-column (:constructor %make-table-column
                            (key label width formatter)))
  key
  label
  width
  formatter)

(defun table-data-column-count (rows)
  (loop for row in rows
        maximize (length row) into count
        finally (return (or count 0))))

(defun humanize-column-key (key)
  (string-capitalize
   (substitute #\Space #\-
               (string-trim "*+"
                            (symbol-name key)))))

(defun column-property-spec-p (spec)
  (and (consp spec)
       (member (first spec) '(:key :label :width :formatter))))

(defun normalize-table-column (spec)
  (cond
    ((table-column-p spec)
     spec)
    ((symbolp spec)
     (%make-table-column spec (humanize-column-key spec) nil nil))
    ((functionp spec)
     (%make-table-column spec "" nil nil))
    ((column-property-spec-p spec)
     (let ((key (getf spec :key)))
       (%make-table-column key
                           (or (getf spec :label)
                               (if (symbolp key)
                                   (humanize-column-key key)
                                   ""))
                           (getf spec :width)
                           (getf spec :formatter))))
    ((consp spec)
     (destructuring-bind (key &optional label width formatter) spec
       (%make-table-column key
                           (or label
                               (if (symbolp key)
                                   (humanize-column-key key)
                                   ""))
                           width
                           formatter)))
    (t
     (error "Invalid table column spec ~S." spec))))

(defun normalize-table-columns (columns)
  (mapcar #'normalize-table-column columns))

(defun plist-record-value (record key marker)
  (getf record key marker))

(defun alist-record-value (record key marker)
  (let ((entry (assoc key record)))
    (if entry
        (cdr entry)
        marker)))

(defun function-record-value (record key marker)
  (handler-case
      (funcall key record)
    (error ()
      marker)))

(defun table-record-value (record key)
  (let ((marker (list :missing)))
    (cond
      ((functionp key)
       (let ((value (function-record-value record key marker)))
         (unless (eq value marker)
           value)))
      ((hash-table-p record)
       (multiple-value-bind (value present-p) (gethash key record)
         (when present-p
           value)))
      ((and (listp record)
            (not (consp (first record))))
       (let ((value (plist-record-value record key marker)))
         (unless (eq value marker)
           value)))
      ((listp record)
       (let ((value (alist-record-value record key marker)))
         (unless (eq value marker)
           value)))
      ((and (symbolp key)
            (not (keywordp key))
            (fboundp key))
       (let ((value (function-record-value record key marker)))
         (unless (eq value marker)
           value)))
      (t
       nil))))

(defun table-column-cell (column record)
  (let ((value (table-record-value record (table-column-key column))))
    (if (table-column-formatter column)
        (funcall (table-column-formatter column) value record)
        value)))

(defun table-record-row (columns record)
  (mapcar (lambda (column)
            (cell-string (table-column-cell column record)))
          columns))

(defun table-records (widget)
  (gethash (widget-id widget) *table-record-registry* #()))

(defun (setf table-records) (records widget)
  (setf (gethash (widget-id widget) *table-record-registry*)
        (coerce records 'vector)))

(defun table-set-size (widget rows columns)
  (%table-set-size (widget-id widget)
                   (max 0 rows)
                   (max 0 columns))
  widget)

(defun table-set-column-labels (widget labels)
  (loop for label in labels
        for column from 0
        do (%table-set-column-label (widget-id widget) column (cell-string label)))
  widget)

(defun table-set-column-widths (widget widths)
  (loop for width in widths
        for column from 0
        do (%table-set-column-width (widget-id widget) column (max 24 width)))
  widget)

(defun table-set-cell (widget row column value)
  (%table-set-cell (widget-id widget)
                   row
                   column
                   (cell-string value))
  widget)

(defun table-cell (widget row column)
  (foreign-string (lambda ()
                    (%table-get-cell (widget-id widget) row column))))

(defun table-set-row (widget row values)
  (loop for value in values
        for column from 0
        do (table-set-cell widget row column value))
  widget)

(defun table-set-rows (widget rows &key columns)
  (table-set-size widget
                  (length rows)
                  (or columns (table-data-column-count rows)))
  (loop for row-values in rows
        for row from 0
        do (table-set-row widget row row-values))
  widget)

(defun table-selected-row (widget)
  (%table-selected-row (widget-id widget)))

(defun table-selected-rows (widget)
  "Return selected table row indices in ascending order."
  (let ((value (foreign-string
                (lambda () (%table-selected-rows (widget-id widget))))))
    (if (string= value "")
        '()
        (mapcar #'parse-integer
                (uiop:split-string value :separator '(#\Space))))))

(defun table-select-row (widget row)
  (%table-select-row (widget-id widget) row)
  widget)

(defun table-current-column-width (widget column)
  (%table-column-width (widget-id widget) column))

(defun table-clear-rows (widget)
  (setf (table-records widget) #())
  (table-set-size widget 0 0))

(defun table-set-records (widget columns records)
  (let* ((normalized-columns (normalize-table-columns columns))
         (rows               (loop for record in records
                                   collect (table-record-row normalized-columns record))))
    (setf (table-records widget) records)
    (table-set-size widget (length rows) (length normalized-columns))
    (table-set-column-labels widget (mapcar #'table-column-label normalized-columns))
    (table-set-column-widths widget
                             (loop for column in normalized-columns
                                   collect (or (table-column-width column) 90)))
    (loop for row-values in rows
          for row from 0
          do (table-set-row widget row row-values))
    widget))

(defun table-selected-record (widget)
  (let ((row (table-selected-row widget)))
    (when (>= row 0)
      (let ((records (table-records widget)))
        (when (< row (length records))
          (aref records row))))))

(defun make-table
    (&key (parent *default-parent*) (x 0) (y 0) (width 260) (height 140)
          (label "") columns column-widths rows callback)
  (let* ((column-count (max (length columns)
                            (table-data-column-count rows)))
         (widget       (make-widget +widget-table+
                                    :parent parent
                                    :x      x
                                    :y      y
                                    :width  width
                                    :height height
                                    :label  label)))
    (table-set-size widget (length rows) column-count)
    (table-set-column-labels widget columns)
    (table-set-column-widths widget column-widths)
    (loop for row-values in rows
          for row from 0
          do (table-set-row widget row row-values))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-record-table
    (&key (parent *default-parent*) (x 0) (y 0) (width 260) (height 140)
          (label "") columns records callback)
  (let ((widget (make-widget +widget-table+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (table-set-records widget columns records)
    (when callback
      (on widget callback :event +event-change+))
    widget))
