;; token-with-mint-burn.clar
;; SIP-010 compliant fungible token with mint & burn
;; Example for STX projects

;; Import trait from deployed contract
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; ------------------------------------------------------------
;; Constants & Errors
;; ------------------------------------------------------------
(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_INSUFFICIENT_BALANCE u101)
(define-constant ERR_UNAUTHORIZED_TRANSFER u102)

;; ------------------------------------------------------------
;; Private Functions
;; ------------------------------------------------------------
(define-private (can-transfer (amount uint) (sender principal))
  (let ((balance (default-to u0 (map-get? balances {owner: sender}))))
    (>= balance amount)))

;; ------------------------------------------------------------
;; Token Metadata
;; ------------------------------------------------------------
(define-constant token-name "Example Token")
(define-constant token-symbol "EXT")
(define-constant token-decimals u6) ;; 6 decimals
(define-constant token-uri u"https://example.com/token.json")

;; ------------------------------------------------------------
;; Data Variables
;; ------------------------------------------------------------
(define-data-var total-supply uint u0)
(define-data-var owner principal tx-sender)

(define-map balances {owner: principal} uint)

;; ------------------------------------------------------------
;; Ownership
;; ------------------------------------------------------------
(define-read-only (get-owner)
  (var-get owner)
)

(define-public (set-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR_NOT_OWNER))
    (var-set owner new-owner)
    (ok true))
)

;; ------------------------------------------------------------
;; Metadata (SIP-010 required)
;; ------------------------------------------------------------
(define-read-only (get-name) (ok token-name))
(define-read-only (get-symbol) (ok token-symbol))
(define-read-only (get-decimals) (ok token-decimals))
(define-read-only (get-token-uri) (ok (some token-uri)))

;; ------------------------------------------------------------
;; Supply & Balance (SIP-010 required)
;; ------------------------------------------------------------
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? balances {owner: account})))
)

;; ------------------------------------------------------------
;; Transfer (SIP-010 required)
;; ------------------------------------------------------------
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (let
    (
      (sender-balance (default-to u0 (map-get? balances {owner: sender})))
      (recipient-balance (default-to u0 (map-get? balances {owner: recipient})))
    )
    (begin
      (asserts! (is-eq tx-sender sender) (err ERR_UNAUTHORIZED_TRANSFER))
      (asserts! (>= sender-balance amount) (err ERR_INSUFFICIENT_BALANCE))

      ;; update balances
      (asserts! (>= sender-balance amount) (err ERR_INSUFFICIENT_BALANCE))
      (map-set balances {owner: sender} (- sender-balance amount))
      (map-set balances {owner: recipient} (+ recipient-balance amount))

      ;; optionally log memo
      (match memo memo-value (begin (print memo-value) true) true)

      (ok true)
    )
  )
)

;; ------------------------------------------------------------
;; Mint (only owner can mint new tokens)
;; ------------------------------------------------------------
(define-public (mint (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR_NOT_OWNER))
    (let
      (
        (current-balance (default-to u0 (map-get? balances {owner: recipient})))
      )
      (var-set total-supply (+ (var-get total-supply) amount))
      (map-set balances {owner: recipient} (+ current-balance amount))
      (ok true)
    )
  )
)

;; ------------------------------------------------------------
;; Burn (any holder can burn their tokens)
;; ------------------------------------------------------------
(define-public (burn (amount uint))
  (let
    (
      (current-balance (default-to u0 (map-get? balances {owner: tx-sender})))
    )
    (begin
      (asserts! (>= current-balance amount) (err ERR_INSUFFICIENT_BALANCE))
      (map-set balances {owner: tx-sender} (- current-balance amount))
      (var-set total-supply (- (var-get total-supply) amount))
      (ok true)
    )
  )
)
