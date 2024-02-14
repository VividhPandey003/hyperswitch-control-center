open HyperSwitchAuthTypes

module TermsAndCondition = {
  @react.component
  let make = () => {
    <div id="tc-text" className="text-center text-sm text-infra-gray-300">
      {"By continuing, you agree to our "->React.string}
      <a
        className="underline cursor-pointer"
        href="https://hyperswitch.io/terms-of-services"
        target="__blank">
        {"Terms of Service"->React.string}
      </a>
      {" & "->React.string}
      <a
        className="underline cursor-pointer"
        href="https://hyperswitch.io/privacyPolicy"
        target="__blank">
        {"Privacy Policy"->React.string}
      </a>
    </div>
  }
}

let flowTypeStrToVariantMapper = val => {
  switch val {
  | Some("merchant_select") => MERCHANT_SELECT
  | Some("dashboard_entry") => DASHBOARD_ENTRY
  | Some(_) => ERROR
  | None => ERROR
  }
}

let emailField = FormRenderer.makeFieldInfo(
  ~label="Email",
  ~name="email",
  ~placeholder="Enter your Email",
  ~isRequired=false,
  ~customInput=InputFields.textInput(~autoComplete="off", ()),
  (),
)

let createPasswordField = FormRenderer.makeFieldInfo(
  ~label="Password",
  ~name="create_password",
  ~placeholder="Enter your Password",
  ~type_="password",
  ~customInput=InputFields.passwordMatchField(
    ~leftIcon={
      <Icon name="password-lock" size=13 />
    },
    (),
  ),
  ~isRequired=false,
  (),
)

let confirmPasswordField = FormRenderer.makeFieldInfo(
  ~label="Confirm Password",
  ~name="comfirm_password",
  ~placeholder="Re-enter your Password",
  ~type_="password",
  ~customInput=InputFields.textInput(
    ~type_="password",
    ~autoComplete="off",
    ~leftIcon={
      <Icon name="password-lock" size=13 />
    },
    (),
  ),
  ~isRequired=false,
  (),
)

let passwordField = FormRenderer.makeFieldInfo(
  ~label="Password",
  ~name="password",
  ~placeholder="Enter your Password",
  ~type_="password",
  ~customInput=InputFields.textInput(
    ~type_="password",
    ~autoComplete="off",
    ~leftIcon={
      <Icon name="password-lock" size=13 />
    },
    (),
  ),
  ~isRequired=false,
  (),
)

let getResetpasswordBodyJson = (password, token) =>
  [("password", password->JSON.Encode.string), ("token", token->JSON.Encode.string)]
  ->Dict.fromArray
  ->JSON.Encode.object

