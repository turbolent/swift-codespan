# swift-codespan

Swift port of the Rust library [`codespan`](https://github.com/brendanzab/codespan),
beautiful diagnostic reporting for text-based programming languages.

![Example preview](./readme_preview.svg?sanitize=true)

## Example

```swift
import Codespan

let source = """
module FizzBuzz where

fizz₁ : Nat → String
fizz₁ num = case (mod num 5) (mod num 3) of
    0 0 => "FizzBuzz"
    0 _ => "Fizz"
    _ 0 => "Buzz"
    _ _ => num

fizz₂ : Nat → String
fizz₂ num =
    case (mod num 5) (mod num 3) of
        0 0 => "FizzBuzz"
        0 _ => "Fizz"
        _ 0 => "Buzz"
        _ _ => num
"""

var files = Files<String>()
let fileId = files.add(name: "FizzBuzz.fun", source: source)

let diagnostic = Diagnostic<FileId>.error(
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
    notes: [
        """
        expected type `String`
           found type `Nat`
        """
    ]
)

var output = ""
try emit(
    writer: &output,
    config: .init(),
    styles: .standard,
    styleEmitter: PlainStyleEmitter(),
    files: files,
    diagnostic: diagnostic
)
print(output)
```

Rendered output (rich, no color):

```
error[E0308]: `case` clauses have incompatible types
   ┌─ FizzBuzz.fun:16:16
   │
10 │   fizz₂ : Nat → String
   │                 ------ expected type `String` found here
11 │   fizz₂ num =
12 │ ╭     case (mod num 5) (mod num 3) of
13 │ │         0 0 => "FizzBuzz"
   │ │                ---------- this is found to be of type `String`
14 │ │         0 _ => "Fizz"
   │ │                ------ this is found to be of type `String`
15 │ │         _ 0 => "Buzz"
   │ │                ------ this is found to be of type `String`
16 │ │         _ _ => num
   │ │                ^^^ expected `String`, found `Nat`
   │ ╰──────────────────' `case` clauses have incompatible types
   │
   = expected type `String`
        found type `Nat`
```
