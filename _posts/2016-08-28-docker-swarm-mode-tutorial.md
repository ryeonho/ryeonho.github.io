---
layout: post
title:  "Docker swarm mode Tutorial 간략 번역"
date:   2016-08-28 23:15:41 +0900
categories: docker
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

- TCP 2377: cluster 관리 커뮤니케이션용
- TCP and UDP 7946: node들간 상호 커뮤니케이션용
- TCP and UDP 4789: 오버레이 네트워크 트레픽용

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

## swarm에 Service 디플로이
swarm이 준비되었다면 이제 Service를 그 swarm에 디플로이 할 수 있음. 여기서는 worker node도 추가했었지만 Service를 deploy하는데 필수는 아님.

1. 터미널 창을 열고 manager node가 있는 머신으로 ssh 접속. 이 튜토리얼에서는 manager1
2. 아래의 명령 실행

   ```
   $ docker service create --replicas 1 --name helloworld alpine ping docker.com

   9uk4639qpg7npwf3fn2aasksr
   ```

   - `docker service create` 가 Service 생성 명령.
   - `—name`이 Service명 `helloworld`
   - `—replicas` 1개의 인스턴스를 요구
   - `alpine ping docker.com` 인자가 Alpine 리눅스를 컨테이너에서 `ping docker.com`을 실행하는 서비스를 정의

3. `docker service ls` 명령으로 실행중 서비스 확인

   ```
   $ docker service ls

   ID            NAME        SCALE  IMAGE   COMMAND
   9uk4639qpg7n  helloworld  1/1    alpine  ping docker.com
   ```

## Service inspect하기
Docker CLI를 이용해서 swarm에 실행중인 service의 상태를 확인 할 수 있음.

1. manager node로 ssh로그인.
2. `docker service inspect --pretty <SERVICE-ID>`를 실행해서 service의 상태를 읽기 쉽게 표시. helloworld의 경우.

   ```
   $ docker service inspect --pretty helloworld

   ID:     9uk4639qpg7npwf3fn2aasksr
   Name:       helloworld
   Mode:       REPLICATED
    Replicas:      1
   Placement:
   UpdateConfig:
    Parallelism:   1
   ContainerSpec:
    Image:     alpine
    Args:  ping docker.com
   ```

   > json format으로 출력하려면 —pretty 옵션을 붙이지 않음

   ```
   $ docker service inspect helloworld
   [
   {
       "ID": "9uk4639qpg7npwf3fn2aasksr",
       "Version": {
           "Index": 418
       },
       "CreatedAt": "2016-06-16T21:57:11.622222327Z",
       "UpdatedAt": "2016-06-16T21:57:11.622222327Z",
       "Spec": {
           "Name": "helloworld",
           "TaskTemplate": {
               "ContainerSpec": {
                   "Image": "alpine",
                   "Args": [
                       "ping",
                       "docker.com"
                   ]
               },
               "Resources": {
                   "Limits": {},
                   "Reservations": {}
               },
               "RestartPolicy": {
                   "Condition": "any",
                   "MaxAttempts": 0
               },
               "Placement": {}
           },
           "Mode": {
               "Replicated": {
                   "Replicas": 1
               }
           },
           "UpdateConfig": {
               "Parallelism": 1
           },
           "EndpointSpec": {
               "Mode": "vip"
           }
       },
       "Endpoint": {
           "Spec": {}
       }
   }
   ]
   ```

   어떤 노드가 Service를 실행중인지 보려면 `docker service ps <SERVICE-ID>`

   ```
   $ docker service ps helloworld

   ID                         NAME          SERVICE     IMAGE   LAST STATE         DESIRED STATE  NODE
   8p1vev3fq5zm0mi8g0as41w35  helloworld.1  helloworld  alpine  Running 3 minutes  Running        worker2
   ```

   helloworld 서비스가 workder2 에서 실행중이지만 manager noded에서 실행될 수도 있음. default로 manager node도 worker node 처럼 task를 실행할 수 있음. `DESIRED STATE` 와 `LAST STATE`도 표시해서 지정한 수만큼의 task가 실행중인지 확인가능.

