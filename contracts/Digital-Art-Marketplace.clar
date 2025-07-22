;; Digital Art Marketplace: Decentralized platform for artists to showcase and sell digital artwork
;; Enables artists to mint collections, collectors to purchase, and curators to authenticate pieces

(define-data-var gallery-curator principal tx-sender)

(define-map artwork-registry
  { artwork-id: uint }
  {
    artist: principal,
    price: uint,
    title: (string-ascii 50),
    description: (string-ascii 500),
    edition-size: uint,
    authenticated: bool
  })

(define-map ownership-history
  { artwork-id: uint, record-id: uint }
  {
    owner: principal,
    acquisition-date: uint,
    status: (string-ascii 20)
  })

(define-data-var next-artwork-id uint u1)

(define-map record-tracker
  { artwork-id: uint }
  { records: uint })

;; Mint a new digital artwork
(define-public (mint-artwork (title-input (string-ascii 50)) (description-input (string-ascii 500)) (edition-input uint) (price-input uint))
  (let
    (
      (artwork-id (var-get next-artwork-id))
      (record-id u0)
      (title title-input)
      (description description-input)
      (edition edition-input)
      (price price-input)
    )
    ;; Input validation
    (asserts! (> price u0) (err u1))
    (asserts! (> (len title) u0) (err u5))
    (asserts! (> (len description) u0) (err u6))
    (asserts! (> edition u0) (err u7))
    
    (map-set artwork-registry
      { artwork-id: artwork-id }
      {
        artist: tx-sender,
        price: price,
        title: title,
        description: description,
        edition-size: edition,
        authenticated: false
      }
    )
    (map-set ownership-history
      { artwork-id: artwork-id, record-id: record-id }
      {
        owner: tx-sender,
        acquisition-date: artwork-id,
        status: "minted"
      }
    )
    (map-set record-tracker
      { artwork-id: artwork-id }
      { records: u1 }
    )
    (var-set next-artwork-id (+ artwork-id u1))
    (ok artwork-id)
  ))

;; Purchase digital artwork
(define-public (purchase-artwork (artwork-id-input uint))
  (let
    (
      (artwork-id artwork-id-input)
      (artwork-info (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) (err u2)))
      (price (get price artwork-info))
      (artist (get artist artwork-info))
      (record-data (default-to { records: u0 } (map-get? record-tracker { artwork-id: artwork-id })))
      (record-id (get records record-data))
      (new-record-id (+ record-id u1))
    )
    ;; Input validation
    (asserts! (> artwork-id u0) (err u8))
    (asserts! (not (is-eq tx-sender artist)) (err u3))
    
    (try! (stx-transfer? price tx-sender artist))
    (map-set ownership-history
      { artwork-id: artwork-id, record-id: record-id }
      {
        owner: tx-sender,
        acquisition-date: (var-get next-artwork-id),
        status: "purchased"
      }
    )
    (map-set record-tracker
      { artwork-id: artwork-id }
      { records: new-record-id }
    )
    (ok true)
  ))

;; Authenticate artwork (curator only)
(define-public (authenticate-artwork (artwork-id-input uint))
  (let
    (
      (artwork-id artwork-id-input)
      (artwork-info (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) (err u2)))
      (record-data (default-to { records: u0 } (map-get? record-tracker { artwork-id: artwork-id })))
      (record-id (get records record-data))
      (new-record-id (+ record-id u1))
    )
    ;; Input validation
    (asserts! (> artwork-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get gallery-curator)) (err u4))
    
    (map-set artwork-registry
      { artwork-id: artwork-id }
      (merge artwork-info { authenticated: true })
    )
    (map-set ownership-history
      { artwork-id: artwork-id, record-id: record-id }
      {
        owner: (get artist artwork-info),
        acquisition-date: (var-get next-artwork-id),
        status: "authenticated"
      }
    )
    (map-set record-tracker
      { artwork-id: artwork-id }
      { records: new-record-id }
    )
    (ok true)
  ))

;; Get artwork details
(define-read-only (get-artwork (artwork-id uint))
  (map-get? artwork-registry { artwork-id: artwork-id }))

;; Get ownership history entry
(define-read-only (get-ownership-record (artwork-id uint) (record-id uint))
  (map-get? ownership-history { artwork-id: artwork-id, record-id: record-id }))

;; Get total ownership records for artwork
(define-read-only (get-ownership-count (artwork-id uint))
  (let
    (
      (record-data (default-to { records: u0 } (map-get? record-tracker { artwork-id: artwork-id })))
    )
    (get records record-data)
  ))
