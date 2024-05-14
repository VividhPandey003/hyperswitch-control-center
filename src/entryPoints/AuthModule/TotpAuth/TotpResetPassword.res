@react.component
let make = (~flowType) => {
  open APIUtils
  open LogicUtils
  open FramerMotion.Motion
  open CommonAuthTypes
  open CommonAuthUtils
  open CommonAuthForm

  let getURL = useGetURL()

  let initialValues = Dict.make()->JSON.Encode.object
  let showToast = ToastState.useShowToast()
  let updateDetails = useUpdateMethod(~showErrorToast=false, ())
  let {authStatus, setAuthStatus} = React.useContext(AuthInfoProvider.authStatusContext)

  let setResetPassword = async body => {
    try {
      let url = getURL(
        ~entityName=USERS,
        ~userType=#RESET_PASSWORD_TOKEN_ONLY,
        ~methodType=Post,
        (),
      )
      let _ = await updateDetails(url, body, Post, ())

      LocalStorage.clear()
      showToast(~message=`Password Changed Successfully`, ~toastType=ToastSuccess, ())
      RescriptReactRouter.replace(HSwitchGlobalVars.appendDashboardPath(~url=`/login`))
    } catch {
    | _ => showToast(~message="Password Reset Failed, Try again", ~toastType=ToastError, ())
    }
    setAuthStatus(LoggedOut)
  }

  let rotatePassword = async password => {
    try {
      let url = getURL(~entityName=USERS, ~userType=#ROTATE_PASSWORD, ~methodType=Post, ())
      let body = [("password", password->JSON.Encode.string)]->getJsonFromArrayOfJson
      let _ = await updateDetails(url, body, Post, ())
      setAuthStatus(LoggedOut)
      LocalStorage.clear()
      showToast(~message=`Password Changed Successfully`, ~toastType=ToastSuccess, ())
      RescriptReactRouter.replace(HSwitchGlobalVars.appendDashboardPath(~url=`/login`))
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Something went wrong")
        let errorCode = err->safeParse->getDictFromJsonObject->getString("code", "")
        let errorMessage = err->safeParse->getDictFromJsonObject->getString("message", "")

        if errorCode === "UR_29" {
          showToast(~message=errorMessage, ~toastType=ToastError, ())
        } else {
          showToast(~message="Password Reset Failed, Try again", ~toastType=ToastError, ())
          setAuthStatus(LoggedOut)
        }
      }
    }
  }

  let {branding} = HyperswitchAtom.featureFlagAtom->Recoil.useRecoilValueFromAtom

  let (logoVariant, iconUrl) = switch (Window.env.logoUrl, branding) {
  | (Some(url), true) => (IconWithURL, Some(url))
  | (Some(url), false) => (IconWithURL, Some(url))
  | _ => (IconWithText, None)
  }

  let confirmButtonAction = password => {
    open TotpTypes
    open TotpUtils
    switch flowType {
    | FORCE_SET_PASSWORD => rotatePassword(password)->ignore
    | _ => {
        let emailToken = authStatus->getEmailToken
        switch emailToken {
        | Some(email_token) => {
            let body = getResetpasswordBodyJson(password, email_token)
            setResetPassword(body)->ignore
          }
        | None => setAuthStatus(LoggedOut)
        }
      }
    }
  }

  let onSubmit = async (values, _) => {
    try {
      let valuesDict = values->getDictFromJsonObject
      let password = getString(valuesDict, "create_password", "")
      confirmButtonAction(password)
    } catch {
    | _ => showToast(~message="Something went wrong, Try again", ~toastType=ToastError, ())
    }
    Nullable.null
  }

  let headerText = switch flowType {
  | FORCE_SET_PASSWORD => "Set password"
  | _ => "Reset password"
  }

  React.useEffect0(_ => {
    open HSwitchGlobalVars
    RescriptReactRouter.replace(appendDashboardPath(~url="/reset_password"))
    None
  })

  <HSwitchUtils.BackgroundImageWrapper
    customPageCss="flex flex-col items-center justify-center overflow-scroll ">
    <div
      className="h-full flex flex-col items-center justify-between overflow-scoll text-grey-0 w-full mobile:w-30-rem">
      <div className="flex flex-col items-center justify-center gap-6 flex-1 mt-4 w-30-rem">
        <Div layoutId="form" className="bg-white w-full text-black mobile:border rounded-lg">
          <div className="px-7 py-6">
            <Div layoutId="logo">
              <HyperSwitchLogo logoHeight="h-8" theme={Dark} logoVariant iconUrl />
            </Div>
          </div>
          <Div layoutId="border" className="border-b w-full" />
          <div className="p-7">
            <ReactFinalForm.Form
              key="auth"
              initialValues
              subscription=ReactFinalForm.subscribeToValues
              validate={values =>
                TotpUtils.validateTotpForm(values, ["create_password", "comfirm_password"])}
              onSubmit
              render={({handleSubmit}) => {
                <div className="flex flex-col gap-6">
                  <h1 id="card-header" className="font-semibold text-xl md:text-2xl">
                    {headerText->React.string}
                  </h1>
                  <form
                    onSubmit={handleSubmit}
                    className={`flex flex-col justify-evenly gap-5 h-full w-full !overflow-visible text-grey-600`}>
                    <ResetPasswordForm />
                    <div id="auth-submit-btn" className="flex flex-col gap-2">
                      <FormRenderer.SubmitButton
                        customSumbitButtonStyle="!w-full !rounded"
                        text="Confirm"
                        userInteractionRequired=true
                        showToolTip=false
                        loadingText="Loading..."
                      />
                    </div>
                  </form>
                </div>
              }}
            />
          </div>
        </Div>
      </div>
    </div>
  </HSwitchUtils.BackgroundImageWrapper>
}
