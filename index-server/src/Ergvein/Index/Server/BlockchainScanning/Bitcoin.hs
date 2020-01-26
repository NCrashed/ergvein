module Ergvein.Index.Server.BlockchainScanning.Bitcoin where

import           Data.Either
import           Data.List.Index
import           Data.Maybe
import           Network.Bitcoin.Api.Blockchain
import           Network.Bitcoin.Api.Client

import           Ergvein.Index.Server.BlockchainScanning.Types
import           Ergvein.Index.Server.Config
import           Ergvein.Index.Server.Environment
import           Ergvein.Types.Transaction
import           Ergvein.Types.Currency
import           Ergvein.Crypto.SHA256

import Data.Serialize
import qualified Data.ByteString                    as B
import qualified Data.HexString                     as HS
import qualified Network.Haskoin.Block              as HK
import qualified Network.Haskoin.Crypto             as HK
import qualified Network.Haskoin.Transaction        as HK
import qualified Network.Haskoin.Util               as HK

txInfo :: HK.Tx -> TxHash -> ([TxInInfo], [TxOutInfo])
txInfo tx txHash = let
  withoutCoinbaseTx = filter $ (/= HK.nullOutPoint) . HK.prevOutput
  in (map txInInfo $ withoutCoinbaseTx $ HK.txIn tx, imap txOutInfo $ HK.txOut tx)
  where
    txInInfo txIn = let
      prevOutput = HK.prevOutput txIn
      in TxInInfo { txInTxHash     = txHash
                  , txInTxOutHash  = HK.txHashToHex $ HK.outPointHash prevOutput
                  , txInTxOutIndex = fromIntegral $ HK.outPointIndex prevOutput
                  }
    txOutInfo txOutIndex txOut = let
      scriptOutputHash = encodeSHA256Hex . doubleSHA256
      in TxOutInfo { txOutTxHash           = txHash
                   , txOutPubKeyScriptHash = scriptOutputHash $ HK.scriptOutput txOut
                   , txOutIndex            = fromIntegral txOutIndex
                   , txOutValue            = HK.outValue txOut
                   }

blockTxInfos :: HK.Block -> BlockHeight -> BlockInfo
blockTxInfos block txBlockHeight = let
  (txInfos ,txInInfos, txOutInfos) = mconcat $ txoInfosFromTx `imap` HK.blockTxns block
  blockContent = BlockContentInfo txInfos txInInfos txOutInfos
  blockMeta = BlockMetaInfo BTC txBlockHeight blockHeaderHexView
  in BlockInfo blockMeta blockContent
  where
    blockHeaderHexView = HK.encodeHex $ encode $ HK.blockHeader block
    txoInfosFromTx txBlockIndex tx = let
      txHash = HK.txHashToHex $ HK.txHash tx
      txI = TxInfo { txHash = txHash
                   , txBlockHeight = txBlockHeight
                   , txBlockIndex  = fromIntegral txBlockIndex
                   }
      (txInI,txOutI) = txInfo tx txHash
      in ([txI], txInI, txOutI)


actualHeight :: Config -> IO BlockHeight
actualHeight cfg = fromIntegral <$> btcNodeClient cfg getBlockCount

blockInfo :: ServerEnv -> BlockHeight -> IO BlockInfo
blockInfo env blockHeightToScan = do
  blockHash <- btcNodeClient cfg $ flip getBlockHash $ fromIntegral blockHeightToScan
  maybeRawBlock <- btcNodeClient cfg $ flip getBlockRaw blockHash
  let rawBlock = fromMaybe blockParsingError maybeRawBlock
      parsedBlock = fromRight blockGettingError $ decode $ HS.toBytes rawBlock
  pure $ blockTxInfos parsedBlock blockHeightToScan
  where
    cfg    = envServerConfig env
    dbPool = envPersistencePool env
    blockGettingError = error $ "Error getting BTC node at height " ++ show blockHeightToScan
    blockParsingError = error $ "Error parsing BTC node at height " ++ show blockHeightToScan