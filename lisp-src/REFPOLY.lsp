;;; REFPOLY.lsp
;;; 통합 참조 폴리라인 수정 도구 (CW 및 CCW/Mixed 지원)
;;; AutoCAD 2013 & Windows 11 환경 최적화

(vl-load-com)
(if (not fn:outerbound) (load "OuterBoundary.lsp"))

;; ==========================================
;; [1] 공통 유틸리티 함수
;; ==========================================

;; 정점 추출
(defun util:get-vertices (ent / pts)
  (foreach x (entget ent)
    (if (= (car x) 10)
      (setq pts (cons (cdr x) pts))
    )
  )
  (reverse pts)
)

;; 부호 있는 면적 계산
(defun util:get-signed-area (pts / area p1 p2)
  (setq area 0.0)
  (setq pts (append pts (list (car pts))))
  (while (and (setq p1 (car pts)) (setq p2 (cadr pts)))
    (setq area (+ area (* (- (car p2) (car p1)) (+ (cadr p2) (cadr p1)))))
    (setq pts (cdr pts))
  )
  area
)

;; 방향 정렬 함수들
(defun util:ensure-clockwise (pts)
  (if (< (util:get-signed-area pts) 0) (reverse pts) pts)
)

(defun util:ensure-counter-clockwise (pts)
  (if (> (util:get-signed-area pts) 0) (reverse pts) pts)
)

;; 리스트 순서대로 구간 추출
(defun util:get-segment-by-list-order (lst idx1 idx2 / res i len continue)
  (setq len (length lst))
  (setq i idx1)
  (setq res nil)
  (setq continue T)
  (while continue
    (setq res (cons (nth i lst) res))
    (if (= i idx2)
      (setq continue nil)
      (setq i (rem (1+ i) len))
    )
  )
  (reverse res)
)

;; 점 유효성 확인
(defun util:is-on-poly (pt ent fuzz)
  (equal pt (vlax-curve-getClosestPointTo ent pt) fuzz)
)

;; 최접점 정점 인덱스
(defun util:get-nearest-vertex-idx (pt pts fuzz / idx min-dist res-idx i d)
  (setq i 0 min-dist 1e9 res-idx -1)
  (foreach v pts
    (setq d (distance pt v))
    (if (< d min-dist) (setq min-dist d res-idx i))
    (setq i (1+ i))
  )
  res-idx
)

