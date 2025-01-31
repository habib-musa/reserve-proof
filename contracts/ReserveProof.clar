;; ReserveProof contract
;; This contract manages reserves and authorized withdrawers
(define-data-var reserve-balance uint u0)
(define-data-var reserve-threshold uint u1000)
(define-data-var authorized-withdrawer (optional principal) none)
(define-map token-balances {token: principal, owner: principal} uint)

(define-constant ERR_NOT_AUTHORIZED u100)
(define-constant ERR_INSUFFICIENT_BALANCE u101)
(define-constant ERR_WITHDRAWER_ALREADY_SET u102)
(define-constant ERR_INVALID_INPUT u103)
(define-constant ERR_THRESHOLD_TOO_LOW u104)
(define-constant ERR_THRESHOLD_TOO_HIGH u105)
(define-constant ERR_OVERFLOW u106)
(define-constant ERR_INVALID_WITHDRAWER u107)
(define-constant ERR_TOKEN_NOT_FOUND u108)
(define-constant ERR_INSUFFICIENT_TOKEN_BALANCE u109)


(define-constant MAX_UINT u340282366920938463463374607431768211455)

(define-public (initialize (withdrawer principal) (threshold uint))
  (begin
    ;; Validate inputs
    (asserts! (not (is-eq withdrawer tx-sender)) (err ERR_INVALID_INPUT))
    (asserts! (> threshold u0) (err ERR_INVALID_INPUT))
    (asserts! (>= threshold u1000) (err ERR_THRESHOLD_TOO_LOW))
    (asserts! (<= threshold u1000000000) (err ERR_THRESHOLD_TOO_HIGH))
    (asserts! (is-none (var-get authorized-withdrawer)) (err ERR_WITHDRAWER_ALREADY_SET))
    
    (var-set authorized-withdrawer (some withdrawer))
    (var-set reserve-threshold threshold)
    (print {event: "initialize", withdrawer: withdrawer, threshold: threshold})
    (ok {message: "Initialization complete"})))

(define-public (set-authorized-withdrawer (withdrawer principal))
  (begin
    (match (var-get authorized-withdrawer)
      current-withdrawer
        (begin
          (asserts! (is-eq tx-sender current-withdrawer) (err ERR_NOT_AUTHORIZED))
          (asserts! (not (is-eq withdrawer current-withdrawer)) (err ERR_INVALID_INPUT))
          (var-set authorized-withdrawer (some withdrawer))
          (print {event: "set-authorized-withdrawer", previous: current-withdrawer, new: withdrawer})
          (ok {message: "Authorized withdrawer updated"}))
      (err ERR_NOT_AUTHORIZED))))

(define-public (deposit-reserves (amount uint))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) (err ERR_INVALID_INPUT))
    (asserts! (<= (+ (var-get reserve-balance) amount) MAX_UINT) (err ERR_OVERFLOW))
    (var-set reserve-balance (+ (var-get reserve-balance) amount))
    (print {event: "deposit", amount: amount, new_balance: (var-get reserve-balance)})
    (ok (var-get reserve-balance))))

(define-public (withdraw-reserves (amount uint))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) (err ERR_INVALID_INPUT))
    (match (var-get authorized-withdrawer)
      withdrawer 
        (begin
          (asserts! (is-eq tx-sender withdrawer) (err ERR_NOT_AUTHORIZED))
          (asserts! (>= (var-get reserve-balance) amount) (err ERR_INSUFFICIENT_BALANCE))
          (let ((new-balance (- (var-get reserve-balance) amount)))
            (var-set reserve-balance new-balance)
            (print {event: "withdraw", amount: amount, new_balance: new-balance})
            (ok new-balance)))
      (err ERR_NOT_AUTHORIZED))))

;; New functionality: Token management
(define-public (deposit-token (token principal) (amount uint))
    (begin
        (asserts! (> amount u0) (err ERR_INVALID_INPUT))
        (let ((balance (default-to u0 (map-get? token-balances {token: token, owner: tx-sender}))))
        (asserts! (<= (+ balance amount) MAX_UINT) (err ERR_OVERFLOW))
        (map-set token-balances {token: token, owner: tx-sender} (+ balance amount))
        (print {event: "token-deposit", token: token, amount: amount, new-balance: (+ balance amount)})
        (ok (+ balance amount)))))

(define-public (withdraw-token (token principal) (amount uint))
    (begin
        (asserts! (> amount u0) (err ERR_INVALID_INPUT))
        (let ((balance (default-to u0 (map-get? token-balances {token: token, owner: tx-sender}))))
            (asserts! (>= balance amount) (err ERR_INSUFFICIENT_TOKEN_BALANCE))
            (map-set token-balances {token: token, owner: tx-sender} (- balance amount))
            (print {event: "token-withdraw", token: token, amount: amount, new-balance: (- balance amount)})
            (ok (- balance amount)))))

(define-read-only (get-token-balance (token principal) (owner principal))
    (ok (default-to u0 (map-get? token-balances {token: token, owner: owner}))))


(define-read-only (get-reserve-balance)
  (ok (var-get reserve-balance)))

(define-read-only (check-threshold)
  (begin
    (if (< (var-get reserve-balance) (var-get reserve-threshold))
        (begin
          (print {event: "threshold-breached", balance: (var-get reserve-balance)})
          (ok {status: "below-threshold", balance: (var-get reserve-balance)}))
        (ok {status: "above-threshold", balance: (var-get reserve-balance)}))))
