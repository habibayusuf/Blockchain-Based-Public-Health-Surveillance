;; Health Authority Verification Contract
;; Manages verification and authorization of health monitoring agencies

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))

;; Data structures
(define-map verified-authorities principal
  {
    name: (string-ascii 100),
    jurisdiction: (string-ascii 100),
    verification-date: uint,
    is-active: bool
  })

(define-map authority-permissions principal (list 10 (string-ascii 50)))

;; Read-only functions
(define-read-only (is-verified-authority (authority principal))
  (match (map-get? verified-authorities authority)
    authority-data (get is-active authority-data)
    false))

(define-read-only (get-authority-info (authority principal))
  (map-get? verified-authorities authority))

(define-read-only (get-authority-permissions (authority principal))
  (default-to (list) (map-get? authority-permissions authority)))

;; Public functions
(define-public (verify-authority (authority principal) (name (string-ascii 100)) (jurisdiction (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-authorities authority)) ERR_ALREADY_VERIFIED)
    (map-set verified-authorities authority {
      name: name,
      jurisdiction: jurisdiction,
      verification-date: block-height,
      is-active: true
    })
    (ok true)))

(define-public (revoke-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? verified-authorities authority)
      authority-data (begin
        (map-set verified-authorities authority (merge authority-data {is-active: false}))
        (ok true))
      ERR_NOT_FOUND)))

(define-public (grant-permission (authority principal) (permission (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-verified-authority authority) ERR_UNAUTHORIZED)
    (let ((current-permissions (get-authority-permissions authority)))
      (map-set authority-permissions authority (unwrap-panic (as-max-len? (append current-permissions permission) u10)))
      (ok true))))
