type entityName =
  | CONNECTOR
  | ROUTING
  | MERCHANT_ACCOUNT
  | REFUNDS
  | REFUND_FILTERS
  | DISPUTES
  | PAYOUTS
  | PAYOUTS_FILTERS
  | ANALYTICS_FILTERS
  | ANALYTICS_PAYMENTS
  | ANALYTICS_DISPUTES
  | ANALYTICS_USER_JOURNEY
  | ANALYTICS_REFUNDS
  | ANALYTICS_AUTHENTICATION
  | ANALYTICS_ACTIVE_PAYMENTS
  | API_KEYS
  | ORDERS
  | ORDER_FILTERS
  | ORDERS_AGGREGATE
  | REFUNDS_AGGREGATE
  | DEFAULT_FALLBACK
  | ANALYTICS_SYSTEM_METRICS
  | SDK_EVENT_LOGS
  | WEBHOOKS_EVENT_LOGS
  | CONNECTOR_EVENT_LOGS
  | GENERATE_SAMPLE_DATA
  | USERS
  | RECON
  | INTEGRATION_DETAILS
  | FRAUD_RISK_MANAGEMENT
  | USER_MANAGEMENT
  | THREE_DS
  | BUSINESS_PROFILE
  | VERIFY_APPLE_PAY
  | PAYMENT_REPORT
  | REFUND_REPORT
  | DISPUTE_REPORT
  | PAYPAL_ONBOARDING
  | PAYPAL_ONBOARDING_SYNC
  | ACTION_URL
  | RESET_TRACKING_ID
  | SURCHARGE
  | CUSTOMERS
  | ACCEPT_DISPUTE
  | DISPUTES_ATTACH_EVIDENCE
  | PAYOUT_DEFAULT_FALLBACK
  | PAYOUT_ROUTING
  | ACTIVE_PAYOUT_ROUTING
  | ACTIVE_ROUTING
  | GLOBAL_SEARCH
  | PAYMENT_METHOD_CONFIG
  | USER_MANAGEMENT_V2
  | API_EVENT_LOGS
  | ANALYTICS_PAYMENTS_V2

type userRoleTypes = USER_LIST | ROLE_LIST | ROLE_ID | NONE

type reconType = [#TOKEN | #REQUEST | #NONE]

type userType = [
  | #CONNECT_ACCOUNT
  | #SIGNUP
  | #SIGNINV2
  | #SIGNOUT
  | #FORGOT_PASSWORD
  | #RESET_PASSWORD
  | #VERIFY_EMAIL_REQUEST
  | #VERIFY_EMAILV2
  | #ACCEPT_INVITE_FROM_EMAIL
  | #SET_METADATA
  | #SWITCH_MERCHANT
  | #PERMISSION_INFO
  | #ROLE_INFO
  | #MERCHANT_DATA
  | #USER_DATA
  | #USER_DELETE
  | #USER_UPDATE
  | #UPDATE_ROLE
  | #INVITE_MULTIPLE
  | #RESEND_INVITE
  | #CREATE_MERCHANT
  | #GET_PERMISSIONS
  | #CREATE_CUSTOM_ROLE
  | #FROM_EMAIL
  | #USER_INFO
  | #ROTATE_PASSWORD
  | #BEGIN_TOTP
  | #VERIFY_TOTP
  | #VERIFY_RECOVERY_CODE
  | #GENERATE_RECOVERY_CODES
  | #TERMINATE_TWO_FACTOR_AUTH
  | #CHECK_TWO_FACTOR_AUTH_STATUS
  | #RESET_TOTP
  | #GET_AUTH_LIST
  | #AUTH_SELECT
  | #SIGN_IN_WITH_SSO
  | #CHANGE_PASSWORD
  | #SWITCH_ORG
  | #SWITCH_MERCHANT_NEW
  | #SWITCH_PROFILE
  | #LIST_ORG
  | #LIST_MERCHANT
  | #LIST_PROFILE
  | #LIST_ROLES_FOR_INVITE
  | #SWITCH_ORG
  | #SWITCH_PROFILE
  | #ROLE_INFO
  | #LIST_INVITATION
  | #ACCEPT_INVITATION_PRE_LOGIN
  | #USER_DETAILS
  | #LIST_ROLES_FOR_ROLE_UPDATE
  | #ACCEPT_INVITATION_HOME
  | #NONE
]

type getUrlTypes = (
  ~entityName: entityName,
  ~methodType: Fetch.requestMethod,
  ~id: option<string>=?,
  ~connector: option<string>=?,
  ~userType: userType=?,
  ~userRoleTypes: userRoleTypes=?,
  ~reconType: reconType=?,
  ~queryParamerters: option<string>=?,
) => string
