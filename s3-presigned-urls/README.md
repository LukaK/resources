# S3 Presigned Urls
Code example of the blog post found [here](https://www.itguyjournals.com/s3-tiered-access-with-presigned-urls/).

Tools and technologies:
- s3
- lambda
- api gateway
- cognito
- aws sam
- aws cli
- bash


Requirements:
- aws account and user with programmatic access
- aws cli
- aws sam
- working email account
- curl


#### Architecture
<p align="center"><img width="50%" src="./assets/s3-pre-signed-url.png" title="Fig 1. S3 presigned url architecture" /></p>
<p align="center">Fig 1. S3 presigned url architecture</p>

Project implements api gateway with cognito authorizer.
Two users are created in cognito to demonstrate tiered access to the s3 resources.
Api gateway implements endpoint with lambda integration, for issuing s3 presigned urls with different permissions.



#### Deploying The Stack

User emails have to be valid emails. You can use mail aliases to make things easyer.
```bash
# set your email here
COGNITO_USER_ONE_EMAIL="me+user1@example.com"
COGNITO_USER_TWO_EMAIL="me+user2@example.com"
STACK_NAME="s3-pre-signed-urls"

# deploy the stack
sam deploy \
--parameter-overrides CognitoUserOneEmail=$COGNITO_USER_ONE_EMAIL  CognitoUserTwoEmail=$COGNITO_USER_TWO_EMAIL \
--capabilities CAPABILITY_IAM \
--stack-name $STACK_NAME \
-t template.sam.yaml

# get infrastructure information from the stack
STACK_OUTPUTS=$(sam list stack-outputs --stack-name $STACK_NAME --output json)
USER_POOL_CLIENT_ID=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "CognitoUserPoolClientId")) | .[0].OutputValue')
USER_POOL_ID=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "UserPoolId")) | .[0].OutputValue')
API_URL=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "MyApiUrl")) | .[0].OutputValue')
BUCKET_NAME=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "BucketName")) | .[0].OutputValue')
```

#### Copy Assets To The S3 Bucket
```bash
# copy data
aws s3 cp assets/cute-cat.jpg "s3://$BUCKET_NAME/tier 1/"
aws s3 cp assets/super-cute-cat.jpg "s3://$BUCKET_NAME/tier 2/"
```

#### Get Auth Token

In your email you will receive temporary password. Set it in the code below.
```bash
# set your temporary password here
EMAIL=$COGNITO_USER_ONE_EMAIL
TMP_PASSWORD=""
NEW_PASSWORD="Supersecretpassword12+"

# retrieve session information
SESSION=$(aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH \
--auth-parameters "USERNAME=$EMAIL,PASSWORD=$TMP_PASSWORD" \
--client-id $USER_POOL_CLIENT_ID \
--query "Session" --output text)

# get token id
TOKEN_ID=$(aws cognito-idp admin-respond-to-auth-challenge \
--user-pool-id $USER_POOL_ID \
--client-id $USER_POOL_CLIENT_ID \
--challenge-responses "USERNAME=$EMAIL,NEW_PASSWORD=$NEW_PASSWORD" \
--challenge-name NEW_PASSWORD_REQUIRED \
--session $SESSION \
--query 'AuthenticationResult.IdToken' --output text)
```

#### Retrieve Assets With S3 Self Signed Urls
```bash
# send token as part of the Authorization header when requesting resources.
curl -G -H "Authorization: Bearer $TOKEN_ID" --data-urlencode "key=tier 1/cute-cat.jpg" "$API_URL/presignedurl"

TIER1_GET_URL=$(curl -G -H "Authorization: Bearer $TOKEN_ID" --data-urlencode "key=tier 1/cute-cat.jpg" "$API_URL/presignedurl" | jq -r '.url')
curl -G -L --output cute-cat.jpg $TIER1_GET_URL

curl -G -H "Authorization: Bearer $TOKEN_ID" --data-urlencode "key=tier 2/super-cute-cat.jpg" "$API_URL/presignedurl"

# if authorized download the image
TIER2_GET_URL=$(curl -G -H "Authorization: Bearer $TOKEN_ID" --data-urlencode "key=tier 2/super-cute-cat.jpg" "$API_URL/presignedurl" | jq -r '.url')
curl -G -L --output super-cute-cat.jpg $TIER2_GET_URL
```
#### Cleanup
```bash
# delete files in s3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive

# delete the stack
sam delete --stack-name $STACK_NAME
```
