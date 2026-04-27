;;; REFPOLY.lsp
;;; 폴리라인 방향 정렬 및 구간 교체
;;; AutoCAD 2013 & Windows 11 환경 최적화

(vl-load-com)
(if (not fn:outerbound) (load "OuterBoundary.lsp"))

;; ==========================================
;; [1] 공통 유틸리티 함수 (util:)
;; ==========================================

;; LWPOLYLINE 정점 좌표 리스트 추출
(defun util:get-vertices (ent / pts)
  (foreach x (entget ent)
    (if (= (car x) 10)
      (setq pts (cons (cdr x) pts))
    )
  )
  (reverse pts)
)

;; CW 기준 부호 면적 계산 (시계 방향 +)
(defun util:get-signed-area (pts / area p1 p2)
  (setq area 0.0)
  (setq pts (append pts (list (car pts))))

  (while (and (setq p1 (car pts)) (setq p2 (cadr pts)))
    (setq area (+ area (* (- (car p2) (car p1)) (+ (cadr p2) (cadr p1)))))
    (setq pts (cdr pts))
  )
  (* 0.5 area)
)

;; 방향 정규화: 시계 / 반시계
(defun util:ensure-clockwise (pts)
  (if (< (util:get-signed-area pts) 0)
    (reverse pts)
    pts
  )
)

(defun util:ensure-counter-clockwise (pts)
  (if (> (util:get-signed-area pts) 0)
    (reverse pts)
    pts
  )
)

;; 리스트 순서 기준으로 idx1 -> idx2 구간 추출
(defun util:get-segment-by-list-order (pts idx1 idx2 / n res i)
  (setq n (length pts))
  (setq res nil)
  (setq i idx1)

  (while (/= i idx2)
    (setq res (cons (nth i pts) res))
    (setq i (rem (1+ i) n))
  )

  (setq res (cons (nth idx2 pts) res))
  (reverse res)
)

;; 점(pt)에 가장 가까운 정점 인덱스 찾기
(defun util:refpoly-get-nearest-vertex-idx (pt pts / min-dist res-idx i d)
  (setq i 0)
  (setq min-dist 1e9)
  (setq res-idx -1)

  (foreach v pts
    (setq d (distance pt v))
    (if (< d min-dist)
      (progn
        (setq min-dist d)
        (setq res-idx i)
      )
    )
    (setq i (1+ i))
  )
  res-idx
)

;; ==========================================
;; [2] 핵심 로직 엔진 (fn:)
;; ==========================================

(defun fn:refpoly-engine (mode-name target-norm-fn ref-norm-fn /
                          *error* doc old-osmode ok
                          target-ent ref-ent
                          target-pts ref-pts
                          ss-ref
                          p1 p2 q1 q2
                          idxP1 idxP2 idxQ1 idxQ2
                          idxP1-prev idxP2-next
                          seg-q rem-p new-pts
                          flat-pts vla-target)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq old-osmode (getvar "OSMODE"))

  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\n오류: " msg))
    )
    (setvar "OSMODE" old-osmode)
    (vla-EndUndoMark doc)
    (princ)
  )

  (vla-StartUndoMark doc)
  (setq ok T)

  (princ (strcat "\n[" mode-name " 시작]"))

  ;; 1) 기준 폴리라인 선택
  (setq target-ent (car (entsel "\n기준 폴리라인 선택: ")))
  (if (or (not target-ent) (/= (cdr (assoc 0 (entget target-ent))) "LWPOLYLINE"))
    (progn
      (princ "\n오류: LWPOLYLINE을 선택하세요.")
      (setq ok nil)
    )
  )

  ;; 2) 참조 영역 선택 후 외곽선 생성
  (if ok
    (progn
      (princ "\n참조 영역 선택: ")
      (setq ss-ref (ssget))
      (if (not ss-ref)
        (progn
          (princ "\n오류: 참조할 객체가 없습니다.")
          (setq ok nil)
        )
      )
    )
  )

  (if ok
    (progn
      (setq ref-ent (fn:outerbound ss-ref))
      (if (not ref-ent)
        (progn
          (princ "\n오류: 외곽선을 생성할 수 없습니다.")
          (setq ok nil)
        )
      )
    )
  )

  ;; 3) 방향 정규화
  (if ok
    (progn
      (setq ref-pts (apply ref-norm-fn (list (util:get-vertices ref-ent))))
      (setq target-pts (apply target-norm-fn (list (util:get-vertices target-ent))))

      ;; 4) 구간 대응점 입력
      (setvar "OSMODE" 1)
      (setq p1 (getpoint "\nP1 클릭: "))
      (setq q1 (getpoint "\nQ1 클릭: "))
      (setq p2 (getpoint "\nP2 클릭: "))
      (setq q2 (getpoint "\nQ2 클릭: "))
      (setvar "OSMODE" old-osmode)

      (if (and p1 q1 p2 q2)
        (progn
          ;; 5) 대응 인덱스 계산
          (setq idxP1 (util:refpoly-get-nearest-vertex-idx p1 target-pts))
          (setq idxQ1 (util:refpoly-get-nearest-vertex-idx q1 ref-pts))
          (setq idxP2 (util:refpoly-get-nearest-vertex-idx p2 target-pts))
          (setq idxQ2 (util:refpoly-get-nearest-vertex-idx q2 ref-pts))

          ;; 6) 참조 구간(seg-q) + 기준 잔여 구간(rem-p) 결합
          (setq seg-q (util:get-segment-by-list-order ref-pts idxQ1 idxQ2))
          (setq idxP1-prev (if (= idxP1 0) (1- (length target-pts)) (1- idxP1)))
          (setq idxP2-next (rem (1+ idxP2) (length target-pts)))
          (setq rem-p (util:get-segment-by-list-order target-pts idxP2-next idxP1-prev))
          (setq new-pts (append rem-p seg-q))

          ;; 7) 좌표 치환
          (setq vla-target (vlax-ename->vla-object target-ent))
          (setq flat-pts nil)
          (foreach v new-pts
            (setq flat-pts (append flat-pts (list (car v) (cadr v))))
          )

          (vlax-put vla-target 'Coordinates
            (vlax-make-variant
              (vlax-safearray-fill
                (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length flat-pts))))
                flat-pts
              )
            )
          )

          (princ "\n교체 완료.")
        )
      )
    )
  )

  (setvar "OSMODE" old-osmode)
  (vla-EndUndoMark doc)
  (princ)
)
;; ==========================================
;; [3] 실행 명령어
;; ==========================================

(defun C:REFPOLY_CW ()
  (fn:refpoly-engine "시계(CW)" 'util:ensure-clockwise 'util:ensure-clockwise)
)

(defun C:REFPOLY_CCW ()
  (fn:refpoly-engine "반시계(CCW)" 'util:ensure-counter-clockwise 'util:ensure-clockwise)
)

(princ "\n폴리라인 방향 정렬 로드 완료.")
(princ)


