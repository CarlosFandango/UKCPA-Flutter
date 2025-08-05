#!/bin/bash

# Start backend server for integration tests
# This script ensures the backend is properly configured for testing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BACKEND_DIR="../../../UKCPA-Server"
BACKEND_PORT=4000
MAX_WAIT_TIME=30

echo -e "${YELLOW}🚀 Starting UKCPA Backend for Integration Tests${NC}"

# Navigate to script directory
cd "$(dirname "$0")"

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
  echo -e "${RED}❌ Backend directory not found at $BACKEND_DIR${NC}"
  echo "Please ensure UKCPA-Server is in the correct location"
  exit 1
fi

# Navigate to backend directory
cd "$BACKEND_DIR"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo -e "${YELLOW}Installing backend dependencies...${NC}"
  yarn install
fi

# Create test environment file if it doesn't exist
if [ ! -f ".env.test" ]; then
  echo -e "${YELLOW}Creating test environment configuration...${NC}"
  cat > .env.test << EOF
# Test Environment Configuration
NODE_ENV=test
PORT=$BACKEND_PORT

# Database (using test database)
DATABASE_URL=postgresql://postgres@localhost:5433/dancehub_test
DATABASE_TEST_URL=postgresql://postgres@localhost:5433/dancehub_test

# Redis
REDIS_URL=redis://localhost:6379

# Session
SESSION_SECRET=test-session-secret

# Site Configuration
SITE_ID=UKCPA
ALLOW_MUTATIONS=true

# CORS Origins
WEBSITE_ORIGIN=http://localhost:3050
EVENTS_ORIGIN=http://localhost:3075
CHILD_ORIGIN=http://localhost:3000
FLUTTER_ORIGIN=http://localhost:*

# Test Mode
IS_TEST_MODE=true
EOF
fi

# Check if backend is already running
if lsof -Pi :$BACKEND_PORT -sTCP:LISTEN -t >/dev/null ; then
  echo -e "${GREEN}✅ Backend already running on port $BACKEND_PORT${NC}"
  exit 0
fi

# Start backend in test mode
echo -e "${YELLOW}Starting backend server...${NC}"

# Use test environment
export NODE_ENV=test

# Start server in background
nohup yarn start:dev > backend-test.log 2>&1 &
BACKEND_PID=$!

echo "Backend PID: $BACKEND_PID"
echo $BACKEND_PID > backend-test.pid

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
WAIT_TIME=0

while [ $WAIT_TIME -lt $MAX_WAIT_TIME ]; do
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:$BACKEND_PORT/graphql | grep -q "200\|400"; then
    echo -e "${GREEN}✅ Backend is ready!${NC}"
    echo "GraphQL endpoint: http://localhost:$BACKEND_PORT/graphql"
    exit 0
  fi
  
  sleep 1
  WAIT_TIME=$((WAIT_TIME + 1))
  echo -n "."
done

echo ""
echo -e "${RED}❌ Backend failed to start within $MAX_WAIT_TIME seconds${NC}"
echo "Check backend-test.log for errors"
tail -n 20 backend-test.log
exit 1