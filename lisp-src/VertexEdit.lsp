;;; 정점 추가 및 삭제 도구 (VertexEdit)
;;; AutoCAD Map 3D 2013 및 Windows 11 환경 최적화
;;; 선택된 객체의 정점을 직접 추가하거나 삭제합니다.
;;; 
;;; [사용자 요청 예외]:
;;; - Rule 3(원본 보존) 대신 객체를 즉시 수정하도록 구현됨.
;;; - 모든 상호작용은 명령행 프롬프트 사용.

(vl-load-com)

;; ==========================================
;; [1] 정점 추가 (C:VERTEX_ADD)
;; ==========================================

(defun C:VERTEX_ADD (/ *error* ent data type p p_on_curve param idx coords new_coords i vla_obj acDoc old_cmdecho)
  (setq acDoc (vla-get-activedocument (vlax-get-acad-object)))
  (vla-startundomark acDoc)

  ;; 에러 핸들러
  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\n오류: " msg))
    )
    (if old_cmdecho (setvar "CMDECHO" old_cmdecho))
    (vla-endundomark acDoc)
    (princ)
  )

  (setq old_cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  (princ "\n정점 추가 도구 [VA]")
  
  (setq ent (car (entsel "\n수정할 객체(Line/LWPolyline) 선택: ")))
  (if (not ent) (progn (princ "\n선택된 객체가 없습니다.") (exit)))

  (setq data (entget ent))
  (setq type (cdr (assoc 0 data)))

  ;; 1. Line인 경우 LWPolyline으로 변환
  (if (= type "LINE")
    (progn
      (command "_.pedit" ent "_Y" "_X")
      (setq ent (entlast))
      (setq type "LWPOLYLINE")
    )
  )

  (if (/= type "LWPOLYLINE")
    (progn (princ "\n지원하지 않는 객체 타입입니다.") (exit))
  )

  (setq vla_obj (vlax-ename->vla-object ent))

  ;; 2. 연속 정점 추가 루프
  (while (setq p (getpoint "\n추가할 정점 위치 클릭 (종료: Enter): "))
    (setq p_on_curve (vlax-curve-getClosestPointTo vla_obj p))
    (setq param (vlax-curve-getParamAtPoint vla_obj p_on_curve))
    
    ;; 삽입될 인덱스 계산 (param이 1.5이면 2번 인덱스에 삽입)
    (setq idx (fix (1+ param)))
    
    (setq coords (vlax-get vla_obj 'Coordinates))
    
    ;; 새로운 좌표 리스트 생성
    (setq new_coords nil)
    (setq i 0)
    (repeat (/ (length coords) 2)
      (if (= i idx)
        (setq new_coords (append new_coords (list (car p_on_curve) (cadr p_on_curve))))
      )
      (setq new_coords (append new_coords (list (nth (* i 2) coords) (nth (1+ (* i 2)) coords))))
      (setq i (1+ i))
    )
    
    ;; 마지막에 추가되는 경우 처리
    (if (>= idx (/ (length coords) 2))
      (setq new_coords (append new_coords (list (car p_on_curve) (cadr p_on_curve))))
    )

    (vlax-put vla_obj 'Coordinates new_coords)
    (princ "\n정점이 추가되었습니다.")
  )

  (setvar "CMDECHO" old_cmdecho)
  (vla-endundomark acDoc)
  (princ "\n정점 추가를 종료합니다.")
  (princ)
)

;; ==========================================
;; [2] 정점 삭제 (C:VERTEX_DEL)
;; ==========================================

(defun C:VERTEX_DEL (/ *error* ent data type p coords new_coords i dist min_dist min_idx vla_obj acDoc old_osmode old_cmdecho pt)
  (setq acDoc (vla-get-activedocument (vlax-get-acad-object)))
  (vla-startundomark acDoc)

  ;; 에러 핸들러
  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\n오류: " msg))
    )
    (if old_osmode (setvar "OSMODE" old_osmode))
    (if old_cmdecho (setvar "CMDECHO" old_cmdecho))
    (vla-endundomark acDoc)
    (princ)
  )

  (setq old_osmode (getvar "OSMODE"))
  (setq old_cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 1) ;; Endpoint OSNAP 활성화

  (princ "\n정점 삭제 도구 [VD]")

  (setq ent (car (entsel "\n수정할 LWPolyline 선택: ")))
  (if (not ent) (progn (princ "\n선택된 객체가 없습니다.") (exit)))

  (setq data (entget ent))
  (setq type (cdr (assoc 0 data)))

  (if (/= type "LWPOLYLINE")
    (progn (princ "\nLWPolyline만 지원합니다.") (exit))
  )

  (setq vla_obj (vlax-ename->vla-object ent))

  ;; 2. 연속 정점 삭제 루프
  (while (setq p (getpoint "\n삭제할 정점 클릭 (종료: Enter): "))
    (setq coords (vlax-get vla_obj 'Coordinates))
    
    ;; 최소 거리 정점 탐색
    (setq min_dist 1e9)
    (setq min_idx -1)
    (setq i 0)
    (repeat (/ (length coords) 2)
      (setq pt (list (nth (* i 2) coords) (nth (1+ (* i 2)) coords)))
      (setq dist (distance (list (car p) (cadr p)) pt))
      (if (< dist min_dist)
        (setq min_dist dist min_idx i)
      )
      (setq i (1+ i))
    )

    ;; Tolerance 0.005 체크
    (if (<= min_dist 0.005)
      (progn
        ;; 정점이 2개 이하이면 삭제 불가
        (if (<= (/ (length coords) 2) 2)
          (princ "\n오류: 정점이 2개 이하인 객체는 정점을 삭제할 수 없습니다.")
          (progn
            (setq new_coords nil)
            (setq i 0)
            (repeat (/ (length coords) 2)
              (if (/= i min_idx)
                (setq new_coords (append new_coords (list (nth (* i 2) coords) (nth (1+ (* i 2)) coords))))
              )
              (setq i (1+ i))
            )
            (vlax-put vla_obj 'Coordinates new_coords)
            (princ (strcat "\n" (itoa (1+ min_idx)) "번 정점이 삭제되었습니다."))
          )
        )
      )
      (princ "\n일치하는 정점을 찾지 못했습니다. (Tolerance: 0.005)")
    )
  )

  (setvar "OSMODE" old_osmode)
  (setvar "CMDECHO" old_cmdecho)
  (vla-endundomark acDoc)
  (princ "\n정점 삭제를 종료합니다.")
  (princ)
)

(princ "\n정점 편집 도구 로드 완료.")
(princ)
