;;; OuterBoundary.lsp
;;; 선택된 객체(라인, 폴리라인)로 둘러싸인 영역의 최외곽선을 폴리라인으로 생성
;;; AutoCAD 2013 & Windows 11 환경 최적화 (프리징 방지)

(vl-load-com)

;; [Command Wrapper]
(defun C:OUTERBOUND (/ ss result)
  (princ "\n외곽선을 추출할 라인 또는 폴리라인을 선택하세요.")
  (setq ss (ssget '((0 . "LINE,LWPOLYLINE,POLYLINE"))))
  (if ss
    (if (setq result (fn:outerbound ss))
      (princ "\n성공: 최외곽 폴리라인이 생성되었습니다.")
      (princ "\n오류: 외곽선 생성에 실패했습니다.")
    )
    (princ "\n선택된 객체가 없습니다.")
  )
  (princ)
)

;; [Core Function]
;; ss: selection set of lines/polylines
;; returns: ename of the final polyline or nil
(defun fn:outerbound (ss / *error* acadObj doc fuzz old-cmdecho regionSS finalRegion explodedSS resultSS finalPoly)
  (setq fuzz 0.0005)
  (setq acadObj (vlax-get-acad-object))
  (setq doc (vla-get-ActiveDocument acadObj))
  
  (defun *error* (msg)
    (vla-EndUndoMark doc)
    (command "_.undo" "1")
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (princ (strcat "\n오류 발생: " msg))
    nil
  )

  (vla-StartUndoMark doc)
  (setq old-cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  (command "_.region" ss "")
  (setq regionSS (ssget "_P" '((0 . "REGION"))))
  
  (if (not regionSS)
    (progn (vla-EndUndoMark doc) (command "_.undo" "1") (setvar "CMDECHO" old-cmdecho) nil)
    (progn
      (if (> (sslength regionSS) 1)
        (command "_.union" regionSS "")
      )
      (setq finalRegion (entlast))
      (command "_.explode" finalRegion)
      (setq explodedSS (ssget "_P"))
      (setvar "PEDITACCEPT" 1)
      (command "_.pedit" "_m" explodedSS "" "_j" fuzz "")
      (setq resultSS (ssget "_P" '((0 . "*POLYLINE"))))
      
      (if (and resultSS (= (sslength resultSS) 1))
        (setq finalPoly (ssname resultSS 0))
        (setq finalPoly nil)
      )
      
      (if (not finalPoly)
        (progn (vla-EndUndoMark doc) (command "_.undo" "1") (setvar "CMDECHO" old-cmdecho) nil)
        (progn (vla-EndUndoMark doc) (setvar "CMDECHO" old-cmdecho) finalPoly)
      )
    )
  )
)

(princ "\n외곽선 추출 도구 로드 완료. 명령어: 'OUTERBOUND'")
(princ)
