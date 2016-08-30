# Swarm mode key concept

[원문](https://docs.docker.com/engine/swarm/key-concepts/)

Docker engine 1.12 부터 추가된 클러스터 관리에 관련된 키 컨셉 소개

## Swarm
Docker Engine에 포함된 클러스터 관리및 조율 기능은 **SwarmKit**을 사용해서 구축됨. 클러스터에 참여하는 Engine은 **swarm mode**로 동작. swarm을 자체적으로 만들거나 다른 swam에 join하는 방식으로 Engine을 swarm mode화 함.

**Swarm**이란 서비스를 deploy하는 engine의 클러스터를 지칭. Docker CLI에는 swarm을 관리하는 명령어를 포함하고 있음(추가하거나 삭제하기 같은). 또한 swarm에 서비스를 deploy하거나 서비스 조율을 하는 명령어도 포함.

 swarm모드가 아닌 경우에는 container 명령을 사용하고. swarm 모드에서는 서비스 조율 명령을 사용함

## Node
**Node**는 swarm에 참여하는 엔진의 인스턴스.

swarm에 서비스를 deploy하려면 service 정의를 manager node에 submit.
**manager node**가 task라고 하는 작업 단위를 worker node로 dispatch
정의한 대로 swarm의 상태를 유지하기 위해서 manager node는 클러스터 관리나 조율 기능도 실행
manager node는 조율 task를 위한 싱글 리더를 뽑음

**Work node**는 task를 받아서 실행.
default로는 manager node도 하나의 work node. dedicated하게 manage만 하도록 설정가.
Agent가 현재 task 상황을 manager에게 notify하면 그릴 토대로 manager가 현재 상태를 유지.

## Service 와 Task
**Service**란 work 노드에서 실행될 task를의 정의. swarm 시스템의 중심구조. swarm과의 상호 작용의 루트가 되는 곳.

Service를 생성할 때 어떤 container 이미지를 그 컨테이너 내부에서 어떤 명령을 실행할 지를 지정.

**replicated 서비스** 모델의 경우 원하는 상태에 지정한 scale 수 만큼 manager가 노드들에 replica task를 할당함.

**global 서비스**의 경우 서비스의 하나의 task를 모든 node에서 실행하게 함

**Task**는 Docker container와 그 안에서 실행되는 명령어를 의미. swarm위 최소 스케쥴링 단위. 서비스 scale에 정의된 수만큼 replia 셋의 task 들을 node들에 할당. 한번 node에 할당된 task는 다른 node로 이동은 불가능. 그 node에서 실행되던지 fail할 뿐.

## Load Balancing
swarm은 **ingress load balancing**을 사용해서 외부에 사용할수 있도록 서비스를 노출 시킴.
swarm manager는 서비스에 PublishedPort를 자동할당. 30000-32767사이에 수동 설정도 가능

cloud load balancer 같은 외부 컴포넌트는 그 task를 실행하고 있는지 여부에 상관 없이 어떤 node에 라도 해당 **PublishedPort**에 접근하면 그 service로 접근 가능. swarm 내의 모든 node는 들어 오는 커넥션을 실행중인 task 인스턴스로 route함

Swarm mode는 내부 DNS 컴포넌트를 가지고 있음. 그 swam내의 각 서비스에 고유의 DNS entry를 할당. swarm 메니져는 서비스의 DNS 명 단위로 request를 분산해서 **internal load balancing**을 함.
