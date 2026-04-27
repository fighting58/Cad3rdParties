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
(defun fn:outerbound (ss / *error* acadObj doc fuzz old-cmdecho old-peditaccept regionSS finalRegion explodedSS resultSS finalPoly ok)
  (setq fuzz 0.0005)
  (setq acadObj (vlax-get-acad-object))
  (setq doc (vla-get-ActiveDocument acadObj))
  (setq old-cmdecho (getvar "CMDECHO"))
  (setq old-peditaccept (getvar "PEDITACCEPT"))

  (defun *error* (msg)
    (setvar "CMDECHO" old-cmdecho)
    (setvar "PEDITACCEPT" old-peditaccept)
    (vla-EndUndoMark doc)
    (command "_.undo" "1")
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\n오류 발생: " msg))
    )
    nil
  )

  (vla-StartUndoMark doc)
  (setvar "CMDECHO" 0)
  (setq ok T)
  (setq finalPoly nil)

  (command "_.region" ss "")
  (setq regionSS (ssget "_P" '((0 . "REGION"))))
  (if (not regionSS) (setq ok nil))

  (if ok
    (progn
      (if (> (sslength regionSS) 1)
        (command "_.union" regionSS "")
      )
      (setq finalRegion (entlast))
      (if finalRegion
        (command "_.explode" finalRegion)
        (setq ok nil)
      )
    )
  )

  (if ok
    (progn
      (setq explodedSS (ssget "_P"))
      (if explodedSS
        (progn
          (setvar "PEDITACCEPT" 1)
          (command "_.pedit" "_m" explodedSS "" "_j" fuzz "")
          (setq resultSS (ssget "_P" '((0 . "*POLYLINE"))))
          (if (and resultSS (= (sslength resultSS) 1))
            (setq finalPoly (ssname resultSS 0))
          )
        )
        (setq ok nil)
      )
    )
  )

  (if (not finalPoly)
    (progn
      (vla-EndUndoMark doc)
      (command "_.undo" "1")
    )
    (vla-EndUndoMark doc)
  )

  (setvar "CMDECHO" old-cmdecho)
  (setvar "PEDITACCEPT" old-peditaccept)
  finalPoly
)
(princ "\n외곽선 추출 도구 로드 완료.")
(princ)



