{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE RecordWildCards #-}

module Iced.Widget.Canvas (
  canvas,
  CanvasState,
  newCanvasState,
  clearCanvasCache,
  freeCanvasState,
) where

import Foreign
import System.IO.Unsafe -- to run clearCache without IO

import Iced.Attribute.Length
import Iced.Attribute.LengthFFI
import Iced.Element
import Iced.Widget.Canvas.Frame
import Iced.Widget.Canvas.FrameAction
import Iced.Widget.Canvas.FramePtr

data NativeCanvasState
type CanvasStatePtr = Ptr NativeCanvasState
type CanvasState = CanvasStatePtr; -- to export
data NativeCanvas
type Self = Ptr NativeCanvas
type AttributeFn = Self -> IO Self

data Attribute = Width Length | Height Length

foreign import ccall safe "canvas_state_new"
  canvas_state_new :: IO (CanvasStatePtr)

foreign import ccall safe "canvas_set_draw"
  canvas_set_draw :: CanvasStatePtr -> FunPtr (NativeDraw) -> IO ()

foreign import ccall safe "canvas_remove_draw"
  canvas_remove_draw :: CanvasStatePtr -> IO ()

foreign import ccall safe "canvas_clear_cache"
  canvas_clear_cache :: CanvasStatePtr -> IO ()

foreign import ccall safe "canvas_state_free"
  canvas_state_free :: CanvasStatePtr -> IO ()

foreign import ccall safe "canvas_new"
  canvas_new :: CanvasStatePtr -> IO Self

foreign import ccall safe "canvas_width"
  canvas_width :: Self -> LengthPtr -> IO Self

foreign import ccall safe "canvas_height"
  canvas_height :: Self -> LengthPtr -> IO Self

foreign import ccall safe "canvas_into_element"
  canvas_into_element :: Self -> IO ElementPtr

type NativeDraw = FramePtr -> IO ()
foreign import ccall "wrapper"
  makeDrawCallback :: NativeDraw -> IO (FunPtr (NativeDraw))

data Canvas = Canvas {
  attributes :: [Attribute],
  actions :: [FrameAction],
  cache :: CanvasStatePtr
}

drawActions :: [FrameAction] -> FramePtr -> IO ()
drawActions [] _framePtr = pure ()
drawActions (action:remaining) framePtr = do
  case action of
    FrameFill shapes color -> frameFill framePtr shapes color
  drawActions remaining framePtr

drawCallback :: [FrameAction] -> NativeDraw
drawCallback actions framePtr = drawActions actions framePtr

instance IntoNative Canvas where
  toNative details = do
    drawCallbackPtr <- makeDrawCallback $ drawCallback details.actions
    canvas_set_draw details.cache drawCallbackPtr
    self <- canvas_new details.cache
    updatedSelf <- applyAttributes self details.attributes
    canvas_into_element updatedSelf

instance UseAttribute Self Attribute where
  useAttribute self attribute = do
    case attribute of
      Width len -> useWidth len self
      Height len -> useHeight len self

instance UseWidth Length Attribute where
  width len = Width len

instance UseHeight Length Attribute where
  height len = Height len

canvas :: [Attribute] -> [FrameAction] -> CanvasStatePtr -> Element
canvas attributes actions cache = pack Canvas { .. }

useWidth :: Length -> AttributeFn
useWidth len self = do
  let nativeLen = lengthToNative len
  canvas_width self nativeLen

useHeight :: Length -> AttributeFn
useHeight len self = do
  let nativeLen = lengthToNative len
  canvas_height self nativeLen

newCanvasState :: IO (CanvasStatePtr)
newCanvasState = canvas_state_new

clearCanvasCache :: CanvasStatePtr -> CanvasStatePtr
clearCanvasCache state = unsafePerformIO $ do -- todo: make it a Command probably?
  canvas_clear_cache state
  return state

freeCanvasState :: CanvasStatePtr -> IO ()
freeCanvasState state = canvas_state_free state
