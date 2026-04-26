;;; AreaAdjust.lsp
;;; 지적 공차면적 기준 통합 면적 조정 도구 (이동형 & 고정형)
;;; AutoCAD 2013 & Windows 11 환경 최적화

(vl-load-com)

;; ==========================================
;; [1] 공통 유틸리티 및 수식 함수
;; ==========================================

;; 정점 추출
(defun util:get-vertices (ent / pts)
  (foreach x (entget ent) (if (= (car x) 10) (setq pts (cons (cdr x) pts))))
  (reverse pts)
)

;; CW 면적 계산 (양수 반환)
(defun util:get-signed-area (pts / area p1 p2)
  (setq area 0.0)
  (setq pts (append pts (list (car pts))))
  (while (and (setq p1 (car pts)) (setq p2 (cadr pts)))
    (setq area (+ area (* (- (car p2) (car p1)) (+ (cadr p2) (cadr p1)))))
    (setq pts (cdr pts))
  )
  (* 0.5 area)
)

;; 시계 방향 강제 정렬
(defun util:ensure-clockwise (pts)
  (if (< (util:get-signed-area pts) 0) (reverse pts) pts)
)

;; 공차 면적 공식: F = 0.026^2 * M * sqrt(S)
(defun util:calc-tolerance (s scale / m f)
  (setq m scale f (* (* 0.026 0.026) m (sqrt s)))
  (atof (rtos f 2 3))
)

;; 입력 파싱 및 목표 면적 산출
(defun util:parse-target (current-area input / prefix val scale reg-area tol-area target)
  (setq input (strcase (vl-string-trim " " input)) prefix (substr input 1 1))
  (cond
    ((= prefix "T") (setq target (atof (substr input 2))))
    ((and (= prefix "D") (/= (substr input 2 1) "-")) (setq target (+ current-area (atof (substr input 2)))))
    ((and (= prefix "D") (= (substr input 2 1) "-")) (setq target (- current-area (atof (substr input 3)))))
    ((= prefix "@") (setq reg-area (atof (substr input 2)) scale 6000))
    ((= prefix "#") (setq reg-area (atof (substr input 2)) scale 1000))
    ((numberp (read input)) (setq reg-area (atof input) scale 1200))
  )
  (if (and reg-area (not target))
    (progn
      (setq tol-area (util:calc-tolerance reg-area scale))
      (if (>= current-area reg-area) (setq target (+ reg-area tol-area -1.0)) (setq target (+ (- reg-area tol-area) 1.0)))
    )
  )
  target
)

;; 두 직선의 교차점
(defun util:intersect-lines (p1 p2 p3 p4 / x1 y1 x2 y2 x3 y3 x4 y4 den t-num)
  (setq x1 (car p1) y1 (cadr p1) x2 (car p2) y2 (cadr p2)
        x3 (car p3) y3 (cadr p3) x4 (car p4) y4 (cadr p4))
  (setq den (- (* (- x1 x2) (- y3 y4)) (* (- y1 y2) (- x3 x4))))
  (if (not (equal den 0.0 1e-9))
    (progn
      (setq t-num (- (* (- x1 x3) (- y3 y4)) (* (- y1 y3) (- x3 x4))))
      (list (+ x1 (* (/ t-num den) (- x2 x1))) (+ y1 (* (/ t-num den) (- y2 y1))))
    )
    nil
  )
)

;; 최접점 정점 인덱스
(defun util:get-nearest-vertex-idx (pt pts fuzz / idx min-dist res-idx i d)
  (setq i 0 min-dist 1e9 res-idx -1)
  (foreach v pts (setq d (distance pt v)) (if (< d min-dist) (setq min-dist d res-idx i)) (setq i (1+ i)))
  res-idx
)

;; 인덱스가 idx1과 idx2 사이에 있는지 확인
(defun util:is-between-indices (i idx1 idx2 n)
  (if (< idx1 idx2) (and (> i idx1) (< i idx2)) (or (> i idx1) (< i idx2)))
)

