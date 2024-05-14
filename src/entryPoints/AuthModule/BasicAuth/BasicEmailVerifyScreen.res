@react.component
let make = (~setAuthType) => {
  open AuthProviderTypes
  open APIUtils
  open LogicUtils
  let {setAuthStatus} = React.useContext(AuthInfoProvider.authStatusContext)
  let getURL = useGetURL()
  let url = RescriptReactRouter.useUrl()
  let updateDetails = useUpdateMethod()
  let (errorMessage, setErrorMessage) = React.useState(_ => "")
  let {setIsSidebarDetails} = React.useContext(SidebarProvider.defaultContext)
  let emailVerifyUpdate = async body => {
    try {
      let url = getURL(~entityName=USERS, ~methodType=Post, ~userType={#VERIFY_EMAILV2}, ())
      let res = await updateDetails(url, body, Post, ())
      let typedAuthInfo = res->BasicAuthUtils.setLoginResToStorage
      await HyperSwitchUtils.delay(1000)
      if typedAuthInfo.token->Option.isSome && typedAuthInfo.email->Option.isSome {
        setAuthStatus(LoggedIn(BasicAuth(typedAuthInfo)))
        setIsSidebarDetails("isPinned", false->JSON.Encode.bool)
      } else {
        setAuthStatus(LoggedOut)
        RescriptReactRouter.push(HSwitchGlobalVars.appendDashboardPath(~url="/login"))
      }
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Verification Failed")
        setErrorMessage(_ => err)
        setAuthStatus(LoggedOut)
      }
    }
  }

  React.useEffect0(() => {
    open CommonAuthUtils
    let tokenFromUrl = url.search->getDictFromUrlSearchParams->Dict.get("token")

    switch tokenFromUrl {
    | Some(token) => token->generateBodyForEmailRedirection->emailVerifyUpdate->ignore
    | None => setErrorMessage(_ => "Token not received")
    }
    None
  })
  let onClick = () => {
    RescriptReactRouter.replace(HSwitchGlobalVars.appendDashboardPath(~url="/login"))
    setAuthType(_ => CommonAuthTypes.LoginWithEmail)
  }

  <EmailVerifyScreen
    errorMessage onClick trasitionMessage="Verifing... You will be redirecting.."
  />
}
