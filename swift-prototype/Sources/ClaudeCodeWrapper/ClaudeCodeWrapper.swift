import Foundation
import ClaudeCodeKit

@main
struct ClaudeCodeWrapper {
    @MainActor
    static func main() async {
        // 테스트 모드 체크
        if CommandLine.arguments.contains("--test") {
            await TestRunner.runTest()
            return
        }

        if CommandLine.arguments.contains("--test-ask") {
            await TestRunner.runAskTest()
            return
        }

        print("🚀 Claude Code Wrapper - Swift Prototype")
        print("=========================================\n")

        let manager = ClaudeCodeManager()
        var pendingQuestion: (toolId: String, input: AskUserQuestionInput)?

        // 이벤트 핸들러 설정
        manager.onEvent = { event in
            switch event {
            case .systemInit(let msg):
                print("📡 Connected to Claude Code v\(msg.claudeCodeVersion)")
                print("   Model: \(msg.model)")
                print("   Session: \(msg.sessionId)")
                print("   Tools: \(msg.tools.count) available\n")

            case .assistantMessage:
                // textOutput에서 처리
                break

            case .textOutput(let text):
                print("🤖 Claude: \(text)\n")

            case .askUserQuestion(let toolId, let input):
                pendingQuestion = (toolId, input)
                print("\n❓ Claude is asking a question:")
                for (_, question) in input.questions.enumerated() {
                    print("   [\(question.header)] \(question.question)")
                    for (optIndex, option) in question.options.enumerated() {
                        print("   \(optIndex + 1). \(option.label) - \(option.description)")
                    }
                    if question.multiSelect {
                        print("   (Multiple selections allowed)")
                    }
                }
                print("\n   Enter option number (or 'other' for custom input):")

            case .result(let msg):
                if msg.isError {
                    print("❌ Error: \(msg.result ?? "Unknown error")")
                } else {
                    if let cost = msg.totalCostUsd {
                        print("💰 Cost: $\(String(format: "%.4f", cost))")
                    }
                }

            case .error(let error):
                print("⚠️ Error: \(error.localizedDescription)")

            case .processExited(let code):
                print("\n👋 Process exited with code: \(code)")
            }
        }

        // 프로세스 시작
        do {
            try manager.start()
            print("✅ Claude Code started successfully\n")
        } catch {
            print("❌ Failed to start: \(error.localizedDescription)")
            return
        }

        // 메인 루프
        print("Type your message (or 'quit' to exit):\n")

        while manager.isRunning {
            print("> ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }

            if input.lowercased() == "quit" || input.lowercased() == "exit" {
                manager.stop()
                break
            }

            // AskUserQuestion 응답 처리
            if let pending = pendingQuestion {
                if let optionNum = Int(input),
                   optionNum > 0,
                   let firstQuestion = pending.input.questions.first,
                   optionNum <= firstQuestion.options.count {
                    let selectedLabel = firstQuestion.options[optionNum - 1].label
                    do {
                        try manager.sendAskUserQuestionResponse(answers: ["q0": selectedLabel])
                        print("✓ Answered: \(selectedLabel)\n")
                    } catch {
                        print("❌ Failed to send response: \(error)")
                    }
                } else if input.lowercased() == "other" {
                    print("Enter your custom answer:")
                    if let customInput = readLine(), !customInput.isEmpty {
                        do {
                            try manager.sendAskUserQuestionResponse(answers: ["q0": customInput])
                            print("✓ Answered: \(customInput)\n")
                        } catch {
                            print("❌ Failed to send response: \(error)")
                        }
                    }
                } else {
                    // 일반 텍스트로 응답
                    do {
                        try manager.sendAskUserQuestionResponse(answers: ["q0": input])
                        print("✓ Answered: \(input)\n")
                    } catch {
                        print("❌ Failed to send response: \(error)")
                    }
                }
                pendingQuestion = nil
                continue
            }

            // 일반 메시지 전송
            do {
                try manager.sendMessage(input)
            } catch {
                print("❌ Failed to send message: \(error)")
            }

            // 응답 대기
            try? await Task.sleep(for: .milliseconds(500))
        }

        print("\n👋 Goodbye!")
    }
}
