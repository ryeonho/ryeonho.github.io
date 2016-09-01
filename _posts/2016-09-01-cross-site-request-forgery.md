---
layout: post
title:  "Cross site request forgery 간략 번역"
categories: security
---

# Cross-site request forgery (CSRF)
CSRF는 malicious site가 visitor의 브라우저로 당신의 서버로 request를 전송하는 것. user의 cookie와 같이 오기 때문에 당사자가 보낸 form이라고 생각하는 것.

당신의 서버의 어떤 form이 vulnerable인지에 따라서 아래와 같은 것들이 가능

- 당신의 서버로 부터 Log out
- victim의 preference를 변경
- victim의 login으로 코멘트를 post
- 다른 account로 자금을 이동

Cookie 대신에 IP 어드레스를 사용할 수도 있음

- victim의 IP 주소로 부터 익명 코멘트를 post.
- wireless 라우터나 케이블 모뎀같은 장비의 셋팅을 변경
- 인트라넷 위키 페이지를 수정
- botnet 없이 분산된 password-guessing 공격 실행(로그인 성공 여부를 감지  가능)

CSRF Attack은 보통 Javascript로 crosse-site form을 자동으로 submit. Javascript가 없더라도 form field를 hidden으로 하고 button을 link나 scroll bar처럼 보일 수 있음.
