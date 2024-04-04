{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE RecordWildCards #-}

module Iced.Widget.Row (
  row,
  alignItems,
  padding,
  spacing,
) where

import Foreign
import Foreign.C.Types

import Iced.Alignment
import Iced.AlignmentFFI
import Iced.Element
import Iced.Spacing
import Iced.Padding

data NativeRow
type SelfPtr = Ptr NativeRow
type AttributeFn = SelfPtr -> IO SelfPtr

data Attribute = Spacing Float | AddPadding Padding | AlignItems Alignment

-- this function is for future use, commented to hide warnings
--foreign import ccall safe "new_row"
--  new_row :: IO (SelfPtr)

foreign import ccall safe "row_align_items"
  row_align_items :: SelfPtr -> AlignmentPtr -> IO (SelfPtr)

-- column top right bottom left
foreign import ccall safe "row_padding"
  row_padding :: SelfPtr -> CFloat -> CFloat -> CFloat -> CFloat -> IO (SelfPtr)

-- row value
foreign import ccall safe "row_spacing"
  row_spacing :: SelfPtr -> CFloat -> IO (SelfPtr)

foreign import ccall safe "row_with_children"
  row_with_children :: CInt -> Ptr ElementPtr -> IO (SelfPtr)

-- this function is for future use, commented to hide warnings
--foreign import ccall safe "row_extend"
--  row_extend :: SelfPtr -> CInt -> Ptr ElementPtr -> IO (SelfPtr)

foreign import ccall safe "row_into_element"
  row_into_element :: SelfPtr -> IO (ElementPtr)

data Row = Row { attributes :: [Attribute], children :: [Element] }

instance IntoNative Row where
  toNative details = do
    elements <- buildElements details.children []
    let len = (length elements)
    elementsPtr <- newArray elements
    selfPtr <- row_with_children (fromIntegral len) elementsPtr
    free elementsPtr
    updatedSelf <- applyAttributes selfPtr details.attributes
    row_into_element updatedSelf

instance UseAttribute SelfPtr Attribute where
  useAttribute selfPtr attribute = do
    case attribute of
      Spacing value -> useSpacing value selfPtr
      AddPadding value -> usePadding value selfPtr
      AlignItems value -> useAlignItems value selfPtr

instance UseAlignment Attribute where
  alignItems value = AlignItems value

instance UsePadding Attribute where
  paddingToAttribute value = AddPadding value

instance UseSpacing Attribute where
  spacing value = Spacing value

row :: [Attribute] -> [Element] -> Element
row attributes children = pack Row { .. }

useAlignItems :: Alignment -> AttributeFn
useAlignItems value selfPtr = do
  let nativeAlignment = alignmentToNative value
  row_align_items selfPtr nativeAlignment

usePadding :: Padding -> AttributeFn
usePadding Padding { .. } selfPtr = do
  row_padding selfPtr (CFloat top) (CFloat right) (CFloat bottom) (CFloat left)

useSpacing :: Float -> AttributeFn
useSpacing value selfPtr = do
  row_spacing selfPtr (CFloat value)
