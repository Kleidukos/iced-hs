{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE RecordWildCards #-}

module Iced.Widget.Tooltip (
  tooltip,
  gap,
  snapWithViewport,
  Position(..),
) where

import Foreign
import Foreign.C.Types

import Iced.Attribute.Internal
import Iced.Attribute.Padding
import Iced.Element

data NativeTooltip
type Self = Ptr NativeTooltip
type AttributeFn = Self -> IO Self
data NativeStyle
type StylePtr = Ptr NativeStyle
data Position = FollowCursor | Top | Bottom | LeftSide | RightSide

data Attribute = Gap Float | AddPadding Float | SnapWithViewport Bool -- | Style Style

-- content tooltip position
foreign import ccall safe "tooltip_new"
  tooltip_new :: ElementPtr -> ElementPtr -> CUChar -> IO Self

-- tooltip gap
foreign import ccall safe "tooltip_gap"
  tooltip_gap :: Self -> CFloat -> IO Self

-- tooltip padding
foreign import ccall safe "tooltip_padding"
  tooltip_padding :: Self -> CFloat -> IO Self

-- tooltip snap
foreign import ccall safe "tooltip_snap_within_viewport"
  tooltip_snap_within_viewport :: Self -> CBool -> IO Self

-- skip for now
-- tooltip style
foreign import ccall safe "tooltip_style"
  tooltip_style :: Self -> StylePtr -> IO Self

foreign import ccall safe "tooltip_into_element"
  into_element :: Self -> IO ElementPtr

data Tooltip = Tooltip {
  content :: Element,
  tooltipElement :: Element,
  position :: Position
}

positionToNative :: Position -> CUChar
positionToNative position = CUChar $
  case position of
    FollowCursor -> 1
    Top -> 2
    Bottom -> 3
    LeftSide -> 4 -- to avoid overlap with Either
    RightSide -> 5 --

instance Builder Self where
  build = into_element

instance IntoNative Tooltip Self where
  toNative details = do
    content <- elementToNative details.content
    tooltipElement <- elementToNative details.tooltipElement
    let position = positionToNative details.position
    tooltip_new content tooltipElement position

instance UseAttribute Self Attribute where
  useAttribute attribute = case attribute of
    Gap value -> useGap value
    AddPadding value -> useFn tooltip_padding value
    SnapWithViewport snap -> useSnapWithViewport snap

instance UsePadding Attribute where
  padding = AddPadding

tooltip :: [Attribute] -> Element -> Element -> Position -> Element
tooltip attributes content tooltipElement position = pack Tooltip { .. } attributes

gap :: Float -> Attribute
gap = Gap

useGap :: Float -> AttributeFn
useGap value self = tooltip_gap self (CFloat value)

snapWithViewport :: Bool -> Attribute
snapWithViewport = SnapWithViewport

useSnapWithViewport :: Bool -> AttributeFn
useSnapWithViewport snap self =
  tooltip_snap_within_viewport self (fromBool snap)