4. 실행중인 node에 접속해서 `docker ps` 명령어로 해당 container의 상세 상태를 확인 가능.

   ```
   $docker ps

   CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
   e609dde94e47        alpine:latest       "ping docker.com"   3 minutes ago       Up 3 minutes                            helloworld.1.8p1vev3fq5zm0mi8g0as41w35
   ```

## 서비스 스케일링
swarm에 Service를 deploy한 다음에는 Docker CLI를 이용해서 Service ps를 scale 할 수 있음.

1. manager node로 ssh 접속.

2. 아래의 명령어로 Service의 실행 상태 변경

   ```
   $ docker service scale <SERVICE-ID>=<NUMBER-OF-TASKS>
   ```
   ex>
   ```
   $ docker service scale helloworld=5

   helloworld scaled to 5
   ```

3. `docker service ps <SERVICE-ID>`로 수정결과 확인

   ```
   $ docker service ps helloworld

   ID                         NAME          SERVICE     IMAGE   LAST STATE          DESIRED STATE  NODE
   8p1vev3fq5zm0mi8g0as41w35  helloworld.1  helloworld  alpine  Running 7 minutes   Running        worker2
   c7a7tcdq5s0uk3qr88mf8xco6  helloworld.2  helloworld  alpine  Running 24 seconds  Running        worker1
   6crl09vdcalvtfehfh69ogfb1  helloworld.3  helloworld  alpine  Running 24 seconds  Running        worker1
   auky6trawmdlcne8ad8phb0f1  helloworld.4  helloworld  alpine  Running 24 seconds  Accepted       manager1
   ba19kca06l18zujfwxyc5lkyn  helloworld.5  helloworld  alpine  Running 24 seconds  Running        worker2

   ```

   task가 4개 늘려서 Alpine linux 의 실행중 인스턴스가 총 5개가 됨. task는 3개의 node로 분산되어 있음.

