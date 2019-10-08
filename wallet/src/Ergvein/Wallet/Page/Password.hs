module Ergvein.Wallet.Page.Password(
    passwordPage
  ) where

import Ergvein.Wallet.Elements
import Ergvein.Wallet.Monad
import Ergvein.Wallet.Password

passwordPage :: MonadFront t m => m ()
passwordPage = container $ do
  divClass "password-setup-title" $ h4 $ text "Setup encryption password for your wallet"
  divClass "password-setup-descr" $ h5 $ text "The password is used every time you perform an operation with your money. Leave the fields empty to set no password for your wallet."
  void $ setupPassword