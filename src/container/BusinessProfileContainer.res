/*
Modules that depend on Business Profiles data are located within this container.
 */
@react.component
let make = () => {
  open HSwitchUtils
  open HyperswitchAtom
  let url = RescriptReactRouter.useUrl()
  let featureFlagDetails = featureFlagAtom->Recoil.useRecoilValueFromAtom
  let fetchBusinessProfiles = BusinessProfileHook.useFetchBusinessProfiles()
  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Loading)
  let setUpBussinessProfileContainer = async () => {
    try {
      setScreenState(_ => PageLoaderWrapper.Loading)
      let _ = await fetchBusinessProfiles()
      setScreenState(_ => PageLoaderWrapper.Success)
    } catch {
    | _ => setScreenState(_ => PageLoaderWrapper.Error(""))
    }
  }

  React.useEffect(() => {
    setUpBussinessProfileContainer()->ignore
    None
  }, [])
  <PageLoaderWrapper screenState={screenState} sectionHeight="!h-screen" showLogoutButton=true>
    {switch url.path->urlPath {
    // Business Profile Modules
    | list{"business-details"} =>
      <AccessControl isEnabled=featureFlagDetails.default permission={Access}>
        <BusinessDetails />
      </AccessControl>
    | list{"business-profiles", ...remainingPath} =>
      <AccessControl permission=Access>
        <EntityScaffold
          entityName="BusinessProfile"
          remainingPath
          renderList={() => <BusinessProfile />}
          renderShow={(_, _) => <BusinessProfileDetails webhookOnly=false showFormOnly=false />}
        />
      </AccessControl>
    | list{"unauthorized"} => <UnauthorizedPage />
    | _ => <NotFoundPage />
    }}
  </PageLoaderWrapper>
}
