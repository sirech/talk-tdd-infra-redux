title: TDD for Containers
class: animation-fade
layout: true

<!-- This slide will serve as the base layout for all your slides -->

---

class: impact

# {{title}}


---

class: impact

.col-6[
## Why?
]

.col-6[
## How?
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

???

- What: Writing tests for your container code

---

class: middle center

![tdd](images/tdd.png)

???

- Who claims to do TDD here?
- Who actually _practices_ TDD?

---

class: middle center

![docker](images/docker.png)

## Containers are everywhere

???

- Many applications nowadays are packaged using containers
- Containers provide a ton of flexibility to package apps and deploy them to any environment, even if you don't control it

---

class: center middle

.image-grid[
.img[![nomad](images/nomad.png)]
.img[![k8s](images/k8s.png)]
.img[![ecs](images/ecs.jpeg)]
.img[![swarm](images/swarm.png)]
]

???

- They are an important component in the path to production

---

class: center middle

## Standard approach is try and see what happens

---

class: center middle

## Which can go badly

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

???

- First step was packaging the app, to run it in the sandbox. Then production would be deployed with this artifact as well
- We didn't really know a lot about Docker in general, let alone best practices

---

# What we did

--

.menu[
- .item[Add stuff to Dockerfile]
- .item[Wait 40+ mins for it to build]
- .item[Test manually]
- .item[Did not work]
- .item[I don't understand why]
- .item[Despair]
- .item[Got to step 1]
]

???

- Jenkins job that built the image
- slow, frustrating
- little insight won

---

# How it went

## Multiple months of work
## Flaky, hard to change
## Path to production didn't even reach production

???

- Afraid to make changes
- led to no improvements over time

---

class: center middle

![fail](images/fail.jpg)

---

class: transition

## There has to be a better way

???

- Didnt know enough about docker to do it differently

---

class: center middle

## Fast feedback and automation are crucial

???

- Just the same as with your regular code
- Containers are becoming first class citizens in our ecosystem

---

class: center middle

## Use the right tools

???

- We have talked about what is TDD for containers, and why it has value. Now we'll get into the how

---

class: center middle

![serverspec](images/serverspec.png)

???

- ServerSpec is a framework based on RSpec
- From the Ruby world


---

class: center middle

## Write RSpec tests for infrastructure

---

class: transition 

# Let's containerize an app
## Now with a lot less pain

???

- I have given this talk before, and focused on what you can do with ServerSpec. This time I want to show you how we could put an application in a container, using TDD

---

class: center middle

.col-6[
.spring[
![springboot](images/springboot.png)
]
]
.col-6[
![java-app](images/java-app.png)
]

???

- spring boot application with one route (/greeting), JAR already built

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

???

- This is ruby code, but it should be easy to follow

---

### OS Version

```ruby
describe file('/etc/alpine-release') do
  its(:content) { is_expected.to match(/3.8.2/) }
end
```

???

- RSpec: Behaviour Driven Development for Ruby.
- This is an actual test that can be run against the container defined in the _Init_

---

### OS Version

```Dockerfile
FROM alpine:3.8
```

???

- Alpine is a great base for a production image

---

### Java Version

```ruby
describe command('java -version') do
  its(:stderr) { is_expected.to match(/1.8.0_181/) }
end
```

???

- Having a test for the version of java means an update is always a conscious decission

---

### Java Version

```Dockerfile
FROM openjdk:8-jre-alpine3.8
```

???

- Still alpine, but based on the official openjdk image

---

### JAR

```ruby
describe file('gs-rest-service.jar') do
  it { is_expected.to be_file }
end
```

???

- jar built in a previous step as part of the pipeline

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

???

- ServerSpec does not only test building the image, but also running it as a container

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

???

- In a multi service architecture, ports can be tricky. So we wanto to make sure we codify the port we run on as a test

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

???

- At this point the image will be running our app just fine. 
- Building a high quality Docker image is more than that. 
- You can codify practices and conventions in your tests so that you make sure the images you build conform to that.

---

### Not running under root

```ruby
describe process('java') do
  its(:user) { is_expected.to eq('runner') }
end
```

???

- It is a good practice to run the command under non-root, and that can be codified in a test

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

???

- This image is simple, but already deployable
- Not very far away from actual images that we deploy to prod

---

```console
rspec spec/container_spec.rb
Randomized with seed 61858
.......

Top 7 slowest examples (12.86 seconds, 99.9% of total time):
  Application Container java listens to correct port should be listening with tcp
    7.82 seconds ./spec/container_spec.rb:20
  Application Container java Process "java" should be running
    4.14 seconds ./spec/container_spec.rb:14
  Application Container java Command "java -version" stderr should match /1.8.0_181/
    0.3948 seconds ./spec/container_spec.rb:10
  Application Container java Process "java" args should contain "gs-rest-service.jar"
    0.15328 seconds ./spec/container_spec.rb:15
  (more output ...)

Finished in 12.87 seconds (files took 1.69 seconds to load)
7 examples, 0 failures
```

???

- how to run it?
- with ruby and docker, it's a matter of executing it
- proves that what I build conforms to the specification I defined

---

# Did the tests pass?

--

## Hell yes!

--

## Cool, let's run them on every commit now

???

- Just running the tests once is useful, but not enough

---

class: full-width
background-image: url(images/pipeline.png)

???

- this is how one of our APIs looks
- based on Concourse, Jenkins or any other CI would work the same way
- no point in deploying to a staging environment if we know the image is not good
- offtopic: Running dind in a pipeline is tricky
- links at the end for examples

---

class: center middle

## Code
### https://github.com/sirech/talk-tdd-infra-redux/tree/master/code

???

- The slides are a bit simplified to fit
- The whole example, including the sample app, can be found under this link

---

class: transition

# This is but a start

???

- Two examples:
 - Current proj: We develop our app and control our infra. These tests enable us to deploy to our test system and prod more confidently
 - Previous proj: Service team building infra for others, including base images. You don't want to deliver broken images to other teams (loss of trust)

---

class: center middle

## This is not a DSL, but regular Ruby code

---

class: center middle

.col-6[
![node](images/node.png)
]
.col-6[
![node-app](images/node-app.png)
]

???

- node app with one route. In this case, there is a dependency, as we want to read a secret
- We assume the first version of the Dockerfile is already there, built using TDD :)

---

class: center middle

![asm](images/asm.jpeg)

???

- Don't put your secrets in the source code, use a proper store
- We are using ASM as our secret store

---

## Access secret

```ruby
describe 'fetches a secret' do
  it { wait_for(secret).to match(/the_secret/) }
end

private

def secret
  command('curl localhost:3000/secret').stdout
end
```

???

- Arbitrary commands can be run in the test

---

## Access secret

```javascript
app.get('/secret', 
  (req, res) => 
    res.send(`The super secret value is ${process.env.SECRET}`))
```

???

- Secret handling transparent to the app

---

## Injected at runtime

```ruby
describe file('/usr/sbin/entrypoint.sh') do
  it { is_expected.to be_file }
end
```

???

- It is a good practice to inject secrets at runtime and not at build time

---

## Injected at runtime


```bash
#!/usr/bin/env bash

set -e

secret=$(
  aws --region "${AWS_REGION}" \
  secretsmanager get-secret-value \
  --secret-id "${SECRET_KEY}" \
  | jq -r .SecretString)
export SECRET="$secret"

exec "$@"
```

???

- This might not be the safest way to inject secrets. Probably something like `pstore` would be better

---

## Injected at runtime

```Dockerfile
FROM node:11.6-alpine

# ... install awscli
# ... node dependencies
# ... copy app

COPY entrypoint.sh /usr/sbin/entrypoint.sh

RUN adduser -D runner

USER runner
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
CMD ["node", "app.js"]
```

???

- no need to modify the app to make it use secrets

---

class: center middle

## How to make the tests run now?

???

- Tests won't run -> no permission to access AWS
- Image will build, but container won't start as it has a dependency

---

class: middle center

.col-6[
![localstack](images/localstack.png)

## Localstack
]

.col-6[
![docker compose](images/docker-compose.png)
]

???

- localstack: mock aws services locally (Tech Radar '19)
- docker compose: orchestrate multiple containers locally

---

## Dependency setup

```yaml
version: '3'
services:
  localstack:
    container_name: localstack
    image: localstack/localstack

    ports:
      - "4584:4584"

    environment:
      - DEFAULT_REGION=eu-central-1
      - SERVICES=secretsmanager
      
  ...
```

???

- my examples are reaching the limit of what can fit in a slide
- standard docker-compose.yml -> can be run locally

---

## Dependency setup

```yaml
  app:
    container_name: app
    build: ./app

    ports:
      - "3000:3000"

    env_file: .env

    links:
      - localstack
```

???

- missing: how to put the secret into localstack
- missing: adapting urls

---

## Dependency setup

```ruby
require 'docker/compose'
set :docker_container, 'app'

RSpec.configure do |config|
  compose = Docker::Compose.new

  config.before(:all) { compose.up(detached: true, build: true) }

  config.after(:all) do
    compose.kill
    compose.rm(force: true)
  end
end
```

---

## That's a lot of *TDD*

```console
  Container File "/usr/sbin/entrypoint.sh" should be file
    1.28 seconds ./spec/container_spec.rb:29
  Container fetches a secret from ASM should match /localstack_secret/
    0.13081 seconds ./spec/container_spec.rb:33

2 examples, 0 failures
```

???

- caveat: This a unit test using mocks
- not tested: do we have access to ASM, is the secret there
- which is ok -> different levels of abstraction

---

class: center middle

## Code
### https://github.com/sirech/example-serverspec-aws

---

class: transition

# Are you convinced now?

???

- I do hope so, because I'm out of slides

---

# Summary

## What: Driving writing container code with tests
## Why: Ensure you build high quality images, automate it, fast feedback loop
## How: Leverage ServerSpec

???

- ServerSpec is not the only alternative. Goss is another option

---

# Links

- _ServerSpec_ resource types: https://serverspec.org/resource_types.html
- https://www.thoughtworks.com/insights/blog/modernizing-your-build-pipelines
- Integrate _ServerSpec_ in _Concourse_: https://github.com/sirech/example-concourse-pipeline
- Container example: https://github.com/sirech/talk-tdd-infra-redux/tree/master/code
- Dependencies example: https://github.com/sirech/example-serverspec-aws

---




