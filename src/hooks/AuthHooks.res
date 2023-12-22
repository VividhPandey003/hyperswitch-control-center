open Promise
type sessionStorage = {
  getItem: (. string) => Js.Nullable.t<string>,
  setItem: (. string, string) => unit,
  removeItem: (. string) => unit,
}

@val external sessionStorage: sessionStorage = "sessionStorage"

external dictToObj: Js.Dict.t<'a> => {..} = "%identity"
@val external atob: string => string = "atob"

let getHeaders = (~uri, ~headers, ()) => {
  let hyperSwitchToken = LocalStorage.getItem("login")->Js.Nullable.toOption
  let isMixpanel = uri->Js.String2.includes("mixpanel")

  Js.log2(uri, "uri")

  if isMixpanel {
    let headerObj = {
      "Content-Type": "application/x-www-form-urlencoded",
      "accept": "application/json",
    }
    Fetch.HeadersInit.make(headerObj)
  } else {
    let headerObj =
      headers->Js.Dict.get("api-key")->Belt.Option.getWithDefault("")->Js.String2.length > 0

    if headerObj {
      let headerObj = {
        "Content-Type": "application/json",
        "api-key": headers->Js.Dict.get("api-key")->Belt.Option.getWithDefault(""),
      }
      Fetch.HeadersInit.make(headerObj)
    } else {
      switch hyperSwitchToken {
      | Some(token) =>
        if token !== "" {
          if (
            uri->Js.String2.includes("lottie-files") ||
              uri->Js.String2.includes("config/merchant-access")
          ) {
            let headerObj = {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${hyperSwitchToken->Belt.Option.getWithDefault("")}`,
              "api-key": "hyperswitch",
            }
            Js.log2(headerObj, "headerObjheaderObjheaderObjheaderObj")
            Fetch.HeadersInit.make(headerObj)
          } else {
            let headerObj = {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${hyperSwitchToken->Belt.Option.getWithDefault("")}`,
              "api-key": "hyperswitch",
              "x-feature": "hyperswitch-custom",
            }
            Fetch.HeadersInit.make(headerObj)
          }
        } else {
          let headerObj = {
            "Content-Type": "application/json",
          }
          Fetch.HeadersInit.make(headerObj)
        }

      | None =>
        let headerObj = {
          "Content-Type": "application/json",
        }
        Fetch.HeadersInit.make(headerObj)
      }
    }
  }
}

@val @scope(("window", "location"))
external hostName: string = "host"

type betaEndpoint = {
  betaApiStr: string,
  originalApiStr: string,
  replaceStr: string,
}

let useApiFetcher = () => {
  let (authStatus, setAuthStatus) = React.useContext(AuthInfoProvider.authStatusContext)

  let token = React.useMemo1(() => {
    switch authStatus {
    | LoggedIn(info) => Some(info.token)
    | _ => None
    }
  }, [authStatus])
  let setReqProgress = Recoil.useSetRecoilState(ApiProgressHooks.pendingRequestCount)

  React.useCallback1(
    (
      uri,
      ~bodyStr: string="",
      ~headers=Js.Dict.empty(),
      ~bodyHeader as _=?,
      ~method_: Fetch.requestMethod,
      ~authToken as _=?,
      ~requestId as _=?,
      ~disableEncryption as _=false,
      ~storageKey as _=?,
      ~betaEndpointConfig=?,
      (),
    ) => {
      let uri = switch betaEndpointConfig {
      | Some(val) => Js.String2.replace(uri, val.replaceStr, val.originalApiStr)
      | None => uri
      }

      let body = switch method_ {
      | Get => resolve(None)
      | _ => resolve(Some(Fetch.BodyInit.make(bodyStr)))
      }

      body->then(body => {
        setReqProgress(. p => p + 1)
        Fetch.fetchWithInit(
          uri,
          Fetch.RequestInit.make(
            ~method_,
            ~body?,
            ~credentials=SameOrigin,
            ~headers=getHeaders(~headers, ~uri, ()),
            (),
          ),
        )
        ->catch(
          err => {
            setReqProgress(. p => p - 1)
            reject(err)
          },
        )
        ->then(
          resp => {
            setReqProgress(. p => p - 1)
            if resp->Fetch.Response.status === 401 {
              switch authStatus {
              | LoggedIn(_) =>
                LocalStorage.clear()
                setAuthStatus(LoggedOut)
                RescriptReactRouter.push("/login")
                resolve(resp)

              | _ => resolve(resp)
              }
            } else {
              resolve(resp)
            }
          },
        )
      })
    },
    [token],
  )
}
