;;; 좌표 오사오입 재결정 도구 (CoordRound)
;;; AutoCAD Map 3D 2013 및 Windows 11 환경 최적화
;;; 선택된 객체의 좌표를 지정된 자리수로 오사오입(Round half to even)하여 새로운 객체를 생성합니다.
;;; 
;;; [규칙 준수]:
;;; - 원본 객체 보존 및 녹색(Color 3)의 ref_object 생성 (Rule 3)
;;; - 모든 상호작용은 명령행 프롬프트 사용 (Rule 2)
;;; - 한글 주석 사용 및 표준 로드 메시지 적용

(vl-load-com)

;; ==========================================
;; [1] 기하 연산 및 공통 유틸리티 (util:)
;; ==========================================

;; 오사오입(Round half to even) 수학 함수
;; num: 대상 숫자
;; prec: 소수점 자리수
(defun util:round-half-to-even (num prec / factor shifted integral fractional)
  (setq factor (expt 10.0 prec))
  (setq shifted (* num factor))
  ;; 엡실론(1e-9)을 더해 부동소수점 오차 방지
  (setq integral (fix (if (>= shifted 0) (+ shifted 1e-9) (- shifted 1e-9))))
  (setq fractional (abs (- shifted integral)))
  
  (if (equal fractional 0.5 1e-7)
    (if (= (rem (abs integral) 2) 0)
      ;; 짝수이면 버림
      (/ (float integral) factor)
      ;; 홀수이면 올림 (부호에 따라 방향 결정)
      (/ (float (+ integral (if (>= shifted 0) 1 -1))) factor)
    )
    ;; 0.5가 아니면 일반적인 반올림 (rtos 활용)
    (/ (atof (rtos shifted 2 0)) factor)
  )
)

;; 리스트 내의 모든 숫자를 오사오입 처리 (주로 폴리라인 좌표용)
(defun util:round-list-half-to-even (lst prec)
  (mapcar '(lambda (x) (util:round-half-to-even x prec)) lst)
)

;; ==========================================
;; [2] 객체 처리 엔진 (fn:)
;; ==========================================

(defun fn:coord-round-engine (prec / ss i ent vla_obj obj_name coords old_coords new_coords p1 p2 center count acDoc)
  (setq acDoc (vla-get-activedocument (vlax-get-acad-object)))
  (vla-startundomark acDoc)
  
  (princ (strcat "\n[좌표 오사오입 변환 - 소수점 " (itoa prec) "자리]"))
  (setq ss (ssget '((0 . "POINT,LINE,LWPOLYLINE,CIRCLE,ARC,TEXT,MTEXT"))))
  
  (if (not ss)
    (progn (princ "\n선택된 객체가 없습니다.") (vla-endundomark acDoc) (exit))
  )

  (setq count 0 i 0)
  (repeat (sslength ss)
    (setq ent (ssname ss i))
    (setq vla_obj (vlax-ename->vla-object ent))
    (setq obj_name (vla-get-objectname vla_obj))
    
    ;; 원본 복사 (Rule 3)
    (setq vla_ref (vla-copy vla_obj))
    (vla-put-color vla_ref 3) ;; 녹색(Color 3) 설정
    
    (cond
      ;; 1. 폴리라인 처리
      ((= obj_name "AcDbPolyline")
       (setq old_coords (vlax-get vla_ref 'Coordinates))
       (setq new_coords (util:round-list-half-to-even old_coords prec))
       (vlax-put vla_ref 'Coordinates new_coords)
      )
      
      ;; 2. 라인 처리
      ((= obj_name "AcDbLine")
       (setq p1 (vlax-get vla_ref 'StartPoint))
       (setq p2 (vlax-get vla_ref 'EndPoint))
       (vla-put-startpoint vla_ref (vlax-3d-point (util:round-list-half-to-even p1 prec)))
       (vla-put-endpoint vla_ref (vlax-3d-point (util:round-list-half-to-even p2 prec)))
      )
      
      ;; 3. 점, 텍스트, 원, 호 등 (중심점/삽입점 기반)
      ((member obj_name '("AcDbPoint" "AcDbText" "AcDbMText" "AcDbCircle" "AcDbArc"))
       (setq p1 (vlax-get vla_ref (if (member obj_name '("AcDbCircle" "AcDbArc")) 'Center 'InsertionPoint)))
       (if (member obj_name '("AcDbCircle" "AcDbArc"))
         (vla-put-center vla_ref (vlax-3d-point (util:round-list-half-to-even p1 prec)))
         (vla-put-insertionpoint vla_ref (vlax-3d-point (util:round-list-half-to-even p1 prec)))
       )
      )
    )
    (setq count (1+ count) i (1+ i))
  )

  (vla-endundomark acDoc)
  (princ (strcat "\n완료: 총 " (itoa count) "개의 객체가 변환되어 녹색으로 생성되었습니다."))
  (princ)
)

;; ==========================================
;; [3] 진입 명령어
;; ==========================================

;; 소수점 2자리 오사오입
(defun C:OSA2 () (fn:coord-round-engine 2))

;; 소수점 3자리 오사오입
(defun C:OSA3 () (fn:coord-round-engine 3))

(princ "\n좌표 오사오입 재결정 도구 로드 완료.")
(princ)
