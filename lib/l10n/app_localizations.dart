import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Hassalah'**
  String get app_title;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @childFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get childFallbackName;

  /// No description provided for @spendBalance.
  ///
  /// In en, this message translates to:
  /// **'Spend balance'**
  String get spendBalance;

  /// No description provided for @saveBalance.
  ///
  /// In en, this message translates to:
  /// **'Save balance'**
  String get saveBalance;

  /// No description provided for @keys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get keys;

  /// No description provided for @chores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get chores;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @mytransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get mytransactions;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @requestMoney.
  ///
  /// In en, this message translates to:
  /// **'Request Money'**
  String get requestMoney;

  /// No description provided for @spendingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Spending Breakdown'**
  String get spendingBreakdown;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get catGifts;

  /// No description provided for @catOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get catOthers;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your mobile number'**
  String get enterMobileNumber;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'05XXXXXXXX'**
  String get mobileHint;

  /// No description provided for @byClickingContinue.
  ///
  /// In en, this message translates to:
  /// **'By clicking \"Continue\", you agree to our '**
  String get byClickingContinue;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Data Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @pleaseEnterMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter your mobile number'**
  String get pleaseEnterMobile;

  /// No description provided for @validSaudiPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Saudi phone number'**
  String get validSaudiPhone;

  /// No description provided for @numberHelp.
  ///
  /// In en, this message translates to:
  /// **'Number must be 10 digits and start with 05.\nExample: 05XXXXXXXX'**
  String get numberHelp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @securityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Security Question'**
  String get securityQuestion;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterPhoneForReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneForReset;

  /// No description provided for @answerSecurity.
  ///
  /// In en, this message translates to:
  /// **'Answer your security question'**
  String get answerSecurity;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterNewPassword;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get yourAnswer;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @verifyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Verify Answer'**
  String get verifyAnswer;

  /// No description provided for @streetQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s the name of the street where you lived as a child?'**
  String get streetQuestion;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @phoneNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Phone not registered'**
  String get phoneNotRegistered;

  /// No description provided for @incorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Incorrect answer'**
  String get incorrectAnswer;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must include upper, lower, number & special character'**
  String get passwordRequirements;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated!'**
  String get passwordUpdated;

  /// No description provided for @failedToReset.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get failedToReset;

  /// No description provided for @pleaseEnterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please enter your answer'**
  String get pleaseEnterAnswer;

  /// No description provided for @forSmarterChildren.
  ///
  /// In en, this message translates to:
  /// **'For Smarter Children...'**
  String get forSmarterChildren;

  /// No description provided for @foodRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Food & Restaurants'**
  String get foodRestaurants;

  /// No description provided for @groceryMarkets.
  ///
  /// In en, this message translates to:
  /// **'Grocery & Markets'**
  String get groceryMarkets;

  /// No description provided for @retailShopping.
  ///
  /// In en, this message translates to:
  /// **'Retail & Shopping'**
  String get retailShopping;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @medical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get medical;

  /// No description provided for @digitalSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Digital & Subscriptions'**
  String get digitalSubscriptions;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @parentWallet.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Wallet'**
  String get parentWallet;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @myCard.
  ///
  /// In en, this message translates to:
  /// **'My Card'**
  String get myCard;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get insights;

  /// No description provided for @totalWord.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalWord;

  /// No description provided for @myChildren.
  ///
  /// In en, this message translates to:
  /// **'My Children'**
  String get myChildren;

  /// No description provided for @transferMoney.
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get transferMoney;

  /// No description provided for @pleaseAddCardFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add a card first'**
  String get pleaseAddCardFirst;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security settings'**
  String get securitySettings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsAndPrivacy;

  /// No description provided for @policyOverview.
  ///
  /// In en, this message translates to:
  /// **'Policy Overview'**
  String get policyOverview;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @termsDescription.
  ///
  /// In en, this message translates to:
  /// **'and does not support real banking transactions. Only one parent account is supported per family in this version.'**
  String get termsDescription;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @questionsOrConcerns.
  ///
  /// In en, this message translates to:
  /// **'Questions or concerns?'**
  String get questionsOrConcerns;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'support@hassala.sa'**
  String get supportEmail;

  /// No description provided for @generateMerchantQR.
  ///
  /// In en, this message translates to:
  /// **'Generate Merchant QR (Demo)'**
  String get generateMerchantQR;

  /// No description provided for @merchantDetails.
  ///
  /// In en, this message translates to:
  /// **'Merchant details'**
  String get merchantDetails;

  /// No description provided for @merchantName.
  ///
  /// In en, this message translates to:
  /// **'Merchant name'**
  String get merchantName;

  /// No description provided for @amountSAR.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR)'**
  String get amountSAR;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Token:'**
  String get tokenLabel;

  /// No description provided for @enterMerchantName.
  ///
  /// In en, this message translates to:
  /// **'Enter merchant name.'**
  String get enterMerchantName;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @failedToCreateQR.
  ///
  /// In en, this message translates to:
  /// **'Failed to create QR'**
  String get failedToCreateQR;

  /// No description provided for @demoMerchant.
  ///
  /// In en, this message translates to:
  /// **'Demo Merchant'**
  String get demoMerchant;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// No description provided for @createNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a new goal'**
  String get createNewGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// No description provided for @enterGoalName.
  ///
  /// In en, this message translates to:
  /// **'Enter goal name'**
  String get enterGoalName;

  /// No description provided for @lettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Letters only'**
  String get lettersOnly;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @max200Chars.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get max200Chars;

  /// No description provided for @amountToSave.
  ///
  /// In en, this message translates to:
  /// **'Amount to save'**
  String get amountToSave;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @numbersOnly.
  ///
  /// In en, this message translates to:
  /// **'Numbers only'**
  String get numbersOnly;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment completed successfully.'**
  String get paymentCompleted;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String somethingWentWrong(String error);

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @reviewPayment.
  ///
  /// In en, this message translates to:
  /// **'Review Payment'**
  String get reviewPayment;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get total;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee:'**
  String get fee;

  /// No description provided for @afterPayment.
  ///
  /// In en, this message translates to:
  /// **'After Payment:'**
  String get afterPayment;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay'**
  String get confirmAndPay;

  /// No description provided for @sarAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} SAR'**
  String sarAmount(String amount);

  /// No description provided for @scanToPay.
  ///
  /// In en, this message translates to:
  /// **'Scan to pay'**
  String get scanToPay;

  /// No description provided for @scanTheQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get scanTheQRCode;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @hassalahVirtualCard.
  ///
  /// In en, this message translates to:
  /// **'Hassalah Virtual Card'**
  String get hassalahVirtualCard;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @childUser.
  ///
  /// In en, this message translates to:
  /// **'CHILD USER'**
  String get childUser;

  /// No description provided for @payWithQR.
  ///
  /// In en, this message translates to:
  /// **'Pay with QR'**
  String get payWithQR;

  /// No description provided for @greatJobSentForApproval.
  ///
  /// In en, this message translates to:
  /// **'Great job! Sent for approval.'**
  String get greatJobSentForApproval;

  /// No description provided for @taskReturned.
  ///
  /// In en, this message translates to:
  /// **'Task Returned!'**
  String get taskReturned;

  /// No description provided for @taskReturnedNote.
  ///
  /// In en, this message translates to:
  /// **'Your parent reviewed this task and sent it back with this note:'**
  String get taskReturnedNote;

  /// No description provided for @pleaseFixTask.
  ///
  /// In en, this message translates to:
  /// **'Please fix the task and try again.'**
  String get pleaseFixTask;

  /// No description provided for @submitNewProof.
  ///
  /// In en, this message translates to:
  /// **'Please fix it, then submit a new proof photo.'**
  String get submitNewProof;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @resubmitProof.
  ///
  /// In en, this message translates to:
  /// **'Resubmit Proof'**
  String get resubmitProof;

  /// No description provided for @submitProof.
  ///
  /// In en, this message translates to:
  /// **'Submit Proof'**
  String get submitProof;

  /// No description provided for @selectPhotoProof.
  ///
  /// In en, this message translates to:
  /// **'Select a photo from your gallery to prove you finished the task.'**
  String get selectPhotoProof;

  /// No description provided for @tapToOpenGallery.
  ///
  /// In en, this message translates to:
  /// **'Tap to open Gallery'**
  String get tapToOpenGallery;

  /// No description provided for @proofPictureRequired.
  ///
  /// In en, this message translates to:
  /// **'Proof picture is required!'**
  String get proofPictureRequired;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @gameScreen.
  ///
  /// In en, this message translates to:
  /// **'Game Screen'**
  String get gameScreen;

  /// No description provided for @failedToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Failed to redeem'**
  String get failedToRedeem;

  /// No description provided for @yay.
  ///
  /// In en, this message translates to:
  /// **'Yay!'**
  String get yay;

  /// No description provided for @redeemedSuccessMsg1.
  ///
  /// In en, this message translates to:
  /// **'You\'ve redeemed'**
  String get redeemedSuccessMsg1;

  /// No description provided for @redeemedSuccessMsg2.
  ///
  /// In en, this message translates to:
  /// **'Your parent has been notified!'**
  String get redeemedSuccessMsg2;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @myPrizes.
  ///
  /// In en, this message translates to:
  /// **'My Prizes'**
  String get myPrizes;

  /// No description provided for @spendKeys.
  ///
  /// In en, this message translates to:
  /// **'Spend your hard-earned keys!'**
  String get spendKeys;

  /// No description provided for @youGotThis.
  ///
  /// In en, this message translates to:
  /// **'You got this!'**
  String get youGotThis;

  /// No description provided for @redeemPrize.
  ///
  /// In en, this message translates to:
  /// **'Redeem Prize'**
  String get redeemPrize;

  /// No description provided for @notEnoughKeys.
  ///
  /// In en, this message translates to:
  /// **'Not enough keys'**
  String get notEnoughKeys;

  /// No description provided for @noPrizesYet.
  ///
  /// In en, this message translates to:
  /// **'No prizes available yet'**
  String get noPrizesYet;

  /// No description provided for @errNotEnoughSaving.
  ///
  /// In en, this message translates to:
  /// **'Not enough Saving balance.'**
  String get errNotEnoughSaving;

  /// No description provided for @errNotEnoughGoalBalance.
  ///
  /// In en, this message translates to:
  /// **'Not enough money in this goal.'**
  String get errNotEnoughGoalBalance;

  /// No description provided for @errExceedTarget.
  ///
  /// In en, this message translates to:
  /// **'You cannot exceed the goal target amount.'**
  String get errExceedTarget;

  /// No description provided for @errGoalCompletedLocked.
  ///
  /// In en, this message translates to:
  /// **'This goal is completed and locked. You cannot add more money.'**
  String get errGoalCompletedLocked;

  /// No description provided for @errGoalCompletedNoMoveOut.
  ///
  /// In en, this message translates to:
  /// **'Completed goals cannot move money back to Saving.'**
  String get errGoalCompletedNoMoveOut;

  /// No description provided for @errGoalHasMoney.
  ///
  /// In en, this message translates to:
  /// **'You must move all money back to Saving before deleting this goal.'**
  String get errGoalHasMoney;

  /// No description provided for @errNothingToRedeem.
  ///
  /// In en, this message translates to:
  /// **'There is nothing left to move to Spending.'**
  String get errNothingToRedeem;

  /// No description provided for @errNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'You can only redeem completed goals.'**
  String get errNotCompleted;

  /// No description provided for @errGoalNotFound.
  ///
  /// In en, this message translates to:
  /// **'This goal no longer exists.'**
  String get errGoalNotFound;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get editGoal;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmount;

  /// No description provided for @enterTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter target'**
  String get enterTarget;

  /// No description provided for @targetMustBeGreater.
  ///
  /// In en, this message translates to:
  /// **'Target must be ≥ saved amount'**
  String get targetMustBeGreater;

  /// No description provided for @saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveBtn;

  /// No description provided for @goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal updated'**
  String get goalUpdated;

  /// No description provided for @goalCompletedCannotChange.
  ///
  /// In en, this message translates to:
  /// **'This goal is completed and cannot be changed. You can redeem it instead.'**
  String get goalCompletedCannotChange;

  /// No description provided for @moveInSavingToGoal.
  ///
  /// In en, this message translates to:
  /// **'Move In (Saving → Goal)'**
  String get moveInSavingToGoal;

  /// No description provided for @moveOutGoalToSaving.
  ///
  /// In en, this message translates to:
  /// **'Move Out (Goal → Saving)'**
  String get moveOutGoalToSaving;

  /// No description provided for @amountStr.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountStr;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmBtn;

  /// No description provided for @moneyAddedToGoal.
  ///
  /// In en, this message translates to:
  /// **'Money added to goal'**
  String get moneyAddedToGoal;

  /// No description provided for @moneyMovedToSaving.
  ///
  /// In en, this message translates to:
  /// **'Money moved to Saving'**
  String get moneyMovedToSaving;

  /// No description provided for @goalMoneyMovedToSpending.
  ///
  /// In en, this message translates to:
  /// **'Goal money moved to Spending'**
  String get goalMoneyMovedToSpending;

  /// No description provided for @deleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get deleteGoal;

  /// No description provided for @deleteGoalWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this goal?\n\nIf there is any money saved inside it, you must move it back to Saving first.'**
  String get deleteGoalWarning;

  /// No description provided for @deleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteBtn;

  /// No description provided for @goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalDeleted;

  /// No description provided for @savingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Savings goal'**
  String get savingsGoal;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved:'**
  String get savedLabel;

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target:'**
  String get targetLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining:'**
  String get remainingLabel;

  /// No description provided for @moveOutGoalToSavingBtn.
  ///
  /// In en, this message translates to:
  /// **'Move Out\n(Goal → Saving)'**
  String get moveOutGoalToSavingBtn;

  /// No description provided for @moveInSavingToGoalBtn.
  ///
  /// In en, this message translates to:
  /// **'Move In\n(Saving → Goal)'**
  String get moveInSavingToGoalBtn;

  /// No description provided for @goalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed'**
  String get goalCompleted;

  /// No description provided for @canMoveCollectedAmount.
  ///
  /// In en, this message translates to:
  /// **'You can move the collected amount to your Spending balance.'**
  String get canMoveCollectedAmount;

  /// No description provided for @goalAlreadyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'This goal has already been redeemed to Spending.'**
  String get goalAlreadyRedeemed;

  /// No description provided for @moveToSpending.
  ///
  /// In en, this message translates to:
  /// **'Move to Spending'**
  String get moveToSpending;

  /// No description provided for @goalDetails.
  ///
  /// In en, this message translates to:
  /// **'Goal details'**
  String get goalDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @failedToLoadGoals.
  ///
  /// In en, this message translates to:
  /// **'Failed to load goals: {error}'**
  String failedToLoadGoals(String error);

  /// No description provided for @somethingWentWrongGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrongGeneric;

  /// No description provided for @notEnoughBalanceToMove.
  ///
  /// In en, this message translates to:
  /// **'You don’t have enough balance to move this amount.'**
  String get notEnoughBalanceToMove;

  /// No description provided for @moveInSpendingToSaving.
  ///
  /// In en, this message translates to:
  /// **'Move In (Spending → Saving)'**
  String get moveInSpendingToSaving;

  /// No description provided for @moveOutSavingToSpending.
  ///
  /// In en, this message translates to:
  /// **'Move Out (Saving → Spending)'**
  String get moveOutSavingToSpending;

  /// No description provided for @moveFailed.
  ///
  /// In en, this message translates to:
  /// **'Move failed. Please try again.'**
  String get moveFailed;

  /// No description provided for @movedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Moved successfully'**
  String get movedSuccessfully;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkError;

  /// No description provided for @addNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Add new goal'**
  String get addNewGoal;

  /// No description provided for @savingTab.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get savingTab;

  /// No description provided for @spendingTab.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get spendingTab;

  /// No description provided for @moveInSpSv.
  ///
  /// In en, this message translates to:
  /// **'Move In (Sp→Sv)'**
  String get moveInSpSv;

  /// No description provided for @moveOutSvSp.
  ///
  /// In en, this message translates to:
  /// **'Move Out (Sv→Sp)'**
  String get moveOutSvSp;

  /// No description provided for @activeGoals.
  ///
  /// In en, this message translates to:
  /// **'Active Goals'**
  String get activeGoals;

  /// No description provided for @noActiveGoals.
  ///
  /// In en, this message translates to:
  /// **'No active goals'**
  String get noActiveGoals;

  /// No description provided for @completedGoals.
  ///
  /// In en, this message translates to:
  /// **'Completed Goals'**
  String get completedGoals;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBackTitle;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPasswordVal.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPasswordVal;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @confirmLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogOut;

  /// No description provided for @spendingInsights.
  ///
  /// In en, this message translates to:
  /// **'Spending Insights'**
  String get spendingInsights;

  /// No description provided for @comparisonByChild.
  ///
  /// In en, this message translates to:
  /// **'Comparison by Child'**
  String get comparisonByChild;

  /// No description provided for @categoryBreakdownFor.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Category Breakdown'**
  String categoryBreakdownFor(String name);

  /// No description provided for @seeWhichChildSpendingMost.
  ///
  /// In en, this message translates to:
  /// **'See which child is spending the most.'**
  String get seeWhichChildSpendingMost;

  /// No description provided for @trackWhereMoneyGoes.
  ///
  /// In en, this message translates to:
  /// **'Track where {name}\'s money goes.'**
  String trackWhereMoneyGoes(String name);

  /// No description provided for @percentOfTotal.
  ///
  /// In en, this message translates to:
  /// **'% of total'**
  String get percentOfTotal;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @noSpendingData.
  ///
  /// In en, this message translates to:
  /// **'No spending data available for this date.'**
  String get noSpendingData;

  /// No description provided for @allChildren.
  ///
  /// In en, this message translates to:
  /// **'All Children'**
  String get allChildren;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// No description provided for @confirmPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPaymentTitle;

  /// No description provided for @aboutToPay.
  ///
  /// In en, this message translates to:
  /// **'You are about to pay'**
  String get aboutToPay;

  /// No description provided for @merchantLabel.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchantLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @expiresAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires at: {time}'**
  String expiresAtLabel(String time);

  /// No description provided for @qrExpiredError.
  ///
  /// In en, this message translates to:
  /// **'QR code has expired'**
  String get qrExpiredError;

  /// No description provided for @paymentFailedError.
  ///
  /// In en, this message translates to:
  /// **'Payment failed (Status: {code})'**
  String paymentFailedError(int code);

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid Successfully!'**
  String get paidStatus;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @payNowButton.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNowButton;

  /// No description provided for @processingStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingStatus;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @failedToLoadParentInfo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load parent info'**
  String get failedToLoadParentInfo;

  /// No description provided for @errorLoadingParentData.
  ///
  /// In en, this message translates to:
  /// **'Error loading parent data'**
  String get errorLoadingParentData;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment was completed.'**
  String get paymentCompletedSubtitle;

  /// No description provided for @paymentCouldNotBeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your payment could not be completed.'**
  String get paymentCouldNotBeCompleted;

  /// No description provided for @paidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid at'**
  String get paidAt;

  /// No description provided for @transactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionIdLabel;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @viewTransactions.
  ///
  /// In en, this message translates to:
  /// **'View Transactions'**
  String get viewTransactions;

  /// No description provided for @uploadQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a QR code image to complete your payment'**
  String get uploadQrSubtitle;

  /// No description provided for @noQrSelected.
  ///
  /// In en, this message translates to:
  /// **'No QR selected'**
  String get noQrSelected;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @chooseQrImage.
  ///
  /// In en, this message translates to:
  /// **'Choose QR Image'**
  String get chooseQrImage;

  /// No description provided for @errorNoQrFound.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in this image.'**
  String get errorNoQrFound;

  /// No description provided for @errorQrUnreadable.
  ///
  /// In en, this message translates to:
  /// **'QR detected but unreadable.'**
  String get errorQrUnreadable;

  /// No description provided for @useThisQr.
  ///
  /// In en, this message translates to:
  /// **'Use this QR'**
  String get useThisQr;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @generateDemoQr.
  ///
  /// In en, this message translates to:
  /// **'Generate Demo QR'**
  String get generateDemoQr;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @errorInvalidQrFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR format'**
  String get errorInvalidQrFormat;

  /// No description provided for @errorFailedResolveQr.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve QR.'**
  String get errorFailedResolveQr;

  /// No description provided for @errorFailedCreateDemoQr.
  ///
  /// In en, this message translates to:
  /// **'Failed to create demo QR.'**
  String get errorFailedCreateDemoQr;

  /// No description provided for @moneyRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Money Requests'**
  String get moneyRequestsTitle;

  /// No description provided for @newRequestTab.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequestTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50.00'**
  String get amountHint;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Add a message'**
  String get messageHint;

  /// No description provided for @requestButton.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestButton;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message for your request'**
  String get enterMessage;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get requestFailed;

  /// No description provided for @requestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get requestSentTitle;

  /// No description provided for @requestForBody.
  ///
  /// In en, this message translates to:
  /// **'Your request for'**
  String get requestForBody;

  /// No description provided for @wasSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'was sent successfully.'**
  String get wasSentSuccessfully;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @manageRewards.
  ///
  /// In en, this message translates to:
  /// **'Manage Rewards'**
  String get manageRewards;

  /// No description provided for @createFunRewards.
  ///
  /// In en, this message translates to:
  /// **'Create fun rewards for your children to earn!'**
  String get createFunRewards;

  /// No description provided for @rewardAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward added successfully!'**
  String get rewardAddedSuccess;

  /// No description provided for @rewardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reward updated!'**
  String get rewardUpdated;

  /// No description provided for @rewardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reward deleted!'**
  String get rewardDeleted;

  /// No description provided for @deleteRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reward'**
  String get deleteRewardTitle;

  /// No description provided for @deleteRewardWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reward?'**
  String get deleteRewardWarning;

  /// No description provided for @editReward.
  ///
  /// In en, this message translates to:
  /// **'Edit Reward'**
  String get editReward;

  /// No description provided for @newReward.
  ///
  /// In en, this message translates to:
  /// **'New Reward'**
  String get newReward;

  /// No description provided for @rewardTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward Title'**
  String get rewardTitleLabel;

  /// No description provided for @rewardTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Zoo Trip'**
  String get rewardTitleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short description...'**
  String get descriptionHint;

  /// No description provided for @costKeysLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost (Keys)'**
  String get costKeysLabel;

  /// No description provided for @costKeysHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get costKeysHint;

  /// No description provided for @keysMustBeGreater.
  ///
  /// In en, this message translates to:
  /// **'Keys must be greater than 0'**
  String get keysMustBeGreater;

  /// No description provided for @noRewardsYet.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet'**
  String get noRewardsYet;

  /// No description provided for @redeemedBy.
  ///
  /// In en, this message translates to:
  /// **'Redeemed by {name}'**
  String redeemedBy(String name);

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @prizes.
  ///
  /// In en, this message translates to:
  /// **'Prizes'**
  String get prizes;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @missingToken.
  ///
  /// In en, this message translates to:
  /// **'Authentication token is missing. Please log in again.'**
  String get missingToken;

  /// No description provided for @failedToLoadChildren.
  ///
  /// In en, this message translates to:
  /// **'Failed to load children (Status: {code})'**
  String failedToLoadChildren(int code);

  /// No description provided for @errorFetchingChildren.
  ///
  /// In en, this message translates to:
  /// **'Error fetching children: {error}'**
  String errorFetchingChildren(String error);

  /// No description provided for @updateSpendingLimit.
  ///
  /// In en, this message translates to:
  /// **'Update Spending Limit'**
  String get updateSpendingLimit;

  /// No description provided for @setNewLimitFor.
  ///
  /// In en, this message translates to:
  /// **'Set new limit for {name}'**
  String setNewLimitFor(String name);

  /// No description provided for @newSpendingLimitSar.
  ///
  /// In en, this message translates to:
  /// **'New Spending Limit (SAR)'**
  String get newSpendingLimitSar;

  /// No description provided for @defaultSavingSplit.
  ///
  /// In en, this message translates to:
  /// **'Default Saving Split'**
  String get defaultSavingSplit;

  /// No description provided for @savingSpendingSplit.
  ///
  /// In en, this message translates to:
  /// **'Saving: {saving}% / Spending: {spending}%'**
  String savingSpendingSplit(int saving, int spending);

  /// No description provided for @childSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Child settings updated'**
  String get childSettingsUpdated;

  /// No description provided for @failedToUpdateChildSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to update child settings'**
  String get failedToUpdateChildSettings;

  /// No description provided for @addNewChild.
  ///
  /// In en, this message translates to:
  /// **'Add New Child'**
  String get addNewChild;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter first name'**
  String get enterFirstName;

  /// No description provided for @nationalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalIdLabel;

  /// No description provided for @enterNationalId.
  ///
  /// In en, this message translates to:
  /// **'Please enter national ID'**
  String get enterNationalId;

  /// No description provided for @mustBe10Digits.
  ///
  /// In en, this message translates to:
  /// **'Must be 10 digits'**
  String get mustBe10Digits;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @phoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Phone must start with 05 and be 10 digits'**
  String get phoneHelp;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @spendingLimitSar.
  ///
  /// In en, this message translates to:
  /// **'Spending Limit (SAR)'**
  String get spendingLimitSar;

  /// No description provided for @enterLimit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a limit'**
  String get enterLimit;

  /// No description provided for @phoneAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already linked to another account'**
  String get phoneAlreadyLinked;

  /// No description provided for @childAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Child added successfully'**
  String get childAddedSuccess;

  /// No description provided for @failedToAddChild.
  ///
  /// In en, this message translates to:
  /// **'Failed to add child'**
  String get failedToAddChild;

  /// No description provided for @manageChildren.
  ///
  /// In en, this message translates to:
  /// **'Manage Children'**
  String get manageChildren;

  /// No description provided for @noChildrenAdded.
  ///
  /// In en, this message translates to:
  /// **'No children added yet'**
  String get noChildrenAdded;

  /// No description provided for @phoneDisplay.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String phoneDisplay(String phone);

  /// No description provided for @limitDisplay.
  ///
  /// In en, this message translates to:
  /// **'Limit: {limit} SAR'**
  String limitDisplay(String limit);

  /// No description provided for @addNewCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCardTitle;

  /// No description provided for @cardHolder.
  ///
  /// In en, this message translates to:
  /// **'CARD HOLDER'**
  String get cardHolder;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'EXPIRY DATE'**
  String get expiryDate;

  /// No description provided for @expiryHint.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get expiryHint;

  /// No description provided for @cardHolderName.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get cardHolderName;

  /// No description provided for @saveCardForFuture.
  ///
  /// In en, this message translates to:
  /// **'Save card details for future payments'**
  String get saveCardForFuture;

  /// No description provided for @errCardNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Card number is required'**
  String get errCardNumberRequired;

  /// No description provided for @errCardNumberDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Card number must contain digits only'**
  String get errCardNumberDigitsOnly;

  /// No description provided for @errCardNumberLength.
  ///
  /// In en, this message translates to:
  /// **'Card number must be 16 digits'**
  String get errCardNumberLength;

  /// No description provided for @errExpiryRequired.
  ///
  /// In en, this message translates to:
  /// **'Expiry date is required'**
  String get errExpiryRequired;

  /// No description provided for @errExpiryInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid expiry date (MM/YY)'**
  String get errExpiryInvalidFormat;

  /// No description provided for @errExpiryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid expiry date'**
  String get errExpiryInvalid;

  /// No description provided for @errExpiryMonth.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid month'**
  String get errExpiryMonth;

  /// No description provided for @errExpiryYear.
  ///
  /// In en, this message translates to:
  /// **'Expiry year must be 26 or later'**
  String get errExpiryYear;

  /// No description provided for @errCvvRequired.
  ///
  /// In en, this message translates to:
  /// **'CVV is required'**
  String get errCvvRequired;

  /// No description provided for @errCvvDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'CVV must contain digits only'**
  String get errCvvDigitsOnly;

  /// No description provided for @errCvvLength.
  ///
  /// In en, this message translates to:
  /// **'CVV must be 3 digits'**
  String get errCvvLength;

  /// No description provided for @errCardNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name on card is required'**
  String get errCardNameRequired;

  /// No description provided for @errCardNameLettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Name must contain English letters only'**
  String get errCardNameLettersOnly;

  /// No description provided for @errCardNameSpace.
  ///
  /// In en, this message translates to:
  /// **'Use only one space between first and last name'**
  String get errCardNameSpace;

  /// No description provided for @errCardNameOneSpace.
  ///
  /// In en, this message translates to:
  /// **'Enter first and last name with one space only'**
  String get errCardNameOneSpace;

  /// No description provided for @errCardNameFirstLast.
  ///
  /// In en, this message translates to:
  /// **'Enter first and last name only'**
  String get errCardNameFirstLast;

  /// No description provided for @errCardNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Each name must be at least 3 letters'**
  String get errCardNameMinLength;

  /// No description provided for @errFailedToSaveCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to save card'**
  String get errFailedToSaveCard;

  /// No description provided for @errErrorSavingCard.
  ///
  /// In en, this message translates to:
  /// **'Error while saving card'**
  String get errErrorSavingCard;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authenticationError;

  /// No description provided for @unableToOpenPaymentPage.
  ///
  /// In en, this message translates to:
  /// **'Unable to open payment page'**
  String get unableToOpenPaymentPage;

  /// No description provided for @redirectUrlMissing.
  ///
  /// In en, this message translates to:
  /// **'Redirect URL missing'**
  String get redirectUrlMissing;

  /// No description provided for @addMoneyFailed.
  ///
  /// In en, this message translates to:
  /// **'Add money failed'**
  String get addMoneyFailed;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @allowanceSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Allowance Setup'**
  String get allowanceSetupTitle;

  /// No description provided for @allowanceSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Teach them to save by splitting their weekly allowance.'**
  String get allowanceSetupSubtitle;

  /// No description provided for @weeklyAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get weeklyAmountLabel;

  /// No description provided for @allocationSplitLabel.
  ///
  /// In en, this message translates to:
  /// **'Allocation Split'**
  String get allocationSplitLabel;

  /// No description provided for @percentSave.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Save'**
  String percentSave(int percent);

  /// No description provided for @allowanceSliderInstruction.
  ///
  /// In en, this message translates to:
  /// **'Adjust the slider to teach your child how much to save from their allowance automatically.'**
  String get allowanceSliderInstruction;

  /// No description provided for @autoTransferWeekly.
  ///
  /// In en, this message translates to:
  /// **'Auto-transfer Weekly'**
  String get autoTransferWeekly;

  /// No description provided for @everySunday.
  ///
  /// In en, this message translates to:
  /// **'Every Sunday'**
  String get everySunday;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @noChildrenFound.
  ///
  /// In en, this message translates to:
  /// **'No children found'**
  String get noChildrenFound;

  /// No description provided for @allowanceSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Allowance Saved ✅'**
  String get allowanceSavedSuccess;

  /// No description provided for @pleaseEnterWeeklyAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter weekly amount'**
  String get pleaseEnterWeeklyAmount;

  /// No description provided for @amountMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Amount must be a number'**
  String get amountMustBeNumber;

  /// No description provided for @amountMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountMustBeGreaterThanZero;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed ({code})'**
  String saveFailed(int code);

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(String error);

  /// No description provided for @currencySarLabel.
  ///
  /// In en, this message translates to:
  /// **' SAR'**
  String get currencySarLabel;

  /// No description provided for @spend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get spend;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @choreApproved.
  ///
  /// In en, this message translates to:
  /// **'Chore approved!'**
  String get choreApproved;

  /// No description provided for @failedToApprove.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve chore'**
  String get failedToApprove;

  /// No description provided for @deleteChoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Chore'**
  String get deleteChoreTitle;

  /// No description provided for @deleteChoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chore?'**
  String get deleteChoreWarning;

  /// No description provided for @choreDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chore deleted successfully'**
  String get choreDeletedSuccess;

  /// No description provided for @failedToDeleteChore.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete chore'**
  String get failedToDeleteChore;

  /// No description provided for @reviewProof.
  ///
  /// In en, this message translates to:
  /// **'Review Proof'**
  String get reviewProof;

  /// No description provided for @childCompletedTask.
  ///
  /// In en, this message translates to:
  /// **'{name} completed the task: {title}'**
  String childCompletedTask(String name, String title);

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @noProofImage.
  ///
  /// In en, this message translates to:
  /// **'No proof image submitted'**
  String get noProofImage;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @addNewChore.
  ///
  /// In en, this message translates to:
  /// **'Add New Chore'**
  String get addNewChore;

  /// No description provided for @choreTitle.
  ///
  /// In en, this message translates to:
  /// **'Chore Title'**
  String get choreTitle;

  /// No description provided for @rewardKeysLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward Keys'**
  String get rewardKeysLabel;

  /// No description provided for @choreType.
  ///
  /// In en, this message translates to:
  /// **'Chore Type'**
  String get choreType;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalidInput;

  /// No description provided for @choreAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chore added successfully'**
  String get choreAddedSuccess;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @childsChores.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Chores'**
  String childsChores(String name);

  /// No description provided for @activeTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTab;

  /// No description provided for @noActiveChores.
  ///
  /// In en, this message translates to:
  /// **'No active chores'**
  String get noActiveChores;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @waitingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting Review'**
  String get waitingReview;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @transferMoney_action.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferMoney_action;

  /// No description provided for @chores_action.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get chores_action;

  /// No description provided for @transactions_action.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions_action;

  /// No description provided for @moneyRequests.
  ///
  /// In en, this message translates to:
  /// **'Money Requests'**
  String get moneyRequests;

  /// No description provided for @goals_action.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals_action;

  /// No description provided for @childsGoals.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Goals'**
  String childsGoals(String name);

  /// No description provided for @savedMetric.
  ///
  /// In en, this message translates to:
  /// **'Saved: '**
  String get savedMetric;

  /// No description provided for @remainingMetric.
  ///
  /// In en, this message translates to:
  /// **'Remaining: '**
  String get remainingMetric;

  /// No description provided for @completedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBadge;

  /// No description provided for @allFamilyChores.
  ///
  /// In en, this message translates to:
  /// **'All Family Chores'**
  String get allFamilyChores;

  /// No description provided for @toReviewTab.
  ///
  /// In en, this message translates to:
  /// **'To Review'**
  String get toReviewTab;

  /// No description provided for @inProgressTab.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressTab;

  /// No description provided for @nochoresToReview.
  ///
  /// In en, this message translates to:
  /// **'No chores to review'**
  String get nochoresToReview;

  /// No description provided for @noActiveChoresList.
  ///
  /// In en, this message translates to:
  /// **'No active chores'**
  String get noActiveChoresList;

  /// No description provided for @childsChoresHeader.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Chores'**
  String childsChoresHeader(String name);

  /// No description provided for @rewardKeys.
  ///
  /// In en, this message translates to:
  /// **'Reward: {keys} Keys'**
  String rewardKeys(int keys);

  /// No description provided for @weeklyBadge.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyBadge;

  /// No description provided for @reviewProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Review {name}\'s Proof'**
  String reviewProofTitle(String name);

  /// No description provided for @taskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task: {title}'**
  String taskLabel(String title);

  /// No description provided for @noProofProvided.
  ///
  /// In en, this message translates to:
  /// **'No proof image provided.'**
  String get noProofProvided;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @reasonForRejection.
  ///
  /// In en, this message translates to:
  /// **'Reason for Rejection'**
  String get reasonForRejection;

  /// No description provided for @rejectionHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., The room is still messy!'**
  String get rejectionHint;

  /// No description provided for @sendToChild.
  ///
  /// In en, this message translates to:
  /// **'Send to Child'**
  String get sendToChild;

  /// No description provided for @choreRejected.
  ///
  /// In en, this message translates to:
  /// **'Chore Rejected & returned to child'**
  String get choreRejected;

  /// No description provided for @failedToReject.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject'**
  String get failedToReject;

  /// No description provided for @editChore.
  ///
  /// In en, this message translates to:
  /// **'Edit Chore'**
  String get editChore;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @descriptionChore.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionChore;

  /// No description provided for @rewardKeysInput.
  ///
  /// In en, this message translates to:
  /// **'Reward (Keys)'**
  String get rewardKeysInput;

  /// No description provided for @choreTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Chore Type'**
  String get choreTypeLabel;

  /// No description provided for @oneTimeOption.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTimeOption;

  /// No description provided for @weeklyOption.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyOption;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @selectTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTimeHint;

  /// No description provided for @assignToChild.
  ///
  /// In en, this message translates to:
  /// **'Assign to Child'**
  String get assignToChild;

  /// No description provided for @selectChild.
  ///
  /// In en, this message translates to:
  /// **'Select a child'**
  String get selectChild;

  /// No description provided for @noChildrenFoundRed.
  ///
  /// In en, this message translates to:
  /// **'No children found.'**
  String get noChildrenFoundRed;

  /// No description provided for @rewardMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Reward must be > 0'**
  String get rewardMustBePositive;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @choreUpdated.
  ///
  /// In en, this message translates to:
  /// **'Chore updated!'**
  String get choreUpdated;

  /// No description provided for @choreCreated.
  ///
  /// In en, this message translates to:
  /// **'Chore created!'**
  String get choreCreated;

  /// No description provided for @errorMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMsg(String error);

  /// No description provided for @deleteChoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Chore?'**
  String get deleteChoreConfirmTitle;

  /// No description provided for @deleteChoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chore? This action cannot be undone.'**
  String get deleteChoreConfirmBody;

  /// No description provided for @choreApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chore Approved!'**
  String get choreApprovedSuccess;

  /// No description provided for @declineRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Request?'**
  String get declineRequestTitle;

  /// No description provided for @declineRequestContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this request?'**
  String get declineRequestContent;

  /// No description provided for @declineBtn.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineBtn;

  /// No description provided for @moneyRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Money request'**
  String get moneyRequestTitle;

  /// No description provided for @noRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No requests found'**
  String get noRequestsFound;

  /// No description provided for @noMessage.
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get noMessage;

  /// No description provided for @approveBtn.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveBtn;

  /// No description provided for @declinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedBadge;

  /// No description provided for @paidBadge.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidBadge;

  /// No description provided for @errMissingTokenParentId.
  ///
  /// In en, this message translates to:
  /// **'Login response missing token or parentId'**
  String get errMissingTokenParentId;

  /// No description provided for @errLoginFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Login failed, please try again'**
  String get errLoginFailedGeneric;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @loginRequiredError.
  ///
  /// In en, this message translates to:
  /// **'You need to log in again.'**
  String get loginRequiredError;

  /// No description provided for @accountDeletedError.
  ///
  /// In en, this message translates to:
  /// **'This account was deleted or does not exist.'**
  String get accountDeletedError;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading data.'**
  String get errorLoadingData;

  /// No description provided for @serverConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the server.'**
  String get serverConnectionFailed;

  /// No description provided for @manageKids.
  ///
  /// In en, this message translates to:
  /// **'Manage Kids'**
  String get manageKids;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @onlyOneCardSaved.
  ///
  /// In en, this message translates to:
  /// **'Only one card can be saved for this parent account.'**
  String get onlyOneCardSaved;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit Card'**
  String get editCard;

  /// No description provided for @removeCard.
  ///
  /// In en, this message translates to:
  /// **'Remove Card'**
  String get removeCard;

  /// No description provided for @removeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove card?'**
  String get removeCardTitle;

  /// No description provided for @removeCardMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this card? You can add a new one later.'**
  String get removeCardMessage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @failedToLoadCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load card'**
  String get failedToLoadCard;

  /// No description provided for @errorLoadingCard.
  ///
  /// In en, this message translates to:
  /// **'Error while loading card'**
  String get errorLoadingCard;

  /// No description provided for @cardRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card removed successfully'**
  String get cardRemovedSuccess;

  /// No description provided for @failedToRemoveCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove card (code: {code})'**
  String failedToRemoveCard(int code);

  /// No description provided for @languageChangedHint.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChangedHint;

  /// No description provided for @noCardFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No card found'**
  String get noCardFoundTitle;

  /// No description provided for @addCardBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Card Now'**
  String get addCardBtn;

  /// No description provided for @authErrorMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Authentication error: Missing token.'**
  String get authErrorMissingToken;

  /// No description provided for @failedToLoadChildrenCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to load children (Code: {code})'**
  String failedToLoadChildrenCode(String code);

  /// No description provided for @errorFetchingChildrenEx.
  ///
  /// In en, this message translates to:
  /// **'Error fetching children: {error}'**
  String errorFetchingChildrenEx(String error);

  /// No description provided for @selectChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Child'**
  String get selectChildTitle;

  /// No description provided for @yourChildren.
  ///
  /// In en, this message translates to:
  /// **'Your Children'**
  String get yourChildren;

  /// No description provided for @noChildrenFoundList.
  ///
  /// In en, this message translates to:
  /// **'No children found'**
  String get noChildrenFoundList;

  /// No description provided for @unnamedChild.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamedChild;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save: '**
  String get saveLabel;

  /// No description provided for @spendLabel.
  ///
  /// In en, this message translates to:
  /// **'Spend: '**
  String get spendLabel;

  /// No description provided for @missingTokenLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Missing token — please log in again'**
  String get missingTokenLoginAgain;

  /// No description provided for @failedToLoadChildrenBasic.
  ///
  /// In en, this message translates to:
  /// **'Failed to load children'**
  String get failedToLoadChildrenBasic;

  /// No description provided for @errorPrefixMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefixMsg(String error);

  /// No description provided for @somethingWentWrongBasic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrongBasic;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @enterCurrentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPasswordHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @createStrongPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get createStrongPasswordHint;

  /// No description provided for @requirementsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirementsTooltip;

  /// No description provided for @doesNotMeetRequirements.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t meet requirements'**
  String get doesNotMeetRequirements;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @reEnterNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reEnterNewPasswordHint;

  /// No description provided for @passwordsDoNotMatchVal.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchVal;

  /// No description provided for @passwordRequirementsDesc.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ chars with uppercase, lowercase, number, and special character.'**
  String get passwordRequirementsDesc;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @changeBtn.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeBtn;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @failedToChangePasswordFallback.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePasswordFallback;

  /// No description provided for @networkErrorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkErrorTryAgain;

  /// No description provided for @changeChildPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change child password'**
  String get changeChildPasswordTitle;

  /// No description provided for @selectChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Select child'**
  String get selectChildLabel;

  /// No description provided for @chooseHint.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseHint;

  /// No description provided for @childFallback.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get childFallback;

  /// No description provided for @childPasswordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Child password changed successfully'**
  String get childPasswordChangedSuccess;

  /// No description provided for @securitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettingsTitle;

  /// No description provided for @securitySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySection;

  /// No description provided for @updateParentPasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Update your parent account password'**
  String get updateParentPasswordSub;

  /// No description provided for @addChildFirstToManage.
  ///
  /// In en, this message translates to:
  /// **'Add a child first to manage passwords'**
  String get addChildFirstToManage;

  /// No description provided for @resetChildPasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Reset a child account password'**
  String get resetChildPasswordSub;

  /// No description provided for @passwordRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements'**
  String get passwordRequirementsTitle;

  /// No description provided for @passwordRequirementsList.
  ///
  /// In en, this message translates to:
  /// **'• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number\n• One special character (!@#\$%^&*)'**
  String get passwordRequirementsList;

  /// No description provided for @transferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferTitle;

  /// No description provided for @fromParent.
  ///
  /// In en, this message translates to:
  /// **'From Parent'**
  String get fromParent;

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String balanceAmount(String amount);

  /// No description provided for @toChild.
  ///
  /// In en, this message translates to:
  /// **'To {name}'**
  String toChild(String name);

  /// No description provided for @splitSavingSpending.
  ///
  /// In en, this message translates to:
  /// **'Split Between Saving and Spending'**
  String get splitSavingSpending;

  /// No description provided for @savePercentage.
  ///
  /// In en, this message translates to:
  /// **'Save: {percent}%'**
  String savePercentage(String percent);

  /// No description provided for @spendPercentage.
  ///
  /// In en, this message translates to:
  /// **'Spend: {percent}%'**
  String spendPercentage(String percent);

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @transferFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed'**
  String get transferFailed;

  /// No description provided for @transferSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transfer Successful!'**
  String get transferSuccessful;

  /// No description provided for @savingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get savingLabel;

  /// No description provided for @spendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get spendingLabel;

  /// No description provided for @updateChildWalletPrompt.
  ///
  /// In en, this message translates to:
  /// **'This will update your child’s wallet balance.'**
  String get updateChildWalletPrompt;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @failedToLoadTransactionsCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions ({code})'**
  String failedToLoadTransactionsCode(String code);

  /// No description provided for @somethingWentWrongError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String somethingWentWrongError(String error);

  /// No description provided for @defaultTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get defaultTransaction;

  /// No description provided for @defaultCategory.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get defaultCategory;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @nameMinLengthVal.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 2 letters'**
  String get nameMinLengthVal;

  /// No description provided for @nameLettersOnlyVal.
  ///
  /// In en, this message translates to:
  /// **'Letters only'**
  String get nameLettersOnlyVal;

  /// No description provided for @nationalIdValidationVal.
  ///
  /// In en, this message translates to:
  /// **'National ID / Iqama must be 10 digits'**
  String get nationalIdValidationVal;

  /// No description provided for @confirmPasswordVal.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordVal;

  /// No description provided for @registeredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Registered successfully! Please log in.'**
  String get registeredSuccessfully;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @nationalIdIqamaLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID / Iqama'**
  String get nationalIdIqamaLabel;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dobLabel;

  /// No description provided for @passwordMinLengthVal.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinLengthVal;

  /// No description provided for @passwordRegexVal.
  ///
  /// In en, this message translates to:
  /// **'Must include upper/lower/number/special'**
  String get passwordRegexVal;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @securityQuestionAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Security Question Answer'**
  String get securityQuestionAnswerLabel;

  /// No description provided for @securityQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'What’s the name of the street where you lived as a child?'**
  String get securityQuestionHint;

  /// No description provided for @selectDateVal.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDateVal;

  /// No description provided for @policyPoint1.
  ///
  /// In en, this message translates to:
  /// **'Using Hassala means you agree to our terms and privacy practices'**
  String get policyPoint1;

  /// No description provided for @policyPoint2.
  ///
  /// In en, this message translates to:
  /// **'You control your data, permissions, and linked devices'**
  String get policyPoint2;

  /// No description provided for @policyPoint3.
  ///
  /// In en, this message translates to:
  /// **'All sensitive data is encrypted and never shared without explicit consent'**
  String get policyPoint3;

  /// No description provided for @termsOfUseFullText.
  ///
  /// In en, this message translates to:
  /// **'You agree to use Hassala responsibly and for family financial education purposes. All accounts created under a parent are subject to parental supervision. Transactions are simulated or processed via licensed PSPs. The app follows SAMA and Saudi data protection standards. Misuse of the platform may result in account suspension. Hassala currently uses sandbox-based payment simulations (e.g., Moyasar) and does not support real banking transactions. Only one parent account is supported per family in this version.'**
  String get termsOfUseFullText;

  /// No description provided for @privacyPolicyFullText.
  ///
  /// In en, this message translates to:
  /// **'Hessala does not share your personal or financial data with third parties without consent. All sensitive data (PINs, passwords, tokens) are encrypted at rest and in transit. You can request data deletion or unlink your bank anytime. Only aggregated, anonymized data may be used for analytics.'**
  String get privacyPolicyFullText;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @allowance.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get allowance;

  /// No description provided for @pleaseSelectChildFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a child first'**
  String get pleaseSelectChildFirst;

  /// No description provided for @whenToTransfer.
  ///
  /// In en, this message translates to:
  /// **'When to transfer?'**
  String get whenToTransfer;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get dayOfMonth;

  /// No description provided for @requestedAmount.
  ///
  /// In en, this message translates to:
  /// **'requested'**
  String get requestedAmount;

  /// No description provided for @requestedMoney.
  ///
  /// In en, this message translates to:
  /// **'requested money'**
  String get requestedMoney;

  /// No description provided for @redeemedPrize.
  ///
  /// In en, this message translates to:
  /// **'redeemed a prize'**
  String get redeemedPrize;

  /// No description provided for @completedTask.
  ///
  /// In en, this message translates to:
  /// **'completed a task'**
  String get completedTask;

  /// No description provided for @walletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Wallet Top-up'**
  String get walletTopUp;

  /// No description provided for @moneyTransfer.
  ///
  /// In en, this message translates to:
  /// **'Money Transfer'**
  String get moneyTransfer;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @parentAllowanceCat.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get parentAllowanceCat;

  /// No description provided for @parentAllowanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Parent Allowance'**
  String get parentAllowanceDesc;

  /// No description provided for @moyasar.
  ///
  /// In en, this message translates to:
  /// **'Moyasar Payment'**
  String get moyasar;

  /// No description provided for @transferToChildMessage.
  ///
  /// In en, this message translates to:
  /// **'Transferred {amount} SAR to {childName}'**
  String transferToChildMessage(String amount, String childName);

  /// No description provided for @allowanceFromParent.
  ///
  /// In en, this message translates to:
  /// **'Allowance from Parent'**
  String get allowanceFromParent;

  /// No description provided for @insight_title_weekly_spending.
  ///
  /// In en, this message translates to:
  /// **'Weekly Spending'**
  String get insight_title_weekly_spending;

  /// No description provided for @insight_msg_weekly_spending.
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} SAR in the last 7 days.'**
  String insight_msg_weekly_spending(String amount);

  /// No description provided for @insight_title_no_spending.
  ///
  /// In en, this message translates to:
  /// **'No Spending'**
  String get insight_title_no_spending;

  /// No description provided for @insight_msg_no_spending_week.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t spent anything in the last 7 days.'**
  String get insight_msg_no_spending_week;

  /// No description provided for @insight_title_top_category.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get insight_title_top_category;

  /// No description provided for @insight_msg_top_category.
  ///
  /// In en, this message translates to:
  /// **'You spent {percentage}% of your money on {category} recently.'**
  String insight_msg_top_category(String percentage, String category);

  /// No description provided for @insight_title_self_control.
  ///
  /// In en, this message translates to:
  /// **'Self Control'**
  String get insight_title_self_control;

  /// No description provided for @insight_msg_self_control.
  ///
  /// In en, this message translates to:
  /// **'You didn’t spend anything yesterday, nice self-control!'**
  String get insight_msg_self_control;

  /// No description provided for @insight_title_start_saving.
  ///
  /// In en, this message translates to:
  /// **'Start Saving'**
  String get insight_title_start_saving;

  /// No description provided for @insight_msg_start_saving.
  ///
  /// In en, this message translates to:
  /// **'Start saving to reach your {goalName} goal!'**
  String insight_msg_start_saving(String goalName);

  /// No description provided for @insight_title_almost_there.
  ///
  /// In en, this message translates to:
  /// **'Almost There'**
  String get insight_title_almost_there;

  /// No description provided for @insight_msg_almost_there.
  ///
  /// In en, this message translates to:
  /// **'Only {amount} SAR left to reach your {goalName}!'**
  String insight_msg_almost_there(String amount, String goalName);

  /// No description provided for @insight_title_goal_progress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get insight_title_goal_progress;

  /// No description provided for @insight_msg_goal_progress.
  ///
  /// In en, this message translates to:
  /// **'Great progress! You\'re {percentage}% closer to your {goalName} goal.'**
  String insight_msg_goal_progress(String percentage, String goalName);

  /// No description provided for @insight_title_spending_increase.
  ///
  /// In en, this message translates to:
  /// **'Spending Increase'**
  String get insight_title_spending_increase;

  /// No description provided for @insight_msg_spending_increase.
  ///
  /// In en, this message translates to:
  /// **'{category} spending increased by {percentage}% recently.'**
  String insight_msg_spending_increase(String category, String percentage);

  /// No description provided for @insight_title_no_goals_yet.
  ///
  /// In en, this message translates to:
  /// **'No Goals Yet'**
  String get insight_title_no_goals_yet;

  /// No description provided for @insight_msg_no_goals_yet.
  ///
  /// In en, this message translates to:
  /// **'Start your first goal and track your progress here.'**
  String get insight_msg_no_goals_yet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
