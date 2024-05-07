open HyperSwitchAuthTypes
@react.component
let make = (~children) => {
  let url = RescriptReactRouter.useUrl()
  let (currentAuthState, setCurrentAuthState) = React.useState(_ => CheckingAuthStatus)

  let setAuthStatus = React.useCallback1((newAuthStatus: HyperSwitchAuthTypes.authStatus) => {
    switch newAuthStatus {
    | LoggedIn(info) => LocalStorage.setItem("login", info.token)
    | LoggedOut
    | CheckingAuthStatus => ()
    }
    setCurrentAuthState(_ => newAuthStatus)
  }, [setCurrentAuthState])

  React.useEffect0(() => {
    switch url.path {
    | list{"user", "verify_email"}
    | list{"user", "set_password"}
    | list{"user", "accept_invite_from_email"}
    | list{"user", "login"}
    | list{"register"} =>
      setAuthStatus(LoggedOut)
    | _ =>
      switch LocalStorage.getItem("login")->Nullable.toOption {
      | Some(token) =>
        if !(token->LogicUtils.isEmptyString) {
          setAuthStatus(LoggedIn(HyperSwitchAuthTypes.getDummyAuthInfoForToken(token)))
        } else {
          setAuthStatus(LoggedOut)
        }
      | None => setAuthStatus(LoggedOut)
      }
    }

    None
  })

  <div className="font-inter-style">
    <AuthInfoProvider>
      {switch currentAuthState {
      | LoggedOut => <HyperSwitchAuthScreen setAuthStatus />
      | LoggedIn(_token) => children
      | CheckingAuthStatus => <Loader />
      }}
    </AuthInfoProvider>
  </div>
}
