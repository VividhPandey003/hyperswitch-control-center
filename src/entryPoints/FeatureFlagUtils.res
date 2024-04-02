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
  userJourneyAnalytics: bool,
  surcharge: bool,
  disputeEvidenceUpload: bool,
  paypalAutomaticFlow: bool,
  threedsAuthenticator: bool,
  globalSearch: bool,
  disputeAnalytics: bool,
}

let featureFlagType = (featureFlags: JSON.t) => {
  open LogicUtils
  let dict = featureFlags->getDictFromJsonObject
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
    userJourneyAnalytics: dict->getBool("user_journey_analytics", false),
    surcharge: dict->getBool("surcharge", false),
    disputeEvidenceUpload: dict->getBool("dispute_evidence_upload", false),
    paypalAutomaticFlow: dict->getBool("paypal_automatic_flow", false),
    threedsAuthenticator: dict->getBool("threeds-authenticator", false),
    globalSearch: dict->getBool("global_search", false),
    disputeAnalytics: dict->getBool("dispute_analytics", false),
  }
  typedFeatureFlag
}
