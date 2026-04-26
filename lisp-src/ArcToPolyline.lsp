;;; Arc to Polyline 변환 도구 (A2P)
;;; AutoCAD Map 3D 2013 및 Windows 11 환경 최적화
;;; 호(Arc) 및 폴리라인 내의 호 세그먼트를 선분으로 구성된 폴리라인으로 변환합니다.
;;; 
;;; 주요 기능:
;;; 1. 수량(n) 지정 변환
;;; 2. 중앙종거(최대 5cm) 기준 변환
;;; 3. 현의 길이(d) 기준 변환
;;;
;;; 출력: 현재 레이어에 노란색(Color 2)으로 새로운 객체 생성.
;;; [Rule 3 예외]: 사용자 요청에 따라 표준 녹색(Color 3) 대신 노란색(Color 2) 적용.
;;; 원본 객체는 보존됩니다.

(vl-load-com)

;; ==========================================
;; [1] 기하 연산 및 공통 유틸리티 (util:)
;; ==========================================

;; 헬퍼: 호 세그먼트에 대한 분할 점 계산
;; obj: vla-object (arc 또는 polyline)
;; start_param: 시작 파라미터 (double)
;; end_param: 끝 파라미터 (double)
;; mode: 변환 모드 ("N", "M", "D")
;; val: 설정 값 (number)
(defun util:get-arc-segmented-points (obj start_param end_param mode val / 
                      dist_start dist_end total_dist n seg_dist pts p i radius ang bulge p1 p2 dist_p1p2 x seg_ang)
  (setq dist_start (vlax-curve-getDistAtParam obj start_param)
        dist_end   (vlax-curve-getDistAtParam obj end_param)
        total_dist (abs (- dist_end dist_start))
  )

  ;; Mode M(중앙종거) 및 D(현의 길이)를 위해 반지름과 전체 각도 계산
  (if (or (= mode "M") (= mode "D"))
    (if (= (vla-get-objectname obj) "AcDbArc")
      (setq radius (vla-get-radius obj)
            ang    (vla-get-totalangle obj))
      (progn
        ;; 폴리라인 내의 호 세그먼트인 경우
        (setq bulge (vla-getbulge obj (fix start_param)))
        (setq p1 (vlax-curve-getPointAtParam obj start_param))
        (setq p2 (vlax-curve-getPointAtParam obj end_param))
        (setq dist_p1p2 (distance (list (car p1) (cadr p1)) (list (car p2) (cadr p2))))
        (setq ang (* 4.0 (atan (abs bulge))))
        (setq radius (/ (/ dist_p1p2 2.0) (sin (/ ang 2.0))))
      )
    )
  )

  (cond
    ;; Mode N: 수량 지정 방식
    ((= mode "N")
     (setq n val))
    
    ;; Mode M: 중앙종거 기준 (h <= val)
    ((= mode "M")
     (if (<= radius val)
       (setq n 1)
       (progn
         (setq x (- 1.0 (/ val radius)))
         (setq seg_ang (* 2.0 (atan (sqrt (- 1.0 (* x x))) x)))
         (setq n (fix (max 1 (abs (/ ang seg_ang)))))
         (if (> (rem (abs ang) seg_ang) 0.0001)
           (setq n (1+ n))
         )
       )
     )
    )

    ;; Mode D: 현의 길이 기준 (d)
    ((= mode "D")
     (if (<= val (* 2.0 radius))
       (progn
         (setq x (/ val (* 2.0 radius)))
         (setq seg_ang (* 2.0 (atan x (sqrt (- 1.0 (* x x))))))
         (setq n (fix (/ ang seg_ang)))
       )
       (setq n 1) ;; 현의 길이가 지름보다 긴 경우
     )
    )
  )

  ;; 점 리스트 생성
  (if (= mode "D")
    ;; Mode D 전용: 일정한 간격 유지 후 마지막 점 추가
    (progn
      (setq pts (list (vlax-curve-getPointAtParam obj start_param)))
      (setq i 1)
      (setq seg_dist (+ dist_start (* i val)))
      (while (< (+ seg_dist 1e-6) dist_end)
        (setq p (vlax-curve-getPointAtDist obj seg_dist))
        (setq pts (cons p pts))
        (setq i (1+ i))
        (setq seg_dist (+ dist_start (* i val)))
      )
      (setq pts (cons (vlax-curve-getPointAtParam obj end_param) pts))
      (setq pts (reverse pts))
    )
    ;; Mode N 및 M: 균등 분할 방식
    (progn
      (setq pts nil)
      (setq i 0)
      (while (<= i n)
        (setq seg_dist (+ dist_start (* (/ i (float n)) total_dist)))
        (if (> seg_dist dist_end) (setq seg_dist dist_end))
        (setq p (vlax-curve-getPointAtDist obj seg_dist))
        (setq pts (cons p pts))
        (setq i (1+ i))
      )
      (setq pts (reverse pts))
    )
  )
  pts
)

