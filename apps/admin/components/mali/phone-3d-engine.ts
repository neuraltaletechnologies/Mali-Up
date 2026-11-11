import {
  AdditiveBlending,
  ACESFilmicToneMapping,
  BufferGeometry,
  CanvasTexture,
  CapsuleGeometry,
  CircleGeometry,
  CylinderGeometry,
  DataTexture,
  DirectionalLight,
  ExtrudeGeometry,
  Group,
  Material,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  PerspectiveCamera,
  PMREMGenerator,
  Scene,
  Shape,
  ShapeGeometry,
  SRGBColorSpace,
  Texture,
  WebGLRenderer,
} from "three"
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js"
import { mergeVertices } from "three/examples/jsm/utils/BufferGeometryUtils.js"
import { CANVAS_PADDING, PHONE_DIMENSIONS, type PhoneModel } from "./phone-3d-specs"

/*
 * Every phone on a page shares one WebGL context: browsers cap live contexts
 * (around 16) and the landing page shows ten phones. Each view renders into a
 * corner of the shared canvas, then copies the result to its own 2D canvas.
 */

const FOV = 20
const MAX_DPR = 2
const MAX_TEXTURE_WIDTH = 720
const IDLE_FRAME_MS = 32
// The screenshots have a coloured hairline baked into their outer edge.
const SCREENSHOT_EDGE_CROP = 0.01

interface ModelSpec {
  depth: number
  edge: number
  corner: number
  frameInset: number
  bezel: number
  screenCorner: number
  frame: { color: number; roughness: number }
  back: { color: number; roughness: number }
}

const MODEL_SPECS: Record<PhoneModel, ModelSpec> = {
  iphone: {
    depth: 8.2,
    edge: 0.9,
    corner: 11.5,
    frameInset: 0.7,
    bezel: 1.5,
    screenCorner: 9.6,
    frame: { color: 0x9a968e, roughness: 0.34 },
    back: { color: 0x8d8982, roughness: 0.62 },
  },
  pixel: {
    depth: 8.6,
    edge: 2.4,
    corner: 12.5,
    frameInset: 1,
    bezel: 2,
    screenCorner: 9.2,
    frame: { color: 0x26282c, roughness: 0.3 },
    back: { color: 0x17181b, roughness: 0.42 },
  },
}

interface BuiltModel {
  group: Group
  screen: MeshBasicMaterial
  spec: ModelSpec
  screenAspect: number
}

function roundedRect(width: number, height: number, radius: number): Shape {
  const x = -width / 2
  const y = -height / 2
  return new Shape()
    .moveTo(x + radius, y)
    .lineTo(x + width - radius, y)
    .absarc(x + width - radius, y + radius, radius, -Math.PI / 2, 0, false)
    .lineTo(x + width, y + height - radius)
    .absarc(x + width - radius, y + height - radius, radius, 0, Math.PI / 2, false)
    .lineTo(x + radius, y + height)
    .absarc(x + radius, y + height - radius, radius, Math.PI / 2, Math.PI, false)
    .lineTo(x, y + radius)
    .absarc(x + radius, y + radius, radius, Math.PI, Math.PI * 1.5, false) as Shape
}

/** A rounded slab, centred on the origin, with smooth edges. */
function slabGeometry(width: number, height: number, radius: number, depth: number, edge: number): BufferGeometry {
  const extruded = new ExtrudeGeometry(roundedRect(width - edge * 2, height - edge * 2, Math.max(radius - edge, 0.1)), {
    depth: depth - edge * 2,
    bevelEnabled: true,
    bevelThickness: edge,
    bevelSize: edge,
    bevelSegments: 8,
    curveSegments: 20,
  })
  extruded.translate(0, 0, -(depth - edge * 2) / 2)
  // ExtrudeGeometry is faceted; welding before recomputing normals smooths it.
  extruded.deleteAttribute("uv")
  extruded.deleteAttribute("normal")
  const welded = mergeVertices(extruded, 1e-3)
  extruded.dispose()
  welded.computeVertexNormals()
  return welded
}

