;;; Shortcuts.lsp
;;; 지연 로딩(Lazy Loading) 방식의 단축 명령어 설정

(vl-load-com)

;; ==========================================
;; [1] 지연 로딩 유틸리티 (util:)
;; ==========================================

;; 명령어 호출 시점에 대상 파일을 로드하고, 실제 명령을 실행
(defun util:lazy-load (file-name cmd-sym / full-path)
  (setq full-path (findfile file-name))
  (if (not full-path) (setq full-path (findfile (strcat "lisp-src/" file-name))))
  
  (if (not (eval cmd-sym))
    (if full-path
      (load full-path)
      (princ (strcat "\n오류: '" file-name "' 파일을 찾을 수 없습니다."))
    )
  )

  (if (eval cmd-sym)
    (apply (eval cmd-sym) nil)
    (princ (strcat "\n오류: '" (vl-princ-to-string cmd-sym) "' 명령어를 실행할 수 없습니다."))
  )
  (princ)
)

;; ==========================================
;; [2] 명령어 단축키 정의
;; ==========================================

(defun C:F2P  () (util:lazy-load "REFPOLY.lsp"         'c:REFPOLY_CW))
(defun C:F3P  () (util:lazy-load "REFPOLY.lsp"         'c:REFPOLY_CCW))
(defun C:AFO  () (util:lazy-load "AreaAdjust.lsp"      'c:AREA_ADJUST))
(defun C:AFO2 () (util:lazy-load "AreaAdjust.lsp"      'c:AREA_ADJUST_FIXED))
(defun C:PNC  () (util:lazy-load "ParcelSplit.lsp"     'c:PNC))
(defun C:WD5  () (util:lazy-load "MapIndex.lsp"        'c:MAPINDEX_500))
(defun C:WD10 () (util:lazy-load "MapIndex.lsp"        'c:MAPINDEX_1000))
(defun C:INC  () (util:lazy-load "IncrementNumber.lsp" 'c:INCNUM))
(defun C:OB   () (util:lazy-load "OuterBoundary.lsp"   'c:OUTERBOUND))
(defun C:A2P  () (util:lazy-load "ArcToPolyline.lsp"   'c:ARCTOPOLYLINE))
(defun C:OSA2 () (util:lazy-load "CoordRound.lsp"      'c:COORDROUND_OSA2))
(defun C:OSA3 () (util:lazy-load "CoordRound.lsp"      'c:COORDROUND_OSA3))
(defun C:VAD  () (util:lazy-load "VertexEdit.lsp"      'c:VERTEX_ADD))
(defun C:VDE  () (util:lazy-load "VertexEdit.lsp"      'c:VERTEX_DEL))
(defun C:ODL  () (util:lazy-load "ODLabel.lsp"         'c:ODLABEL))

;; ==========================================
;; [3] 도움말 시스템
;; ==========================================

(defun C:APPHELP ()
  (princ "\n============================================")
  (princ "\n AutoCAD 3rd Party 도구 모음")
  (princ "\n - Version: 1.0.10 (2026-04-28)")
  (princ "\n - Developer: LX Kim Byoung-woo")
  (princ "\n============================================")
  (princ "\n  F2P/F3P   - 폴리라인 방향 정렬 (CW/CCW)")
  (princ "\n  AFO/AFO2  - 면적 정밀 조정")
  (princ "\n  PNC       - 지번 레이어 분해")
  (princ "\n  WD5/WD10  - 도곽 생성 (500/1000)")
  (princ "\n  OSA2/OSA3 - 좌표 오사오입 재결정")
  (princ "\n  INC       - 연속번호 생성")
  (princ "\n  OB        - 외곽선 생성")
  (princ "\n  A2P       - 호를 폴리라인으로 변환")
  (princ "\n  VAD/VDE   - 정점 추가/삭제")
  (princ "\n  ODL       - 레이블 생성")
  (princ "\n--------------------------------------------")
  (princ "\n* 모든 기능은 첫 실행 시 자동으로 로드됩니다.")
  (princ "\n============================================")
  (princ)
)

(princ "\n단축 명령어 시스템 로드 완료.")
(princ)
