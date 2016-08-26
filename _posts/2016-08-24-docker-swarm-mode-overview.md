---
layout: post
title:  "Docker swarm mode overview 간략 번역"
date:   2016-08-24 14:40:41 +0900
categories: docker "docker swarm mode"
---
# Docker Swarm mode overview
https://docs.docker.com/engine/swarm/

- Docker engine v1.12.0 이상
- swarm: docker engine의 클러스터
- swarm-mode: docker engine가 swarm으로 동작하도록 하는 모드를 engine에 native로 탑재하고 있음

1.12 이전: Docker Swarm (비슷한 이름에 다른 …)

## 주요 기능

- 클러스터 기능이 docker 자체에: 외부 툴 없이 Docker engine CLI만으로 docker engine들의 swarm 관리
- 비 중앙 관리: 노드들의 역할을 deploy시에 헨들X. 런타임 시에 각 역할을 핸들. 모든 종류의 노드들, 메니저, 워커를 deploy할 수 있다는 것은, 하나의 이미지로 전체 swarm을 빌드 할 수 있음을 의미
- 선언적 서비스 모델: 어플리케이션 스텍의 각 서비스들의 원하는 상태를 정의할 수 있도록 선언적 접근 방법을 사용
- 스케일링: 각 서비스들에 실행할 수를 선언할 수 있음. 스케일 업/다운 시키면 swarm manager가 자동으로 상태를 유지하기 위해 task를 늘리거나 줄입니다.
- 원하는 상태로 조정: swarm manager node는 지속적으로 클러스터 상태를 모니터링해서 원하는 상태와 실제상태를 조정합니다. 10 replica를 container로 실행되도록 service를 설정한 상태에서 2개의 container를 가진 worker 머신이 crash를 했다면 manager는 이를 대신하기 위해서 새롭게 2개의 replica를 생성하고 동작중인 worker에 할당함.
- 멀티 호스트 네트워크: 서비스들을 위한 오버레이 네트워크를 정의. 어플리케이션을 생성하거나 업뎃할 때 swarm manager가 자동으로 container들에서 이 이버레이 네트워크상의 주소를 할당.
- service discovery: swarm manager node는 각 서비스에 고유의 dns를 할당하고 실행하는 container들의 load balancing을 실행. 이 내장 DNS를 통해서 swarm에서 동작중인 모든 container를 query가능.
- 로드 밸런싱: 서비스들의 포트를 외부 로드 밸런서에 노출할 수 있음. 내부적으로는 서비스 container들을 각 node들에 어떻게 분배할 지 지정할 수 있음
- 보안: swarm 내의 모든 노드는 강제적으로 TSL 상호 인증과 암호화를 상용하도록 되어 있음. 자세 서명 root 인증서나 커스텀 root CA의 인증서를 사용하는 option도 있음
- 롤링 업데이트: 롤 아웃 시에 점진적으로 서비스 업데이트를 node에 적용할 수 있음. swarm manager 통해서 각 node 세트에 서비스 deploy의 delay를 제어할 수 있음. 도중에 뭔가 문제가 발생하면 이전 버젼의 서비스로 task 롤백이 가능.

## swarm command들

- swarm init
- swarm join
- service create
- service inspect
- service ls
- service rm
- service scale
- service ps
- service update
