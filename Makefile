
build: clean
	docker build . --progress=plain -t decknroll/json2env:build

show-test: clean show-test-run clean

show-test-run:
	cd test && docker-compose -f docker-compose.test.yaml up --abort-on-container-exit

test: FORCE docker-run-test
	cd test && docker-compose -f docker-compose.test.yaml run --rm sut

docker-run-test:
	echo '{"docker-run-test":"success"}' | docker run -i decknroll/json2env:build

FORCE:
	# https://www.gnu.org/software/make/manual/html_node/Force-Targets.html

push:
	docker tag decknroll/json2env:build decknroll/json2env:latest
	docker push decknroll/json2env:latest

clean:
	docker image rm decknroll/json2env:build --force || true
	docker image rm decknroll/json2env:test --force || true
	cd test && docker-compose -f docker-compose.test.yaml down --rmi all

build-test-push: build test push