/** A flat rounded panel whose UVs span 0..1 across its full bounds. */
function panelGeometry(width: number, height: number, radius: number): BufferGeometry {
  const geometry = new ShapeGeometry(roundedRect(width, height, radius), 24)
  const position = geometry.getAttribute("position")
  const uv = geometry.getAttribute("uv")
  for (let i = 0; i < position.count; i++) {
    uv.setXY(i, position.getX(i) / width + 0.5, position.getY(i) / height + 0.5)
  }
  uv.needsUpdate = true
  return geometry
}

function addLens(parent: Group, x: number, y: number, radius: number, z: number, ring: Material, glass: Material) {
  const barrel = new Mesh(new CylinderGeometry(radius, radius, 1.2, 40), ring)
  barrel.rotation.x = Math.PI / 2
  barrel.position.set(x, y, z + 0.3)
  const lens = new Mesh(new CircleGeometry(radius * 0.82, 40), glass)
  lens.position.set(x, y, z + 0.92)
  const iris = new Mesh(new CircleGeometry(radius * 0.36, 28), new MeshBasicMaterial({ color: 0x0b1626 }))
  iris.position.set(x, y, z + 0.94)
  parent.add(barrel, lens, iris)
}

function addSideButton(
  parent: Group,
  side: 1 | -1,
  halfWidth: number,
  centerY: number,
  length: number,
  material: Material,
) {
  const button = new Mesh(new CapsuleGeometry(0.75, length, 6, 14), material)
  button.scale.x = 0.55
  button.position.set(side * halfWidth, centerY, 0)
  parent.add(button)
}

