FROM lambci/lambda:build-python3.7

COPY . .

RUN npm install

# Assumes you have a .lambdaignore file with a list of files you don't want in your zip
RUN cat .lambdaignore | xargs zip -9qyr lambda.zip . -x
