autocad map 3d 2013 버전을 사용중이야.  AutoLisp을 사용하여 autocad 3rd party 응용프로그램을 작성하려고 해.
오토캐드 2013은 windows11 환경에서 프리징 현상을 만들고 있어. 이 현상이 나타나지 않도록 다음 기능을 생성해줘. 

## 스케일에 따른 공차 계산
1. 공차면적 공식(F = 0.026^2 * M * sqrt(S))
   - S: 대장면적
   - M: 축척 (1000, 1200, 6000)
   - F: 공차면적
   - 공차면적은 소수점 아래 3자리까지 표현

## 면적 조정
1. 객체 선택(LWPOLYLINE only, 하나의 객체만 선택 가능)
2. ref_object: 선택 객체를 복사하여 ref_object로 사용(메모리)
3. ref_object의 면적을 프롬프트로 표시
4. 목표 면적값 입력:
   1. 입력예: 123.2, @123, #123, d123, d-123, t123
5. prefix(대소문자 구분없음)에 의해 입력 값 파싱 후 목표면적 설정
   1. 면적(숫자형식): (scale:1200, reg_area: 123.2, tol_area: 공차면적)
      - target_area = reg_area + tol_area - 1  if (객체면적 >= reg_area) else reg_area - tol_area + 1
   2. "@면적": (scale:6000, reg_area: 면적, tol_area: 공차면적)
      - target_area = reg_area + tol_area - 1  if (객체면적 >= reg_area) else reg_area - tol_area + 1
   3. "#면적": (scale:1000, reg_area: 면적, tol_area: 공차면적)
      - target_area = reg_area + tol_area - 1  if (객체면적 >= reg_area) else reg_area - tol_area + 1
   4. "d면적": 면적 차이에 의한 목표면적 설정
      - target_area = reg_area + 면적
   5. "d-면적": 면적 차이에 의한 목표면적 설정(마이너스)
      - target_area = reg_area - 면적
   6. "t면적": 목표 면적만 존재
      - target_area = 면적
6. 변경할 구간 설정(p1, p2)
   1. 객체를 cw 방향으로 설정
   2. 객체 위의 점 2개를 사용자로부터 입력받기(snap기능 사용)
       - 사용자에게 프롬프트를 통해 무엇을 입력할 지 알리기
       - osnap: endpoint
7. 구간 폴리라인 생성: p1과 p2 사이의 점들을 순서대로 연결한 폴리라인을 생성하고 길이를 계산
8. 옵셋을 이용하여 구간폴리라인 변경
   - 옵셋 거리: (목표면적 - ref_object면적) / 구간길이 * (-1)
9. 선택 객체와 구간 폴리라인이 겹치지 않는 경우
   - p1 이전점과  p1을 잇는 선분과 구간 폴리라인의 시작점과 그 다음점을 잇는 선분의 교차점을 구간 폴리라인의 시작점으로 설정
   - p2와 p2 다음점을 잇는 선분과 구간 폴리라인의 마지막점과 그전점을 잇는 선분의 교차점을 구간 폴리라인의 끝점으로 설정
10. ref_object의 p1과 p2사이의 점들을 구간 폴리라인의 점들로 대체
11. ref_object의 면적 재계산
12. 면적 재계산 후 목표 면적과의 차이가 0.01 범위내에 있는지 확인
13. 허용오차 범위내에 있으면 작업 완료
14. 허용오차 범위내에 있지 않으면 8번으로 돌아가서 최대 30회 반복 
   - 30회 이상 반복하면 작업 중단하고 user에게 알림


## 프리징 현상 방지 방안
1. 사용자와 상호작용하는 부분은 AutoCad 프롬프트 창을 활용하도록 구현해줘. 
2. msgbox, inputbox 와 같은 창을 사용하지 말 것
