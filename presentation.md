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

class: impact

.col-6[
# Why?
]

.col-6[
# How?
]

???

- Goal: Help you get started testing your infra


---

class: impact center middle

## Mario Fernandez
 Lead Developer
 
 
 **Thought**Works

---

## .bubble[Nov 17] Tech Radar

--

> Many development teams have adopted *test-driven development* practices for writing application code because of their benefits. 

--

<hr />
> Others have turned to *containers* to package and deploy their software, and it's accepted practice to use automated scripts to build the containers.

--

<hr />
> What we’ve seen few teams do so far is combine the two trends and drive the writing of the container scripts using tests.

---

class: middle center

![tdd](images/tdd.png)

???

- Who claims to do TDD here?
- Who actually _practices_ TDD?

---

class: middle center

![docker](images/docker.png)

---

class: center middle

## Path to Production

---

class: center middle

.image-grid[
.img[![nomad](images/nomad.png)]
.img[![k8s](images/k8s.png)]
.img[![ecs](images/ecs.jpeg)]
.img[![swarm](images/swarm.png)]
]

---

class: transition

# My first experience with Docker

---

class: middle

# Setup
## 8+ years old Ruby monolith

---

class: middle

# Job to be done
## Package the app as a container
## Would run in a VM as a sandbox

---

# How it went

--

.menu[
- .item[Try something]
- .item[Wait 40+ mins]
- .item[Did not work]
- .item[I don't know what I'm doing]
- .item[Despair]
- .item[Consider career choice]
]

---

class: transition

## There has to be a better way

---

class: center middle

## Fast feedback

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

class: impact 

# Let's containerize an app
## Now with a lot less pain

---

class: center

![springboot](images/springboot.jpg)

???

- spring boot application with one route (/greeting), JAR already built

---

## Pic with server and one route

---

class: center middle

![jar](images/jar.png)

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

class: transition

# This is but a start

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




