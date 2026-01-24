#!/usr/bin/env node
/**
 * PoC 4: AskUserQuestion 응답 - 다양한 형식 테스트
 */

const { spawn } = require('child_process');

const claude = spawn('claude', [
  '-p',
  '--input-format=stream-json',
  '--output-format=stream-json',
  '--verbose',
  '--include-partial-messages'
], {
  stdio: ['pipe', 'pipe', 'pipe']
});

let outputBuffer = '';
let pendingToolUse = null;
let attemptCount = 0;

const responseFormats = [
  // 형식 1: answers 객체만
  (toolId, input) => ({
    type: 'user',
    message: {
      role: 'user',
      content: JSON.stringify({
        answers: { q0: input.questions[0].options[0].label }
      })
    }
  }),
  // 형식 2: 직접 텍스트 응답
  (toolId, input) => ({
    type: 'user',
    message: {
      role: 'user',
      content: input.questions[0].options[0].label
    }
  }),
];

function sendMessage(msg) {
  console.log('\n>>> SENDING:', JSON.stringify(msg, null, 2));
  claude.stdin.write(JSON.stringify(msg) + '\n');
}

claude.stdout.on('data', (data) => {
  outputBuffer += data.toString();
  const lines = outputBuffer.split('\n');
  outputBuffer = lines.pop();

  for (const line of lines) {
    if (!line.trim()) continue;

    try {
      const json = JSON.parse(line);

      // 상세 로깅
      if (json.type === 'assistant') {
        console.log('\n<<< ASSISTANT MESSAGE');
        if (json.message?.content) {
          for (const block of json.message.content) {
            console.log('   Block type:', block.type);
            if (block.type === 'tool_use') {
              console.log('   Tool:', block.name, '| ID:', block.id);
              if (block.name === 'AskUserQuestion') {
                pendingToolUse = block;
                console.log('\n🎯 AskUserQuestion detected!');
                console.log(JSON.stringify(block.input, null, 2));

                // 2초 후 응답 시도
                setTimeout(() => {
                  if (pendingToolUse && attemptCount < responseFormats.length) {
                    const format = responseFormats[attemptCount];
                    console.log(`\n📝 Trying format ${attemptCount + 1}...`);
                    sendMessage(format(block.id, block.input));
                    attemptCount++;
                    pendingToolUse = null;
                  }
                }, 2000);
              }
            }
            if (block.type === 'text') {
              console.log('   Text:', block.text?.slice(0, 100));
            }
          }
        }
      } else if (json.type === 'result') {
        console.log('\n✅ RESULT:', json.subtype);
        console.log('   Message:', json.result?.slice(0, 150));
      } else if (json.type === 'system') {
        console.log('\n<<< SYSTEM:', json.subtype);
      } else if (json.type === 'user') {
        console.log('\n<<< USER (echo back)');
      } else {
        console.log('\n<<< OTHER:', json.type);
      }
    } catch (e) {
      console.log('Parse error:', e.message);
    }
  }
});

claude.stderr.on('data', (data) => {
  const msg = data.toString().trim();
  if (msg) console.error('STDERR:', msg);
});

claude.on('close', (code) => {
  console.log('\n=== Exited:', code, '===');
  process.exit(0);
});

// 프롬프트 전송
setTimeout(() => {
  sendMessage({
    type: 'user',
    message: {
      role: 'user',
      content: 'Please use the AskUserQuestion tool to ask me which programming language I prefer. Provide at least 3 options.'
    }
  });
}, 500);

// 20초 후 타임아웃
setTimeout(() => {
  console.log('\n=== Timeout ===');
  claude.stdin.end();
}, 20000);