function buildPhone(model: PhoneModel): BuiltModel {
  const { width, height } = PHONE_DIMENSIONS[model]
  const spec = MODEL_SPECS[model]
  const group = new Group()
  const front = spec.depth / 2

  const frame = new MeshStandardMaterial({
    color: spec.frame.color,
    metalness: 1,
    roughness: spec.frame.roughness,
  })
  const blackGlass = new MeshPhysicalMaterial({ color: 0x030304, roughness: 0.12, clearcoat: 1, clearcoatRoughness: 0.05 })
  const backGlass = new MeshPhysicalMaterial({
    color: spec.back.color,
    metalness: 0.15,
    roughness: spec.back.roughness,
    clearcoat: 0.25,
    clearcoatRoughness: 0.5,
  })
  const cameraGlass = new MeshPhysicalMaterial({ color: 0x05070b, roughness: 0.04, clearcoat: 1, clearcoatRoughness: 0.02 })

  group.add(new Mesh(slabGeometry(width, height, spec.corner, spec.depth, spec.edge), frame))

  // Front glass, display, and the reflective layer over it.
  const glassWidth = width - spec.frameInset * 2
  const glassHeight = height - spec.frameInset * 2
  const glass = new Mesh(panelGeometry(glassWidth, glassHeight, spec.corner - spec.frameInset), blackGlass)
  glass.position.z = front + 0.02
  group.add(glass)

  const screenWidth = glassWidth - spec.bezel * 2
  const screenHeight = glassHeight - spec.bezel * 2
  const screen = new MeshBasicMaterial({ toneMapped: false, map: blackPixel() })
  const display = new Mesh(panelGeometry(screenWidth, screenHeight, spec.screenCorner), screen)
  display.position.z = front + 0.06
  group.add(display)

  const reflection = new Mesh(
    panelGeometry(glassWidth, glassHeight, spec.corner - spec.frameInset),
    // Additive so highlights brighten the screenshot without dimming it.
    new MeshPhysicalMaterial({
      color: 0x000000,
      roughness: 0.05,
      transparent: true,
      blending: AdditiveBlending,
      depthWrite: false,
      envMapIntensity: 1.4,
    }),
  )
  reflection.position.z = front + 0.14
  reflection.renderOrder = 2
  group.add(reflection)

  // Camera cut-out, positioned over the hole baked into the screenshots.
  const screenTop = screenHeight / 2
  if (model === "iphone") {
    const island = new Mesh(panelGeometry(19, 7, 3.5), cameraGlass)
    island.position.set(0, screenTop - 4.2, front + 0.1)
    group.add(island)
  } else {
    const hole = new Mesh(new CircleGeometry(2.8, 40), cameraGlass)
    hole.position.set(0, screenTop - 3.9, front + 0.1)
    group.add(hole)
  }

  // Back of the phone. Local +z points out of the back.
  const rear = new Group()
  rear.rotation.y = Math.PI
  rear.position.z = -front - 0.02
  rear.add(new Mesh(panelGeometry(glassWidth, glassHeight, spec.corner - spec.frameInset), backGlass))
  group.add(rear)

  const top = height / 2
  if (model === "iphone") {
    const size = 37
    const plateau = new Mesh(slabGeometry(size, size + 2, 10, 2, 0.5), backGlass)
    plateau.position.set(-width / 2 + size / 2 + 3.2, top - size / 2 - 4.2, 1)
    rear.add(plateau)
    const originX = plateau.position.x
    const originY = plateau.position.y
    addLens(rear, originX - 8.6, originY + 9.2, 7, 2, frame, cameraGlass)
    addLens(rear, originX - 8.6, originY - 9.2, 7, 2, frame, cameraGlass)
    addLens(rear, originX + 9.4, originY, 7, 2, frame, cameraGlass)
    const flash = new Mesh(new CircleGeometry(2.4, 28), new MeshStandardMaterial({ color: 0xf1e7c8, roughness: 0.4 }))
    flash.position.set(originX + 10, originY + 13.4, 2.02)
    rear.add(flash)
  } else {
    const bar = new Mesh(slabGeometry(width - 7, 23, 11, 3, 1.2), frame)
    bar.position.set(0, top - 32, 1.5)
    rear.add(bar)
    const pillY = bar.position.y
    const pill = new Mesh(panelGeometry(44, 15, 7.5), cameraGlass)
    pill.position.set(-5, pillY, 3.02)
    rear.add(pill)
    addLens(rear, -19.5, pillY, 5.2, 2.2, frame, cameraGlass)
    addLens(rear, -5, pillY, 5.2, 2.2, frame, cameraGlass)
    addLens(rear, 9.5, pillY, 5.2, 2.2, frame, cameraGlass)
    const flash = new Mesh(new CircleGeometry(2.4, 28), new MeshStandardMaterial({ color: 0xf1e7c8, roughness: 0.4 }))
    flash.position.set(25, pillY, 3.02)
    rear.add(flash)
  }

  const halfWidth = width / 2
  if (model === "iphone") {
    addSideButton(group, -1, halfWidth, 40, 5, frame)
    addSideButton(group, -1, halfWidth, 25, 10, frame)
    addSideButton(group, -1, halfWidth, 11, 10, frame)
    addSideButton(group, 1, halfWidth, 21, 16, frame)
  } else {
    addSideButton(group, 1, halfWidth, 36, 9, frame)
    addSideButton(group, 1, halfWidth, 15, 19, frame)
  }

  return { group, screen, spec, screenAspect: screenHeight / screenWidth }
}

let sharedBlackPixel: DataTexture | null = null
function blackPixel(): DataTexture {
  if (!sharedBlackPixel) {
    sharedBlackPixel = new DataTexture(new Uint8Array([0, 0, 0, 255]), 1, 1)
    sharedBlackPixel.needsUpdate = true
  }
  return sharedBlackPixel
}

/** Shows the top of the screenshot, cropping the bottom if it is taller than the display. */
function fitTexture(texture: Texture, screenAspect: number) {
  const image = texture.image as { width: number; height: number }
  const visible = 1 - SCREENSHOT_EDGE_CROP * 2
  const imageAspect = image.height / image.width
  if (imageAspect >= screenAspect) {
    const repeatY = visible * (screenAspect / imageAspect)
    texture.repeat.set(visible, repeatY)
    texture.offset.set(SCREENSHOT_EDGE_CROP, 1 - SCREENSHOT_EDGE_CROP - repeatY)
  } else {
    const repeatX = visible * (imageAspect / screenAspect)
    texture.repeat.set(repeatX, visible)
    texture.offset.set((1 - repeatX) / 2, SCREENSHOT_EDGE_CROP)
  }
}

