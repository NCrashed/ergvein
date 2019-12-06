module Ergvein.Interfaces.Ergo.Scorex.Crypto.Authds where

import Data.ByteString
import Data.Serialize                     as S (Serialize (..), decode, encode, get, put)
import Data.Serialize.Get                 as S
import Data.Serialize.Put                 as S
import Data.Word

-- Commented types are the port of original scala authds.scala source file. They are not needed yet.

-- newtype LeafData = LeafData { unLeafData :: ByteString }  --  TaggedType[Array[Byte]]

-- newtype Side = Side { unSide :: Word8 }  --  TaggedType[Byte]
--   deriving (Serialize)

-- newtype ADKey = ADKey { unADKey :: ByteString }  --  TaggedType[Array[Byte]]

-- newtype ADValue = ADValue { unADValue :: ByteString }  --  TaggedType[Array[Byte]]

-- newtype Balance = Balance { unBalance :: Word8 }  --  TaggedType[Byte]
--   deriving (Serialize)

-- //33 bytes! extra byte with tree height here!
newtype ADDigest = ADDigest { unADDigest :: ByteString }  --  TaggedType[Array[Byte]]
  deriving (Eq)

instance Serialize ADDigest where
    get = ADDigest <$> S.getBytes 33
    put = S.putByteString . unADDigest