let getEmailPasswordBody = (email, password, country) =>
  [
    ("email", email->JSON.Encode.string),
    ("password", password->JSON.Encode.string),
    ("country", country->JSON.Encode.string),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object

let getEmailBody = (email, ~country=?, ()) => {
  let fields = [("email", email->JSON.Encode.string)]

  switch country {
  | Some(value) => fields->Array.push(("country", value->JSON.Encode.string))->ignore
  | _ => ()
  }

  fields->Dict.fromArray->JSON.Encode.object
}

let parseResponseJson = (~json, ~email) => {
  open HSwitchUtils
  open LogicUtils
  let valuesDict = json->JSON.Decode.object->Option.getOr(Dict.make())
  let verificationValue = valuesDict->getOptionInt("verification_days_left")->Option.getOr(-1)
  let flowType = valuesDict->getOptionString("flow_type")
  let flowTypeVal = switch flowType {
  | Some(val) => val->JSON.Encode.string
  | None => JSON.Encode.null
  }

  // * Setting all local storage values
  if flowType->Option.isSome && flowType->flowTypeStrToVariantMapper === MERCHANT_SELECT {
    LocalStorage.setItem(
      "accept_invite_data",
      valuesDict->getArrayFromDict("merchants", [])->JSON.stringifyAny->Option.getOr(""),
    )
  }
  setMerchantDetails("merchant_id", valuesDict->getString("merchant_id", "")->JSON.Encode.string)
  setMerchantDetails("email", email->JSON.Encode.string)
  setMerchantDetails("verification", verificationValue->Int.toString->JSON.Encode.string)
  setUserDetails("name", valuesDict->getString("name", "")->JSON.Encode.string)
  setUserDetails("user_role", valuesDict->getString("user_role", "")->JSON.Encode.string)
  setUserDetails("flow_type", flowTypeVal)
  valuesDict->getString("token", "")
}

let validateForm = (values: JSON.t, keys: array<string>) => {
  let valuesDict = values->LogicUtils.getDictFromJsonObject

  let errors = Dict.make()
  keys->Array.forEach(key => {
    let value = LogicUtils.getString(valuesDict, key, "")

    // empty check
    if value == "" {
      switch key {
      | "email" => Dict.set(errors, key, "Please enter your Email ID"->JSON.Encode.string)
      | "password" => Dict.set(errors, key, "Please enter your Password"->JSON.Encode.string)
      | "create_password" => Dict.set(errors, key, "Please enter your Password"->JSON.Encode.string)
      | "comfirm_password" =>
        Dict.set(errors, key, "Please enter your Password Once Again"->JSON.Encode.string)
      | _ =>
        Dict.set(
          errors,
          key,
          `${key->LogicUtils.capitalizeString} cannot be empty`->JSON.Encode.string,
        )
      }
    }

    // email check
    if value !== "" && key === "email" && value->HSwitchUtils.isValidEmail {
      Dict.set(errors, key, "Please enter valid Email ID"->JSON.Encode.string)
    }

    // password check
    MerchantAccountUtils.passwordKeyValidation(value, key, "create_password", errors)

    // confirm password check
    MerchantAccountUtils.confirmPasswordCheck(
      value,
      key,
      "comfirm_password",
      "create_password",
      valuesDict,
      errors,
    )
  })

  errors->JSON.Encode.object
}

let note = (authType, setAuthType, isMagicLinkEnabled) => {
  open UIUtils
  let getFooterLinkComponent = (~btnText, ~authType, ~path) => {
    <div
      onClick={_ => {
        setAuthType(_ => authType)
        path->RescriptReactRouter.push
      }}
      className="text-sm text-center text-blue-900 cursor-pointer hover:underline underline-offset-2">
      {btnText->React.string}
    </div>
  }

  <div className="w-96">
    {switch authType {
    | LoginWithEmail =>
      getFooterLinkComponent(
        ~btnText="or sign in using password",
        ~authType=LoginWithPassword,
        ~path="/login",
      )
    | LoginWithPassword =>
      <RenderIf condition={isMagicLinkEnabled}>
        {getFooterLinkComponent(
          ~btnText="or sign in with an email",
          ~authType=LoginWithEmail,
          ~path="/login",
        )}
      </RenderIf>
    | SignUP =>
      <RenderIf condition={isMagicLinkEnabled}>
        <p className="text-center text-sm">
          {"We'll be emailing you a magic link for a password-free experience, you can always choose to setup a password later."->React.string}
        </p>
      </RenderIf>
    | ForgetPassword | MagicLinkEmailSent | ForgetPasswordEmailSent | ResendVerifyEmailSent =>
      <div className="w-full flex justify-center">
        <div
          onClick={_ => {
            let backState = switch authType {
            | MagicLinkEmailSent => SignUP
            | ForgetPasswordEmailSent => ForgetPassword
            | ResendVerifyEmailSent => ResendVerifyEmail
            | ForgetPassword | _ => LoginWithPassword
            }
            setAuthType(_ => backState)
          }}
          className="text-sm text-center text-blue-900 hover:underline underline-offset-2 cursor-pointer w-fit">
          {"Cancel"->React.string}
        </div>
      </div>
    | _ => React.null
    }}
  </div>
}

module PageFooterSection = {
  @react.component
  let make = () => {
    <div
      className="justify-center text-base flex flex-col md:flex-row md:gap-3 items-center py-5 md:py-7">
      <div id="footer" className="flex items-center gap-2">
        {"An open-source initiative by "->React.string}
        <a href="https://juspay.in/" target="__blank">
          <img src={`/icons/juspay-logo-dark.svg`} className="h-3" />
        </a>
      </div>
    </div>
  }
}

module ToggleLiveTestMode = {
  open HSwitchGlobalVars
  @react.component
  let make = (~authType, ~mode, ~setMode, ~setAuthType, ~customClass="") => {
    let liveButtonRedirectUrl = switch hostType {
    | Live | Sandbox => liveURL
    | Local => localURL
    | Netlify => netlifyUrl
    }

    let testButtonRedirectUrl = switch hostType {
    | Live | Sandbox => sandboxURL
    | Local => localURL
    | Netlify => netlifyUrl
    }

    <>
      {switch authType {
      | LoginWithPassword
      | LoginWithEmail
      | LiveMode => {
          let borderStyle = "border-b-1 border-grey-600 border-opacity-50"
          let selectedtStyle = "border-b-2 inline-block relative -bottom-px py-2"
          let testModeStyles = mode === TestButtonMode ? selectedtStyle : ""
          let liveModeStyles = mode === LiveButtonMode ? selectedtStyle : ""

          <FramerMotion.Motion.Div
            transition={{duration: 0.3}} layoutId="toggle" className="w-full">
            <div className={`w-full p-2 ${customClass} `}>
              <div className={`flex items-center ${borderStyle} gap-4`}>
                <div
                  className={`!shadow-none text-white text-start text-fs-16 font-semibold cursor-pointer flex justify-center`}
                  onClick={_ => {
                    setMode(_ => TestButtonMode)
                    setAuthType(_ => LoginWithEmail)
                    Window.Location.replace(testButtonRedirectUrl)
                  }}>
                  <span className={`${testModeStyles}`}> {"Test Mode"->React.string} </span>
                </div>
                <div
                  className={`!shadow-none text-white text-start text-fs-16 font-semibold cursor-pointer flex justify-center`}
                  onClick={_ => {
                    setMode(_ => LiveButtonMode)
                    setAuthType(_ => LoginWithEmail)
                    Window.Location.replace(liveButtonRedirectUrl)
                  }}>
                  <span className={`${liveModeStyles}`}> {"Live Mode"->React.string} </span>
                </div>
              </div>
            </div>
          </FramerMotion.Motion.Div>
        }

      | _ => React.null
      }}
    </>
  }
}

module Header = {
  @react.component
  let make = (~authType, ~setAuthType, ~email) => {
    let form = ReactFinalForm.useForm()
    let {magicLink: isMagicLinkEnabled, isLiveMode} =
      HyperswitchAtom.featureFlagAtom->Recoil.useRecoilValueFromAtom
    let headerStyle = switch authType {
    | MagicLinkEmailSent
    | ForgetPasswordEmailSent
    | ForgetPassword
    | ResendVerifyEmailSent => "flex flex-col justify-center items-center"
    | _ => "flex flex-col"
    }

    let cardHeaderText = switch authType {
    | LoginWithPassword | LoginWithEmail => "Hey there, Welcome back!"
    | SignUP => "Welcome to Hyperswitch"
    | MagicLinkEmailSent
    | ForgetPasswordEmailSent
    | ResendVerifyEmailSent => "Please check your inbox"
    | ResetPassword => "Reset Password"
    | ForgetPassword => "Forgot Password?"
    | ResendVerifyEmail => "Resend Verify Email"
    | _ => ""
    }

    let getNoteUI = info => {
      <div className="flex-col items-center justify-center">
        <div> {info->React.string} </div>
        <div className="w-full flex justify-center text-center font-bold">
          {email->React.string}
        </div>
      </div>
    }

    let getHeaderLink = (~prefix, ~authType, ~path, ~sufix) => {
      <div className="flex text-sm items-center gap-2">
        <div className="text-grey-650"> {prefix->React.string} </div>
        <div
          onClick={_ => {
            form.resetFieldState("email")
            form.reset(JSON.Encode.object(Dict.make())->Nullable.make)
            setAuthType(_ => authType)
            path->RescriptReactRouter.push
          }}
          id="card-subtitle"
          className="font-semibold text-blue-900 cursor-pointer">
          {sufix->React.string}
        </div>
      </div>
    }

    let showInfoIcon = switch authType {
    | MagicLinkEmailSent
    | ForgetPassword
    | ForgetPasswordEmailSent
    | ResendVerifyEmailSent
    | ResendVerifyEmail => true
    | _ => false
    }

    <div className={`${headerStyle} gap-2 h-fit mb-7 w-96`}>
      <UIUtils.RenderIf condition={showInfoIcon}>
        <div className="flex justify-center my-5">
          {switch authType {
          | MagicLinkEmailSent | ForgetPasswordEmailSent | ResendVerifyEmailSent =>
            <img className="w-48" src={`/assets/mail.svg`} />
          | ForgetPassword => <img className="w-24" src={`/assets/key-password.svg`} />
          | _ => React.null
          }}
        </div>
      </UIUtils.RenderIf>
      <h1 id="card-header" className="font-semibold text-xl md:text-2xl">
        {cardHeaderText->React.string}
      </h1>
      {switch authType {
      | LoginWithPassword | LoginWithEmail =>
        !isLiveMode
          ? getHeaderLink(
              ~prefix="New to Hyperswitch?",
              ~authType=SignUP,
              ~path="/register",
              ~sufix="Sign up",
            )
          : React.null

      | SignUP =>
        getHeaderLink(
          ~prefix="Already using Hyperswitch?",
          ~authType=isMagicLinkEnabled ? LoginWithEmail : LoginWithPassword,
          ~path="/login",
          ~sufix="Sign in",
        )
      | ForgetPassword =>
        <div className="text-md text-center text-grey-650 w-full max-w-md">
          {"Enter your email address associated with your account, and we'll send you a link to reset your password."->React.string}
        </div>
      | MagicLinkEmailSent => "A magic link has been sent to "->getNoteUI
      | ForgetPasswordEmailSent => "A reset password link has been sent to "->getNoteUI
      | ResendVerifyEmailSent => "A verify email link has been sent to "->getNoteUI
      | _ => React.null
      }}
    </div>
  }
}

let errorMapper = dict => {
  open LogicUtils
  {
    code: dict->getString("code", "UR_00"),
    message: dict->getString("message", "something went wrong"),
    type_: dict->getString("message", "something went wrong"),
  }
}

let parseErrorMessage = errorMessage => {
  let parsedValue = switch Exn.message(errorMessage) {
  | Some(msg) => msg->LogicUtils.safeParse
  | None => JSON.Encode.null
  }

  switch JSON.Classify.classify(parsedValue) {
  | Object(obj) => obj->errorMapper
  | String(_str) => Dict.make()->errorMapper
  | _ => Dict.make()->errorMapper
  }
}

let errorSubCodeMapper = (subCode: string) => {
  switch subCode {
  | "UR_01" => UR_01
  | "UR_03" => UR_03
  | "UR_05" => UR_05
  | "UR_16" => UR_16
  | _ => UR_00
  }
}
