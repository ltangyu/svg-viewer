; ══════════════════════════════════════════════════════════════
; SVG Viewer — NSIS Installer Hooks
; Fixes Tauri bug #9803: missing Capabilities & RegisteredApplications
; Without these, the Windows "Open With" dialog loops infinitely.
; ══════════════════════════════════════════════════════════════

!macro CUSTOM_INSTALL
  ; ── Register Application ──
  WriteRegStr SHCTX "Software\Classes\Applications\svg-viewer.exe" "FriendlyAppName" "SVG Viewer"
  WriteRegStr SHCTX "Software\Classes\Applications\svg-viewer.exe\shell\open\command" "" '"$INSTDIR\svg-viewer.exe" "%1"'
  WriteRegStr SHCTX "Software\Classes\Applications\svg-viewer.exe\SupportedTypes" ".svg" ""

  ; ── Register Capabilities (THE FIX for Tauri #9803) ──
  WriteRegStr SHCTX "Software\SVGViewer\Capabilities" "ApplicationName" "SVG Viewer"
  WriteRegStr SHCTX "Software\SVGViewer\Capabilities" "ApplicationDescription" "Lightweight SVG Viewer with animation support"
  WriteRegStr SHCTX "Software\SVGViewer\Capabilities\FileAssociations" ".svg" "SVGViewer.svg"

  ; ── RegisteredApplications (required for Windows Default Apps) ──
  WriteRegStr SHCTX "Software\RegisteredApplications" "SVGViewer" "Software\SVGViewer\Capabilities"

  ; ── Add Content Type & PerceivedType ──
  WriteRegStr SHCTX "Software\Classes\.svg" "Content Type" "image/svg+xml"
  WriteRegStr SHCTX "Software\Classes\.svg" "PerceivedType" "image"
!macroend

!macro CUSTOM_UNINSTALL
  ; ── Clean up Capabilities ──
  DeleteRegKey SHCTX "Software\SVGViewer"
  DeleteRegValue SHCTX "Software\RegisteredApplications" "SVGViewer"

  ; ── Clean up Application registration ──
  DeleteRegKey SHCTX "Software\Classes\Applications\svg-viewer.exe"

  ; ── Remove Content Type & PerceivedType ──
  DeleteRegValue SHCTX "Software\Classes\.svg" "Content Type"
  DeleteRegValue SHCTX "Software\Classes\.svg" "PerceivedType"
!macroend
