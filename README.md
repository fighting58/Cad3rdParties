# Cad3rdParties
AutoCAD Map 3D 2013 최적화 리습 도구 모음

## 개요
이 프로젝트는 AutoCAD Map 3D 2013 (Windows 11 환경)에서 발생할 수 있는 프리징 현상을 방지하고, 지적 측량 및 도면 작업의 효율성을 높이기 위해 개발된 리습(Lisp) 도구 모음입니다. 모든 도구는 명령행(Prompt) 인터페이스만을 사용하여 안정성을 확보했습니다.

## 주요 기능
- **REFPOLY**: 폴리라인의 방향을 시계(CW) 또는 반시계(CCW) 방향으로 정규화합니다.
- **ODLabel**: 객체 데이터(Object Data)를 추출하여 스마트한 위치와 각도로 레이블을 생성합니다.
- **AreaAdjust**: 지적 공차 공식을 적용하여 폴리라인의 면적을 정밀하게 조정합니다.
- **ParcelSplit**: 지번 레이어를 분석하여 본번/부번 지번 및 도곽 단위별로 분해합니다.
- **MapIndex**: 원점(200000, 600000) 기준으로 축척별(1:500, 1:1000) 도곽을 자동 생성합니다.
- **IncrementNumber**: 숫자를 자동으로 증가시키며 도면에 입력합니다.
- **OuterBoundary**: 선택한 여러 객체의 통합 외곽선을 추출합니다.
- **ArcToPolyline**: 호(Arc)를 현분 형태의 폴리라인으로 변환합니다. (분량, 중앙종거, 현 길이 옵션)
- **CoordRound**: 좌표를 오사오입(Round half to even) 규칙에 따라 정결합합니다.
- **VertexEdit**: 폴리라인의 정점을 직접 추가하거나 삭제합니다.

## 설치 및 사용법
1. 저장소의 모든 파일을 다운로드합니다.
2. AutoCAD의 `OPTIONS` -> `Files` -> `Support File Search Path`에 `lisp-src` 폴더를 추가합니다.
3. `Shortcuts.lsp` 파일을 `APPLOAD` 명령어로 로드합니다.
4. **`APPHELP`** 명령어를 입력하여 단축키 목록과 설명을 확인합니다.

## 단축 명령어 (Aliases)
- **F2P / F3P**: 폴리라인 방향 정규화 (CW / CCW)
- **ODL**: OD 데이터 레이블 생성
- **AFO / AFO2**: 면적 정밀 조정 (구간 이동 / 고정점 유지)
- **PNC**: 지번 데이터 분해 및 분리
- **WD5 / WD10**: 도곽 생성 (1:500 / 1:1000)
- **INC**: 숫자 자동 증가 입력
- **OB**: 외곽선 추출
- **A2P**: 호를 현분 폴리라인으로 변환
- **OSA2 / OSA3**: 좌표 오사오입 (소수 2자리 / 3자리)
- **VAD / VDE**: 정점 추가 / 삭제

## 정보
- **Version**: 1.0.4
- **Developer**: LX Kim Byoung-woo
- **Release Date**: 2026-04-27
