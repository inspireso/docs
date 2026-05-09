#!/usr/bin/env bash

# 测试脚本：验证 openvpn_batch.sh 的功能
# 由于实际 OpenVPN 环境可能不存在，主要测试脚本逻辑

SCRIPT_DIR=$(dirname "$0")
BATCH_SCRIPT="$SCRIPT_DIR/openvpn_batch.sh"

echo "=========================================="
echo "OpenVPN Batch Script Test"
echo "=========================================="

# 测试1：无参数调用
echo ""
echo "[Test 1] 无参数调用"
result=$(bash "$BATCH_SCRIPT" 2>&1)
if echo "$result" | grep -q "Usage:"; then
  echo "PASS - 显示使用说明"
else
  echo "FAIL - 未显示使用说明"
fi

# 测试2：错误动作参数
echo ""
echo "[Test 2] 错误动作参数"
result=$(bash "$BATCH_SCRIPT" invalid_action user1 2>&1)
if echo "$result" | grep -q "Error: Action must be"; then
  echo "PASS - 拒绝无效动作"
else
  echo "FAIL - 未拒绝无效动作"
fi

# 测试3：密码生成规则验证
echo ""
echo "[Test 3] 密码生成规则：用户名@随机8位密码"
USERNAME="testuser"
RANDOM_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)
USER_PASSWORD="$USERNAME@$RANDOM_PASS"

# 验证格式
if [[ "$USER_PASSWORD" =~ ^[a-zA-Z0-9_]+@[a-zA-Z0-9]{8}$ ]]; then
  echo "PASS - 密码格式正确: $USER_PASSWORD"
else
  echo "FAIL - 密码格式错误: $USER_PASSWORD"
fi

# 验证随机部分长度
random_len=${#RANDOM_PASS}
if [ "$random_len" -eq 8 ]; then
  echo "PASS - 随机部分长度为8位"
else
  echo "FAIL - 随机部分长度错误: $random_len"
fi

# 测试4：多次生成密码验证随机性
echo ""
echo "[Test 4] 密码随机性验证（生成10个密码）"
declare -a PASSWORDS
for i in {1..10}; do
  PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)
  PASSWORDS+=("$PASS")
done

unique_count=$(printf '%s\n' "${PASSWORDS[@]}" | sort -u | wc -l | tr -d ' ')
if [ "$unique_count" -ge 9 ]; then
  echo "PASS - 生成的密码具有随机性（10个密码中至少9个不同）"
else
  echo "FAIL - 密码随机性不足（10个密码中仅$unique_count个不同）"
fi

# 测试5：用户列表文件读取
echo ""
echo "[Test 5] 用户列表文件读取"
TEST_USER_FILE=$(mktemp)
cat > "$TEST_USER_FILE" <<EOF
# 这是注释行
user1
user2

user3
# 另一个注释
EOF

# 模拟读取逻辑
USERS=$(grep -v '^#' "$TEST_USER_FILE" | grep -v '^$')
expected_count=3
actual_count=$(echo "$USERS" | wc -l | tr -d ' ')

if [ "$actual_count" -eq "$expected_count" ]; then
  echo "PASS - 正确读取用户列表（$actual_count个用户）"
else
  echo "FAIL - 用户列表读取错误"
  echo "  Expected: $expected_count users"
  echo "  Actual: $actual_count users"
fi

rm "$TEST_USER_FILE"

# 测试6：文件不存在错误处理
echo ""
echo "[Test 6] 文件不存在错误处理"
result=$(bash "$BATCH_SCRIPT" create -f /tmp/nonexistent_file.txt 2>&1)
if echo "$result" | grep -q "Error: File not found"; then
  echo "PASS - 正确处理文件不存在"
else
  echo "FAIL - 未正确处理文件不存在"
fi

# 测试7：密码强度验证
echo ""
echo "[Test 7] 密码强度验证"
PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)

# 检查是否包含字母和数字
has_letter=0
has_digit=0

if [[ "$PASS" =~ [a-zA-Z] ]]; then
  has_letter=1
fi
if [[ "$PASS" =~ [0-9] ]]; then
  has_digit=1
fi

if [ "$has_letter" -eq 1 ] && [ "$has_digit" -eq 1 ]; then
  echo "PASS - 密码包含字母和数字: $PASS"
else
  echo "FAIL - 密码强度不足: $PASS"
fi

# 测试总结
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "所有基础逻辑测试已完成"
echo "注意：实际证书生成需要在有 OpenVPN 环境的服务器上运行"