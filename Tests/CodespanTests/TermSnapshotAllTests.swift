import XCTest
@testable import Codespan

final class TermSnapshotAllTests: XCTestCase {
    func testAllTermSnapshots() throws {
        let snapshotNames = try loadSnapshotNames()
        for name in snapshotNames {
            let (module, variant) = parseSnapshotName(name)
            let testData = try snapshotData(for: module)
            let config = configForVariant(variant, base: testData.baseConfig)
            let theme = themeForVariant(variant)
            let expected = trimTrailingNewlines(try loadSnapshotContent(name: name))
            let output = trimTrailingNewlines(try testData.emit(config, theme))
            XCTAssertEqual(output, expected, "Snapshot mismatch: \(name)")
        }
    }
}

private struct SnapshotTestData {
    let baseConfig: Config
    let emit: (Config, Styles) throws -> String
}

private func snapshotData(for module: String) throws -> SnapshotTestData {
    switch module {
    case "empty":
        return makeEmptyData()
    case "same_line":
        return makeSameLineData()
    case "overlapping":
        return makeOverlappingData()
    case "message":
        return makeMessageData()
    case "message_and_notes":
        return makeMessageAndNotesData()
    case "message_errorcode":
        return makeMessageErrorcodeData()
    case "empty_ranges":
        return makeEmptyRangesData()
    case "same_ranges":
        return makeSameRangesData()
    case "multifile":
        return makeMultifileData()
    case "fizz_buzz":
        return makeFizzBuzzData()
    case "multiline_overlapping":
        return makeMultilineOverlappingData()
    case "tabbed":
        return makeTabbedData()
    case "tab_columns":
        return makeTabColumnsData()
    case "unicode":
        return makeUnicodeData()
    case "unicode_spans":
        return makeUnicodeSpansData()
    case "position_indicator":
        return makePositionIndicatorData()
    case "multiline_omit":
        return makeMultilineOmitData()
    case "surrounding_lines":
        return makeSurroundingLinesData()
    default:
        throw SnapshotError.unknownModule(module)
    }
}

