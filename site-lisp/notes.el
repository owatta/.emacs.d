;;; notes.el --- Simple, Plain-Text Notes With Search & Backlinks. -*- lexical-binding: t; -*-

;;; Commentary:
;;; Nothing else worked for me, so I wrote my own thing :3

;;; Code:

(defgroup notes ()
  "Simple, Plain-Text Notes With Search & Backlinks."
  :group 'files)

(defcustom notes-directory "~/Documents/notes/"
  "Directory containing notes."
  :type 'directory
  :group 'notes)

(defcustom notes-file-extension ".org"
  "File type extension for new notes."
  :type 'string
  :group 'notes)

(defcustom notes-id-format "%y%j%H%M"
  "Note ID format.

Each note gets a unique ID, based on the time of it's creation.
It is important for the ID to be unique, as it is used for
linking notes. The default format is `YYDDDHHMM' where:

YY - year without the century,
DDD - day of the year,
HH - hour,
MM - minute."
  :type 'string
  :group 'notes)

(defun notes-create-id ()
  "Create a note ID."
  (format-time-string notes-id-format))

(defun notes-find-note (name)
  "Open note NAME, if exists. Otherwise, create one."
  (interactive (list (completing-read
		      "Note Title: "
		      (directory-files notes-directory nil "[^\.\.?]"))))
  (if (and name (file-exists-p (concat notes-directory name)))
      (find-file (concat notes-directory name))
    (progn (find-file (concat notes-directory (notes-create-id) notes-file-extension))
	   (insert name))))

(provide 'notes)
;;; notes.el ends here
