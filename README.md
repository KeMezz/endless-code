# EndlessCode

A native Claude Code client for macOS/iOS.

Use all Claude Code CLI features through a seamless GUI. Enjoy interactive workflows with an intuitive interface without needing to open a terminal.

## Features

### macOS App (Server + Client)
- **CLI Process Management**: Run Claude Code CLI as subprocess with direct stdin/stdout control
- **JSONL Streaming Parser**: Real-time message parsing and classification
- **Interactive Prompt Handling**: Handle CLI interactions (AskUserQuestion, etc.) via GUI
- **WebSocket API**: Real-time bidirectional communication
- **Chat Interface**: Markdown rendering, syntax-highlighted code blocks
- **File Explorer**: Project directory tree with syntax highlighting
- **Diff Viewer**: Git diff visualization

### iOS App (Client)
- **Remote Access**: Connect to macOS server for mobile usage
- **Bonjour Server Discovery**: Auto-detect servers on local network
- **Mobile-Optimized UI**: Touch-friendly interface

## Requirements

### System
- macOS 26.0+ (Tahoe) / iOS 26.0+
- Apple Silicon (M1+)
- Xcode 16+

### Prerequisites
- [Claude Code CLI](https://docs.anthropic.com/claude-code) installed and authenticated
- Git

## Installation

### Build from Source

```bash
git clone https://github.com/user/cc-wrapper.git
cd cc-wrapper
open EndlessCode.xcodeproj
```

Run with `Cmd + R` in Xcode.

## Architecture

```
┌─────────────────────────────────────┐
│         Client Layer (SwiftUI)      │
│   macOS App          iOS App        │
└───────────┬─────────────┬───────────┘
            │ WebSocket   │
┌───────────▼─────────────▼───────────┐
│         Server Layer (Vapor)        │
│   ClaudeCodeManager, SessionManager │
└───────────────────┬─────────────────┘
                    │ stdin/stdout
              ┌─────▼─────┐
              │ claude CLI│
              └───────────┘
```

## Development

### Build

```bash
xcodebuild build -scheme EndlessCode -destination 'platform=macOS'
```

### Test

```bash
# Run all tests
xcodebuild test -scheme EndlessCode -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme EndlessCode -destination 'platform=macOS' \
  -only-testing:EndlessCodeTests/JSONLParserTests
```

### Coverage

```bash
xcodebuild test -scheme EndlessCode -destination 'platform=macOS' \
  -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
xcrun xccov view --report TestResults.xcresult
```

## Tech Stack

| Area | Technology |
|------|------------|
| Language | Swift 6.2+ (Strict Concurrency) |
| UI | SwiftUI |
| Server | Vapor 4 |
| Syntax Highlighting | Tree-sitter |
| Markdown | MarkdownUI |

## Project Structure

```
EndlessCode/
├── Shared/              # Common Models, ViewModels
├── ClaudeCodeServer/    # CLI management, JSONL parsing, WebSocket API
├── macOS/               # macOS app (includes server)
└── iOS/                 # iOS app (client only)
```

## Specifications

This project uses OpenSpec for spec-driven development.

- Specs: `openspec/changes/add-mvp-specs/specs/`
- Tasks: `openspec/changes/add-mvp-specs/tasks.md`

## License

MIT

## Contributing

PRs are welcome. Before contributing, please ensure:

1. Test coverage remains above 80%
2. Code follows Swift 6.2 Strict Concurrency
3. Commits follow Conventional Commits format