private func makeEmptyData() -> SnapshotTestData {
    let files = Files<String>()
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.bug(),
        Diagnostic<FileId>.error(),
        Diagnostic<FileId>.warning(),
        Diagnostic<FileId>.note(),
        Diagnostic<FileId>.help(),
        Diagnostic<FileId>.bug(),
    ]
    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeSameLineData() -> SnapshotTestData {
    var files = Files<String>()
    let fileId = files.add(name: "one_line.rs", source: unindent("""
        fn main() {
            let mut v = vec![Some(\"foo\"), Some(\"bar\")];
            v.push(v.pop().unwrap());
        }
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "E0499",
            message: "cannot borrow `v` as mutable more than once at a time",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 71..<72,
                    message: "second mutable borrow occurs here"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 64..<65,
                    message: "first borrow later used by call"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 66..<70,
                    message: "first mutable borrow occurs here"
                ),
            ]
        ),
        Diagnostic<FileId>.error(
            message: "aborting due to previous error",
            notes: ["For more information about this error, try `rustc --explain E0499`."]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeOverlappingData() -> SnapshotTestData {
    var files = Files<String>()

    let fileId1 = files.add(name: "nested_impl_trait.rs", source: unindent("""
        use std::fmt::Debug;

        fn fine(x: impl Into<u32>) -> impl Into<u32> { x }

        fn bad_in_ret_position(x: impl Into<u32>) -> impl Into<impl Debug> { x }
    """))

    let fileId2 = files.add(name: "typeck_type_placeholder_item.rs", source: unindent("""
        fn fn_test1() -> _ { 5 }
        fn fn_test2(x: i32) -> (_, _) { (x, x) }
    """))

    let fileId3 = files.add(name: "libstd/thread/mod.rs", source: unindent("""
        #[stable(feature = \"rust1\", since = \"1.0.0\")]
        pub fn spawn<F, T>(self, f: F) -> io::Result<JoinHandle<T>>
        where
            F: FnOnce() -> T,
            F: Send + 'static,
            T: Send + 'static,
        {
            unsafe { self.spawn_unchecked(f) }
        }
    """))

    let fileId4 = files.add(name: "no_send_res_ports.rs", source: unindent("""
        use std::thread;
        use std::rc::Rc;

        #[derive(Debug)]
        struct Port<T>(Rc<T>);

        fn main() {
            #[derive(Debug)]
            struct Foo {
                _x: Port<()>,
            }

            impl Drop for Foo {
                fn drop(&mut self) {}
            }

            fn foo(x: Port<()>) -> Foo {
                Foo {
                    _x: x
                }
            }

            let x = foo(Port(Rc::new(())));

            thread::spawn(move|| {
                let y = x;
                println!("{:?}", y);
            });
        }
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "E0666",
            message: "nested `impl Trait` is not allowed",
            labels: [
                Label.primary(
                    fileId: fileId1,
                    range: 129..<139,
                    message: "nested `impl Trait` here"
                ),
                Label.secondary(
                    fileId: fileId1,
                    range: 119..<140,
                    message: "outer `impl Trait`"
                ),
            ]
        ),
        Diagnostic<FileId>.error(
            code: "E0121",
            message: "the type placeholder `_` is not allowed within types on item signatures",
            labels: [
                Label.primary(
                    fileId: fileId2,
                    range: 17..<18,
                    message: "not allowed in type signatures"
                ),
                Label.secondary(
                    fileId: fileId2,
                    range: 17..<18,
                    message: "help: replace with the correct return type: `i32`"
                ),
            ]
        ),
        Diagnostic<FileId>.error(
            code: "E0121",
            message: "the type placeholder `_` is not allowed within types on item signatures",
            labels: [
                Label.primary(
                    fileId: fileId2,
                    range: 49..<50,
                    message: "not allowed in type signatures"
                ),
                Label.primary(
                    fileId: fileId2,
                    range: 52..<53,
                    message: "not allowed in type signatures"
                ),
                Label.secondary(
                    fileId: fileId2,
                    range: 48..<54,
                    message: "help: replace with the correct return type: `(i32, i32)`"
                ),
            ]
        ),
        Diagnostic<FileId>.error(
            code: "E0277",
            message: "`std::rc::Rc<()>` cannot be sent between threads safely",
            labels: [
                Label.primary(
                    fileId: fileId4,
                    range: 339..<352,
                    message: "`std::rc::Rc<()>` cannot be sent between threads safely"
                ),
                Label.secondary(
                    fileId: fileId4,
                    range: 353..<416,
                    message: "within this `[closure@no_send_res_ports.rs:29:19: 33:6 x:main::Foo]`"
                ),
                Label.secondary(
                    fileId: fileId3,
                    range: 141..<145,
                    message: "required by this bound in `std::thread::spawn`"
                ),
            ],
            notes: [
                "help: within `[closure@no_send_res_ports.rs:29:19: 33:6 x:main::Foo]`, the trait `std::marker::Send` is not implemented for `std::rc::Rc<()>`",
                "note: required because it appears within the type `Port<()>`",
                "note: required because it appears within the type `main::Foo`",
                "note: required because it appears within the type `[closure@no_send_res_ports.rs:29:19: 33:6 x:main::Foo]`",
            ]
        ),
        Diagnostic<FileId>.error(
            message: "aborting due 5 previous errors",
            notes: [
                "Some errors have detailed explanations: E0121, E0277, E0666.",
                "For more information about an error, try `rustc --explain E0121`.",
            ]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeMessageData() -> SnapshotTestData {
    let files = Files<String>()
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(message: "a message"),
        Diagnostic<FileId>.warning(message: "a message"),
        Diagnostic<FileId>.note(message: "a message"),
        Diagnostic<FileId>.help(message: "a message"),
    ]
    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeMessageAndNotesData() -> SnapshotTestData {
    let files = Files<String>()
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(message: "a message", notes: ["a note"]),
        Diagnostic<FileId>.warning(message: "a message", notes: ["a note"]),
        Diagnostic<FileId>.note(message: "a message", notes: ["a note"]),
        Diagnostic<FileId>.help(message: "a message", notes: ["a note"]),
    ]
    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeMessageErrorcodeData() -> SnapshotTestData {
    let files = Files<String>()
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(code: "E0001", message: "a message"),
        Diagnostic<FileId>.warning(code: "W001", message: "a message"),
        Diagnostic<FileId>.note(code: "N0815", message: "a message"),
        Diagnostic<FileId>.help(code: "H4711", message: "a message"),
        Diagnostic<FileId>.error(code: "", message: "where did my errorcode go?"),
        Diagnostic<FileId>.warning(code: "", message: "where did my errorcode go?"),
        Diagnostic<FileId>.note(code: "", message: "where did my errorcode go?"),
        Diagnostic<FileId>.help(code: "", message: "where did my errorcode go?"),
    ]
    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeEmptyRangesData() -> SnapshotTestData {
    var files = Files<String>()
    let fileId = files.add(name: "hello", source: "Hello world!\nBye world!\n   ")
    let source = try? files.source(of: fileId)
    let eof = UInt(source?.utf8.count ?? 0)
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.note(
            message: "middle",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 6..<6,
                    message: "middle"
                )
            ]
        ),
        Diagnostic<FileId>.note(
            message: "end of line",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 12..<12,
                    message: "end of line"
                )
            ]
        ),
        Diagnostic<FileId>.note(
            message: "end of line",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 23..<23,
                    message: "end of line"
                )
            ]
        ),
        Diagnostic<FileId>.note(
            message: "end of file",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: eof..<eof,
                    message: "end of file"
                )
            ]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeSameRangesData() -> SnapshotTestData {
    var files = Files<String>()
    let fileId = files.add(name: "same_range", source: "::S { }")
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            message: "Unexpected token",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 4..<4,
                    message: "Unexpected '{'"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 4..<4,
                    message: "Expected '('"
                )
            ]
        )
    ]
    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeMultifileData() -> SnapshotTestData {
    var files = Files<String>()

    let fileId1 = files.add(name: "Data/Nat.fun", source: unindent("""
        module Data.Nat where

        data Nat : Type where
            zero : Nat
            succ : Nat → Nat

        {-# BUILTIN NATRAL Nat #-}

        infixl 6 _+_ _-_

        _+_ : Nat → Nat → Nat
        zero    + n₂ = n₂
        succ n₁ + n₂ = succ (n₁ + n₂)

        _-_ : Nat → Nat → Nat
        n₁      - zero    = n₁
        zero    - succ n₂ = zero
        succ n₁ - succ n₂ = n₁ - n₂
    """))

    let fileId2 = files.add(name: "Test.fun", source: unindent("""
        module Test where

        _ : Nat
        _ = 123 + \"hello\"
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            message: "unknown builtin: `NATRAL`",
            labels: [
                Label.primary(
                    fileId: fileId1,
                    range: 96..<102,
                    message: "unknown builtin"
                )
            ],
            notes: ["there is a builtin with a similar name: `NATURAL`"]
        ),
        Diagnostic<FileId>.warning(
            message: "unused parameter pattern: `n₂`",
            labels: [
                Label.primary(
                    fileId: fileId1,
                    range: 285..<289,
                    message: "unused parameter"
                )
            ],
            notes: ["consider using a wildcard pattern: `_`"]
        ),
        Diagnostic<FileId>.error(
            code: "E0001",
            message: "unexpected type in application of `_+_`",
            labels: [
                Label.primary(
                    fileId: fileId2,
                    range: 37..<44,
                    message: "expected `Nat`, found `String`"
                ),
                Label.secondary(
                    fileId: fileId1,
                    range: 130..<155,
                    message: "based on the definition of `_+_`"
                ),
            ],
            notes: [unindent("""
                expected type `Nat`
                   found type `String`
            """)]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeFizzBuzzData() -> SnapshotTestData {
    var files = Files<String>()

    let fileId = files.add(name: "FizzBuzz.fun", source: unindent("""
        module FizzBuzz where

        fizz₁ : Nat → String
        fizz₁ num = case (mod num 5) (mod num 3) of
            0 0 => \"FizzBuzz\"
            0 _ => \"Fizz\"
            _ 0 => \"Buzz\"
            _ _ => num

        fizz₂ : Nat → String
        fizz₂ num =
            case (mod num 5) (mod num 3) of
                0 0 => \"FizzBuzz\"
                0 _ => \"Fizz\"
                _ 0 => \"Buzz\"
                _ _ => num
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "E0308",
            message: "`case` clauses have incompatible types",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 163..<166,
                    message: "expected `String`, found `Nat`"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 62..<166,
                    message: "`case` clauses have incompatible types"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 41..<47,
                    message: "expected type `String` found here"
                ),
            ],
            notes: [unindent("""
                expected type `String`
                   found type `Nat`
            """)]
        ),
        Diagnostic<FileId>.error(
            code: "E0308",
            message: "`case` clauses have incompatible types",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 328..<331,
                    message: "expected `String`, found `Nat`"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 211..<331,
                    message: "`case` clauses have incompatible types"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 258..<268,
                    message: "this is found to be of type `String`"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 284..<290,
                    message: "this is found to be of type `String`"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 306..<312,
                    message: "this is found to be of type `String`"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 186..<192,
                    message: "expected type `String` found here"
                ),
            ],
            notes: [unindent("""
                expected type `String`
                   found type `Nat`
            """)]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeMultilineOverlappingData() -> SnapshotTestData {
    var files = Files<String>()
    let fileId = files.add(
        name: "codespan/src/file.rs",
        source: "        match line_index.compare(self.last_line_index()) {\n            Ordering::Less => Ok(self.line_starts()[line_index.to_usize()]),\n            Ordering::Equal => Ok(self.source_span().end()),\n            Ordering::Greater => LineIndexOutOfBoundsError {\n                given: line_index,\n                max: self.last_line_index(),\n            },\n        }"
    )

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "E0308",
            message: "match arms have incompatible types",
            labels: [
                Label.secondary(
                    fileId: fileId,
                    range: 89..<134,
                    message: "this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"
                ),
                Label.primary(
                    fileId: fileId,
                    range: 230..<351,
                    message: "expected enum `Result`, found struct `LineIndexOutOfBoundsError`"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 8..<362,
                    message: "`match` arms have incompatible types"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 167..<195,
                    message: "this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"
                ),
            ],
            notes: [unindent("""
                    expected type `Result<ByteIndex, LineIndexOutOfBoundsError>`
                       found type `LineIndexOutOfBoundsError`
            """)]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeTabbedData() -> SnapshotTestData {
    var files = Files<String>()
    let fileId = files.add(name: "tabbed", source: unindent("""
        Entity:
        \tArmament:
        \t\tWeapon: DogJaw
        \t\tReloadingCondition:\tattack-cooldown
        \tFoo: Bar
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.warning(
            message: "unknown weapon `DogJaw`",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 29..<35,
                    message: "the weapon"
                )
            ]
        ),
        Diagnostic<FileId>.warning(
            message: "unknown condition `attack-cooldown`",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 58..<73,
                    message: "the condition"
                )
            ]
        ),
        Diagnostic<FileId>.warning(
            message: "unknown field `Foo`",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 75..<78,
                    message: "the field"
                )
            ]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeTabColumnsData() -> SnapshotTestData {
    var files = Files<String>()
    let source = unindent("""
        \thello
        ∙\thello
        ∙∙\thello
        ∙∙∙\thello
        ∙∙∙∙\thello
        ∙∙∙∙∙\thello
        ∙∙∙∙∙∙\thello
    """)
    let ranges = byteRanges(of: "hello", in: source)
    let fileId = files.add(name: "tab_columns", source: source)
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.warning(
            message: "tab test",
            labels: ranges.map { Label.primary(
                fileId: fileId,
                range: $0
            ) }
        )
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeUnicodeData() -> SnapshotTestData {
    let prefix = "extern "
    let abi = "\"路濫狼á́́\""
    let suffix = " fn foo() {}"
    var files = Files<String>()
    let fileId = files.add(name: "unicode.rs", source: "\(prefix)\(abi)\(suffix)")
    let start = UInt(byteCount(prefix))
    let end = start + UInt(byteCount(abi))
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "E0703",
            message: "invalid ABI: found `路濫狼á́́`",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: start..<end,
                    message: "invalid ABI"
                )
            ],
            notes: [unindent("""
                valid ABIs:
                  - aapcs
                  - amdgpu-kernel
                  - C
                  - cdecl
                  - efiapi
                  - fastcall
                  - msp430-interrupt
                  - platform-intrinsic
                  - ptx-kernel
                  - Rust
                  - rust-call
                  - rust-intrinsic
                  - stdcall
                  - system
                  - sysv64
                  - thiscall
                  - unadjusted
                  - vectorcall
                  - win64
                  - x86-interrupt
            """)]
        ),
        Diagnostic<FileId>.error(
            message: "aborting due to previous error",
            notes: ["For more information about this error, try `rustc --explain E0703`."]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeUnicodeSpansData() -> SnapshotTestData {
    let moonPhases = "🐄🌑🐄🌒🐄🌓🐄🌔🐄🌕🐄🌖🐄🌗🐄🌘🐄"
    let invalidStart: UInt = 1
    let cowLength = UInt(byteCount("🐄"))
    let invalidEnd = cowLength - 1
    var files = Files<String>()
    let fileId = files.add(name: "moon_jump.rs", source: moonPhases)
    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "E01",
            message: "cow may not jump during new moon.",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: invalidStart..<invalidEnd,
                    message: "Invalid jump"
                )
            ]
        ),
        Diagnostic<FileId>.note(
            message: "invalid unicode range",
            labels: [
                Label.secondary(
                    fileId: fileId,
                    range: invalidStart..<cowLength,
                    message: "Cow range does not start at boundary."
                )
            ]
        ),
        Diagnostic<FileId>.note(
            message: "invalid unicode range",
            labels: [
                Label.secondary(
                    fileId: fileId,
                    range: UInt(byteCount("🐄🌑"))..<UInt(byteCount("🐄🌑🐄")) - 1,
                    message: "Cow range does not end at boundary."
                )
            ]
        ),
        Diagnostic<FileId>.note(
            message: "invalid unicode range",
            labels: [
                Label.secondary(
                    fileId: fileId,
                    range: invalidStart..<UInt(byteCount("🐄🌑🐄")) - 1,
                    message: "Cow does not start or end at boundary."
                )
            ]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makePositionIndicatorData() -> SnapshotTestData {
    var files = Files<String>()
    let fileId = files.add(name: "tests/main.js", source: unindent("""
        \"use strict\";
        let zero=0;
        function foo() {
          \"use strict\";
          one=1;
        }
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.warning(
            code: "ParserWarning",
            message: "The strict mode declaration in the body of function `foo` is redundant, as the outer scope is already in strict mode",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 45..<57,
                    message: "This strict mode declaration is redundant"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 0..<12,
                    message: "Strict mode is first declared here"
                ),
            ]
        ),
    ]

    return SnapshotTestData(baseConfig: .init()) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeMultilineOmitData() -> SnapshotTestData {
    var config = Config()
    config.startContextLines = 2
    config.endContextLines = 1

    var files = Files<String>()

    let fileId1 = files.add(name: "empty_if_comments.lua", source: [
        "elseif 3 then",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "else",
    ].joined(separator: "\n"))

    let fileId2 = files.add(name: "src/lib.rs", source: [
        "fn main() {",
        "    1",
        "    + 1",
        "    + 1",
        "    + 1",
        "    + 1",
        "    +1",
        "    + 1",
        "    + 1",
        "    + 1",
        "}",
    ].joined(separator: "\n"))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            code: "empty_if",
            message: "empty elseif block",
            labels: [
                Label.primary(
                    fileId: fileId1,
                    range: 0..<23
                ),
                Label.secondary(
                    fileId: fileId1,
                    range: 15..<21,
                    message: "content should be in here"
                ),
            ]
        ),
        Diagnostic<FileId>.error(
            code: "E0308",
            message: "mismatched types",
            labels: [
                Label.primary(
                    fileId: fileId2,
                    range: 17..<80,
                    message: "expected (), found integer"
                ),
                Label.secondary(
                    fileId: fileId2,
                    range: 55..<55,
                    message: "missing whitespace"
                ),
            ],
            notes: ["note:\texpected type `()`\n\tfound type `{integer}`"]
        ),
    ]

    return SnapshotTestData(baseConfig: config) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func makeSurroundingLinesData() -> SnapshotTestData {
    let config = Config(
        beforeLabelLines: 2,
        afterLabelLines: 1
    )

    var files = Files<String>()
    let fileId = files.add(name: "surroundingLines.fun", source: unindent("""
        #[foo]
        fn main() {
            println!(
                "{}",
                Foo
            );
        }

        struct Foo
    """))

    let diagnostics: [Diagnostic<FileId>] = [
        Diagnostic<FileId>.error(
            message: "Unknown attribute macro",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 2..<5,
                    message: "No attribute macro `foo` known"
                )
            ]
        ),
        Diagnostic<FileId>.error(
            message: "Missing argument for format",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 55..<58,
                    message: "No instance of std::fmt::Display exists for type Foo"
                ),
                Label.secondary(
                    fileId: fileId,
                    range: 42..<44,
                    message: "Unable to use `{}`-directive to display `Foo`"
                ),
            ]
        ),
        Diagnostic<FileId>.error(
            message: "Syntax error",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 79..<79,
                    message: "Missing a semicolon"
                )
            ]
        ),
    ]

    return SnapshotTestData(baseConfig: config) { config, styles in
        try emitAll(diagnostics: diagnostics, config: config, styles: styles, files: files)
    }
}

