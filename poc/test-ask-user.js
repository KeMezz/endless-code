#!/usr/bin/env node
/**
 * PoC 3: AskUserQuestion 감지 및 응답 테스트
 */

const { spawn } = require('child_process');

const claude = spawn('claude', [
  '-p',
  '--input-format=stream-json',
  '--output-format=stream-json',
  '--verbose'
], {
  stdio: ['pipe', 'pipe', 'pipe']
});

let outputBuffer = '';
let pendingToolUse = null;

function sendMessage(msg) {
  console.log('\n>>> SENDING:', JSON.stringify(msg));
  claude.stdin.write(JSON.stringify(msg) + '\n');
}

function sendToolResult(toolUseId, result) {
  // 방법 1: user 타입으로 tool_result 포함
  const msg = {
    type: 'user',
    message: {
      role: 'user',
      content: [{
        type: 'tool_result',
        tool_use_id: toolUseId,
        content: result
      }]
    }
  };
  sendMessage(msg);
}

claude.stdout.on('data', (data) => {
  outputBuffer += data.toString();
  const lines = outputBuffer.split('\n');
  outputBuffer = lines.pop();

  for (const line of lines) {
    if (!line.trim()) continue;

    try {
      const json = JSON.parse(line);
      console.log('\n<<< RECEIVED:', json.type, json.subtype || '');

      // tool_use 감지
      if (json.type === 'assistant' && json.message?.content) {
        for (const block of json.message.content) {
          if (block.type === 'tool_use') {
            console.log('🔧 Tool:', block.name);
            console.log('   ID:', block.id);
            console.log('   Input:', JSON.stringify(block.input, null, 2));

            if (block.name === 'AskUserQuestion') {
              pendingToolUse = block;
              console.log('\n🎯 AskUserQuestion detected!');
              console.log('   Questions:', JSON.stringify(block.input.questions, null, 2));

              // 3초 후 자동 응답
              setTimeout(() => {
                if (pendingToolUse) {
                  const answer = { q0: block.input.questions[0].options[0].label };
                  console.log('\n📝 Auto-answering:', answer);
                  sendToolResult(block.id, JSON.stringify({ answers: answer }));
                  pendingToolUse = null;
                }
              }, 2000);
            }
          }
          if (block.type === 'text') {
            console.log('📄 Text:', block.text.slice(0, 150));
          }
        }
      }

      if (json.type === 'result') {
        console.log('✅ Result:', json.result?.slice(0, 200));
        console.log('   Cost: $' + json.total_cost_usd?.toFixed(4));
      }
    } catch (e) {
      console.log('Parse error:', e.message, line.slice(0, 50));
    }
  }
});

claude.stderr.on('data', (data) => {
  console.error('STDERR:', data.toString());
});

claude.on('close', (code) => {
  console.log('\n=== Exited:', code, '===');
});

// AskUserQuestion을 유발할 프롬프트 전송
setTimeout(() => {
  sendMessage({
    type: 'user',
    message: {
      role: 'user',
      content: 'I want to create a new file. Use the AskUserQuestion tool to ask me what filename I want.'
    }
  });
}, 1000);

// 30초 후 타임아웃
setTimeout(() => {
  console.log('\n=== Timeout ===');
  claude.stdin.end();
}, 30000);
