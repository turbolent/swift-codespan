/// The display style to use when rendering diagnostics.
public enum DisplayStyle {
    /// Output a richly formatted diagnostic, with source code previews.
    ///
    /// ```text
    /// error[E0001]: unexpected type in `+` application
    ///   ┌─ test:2:9
    ///   │
    /// 2 │ (+ test "")
    ///   │         ^^ expected `Int` but found `String`
    ///   │
    ///   = expected type `Int`
    ///        found type `String`
    ///
    /// error[E0002]: Bad config found
    ///
    /// ```
    case rich

    /// Output a condensed diagnostic, with a line number, severity, message and notes (if any).
    ///
    /// ```text
    /// test:2:9: error[E0001]: unexpected type in `+` application
    /// = expected type `Int`
    ///      found type `String`
    ///
    /// error[E0002]: Bad config found
    /// ```
    case medium

    /// Output a short diagnostic, with a line number, severity, and message.
    ///
    /// ```text
    /// test:2:9: error[E0001]: unexpected type in `+` application
    /// error[E0002]: Bad config found
    /// ```
    case short
}
