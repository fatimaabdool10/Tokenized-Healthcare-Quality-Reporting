;; Quality Metric Contract
;; Establishes measurement standards for healthcare quality

(define-data-var admin principal tx-sender)

;; Metric types: 0 = process, 1 = outcome, 2 = structure, 3 = patient experience
(define-map metrics
  { metric-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    description: (string-utf8 500),
    type: uint,
    min-value: int,
    max-value: int,
    unit: (string-ascii 20),
    is-active: bool,
    created-at: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_INVALID_RANGE u4)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Create a new quality metric (admin only)
(define-public (create-metric
    (metric-id (string-ascii 64))
    (name (string-ascii 100))
    (description (string-utf8 500))
    (type uint)
    (min-value int)
    (max-value int)
    (unit (string-ascii 20))
  )
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (> max-value min-value) (err ERR_INVALID_RANGE))
    (asserts! (is-none (map-get? metrics { metric-id: metric-id })) (err ERR_ALREADY_EXISTS))

    (map-set metrics
      { metric-id: metric-id }
      {
        name: name,
        description: description,
        type: type,
        min-value: min-value,
        max-value: max-value,
        unit: unit,
        is-active: true,
        created-at: block-height
      }
    )
    (ok true)
  )
)

;; Update an existing metric (admin only)
(define-public (update-metric
    (metric-id (string-ascii 64))
    (name (string-ascii 100))
    (description (string-utf8 500))
    (type uint)
    (min-value int)
    (max-value int)
    (unit (string-ascii 20))
    (is-active bool)
  )
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (> max-value min-value) (err ERR_INVALID_RANGE))
    (asserts! (is-some (map-get? metrics { metric-id: metric-id })) (err ERR_NOT_FOUND))

    (map-set metrics
      { metric-id: metric-id }
      {
        name: name,
        description: description,
        type: type,
        min-value: min-value,
        max-value: max-value,
        unit: unit,
        is-active: is-active,
        created-at: (get created-at (unwrap-panic (map-get? metrics { metric-id: metric-id })))
      }
    )
    (ok true)
  )
)

;; Deactivate a metric (admin only)
(define-public (deactivate-metric (metric-id (string-ascii 64)))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (match (map-get? metrics { metric-id: metric-id })
      metric-data (begin
        (map-set metrics
          { metric-id: metric-id }
          (merge metric-data { is-active: false })
        )
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Get metric information
(define-read-only (get-metric (metric-id (string-ascii 64)))
  (map-get? metrics { metric-id: metric-id })
)

;; Check if metric is active
(define-read-only (is-metric-active (metric-id (string-ascii 64)))
  (match (map-get? metrics { metric-id: metric-id })
    metric-data (get is-active metric-data)
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
