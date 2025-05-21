.PHONY: build cluster register run network clean deploy-all

network:
	bash deploy/create-vpc-and-subnet.sh

build:
	bash deploy/build-and-push-ecr.sh

cluster:
	bash deploy/create-cluster.sh

register:
	bash deploy/register-task.sh

run:
	bash deploy/run-service.sh

ip:
	bash deploy/get-task-ip.sh

clean:
	rm -f .env


destroy:
	bash deploy/destroy-ecs-service.sh

deploy-all: network build cluster register run ip
	@echo "Flask API deployed successfully!"
	@echo "Access the application at: http://$(shell cat .env | grep FLASK_API_URL | cut -d '=' -f2)"
	@echo "Remember to clean up resources after use."