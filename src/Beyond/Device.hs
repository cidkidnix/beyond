{-# LANGUAGE ImportQualifiedPost #-}
module Beyond.Device where

import System.HID qualified as HID
import Data.Word
import Data.ByteString qualified as BS
import Control.Concurrent
import Control.Monad.Trans.Reader
import Control.Monad.IO.Class
import Control.Monad

beyondVID :: Word16
beyondVID = 0x35bd

beyondPID :: Word16
beyondPID = 0x0101

setFanSpeedCommand :: Word8
setFanSpeedCommand = 0x46

setLEDCommand :: Word8
setLEDCommand = 0x4C

minFanSpeed :: Word8
minFanSpeed = 40

maxFanSpeed :: Word8
maxFanSpeed = 100


data RGB = RGB
  { red :: Word8
  , green :: Word8
  , blue :: Word8
  } deriving (Show, Eq, Ord)

data Context = Context
  { _device :: HID.Device }

formatCommand :: [Word8] -> BS.ByteString
formatCommand cmds' = do
    let cmds = 0:cmds'
        len = length $ cmds
        fill = replicate (65 - len) 0
        full = cmds <> fill
    BS.pack full

setFanSpeed :: MonadIO m => Word8 -> ReaderT Context m ()
setFanSpeed speed = do
    dev <- asks _device
    let cmd = formatCommand [setFanSpeedCommand, speed]
    a <- HID.sendFeatureReport dev cmd
    liftIO $ print a

setLEDColor :: MonadIO m => RGB -> ReaderT Context m ()
setLEDColor rgb = do
    dev <- asks _device
    let cmd = formatCommand [setLEDCommand, red rgb, green rgb, blue rgb]
    a <- HID.sendFeatureReport dev cmd
    liftIO $ print a

test :: IO ()
test = do
    void $ HID.init
    device <- getDevice
    flip runReaderT (Context device) $ do
      resp <- setFanSpeed 40
      resp' <- setLEDColor (RGB 0 0 255)
      liftIO $ print resp
      liftIO $ print resp'

-- This may hang forever if we cant connect to the device
getDevice :: IO HID.Device
getDevice = go 0
    where
        go :: Integer -> IO HID.Device
        go 5 = error "Beyond.Device.getDevice: Failed on fifth retry!"
        go n = do
          a <- HID.vendorProductSerialDevice beyondVID beyondPID Nothing
          case a of
            Nothing -> do
                threadDelay 1000000
                putStrLn $ "Try: " <> show n
                go (n + 1)
            Just dev -> pure dev