;; 루프 매크로 대용
(defmacro loop-seg (&rest body) `(let ((continue T)) (while continue ,@body)))

;; ==========================================
;; [2-A] 엔진 1: 구간 이동 방식 (P1, P2 이동)
;; ==========================================

(defun fn:adjust-area-move (pts-list idx1 idx2 target-area / 
                            pts n i p1 p2 p-prev p-next seg-pts seg-len offset-dist
                            dx dy v-inward new-seg-pts sub-pts iter current-area)
  (setq iter 0 current-area (util:get-signed-area pts-list) n (length pts-list))
  (while (and (< iter 30) (> (abs (- target-area current-area)) 0.01))
    (setq seg-len 0.0 i idx1)
    (loop-seg
      (setq p1 (nth i pts-list) p2 (nth (rem (1+ i) n) pts-list))
      (setq seg-len (+ seg-len (distance p1 p2)))
      (if (= i idx2) (setq continue nil) (setq i (rem (1+ i) n)))
    )
    (setq offset-dist (/ (- target-area current-area) seg-len -1.0))
    (setq idx-prev (if (= idx1 0) (1- n) (1- idx1)) idx-next (rem (1+ idx2) n))
    (setq p-prev (nth idx-prev pts-list) p-next (nth idx-next pts-list))
    (setq new-seg-pts nil i idx1)
    (loop-seg
      (setq p1 (nth i pts-list) p2 (nth (rem (1+ i) n) pts-list) d-val (max 1e-9 (distance p1 p2)))
      (setq v-inward (list (/ (- (cadr p2) (cadr p1)) d-val) (/ (- (car p1) (car p2)) d-val)))
      (setq new-seg-pts (append new-seg-pts (list (list (+ (car p1) (* offset-dist (car v-inward))) (+ (cadr p1) (* offset-dist (cadr v-inward)))))))
      (if (= i idx2) (setq continue nil) (setq i (rem (1+ i) n)))
    )
    (setq p2-orig (nth idx2 pts-list)
          new-p2 (list (+ (car p2-orig) (* offset-dist (car v-inward))) (+ (cadr p2-orig) (* offset-dist (cadr v-inward)))))
    (setq new-seg-pts (append new-seg-pts (list new-p2)))
    (setq p1-adj (util:intersect-lines p-prev (nth idx1 pts-list) (car new-seg-pts) (cadr new-seg-pts))
          p-last (last new-seg-pts) p-last-1 (nth (- (length new-seg-pts) 2) new-seg-pts)
          p2-adj (util:intersect-lines (nth idx2 pts-list) p-next p-last p-last-1))
    (if (and p1-adj p2-adj)
      (progn
        (setq sub-pts (cdr (reverse (cdr (reverse new-seg-pts))))
              final-seg (append (list p1-adj) sub-pts (list p2-adj))
              head nil i 0)
        (while (< i idx1) (setq head (append head (list (nth i pts-list)))) (setq i (1+ i)))
        (setq tail nil i (1+ idx2))
        (while (< i n) (setq tail (append tail (list (nth i pts-list)))) (setq i (1+ i)))
        (setq pts-list (append head final-seg tail))
      )
    )
    (setq current-area (util:get-signed-area pts-list) iter (1+ iter))
  )
  pts-list
)

;; ==========================================
;; [2-B] 엔진 2: 고정점 방식 (P1, P2 유지)
;; ==========================================

(defun fn:adjust-area-fixed (pts-list idx1 idx2 target-area / 
                             pts n i p-chord1 p-chord2 chord-len v-inward offset-dist
                             new-list current-area iter mid-pt)
  (setq n (length pts-list) iter 0 current-area (util:get-signed-area pts-list))
  (if (= (rem (1+ idx1) n) idx2)
    (progn
      (setq p-chord1 (nth idx1 pts-list) p-chord2 (nth idx2 pts-list)
            mid-pt (list (* 0.5 (+ (car p-chord1) (car p-chord2))) (* 0.5 (+ (cadr p-chord1) (cadr p-chord2))))
            head (vl-subseq-custom pts-list 0 (1+ idx1))
            tail (vl-subseq-custom pts-list (1+ idx1) n)
            pts-list (append head (list mid-pt) tail)
            n (1+ n) idx2 (1+ idx2))
    )
  )
  (setq p-chord1 (nth idx1 pts-list) p-chord2 (nth idx2 pts-list) chord-len (max 1e-9 (distance p-chord1 p-chord2)))
  (setq v-inward (list (/ (- (cadr p-chord2) (cadr p-chord1)) chord-len) (/ (- (car p-chord1) (car p-chord2)) chord-len)))
  (while (and (< iter 30) (> (abs (- target-area current-area)) 0.01))
    (setq offset-dist (/ (- target-area current-area) (* 0.5 chord-len) -1.0)
          new-list nil i 0)
    (while (< i n)
      (setq p (nth i pts-list))
      (if (util:is-between-indices i idx1 idx2 n)
        (setq p (list (+ (car p) (* offset-dist (car v-inward))) (+ (cadr p) (* offset-dist (cadr v-inward)))))
      )
      (setq new-list (cons p new-list) i (1+ i))
    )
    (setq pts-list (reverse new-list) current-area (util:get-signed-area pts-list) iter (1+ iter))
  )
  pts-list
)

(defun vl-subseq-custom (lst start end / res i)
  (setq i 0 res nil)
  (while (and lst (< i end)) (if (>= i start) (setq res (cons (car lst) res))) (setq lst (cdr lst) i (1+ i)))
  (reverse res)
)

;; ==========================================
;; [3] 메인 명령어 및 통합 UI
;; ==========================================

(defun fn:area-adjust-main (mode-name engine-fn / *error* doc ent pts target-input target-area p1 p2 idx1 idx2 new-pts flat-pts vla-orig vla-ref final-area)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort"))) (princ (strcat "\n오류: " msg)))
    (vla-EndUndoMark doc) (princ)
  )
  (vla-StartUndoMark doc)
  (princ (strcat "\n[" mode-name " 모드 시작]"))
  (setq ent (car (entsel "\n조정할 폴리라인을 선택하세요: ")))
  (if (or (not ent) (/= (cdr (assoc 0 (entget ent))) "LWPOLYLINE"))
    (progn (princ "\n오류: LWPOLYLINE만 가능.") (exit))
  )
  (setq pts (util:ensure-clockwise (util:get-vertices ent))
        current-area (util:get-signed-area pts))
  (princ (strcat "\n현재 면적: " (rtos current-area 2 2)))
  (setq target-input (getstring T "\n목표 면적 입력 (예: 123, @100, #200, d10, t150): ")
        target-area (util:parse-target current-area target-input))
  (if (not target-area) (progn (princ "\n오류: 잘못된 입력.") (exit)))
  (princ (strcat "\n설정된 목표 면적: " (rtos target-area 2 2)))
  (setvar "OSMODE" 1)
  (setq p1 (getpoint "\n구간 시작점 P1 클릭: ") idx1 (util:get-nearest-vertex-idx p1 pts 0.001)
        p2 (getpoint "\n구간 끝점 P2 클릭: ") idx2 (util:get-nearest-vertex-idx p2 pts 0.001))
  (setvar "OSMODE" 0)
  (princ "\n연산 중...")
  (setq new-pts (apply engine-fn (list pts idx1 idx2 target-area)))
  (if new-pts
    (progn
      (setq vla-orig (vlax-ename->vla-object ent) vla-ref (vla-copy vla-orig) flat-pts nil)
      (foreach v new-pts (setq flat-pts (append flat-pts (list (car v) (cadr v)))))
      (vlax-put-property vla-ref 'Coordinates (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length flat-pts)))) flat-pts)))
      (vla-put-color vla-ref 3)
      (setq final-area (util:get-signed-area new-pts))
      (if (<= (abs (- target-area final-area)) 0.01)
        (princ (strcat "\n[완료] 녹색 ref_object 생성. 면적: " (rtos final-area 2 2)))
        (princ (strcat "\n[중단] 30회 초과. 녹색 ref_object 생성. 면적: " (rtos final-area 2 2) " (오차: " (rtos (abs (- target-area final-area)) 2 4) ")"))
      )
    )
  )
  (vla-EndUndoMark doc) (princ)
)

;; 명령어 1: 구간 이동 방식
(defun C:AREA_ADJUST () (fn:area-adjust-main "구간 이동" 'fn:adjust-area-move))

;; 명령어 2: 고정점 방식
(defun C:AREA_ADJUST_FIXED () (fn:area-adjust-main "고정점 유지" 'fn:adjust-area-fixed))

(princ "\n면적 정밀 조정 도구(통합) 로드 완료. 명령어: AREA_ADJUST, AREA_ADJUST_FIXED")
(princ)
