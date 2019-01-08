title: TDD for Containers
class: animation-fade
layout: true

<!-- This slide will serve as the base layout for all your slides -->
.bottom-bar[
  {{title}}
]

---

class: impact

# {{title}}

---

## Mario Fernandez
### Lead Developer
### ThoughtWorks

---

class: center middle

## Path to production

---

class: center middle

.image-grid[
.img[![nomad](images/nomad.png)]
.img[![k8s](images/k8s.png)]
.img[![ecs](images/ecs.jpeg)]
.img[![swarm](images/swarm.png)]
]

---

# Let's containerize an app
## Based on a real experience

---

# Build app
## Wholly unprepared to run inside a container

---

class: center middle

## Barely understand Docker

---

class: center middle

## Vomit stuff on Dockerfile

---

class: center middle

## Wait 40+ mins for image to be built

---

class: center middle

## Does not work

---

class: center middle

## Despair

---

class: center middle

## Consider career choices

---

class: center middle

## Repeat

---

class: center middle

## There has to be a better way

---

class: center middle

## Use the right tools

---

class: center middle

![serverspec](images/serverspec.png)

---

class: center middle

## Write RSpec tests for infrastructure

---

# Let's containerize an app
## Now with a lot less pain

---

spring boot application with one route (/greeting), JAR already built

---

### Init

```ruby
require 'serverspec'
require 'docker'
require 'rspec/wait'

set :backend, :docker
set :docker_image, 'example-openjdk'

RSpec.configure do |config|
  config.wait_timeout = 60 # seconds
end
```

---

### OS Version

```ruby
describe file('/etc/alpine-release') do
  its(:content) { is_expected.to match(/3.8.2/) }
end
```

---

### OS Version

```Dockerfile
FROM alpine:3.8
```

---

### Java Version

```ruby
describe command('java -version') do
  its(:stderr) { is_expected.to match(/1.8.0_181/) }
end
```

---

### Java Version

```Dockerfile
FROM openjdk:8-jre-alpine3.8
```

---

### JAR

```ruby
describe file('gs-rest-service.jar') do
  it { is_expected.to be_file }
end
```

---

### JAR

```Dockerfile
FROM openjdk:8-jre-alpine3.8

WORKDIR /app
ENV VERSION="0.1.0"

COPY build/libs/gs-rest-service-${VERSION}.jar .
```

---

### App is running

```ruby
describe process('java') do
  it { is_expected.to be_running }
  its(:args) { is_expected.to contain('gs-rest-service.jar') }
end
```

---

### App is running

```Dockerfile
FROM openjdk:8-jre-alpine3.8

WORKDIR /app
ENV VERSION="0.1.0"

COPY build/libs/gs-rest-service-${VERSION}.jar gs-rest-service.jar

CMD ["java", "-jar", "gs-rest-service.jar"]
```

---

### Bound to right port

```ruby
describe 'listens to correct port' do
  it { wait_for(port(8080)).to be_listening.with('tcp') }
end
```

---

### Bound to right port

```Dockerfile
FROM openjdk:8-jre-alpine3.8

WORKDIR /app
EXPOSE 8080
ENV VERSION="0.1.0"

COPY build/libs/gs-rest-service-${VERSION}.jar gs-rest-service.jar

CMD ["java", "-jar", "gs-rest-service.jar"]
```

---

### Not running under root

```ruby
describe process('java') do
  its(:user) { is_expected.to eq('runner') }
end
```

---

### Not running under root

```Dockerfile
FROM openjdk:8-jre-alpine3.8

WORKDIR /app
EXPOSE 8080
ENV VERSION="0.1.0"

COPY build/libs/gs-rest-service-${VERSION}.jar gs-rest-service.jar

RUN adduser -D runner

USER runner
CMD ["java", "-jar", "gs-rest-service.jar"]
```

---

# Did the tests pass?

--

## Hell, yes!

--

## Cool, let's run them on every commit now

---

class: full-width
background-image: url(images/pipeline.png)

---

# What else?

---

Running healthcheck

---

Scenario: Container with dependencies

---

entrypoint with aws

---

docker compose with localstack

---

run docker compose 

---

# Links

- _ServerSpec_ resource types: https://serverspec.org/resource_types.html
- https://www.thoughtworks.com/insights/blog/modernizing-your-build-pipelines
- Integrate _ServerSpec_ in _Concourse_: https://github.com/sirech/example-concourse-pipeline
- Code for the example: https://github.com/sirech/talk-tdd-infra-redux/tree/master/code



