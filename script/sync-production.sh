#!/bin/bash
# Simple production sync script
set -e

# Load .env file if it exists (Rails dotenv-rails style)
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# Configuration with defaults
PROD_HOST="${PROD_HOST:-your-vps-hostname}"
PROD_USER="${PROD_USER:-deploy}"
PROD_DB="${PROD_DB:-blackbook_production}"
LOCAL_DB="${LOCAL_DB:-blackbook_dev}"
PROD_APP_PATH="${PROD_APP_PATH:-/var/www/blackbook}"

echo "🚀 Syncing production data..."
echo "Production: $PROD_USER@$PROD_HOST"

# 1. Sync database
echo "📊 Syncing database..."

# Get database config from production and create secure mysqldump
ssh "$PROD_USER@$PROD_HOST" "cd '$PROD_APP_PATH' && 
  # Parse database.yml
  DB_USER=\$(grep -A 20 '^production:' config/database.yml | grep -E '^\s+username:' | sed 's/.*username:\s*//' | sed 's/[\"'\'']//' | tr -d ' ')
  DB_PASS=\$(grep -A 20 '^production:' config/database.yml | grep -E '^\s+password:' | sed 's/.*password:\s*//' | sed 's/[\"'\'']//' | tr -d ' ')
  DB_HOST=\$(grep -A 20 '^production:' config/database.yml | grep -E '^\s+host:' | sed 's/.*host:\s*//' | sed 's/[\"'\'']//' | tr -d ' ')
  
  # Create secure MySQL config file
  MYSQL_CONFIG=\$(mktemp)
  cat > \"\$MYSQL_CONFIG\" <<EOF
[client]
user=\$DB_USER
password=\$DB_PASS
host=\${DB_HOST:-localhost}
EOF
  
  # Use --defaults-extra-file to avoid exposing credentials
  mysqldump --defaults-extra-file=\"\$MYSQL_CONFIG\" --single-transaction --no-tablespaces '$PROD_DB'
  
  # Clean up
  rm -f \"\$MYSQL_CONFIG\"
" | mysql -u root "$LOCAL_DB"

# 2. Sync uploaded files
echo "🖼️  Syncing files..."
mkdir -p public/system data
rsync -avz --progress --delete "$PROD_USER@$PROD_HOST:$PROD_APP_PATH/public/system/" "./public/system/"
rsync -avz --progress --delete "$PROD_USER@$PROD_HOST:$PROD_APP_PATH/data/" "./data/"

echo "✅ Sync complete!"