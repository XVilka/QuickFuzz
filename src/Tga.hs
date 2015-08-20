{-# LANGUAGE TemplateHaskell, FlexibleInstances#-}

module QuickTga where

import Test.QuickCheck
import Check

import Control.Monad.Zip
import Control.Exception
import Data.Binary( Binary(..), encode )

import Codec.Picture.Types
--import Codec.Picture.Tga
import Codec.Picture.Metadata.Exif
import Codec.Picture.Metadata

import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString as B

import Data.DeriveTH
import Data.Word(Word8, Word16, Word32)
import Data.Int( Int16, Int8 )

import DeriveArbitrary

import GHC.Types
import GHC.Word

import qualified Data.Vector as V
import qualified Data.Vector.Unboxed as VU
import qualified Data.Vector.Storable as VS

import System.Process
import System.Exit


instance Arbitrary a => Arbitrary (V.Vector a) where
   arbitrary = do 
     l <- listOf arbitrary
     return $ V.fromList l

instance (VU.Unbox a, Arbitrary a) => Arbitrary (VU.Vector a) where
   arbitrary = do 
     l <- listOf arbitrary
     return $ VU.fromList l

instance (VS.Storable a, Arbitrary a) => Arbitrary (VS.Vector a) where
   arbitrary = do 
     l <- listOf arbitrary
     return $ VS.fromList l


instance Arbitrary B.ByteString where
   arbitrary = do 
     l <- listOf (arbitrary :: Gen Word8)
     return $ B.pack l

instance Arbitrary L.ByteString where
   arbitrary = do 
     l <- listOf (arbitrary :: Gen Word8)
     return $ L.pack l
{-
instance Arbitrary (Metadatas) where
  arbitrary = do
      w <- (arbitrary :: Gen Word)
      s <- (arbitrary :: Gen String)
      d <- (arbitrary :: Gen Double) 
      sf <- (arbitrary :: Gen SourceFormat)
      return $ Metadatas { getMetadatas = [ Format :=> sf, Gamma :=> d,  DpiX :=> w, DpiY :=> w, Width :=> w, Height :=> w, Title :=> s] }
-}
instance Arbitrary (Image PixelYCbCr8) where
   arbitrary = do
       l <- listOf (arbitrary :: Gen (PixelBaseComponent PixelYCbCr8))
       w <- (arbitrary :: Gen Int)
       h <- (arbitrary :: Gen Int)
       return $ Image { imageWidth = w, imageHeight = h, imageData = VS.fromList [1] }

instance Show (Image PixelYCbCr8) where
   show x = ""
{-
derive makeArbitrary ''ExifTag
derive makeArbitrary ''IfdType
derive makeArbitrary ''ExifData
derive makeArbitrary ''JpgAdobeApp14
derive makeArbitrary ''JFifUnit
derive makeArbitrary ''AdobeTransform

derive makeArbitrary ''JpgJFIFApp0
derive makeArbitrary ''ImageFileDirectory

derive makeArbitrary ''DctComponent
derive makeArbitrary ''JpgQuantTableSpec
derive makeArbitrary ''JpgHuffmanTableSpec
derive makeArbitrary ''JpgScanSpecification
derive makeArbitrary ''JpgScanHeader
derive makeArbitrary ''JpgFrameKind
derive makeArbitrary ''JpgComponent
derive makeArbitrary ''JpgFrameHeader
derive makeArbitrary ''JpgFrame
derive makeArbitrary ''JpgImage
derive makeArbitrary ''SourceFormat
-}
-- $(deriveArbitraryRec ''TgaImage)

--type MJpgImage  = (Word8,Metadatas, Image PixelYCbCr8)
--encodeJpgImage (quality, metas, img) = encodeJpegAtQualityWithMetadata quality metas img

--type TgaImage = TgaFile

--mencode :: TgaFile -> L.ByteString
mencode = (encode :: TgaFile -> L.ByteString) --JpgImage

main = quickCheckWith stdArgs { maxSuccess = 1200000, maxSize = 500 } ( noShrinking $ absprop "buggy_qc.jp2" "bins/pixbuf_vuln_poc" ["buggy_qc.jp2"] mencode)

--main = quickCheckWith stdArgs { maxSuccess = 1200000, maxSize = 100 } (noShrinking $ absprop "buggy_qc.jp2" "/usr/bin/jasper" ["--input", "buggy_qc.jp2", "--output-format", "pnm"] mencode)



{--
type MJpegFile  = (Word8,Metadatas, Image PixelYCbCr8)

encodeJpegFile (quality, metas, img) = encodeJpegAtQualityWithMetadata quality metas img

filenames = take 11 (repeat "buggy_qc.jpg")

instance Arbitrary (Image PixelYCbCr8) where
   arbitrary = do
       l <- listOf (arbitrary :: Gen (PixelBaseComponent PixelYCbCr8))
       w <- (arbitrary :: Gen Int)
       h <- (arbitrary :: Gen Int)
       return $ Image { imageWidth = w, imageHeight = h, imageData = VS.fromList l }

handler :: SomeException -> IO ()
handler _ = return ()
 
main = do
  jpgs  <- sample' (resize 10 (arbitrary :: Gen MJpegFile))
  mapM_ (\(filename,jpg) -> 
      do
       catch (L.writeFile filename (encodeJpegFile jpg)) handler
       --ret <- rawSystem "/usr/bin/valgrind" ["--error-exitcode=-1", "/usr/bin/jpeginfo","buggy.jpg"]
       r <- (randomIO :: IO Int)
       ret <- rawSystem "/usr/bin/zzuf" ["-q", "-s", (show (r `mod` 10024))++":"++(show (r `mod` 10024 + 1)), "-Ix", "-M-1", "-c", "-S", "-T", "2", "/usr/bin/file", "buggy_qc.jpg"]

       --ret <- rawSystem "/usr/bin/zzuf" ["-s", "0:100","-c", "-S", "-T", "3", "/usr/bin/identify.im6", "buggy.jpg"]
       case ret of
        ExitFailure x -> ( do 
                            putStrLn (show x) 
                            exitWith ret)
        _             -> return ()
     ) (zip filenames jpgs)
  main

-}