{-# LANGUAGE RecordWildCards #-}

module Iced.ColorFFI (
  ColorPtr,
  -- reexports
  module Iced.Color,
  --
) where

import Foreign
import Foreign.C.Types

import Iced.Attribute.Internal
import Iced.Color

data NativeColor
type ColorPtr = Ptr NativeColor

-- r g b a
-- values must be in 0.0 - 1.0 range
-- in debug mode panics if any value is out of range
foreign import ccall "color_new"
  color_new :: CFloat -> CFloat -> CFloat -> CFloat -> IO ColorPtr

instance ValueToNativeIO Color ColorPtr where
  valueToNativeIO Color{..} = color_new (CFloat r) (CFloat g) (CFloat b) (CFloat a)
