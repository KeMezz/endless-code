#!/usr/bin/env node
/**
 * PoC 2: 양방향 stream-json 통신 테스트
 *
 * Claude Code CLI의 --input-format=stream-json, --output-format=stream-json
 * 옵션을 사용하여 양방향 통신이 가능한지 확인
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

claude.stdout.on('data', (data) => {
  outputBuffer += data.toString();
  const lines = outputBuffer.split('\n');
  outputBuffer = lines.pop(); // 마지막 불완전한 라인 보관

  for (const line of lines) {
    if (line.trim()) {
      try {
        const json = JSON.parse(line);
        console.log('\n=== RECEIVED ===');
        console.log('Type:', json.type);
        if (json.subtype) console.log('Subtype:', json.subtype);

        // tool_use 감지
        if (json.type === 'assistant' && json.message?.content) {
          for (const block of json.message.content) {
            if (block.type === 'tool_use') {
              console.log('🔧 Tool Use:', block.name);
              console.log('   Input:', JSON.stringify(block.input, null, 2).slice(0, 200));
            }
          }
        }

        // 결과 출력
        if (json.type === 'result') {
          console.log('Result:', json.result?.slice(0, 200));
        }
      } catch (e) {
        console.log('Parse error:', line.slice(0, 100));
      }
    }
  }
});

claude.stderr.on('data', (data) => {
  console.error('STDERR:', data.toString());
});

claude.on('close', (code) => {
  console.log('\n=== Process exited with code:', code, '===');
});

// 첫 번째 메시지 전송
setTimeout(() => {
  const message = {
    type: 'user',
    message: {
      role: 'user',
      content: 'Say "hello" in Korean'
    }
  };
  console.log('\n=== SENDING ===');
  console.log(JSON.stringify(message));
  claude.stdin.write(JSON.stringify(message) + '\n');
}, 1000);

// 5초 후 종료
setTimeout(() => {
  console.log('\n=== Timeout, closing... ===');
  claude.stdin.end();
}, 15000);
