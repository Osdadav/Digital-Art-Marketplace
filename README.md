# Digital Art Marketplace

A decentralized platform for artists to showcase and sell digital artwork on the Stacks blockchain.

## Features

- **Mint Artwork**: Artists can create digital art collections with metadata
- **Purchase System**: Collectors can buy authenticated pieces directly
- **Curation**: Gallery curators authenticate and validate artwork
- **Ownership History**: Complete provenance tracking for each piece

## Smart Contract Functions

### Public Functions
- `mint-artwork`: Create new digital artwork
- `purchase-artwork`: Buy existing artwork
- `authenticate-artwork`: Curator validation (curator only)

### Read-Only Functions
- `get-artwork`: Retrieve artwork details
- `get-ownership-record`: View ownership history
- `get-ownership-count`: Get total ownership records

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Set gallery curator address
3. Artists can mint their digital collections
4. Collectors purchase authenticated pieces

## License

MIT License
```

**Branch Name**: `feature/digital-art-marketplace-mvp`

**PR Title**: `feat: implement digital art marketplace with curation system`

**PR Description**: 
Introduces a decentralized digital art marketplace enabling artists to mint collections, collectors to purchase authenticated pieces, and curators to validate artwork. Features complete ownership history tracking and secure STX-based transactions.

**Commit Messages**:
- README: `docs: add comprehensive documentation for digital art marketplace`
- Code: `feat: implement digital art marketplace with minting and curation`

---

## PROJECT 2: RESEARCH PAPER PEER REVIEW SYSTEM

<CodeProject id="art-marketplace">

```clarity file="contracts/research-peer-review.clar"
;; Research Paper Peer Review System: Decentralized academic paper review platform
;; Enables researchers to submit papers, reviewers to evaluate, and editors to approve publications

(define-data-var chief-editor principal tx-sender)

(define-map manuscript-database
  { manuscript-id: uint }
  {
    author: principal,
    review-fee: uint,
    paper-title: (string-ascii 50),
    abstract: (string-ascii 500),
    review-period: uint,
    published: bool
  })

(define-map review-timeline
  { manuscript-id: uint, entry-id: uint }
  {
    reviewer: principal,
    submission-date: uint,
    review-status: (string-ascii 20)
  })

(define-data-var next-manuscript-id uint u1)

(define-map timeline-counter
  { manuscript-id: uint }
  { entries: uint })

;; Submit research paper for review
(define-public (submit-manuscript (title-input (string-ascii 50)) (abstract-input (string-ascii 500)) (period-input uint) (fee-input uint))
  (let
    (
      (manuscript-id (var-get next-manuscript-id))
      (entry-id u0)
      (title title-input)
      (abstract abstract-input)
      (period period-input)
      (fee fee-input)
    )
    ;; Input validation
    (asserts! (> fee u0) (err u1))
    (asserts! (> (len title) u0) (err u5))
    (asserts! (> (len abstract) u0) (err u6))
    (asserts! (> period u0) (err u7))
    
    (map-set manuscript-database
      { manuscript-id: manuscript-id }
      {
        author: tx-sender,
        review-fee: fee,
        paper-title: title,
        abstract: abstract,
        review-period: period,
        published: false
      }
    )
    (map-set review-timeline
      { manuscript-id: manuscript-id, entry-id: entry-id }
      {
        reviewer: tx-sender,
        submission-date: manuscript-id,
        review-status: "submitted"
      }
    )
    (map-set timeline-counter
      { manuscript-id: manuscript-id }
      { entries: u1 }
    )
    (var-set next-manuscript-id (+ manuscript-id u1))
    (ok manuscript-id)
  ))

;; Accept review assignment
(define-public (accept-review (manuscript-id-input uint))
  (let
    (
      (manuscript-id manuscript-id-input)
      (manuscript-info (unwrap! (map-get? manuscript-database { manuscript-id: manuscript-id }) (err u2)))
      (fee (get review-fee manuscript-info))
      (author (get author manuscript-info))
      (timeline-data (default-to { entries: u0 } (map-get? timeline-counter { manuscript-id: manuscript-id })))
      (entry-id (get entries timeline-data))
      (new-entry-id (+ entry-id u1))
    )
    ;; Input validation
    (asserts! (> manuscript-id u0) (err u8))
    (asserts! (not (is-eq tx-sender author)) (err u3))
    
    (try! (stx-transfer? fee tx-sender author))
    (map-set review-timeline
      { manuscript-id: manuscript-id, entry-id: entry-id }
      {
        reviewer: tx-sender,
        submission-date: (var-get next-manuscript-id),
        review-status: "reviewing"
      }
    )
    (map-set timeline-counter
      { manuscript-id: manuscript-id }
      { entries: new-entry-id }
    )
    (ok true)
  ))

;; Approve publication (chief editor only)
(define-public (approve-publication (manuscript-id-input uint))
  (let
    (
      (manuscript-id manuscript-id-input)
      (manuscript-info (unwrap! (map-get? manuscript-database { manuscript-id: manuscript-id }) (err u2)))
      (timeline-data (default-to { entries: u0 } (map-get? timeline-counter { manuscript-id: manuscript-id })))
      (entry-id (get entries timeline-data))
      (new-entry-id (+ entry-id u1))
    )
    ;; Input validation
    (asserts! (> manuscript-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get chief-editor)) (err u4))
    
    (map-set manuscript-database
      { manuscript-id: manuscript-id }
      (merge manuscript-info { published: true })
    )
    (map-set review-timeline
      { manuscript-id: manuscript-id, entry-id: entry-id }
      {
        reviewer: (get author manuscript-info),
        submission-date: (var-get next-manuscript-id),
        review-status: "published"
      }
    )
    (map-set timeline-counter
      { manuscript-id: manuscript-id }
      { entries: new-entry-id }
    )
    (ok true)
  ))

;; Get manuscript details
(define-read-only (get-manuscript (manuscript-id uint))
  (map-get? manuscript-database { manuscript-id: manuscript-id }))

;; Get review timeline entry
(define-read-only (get-review-entry (manuscript-id uint) (entry-id uint))
  (map-get? review-timeline { manuscript-id: manuscript-id, entry-id: entry-id }))

;; Get total review entries for manuscript
(define-read-only (get-review-count (manuscript-id uint))
  (let
    (
      (timeline-data (default-to { entries: u0 } (map-get? timeline-counter { manuscript-id: manuscript-id })))
    )
    (get entries timeline-data)
  ))