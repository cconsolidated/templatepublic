#!/bin/sh
set -e

# Debug: Print all environment variables
echo "Environment variables:"
env | sort

# Required ENV variables:
# SUPABASE_URL - the Supabase project URL
# SUPABASE_SERVICE_KEY - the Supabase service key
# PROJECT_ID - the project ID to fetch
# VERSION_ID - the version ID to fetch from current_versions
# GIT_REPO_URL - (optional) git repo to clone
# S3_BUCKET_NAME - the S3 bucket name

if [ -z "$SUPABASE_URL" ] && [ -n "$NEXT_PUBLIC_SUPABASE_URL" ]; then
  export SUPABASE_URL="$NEXT_PUBLIC_SUPABASE_URL"
fi

# Clone the git repo using the SSH key, if provided
if [ -z "$GIT_REPO_URL" ]; then
  echo "No GIT_REPO_URL provided, using default template repo."
  git clone "git@github.com:cconsolidated/templatepublic.git" /app/repo
else
  git clone "$GIT_REPO_URL" /app/repo
fi

# Query Supabase for the project's code for the given version
if [ -z "$PROJECT_ID" ] || [ -z "$VERSION_ID" ]; then
  echo "PROJECT_ID and VERSION_ID must be set."
  echo "PROJECT_ID: $PROJECT_ID"
  echo "VERSION_ID: $VERSION_ID"
  exit 1
fi

echo "Fetching project code from Supabase for project $PROJECT_ID, version $VERSION_ID..."
RESPONSE=$(curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  "$SUPABASE_URL/rest/v1/code?project_id=eq.$PROJECT_ID&version=eq.$VERSION_ID&select=content")

echo "Raw response: $RESPONSE"

# Check if response is valid JSON and has data
if ! echo "$RESPONSE" | jq empty 2>/dev/null; then
  echo "Error: Invalid JSON response from Supabase"
  echo "Response: $RESPONSE"
  exit 1
fi

# Extract the content
PROJECT_FILES=$(echo "$RESPONSE" | jq -r ".[0].content")
if [ -z "$PROJECT_FILES" ] || [ "$PROJECT_FILES" = "null" ]; then
  echo "Error: No project files found for project $PROJECT_ID, version $VERSION_ID"
  echo "Response: $RESPONSE"
  exit 1
fi

echo "Project files: $PROJECT_FILES"

# Write the files to the repo
if [ -d /app/repo ]; then
  echo "Writing project files..."
  echo "$PROJECT_FILES" | jq -c '.[]' | while read -r fileobj; do
    file=$(echo "$fileobj" | jq -r '.path')
    content=$(echo "$fileobj" | jq -r '.content')
    if [ -n "$file" ] && [ -n "$content" ]; then
      dir=$(dirname "/app/repo$file")
      mkdir -p "$dir"
      echo "$content" > "/app/repo$file"
      echo "Wrote to /app/repo$file"
    fi
  done
else
  echo "No /app/repo directory, skipping code injection."
fi

# Build the project if repo exists
if [ -d /app/repo ]; then
  echo "Building project..."
  cd /app/repo
  
  # Install dependencies
  echo "Installing dependencies..."
  npm install
  
  # Build the project
  echo "Running build..."
  npm run build
  
  # Verify build output
  if [ ! -d "build/client" ] || [ ! -d "build/server" ]; then
    echo "Error: Build output directories 'build/client' and/or 'build/server' not found"
    exit 1
  fi
  
  # Create project directories in S3 before syncing
  echo "Creating project directories in S3..."
  aws s3api put-object --bucket $S3_BUCKET_NAME --key "$PROJECT_ID/client/"
  aws s3api put-object --bucket $S3_BUCKET_NAME --key "$PROJECT_ID/server/"
  
  # Configure S3 bucket for private access
  echo "Configuring S3 bucket for private access..."
  aws s3api put-public-access-block \
    --bucket $S3_BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  
  # Create Origin Access Identity for CloudFront
  echo "Creating CloudFront Origin Access Identity..."
  OAI_RESPONSE=$(aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config \
    "CallerReference=$(date +%s),Comment=OAI for $PROJECT_ID")
  
  OAI_ID=$(echo "$OAI_RESPONSE" | jq -r '.CloudFrontOriginAccessIdentity.Id')
  
  # Add bucket policy for CloudFront access only
  echo "Adding bucket policy for CloudFront access..."
  aws s3api put-bucket-policy \
    --bucket $S3_BUCKET_NAME \
    --policy "{
      \"Version\": \"2012-10-17\",
      \"Statement\": [
        {
          \"Sid\": \"AllowCloudFrontServicePrincipal\",
          \"Effect\": \"Allow\",
          \"Principal\": {
            \"Service\": \"cloudfront.amazonaws.com\"
          },
          \"Action\": \"s3:GetObject\",
          \"Resource\": \"arn:aws:s3:::$S3_BUCKET_NAME/*\",
          \"Condition\": {
            \"StringEquals\": {
              \"AWS:SourceArn\": \"arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/*\"
            }
          }
        }
      ]
    }"
  
  # Upload the built files to S3
  echo "Uploading client files to S3..."
  aws s3 sync ./build/client s3://$S3_BUCKET_NAME/$PROJECT_ID/client/
  
  echo "Uploading server files to S3..."
  aws s3 sync ./build/server s3://$S3_BUCKET_NAME/$PROJECT_ID/server/
