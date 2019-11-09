import os, strformat

import glad/gl
import glfw
import nanovg

type TooltipState = enum
  tsOff, tsShowDelay, tsShow, tsFadeOutDelay, tsFadeOut

const
  TooltipShowDelay       = 0.2
  TooltipFadeOutDelay    = 0.2
  TooltipFadeOutDuration = 0.3

type UIState = object
  mx:         float
  my:         float
  mbLeft:     bool
  mbRight:    bool
  mbMid:      bool
  hotItem:    int
  activeItem: int

  tooltipState:     TooltipState
  lastTooltipState: TooltipState
  tooltipT0:        float
  tooltipText:      string


var gui: UIState

let RED = rgb(1.0, 0.4, 0.4)


proc mouseButtonCb(win: Window, button: MouseButton, pressed: bool,
                   modKeys: set[ModifierKey]) =

  case button
  of mb1: gui.mbLeft  = pressed
  of mb2: gui.mbRight = pressed
  of mb3: gui.mbMid   = pressed
  else: discard


proc keyCb(win: Window, key: Key, scanCode: int32, action: KeyAction,
           modKeys: set[ModifierKey]) =

  if action != kaDown: return

  case key
  of keyEscape: win.shouldClose = true
  else: return


proc createWindow(): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 1000, h: 800)
  cfg.title = "uiState test"
  cfg.resizable = true
  cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  cfg.debugContext = true
  cfg.nMultiSamples = 4

  when defined(macosx):
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  newWindow(cfg)


proc mouseInside(x, y, w, h: float): bool =
  gui.mx >= x and gui.mx <= x+w and
  gui.my >= y and gui.my <= y+h


proc drawToolTip(vg: NVGContext, x, y: float, text: string,
                 alpha: float = 1.0) =
  let
    w = 150.0
    h = 40.0

  vg.beginPath()
  vg.roundedRect(x, y, w, h, 5)
  vg.fillColor(black(0.65 * alpha))
  vg.fill()

  vg.fontSize(15.0)
  vg.fontFace("sans-bold")
  vg.textAlign(haLeft, vaMiddle)
  vg.fillColor(white(alpha))
  discard vg.text(x + 10, y + 10, text)


proc uiStatePre() =
  gui.hotItem = 0

proc uiStatePost(vg: NVGContext) =
  if gui.mbLeft:
    if gui.activeItem == 0:
      # Mouse button was pressed outside of any widget. We need to mark this
      # as a separate state so we can't just "drag into" a widget while the
      # button is being depressed and activate it.
      gui.activeItem = -1
  else:
    # If the button was released inside the active widget, that
    # was already handled at this point, we're just clearing the active item
    # here. This also takes care of the case when the button was depressed
    # inside the widget but released outside of it.
    gui.activeItem = 0

  # Tooltip handling
  let
    ttx = gui.mx + 13
    tty = gui.my + 20

  case gui.tooltipState:
  of tsOff: discard
  of tsShowDelay:
    if getTime() - gui.tooltipT0 > TooltipShowDelay:
      gui.tooltipState = tsShow

  of tsShow:
    drawToolTip(vg, ttx, tty, gui.tooltipText)

  of tsFadeOutDelay:
    drawToolTip(vg, ttx, tty, gui.tooltipText)
    if getTime() - gui.tooltipT0 > TooltipFadeOutDelay:
      gui.tooltipState = tsFadeOut
      gui.tooltipT0 = getTime()

  of tsFadeOut:
    let t = getTime() - gui.tooltipT0
    if t > TooltipFadeOutDuration:
      gui.tooltipState = tsOff
    else:
      let alpha = 1.0 - t / TooltipFadeOutDuration
      drawToolTip(vg, ttx, tty, gui.tooltipText, alpha)

  gui.lastTooltipState = gui.tooltipState

  if gui.lastTooltipState == tsShowDelay:
    gui.tooltipState = tsOff
  elif gui.lastTooltipState == tsShow:
    gui.tooltipState = tsFadeOutDelay
    gui.tooltipT0 = getTime()


proc handleTooltipInsideWidget(tooltipText: string) =
  gui.tooltipState = gui.lastTooltipState

  if gui.tooltipState == tsOff:
    gui.tooltipState = tsShowDelay
    gui.tooltipT0 = getTime()

  elif gui.tooltipState >= tsShow:
    gui.tooltipState = tsShow
    gui.tooltipT0 = getTime()
    gui.tooltipText = tooltipText


proc renderButton(vg: NVGContext, id: int, x, y, w, h: float, label: string, color: Color,
                  tooltipText: string = ""): bool =

  let inside = mouseInside(x, y, w, h)
  if inside:
    gui.hotItem = id
    if gui.activeItem == 0 and gui.mbLeft:
      gui.activeItem = id

  if not gui.mbLeft and gui.hotItem == id and gui.activeItem == id:
    echo fmt"button {id} pressed"
    result = true

  let fillColor = if gui.hotItem == id:
    if gui.activeItem == id: RED
    else: gray(0.8)
  else:
    color

  vg.beginPath()
  vg.roundedRect(x, y, w, h, 5)
  vg.fillColor(fillColor)
  vg.fill()
#  vg.strokeWidth(2.0)
#  vg.strokeColor(gray(0.2))
#  vg.stroke()

  vg.fontSize(19.0)
  vg.fontFace("sans-bold")
  vg.textAlign(haLeft, vaMiddle)
  vg.fillColor(black(0.7))
  let tw = vg.horizontalAdvance(0,0, label)
  discard vg.text(x + w*0.5 - tw*0.5, y+h*0.5, label)

  if inside:
    handleTooltipInsideWidget(tooltipText)


proc renderUI(vg: NVGContext) =
  let
    w = 110.0
    h = 22.0
    pad = h + 8
  var
    x = 100.5
    y = 50.5

  var btnpUshed = renderButton(vg, 1, x, y, w, h, "Start", color = gray(0.60), "I am the first!")
  y += pad

  btnPushed = renderButton(vg, 2, x, y, w, h, "Stop", color = gray(0.60), "Middle one...")
  y += pad

  btnPushed = renderButton(vg, 3, x, y, w, h, "Preferences", color = gray(0.60), "Last button")
  y += pad


proc loadData(vg: NVGContext) =
  let regularFont = vg.createFont("sans", "data/Roboto-Regular.ttf")
  if regularFont == NoFont:
    quit "Could not add font italic.\n"

  let boldFont = vg.createFont("sans-bold", "data/Roboto-Bold.ttf")
  if boldFont == NoFont:
    quit "Could not add font italic.\n"


proc main() =
  glfw.initialize()

  var win = createWindow()
  win.mouseButtonCb = mouseButtonCb
  win.keyCb = keyCb
  win.pos = (400, 150)  # TODO for development

  glfw.makeContextCurrent(win)

  var flags = {nifStencilStrokes, nifDebug}
  var vg = nvgInit(getProcAddress, flags)
  if vg == nil:
    quit "Error creating NanoVG context"

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  loadData(vg)

  glfw.swapInterval(1)

  while not win.shouldClose:
    var
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufferSize
      pxRatio = fbWidth / winWidth

    # Update and render
    glViewport(0, 0, fbWidth, fbHeight)

    glClearColor(0.3, 0.3, 0.3, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    uiStatePre()
    (gui.mx, gui.my) = win.cursorPos()

    vg.renderUI()

    uiStatePost(vg)

    vg.endFrame()

    glfw.swapBuffers(win)
    glfw.pollEvents()


  nvgDeinit(vg)

  glfw.terminate()


main()
