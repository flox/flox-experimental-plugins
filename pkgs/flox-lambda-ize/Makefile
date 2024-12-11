ROLE_NAME := lambda-role

.state/role:
	mkdir -p $(@D)
	aws iam create-role --role-name $(ROLE_NAME) --assume-role-policy-document file://./role-policy.json > $@
	aws iam attach-role-policy --role-name $(ROLE_NAME) --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

.state/function: .state/role
	{ \
	aws lambda create-function --function-name bash-runtime \
	--zip-file fileb://function.zip --handler function.handler --runtime provided.al2023 \
	--no-cli-pager \
	--role $$(cat .state/role | jq .Role.Arn -r) > $@ ; \
	}

IMAGE_URI := "140439111649.dkr.ecr.us-east-1.amazonaws.com/bash-runtime:latest"
.state/function: .state/role
	aws lambda create-function \
	--function-name bash-runtime \
	--package-type Image \
	--code ImageUri=${IMAGE_URI} \
	--role $$(cat .state/role | jq .Role.Arn -r) \
	--timeout 3 \
	--memory-size 128 \
	--no-cli-pager > $@

.state/repository:
	aws ecr create-repository --repository-name bash-runtime --no-cli-pager > $@
	#aws ecr set-repository-policy \
	#	--repository-name bash-runtime \
	#	--policy-text file://repo-policy.json \
	#	--no-cli-pager
	# no perms needed?


function.zip: function.sh bootstrap
	zip $@ $^

update: function.zip
	aws lambda update-function-code --function-name bash-runtime \
		--no-cli-pager \
		--image-uri ${IMAGE_URI}
#		--zip-file fileb://function.zip \

run:
	aws lambda invoke --function-name bash-runtime --payload '{"text":"Hello"}' --cli-binary-format raw-in-base64-out response.txt >&2
	cat response.txt

login:
	{ \
	export MYACCOUNT=140439111649 ; \
	export MYREGION="us-east-1" ; \
	export FUNCTIONNAME="bash-runtime" ; \
	aws ecr get-login-password --region $${MYREGION} | \
	docker login --username AWS --password-stdin $${MYACCOUNT}.dkr.ecr.$${MYREGION}.amazonaws.com ; \
	docker build --tag $${MYACCOUNT}.dkr.ecr.$${MYREGION}.amazonaws.com/$${FUNCTIONNAME}:latest . ; \
	docker push $${MYACCOUNT}.dkr.ecr.$${MYREGION}.amazonaws.com/$${FUNCTIONNAME}:latest ; \
	}
build:
	{ \
	export MYACCOUNT=140439111649 ; \
	export MYREGION="us-east-1" ; \
	export FUNCTIONNAME="bash-runtime" ; \
	echo  build --tag $${MYACCOUNT}.dkr.ecr.$${MYREGION}.amazonaws.com/$${FUNCTIONNAME}:latest . ; \
	docker build --tag $${MYACCOUNT}.dkr.ecr.$${MYREGION}.amazonaws.com/$${FUNCTIONNAME}:latest . ; \
	docker push $${MYACCOUNT}.dkr.ecr.$${MYREGION}.amazonaws.com/$${FUNCTIONNAME}:latest ; \
	}

