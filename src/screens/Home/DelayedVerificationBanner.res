open APIUtils

@react.component
let make = (~merchantId="", ~verificationDays) => {
  open CommonAuthHooks
  let updateDetails = useUpdateMethod(~showErrorToast=false)
  let showToast = ToastState.useShowToast()
  let showPopUp = PopUpState.useShowPopUp()
  let getURL = useGetURL()
  let {email} = useCommonAuthInfo()->Option.getOr(defaultAuthInfo)
  let authId = HyperSwitchEntryUtils.getSessionData(~key="auth_id")

  let verificationMessage = `${verificationDays->Int.toString} ${verificationDays === 1
      ? "day"
      : "days"} to go!`

  let openVerifiedPopUp = (~heading, ~description, ~isApiFailed, ~retryFunction) => {
    showPopUp({
      popUpType: (Primary, WithIcon),
      heading,
      description: description->React.string,
      handleConfirm: {
        text: isApiFailed ? "RETRY" : "OK",
        onClick: _ => {
          isApiFailed ? retryFunction() : ()
        },
      },
    })
  }

  let rec resendEmailVerify = async () => {
    let body = email->CommonAuthUtils.getEmailBody
    try {
      let url = getURL(
        ~entityName=USERS,
        ~userType=#VERIFY_EMAIL_REQUEST,
        ~methodType=Post,
        ~queryParamerters=Some(`auth_id=${authId}`),
      )
      let _ = await updateDetails(url, body, Post)
      showToast(~message=`Email Send Successfully!`, ~toastType=ToastSuccess)
    } catch {
    | _ =>
      openVerifiedPopUp(
        ~heading="Failed to send email",
        ~description="Please retry sending an email or try again after some time in case the issue persists!",
        ~isApiFailed=true,
        ~retryFunction={_ => resendEmailVerify()->ignore},
      )
    }
  }

  <div
    className={`flex justify-center items-center text-lg bg-orange-100 dark:text-black rounded-bl-lg rounded-br-lg px-10 py-2 whitespace-nowrap`}>
    <span className="font-bold mr-1"> {`${verificationMessage}`->React.string} </span>
    <span
      className="hover:underline text-orange-900 cursor-pointer font-bold ml-1 underline underline-offset-2"
      onClick={_ => resendEmailVerify()->ignore}>
      {"Verify"->React.string}
    </span>
    <span className="ml-1 font-medium">
      {"your email address for uninterrupted access. "->React.string}
    </span>
  </div>
}
