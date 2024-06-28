# Api gateway with cognito auth flow

Template deploys api gateway with lambda integration and cognito authorization.
Default user is created with the template and requires additional configuration.


## Deploying Infrastructure
```bash
# set your email here
COGNITO_USER_EMAIL="me@example.com"
STACK_NAME="api-gw-with-cognito"

# deploy the stack
sam deploy \
--parameter-overrides CognitoUserEmail=$COGNITO_USER_EMAIL  \
--capabilities CAPABILITY_IAM \
--stack-name $STACK_NAME \
-t template.sam.yaml
```
```bash
# get infrastructure information from the stack
STACK_OUTPUTS=$(sam list stack-outputs --stack-name $STACK_NAME --output json)
USER_POOL_CLIENT_ID=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "CognitoUserPoolClientId")) | .[0].OutputValue')
USER_POOL_ID=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "UserPoolId")) | .[0].OutputValue')
API_URL=$(echo $STACK_OUTPUTS | jq -r 'map(select(.OutputKey == "MyApiUrl")) | .[0].OutputValue')
```

## Retrieving Auth Token Id

Check your email for temporary password and set it in the code below.
```bash
# set your temporary password here
TMP_PASSWORD=""
NEW_PASSWORD="Supersecretpassword12+"

# retrieve session information
SESSION=$(aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH \
--auth-parameters "USERNAME=$COGNITO_USER_EMAIL,PASSWORD=$TMP_PASSWORD" \
--client-id $USER_POOL_CLIENT_ID \
--query "Session" --output text)

TOKEN_ID=$(aws cognito-idp admin-respond-to-auth-challenge \
--user-pool-id $USER_POOL_ID \
--client-id $USER_POOL_CLIENT_ID \
--challenge-responses "USERNAME=$COGNITO_USER_EMAIL,NEW_PASSWORD=$NEW_PASSWORD" \
--challenge-name NEW_PASSWORD_REQUIRED \
--session $SESSION \
--query 'AuthenticationResult.IdToken' --output text)
```

## Testing Lambda Integration
```bash
# send token as part of the Authorization header when requesting resources.
curl -G -H "Authorization: Bearer $TOKEN_ID" $API_URL
```
## Cleanup
```bash
# delete the stack
sam delete --stack-name $STACK_NAME
```