4. 현재 머신의 container의 상태를 `docker ps’ 명령으로 확인. manager1의 경우 아래와 같음.

   ```
   $ docker ps

   CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
   528d68040f95        alpine:latest       "ping docker.com"   About a minute ago   Up About a minute                       helloworld.4.auky6trawmdlcne8ad8phb0f1
   ```

   마찬가지로 다른 각각의 node에 ssh 접속해서 해당 node의 container를 확인 가능

## swarm으로 부터 Service 삭제
이제 더 이상 helloworld 서비스는 필요가 없기 때문에 삭제해도 됨.

1. 터미널에서 manager node로 ssh 접속
2. `docker service rm helloworld` 명령어로 helloworld service 삭제

   ```
   $ docker service rm helloworld

   helloworld
   ```

3. `docker service inspect <SERVICE-ID>` 명령어로 manager가 service를 삭제했는지 확인. CLI는 service를 찾을 수 없다는 메세지를 리턴

   ```
   $ docker service inspect helloworld
   []
   Error: no such service or task: helloworld
   ```

## Service를 rolling update 하기
앞에서 service의 인스턴스를 scale 했었음. 이번에는 Redis 3.0.6 컨테이너 이미지로  service를 deploy함. rolling update를 이용해서 Redis 3.0.7 이미지로 service를 upgrade함.

1. 터미널에서 manager node로 ssh접속
2. Redis 3.0.6을 swarm에 디플로이. 10초 업데이트 delay지정.

   ```
   $ docker service create \
     --replicas 3 \
     --name redis \
     --update-delay 10s \
     redis:3.0.6

   0u6a4s31ybk7yw2wyvtikmu50
   ```

   이렇게 rolling update 정책을 service 디플로이시에 설정.  
   `--update-delay`는 서비스 task나 task set의 업데이트간의 시간 간격을 지정. 시간 `T`는 초: `Ts`, 분: `Tm`, 시간:`Th`의 조합으로 정의. 즉 `10m30s`는 10분 30초.  
   default로 스케쥴러는 task를 한번에 하나씩 업데이트. `--update-parallelism` 옵션으로 스케쥴러가 동시에 업데이트 하는 task 수를 조정가능. default로 task의 update의 결과가 RUNNING이면 다음 task를 update해가서 전체의 task가 업데이트됨. 도중에 하나라도 FAIL을 리턴하면 스케쥴러는 update를 일시 중단함. `docker service create`나 `docker service update`의 `--update-failure-action` 옵션으로 지정가능.

3. `redis` 서비스 inspect

   ```
   $ docker service inspect --pretty redis

   ID:             0u6a4s31ybk7yw2wyvtikmu50
   Name:           redis
   Mode:           Replicated
    Replicas:      3
   Placement:
    Strategy:      Spread
   UpdateConfig:
    Parallelism:   1
    Delay:         10s
   ContainerSpec:
    Image:         redis:3.0.6
   Resources:
   ```

4. `redis` Service의 컨테이너 이미지 업데이트. swarm manager는 `UpdateConfig` 정책에 따라서 업데이트 적용.

   ```
   $ docker service update --image redis:3.0.7 redis
   redis
   ```

   스케쥴러는 다음과 같은 순으로 rolling update를 실시

   - 첫 번째 task를 stop
   - 중단된 task의 update를 스케쥴
   - update된 task의 container를 start
   - task의 update 결과가 RUNNING이면, 지정된 시간 동안 기다렸다가 다음 task를 stop.
   - update 중  task가 FAILED를 리턴하면 중단

5. `docker service inspect --pretty redis`로 결과를 확인
   ```
   $ docker service inspect --pretty redis

   ID:             0u6a4s31ybk7yw2wyvtikmu50
   Name:           redis
   Mode:           Replicated
    Replicas:      3
   Placement:
    Strategy:      Spread
   UpdateConfig:
    Parallelism:   1
    Delay:         10s
   ContainerSpec:
    Image:         redis:3.0.7
   Resources:
   ```

   update를 실패하면

   ```
   $ docker service inspect --pretty redis

   ID:             0u6a4s31ybk7yw2wyvtikmu50
   Name:           redis
   ...snip...
   Update status:
    State:      paused
    Started:    11 seconds ago
    Message:    update paused due to failure or early termination of task 9p7ith557h8ndf0ui9s0q951b
   ...snip...
   ```

   update를 재개하려면 아래와 같이 `docker service update <SERVICE-ID>`

   ```
   docker service update redis
   ```

   문제를 해결하기 위해서 `docker service update`로 설정을 변경해야 할 필요가 있을 수도.

6. rolling update를 보려면 `docker service ps <SERVICE-ID>`

   ```
   $ docker service ps redis

   ID                         NAME         IMAGE        NODE       DESIRED STATE  CURRENT STATE            ERROR
   dos1zffgeofhagnve8w864fco  redis.1      redis:3.0.7  worker1    Running        Running 37 seconds
   88rdo6pa52ki8oqx6dogf04fh   \_ redis.1  redis:3.0.6  worker2    Shutdown       Shutdown 56 seconds ago
   9l3i4j85517skba5o7tn5m8g0  redis.2      redis:3.0.7  worker2    Running        Running About a minute
   66k185wilg8ele7ntu8f6nj6i   \_ redis.2  redis:3.0.6  worker1    Shutdown       Shutdown 2 minutes ago
   egiuiqpzrdbxks3wxgn8qib1g  redis.3      redis:3.0.7  worker1    Running        Running 48 seconds
   ctzktfddb2tepkr45qcmqln04   \_ redis.3  redis:3.0.6  mmanager1  Shutdown       Shutdown 2 minutes ago
   ```
   update 도중에 위의 명령을 실행하면 몇몇 task는 3.0.6 몇몇 task는 3.0.7의 상태로 출력됨. 위의 결과는 update 종료된 상태.

## swarm에서 node 추출
앞의 예재까지 모든 node는 `ACTIVE` 상태로 실행중이었음. swarm manager는 task를 `ACTIVE` node로 할당가능. 즉 현재까지 모든 node가 task를 받을 수 있었음.

계획적 메인터넌스 시간등, node를 `DRAIN`상태로 만들 필요가 있음. ‘DRAIN’ 상태에서는 swarm manager로 부터 새로운 task를 받지 않게 됨. 또한 manager는 그 node의 task를 stop하게 되고 `ACTIVE`의 어떤 node에 replica task를 런치함.

1. 터미널에서 manager node로 ssh 접속.
2. node가 `ACTIVE`인지 확인

   ```
   $ docker node ls

   ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
   1bcef6utixb0l0ca7gxuivsj0    worker2   Ready   Active
   38ciaotwjuritcdtn9npbnkuz    worker1   Ready   Active
   e216jshn25ckzbvmwlnh5jr3g *  manager1  Ready   Active        Leader
   ```

3. 앞에서 썼던 `redis` 서비스를 실행하지 않았다면, start.

   ```
   $ docker service create --replicas 3 --name redis --update-delay 10s redis:3.0.6
    c5uo6kdmzpon37mgj9mwglcfw
   ```

4. `docker service ps redis` 로 manager가 어떤식으로 task를 각 node에 할당했는지 확인

   ```
   $ docker service ps redis

   ID                         NAME     SERVICE  IMAGE        LAST STATE          DESIRED STATE  NODE
   7q92v0nr1hcgts2amcjyqg3pq  redis.1  redis    redis:3.0.6  Running 26 seconds  Running        manager1
   7h2l8h3q3wqy5f66hlv9ddmi6  redis.2  redis    redis:3.0.6  Running 26 seconds  Running        worker1
   9bg7cezvedmkgg6c8yzvbhwsd  redis.3  redis    redis:3.0.6  Running 26 seconds  Running        worker2
   ```
각 task각 각 node에 분산되어 있지만 환경에 따라 다른 결과를 가질 수 있음

5. `docker node update --availability drain <NODE-ID>`로 task가 실행중인 node를 `DRAIN`상태로 만듬

   ```
   docker node update --availability drain worker1

   worker1
   ```

6. node를 inspect해서 availability 상태를 확인

   ```
   $ docker node inspect --pretty worker1

   ID:         38ciaotwjuritcdtn9npbnkuz
   Hostname:       worker1
   Status:
    State:         Ready
    Availability:      Drain
   ...snip...
   ```

   `Availability`가  `Drain`상태.

7. `docker service ps redis`로 manager가 어떻게 task를 재 분배했는지 확인

   ```
   $ docker service ps redis

   ID                         NAME          IMAGE        NODE      DESIRED STATE  CURRENT STATE           ERROR
   7q92v0nr1hcgts2amcjyqg3pq  redis.1       redis:3.0.6  manager1  Running        Running 4 minutes
   b4hovzed7id8irg1to42egue8  redis.2       redis:3.0.6  worker2   Running        Running About a minute
   7h2l8h3q3wqy5f66hlv9ddmi6   \_ redis.2   redis:3.0.6  worker1   Shutdown       Shutdown 2 minutes ago
   9bg7cezvedmkgg6c8yzvbhwsd  redis.3       redis:3.0.6  worker2   Running        Running 4 minutes
   ```

    `Drain` 상태의 node의 task가 종료되고 다른 `ACTIVE` node에 task가 생성됨.

8. `docker node update --availability active <NODE-ID>`로 drain 상태의 node를 active로 되돌림

   ```
   $ docker node update --availability active worker1

   worker1
   ```

9. node를 inspect해서 결과 확인

   ```
   $ docker node inspect --pretty worker1

     ID:			38ciaotwjuritcdtn9npbnkuz
     Hostname:		worker1
     Status:
      State:			Ready
      Availability:		Active
    ...snip...
   ```

   Active 상태이므로 다음의 상황에서 task를 받을 수 있게 됨

   - service가 scale up 하게 될 때
   - rolling update하게 될 때
   - 다른 node를 ‘Drain’으로 변경했을 때
   - 어떤 Active node에 있던 task가 fail 했을 때
