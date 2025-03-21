module Iced.Style.Internal where

import Iced.Color

class UseBackground attribute where
  background :: Color -> attribute

class UseBar attribute where
  bar :: Color -> attribute

class UseBorder attribute where
  -- color width radius
  border :: Color -> Float -> Float -> attribute

class UseBorderColor attribute where
  borderColor :: Color -> attribute

class UseBorderWidth attribute where
  borderWidth :: Float -> attribute

class UseDotColor attribute where
  dotColor :: Color -> attribute

class UseIconColor attribute where
  iconColor :: Color -> attribute

class UseHandleColor attribute where
  handleColor :: Color -> attribute

class UsePlaceholderColor attribute where
  placeholderColor :: Color -> attribute

class UseTextColor attribute where
  textColor :: Color -> attribute

class UseSelectionColor attribute where
  selectionColor :: Color -> attribute
