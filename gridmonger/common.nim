type
  Orientation* = enum
    Horiz, Vert

  Direction* = enum
    North, East, South, West


type
  # Rects are endpoint-exclusive
  Rect*[T: SomeNumber | Natural] = object
    x1*, y1*, x2*, y2*: T

func width*[T: SomeNumber | Natural](r: Rect[T]): T = r.x2 - r.x1
func height*[T: SomeNumber | Natural](r: Rect[T]): T = r.y2 - r.y1

func contains*[T: SomeNumber | Natural](r: Rect[T], x, y: T): bool =
  x >= r.x1 and x < r.x2 and y >= r.y1 and y < r.y2

func normalize*[T: SomeNumber | Natural](r: Rect[T]): Rect[T] =
  Rect[T](x1: min(r.x1, r.x2), y1: min(r.y1, r.y2),
          x2: max(r.x1, r.x2), y2: max(r.y1, r.y2))


type
  Floor* = enum
    fNone                = (  0, "blank"),
    fEmptyFloor          = ( 10, "empty"),
    fClosedDoor          = ( 20, "closed door"),
    fOpenDoor            = ( 21, "open door"),
    fPressurePlate       = ( 30, "pressure plate"),
    fHiddenPressurePlate = ( 31, "hidden pressure plate"),
    fClosedPit           = ( 40, "closed pit"),
    fOpenPit             = ( 41, "open pit"),
    fHiddenPit           = ( 42, "hidden pit"),
    fCeilingPit          = ( 43, "ceiling pit"),
    fStairsDown          = ( 50, "stairs down"),
    fStairsUp            = ( 51, "stairs up"),
    fSpinner             = ( 60, "spinner"),
    fTeleport            = ( 70, "teleport"),
    fCustom              = (999, "custom")

  Wall* = enum
    wNone          = ( 0, "none"),
    wWall          = (10, "wall"),
    wIllusoryWall  = (11, "illusory wall"),
    wInvisibleWall = (12, "invisible wall")
    wOpenDoor      = (20, "closed door"),
    wClosedDoor    = (21, "open door"),
    wSecretDoor    = (22, "secret door"),
    wLever         = (30, "statue")
    wNiche         = (40, "niche")
    wStatue        = (50, "statue")

  Cell* = object
    floor*:            Floor
    floorOrientation*: Orientation
    wallN*, wallW*:    Wall
    customChar*:       char
    notes*:            string

  # (0,0) is the top-left cell of the map
  Map* = ref object
    width*:  Natural
    height*: Natural
    cells*:  seq[Cell]


type
  # (0,0) is the top-left cell of the selection
  Selection* = ref object
    width*:  Natural
    height*: Natural
    cells*:  seq[bool]


type
  SelectionRect* = object
    x0*, y0*:   Natural
    rect*:      Rect[Natural]
    fillValue*: bool

  CopyBuffer* = object
    map*:       Map
    selection*: Selection