interface View extends PhoneViewOptions {
  context: CanvasRenderingContext2D
  texture: Texture | null
  requestedSrc: string
  visible: boolean
  announced: boolean
  dirty: boolean
  spin: number
  spinTarget: number
  dragging: boolean
  lastPointerX: number
  removeDragListeners: (() => void) | null
}

export interface PhoneViewOptions {
  canvas: HTMLCanvasElement
  model: PhoneModel
  src: string
  yaw: number
  pitch: number
  interactive: boolean
  phase: number
  onReady: () => void
  onUnavailable: () => void
}

export interface PhoneViewHandle {
  setSource: (src: string) => void
  setPose: (yaw: number, pitch: number) => void
  destroy: () => void
}

class PhoneEngine {
  readonly views = new Set<View>()
  disposed = false

  private readonly renderer: WebGLRenderer
  private readonly scene = new Scene()
  private readonly camera = new PerspectiveCamera(FOV, 1, 1, 2000)
  private readonly models: Record<PhoneModel, BuiltModel>
  private readonly textures = new Map<string, Promise<Texture>>()
  private readonly loadedTextures = new Set<Texture>()
  private readonly observer: IntersectionObserver
  private readonly reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  private bufferWidth = 0
  private bufferHeight = 0
  private frame = 0
  private lastFrame = 0
  private clock = 0
  private pointerX = 0
  private pointerY = 0
  private smoothPointerX = 0
  private smoothPointerY = 0

  constructor() {
    this.renderer = new WebGLRenderer({ alpha: true, antialias: true, failIfMajorPerformanceCaveat: true })
    this.renderer.setPixelRatio(1)
    this.renderer.setClearColor(0x000000, 0)
    this.renderer.toneMapping = ACESFilmicToneMapping
    this.renderer.setScissorTest(true)

    const pmrem = new PMREMGenerator(this.renderer)
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture
    pmrem.dispose()

    const key = new DirectionalLight(0xffffff, 1.4)
    key.position.set(-120, 200, 300)
    this.scene.add(key)

    this.models = { iphone: buildPhone("iphone"), pixel: buildPhone("pixel") }
    this.scene.add(this.models.iphone.group, this.models.pixel.group)

    this.observer = new IntersectionObserver(this.onIntersection, { rootMargin: "300px" })
    window.addEventListener("pointermove", this.onPointerMove, { passive: true })
    this.renderer.domElement.addEventListener("webglcontextlost", this.onContextLost)
    this.frame = requestAnimationFrame(this.tick)
  }

  addView(options: PhoneViewOptions): View | null {
    const context = options.canvas.getContext("2d")
    if (!context) return null
    const view: View = {
      ...options,
      context,
      texture: null,
      requestedSrc: options.src,
      visible: false,
      announced: false,
      dirty: true,
      spin: this.reducedMotion ? 0 : -0.7,
      spinTarget: 0,
      dragging: false,
      lastPointerX: 0,
      removeDragListeners: null,
    }
    if (options.interactive && !this.reducedMotion) view.removeDragListeners = this.attachDrag(view)
    this.views.add(view)
    this.observer.observe(options.canvas)
    return view
  }

  removeView(view: View) {
    view.removeDragListeners?.()
    this.observer.unobserve(view.canvas)
    this.views.delete(view)
  }

  requestSource(view: View, src: string) {
    view.requestedSrc = src
    if (view.visible) this.loadViewTexture(view)
  }

  markDirty(view: View) {
    view.dirty = true
  }

  dispose() {
    this.disposed = true
    cancelAnimationFrame(this.frame)
    this.observer.disconnect()
    window.removeEventListener("pointermove", this.onPointerMove)
    this.renderer.domElement.removeEventListener("webglcontextlost", this.onContextLost)
    this.scene.traverse((object) => {
      if (object instanceof Mesh) {
        object.geometry.dispose()
        const material = object.material as Material
        material.dispose()
      }
    })
    this.loadedTextures.forEach((texture) => texture.dispose())
    this.scene.environment?.dispose()
    sharedBlackPixel?.dispose()
    sharedBlackPixel = null
    this.renderer.dispose()
    this.renderer.forceContextLoss()
  }

  private readonly onContextLost = (event: Event) => {
    event.preventDefault()
    this.views.forEach((view) => view.onUnavailable())
    cancelAnimationFrame(this.frame)
  }

