type featureFlag = {
  default: bool,
  testLiveToggle: bool,
  email: bool,
  quickStart: bool,
  isLiveMode: bool,
  auditTrail: bool,
  systemMetrics: bool,
  sampleData: bool,
  frm: bool,
  payOut: bool,
  recon: bool,
  testProcessors: bool,
  feedback: bool,
  generateReport: bool,
  mixpanel: bool,
  mixpanelToken: string,
  userJourneyAnalytics: bool,
  authenticationAnalytics: bool,
  surcharge: bool,
  disputeEvidenceUpload: bool,
  paypalAutomaticFlow: bool,
  threedsAuthenticator: bool,
  globalSearch: bool,
  disputeAnalytics: bool,
  configurePmts: bool,
  branding: bool,
  totp: bool,
  liveUsersCounter: bool,
  granularity: bool,
  customWebhookHeaders: bool,
}

let featureFlagType = (featureFlags: JSON.t) => {
  open LogicUtils
  let dict = featureFlags->getDictFromJsonObject->getDictfromDict("features")
  let typedFeatureFlag: featureFlag = {
    default: dict->getBool("default", true),
    testLiveToggle: dict->getBool("test_live_toggle", false),
    email: dict->getBool("email", false),
    quickStart: dict->getBool("quick_start", false),
    isLiveMode: dict->getBool("is_live_mode", false),
    auditTrail: dict->getBool("audit_trail", false),
    systemMetrics: dict->getBool("system_metrics", false),
    sampleData: dict->getBool("sample_data", false),
    frm: dict->getBool("frm", false),
    payOut: dict->getBool("payout", false),
    recon: dict->getBool("recon", false),
    testProcessors: dict->getBool("test_processors", false),
    feedback: dict->getBool("feedback", false),
    generateReport: dict->getBool("generate_report", false),
    mixpanel: dict->getBool("mixpanel", false),
    mixpanelToken: dict->getString("mixpanel_token", ""),
    userJourneyAnalytics: dict->getBool("user_journey_analytics", false),
    authenticationAnalytics: dict->getBool("authentication_analytics", false),
    surcharge: dict->getBool("surcharge", false),
    disputeEvidenceUpload: dict->getBool("dispute_evidence_upload", false),
    paypalAutomaticFlow: dict->getBool("paypal_automatic_flow", false),
    threedsAuthenticator: dict->getBool("threeds_authenticator", false),
    globalSearch: dict->getBool("global_search", false),
    disputeAnalytics: dict->getBool("dispute_analytics", false),
    configurePmts: dict->getBool("configure_pmts", false),
    branding: dict->getBool("branding", false),
    totp: dict->getBool("totp", false),
    liveUsersCounter: dict->getBool("live_users_counter", false),
    granularity: dict->getBool("granularity", false),
    customWebhookHeaders: dict->getBool("custom_webhook_headers", false),
  }
  typedFeatureFlag
}