;; 헬퍼: 점 리스트로부터 LWPolyline 생성
(defun util:create-lwpolyline-yellow (pts / acDoc space obj coords i)
  (setq acDoc (vla-get-activedocument (vlax-get-acad-object)))
  (setq space (vla-get-modelspace acDoc))
  (setq coords (vlax-make-safearray vlax-vbDouble (cons 0 (1- (* (length pts) 2)))))
  (setq i 0)
  (foreach p pts
    (vlax-safearray-put-element coords i (car p))
    (vlax-safearray-put-element coords (1+ i) (cadr p))
    (setq i (+ i 2))
  )
  (setq obj (vla-addlightweightpolyline space coords))
  (vla-put-color obj 2) ;; 노란색 적용 (사용자 요청에 따른 Rule 3 예외)
  obj
)

;; ==========================================
;; [2] 메인 명령어 (C:A2P)
;; ==========================================

(defun C:ARCTOPOLYLINE (/ *error* ss mode val i ent data type old_cmdecho old_osmode count acDoc vla_obj j num_segs bulge p1 seg_pts pts new_poly)
  
  (setq acDoc (vla-get-activedocument (vlax-get-acad-object)))

  ;; 에러 핸들러
  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\n오류: " msg))
    )
    (if old_cmdecho (setvar "CMDECHO" old_cmdecho))
    (if old_osmode (setvar "OSMODE" old_osmode))
    (vla-endundomark acDoc)
    (princ)
  )

  ;; 시작 안내
  (princ "\n호 변환 도구 (Arc to Polyline) [ARCTOPOLYLINE]")
  
  ;; 객체 선택 (Arc 및 LWPolyline만 필터링)
  (setq ss (ssget '((0 . "ARC,LWPOLYLINE"))))
  (if (not ss)
    (progn (princ "\n선택된 객체가 없습니다.") (exit))
  )

  ;; 옵션 선택
  (initget "Number Midordinate Distance")
  (setq mode (getkword "\n변환 옵션 선택 [수량(N)/중앙종거(M)/등간격(D)]: "))
  (if (not mode) (setq mode "Number"))

  (cond
    ((= mode "Number") 
     (setq mode "N")
     (setq val (getint "\n분할 수량 입력 <10>: "))
     (if (not val) (setq val 10)))
    ((= mode "Midordinate")
     (setq mode "M")
     (setq val (getdist "\n중앙종거(m) 입력 <0.05>: "))
     (if (not val) (setq val 0.05))) ;; 기본 0.05m
    ((= mode "Distance")
     (setq mode "D")
     (setq val (getdist "\n현의 길이(m) 입력 <1.0>: "))
     (if (not val) (setq val 1.0)))
  )

  ;; 시스템 변수 저장 및 설정
  (setq old_cmdecho (getvar "CMDECHO"))
  (setq old_osmode (getvar "OSMODE"))
  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)
  (vla-startundomark acDoc)

  (setq count 0)
  (setq i 0)
  ;; 선택 세트 순회
  (repeat (sslength ss)
    (setq ent (ssname ss i))
    (setq data (entget ent))
    (setq type (cdr (assoc 0 data)))
    (setq vla_obj (vlax-ename->vla-object ent))
    
    (cond
      ;; ARC 처리
      ((= type "ARC")
       (setq pts (util:get-arc-segmented-points vla_obj 
                                (vlax-curve-getStartParam vla_obj) 
                                (vlax-curve-getEndParam vla_obj) 
                                mode val))
       (util:create-lwpolyline-yellow pts)
       (setq count (1+ count))
      )

      ;; LWPOLYLINE 처리
      ((= type "LWPOLYLINE")
       (setq pts nil)
       (setq j 0)
       (setq num_segs (fix (vlax-curve-getEndParam vla_obj)))
       ;; 각 세그먼트 순회
       (while (< j num_segs)
         (setq bulge (vla-getbulge vla_obj j))
         (setq p1 (vlax-curve-getPointAtParam vla_obj j))
         (if (= bulge 0.0)
           ;; 직선 세그먼트
           (setq pts (cons p1 pts))
           ;; 호 세그먼트
           (progn
             (setq seg_pts (util:get-arc-segmented-points vla_obj j (1+ j) mode val))
             ;; 중복점 제거를 위해 마지막 점 제외
             (setq seg_pts (reverse (cdr (reverse seg_pts))))
             (setq pts (append (reverse seg_pts) pts))
           )
         )
         (setq j (1+ j))
       )
       
       (if (= (vla-get-closed vla_obj) :vlax-true)
         ;; 폐합된 경우
         (setq new_poly (util:create-lwpolyline-yellow (reverse pts)))
         (progn
           ;; 열린 폴리라인의 경우 마지막 정점 추가
           (setq pts (cons (vlax-curve-getPointAtParam vla_obj num_segs) pts))
           (setq new_poly (util:create-lwpolyline-yellow (reverse pts)))
         )
       )
       
       ;; 원본이 폐합 상태였다면 결과물도 폐합 처리
       (if (= (vla-get-closed vla_obj) :vlax-true)
         (vla-put-closed new_poly :vlax-true)
       )
       (setq count (1+ count))
      )
    )
    (setq i (1+ i))
  )

  ;; 정리 및 복구
  (vla-endundomark acDoc)
  (setvar "CMDECHO" old_cmdecho)
  (setvar "OSMODE" old_osmode)
  (princ (strcat "\n총 " (itoa count) "개의 객체가 변환되었습니다."))
  (princ)
)

(princ "\n호 변환 도구(Arc to Polyline) 로드 완료.")
(princ)
