---
layout: post
title:  "Docker swarm mode Totorial 간략 번역"
date:   2016-08-28 23:15:41 +0900
categories: docker "docker swarm mode"
---
# Swam mode Tutorial
[원문: https://docs.docker.com/engine/swarm/swarm-tutorial/](https://docs.docker.com/engine/swarm/swarm-tutorial/)

Docker Engine의 Swarm mode 튜토리얼
Key concept 미리 읽어 두는 것이 좋음

튜토리얼 내용

- Swarm mode 로 Docker Engine의 클러스터 초기화
- swam에 node 추가
- swarm에 어플리케이션 service 디플로이
- 모든 것인 동작중인 상태 swarm 관리

튜토리얼에서는 터미널 윈도우에서 Docker Engine CLI 사용. 머신에 Docker 를 인스톨해서 셀 상에서 실행하는 것에 익숙한 레벨이어야 함.

Docker에 대해서 익숙하지 않다면 Docker Engine 에 대한 선행 학습 필요.

## 준비

준비물

- 3 대의 네트웍에 연결된 호스트
- 각각 1.12 이상의 Docker Engine이 설치된 상태
- Manager machine의 IP
- 호스트들의 간의 포트가 접근 가능한 상태

### 3 대의 네트웍에 연결된 호스트
swarm의 node로서 3대를 준비. PC,  데이터 센터, 클라우스 서비스 상의 virtual pc도 가능. 아래의 머신명으로 가정.
- manager1
- worker1
- worker2

### Docker Engine 1.12 이상
swarm mode를 사용하려면 각 머신에 Docker Engine을 설치해야 함. Docker for Mac, Docker for Windows OK.

> Docker for Mac, Docker for Windows에서는 single-node 만 가능 가능. Swarm을 만들어서 하나의 Service 만 실행가능. 추가적으로 node를 추가하거나 scaling 은 불가능.

각 머신에 Docker engine을 실행중 상태로 둠

###  Manager machine의 IP
모든 host 머신에 접속가능한 네트워크 인터페이스의 IP. 이 IP를 통해서 모든 node가 manager에 접근가능해야 함.
고정 아이피이어야 함.
이 튜터리얼에서는 manger1: 192.168.99.100

### 호스트들간의 오픈 된 포트
TCP 2377: cluster 관리 커뮤니케이션용
TCP and UDP 7946: node들간 상호 커뮤니케이션용
TCP and UDP 4789: 오버레이 네트워크 트레픽용

## Swarm 생성
setup이 완료 되었다면 swarm을 생성할 준비가 된 것임. Docker Engine이 실행중인 상태인지 확인.

1. manager node 머신에  ssh 접속. 이 튜토리얼에서는 manager1.
2. 아래의 명령어로 swarm 생성

     ``` 
    docker swarm init --advertise-addr <MANAGER-IP>
     ```
    이 튜토리얼에서는 아래와 같이 manager1에서 swarm 생성

    ```
    $ docker swarm init --advertise-addr 192.168.99.100
    Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.
    
    To add a worker to this swarm, run the following command:
    
    docker swarm join \
    --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
    192.168.99.100:2377
    
    To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
     ```

    `—advertise-addr` 를 사용해서 192.168.99.100로 접근하라고 알림. 다른 node들은 이 IP로 manager에 접근할 수 있어야 함. 실행 결과로 출력된 내용에 새로운 node를 이 swarm에 참가할 수 있는 명령어가 표시됨. node는 —token의 값에 따라서 worker 또는 manager로써 join함.
3. `docker info` 로 현재 swarm 상태 확인
    ````
    $ docker info
    
    Containers: 2
    Running: 0
    Paused: 0
    Stopped: 2
      ...snip...
    Swarm: active
      NodeID: dxn1zf6l61qsb1josjja83ngz
      Is Manager: true
      Managers: 1
      Nodes: 1
      ...snip...
    ````
4. `docker node ls`로 nodes들의 상태 확인
    ````
    $ docker node ls
    
    ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
    dxn1zf6l61qsb1josjja83ngz *  manager1  Ready   Active        Leader
    ````
ID 뒤의 * 마크가 현재 접속중임을 의미
Docker engine swarm mode는 machine의 host name으로 node명을 자동으로 정함. 나머지 column에 대해서는 뒤에 다룸

## swarm에 노드 추가하기
manager node과 함께 swarm을 생성했다면 이제 work node를 추가할 수 있음.

1. 터미널을 열고 worker node로 동작시키고 싶은 machine으로 ssh. 이 튜토리얼에서는 worker1.
2. swarm 생성시 `docker swarm init` 결과에 표시 되었던 명령어를 사용해서 worker node를 swarm에 추가 시킴.
    ```
    $ docker swarm join \
      --token  SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
      192.168.99.100:2377

    This node joined a swarm as a worker.
    ```
    명령어를 다시 보고 싶으면 아래와 같이 manager node에서 실행해서 확인 가능

     ```
    $ docker swarm join-token worker

    To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
    192.168.99.100:2377 
     ```
3. 다시 terminal로 이번에는 두번째 worker node로 ssh 접속. 이 튜토리얼에서는 worker2
4. 앞의 같은 명령어로 swarm에 두번째 worker node를 생성
    ```
    $ docker swarm join \
      --token  SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
      192.168.99.100:2377

    This node joined a swarm as a worker.
    ```
5. terminal에서 다시 manager node로 ssh 접속. `docker node ls`로 worker node 확인
    ```
     ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
    03g1y59jwfg7cf99w4lt0f662    worker2   Ready   Active
    9j68exjopxe7wfl6yuxml7a7j    worker1   Ready   Active
    dxn1zf6l61qsb1josjja83ngz *  manager1  Ready   Active        Leader
    ```
`MANAGER` 컬럼이 swarm의 manager임을 나타냄. 아무 것도 없는 worker1, worker2가 worker node임을 의미. swarm 관리 명령어는 manager node 들에서만 실행 가능.
