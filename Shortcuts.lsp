;;; Shortcuts.lsp
;;; 지연 로딩(Lazy Loading) 방식의 단축 명령어 설정

(vl-load-com)

;; [지연 로딩 유틸리티]
(defun util:lazy-load (file-name cmd-sym / full-path)
  ;; 1. 파일 찾기 (직접 또는 lisp-src/ 경로 추가)
  (setq full-path (findfile file-name))
  (if (not full-path)
    (setq full-path (findfile (strcat "lisp-src/" file-name)))
  )

  ;; 2. 파일 로드
  (if (not (eval cmd-sym))
    (if full-path
      (load full-path)
      (princ (strcat "\n오류: '" file-name "' 파일을 찾을 수 없습니다. (지원 경로 확인 요망)"))
    )
  )

  ;; 3. 명령어 실행
  (if (eval cmd-sym)
    (apply (eval cmd-sym) nil)
    (princ (strcat "\n오류: '" (vl-princ-to-string cmd-sym) "' 명령어를 실행할 수 없습니다."))
  )
  (princ)
)

;; 1. REFPOLY 관련
(defun C:F2P () (util:lazy-load "lisp-src/REFPOLY.lsp" 'c:REFPOLY_CW))
(defun C:F3P () (util:lazy-load "lisp-src/REFPOLY.lsp" 'c:REFPOLY_CCW))

;; 2. ODLabel 관련
(defun C:ODL () (util:lazy-load "lisp-src/ODLabel.lsp" 'c:ODLABEL))

;; 3. AreaAdjust 관련
(defun C:AFO  () (util:lazy-load "lisp-src/AreaAdjust.lsp" 'c:AREA_ADJUST))
(defun C:AFO2 () (util:lazy-load "lisp-src/AreaAdjust.lsp" 'c:AREA_ADJUST_FIXED))

;; 4. 유틸리티 관련
(defun C:PNC  () (util:lazy-load "lisp-src/ParcelSplit.lsp" 'c:PARCEL_SPLIT))
(defun C:WD5 () (util:lazy-load "lisp-src/MapIndex.lsp" 'c:MAPINDEX_500))
(defun C:WD10() (util:lazy-load "lisp-src/MapIndex.lsp" 'c:MAPINDEX_1000))
(defun C:INC  () (util:lazy-load "lisp-src/IncrementNumber.lsp" 'c:INCREMENTNUMBER))
(defun C:OB   () (util:lazy-load "lisp-src/OuterBoundary.lsp" 'c:OUTERBOUNDARY))
(defun C:A2P  () (util:lazy-load "lisp-src/ArcToPolyline.lsp" 'c:ARCTOPOLYLINE))
(defun C:OSA2 () (util:lazy-load "lisp-src/CoordRound.lsp" 'c:OSA2))
(defun C:OSA3 () (util:lazy-load "lisp-src/CoordRound.lsp" 'c:OSA3))
(defun C:VAD  () (util:lazy-load "lisp-src/VertexEdit.lsp" 'c:VERTEX_ADD))
(defun C:VDE  () (util:lazy-load "lisp-src/VertexEdit.lsp" 'c:VERTEX_DEL))

;; 5. 도움말 명령어
(defun C:APPHELP ()
  (princ "\n============================================")
  (princ "\n [CAD 3rd Party Tools] ")
  (princ "\n - Version: 1.0.4 (2026-04-27)")
  (princ "\n - Developer: LX Kim Byoung-woo")
  (princ "\n============================================")
  (princ "\n  F2P  - REFPOLY_CW - 시계 방향(CW) 구간 교체")
  (princ "\n  F3P  - REFPOLY_CCW - 반시계 방향(CCW) 구간 교체")
  (princ "\n  ODL  - ODLABEL - OD 데이터 레이블 생성")
  (princ "\n  AFO  - AREA_ADJUST - 면적 정밀 조정 (구간 이동)")
  (princ "\n  AFO2 - AREA_ADJUST_FIXED - 면적 정밀 조정 (고정점 유지)")
  (princ "\n  PNC  - PARCEL_SPLIT - 지번 레이어 분해 및 분리")
  (princ "\n  WD5  - MAPINDEX_500 - 도곽 생성 (축척 1:500)")
  (princ "\n  WD10 - MAPINDEX_1000 - 도곽 생성 (축척 1:1000)")
  (princ "\n  INC  - INCREMENTNUMBER - 숫자 자동 증가 입력")
  (princ "\n  OB   - OUTERBOUNDARY - 외곽선 추출")
  (princ "\n  A2P  - ARCTOPOLYLINE - 호(Arc)를 선분 폴리라인으로 변환")
  (princ "\n  OSA2 - OSA2 - 좌표 오사오입 재결정 (소수 2자리)")
  (princ "\n  OSA3 - OSA3 - 좌표 오사오입 재결정 (소수 3자리)")
  (princ "\n  VAD  - VERTEX_ADD - 정점 추가")
  (princ "\n  VDE  - VERTEX_DEL - 정점 삭제")
  (princ "\n--------------------------------------------")
  (princ "\n* 모든 기능은 첫 실행 시 자동으로 로드됩니다.")
  (princ)
)

(princ "\n모든 기능이 로드되었습니다. 도움말은 'APPHELP'를 입력하세요.")
(princ)
