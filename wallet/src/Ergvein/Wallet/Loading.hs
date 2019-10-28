{-# LANGUAGE OverloadedLists #-}

module Ergvein.Wallet.Loading
  (
    loadingWidget
  ) where

import Control.Monad.IO.Class
import Data.Time

import Ergvein.Text
import Ergvein.Wallet.Monad

percentDyn :: MonadFront t m => NominalDiffTime -> m (Dynamic t Int)
percentDyn dt = do
  buildE <- getPostBuild
  (eE, fire) <- newTriggerEvent
  tickE <- delay dt $ leftmost [buildE, eE]
  performEvent_ $ (liftIO $ fire ()) <$ tickE
  foldDyn (\_ v -> if v == 100 then 0 else v + 10) 0 tickE

loadingWidget :: forall t m . MonadFront t m => m ()
loadingWidget = do
  triggerE <- fmap fst getLoadingWidgetTF
  backE <- getBackEvent
  let toggleE = leftmost [("", False) <$ backE, triggerE]
  tglD <- holdUniqDyn =<< holdDyn ("", False) toggleE
  widgetHold (pure ()) $ ffor (updated tglD) $ \(t, b) -> if not b
    then pure ()
    else divClass "loading-page" $ divClass "loading-box" $ do
      el "h5" $ text t
      divClass "loading__bar" $ do
        percD <- percentDyn 0.15
        let attrD' = ffor percD $ \v -> [
                ("class", "loading__status")
              , ("style", "width: " <> showt v <> "%;")]
        elDynAttr "div" attrD' $ pure ()
  pure ()