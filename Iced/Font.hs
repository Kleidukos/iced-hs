{-# LANGUAGE TemplateHaskell #-}

module Iced.Font (includeBytes) where

import qualified Data.ByteString as ByteString
import Language.Haskell.TH
import Language.Haskell.TH.Syntax

includeBytes :: FilePath -> Q Exp
includeBytes path = do
  string <- runIO (ByteString.readFile path)
  addDependentFile path
  let bytes = ByteString.unpack string
  [| bytes |]
