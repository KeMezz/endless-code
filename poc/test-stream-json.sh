#!/bin/bash
# PoC 1: stream-json 출력 형식 확인

echo "=== PoC 1: Testing --output-format=stream-json ==="
echo ""

# 간단한 프롬프트로 JSONL 출력 확인
claude -p "say hello in korean, just one word" \
  --output-format=stream-json \
  --dangerously-skip-permissions \
  2>/dev/null | head -50

echo ""
echo "=== End of PoC 1 ==="
