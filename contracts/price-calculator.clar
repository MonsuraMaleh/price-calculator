;; ------------------------------------------------------------
;; price-calculator.clar
;; Utility contract for price and rate calculations in STX DeFi
;; ------------------------------------------------------------
;; Features:
;; - Compute token price ratios
;; - Estimate output amounts for swaps
;; - Compute slippage
;; - Used by AMMs, DEXs, and liquidity pools
;; ------------------------------------------------------------

(define-constant ERR_INVALID_AMOUNT u100)
(define-constant ERR_DIV_ZERO u101)

;; ------------------------------------------------------------
;; PRICE CALCULATION FUNCTIONS
;; ------------------------------------------------------------

;; Calculates the price ratio between two tokens:
;; price = reserveY / reserveX
(define-read-only (get-price-ratio (reserve-x uint) (reserve-y uint))
  (begin
    (asserts! (> reserve-x u0) (err ERR_DIV_ZERO))
    (ok (/ (* reserve-y u1000000) reserve-x)) ;; scaled by 1e6
  )
)

;; Given an input amount, returns the output based on constant product formula:
;; output = (reserveY * amountIn * 997) / (reserveX * 1000 + amountIn * 997)
(define-read-only (get-swap-output (amount-in uint) (reserve-x uint) (reserve-y uint))
  (let (
        (amount-in-with-fee (* amount-in u997))
        (numerator (* amount-in-with-fee reserve-y))
        (denominator (+ (* reserve-x u1000) amount-in-with-fee))
      )
    (begin
      (asserts! (> denominator u0) (err ERR_DIV_ZERO))
      (ok (/ numerator denominator))
    )
  )
)

;; Given reserves and desired output, estimate required input
;; input = (reserveX * amountOut * 1000) / ((reserveY - amountOut) * 997)
(define-read-only (get-required-input (amount-out uint) (reserve-x uint) (reserve-y uint))
  (begin
    (asserts! (< amount-out reserve-y) (err ERR_INVALID_AMOUNT))
    (let (
          (numerator (* reserve-x amount-out u1000))
          (denominator (* (- reserve-y amount-out) u997))
        )
      (ok (/ numerator denominator))
    )
  )
)

;; Compute slippage percentage
;; slippage = ((expected - actual) / expected) * 100
(define-read-only (get-slippage (expected uint) (actual uint))
  (begin
    (asserts! (> expected u0) (err ERR_DIV_ZERO))
    (let ((diff (if (> expected actual) (- expected actual) (- actual expected))))
      (ok (/ (* diff u100) expected))
    )
  )
)

;; ------------------------------------------------------------
;; EXAMPLE HELPER
;; ------------------------------------------------------------

;; Compute spot price and swap example
(define-read-only (example-pricing)
  (let (
        (reserve-x u5000000) ;; Token X reserve
        (reserve-y u10000000) ;; Token Y reserve
        (input u1000000)
        (price (unwrap-panic (get-price-ratio reserve-x reserve-y)))
        (output (unwrap-panic (get-swap-output input reserve-x reserve-y)))
      )
    (ok {
      price_ratio: price,
      output_amount: output,
      tokenx_reserve: reserve-x,
      tokeny_reserve: reserve-y
    })
  )
)
