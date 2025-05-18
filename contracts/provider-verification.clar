;; Provider Verification Contract
;; Validates healthcare entities and their credentials

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: (string-ascii 64) }
  {
    principal: principal,
    name: (string-ascii 100),
    specialty: (string-ascii 100),
    license-number: (string-ascii 50),
    status: uint,
    verification-date: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new healthcare provider
(define-public (register-provider
    (provider-id (string-ascii 64))
    (name (string-ascii 100))
    (specialty (string-ascii 100))
    (license-number (string-ascii 50))
  )
  (let ((existing-entry (map-get? providers { provider-id: provider-id })))
    (asserts! (is-none existing-entry) (err ERR_ALREADY_REGISTERED))

    (map-set providers
      { provider-id: provider-id }
      {
        principal: tx-sender,
        name: name,
        specialty: specialty,
        license-number: license-number,
        status: u0, ;; Initially unverified
        verification-date: u0
      }
    )
    (ok true)
  )
)

;; Verify a provider (admin only)
(define-public (verify-provider (provider-id (string-ascii 64)))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (match (map-get? providers { provider-id: provider-id })
      provider-data (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data {
            status: u1,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Suspend a provider (admin only)
(define-public (suspend-provider (provider-id (string-ascii 64)))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (match (map-get? providers { provider-id: provider-id })
      provider-data (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { status: u2 })
        )
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Get provider information
(define-read-only (get-provider (provider-id (string-ascii 64)))
  (map-get? providers { provider-id: provider-id })
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider-id (string-ascii 64)))
  (match (map-get? providers { provider-id: provider-id })
    provider-data (is-eq (get status provider-data) u1)
    false
  )
)

;; Transfer admin rights (admin only)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