  private readonly onPointerMove = (event: PointerEvent) => {
    if (event.pointerType === "touch") return
    this.pointerX = event.clientX / window.innerWidth - 0.5
    this.pointerY = event.clientY / window.innerHeight - 0.5
  }

  private readonly onIntersection = (entries: IntersectionObserverEntry[]) => {
    for (const entry of entries) {
      for (const view of this.views) {
        if (view.canvas !== entry.target) continue
        view.visible = entry.isIntersecting
        if (view.visible) this.loadViewTexture(view)
      }
    }
  }

  private loadViewTexture(view: View) {
    const src = view.requestedSrc
    this.loadTexture(src).then(
      (texture) => {
        // A newer source may have been requested while this one loaded.
        if (this.disposed || view.requestedSrc !== src) return
        view.texture = texture
        view.dirty = true
      },
      () => {
        if (view.requestedSrc === src && !view.texture) view.onUnavailable()
      },
    )
  }

  private loadTexture(src: string): Promise<Texture> {
    const existing = this.textures.get(src)
    if (existing) return existing
    const pending = new Promise<Texture>((resolve, reject) => {
      const image = new Image()
      image.onerror = () => reject(new Error(`Could not load ${src}`))
      image.onload = () => {
        // The source files are full-resolution; phones never need that much.
        const scale = Math.min(1, MAX_TEXTURE_WIDTH / image.naturalWidth)
        const surface = document.createElement("canvas")
        surface.width = Math.round(image.naturalWidth * scale)
        surface.height = Math.round(image.naturalHeight * scale)
        const context = surface.getContext("2d")
        if (!context) {
          reject(new Error("2D canvas unavailable"))
          return
        }
        // Transparent screenshot corners must read as the black bezel.
        context.fillStyle = "#000"
        context.fillRect(0, 0, surface.width, surface.height)
        context.drawImage(image, 0, 0, surface.width, surface.height)
        const texture = new CanvasTexture(surface)
        texture.colorSpace = SRGBColorSpace
        texture.anisotropy = Math.min(8, this.renderer.capabilities.getMaxAnisotropy())
        this.loadedTextures.add(texture)
        resolve(texture)
      }
      image.src = src
    })
    this.textures.set(src, pending)
    return pending
  }

  private attachDrag(view: View): () => void {
    const { canvas } = view
    canvas.style.touchAction = "pan-y"
    canvas.style.cursor = "grab"
    const onDown = (event: PointerEvent) => {
      view.dragging = true
      view.lastPointerX = event.clientX
      canvas.setPointerCapture(event.pointerId)
      canvas.style.cursor = "grabbing"
    }
    const onMove = (event: PointerEvent) => {
      if (!view.dragging) return
      view.spin += (event.clientX - view.lastPointerX) * 0.012
      view.lastPointerX = event.clientX
    }
    const onUp = () => {
      view.dragging = false
      canvas.style.cursor = "grab"
      // Settle on whichever front-facing turn is nearest.
      view.spinTarget = Math.round(view.spin / (Math.PI * 2)) * Math.PI * 2
    }
    canvas.addEventListener("pointerdown", onDown)
    canvas.addEventListener("pointermove", onMove)
    canvas.addEventListener("pointerup", onUp)
    canvas.addEventListener("pointercancel", onUp)
    return () => {
      canvas.removeEventListener("pointerdown", onDown)
      canvas.removeEventListener("pointermove", onMove)
      canvas.removeEventListener("pointerup", onUp)
      canvas.removeEventListener("pointercancel", onUp)
    }
  }

  private readonly tick = (now: number) => {
    this.frame = requestAnimationFrame(this.tick)
    const interacting = [...this.views].some((view) => view.visible && view.dragging)
    if (!interacting && now - this.lastFrame < IDLE_FRAME_MS) return
    const delta = Math.min(0.1, (now - this.lastFrame) / 1000)
    this.lastFrame = now
    this.clock += delta

    const follow = 1 - Math.exp(-delta * 4)
    this.smoothPointerX += (this.pointerX - this.smoothPointerX) * follow
    this.smoothPointerY += (this.pointerY - this.smoothPointerY) * follow

    for (const view of this.views) {
      if (!view.visible || !view.texture) continue
      if (this.reducedMotion && !view.dirty) continue
      this.renderView(view, delta)
      view.dirty = false
      if (!view.announced) {
        view.announced = true
        view.onReady()
      }
    }
  }

