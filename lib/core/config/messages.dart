class AppMessages {
  AppMessages._();

  static const String passwordSet = "Your password has been reset successfully";

  // ------------------- EMPTY STATES / PLACEHOLDERS -------------------
  static const String emptyTitle = "Nothing Here Yet";
  static const String emptyMessage = "We couldn't find anything to display here at the moment. Try again later or refresh.";

  static const String emptyOrdersTitle = "No Orders Yet";
  static const String emptyOrdersMessage = "You haven't placed any orders yet. Start browsing and add your first order.";

  static const String emptyCartTitle = "Your Cart is Empty";
  static const String emptyCartMessage = "Looks like you haven't added any items to your cart. Explore products and add them here.";

  static const String emptyFavoritesTitle = "No Favorites Found";
  static const String emptyFavoritesMessage = "You haven't marked any items as favorites yet. Tap the heart icon to save your favorites.";

  static const String emptyNotificationsTitle = "No Notifications";
  static const String emptyNotificationsMessage = "You currently have no notifications. Check back later for updates.";

  static const String emptyMessagesTitle = "No Messages";
  static const String emptyMessagesMessage = "Your inbox is empty. Send or receive messages to get started.";

  static const String emptyProfileDataTitle = "Profile Data Missing";
  static const String emptyProfileDataMessage = "Some information is missing in your profile. Please update your profile to continue.";

  static const String emptyWishlistTitle = "No Wishlist Items";
  static const String emptyWishlistMessage = "You haven't added any items to your wishlist yet. Browse products and add your favorites here.";

  static const String emptyBookingsTitle = "No Bookings Yet";
  static const String emptyBookingsMessage = "You don't have any bookings yet. Explore listings and make your first booking.";

  // ------------------- GENERAL SUCCESS / ERROR -------------------
  static const String successTitle = "Success";
  static const String successMessage = "Your request was completed successfully.";

  static const String errorTitle = "Something Went Wrong";
  static const String errorMessage = "We couldn't complete your request. Please check your internet connection and try again.";

  static const String networkErrorTitle = "No Internet Connection";
  static const String networkErrorMessage = "Please check your internet connection and try again.";

  static const String serverErrorTitle = "Something Went Wrong";
  static const String serverErrorMessage = "We're having trouble processing your request right now. Please try again in a moment.";

  static const String notFoundErrorTitle = "Content Not Found";
  static const String notFoundErrorMessage = "We couldn't find what you're looking for. It may have been removed or is no longer available.";

  static const String unknownErrorTitle = "Something Went Wrong";
  static const String unknownErrorMessage = "An unexpected issue occurred. Please try again later.";

  static const String botProtectionErrorTitle = "Access Blocked";
  static const String botProtectionErrorMessage = "Our server has flagged this request as automated traffic. Please contact support and we'll get it resolved for you.";

  static const String timeoutErrorTitle = "Request Timed Out";
  static const String timeoutErrorMessage = "The request took too long to complete. Please try again.";

  static const String forbiddenErrorTitle = "Access Denied";
  static const String forbiddenErrorMessage = "You don't have permission to access this resource.";

  static const String requestCancelledTitle = "Request Cancelled";
  static const String requestCancelledMessage = "The request was cancelled. Please try again.";

  // ------------------- FORMS -------------------
  static const String formEmptyFieldTitle = "Field Required";
  static const String formEmptyFieldMessage = "This field cannot be empty. Please provide a valid value.";

  static const String invalidEmailTitle = "Invalid Email";
  static const String invalidEmailMessage = "Please enter a valid email address.";

  static const String invalidPhoneTitle = "Invalid Phone Number";
  static const String invalidPhoneMessage = "Please enter a valid phone number.";

  // ------------------- DATES / TIME -------------------
  static const String dobEmptyTitle = "Date of Birth Missing";
  static const String dobEmptyMessage = "Please select your date of birth to continue.";

  static const String timeEmptyTitle = "Time Not Selected";
  static const String timeEmptyMessage = "Please select a time before proceeding.";

  // ------------------- USER AUTHENTICATION -------------------
  static const String loginFailedTitle = "Login Failed";
  static const String loginFailedMessage = "Check your credentials and try again.";

  static const String registrationFailedTitle = "Registration Failed";
  static const String registrationFailedMessage = "Something went wrong while registering. Please try again.";

  static const String logoutSuccessTitle = "Logged Out";
  static const String logoutSuccessMessage = "You have been logged out successfully.";

  static const String logoutFailedTitle = "Logout Failed";
  static const String logoutFailedMessage = "Could not log you out. Please try again.";

  static const String sessionExpiredTitle = "Session Expired";
  static const String sessionExpiredMessage = "Your session has expired. Please login again.";
}