private func emitAll<F: FilesProtocol>(
    diagnostics: [Diagnostic<F.FileId>],
    config: Config,
    styles: Styles,
    files: F
) throws -> String where F.Source: StringProtocol {
    var output = ""
    for diagnostic in diagnostics {
        try emit(
            writer: &output,
            config: config,
            styles: styles,
            styleEmitter: DebugStyleEmitter(),
            files: files,
            diagnostic: diagnostic
        )
    }
    return output
}

private func configForVariant(_ variant: String, base: Config) -> Config {
    var config = base
    if variant.contains("rich") {
        config.displayStyle = .rich
    } else if variant.contains("medium") {
        config.displayStyle = .medium
    } else if variant.contains("short") {
        config.displayStyle = .short
    }

    if variant.contains("ascii") {
        config.chars = .ascii
    }

    if let tabWidth = tabWidthFromVariant(variant) {
        config.tabWidth = tabWidth
    }

    return config
}

private func themeForVariant(_ variant: String) -> Styles {
    if variant.hasSuffix("_no_color") {
        return .noColor
    }
    if variant.hasSuffix("_color") {
        return .standardColor
    }
    return .noColor
}

private func tabWidthFromVariant(_ variant: String) -> UInt? {
    guard variant.contains("tab_width_") else {
        return nil
    }
    let parts = variant.split(separator: "_")
    guard let index = parts.firstIndex(of: "width"), index + 1 < parts.count else {
        return nil
    }
    return UInt(String(parts[index + 1]))
}

