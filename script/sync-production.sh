#!/bin/bash
# Simple production sync script
set -e

# Safe .env file loading
load_env() {
    if [ -f ".env" ]; then
        echo "Loading .env file..."
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue

            # Validate line format (KEY=VALUE)
            if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
                export "$line"
            else
                echo "Warning: Skipping invalid line in .env: $line" >&2
            fi
        done < ".env"
    fi
}

# Validate required environment variables
validate_env() {
    local required_vars=("PROD_HOST" "PROD_USER")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" || "${!var}" == *"your-"* ]]; then
            echo "Error: $var must be set and cannot contain placeholder values" >&2
            echo "Please set $var in .env file or environment" >&2
            exit 1
        fi

        # Basic validation for hostname/username
        if [[ "$var" == "PROD_HOST" && ! "${!var}" =~ ^[a-zA-Z0-9.-]+$ ]]; then
            echo "Error: Invalid hostname format for $var" >&2
            exit 1
        fi
        if [[ "$var" == "PROD_USER" && ! "${!var}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "Error: Invalid username format for $var" >&2
            exit 1
        fi
    done
}

load_env

# Configuration with defaults
PROD_HOST="${PROD_HOST:-your-vps-hostname}"
PROD_USER="${PROD_USER:-deploy}"
PROD_DB="${PROD_DB:-blackbook_production}"
LOCAL_DB="${LOCAL_DB:-blackbook_dev}"
PROD_APP_PATH="${PROD_APP_PATH:-/var/www/blackbook}"

echo "🚀 Syncing production data..."
echo "Production: $PROD_USER@$PROD_HOST"
echo ""
echo "To skip database sync: SKIP_DATABASE=1"
echo "To skip files sync: SKIP_FILES=1"
echo ""

# 1. Sync database
if [[ -z "$SKIP_DATABASE" ]]; then
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
else
  echo "⏭️  Skipping database sync (SKIP_DATABASE=1)"
fi

# 2. Sync uploaded files
if [[ -z "$SKIP_FILES" ]]; then
  echo "🖼️  Syncing files..."
  mkdir -p public/system data

  echo "Syncing images..."
  rsync -avz --progress --delete "$PROD_USER@$PROD_HOST:$PROD_APP_PATH/public/system/" "./public/system/"
  echo "✅ Images sync complete!"

  echo "Syncing GML data..."
  rsync -avz --progress --delete "$PROD_USER@$PROD_HOST:$PROD_APP_PATH/data/" "./data/"
  echo "✅ GML data sync complete!"
else
  echo "⏭️  Skipping files sync (SKIP_FILES=1)"
fi

echo "✅ Sync complete!"