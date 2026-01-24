import Foundation
import ClaudeCodeKit

/// 비대화형 테스트 러너
@MainActor
struct TestRunner {
    /// 기본 테스트 (--test)
    static func runTest() async {
        print("🧪 Running non-interactive test...")
        print("================================\n")

        let manager = ClaudeCodeManager()
        var receivedInit = false
        var receivedResponse = false
        var testComplete = false

        manager.onEvent = { event in
            switch event {
            case .systemInit(let msg):
                receivedInit = true
                print("✅ [1/3] Received system init")
                print("   Version: \(msg.claudeCodeVersion)")
                print("   Model: \(msg.model)")
                print("   Tools: \(msg.tools.count)")

            case .textOutput(let text):
                receivedResponse = true
                print("✅ [2/3] Received text response")
                print("   Text: \(text.prefix(100))...")

            case .askUserQuestion(let toolId, let input):
                print("✅ [BONUS] Received AskUserQuestion!")
                print("   Tool ID: \(toolId)")
                print("   Question: \(input.questions.first?.question ?? "N/A")")
                print("   Options: \(input.questions.first?.options.map { $0.label }.joined(separator: ", ") ?? "N/A")")

                // 자동 응답
                if let firstOption = input.questions.first?.options.first {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        do {
                            try manager.sendAskUserQuestionResponse(answers: ["q0": firstOption.label])
                            print("   → Auto-answered: \(firstOption.label)")
                        } catch {
                            print("   → Failed to respond: \(error)")
                        }
                    }
                }

            case .result(let msg):
                print("✅ [3/3] Received result")
                print("   Success: \(!msg.isError)")
                if let cost = msg.totalCostUsd {
                    print("   Cost: $\(String(format: "%.4f", cost))")
                }
                testComplete = true

            case .error(let error):
                print("⚠️ Error: \(error.localizedDescription)")

            case .processExited(let code):
                print("\n📊 Process exited: \(code)")
                testComplete = true

            case .assistantMessage:
                break
            }
        }

        // 시작
        do {
            try manager.start()
            print("🚀 Claude Code started\n")
        } catch {
            print("❌ Failed: \(error)")
            return
        }

        // 1초 후 메시지 전송
        try? await Task.sleep(for: .seconds(1))

        print("📤 Sending test message...\n")
        do {
            try manager.sendMessage("Say 'Hello from Swift!' in exactly those words.")
        } catch {
            print("❌ Send failed: \(error)")
        }

        // 응답 대기 (최대 30초)
        for _ in 0..<60 {
            if testComplete { break }
            try? await Task.sleep(for: .milliseconds(500))
        }

        manager.stop()

        // 결과 출력
        print("\n================================")
        print("📊 Test Results:")
        print("   System Init: \(receivedInit ? "✅" : "❌")")
        print("   Text Response: \(receivedResponse ? "✅" : "❌")")
        print("   Test Complete: \(testComplete ? "✅" : "❌")")

        if receivedInit && receivedResponse && testComplete {
            print("\n🎉 All tests passed!")
        } else {
            print("\n⚠️ Some tests failed")
        }
    }

    /// AskUserQuestion 테스트 (--test-ask)
    static func runAskTest() async {
        print("🧪 Running AskUserQuestion test...")
        print("==================================\n")

        let manager = ClaudeCodeManager()
        var receivedQuestion = false
        var answeredQuestion = false
        var testComplete = false

        manager.onEvent = { event in
            switch event {
            case .systemInit(let msg):
                print("📡 Connected: v\(msg.claudeCodeVersion)")

            case .textOutput(let text):
                print("🤖 Claude: \(text.prefix(150))...")
                if answeredQuestion {
                    testComplete = true
                }

            case .askUserQuestion(let toolId, let input):
                receivedQuestion = true
                print("\n✅ Received AskUserQuestion!")
                print("   Tool ID: \(toolId)")

                if let q = input.questions.first {
                    print("   Question: \(q.question)")
                    print("   Options:")
                    for (i, opt) in q.options.enumerated() {
                        print("     \(i+1). \(opt.label) - \(opt.description)")
                    }

                    // 첫 번째 옵션으로 자동 응답
                    let selected = q.options.first?.label ?? "Option 1"
                    print("\n📤 Auto-selecting: \(selected)")

                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        do {
                            try manager.sendAskUserQuestionResponse(answers: ["q0": selected])
                            answeredQuestion = true
                            print("✅ Response sent!")
                        } catch {
                            print("❌ Failed: \(error)")
                        }
                    }
                }

            case .result(let msg):
                if let cost = msg.totalCostUsd {
                    print("\n💰 Cost: $\(String(format: "%.4f", cost))")
                }
                if answeredQuestion {
                    testComplete = true
                }

            case .error(let error):
                print("⚠️ \(error.localizedDescription)")

            case .processExited(let code):
                print("\n👋 Exited: \(code)")
                testComplete = true

            case .assistantMessage:
                break
            }
        }

        do {
            try manager.start()
            print("🚀 Started\n")
        } catch {
            print("❌ Failed: \(error)")
            return
        }

        try? await Task.sleep(for: .seconds(1))

        print("📤 Requesting AskUserQuestion...\n")
        do {
            try manager.sendMessage("Use the AskUserQuestion tool to ask me which color I prefer. Give me 3 color options.")
        } catch {
            print("❌ Send failed: \(error)")
        }

        // 60초 대기
        for _ in 0..<120 {
            if testComplete { break }
            try? await Task.sleep(for: .milliseconds(500))
        }

        manager.stop()

        print("\n==================================")
        print("📊 Results:")
        print("   Received Question: \(receivedQuestion ? "✅" : "❌")")
        print("   Answered Question: \(answeredQuestion ? "✅" : "❌")")
        print("   Test Complete: \(testComplete ? "✅" : "❌")")

        if receivedQuestion && answeredQuestion && testComplete {
            print("\n🎉 AskUserQuestion test passed!")
        } else {
            print("\n⚠️ Test incomplete")
        }
    }
}
