/// Checkout finalize request shaping.
///
/// `POST /transactions/{id}/check-out` sends mobile-computed totals at the top
/// level (`amount`, `time_out`, `is_overnight`, `ticket_lost`) plus
/// `driver_out` and `condition_checkout`.
///
/// Do **not** echo GET `checkout-preview` display blocks (`release_summary`,
/// `ticket`, `condition_comparison`) in the request `preview` object — the API
/// returns those on the response only.
