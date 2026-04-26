;;; Shortcuts.lsp
;;; 지연 로딩(Lazy Loading) 방식의 단축 명령어 설정

(vl-load-com)

;; [지연 로딩 유틸리티]
;; 캐드 지원 폴더(Support Path)에 파일이 있는 경우 파일명만으로 로드합니다.
(defun util:lazy-load (file-name cmd-sym)
  (if (not (eval cmd-sym))
    (progn
      (if (findfile file-name)
        (load file-name)
        (princ (strcat "\n오류: 지원 폴더에서 '" file-name "' 파일을 찾을 수 없습니다."))
      )
    )
  )
  ;; 로드 후 명령어가 존재하면 실행
  (if (eval cmd-sym)
    (apply (eval cmd-sym) nil)
    (princ (strcat "\n오류: '" (vl-princ-to-string cmd-sym) "' 명령어를 실행할 수 없습니다."))
  )
  (princ)
)

;; 1. REFPOLY 관련
(defun C:F2P () (util:lazy-load "REFPOLY.lsp" 'c:REFPOLY_CW))
(defun C:F3P () (util:lazy-load "REFPOLY.lsp" 'c:REFPOLY_CCW))

;; 2. ODLabel 관련
(defun C:ODL () (util:lazy-load "ODLabel.lsp" 'c:ODLABEL))

;; 3. AreaAdjust 관련
(defun C:AFO  () (util:lazy-load "AreaAdjust.lsp" 'c:AREA_ADJUST))
(defun C:AFO2 () (util:lazy-load "AreaAdjust.lsp" 'c:AREA_ADJUST_FIXED))

;; 4. 유틸리티 관련
(defun C:PS   () (util:lazy-load "ParcelSplit.lsp" 'c:PARCEL_SPLIT))
(defun C:WD500 () (util:lazy-load "MapIndex.lsp" 'c:WD500))
(defun C:WD1000() (util:lazy-load "MapIndex.lsp" 'c:WD1000))
(defun C:INC  () (util:lazy-load "IncrementNumber.lsp" 'c:INCREMENTNUMBER))
(defun C:OB   () (util:lazy-load "OuterBoundary.lsp" 'c:OUTERBOUNDARY))

;; 5. 도움말 명령어
(defun C:APPHELP ()
  (princ "\n============================================")
  (princ "\n [CAD 3rd Party Tools] ")
  (princ "\n - Version: 1.2.1 (2026-04-26)")
  (princ "\n - Developer: LX Kim Byoung-woo")
  (princ "\n============================================")
  (princ "\n  F2P  - REFPOLY_CW - 시계 방향(CW) 구간 교체")
  (princ "\n  F3P  - REFPOLY_CCW - 반시계 방향(CCW) 구간 교체")
  (princ "\n  ODL  - ODLABEL - OD 데이터 레이블 생성")
  (princ "\n  AFO  - AREA_ADJUST - 면적 정밀 조정 (구간 이동)")
  (princ "\n  AFO2 - AREA_ADJUST_FIXED - 면적 정밀 조정 (고정점 유지)")
  (princ "\n  PS   - PARCEL_SPLIT - 지번 레이어 분해 및 분리")
  (princ "\n  WD500 - WD500 - 도곽 생성 (축척 1:500)")
  (princ "\n  WD1000 - WD1000 - 도곽 생성 (축척 1:1000)")
  (princ "\n  INC  - INCREMENTNUMBER - 숫자 자동 증가 입력")
  (princ "\n  OB   - OUTERBOUNDARY - 외곽선 추출")
  (princ "\n--------------------------------------------")
  (princ "\n* 모든 기능은 첫 실행 시 자동으로 로드됩니다.")
  (princ)
)

(princ "\n모든 기능이 로드되었습니다. 도움말은 'APPHELP'를 입력하세요.")
(princ)