else
  echo "No /app/repo directory, skipping build and deploy."
fi

echo "Checking for deployed_url in Supabase..."
PROJECT_JSON=$(curl -s -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  "$SUPABASE_URL/rest/v1/projects?id=eq.$PROJECT_ID&select=deployed_url")

DEPLOYED_URL=$(echo "$PROJECT_JSON" | jq -r '.[0].deployed_url')

if [ "$DEPLOYED_URL" = "null" ] || [ -z "$DEPLOYED_URL" ]; then
  echo "No deployed_url found. Creating new CloudFront distribution..."

  # Write distribution-config.json
  cat > /tmp/distribution-config.json <<EOF
{
  "CallerReference": "deploy-$(date +%s)",
  "Comment": "Public distribution for project $PROJECT_ID",
  "Enabled": true,
  "Origins": {
    "Quantity": 2,
    "Items": [
      {
        "Id": "S3-Client-$S3_BUCKET_NAME",
        "DomainName": "$S3_BUCKET_NAME.s3.amazonaws.com",
        "OriginPath": "/$PROJECT_ID/client",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      },
      {
        "Id": "S3-Server-$S3_BUCKET_NAME",
        "DomainName": "$S3_BUCKET_NAME.s3.amazonaws.com",
        "OriginPath": "/$PROJECT_ID/server",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-Client-$S3_BUCKET_NAME",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["HEAD", "GET"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["HEAD", "GET"]
      }
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": { "Forward": "none" }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true
  },
  "CacheBehaviors": {
    "Quantity": 1,
    "Items": [
      {
        "PathPattern": "/api/*",
        "TargetOriginId": "S3-Server-$S3_BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
          "Quantity": 3,
          "Items": ["HEAD", "GET", "OPTIONS"],
          "CachedMethods": {
            "Quantity": 2,
            "Items": ["HEAD", "GET"]
          }
        },
        "ForwardedValues": {
          "QueryString": true,
          "Cookies": { "Forward": "all" },
          "Headers": ["*"]
        },
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 0,
        "Compress": true
      }
    ]
  },
  "DefaultRootObject": "index.html",
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": 200,
        "ErrorCachingMinTTL": 0
      }
    ]
  }
}
EOF

  CLOUDFRONT_JSON=$(aws cloudfront create-distribution \
    --distribution-config file:///tmp/distribution-config.json \
    --region us-east-1)

  CLOUDFRONT_URL=$(echo "$CLOUDFRONT_JSON" | jq -r '.Distribution.DomainName')

  # Update Supabase project with deployed_url
  curl -X PATCH "$SUPABASE_URL/rest/v1/projects?id=eq.$PROJECT_ID" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"deployed_url\": \"https://$CLOUDFRONT_URL\"}"

  echo "Set deployed_url to https://$CLOUDFRONT_URL"
else
  echo "Project already has a deployed_url: $DEPLOYED_URL"
  echo "Skipping CloudFront distribution creation. Content has been updated in S3."
fi

echo "Deployment complete!" 