  private renderView(view: View, delta: number) {
    const texture = view.texture as Texture
    const dpr = Math.min(window.devicePixelRatio || 1, MAX_DPR)
    const width = Math.round(view.canvas.clientWidth * dpr)
    const height = Math.round(view.canvas.clientHeight * dpr)
    if (width === 0 || height === 0) return
    if (view.canvas.width !== width || view.canvas.height !== height) {
      view.canvas.width = width
      view.canvas.height = height
    }
    if (width > this.bufferWidth || height > this.bufferHeight) {
      this.bufferWidth = Math.max(width, this.bufferWidth)
      this.bufferHeight = Math.max(height, this.bufferHeight)
      this.renderer.setSize(this.bufferWidth, this.bufferHeight, false)
    }

    const built = this.models[view.model]
    this.models.iphone.group.visible = view.model === "iphone"
    this.models.pixel.group.visible = view.model === "pixel"

    if (!view.dragging) view.spin += (view.spinTarget - view.spin) * (1 - Math.exp(-delta * 3.5))

    const sway = this.reducedMotion ? 0 : Math.sin(this.clock * 0.55 + view.phase) * 0.07
    const nod = this.reducedMotion ? 0 : Math.cos(this.clock * 0.42 + view.phase) * 0.025
    built.group.rotation.y = view.yaw + view.spin + sway + this.smoothPointerX * 0.14
    built.group.rotation.x = view.pitch + nod + this.smoothPointerY * 0.08

    fitTexture(texture, built.screenAspect)
    built.screen.map = texture

    const phoneHeight = PHONE_DIMENSIONS[view.model].height
    const distance = (phoneHeight * (1 + CANVAS_PADDING * 2)) / (2 * Math.tan((FOV * Math.PI) / 360))
    this.camera.aspect = width / height
    this.camera.position.set(0, 0, distance)
    this.camera.near = distance - 110
    this.camera.far = distance + 110
    this.camera.updateProjectionMatrix()

    // The viewport origin is bottom-left; pin views to the buffer's top-left.
    const y = this.bufferHeight - height
    this.renderer.setViewport(0, y, width, height)
    this.renderer.setScissor(0, y, width, height)
    this.renderer.render(this.scene, this.camera)

    view.context.clearRect(0, 0, width, height)
    view.context.drawImage(this.renderer.domElement, 0, 0, width, height, 0, 0, width, height)
  }
}

let engine: PhoneEngine | null = null
let engineCreationFailed = false
let disposeTimer: ReturnType<typeof setTimeout> | undefined

function acquireEngine(): PhoneEngine | null {
  clearTimeout(disposeTimer)
  if (engineCreationFailed) return null
  if (!engine) {
    try {
      engine = new PhoneEngine()
    } catch {
      // No WebGL, or software-only GL that would be too slow to animate.
      engineCreationFailed = true
      return null
    }
  }
  return engine
}

function releaseEngine(released: PhoneEngine) {
  if (released.views.size > 0) return
  // Deferred so a same-tick remount (e.g. Strict Mode) reuses the context.
  disposeTimer = setTimeout(() => {
    if (released.views.size > 0 || released.disposed) return
    released.dispose()
    if (engine === released) engine = null
  }, 1000)
}

export function createPhoneView(options: PhoneViewOptions): PhoneViewHandle {
  const owner = acquireEngine()
  const view = owner?.addView(options) ?? null
  if (!owner || !view) {
    options.onUnavailable()
    return { setSource: () => {}, setPose: () => {}, destroy: () => {} }
  }
  return {
    setSource: (src) => owner.requestSource(view, src),
    setPose: (yaw, pitch) => {
      view.yaw = yaw
      view.pitch = pitch
      owner.markDirty(view)
    },
    destroy: () => {
      owner.removeView(view)
      releaseEngine(owner)
    },
  }
}
