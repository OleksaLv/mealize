abstract class AppStrings {
  const AppStrings._();

  // General
  static const String appTitle = 'mealize';
  static const String or = 'Or';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String emailHint = 'emailaddress@gmail.com';
  static const String passwordHint = '********';

  // LoginScreen
  static const String signInTitle = 'Sign in to your\naccount';
  static const String signInSubtitle = 'Enter your email and password to log in';
  static const String logIn = 'Log In';
  static const String loggingIn = 'Logging in...';
  static const String continueWithGoogle = 'Continue with Google';
  static const String noAccount = "Don't have account?";
  static const String signUp = 'Sign Up';

  // RegisterScreen
  static const String signUpTitle = 'Sign up';
  static const String signUpSubtitle = 'Create an account to continue';
  static const String repeatPassword = 'Repeat password';
  static const String register = 'Register';
  static const String registering = 'Registering...';
  static const String haveAccount = "Already have an account?";

  // ScheduleScreen
  static const String schedule = 'Schedule';

  // SettingsScreen
  static const String settings = 'Settings';
  static const String noEmailAvailable = 'No email available';
  static const String logOut = 'Log Out';

  // BottomNavBar
  static const String navSchedule = 'schedule';
  static const String navPantry = 'pantry';
  static const String navRecipes = 'recipes';

  // Errors of validators
  static const String emailEmptyError = 'Please enter your email';
  static const String emailInvalidError = 'Please enter a valid email address';
  static const String passwordEmptyError = 'Please enter your password';
  static const String passwordLengthError = 'Password must be at least 6 characters';
  static const String passwordRepeatError = 'Please repeat your password';
  static const String passwordMismatchError = 'Passwords do not match';

  // Errors of AuthRepository
  static const String authWeakPassword = 'The password is too weak.';
  static const String authEmailInUse = 'This email is already in use.';
  static const String authInvalidEmail = 'Invalid email format.';
  static const String authErrorOccurred = 'An error occurred. Please try again later.';
  static const String authUnknownError = 'An unknown error occurred.';
  static const String authInvalidCredential = 'Invalid email or password.';
  static const String authUserDisabled = 'This account has been disabled.';
  static const String authGoogleError = 'Google sign-in error. Please try again later.';
  static const String authGoogleAuthError = 'Google authentication error. Please try again later.';
  static const String authSignOutError = 'Error logging out.';
}