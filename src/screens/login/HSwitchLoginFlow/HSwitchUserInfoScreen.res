@react.component
let make = () => {
  open HyperSwitchAuthTypes
  open APIUtils

  let url = RescriptReactRouter.useUrl()
  let updateDetails = useUpdateMethod()
  let fetchDetails = APIUtils.useGetMethod()
  let (errorMessage, setErrorMessage) = React.useState(_ => "")
  let {setIsSidebarDetails} = React.useContext(SidebarProvider.defaultContext)
  let {setAuthStatus} = React.useContext(AuthInfoProvider.authStatusContext)

  let userInfo = async () => {
    open HSwitchLoginUtils
    open LogicUtils
    try {
      // TODO: user info api call
      let token = getSptTokenType()
      let url = getURL(~entityName=USERS, ~userType=#USER_INFO, ~methodType=Get, ())
      Js.log2("url", url)
      let response = await fetchDetails(url)
      let email = response->getDictFromJsonObject->getString("email", "")
      let token = HyperSwitchAuthUtils.parseResponseJson(~json=response, ~email)
      setAuthStatus(LoggedIn(HSwitchLoginUtils.getDummyAuthInfoForToken(token, DASHBOARD_ENTRY)))
    } catch {
    | _ => setAuthStatus(LoggedOut)
    }
  }

  React.useEffect0(() => {
    Js.log("Log in User Infi")
    userInfo()->ignore
    None
  })

  <HSwitchUtils.BackgroundImageWrapper customPageCss="font-semibold md:text-3xl p-16">
    {if errorMessage->String.length !== 0 {
      <div className="flex flex-col justify-between gap-32 flex items-center justify-center h-2/3">
        <Icon
          name="hyperswitch-text-icon"
          size=40
          className="cursor-pointer w-60"
          parentClass="flex flex-col justify-center items-center bg-white"
        />
        <div className="flex flex-col justify-between items-center gap-12 ">
          <img src={`/assets/WorkInProgress.svg`} />
          <div
            className={`leading-4 ml-1 mt-2 text-center flex items-center flex-col gap-6 w-full md:w-133 flex-wrap`}>
            <div className="flex gap-2.5 items-center">
              <Icon name="exclamation-circle" size=22 className="fill-red-500 mr-1.5" />
              <p className="text-fs-20 font-bold text-white">
                {React.string("Invalid Link or session expired")}
              </p>
            </div>
            <p className="text-fs-14 text-white opacity-60 font-semibold ">
              {"It appears that the link you were trying to access has expired or is no longer valid. Please try again ."->React.string}
            </p>
          </div>
          <Button
            text="Go back to login"
            buttonType={Primary}
            buttonSize={Small}
            customButtonStyle="cursor-pointer cursor-pointer w-5 rounded-md"
            onClick={_ => {
              RescriptReactRouter.replace(HSwitchGlobalVars.appendDashboardPath(~url="/login"))
              // setAuthType(_ => HyperSwitchAuthTypes.LoginWithEmail)
            }}
          />
        </div>
      </div>
    } else {
      <div className="h-full w-full flex justify-center items-center text-white opacity-90">
        {"You will be redirecting to the dashbord.."->React.string}
      </div>
    }}
  </HSwitchUtils.BackgroundImageWrapper>
}
