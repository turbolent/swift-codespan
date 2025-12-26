import Foundation

import Codespan

enum OutputMode: String {
    case plain
    case svg
    case ansi
}

struct FileHandleOutputStream: TextOutputStream {
    let fileHandle: FileHandle

    init(_ fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    mutating func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            fileHandle.write(data)
        }
    }
}

func renderPlain(to output: inout some TextOutputStream) throws {
    let example = ReadmeExample.make()
    try emit(
        writer: &output,
        config: .init(),
        styles: .standard,
        styleEmitter: PlainStyleEmitter(),
        files: example.files,
        diagnostic: example.diagnostic
    )
}

func renderAnsi(to output: inout some TextOutputStream) throws {
    let example = ReadmeExample.make()
    try emit(
        writer: &output,
        config: .init(),
        styles: .standardColor,
        styleEmitter: ANSIStyleEmitter(),
        files: example.files,
        diagnostic: example.diagnostic
    )
}

func renderSvg(to output: inout some TextOutputStream) throws {
    let example = ReadmeExample.make()
    var content = ""
    try emit(
        writer: &content,
        config: .init(),
        styles: .standardColor,
        styleEmitter: SVGStyleEmitter(),
        files: example.files,
        diagnostic: example.diagnostic
    )

    let numLines = content.components(separatedBy: "\n").count
    let padding = 10
    let fontSize = 12
    let lineSpacing = 3
    let width = 882
    let height = padding + numLines * (fontSize + lineSpacing) + padding

    let full = svgTemplate(
        content: content,
        width: width,
        height: height,
        padding: padding,
        fontSize: fontSize
    )

    output.write(full)
}

func svgTemplate(
    content: String,
    width: Int,
    height: Int,
    padding: Int,
    fontSize: Int
) -> String {
    """
    <svg viewBox="0 0 \(width) \(height)" xmlns="http://www.w3.org/2000/svg">
      <style>
        /* https://github.com/aaron-williamson/base16-alacritty/blob/master/colors/base16-tomorrow-night-256.yml */
            pre {
                background: #1d1f21;
                margin: 0;
                padding: \(padding)px;
                border-radius: 6px;
                color: #ffffff;
                font: \(fontSize)px SFMono-Regular, Consolas, Liberation Mono, Menlo, monospace;
            }
            
            pre .bold {
                font-weight: bold;
            }
            
            pre .header-bug,
            pre .header-error {
                color: #cc6666;
                font-weight: bold;
            }
            
            pre .header-warning {
                color: #f0c674;
                font-weight: bold;
            }
            
            pre .header-note {
                color: #b5bd68;
                font-weight: bold;
            }
            
            pre .header-help {
                color: #8abeb7;
                font-weight: bold;
            }
            
            pre .header-message {
                color: #c5c8c6;
                font-weight: bold;
            }
            
            pre .line-number,
            pre .source-border,
            pre .note-bullet {
                color: #81a2be;
            }
            
            pre .label-primary-bug,
            pre .label-primary-error {
                color: #cc6666;
            }
            
            pre .label-primary-warning {
                color: #f0c674;
            }
            
            pre .label-primary-note {
                color: #b5bd68;
            }
            
            pre .label-primary-help {
                color: #8abeb7;
            }
            
            pre .label-secondary-bug,
            pre .label-secondary-error,
            pre .label-secondary-warning,
            pre .label-secondary-note,
            pre .label-secondary-help {
                color: #81a2be;
            }
      </style>

      <foreignObject x="0" y="0" width="\(width)" height="\(height)">
        <div xmlns="http://www.w3.org/1999/xhtml">
          <pre>\(content)</pre>
        </div>
      </foreignObject>
    </svg>
    """
}

func writeStderr(_ string: String) {
    FileHandle.standardError.write(Data(string.utf8))
}

func printUsage() {
    writeStderr(
        """
        Usage: codespan-readme-preview <plain|svg|ansi>
        """
    )
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let modeRaw = args.first else {
        printUsage()
        exit(1)
    }

    if modeRaw == "--help" || modeRaw == "-h" {
        printUsage()
        exit(0)
    }

    guard let mode = OutputMode(rawValue: modeRaw) else {
        printUsage()
        exit(1)
    }

    var output = FileHandleOutputStream(FileHandle.standardOutput)
    switch mode {
    case .plain:
        try renderPlain(to: &output)
    case .ansi:
        try renderAnsi(to: &output)
    case .svg:
        try renderSvg(to: &output)
    }
} catch {
    writeStderr("error: \(error)\n")
    exit(1)
}