;; ==========================================
;; [2] 핵심 연산 엔진
;; ==========================================
(defun fn:refpoly-engine (mode-desc ref-norm-fn target-norm-fn / 
                          *error* old-osmode old-cmdecho doc ss-ref ref-ent ref-pts is-temp-ref 
                          ss-target target-ent target-pts p1 q1 p2 q2 idxP1 idxQ1 idxP2 idxQ2 
                          seg-q rem-p new-pts flat-pts vla-target)
  
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  
  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\n오류: " msg))
    )
    (if (and is-temp-ref ref-ent) (entdel ref-ent))
    (if old-osmode (setvar "OSMODE" old-osmode))
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (vla-EndUndoMark doc)
    (command "_.undo" "1")
    (princ "\n작업이 중단되었습니다.")
    (princ)
  )

  (vla-StartUndoMark doc)
  (setq old-osmode (getvar "OSMODE"))
  (setq old-cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  (princ (strcat "\n[" mode-desc " 모드 실행]"))

  ;; 1. 기준 폴리라인 선택
  (princ "\n[단계 1] 기준 폴리라인(Reference)을 선택하세요.")
  (setq ss-ref (ssget '((0 . "LINE,LWPOLYLINE,POLYLINE"))))
  (if (not ss-ref) (progn (princ "\n취소되었습니다.") (exit)))

  (setq is-temp-ref nil)
  (if (> (sslength ss-ref) 1)
    (progn
      (princ "\n다중 객체에서 외곽선 추출 중...")
      (setq ref-ent (fn:outerbound ss-ref))
      (if (not ref-ent) (progn (princ "\n외곽선 추출 실패.") (exit)))
      (setq is-temp-ref T)
    )
    (progn
      (setq ref-ent (ssname ss-ref 0))
      (if (or (/= (cdr (assoc 0 (entget ref-ent))) "LWPOLYLINE")
              (= (logand (cdr (assoc 70 (entget ref-ent))) 1) 0))
        (progn (princ "\n오류: 단일 기준은 닫힌 LWPOLYLINE이어야 합니다.") (exit))
      )
    )
  )
  (setq ref-pts (apply ref-norm-fn (list (util:get-vertices ref-ent))))

  ;; 2. 수정 대상 폴리라인 선택
  (princ "\n[단계 2] 대상 폴리라인(Target) 1개를 선택하세요.")
  (setq ss-target (ssget ":S" '((0 . "LWPOLYLINE"))))
  (if (not ss-target) (exit))
  (setq target-ent (ssname ss-target 0))
  (if (= (logand (cdr (assoc 70 (entget target-ent))) 1) 0)
    (progn (princ "\n오류: 대상 객체는 반드시 닫혀 있어야 합니다.") (exit))
  )
  (setq target-pts (apply target-norm-fn (list (util:get-vertices target-ent))))

  ;; 3. 점 입력
  (setvar "OSMODE" 1)
  (setq p1 (getpoint "\n[단계 3] 대상 시작점 P1 클릭: "))
  (if (not (util:is-on-poly p1 target-ent 0.0005)) (progn (princ "\n오류: 점이 대상 위에 없음.") (exit)))
  
  (setq q1 (getpoint "\n[단계 4] 기준 시작점 Q1 클릭: "))
  (if (not (util:is-on-poly q1 ref-ent 0.0005)) (progn (princ "\n오류: 점이 기준 위에 없음.") (exit)))

  (setq p2 (getpoint "\n[단계 5] 대상 끝점 P2 클릭: "))
  (if (not (util:is-on-poly p2 target-ent 0.0005)) (progn (princ "\n오류: 점이 대상 위에 없음.") (exit)))

  (setq q2 (getpoint "\n[단계 6] 기준 끝점 Q2 클릭: "))
  (if (not (util:is-on-poly q2 ref-ent 0.0005)) (progn (princ "\n오류: 점이 기준 위에 없음.") (exit)))
  (setvar "OSMODE" old-osmode)

  ;; 4. 정점 인덱스 및 구간 추출
  (setq idxP1 (util:get-nearest-vertex-idx p1 target-pts 0.0005))
  (setq idxQ1 (util:get-nearest-vertex-idx q1 ref-pts 0.0005))
  (setq idxP2 (util:get-nearest-vertex-idx p2 target-pts 0.0005))
  (setq idxQ2 (util:get-nearest-vertex-idx q2 ref-pts 0.0005))

  (setq seg-q (util:get-segment-by-list-order ref-pts idxQ1 idxQ2))
  (setq idxP2-next (rem (1+ idxP2) (length target-pts)))
  (setq idxP1-prev (if (= idxP1 0) (1- (length target-pts)) (1- idxP1)))
  (setq rem-p (util:get-segment-by-list-order target-pts idxP2-next idxP1-prev))
  
  (setq new-pts (append seg-q rem-p))
  (setq flat-pts nil)
  (foreach v new-pts (setq flat-pts (append flat-pts (list (car v) (cadr v)))))
  
  ;; 5. 객체 좌표 업데이트
  (setq vla-target (vlax-ename->vla-object target-ent))
  (vlax-put-property vla-target 'Coordinates 
    (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length flat-pts)))) flat-pts))
  )

  ;; 6. 마무리
  (if is-temp-ref (entdel ref-ent))
  (setvar "CMDECHO" old-cmdecho)
  (vla-EndUndoMark doc)
  (princ "\n수정이 완료되었습니다.")
  (princ)
)

;; ==========================================
;; [3] 명령어 정의
;; ==========================================

;; 시계 방향 모드 (둘 다 CW)
(defun C:REFPOLY_CW ()
  (fn:refpoly-engine "시계 방향(CW)" 'util:ensure-clockwise 'util:ensure-clockwise)
)

;; 혼합 모드 (기준 CCW, 대상 CW)
(defun C:REFPOLY_CCW ()
  (fn:refpoly-engine "혼합(기준CCW, 대상CW)" 'util:ensure-counter-clockwise 'util:ensure-clockwise)
)

(princ "\n통합 REFPOLY 도구 로드 완료.")
(princ)
