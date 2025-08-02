#!/bin/bash

echo "🧪 Running Comprehensive Microservices Test Suite"
echo "=================================================="

# Test Results Storage
PASSED=0
FAILED=0

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local method="${4:-GET}"
    local data="${5:-}"
    
    echo -n "Testing $name... "
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$url")
    else
        response=$(curl -s -w "%{http_code}" "$url")
    fi
    
    status_code="${response: -3}"
    body="${response%???}"
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "✅ PASS (Status: $status_code)"
        ((PASSED++))
    else
        echo "❌ FAIL (Expected: $expected_status, Got: $status_code)"
        echo "   Response: $body"
        ((FAILED++))
    fi
}

echo ""
echo "🔍 Health Check Tests"
echo "--------------------"
test_endpoint "Gaming Service Health" "http://localhost:3001/health" "200"
test_endpoint "Order Service Health" "http://localhost:3002/health" "200"
test_endpoint "Analytics Service Health" "http://localhost:3003/health" "200"
test_endpoint "Frontend Health" "http://localhost:8080/health" "200"

echo ""
echo "🎮 Gaming Service API Tests"
echo "---------------------------"
test_endpoint "Products List" "http://localhost:3001/api/products" "200"
test_endpoint "Metrics Endpoint" "http://localhost:3001/metrics" "200"

echo ""
echo "📊 Analytics Service API Tests"
echo "------------------------------"
test_endpoint "Analytics Dashboard" "http://localhost:3003/analytics/dashboard" "200"
test_endpoint "Event Tracking" "http://localhost:3003/analytics/track/event" "201" "POST" '{"session_id":"test-123","event_type":"click","event_name":"test_button"}'
test_endpoint "Page Visit Tracking" "http://localhost:3003/analytics/track/page-visit" "201" "POST" '{"session_id":"test-123","url":"http://localhost:8080/test","path":"/test","title":"Test Page"}'

echo ""
echo "🏪 Order Service API Tests"
echo "--------------------------"
# Note: Order service might be rate limited, so we test with a delay
sleep 2
test_endpoint "Order Service Metrics" "http://localhost:3002/metrics" "200"

echo ""
echo "🌐 Frontend Tests"
echo "----------------"
test_endpoint "Frontend Main Page" "http://localhost:8080" "200"
test_endpoint "Frontend Static Assets" "http://localhost:8080/static/css/main.4274ed75.css" "200"

echo ""
echo "🗄️ Database Connection Tests"
echo "----------------------------"
echo -n "Testing PostgreSQL connection... "
if docker-compose -f docker-compose.local.yml exec -T postgres psql -U postgres -d lugx_gaming -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ PASS"
    ((PASSED++))
else
    echo "❌ FAIL"
    ((FAILED++))
fi

echo -n "Testing ClickHouse connection... "
if curl -s http://localhost:8123/ping | grep -q "Ok"; then
    echo "✅ PASS"
    ((PASSED++))
else
    echo "❌ FAIL"
    ((FAILED++))
fi

echo ""
echo "📈 Test Results Summary"
echo "======================"
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo "📊 Total: $((PASSED + FAILED))"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed! Your microservices are working perfectly!"
    echo ""
    echo "🌐 Access your application:"
    echo "   Frontend: http://localhost:8080"
    echo "   Gaming API: http://localhost:3001"
    echo "   Order API: http://localhost:3002"
    echo "   Analytics API: http://localhost:3003"
    exit 0
else
    echo ""
    echo "⚠️  Some tests failed. Check the logs with:"
    echo "   docker-compose -f docker-compose.local.yml logs [service-name]"
    exit 1
fi
