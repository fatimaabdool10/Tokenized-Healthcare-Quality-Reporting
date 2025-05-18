;; Benchmark Contract
;; Establishes comparison standards for quality metrics

(define-data-var admin principal tx-sender)

;; Benchmark data structure
(define-map benchmarks
  {
    metric-id: (string-ascii 64),
    reporting-period: (string-ascii 20), ;; Format: YYYY-MM
    region: (string-ascii 50) ;; Optional region specification, "ALL" for nationwide
  }
  {
    target-value: int,
    min-acceptable: int,
    max-ideal: int,
    national-average: int,
    sample-size: uint,
    last-updated: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_INVALID_VALUES u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Set benchmark for a metric (admin only)
(define-public (set-benchmark
    (metric-id (string-ascii 64))
    (reporting-period (string-ascii 20))
    (region (string-ascii 50))
    (target-value int)
    (min-acceptable int)
    (max-ideal int)
    (national-average int)
    (sample-size uint)
  )
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))

    ;; Validate benchmark values
    (asserts! (and
      (<= min-acceptable target-value)
      (>= max-ideal target-value)
    ) (err ERR_INVALID_VALUES))

    (map-set benchmarks
      {
        metric-id: metric-id,
        reporting-period: reporting-period,
        region: region
      }
      {
        target-value: target-value,
        min-acceptable: min-acceptable,
        max-ideal: max-ideal,
        national-average: national-average,
        sample-size: sample-size,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Get benchmark for a metric
(define-read-only (get-benchmark
    (metric-id (string-ascii 64))
    (reporting-period (string-ascii 20))
    (region (string-ascii 50))
  )
  (map-get? benchmarks {
    metric-id: metric-id,
    reporting-period: reporting-period,
    region: region
  })
)

;; Check if a value meets the benchmark target
(define-read-only (meets-target
    (metric-id (string-ascii 64))
    (reporting-period (string-ascii 20))
    (region (string-ascii 50))
    (value int)
  )
  (match (map-get? benchmarks {
    metric-id: metric-id,
    reporting-period: reporting-period,
    region: region
  })
    benchmark-data (>= value (get target-value benchmark-data))
    false
  )
)

;; Check if a value meets minimum acceptable standard
(define-read-only (meets-minimum
    (metric-id (string-ascii 64))
    (reporting-period (string-ascii 20))
    (region (string-ascii 50))
    (value int)
  )
  (match (map-get? benchmarks {
    metric-id: metric-id,
    reporting-period: reporting-period,
    region: region
  })
    benchmark-data (>= value (get min-acceptable benchmark-data))
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