private func parseSnapshotName(_ name: String) -> (module: String, variant: String) {
    let base = name.replacingOccurrences(of: ".snap", with: "")
    let parts = base.split(separator: "__")
    return (String(parts[1]), String(parts[2]))
}

private func loadSnapshotNames() throws -> [String] {
    let url = fixturesURL()
    let files = try FileManager.default.contentsOfDirectory(atPath: url.path)
    return files.filter { $0.hasSuffix(".snap") }.sorted()
}

private func loadSnapshotContent(name: String) throws -> String {
    let url = fixturesURL().appendingPathComponent(name)
    let text = try String(contentsOf: url, encoding: .utf8)
    let lines = text.components(separatedBy: "\n")
    var separators: [Int] = []
    for (index, line) in lines.enumerated() where line == "---" {
        separators.append(index)
    }
    guard separators.count >= 2 else {
        throw SnapshotError.invalidSnapshot(name)
    }
    return lines[(separators[1] + 1)...].joined(separator: "\n")
}

private func fixturesURL() -> URL {
    let testsURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    return testsURL.appendingPathComponent("Fixtures")
}

private enum SnapshotError: Error {
    case unknownModule(String)
    case invalidSnapshot(String)
}

private func trimTrailingNewlines(_ text: String) -> String {
    var result = text
    while result.hasSuffix("\n") {
        result.removeLast()
    }
    return result
}

private func unindent(_ text: String) -> String {
    var lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        .map(String.init)
    if lines.first == "" {
        lines.removeFirst()
    }
    let nonEmpty = lines.filter { !$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty }
    var indent = 0
    if let minIndent = nonEmpty.map({ line -> Int in
        line.prefix { $0 == " " || $0 == "\t" }.count
    }).min() {
        indent = minIndent
    }
    let result = lines.map { line in
        if line.count >= indent {
            return String(line.dropFirst(indent))
        }
        return line
    }
    return result.joined(separator: "\n")
}

private func byteCount(_ string: String) -> Int {
    string.utf8.count
}

private func byteRanges(of needle: String, in haystack: String) -> [Range<UInt>] {
    var ranges: [Range<UInt>] = []
    var searchStart = haystack.startIndex
    while let range = haystack.range(of: needle, range: searchStart..<haystack.endIndex) {
        let lower = UInt(haystack.utf8.distance(from: haystack.startIndex, to: range.lowerBound))
        let upper = lower + UInt(needle.utf8.count)
        ranges.append(lower..<upper)
        searchStart = range.upperBound
    }
    return ranges
}
